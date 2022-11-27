# Suma

Suma is a platform and application for collective purchasing and local community empowerment.
It is focuses on the needs of low-income people, people of color,
and other frontline communities, who have traditionally be unserved by technology.

It is steered by [https://mysuma.org](https://mysuma.org),
a digital justice nonprofit.

Check out the [docs](https://github.com/lithictech/suma/tree/main/docs) folder for more info.

To get started, you can run:

```
make install
make reset-db
make migrate
make bootstrap-db
```

If you are only doing backend work,
you can use the embedded frontend, as explained in the "Infrastructure" section:

```
make build-frontends
make run
```

To work on the frontends, you need to be in the right folder:

```
make run # from the app root
# Open another terminal
cd webapp
make install
make start # Run a React dev server frontend against the running local backend
```


## Infrastructure

Right now, Suma is designed to be hosted on Heroku,
though it will be pretty simple to run it via Docker or other hosting platforms in the future.

Suma's backend is a Ruby server, and its frontends are Single Page Applications in React.
As explained in our [Guiding Technical Principals](https://github.com/lithictech/suma/blob/main/docs/index.md#guiding-principles),
we aim to minimize dependencies, so the Rack server actually serves the frontend.

This involves two non-obvious features in the codebase:

- Instead of building just a Ruby app, we also need the JavaScript toolchain available
  for building the React production build. So to build a production build,
  always use `make build-frontends`, which builds the React app into `./build-webapp`.
  The Rack app then serves that directory as static content at `/app`, as below.
  - NOTE: At build time, we template in some environment variables that are shared
    between the backend and frontend, like copying `RACK_ENV` into `NODE_ENV`,
    or `SENTRY_DSN` into `REACT_APP_SENTRY_DSN`. Because these values are
    *built into the JS at build time*, you MUST rebuild and redeploy the app
    these enviroment variables, or you'll just modify the backend.
- We have some custom Rack middleware for servering the React SPAs
  and other static assets ([see here](https://github.com/lithictech/suma/tree/main/lib/rack)).
  This allows us to have a "zero configuration" deployment.
  For a faster option, you can set up your reverse proxy (nginx or whatever)
  to serve the static assets instead.


## Auth

Auth with Suma is based exclusively on SMS verification rather than
an explicit registration and login step.

- Client POSTs to `/v1/auth/start` with a phone number.
- Server will create a Member if none exists with that phone number.
- Server no-ops if a Member already exists with that phone number.
- In both cases, the server dispatches a One Time Password (OTP) to the phone number.
- At this point, the client does *not* have an authenticated session.
- Client POSTS to `/v1/auth/verify` with the phone number and the OTP.
- If the phone number and OTP are valid, Server sets up an authenticated session.
- If they are invalid, Server returns an error.
- Client can POST to `/v1/auth/start` with the phone number again to dispatch
  a new OTP.


## Localization

### Frontend

We use the excellent i18next library for localization on the frontend.

Localization strings are stored in `webapp/public/locale`.
Right now only the public app is localized; the admin app is English-only,
but can be localized in the future.

We manage the localization JSON files with the following process:

- When we are developing a feature, it's fine to put strings directly into the JS.
- We then extract the strings and put them into `locale/en/strings.json`.
- Run `bundle exec rake i18n:format` to format locale files.
- Run `bundle exec rake i18n:prepare_csv[es] > spanish.csv`,
  which will write out a CSV with all the base (English) localization keys, English values,
  and language-specific values (Spanish in the case of 'es').
- Hand that file off to translators. They should fill in the 'Spanish' column.
- To load the translated strings back into Suma, run `cat spanish.csv | bundle exec rake i18n:import_csv`.
  This will overwrite `locale/es/strings.json` with the values parsed from the CSV.

### Longform Localization

In some cases, we have long-form content that can be expressed as normal Markdown,
and we do not need to build a custom page for it.

To do this, first, create a file like `locale/en/source/myfile.md`.

Then when you run `i18n:format` (as above), the file `locale/en/myfile.json` is automatically created/updated.
Re-run `make i18n-format` or the Rake task manually every time there is a Markdown file update.

Then use the `MarkdownContent` component to load it dynamically, or you can also load it directly directly
via `i18n.loadNamespaces(myfile)`.

To localize these files, you must manually create the appropriate locale-specific source files.
We do not automatically manage them with 18n commands, since they are pretty rare,
and updating them is not a developer-driven process that requires iteration.

So as an example, to localize `locale/en/source/myfile.md`, you must manually create
the file `/locale/fr/source/myfile.md`. Whenever you run `i18n-format`, it will automatically
create/update the appropriate resource files.
 
### Backend

Localization on the backend involves choosing the right column from the database.
We use a custom plugin, `Sequel::Plugins::TranslatedText`, for this
(eventually we'll break it into its own repository).
The way it works is:

- The frontend api module reads the language from `i18n.js` and 
  passes in an `Accept-Language` header.
- Rack middleware parses it, and sets the `SequelTranslatedText.language` thread local
  (it also sets the `Content-Language` response header).
- Various models have relations to the `Suma::TranslatedText` model,
  for example `products.name_id` is an FK to `translated_texts.id`.
- The `translated_texts` table has `es`, `en`, etc., columns for each supported language.
- When we access `Product#name`, it returns a `TranslatedText` instance.
  When we access `Product#name_string` or `Product#name#string`, it looks at the
  `SequelTranslatedText.language` value, and chooses the column based on that.
  - If the translated value isn't set, fall back to a default language.

There are a couple Rake tasks that dump the entire `translated_texts` table to a CSV,
and then allows it to be updated via CSV as well: `rake i18n:export_dynamic`
and `rake i18n:import_dynamic`.


## Images (and Uploaded Files)

Suma stores images in the database by default.
Given the choice between 1) a 3rd party dependency, 2) filesystems with backups,
or 3) a big database, we chose the last.

However, there is the ability for images to be stored in S3, R2, etc.
It isn't built out yet but will likely need to be in the future
to support larger Suma deployments.

The way images work is:

- There is an `blobs` table which stores the image bytes and a hash.
  The hash acts as a unique identifier for the bytes.
- This blobs table is NOT a normal application table. It can be in a separate database.
  This is important, for example, if the image table grows, and we do not want to back it up
  with the same semantics as the rest of the data.
- There is an `uploaded_files` table which stores the image metadata, like name and content type,
  and the location to the image blob. This can be the `blob_hash` (in which case we assume
  it is coming from the blobs table), or in the future, it can be a URL to the blob
  in a service like S3 or R2.
- When a resource with an image, like a product image, is returned, the value returned
  is the _image url_. The URL can be to our backend, or to S3, etc.
- The frontend makes an HTTP request to the suma backend to fetch the image.
  It can include some basic image processing constraints, like format and resolution,
  and the backend uses `libvips` to process the blob.

See `UploadedFile` for the code around blobs and file uploading.

See `API::Images` for the endpoints related to image uploads and image fetching.


## Logging and Error Handling

Logging is done as a standard [12 Factor App](https://12factor.net/),
which means we log to stdout. Further, we use structured logging via
[Semantic Logger](https://github.com/reidmorrison/semantic_logger).

For exception reporting, we use [Sentry](https://sentry.io/).
One of the important reasons for this choice is that Sentry can be
[self-hosted](https://develop.sentry.dev/self-hosted/) pretty easily.
That is, a minimal installation of Suma can self-host (or entirely forego) Sentry.
In the future, we can make exception handling services configurable,
but given Sentry's ubiquity, and self-hosting capability,
it seemed unnecessary.
