create extension if not exists pgcrypto;
create table public.profiles (
 id uuid primary key references auth.users on delete cascade,
 name text not null default '', email text not null default '',
 role text not null default 'customer' check(role in ('customer','staff','admin')),
 created_at timestamptz not null default now()
);
create function public.app_role() returns text language sql stable security definer set search_path=public as $$ select coalesce((select role from profiles where id=auth.uid()),'customer') $$;
create function public.on_signup() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into profiles(id,name,email) values(new.id,coalesce(new.raw_user_meta_data->>'name',''),coalesce(new.email,''));return new;end $$;
create trigger create_profile after insert on auth.users for each row execute function public.on_signup();
create table public.products (
 id text primary key default gen_random_uuid()::text, name text not null,
 description text not null default '',category text not null check(category in ('Snacks','Bakery','Drinks')),
 price integer not null check(price>0),unit text not null default 'piece',kind text default 'mandazi',
 image_url text,tag text,rating text,available boolean not null default true,created_at timestamptz not null default now()
);
create table public.orders (
 id uuid primary key default gen_random_uuid(), number text not null unique,
 customer_id uuid not null references public.profiles(id),customer_name text not null,phone text not null,notes text not null default '',
 items jsonb not null,total bigint not null check(total>0),
 status text not null default 'Received' check(status in ('Received','Preparing','Ready','Delivered','Cancelled')),
 payment_status text not null default 'Unpaid' check(payment_status in ('Unpaid','Paid')),
 created_at timestamptz not null default now()
);
create table public.messages (
 id uuid primary key default gen_random_uuid(),order_id uuid not null references public.orders(id) on delete cascade,
 sender_id uuid not null references public.profiles(id),sender_role text not null check(sender_role in ('customer','staff','admin')),
 body text not null check(length(trim(body)) between 1 and 2000),created_at timestamptz not null default now()
);
create table public.feedback (
 id uuid primary key default gen_random_uuid(),customer_id uuid references public.profiles(id),
 name text not null check(length(name) between 1 and 100),body text not null check(length(body) between 1 and 2000),
 rating integer not null check(rating between 1 and 5),created_at timestamptz not null default now()
);
alter table profiles enable row level security;
alter table products enable row level security;
alter table orders enable row level security;
alter table messages enable row level security;
alter table feedback enable row level security;
create policy profiles_read on profiles for select to authenticated using (id=auth.uid() or app_role()='admin');
create policy profiles_admin_update on profiles for update to authenticated using(app_role()='admin') with check(app_role()='admin');
create policy products_read on products for select to anon,authenticated using(available or app_role() in ('admin','staff'));
create policy products_admin on products for all to authenticated using(app_role() in ('admin','staff')) with check(app_role() in ('admin','staff'));
create policy orders_read on orders for select to authenticated using(customer_id=auth.uid() or app_role() in ('admin','staff'));
create policy orders_staff_update on orders for update to authenticated using(app_role() in ('admin','staff')) with check(app_role() in ('admin','staff'));
revoke update on orders from authenticated;
grant update(status,payment_status) on orders to authenticated;
create policy messages_read on messages for select to authenticated using(exists(select 1 from orders where id=order_id and (customer_id=auth.uid() or app_role() in ('admin','staff'))));
create policy messages_send on messages for insert to authenticated with check(sender_id=auth.uid() and sender_role=app_role() and exists(select 1 from orders where id=order_id and (customer_id=auth.uid() or app_role() in ('admin','staff'))));
create policy feedback_send on feedback for insert to anon,authenticated with check(customer_id is null or customer_id=auth.uid());
create policy feedback_read on feedback for select to authenticated using(customer_id=auth.uid() or app_role()='admin');
create function public.place_order(basket jsonb,buyer_name text,buyer_phone text,buyer_notes text default '') returns uuid language plpgsql security definer set search_path=public as $$
declare entry jsonb; p products%rowtype; q integer; amount bigint:=0; lines jsonb:='[]'::jsonb; oid uuid:=gen_random_uuid();
begin
 if auth.uid() is null then raise exception 'Please log in first';end if;
 if jsonb_typeof(basket)<>'array' or jsonb_array_length(basket) not between 1 and 100 then raise exception 'Invalid basket';end if;
 if length(trim(buyer_name)) not between 1 and 100 or length(trim(buyer_phone)) not between 7 and 24 or length(buyer_notes)>500 then raise exception 'Please check your contact details';end if;
 for entry in select * from jsonb_array_elements(basket) loop
  q:=(entry->>'qty')::integer;
  if q is null or q not between 1 and 100 then raise exception 'Invalid quantity';end if;
  select * into p from products where id=entry->>'product_id' and available for share;
  if not found then raise exception 'An item is unavailable. Please refresh your basket.';end if;
  amount:=amount+(p.price::bigint*q);
  lines:=lines||jsonb_build_array(jsonb_build_object('product_id',p.id,'name',p.name,'qty',q,'price',p.price));
 end loop;
 insert into orders(id,number,customer_id,customer_name,phone,notes,items,total) values(oid,'EO-'||upper(substr(replace(oid::text,'-',''),1,10)),auth.uid(),trim(buyer_name),trim(buyer_phone),buyer_notes,lines,amount);
 return oid;
end $$;
revoke all on function place_order(jsonb,text,text,text) from public;
grant execute on function place_order(jsonb,text,text,text) to authenticated;
insert into products(id,name,description,category,price,unit,kind,tag,rating) values
('daddies','Crunchy Daddies','Little bites. Big happiness.','Snacks',2000,'pack','daddies','BESTSELLER','4.9'),
('mandazi','Golden Mandazi','Soft inside, golden outside.','Bakery',1000,'piece','mandazi','FRESH DAILY','4.8'),
('samosa','Beef Samosa','Crispy, savoury & full of flavour.','Snacks',1500,'piece','samosa','POPULAR','4.9'),
('tea','Spiced African Tea','A warm cup of comfort.','Drinks',2000,'cup','tea',null,'4.8'),
('cake','Vanilla Cake Slice','A little slice of something sweet.','Bakery',3000,'slice','cake',null,'4.7'),
('juice','Fresh Passion Juice','Freshly squeezed. Naturally good.','Drinks',2500,'cup','juice','REFRESHING','4.9');
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('product-images','product-images',true,3145728,array['image/jpeg','image/png','image/webp']);
create policy image_read on storage.objects for select to anon,authenticated using(bucket_id='product-images');
create policy image_admin_upload on storage.objects for insert to authenticated with check(bucket_id='product-images' and public.app_role() in ('admin','staff'));
create policy image_admin_update on storage.objects for update to authenticated using(bucket_id='product-images' and public.app_role() in ('admin','staff')) with check(bucket_id='product-images' and public.app_role() in ('admin','staff'));
create policy image_admin_delete on storage.objects for delete to authenticated using(bucket_id='product-images' and public.app_role() in ('admin','staff'));
alter publication supabase_realtime add table public.orders,public.messages,public.products;
create index orders_customer_idx on orders(customer_id);
create index messages_order_idx on messages(order_id,created_at);

begin;
alter table public.orders add column if not exists payment_method text not null default 'collection' check (payment_method in ('collection','mtn','airtel'));
alter table public.orders add column if not exists payment_reference text;
alter table public.orders add column if not exists payment_submitted_at timestamptz;
alter table public.orders add column if not exists payment_verified_by uuid references public.profiles(id);
alter table public.orders add column if not exists payment_verified_at timestamptz;
create unique index if not exists orders_mobile_reference_unique on public.orders(payment_method,upper(trim(payment_reference))) where payment_method in ('mtn','airtel') and payment_reference is not null;
create or replace function public.place_order_with_payment(basket jsonb,buyer_name text,buyer_phone text,buyer_notes text,pay_method text) returns uuid language plpgsql security definer set search_path=public as $$
declare oid uuid;
begin
 if pay_method is null or pay_method not in ('collection','mtn','airtel') then raise exception 'Choose a valid payment method';end if;
 oid:=public.place_order(basket,buyer_name,buyer_phone,buyer_notes);
 update orders set payment_method=pay_method where id=oid;
 return oid;
end $$;
revoke all on function public.place_order_with_payment(jsonb,text,text,text,text) from public;
grant execute on function public.place_order_with_payment(jsonb,text,text,text,text) to authenticated;
create or replace function public.submit_payment_reference(order_id uuid,transaction_ref text) returns void language plpgsql security definer set search_path=public as $$
declare o public.orders%rowtype; ref text:=upper(trim(transaction_ref));
begin
 if auth.uid() is null then raise exception 'Please log in';end if;
 select * into o from orders where id=order_id and customer_id=auth.uid() for update;
 if not found then raise exception 'Order not found';end if;
 if o.status='Cancelled' or o.payment_status='Paid' then raise exception 'This order cannot accept a payment reference';end if;
 if o.payment_method not in ('mtn','airtel') then raise exception 'This order uses pay on collection';end if;
 if ref is null or length(ref) not between 4 and 80 or ref !~ '^[A-Z0-9 ._/-]+$' then raise exception 'Enter a valid transaction reference (4 to 80 characters)';end if;
 update orders set payment_reference=ref,payment_submitted_at=now() where id=o.id;
end $$;
revoke all on function public.submit_payment_reference(uuid,text) from public;
grant execute on function public.submit_payment_reference(uuid,text) to authenticated;
create or replace function public.audit_manual_payment() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if new.payment_status='Paid' and old.payment_status is distinct from 'Paid' then
  if public.app_role() not in ('admin','staff') then raise exception 'Only staff can verify payments';end if;
  if new.status='Cancelled' then raise exception 'Cannot confirm a cancelled order';end if;
  if new.payment_method in ('mtn','airtel') and nullif(trim(new.payment_reference),'') is null then raise exception 'A customer transaction reference is required';end if;
  new.payment_verified_by:=auth.uid();new.payment_verified_at:=now();
 elsif new.payment_status='Unpaid' and old.payment_status='Paid' then
  new.payment_verified_by:=null;new.payment_verified_at:=null;
 end if;
 return new;
end $$;
drop trigger if exists audit_manual_payment on public.orders;
create trigger audit_manual_payment before update on public.orders for each row execute function public.audit_manual_payment();
commit;
