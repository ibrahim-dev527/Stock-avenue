-- ============================================================
-- STOCK AVENUE GHANA — UPGRADE MIGRATION v3
-- Adds a single-row "store_settings" table so the owner can edit
-- contact info and a site-wide announcement banner from admin.html
-- without ever touching code. Run this once in the SQL Editor.
-- ============================================================

create table if not exists store_settings (
  id                 int primary key default 1,
  phone_main         text not null default '0544 862 778',
  phone_alt          text not null default '0206 763 412',
  whatsapp_number    text not null default '233544882778',   -- digits only, country code first, no + or spaces
  address_line1      text not null default '3 La-Bawaleshi Road',
  address_line2      text not null default 'Accra, Ghana',
  instagram_handle   text not null default 'stockavenue.gh', -- no @ and no URL, just the handle
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

-- seed the single settings row with your current live values (safe to run once)
insert into store_settings (id, phone_main, phone_alt, whatsapp_number, address_line1, address_line2, instagram_handle, announcement_text, announcement_active)
values (1, '0544 862 778', '0206 763 412', '233544882778', '3 La-Bawaleshi Road', 'Accra, Ghana', 'stockavenue.gh', '', false)
on conflict (id) do nothing;
