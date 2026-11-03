# Educate Orders

**Latest payment update:** manual MTN MoMo and Airtel Money are now implemented alongside pay on collection. Existing projects must run `manual-payments.sql` before the mobile payment choices become available. They are manual transfers, not automatic payment processing.
## Your phone-first ordering app

### Updated layout
The Educate-branded interface now uses an Airtel Money-inspired red-and-white dashboard: bold red header, basket summary, four quick-action shortcuts, a food promotion card, rounded product cards and fixed mobile bottom navigation. This is an independent design, not an Airtel app or affiliation.

Open the **Educate Orders live preview** to try the app. It works on small phone screens and larger displays.

### Try it now
1. Add mandazi, daddies or samosas to your basket.
2. Open **My cart**, enter a name and phone number, and place a demo order.
3. Go to **Orders** to check its status or open the order conversation.
4. Connect Supabase and log in as an authorised admin or staff member to use management tools.
5. New accounts are customers. Only admins can assign roles.

**Preview mode is local to your browser.** There is no public staff/admin role selector, and no money is charged. There are no seeded customer records; create a demo order to populate the dashboard.

## Included
- Phone-first shop, category filters, desktop search and favourites.
- Basket with quantity controls and Uganda shilling pricing.
- Pickup checkout with payment on collection.
- Order progress and staff payment-status recording.
- Admin product creation/editing, photos, pricing and menu availability.
- Account creation and login screens wired to Supabase when connected.
- Feedback form and admin feedback view.
- Order-specific customer/staff chat; shared realtime updates when connected.
- Supabase row-level access policies, profile roles and protected product uploads.
- Database-authoritative checkout: product prices are calculated on the server.
- Installable PWA shell, offline catalogue and locally saved basket/order drafts.

## Connect Supabase
1. Create a new Supabase project.
2. Run **supabase.sql** from this project in the Supabase SQL Editor. The script is intended for a fresh database and includes sample products with illustrative prices.
3. Open **Account → Configure**, or the **Connect Supabase** link in the demo banner.
4. Enter the project URL and its **publishable / anon key**. Never enter a secret or service-role key. The public key is expected to be browser-visible; row-level security protects your data.
5. Create your account in the app. Confirm your email if your project requires it. Set your production Site URL and allowed redirect URLs in Supabase Auth settings.
6. Promote your own account from the trusted Supabase SQL Editor:

```sql
update public.profiles
set role = 'admin'
where email = 'your-actual-email@example.com';
```

7. Refresh the app or sign out and back in. Your workspace appears in Account. Admins can view registered profiles and assign staff roles. Do not remove your last admin.
8. Test with two separate browsers/devices: place an order as a customer and open the workspace as staff. Realtime is enabled in the SQL script.

Connection replaces the demo catalogue with the shared Supabase catalogue. Local demo orders and users are **not** migrated. Browser-local configuration must be entered per device in this prototype; for public launch, deploy a fixed public project configuration rather than asking customers to enter it.

## Offline behaviour
Visit once online and allow the service worker to save the app. Reopen or refresh to ensure it is controlling the page. Then the saved catalogue and basket remain accessible without internet. Default product artwork is embedded; uploaded product photos are cached after being viewed. Unvisited photos may not be available offline.

Offline checkout saves an explicit **Draft**, not a confirmed order. Reconnect, open Orders, and submit it manually. The app checks prices and availability again. Nothing is automatically charged or silently sent. Chat, feedback, account operations and staff updates need internet. Supabase's authentication library is loaded online; account sign-in cannot start offline.

## Notifications and payments
- Live in-app order/message alerts work while the app is open and connected to Supabase.
- Browser notifications can be requested in Account; support varies by device. They are not reliable background push.
- Closed-app/background push needs a push service, subscription management and a server-side notification worker. These are **not included**.
- This version uses **pay on collection** and manual staff payment records. It does **not** process Mobile Money or card payments.
- Adding Mobile Money requires a supported provider, server-side secrets and verified payment webhooks. Never mark payments paid solely from a browser callback.

## Running and deployment
Requires Node.js 18 or later. There are no runtime npm dependencies.

```sh
cd educate-orders
npm start
```

The preview server listens on `0.0.0.0:3000`. For production, deploy index.html, app.js, style.css, sw.js, manifest.webmanifest and icon.svg on an HTTPS static host. Serve the manifest and service worker from the application root. HTTPS is required for installation, service workers and notifications (localhost is a development exception).

Fonts use an optional external Google Fonts stylesheet. Offline, system fonts are used. Product artwork is original inline SVG illustration, not photography. All sample prices and ratings are placeholders to review before launch.

## Verification
Mobile-browser smoke testing covered: catalogue rendering, adding to basket, placing an order, sending a demo chat message, changing an order status as admin, creating a product, offline reload, saving an offline draft, and checking for horizontal overflow. No browser JavaScript errors occurred in that test. The live Supabase integration cannot be end-to-end verified until a project is supplied.

## Before public launch
- Connect and test your real Supabase project with separate customer, staff and admin accounts.
- Verify access policies, role changes, realtime delivery and uploaded photo caching on target phones.
- Add abuse/rate limiting (especially public feedback), error monitoring, backups, and recovery procedures.
- Add a password-reset flow and account deletion workflow.
- Establish your actual menu, collection arrangements, privacy policy and data retention rules.
- Add stock quantities/reservations if you need inventory control; current availability is a simple available/hidden switch, not unit stock tracking.
- Add reliable background push and a verified payment provider if required.
- Deploy fixed public Supabase configuration and harden authentication/session handling for production.

Project files: index.html, style.css, app.js, sw.js, manifest.webmanifest, icon.svg, server.js, package.json, supabase.sql. The provided source archive includes this guide.

## Login-only management update
The workspace now requires a signed-in Supabase user with a matching database profile assigned `admin` or `staff`. There is no demo-role switch. Guests and customers do not see management tools. Admins and staff can manage products, product photos and orders. Only admins can view/manage users and roles or view all feedback. Product uploads accept JPG, PNG and WebP up to 3 MB; arbitrary executable/document uploads are not supported.

Existing Supabase projects: run `permissions-update.sql` to allow authorised staff to manage products and photos. New projects: use the updated `supabase.sql`. Permissions must be applied in your actual project; they are not activated remotely by editing these files.

Guest browser verification passed: no role selector or workspace link, and a direct workspace navigation attempt opened login. No JavaScript errors occurred. Real admin/staff login and database permissions still need testing against your Supabase project.

## Modern CSS update
Added refined gradients, softer shadows, floating mobile navigation, consistent rounded cards, clearer form focus states, press/hover feedback and short entrance/dialog transitions. Motion respects prefers-reduced-motion. Unnecessary source comments were removed. Mobile and desktop browser checks at widths 360, 390, 768 and 1440 verified no horizontal overflow, working basket and checkout, reduced-motion support and no JavaScript errors.

## MRHS Educate Club branding
The app now uses the supplied official club logo and its navy (#001F5E), turquoise (#00B5C8) and orange (#FF8300) palette. Headers, cards, buttons, tabs, forms, navigation and notification styling follow these colours. The original logo artwork is retained; app icons are derived from the emblem on a white background. Logo and icons are cached for offline use. Modern transitions and reduced-motion support remain. Browser checks passed at 360, 390, 768 and 1440 pixels, including basket/checkout and no horizontal overflow.

## Supabase project configured
The app now includes config.js with the supplied public project URL and publishable key. These are public browser credentials, not secrets. Include config.js when deploying. The connection check succeeded for Supabase Auth, but public.products was not found. Run supabase.sql in the project SQL Editor before using the live app. Email confirmation is enabled in this project. The project is not connected through Arena’s Supabase connector, so database setup was not executed automatically.

## Account confirmation update
Signup without a session now keeps an explicit Check your email dialog open, explains that the user is not signed in, and offers a resend confirmation form. Login errors remain visible in the form, submit buttons show progress, and successful login opens Account to show the signed-in identity/role. New users remain customers until an administrator assigns another role. Confirmation/resend/unconfirmed-login UI tests used mocked auth responses to avoid sending test emails or creating accounts in the real project.

Confirmation-link fix: connected the login screen’s Need a confirmation email action to the resend dialog. The email entered on the login form is carried forward. Browser testing clicked the actual link and verified a mocked resend request and visible success feedback, without sending a real email.

## Manual Mobile Money checkout
Payment details confirmed by the owner: MTN MoMo 0778722677; Airtel Money 0705994665; recipient Baluku Ronald. These are receiving-wallet instructions, not a payment gateway or an automatic deduction. Customers must verify the displayed recipient name in their provider’s app/menu before authorising payment. Never enter or collect wallet PINs in Educate Orders.

Existing projects: run manual-payments.sql in the Supabase SQL Editor. It adds payment method, customer reference, submission time, staff verifier and confirmation time; a database-unique reference index prevents the same reference being assigned to multiple orders on the same network. It adds protected checkout/reference functions and staff-verification audit handling. New installations already include this update at the end of supabase.sql. Do not rerun the full initial setup on an existing project.

Until migration is applied, mobile payment options stay disabled and collection continues to use the original checkout function. After migration, refresh the app. Place an order first, then use Orders → Payment details / Submit reference. Send the database-confirmed total from the provider’s own app/menu, then submit the reference. The order remains Unpaid, displayed as Awaiting staff verification. Staff must compare the actual receiving-wallet credit, transaction reference and amount before clicking Confirm received and checking the receipt-confirmation box. Payment confirmation records who verified it and when. This is a manual staff assertion, not independent provider verification. No test payments or real accounts were created.

Browser tests with mocked Supabase responses passed for MTN/Airtel destination details, checkout payment selection, transaction reference submission, continued unpaid state until staff approval, staff confirmation and disabled mobile choices when migration is absent. Real database end-to-end verification still requires running the migration and testing with authorised accounts. Cancellation/refund processing and automated network confirmation are not implemented. Contact the team for payment corrections or refunds.
