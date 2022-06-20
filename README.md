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
