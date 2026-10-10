# Stock Avenue Ghana — Backend Setup Guide

This website now runs on a real Supabase backend: products, prices, sizes and
images all live in a database instead of being hard-coded in the page. Follow
these steps once, in order, and the whole site (and the admin page) will work.

## 1. Create your Supabase project

1. Go to https://supabase.com and sign in (or create a free account).
2. Click **New Project**. Pick any name (e.g. "stock-avenue-ghana") and a
   strong database password — save that password somewhere safe.
3. Wait about a minute for the project to finish setting up.

## 2. Run the database schema

1. In your project, open **SQL Editor** (left sidebar).
2. Click **New query**.
3. Open `supabase-schema.sql` (included alongside this guide), copy **all**
   of it, paste it into the editor, and click **Run**.
4. This creates the `products` table (with stock levels and optional sale
   pricing), the `orders` table (so real checkouts are recorded, not just
   sent to WhatsApp), locks everything down with security rules, sets up
   the image storage bucket, and loads your 28 starting products so the
   site isn't empty on day one. You can edit or delete any of them from the
   admin page afterwards.

> **Already set up the site before and just pulled these newer files?**
> Don't re-run `supabase-schema.sql` — it will try to recreate things you
> already have. Instead run `migration-v2.sql` once; it only adds what's
> new (stock levels, sale pricing, the orders table) without touching your
> existing products.

## 3. Lock the system down (important — do this before going live)

1. Go to **Authentication → Sign In / Providers** (or **Authentication →
   Settings** depending on your Supabase version).
2. Find **Allow new users to sign up** and turn it **OFF**. This is the most
   important step — it stops any stranger from creating an account and
   getting access to your admin page.
3. Go to **Authentication → Users → Add user**. Create your own admin login:
   your email address and a strong password. This is the only account that
   will ever be able to log into `admin.html`.

## 4. Connect the website to your project

1. Go to **Project Settings → API**.
2. Copy the **Project URL** and the **anon / public** key (NOT the
   `service_role` key — that one must never be used in the browser).
3. Open each of these files and replace the two placeholder lines near the
   top of the `<script>` section:
   - `index.html`, `shop.html`, `collections.html`, `product.html`,
     `about.html`, `contact.html`, `admin.html`
   ```js
   const SUPABASE_URL = "PASTE_YOUR_PROJECT_URL_HERE";
   const SUPABASE_ANON_KEY = "PASTE_YOUR_ANON_PUBLIC_KEY_HERE";
   ```
   Tip: since it's the same two lines in every file, use your code editor's
   "Find & Replace across files" to update all seven at once.

## 5. Log in to the admin page

1. Open `admin.html` in your browser.
2. Sign in with the admin email/password you created in Step 3.
3. From there you can add, edit, deactivate or delete products, upload
   product photos, set the price in **cedis (GHS) or dollars (USD)**, and
   set available sizes (e.g. `S, M, L, XL` or `30, 32, 34, 36`).

## Why this is secure

- The public site can only ever **read** products — it uses the public
  "anon" key, which has no write access at all (enforced by the database's
  Row Level Security rules, not just hidden in the code).
- Only a signed-in admin session can add, edit or delete a product or
  upload an image — enforced the same way, at the database level.
- Because public sign-up is switched off, the only account that can ever
  sign in is the one you create yourself in Step 3.
- Nothing sensitive (passwords, secret keys) is ever stored in the website
  files — only the public URL and public anon key, which are safe to expose
  by design.

## Ongoing use

- To add more admin users later (e.g. a staff member), repeat Step 3 to
  create another account the same way — never re-enable public sign-up.
- If you ever suspect a password was compromised, go to **Authentication →
  Users**, reset that user's password or delete the account.

## What's new in this version

- **Stock levels** — set how many of each item you have in the admin form.
  The storefront shows "Only X left" when stock is low and "Out of Stock"
  (with Add to Cart disabled) at zero. Stock is not deducted automatically
  when an order comes in — you lower it yourself once you've confirmed the
  sale on WhatsApp, so two people enquiring about the same last item can't
  accidentally both "win" it before you've replied to either.
- **Sale pricing** — set a "Compare at price" in the admin form higher than
  the actual price to show a strikethrough price and a sale badge.
- **Wishlist** — shoppers can save items with the heart icon; stored in
  their browser, no setup needed on your end.
- **Real checkout** — "Send Order Enquiry" now asks for the customer's name
  and phone number first, saves the order to your database, and then opens
  WhatsApp with the same details. You'll see every order (even ones a
  customer never followed up on WhatsApp) in the new **Orders** tab in
  admin.html, where you can mark them Confirmed, Completed or Cancelled.

## Deploying to stockavenuegh.com

1. Upload **every file and folder** to the root of your hosting (the same
   level, not inside a subfolder) — that means all the `.html` files,
   `manifest.json`, `sw.js`, `robots.txt`, `sitemap.xml`, and the whole
   `icons/` folder together. The `backend/` folder is for you only — it
   doesn't need to go on the live server.
2. Make sure `index.html` is set as your site's default/home page in
   Stormerhost's hosting settings (sometimes called "index file" or
   "default document").
3. **HTTPS is required.** Both the "Install app" feature and the service
   worker only work over `https://` (never plain `http://`). Stormerhost
   should issue a free SSL certificate for the domain automatically — if
   `https://stockavenuegh.com` doesn't load with a padlock in the browser,
   contact their support to enable it before showing the client.
4. Once live, submit `https://stockavenuegh.com/sitemap.xml` in Google
   Search Console (Search Console → Sitemaps) so Google starts indexing the
   site faster.

## SEO additions in this version

- Every page now has a canonical URL, Open Graph tags, and a Twitter card
  pointing at `stockavenuegh.com`, plus `robots.txt` and `sitemap.xml`.
- Structured data (`ClothingStore` schema) is embedded on every page so
  Google can show your address, phone number and Instagram directly in
  search results.
- `admin.html` is excluded from search engines via `robots.txt` and a
  `noindex` tag, so it never shows up in Google.

## Installing as a mobile app

- The site is now an installable PWA (Progressive Web App). On Android/
  Chrome, a small "Install Stock Avenue Ghana" card appears automatically
  a couple of seconds after a visitor lands on the site (only if the
  browser considers it installable, which requires HTTPS — see above).
  Tapping **Install** adds it to their home screen like a real app.
- On iPhone, Safari doesn't support that automatic prompt, so visitors
  instead see a card telling them to tap **Share → Add to Home Screen**.
- Once someone dismisses the card (or installs), it won't show again on
  that device.
- The app icon is the "S" mark already used for the favicon, generated at
  the sizes each platform needs (`icons/icon-192.png`, `icons/icon-512.png`,
  a maskable version for Android's adaptive icons, and an Apple touch icon).
- This install feature is on the 6 shopper-facing pages only — `admin.html`
  stays a normal secured page, not something intended to be "installed".
