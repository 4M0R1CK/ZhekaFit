# SEO notes

- Until the project has a public hostname, `robots.txt` and `sitemap.xml` use `https://example.com`. Set `VITE_PUBLIC_SITE_URL` to the production origin at build time; the build updates both files.
- The build collects published program and trainer slugs through the public Supabase API and adds their detail routes to the sitemap. If Supabase cannot be reached during build, the sitemap still contains the static public routes; rebuild after the service is available to include dynamic pages.
- This frontend does not expose a first-party `/api` endpoint. It calls Supabase directly, so nginx cannot add `X-Robots-Tag` to those separate API responses. Supabase row-level security controls data access; `robots.txt` is not an access-control mechanism.
- The app is a client-rendered React SPA. It updates the title and private-route `noindex` metadata after navigation; crawlers must render JavaScript to see those updates. Server-rendered route metadata can be added when the app moves to SSR.
- The page has Open Graph title and description tags. A canonical origin and social preview image are not configured until the production domain and share image are selected.

## Lighthouse evidence

Desktop Lighthouse SEO on the local production build (Chrome 157, Lighthouse 13.6): **92/100 before** and **100/100 after**. The only failed scored audit before was the missing/invalid `robots.txt`; all scored SEO audits passed after the changes. Screenshots: [before](before.png) and [after](after.png). The Lighthouse report also lists structured data among the items to check manually; the site does not currently publish structured data.

The generated JavaScript entry is about 668 KB before gzip. Code splitting is left for the later performance lesson; the audited SEO category passes independently of that performance work.
