begin;
drop policy if exists products_admin on public.products;
create policy products_admin on public.products for all to authenticated
using(public.app_role() in ('admin','staff'))
with check(public.app_role() in ('admin','staff'));
drop policy if exists image_admin_upload on storage.objects;
create policy image_admin_upload on storage.objects for insert to authenticated
with check(bucket_id='product-images' and public.app_role() in ('admin','staff'));
drop policy if exists image_admin_update on storage.objects;
create policy image_admin_update on storage.objects for update to authenticated
using(bucket_id='product-images' and public.app_role() in ('admin','staff'))
with check(bucket_id='product-images' and public.app_role() in ('admin','staff'));
drop policy if exists image_admin_delete on storage.objects;
create policy image_admin_delete on storage.objects for delete to authenticated
using(bucket_id='product-images' and public.app_role() in ('admin','staff'));
commit;
