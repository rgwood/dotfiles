---
name: publish-site
description: Publish a small static website (HTML/CSS/JS, images) to its own subdomain at https://NAME.reillywood.com. Use when Reilly asks to publish, host, deploy or "put up" a single-serving site, joke page, demo or other static page on reillywood.com.
---

# Publish a static site to NAME.reillywood.com

A Cloudflare Worker serves `https://NAME.reillywood.com/PATH` from the object
`NAME/PATH` in the `reillywood-sites` R2 bucket. A new site is just uploaded files:
no DNS, cert or deploy step.

## Rules

- `NAME` is one lowercase DNS label: `a-z`, `0-9` and `-`, no dots. `foo.bar` won't work.
- Don't use `www`, `mail`, `reitunes`, `api`, `admin`, `login`, `auth` or `status`.
- Static files only. There's no server-side code. Use relative links or links from `/`.
- Put `index.html` at the root of the site. `/about` redirects to `/about/` and serves
  `about/index.html`. An optional `404.html` at the root is the site's 404 page.
- Never put secrets or anything private in a site: everything published is public.

## Steps

1. **Pick a name and make sure it's free.** A 404 means nobody's using it:

   ```sh
   curl -s -o /dev/null -w '%{http_code}\n' https://NAME.reillywood.com/
   ```

   If it isn't 404, pick another name, unless Reilly asked you to update that site.

2. **Build the site** in a directory of its own.

3. **Upload every file.** Run this from inside the site's directory. `--remote` is
   required (without it wrangler writes to a local dev bucket). Content types are worked
   out from file extensions, so there's no need to set them. wrangler leaves a `.wrangler/`
   cache folder behind. The `find` skips dotfiles, so it's never uploaded, and you can
   delete it afterwards.

   ```sh
   find . -type f ! -path '*/.*' -printf '%P\n' | while read -r f; do
     wrangler r2 object put "reillywood-sites/NAME/$f" --file "$f" --remote
   done
   ```

   For a single file, upload it as `index.html`:

   ```sh
   wrangler r2 object put reillywood-sites/NAME/index.html --file page.html --remote
   ```

4. **Check it's live**, then give Reilly the URL:

   ```sh
   curl -s -o /dev/null -w '%{http_code}\n' https://NAME.reillywood.com/
   ```

## Updating and removing

- Re-uploading a path overwrites it. Files you no longer need are not removed
  automatically. Delete them one at a time:

  ```sh
  wrangler r2 object delete reillywood-sites/NAME/old.css --remote
  ```

- wrangler can't list a bucket's objects, so keep track of what you uploaded if you
  might need to delete it later.

## If something goes wrong

- `wrangler: command not found` or an auth error: wrangler needs to be installed and
  logged in to Reilly's Cloudflare account (`wrangler whoami`). Ask Reilly rather than
  trying to log in yourself.
- If the name doesn't resolve right after you check it, the local DNS cache may still hold
  an old answer. Test with `curl --resolve NAME.reillywood.com:443:104.21.16.103 …`.
- The Worker and setup live in Reilly's private `infra` repo under `static-sites/`.
