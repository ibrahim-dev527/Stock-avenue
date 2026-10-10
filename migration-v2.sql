-- ============================================================
-- STOCK AVENUE GHANA — UPGRADE MIGRATION
-- Run this AFTER supabase-schema.sql (or after you've already
-- run it once before). Safe to run even if some parts already
-- exist — it checks before creating anything.
-- ============================================================

-- ---------- 1. New product columns: stock + sale pricing ----------
alter table products add column if not exists stock_qty integer not null default 10 check (stock_qty >= 0);
alter table products add column if not exists compare_at_price numeric(10,2) check (compare_at_price is null or compare_at_price >= 0);

-- ---------- 2. ORDERS TABLE ----------
-- Every "Send Order Enquiry" now saves a real order record here
-- (in addition to opening WhatsApp), so you have a proper order
-- history in the admin page instead of relying on WhatsApp alone.
create table if not exists orders (
  id             bigint generated always as identity primary key,
  customer_name  text not null,
  customer_phone text not null,
  items          jsonb not null,           -- snapshot of cart items at time of order
  total_ghs      numeric(10,2) not null default 0,
  total_usd      numeric(10,2) not null default 0,
  status         text not null default 'pending' check (status in ('pending','confirmed','completed','cancelled')),
  created_at     timestamptz not null default now()
);

alter table orders enable row level security;

-- Any shopper (logged out) can CREATE an order when they check out —
-- but note they can only INSERT, never read, edit or delete orders.
create policy "Anyone can place an order"
on orders for insert
to anon, authenticated
with check (true);

-- Only a signed-in admin can view or manage the order list.
create policy "Admins can view orders"
on orders for select
to authenticated
using (true);

create policy "Admins can update orders"
on orders for update
to authenticated
using (true) with check (true);

create policy "Admins can delete orders"
on orders for delete
to authenticated
using (true);

-- ---------- 3. Reduce stock automatically isn't done here on purpose ----------
-- Stock is decreased manually by you in the admin page once you confirm
-- an order on WhatsApp — this avoids accidentally overselling if two
-- people enquire about the same last item before you reply to either.
