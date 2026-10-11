-- ============================================================
-- STOCK AVENUE GHANA — SUPABASE DATABASE SCHEMA (v2)
-- Run this once in your Supabase project's SQL Editor
-- (Dashboard → SQL Editor → New query → paste all of this → Run)
--
-- Already ran the v1 version of this file before? Don't re-run
-- this one — run backend/migration-v2.sql instead, it only adds
-- what's new without touching what you already have.
-- ============================================================

-- ---------- 1. PRODUCTS TABLE ----------
create table if not exists products (
  id                bigint generated always as identity primary key,
  name              text not null,
  category          text not null check (category in
                      ('Clothing','Footwear','Perfumes','Watches','Sunglasses','Kidswear','Accessories')),
  description       text not null default '',
  price             numeric(10,2) not null default 0 check (price >= 0),
  compare_at_price  numeric(10,2) check (compare_at_price is null or compare_at_price >= 0), -- set this to show a "was" price / sale badge
  currency          text not null default 'GHS' check (currency in ('GHS','USD')),
  stock_qty         integer not null default 10 check (stock_qty >= 0),
  sizes             text[] not null default '{}',   -- e.g. {S,M,L,XL} or {30,32,34,36}
  images            text[] not null default '{}',   -- public Storage URLs, first = main image
  tag               text default null check (tag in ('featured','new') or tag is null),
  is_active         boolean not null default true,  -- lets admin hide a product without deleting it
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_products_updated_at on products;
create trigger trg_products_updated_at
before update on products
for each row execute function set_updated_at();

-- ---------- 2. PRODUCTS ROW LEVEL SECURITY ----------
alter table products enable row level security;

create policy "Public can view active products"
on products for select
to anon, authenticated
using (is_active = true);

create policy "Admins can view all products"
on products for select
to authenticated
using (true);

create policy "Admins can insert products"
on products for insert
to authenticated
with check (true);

create policy "Admins can update products"
on products for update
to authenticated
using (true) with check (true);

create policy "Admins can delete products"
on products for delete
to authenticated
using (true);

-- ---------- 3. ORDERS TABLE ----------
-- Every checkout saves a real order record here (in addition to
-- opening WhatsApp), so you have proper order history in the
-- admin page instead of relying on WhatsApp messages alone.
create table if not exists orders (
  id             bigint generated always as identity primary key,
  customer_name  text not null,
  customer_phone text not null,
  items          jsonb not null,
  total_ghs      numeric(10,2) not null default 0,
  total_usd      numeric(10,2) not null default 0,
  status         text not null default 'pending' check (status in ('pending','confirmed','completed','cancelled')),
  created_at     timestamptz not null default now()
);

alter table orders enable row level security;

create policy "Anyone can place an order"
on orders for insert
to anon, authenticated
with check (true);

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

-- ---------- 4. STORE SETTINGS (editable from admin.html) ----------
create table if not exists store_settings (
  id                 int primary key default 1,
  phone_main         text not null default '0544 862 778',
  phone_alt          text not null default '0206 763 412',
  whatsapp_number    text not null default '233544882778',
  address_line1      text not null default '3 La-Bawaleshi Road',
  address_line2      text not null default 'Accra, Ghana',
  instagram_handle   text not null default 'stockavenue.gh',
  announcement_text  text not null default '',
  announcement_active boolean not null default false,
  updated_at         timestamptz not null default now(),
  constraint single_row check (id = 1)
);

drop trigger if exists trg_settings_updated_at on store_settings;
create trigger trg_settings_updated_at
before update on store_settings
for each row execute function set_updated_at();

alter table store_settings enable row level security;

create policy "Public can view store settings"
on store_settings for select
to anon, authenticated
using (true);

create policy "Admins can update store settings"
on store_settings for update
to authenticated
using (true) with check (true);

create policy "Admins can insert store settings"
on store_settings for insert
to authenticated
with check (true);

insert into store_settings (id, phone_main, phone_alt, whatsapp_number, address_line1, address_line2, instagram_handle, announcement_text, announcement_active)
values (1, '0544 862 778', '0206 763 412', '233544882778', '3 La-Bawaleshi Road', 'Accra, Ghana', 'stockavenue.gh', '', false)
on conflict (id) do nothing;

-- ---------- 5. STORAGE BUCKET FOR PRODUCT IMAGES ----------
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

create policy "Public can view product images"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'product-images');

create policy "Admins can upload product images"
on storage.objects for insert
to authenticated
with check (bucket_id = 'product-images');

create policy "Admins can update product images"
on storage.objects for update
to authenticated
using (bucket_id = 'product-images');

create policy "Admins can delete product images"
on storage.objects for delete
to authenticated
using (bucket_id = 'product-images');

-- ============================================================
-- IMPORTANT SECURITY STEPS TO DO IN THE SUPABASE DASHBOARD
-- (not SQL — see SETUP.md for full walkthrough):
--   1. Authentication → Providers → Email → turn OFF "Allow new
--      users to sign up".
--   2. Authentication → Users → Add user → create your ONE admin
--      account manually.
--   3. Only that account can log in to admin.html and write to
--      the database, because signups are disabled.
-- ============================================================

-- ---------- 6. SEED DATA (only runs if products table is empty) ----------
do $$
begin
  if not exists (select 1 from products) then
    insert into products (name, category, description, price, compare_at_price, currency, stock_qty, sizes, images, tag) values
    ('Classic Oxford Shirt','Clothing','A versatile wardrobe essential for polished everyday dressing and smart-casual occasions.',180,null,'GHS',14,'{S,M,L,XL,XXL}','{https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=800&q=80&auto=format&fit=crop}','featured'),
    ('Premium Casual Shirt','Clothing','Contemporary fabric and fit, designed for relaxed weekday wear.',160,null,'GHS',18,'{S,M,L,XL}','{https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=800&q=80&auto=format&fit=crop}','featured'),
    ('Essential Polo Shirt','Clothing','A clean, comfortable polo that pairs easily with jeans or chinos.',140,169,'GHS',20,'{S,M,L,XL,XXL}','{https://images.unsplash.com/photo-1586790170083-2f9ceadc732d?w=800&q=80&auto=format&fit=crop}','featured'),
    ('Everyday Denim Jeans','Clothing','A dependable straight-leg denim built for daily comfort.',220,null,'GHS',12,'{30,32,34,36,38}','{https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=800&q=80&auto=format&fit=crop}','featured'),
    ('Modern Tailored Blazer','Clothing','A structured silhouette for smart-casual and formal settings alike.',420,480,'GHS',6,'{S,M,L,XL}','{https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&q=80&auto=format&fit=crop}','featured'),
    ('Relaxed Fit Trousers','Clothing','Comfortable tapered trousers suited for work and everyday wear.',190,null,'GHS',10,'{30,32,34,36}','{https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=800&q=80&auto=format&fit=crop}',null),
    ('Signature Oversized T-Shirt','Clothing','A relaxed everyday tee in a heavier, premium-feel cotton.',110,null,'GHS',22,'{S,M,L,XL}','{https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800&q=80&auto=format&fit=crop}','new'),
    ('Everyday Summer Dress','Clothing','A lightweight, easy-fit dress designed for warm-weather days.',210,null,'GHS',9,'{S,M,L}','{https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800&q=80&auto=format&fit=crop}','new'),
    ('Urban Essential Sneakers','Footwear','A clean, minimal sneaker that works with almost any outfit.',26,null,'USD',16,'{40,41,42,43,44}','{https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800&q=80&auto=format&fit=crop}','featured'),
    ('Classic Leather Loafers','Footwear','Timeless loafers crafted for smart-casual dressing.',34,40,'USD',8,'{40,41,42,43}','{https://images.unsplash.com/photo-1533867617858-e7b97e060509?w=800&q=80&auto=format&fit=crop}','featured'),
    ('Everyday Casual Sneakers','Footwear','A comfortable go-to sneaker built for daily movement.',24,null,'USD',15,'{40,41,42,43,44}','{https://images.unsplash.com/photo-1560769629-975ec94e6a86?w=800&q=80&auto=format&fit=crop}','new'),
    ('Minimal Slides','Footwear','Simple, comfortable slides for off-duty days.',90,null,'GHS',0,'{40,41,42,43}','{https://images.unsplash.com/photo-1603808033176-3af09aa42fdc?w=800&q=80&auto=format&fit=crop}',null),
    ('Classic Formal Shoes','Footwear','Polished leather-style shoes for formal and office wear.',38,null,'USD',11,'{40,41,42,43,44}','{https://images.unsplash.com/photo-1614252369475-531eba835eb1?w=800&q=80&auto=format&fit=crop}',null),
    ('Kids Everyday Sneakers','Footwear','Durable, comfortable sneakers built for active kids.',120,null,'GHS',13,'{28,30,32,34}','{https://images.unsplash.com/photo-1514989940723-e8e51635b782?w=800&q=80&auto=format&fit=crop}',null),
    ('Signature Oud Fragrance','Perfumes','A rich, long-lasting oud-based fragrance for evening wear.',45,null,'USD',10,'{50ml,100ml}','{https://images.unsplash.com/photo-1594035910387-fea47794261f?w=800&q=80&auto=format&fit=crop}','featured'),
    ('Fresh Citrus Fragrance','Perfumes','A light, energising scent suited for daytime wear.',38,null,'USD',17,'{50ml,100ml}','{https://images.unsplash.com/photo-1541643600914-78b084683601?w=800&q=80&auto=format&fit=crop}','new'),
    ('Midnight Amber','Perfumes','A warm, deep fragrance designed for cooler evenings.',42,50,'USD',7,'{50ml,100ml}','{https://images.unsplash.com/photo-1590736969955-71cc94901144?w=800&q=80&auto=format&fit=crop}',null),
    ('Minimalist Wristwatch','Watches','A clean-faced everyday watch that pairs with any outfit.',350,null,'GHS',9,'{One Size}','{https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=800&q=80&auto=format&fit=crop}','featured'),
    ('Classic Leather Strap Watch','Watches','A refined watch with a soft leather strap for daily wear.',300,360,'GHS',5,'{One Size}','{https://images.unsplash.com/photo-1547996160-81dfa63595aa?w=800&q=80&auto=format&fit=crop}',null),
    ('Everyday Steel Watch','Watches','A durable steel-band watch suited for work and weekends.',65,null,'USD',12,'{One Size}','{https://images.unsplash.com/photo-1508057198894-247b23fe5ade?w=800&q=80&auto=format&fit=crop}','new'),
    ('Classic Black Frame Sunglasses','Sunglasses','A timeless black frame suited for everyday sun protection.',150,null,'GHS',20,'{One Size}','{https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=800&q=80&auto=format&fit=crop}','featured'),
    ('Aviator Sunglasses','Sunglasses','A classic aviator shape with a modern finish.',22,null,'USD',14,'{One Size}','{https://images.unsplash.com/photo-1473496169904-658ba7c44d8a?w=800&q=80&auto=format&fit=crop}',null),
    ('Round Retro Sunglasses','Sunglasses','A retro-inspired round frame for a distinct look.',130,155,'GHS',8,'{One Size}','{https://images.unsplash.com/photo-1577803645773-f96470509666?w=800&q=80&auto=format&fit=crop}','new'),
    ('Kids Casual Outfit Set','Kidswear','A comfortable, easy-to-wear everyday set for kids.',140,null,'GHS',11,'{2-3Y,4-5Y,6-7Y,8-9Y}','{https://images.unsplash.com/photo-1622290291468-a28f7a7dc6a8?w=800&q=80&auto=format&fit=crop}','featured'),
    ('Kids Graphic T-Shirt','Kidswear','A soft, playful everyday tee for kids.',65,null,'GHS',19,'{2-3Y,4-5Y,6-7Y,8-9Y}','{https://images.unsplash.com/photo-1519238263530-99bdd11df2ea?w=800&q=80&auto=format&fit=crop}',null),
    ('Everyday Crossbody Bag','Accessories','A compact, practical bag for daily essentials.',30,null,'USD',13,'{One Size}','{https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=800&q=80&auto=format&fit=crop}','featured'),
    ('Classic Leather Belt','Accessories','A durable, everyday belt finished for both casual and formal fits.',85,null,'GHS',16,'{S,M,L,XL}','{https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800&q=80&auto=format&fit=crop}',null),
    ('Structured Tote Bag','Accessories','A spacious, structured tote suited for work and travel days.',40,48,'USD',6,'{One Size}','{https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=800&q=80&auto=format&fit=crop}','new');
  end if;
end $$;
