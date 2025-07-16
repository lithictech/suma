# Suma Localization

Localization is essential to many Suma use cases. There are a few components:

- `Suma::TranslatedText`: These rows contain the localized text translations for any dynamic text.
  For example, a `Program` has a `name` that is a `TranslatedText`.
- `Suma::I18n::StaticString`: These rows are added as required by the frontend or wherever static strings are needed.
  They can be edited through the admin app.
- The frontend requests localized strings for dynamic resources.
  For example, `Program.name` is returned as the localized string.
  See `expose_translated` for more info.
- The frontend requests the static string file when it loads, similiar to localization systems like `i18n.js`
- The `i18n.js` frontend library does interpolation of static strings.

## Static Localization

Dynamic localization is pretty straightforward- edit strings on a model in admin,
and it takes effect immediately since it is part of the resource representation.

Static strings though require an actual localization pipeline,
since they aren't attached to any particular resources.
This means they need both a dedicated editor, and a dedicated delivery mechanism (a static strings file).

The static string pipeline is:

- The files in `data/i18n/static_keys/strings.txt` file contains all the static string keys needed by the app.
  - There are multiple files here, and each is a 'namespace.'
  - Namespaces are loaded separately by the app to cut down on memory, like only loading the privacy policy strings
    when viewing that page.
- The release process upserts these keys, and marks any not-present rows deprecated.
- On the first request to `/v1/meta/static_strings/<locale>/<namespace>.json`, the static strings are written out
  for that local and namespace if needed (see below), and the file is served.
  - The file is also generated ahead of time in a background thread after startup,
    so it doesn't delay startup, and 'primes' the initial strings file request.
  - The time this happens is recorded.
- Whenever the text or another field is modified, `modified_at` is set.
- Every few minutes, a background thread wakes up. It checks the `max(modified_at)` on the static strings table.
  If `modified_at` is after the time the string file was generated, it regenerates the file.
- Static strings can be dumped to `data/i18n/static_strings_seed.json` through `dump_to_seed_file`.
- Static strings can be loaded from the seed file using `load_from_seed_file`.
  This is usually done during bootstrapping.

## Message Localization

Messages are another type of static string.
`Message::Templte` instances with `dynamic?` of `true`
will look up their content from the database rather than a file.
