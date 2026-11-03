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
