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

Dynamic localization is pretty straightforward: edit strings on a model in admin,
and it takes effect immediately since it is part of the resource representation.

Static strings though require an actual localization pipeline,
since they aren't attached to any particular resources.
This means they need both a dedicated editor and a dedicated delivery mechanism (a static strings file).

The static string pipeline is:

- The files in `data/i18n/seeds/<locale>/<namespace>.json` file contains all the static string keys needed by the app.
  - Namespaces are loaded separately by the app to cut down on memory,
    such as only loading the privacy policy strings when viewing that page.
- The release process calls `StaticStringRebuilder.import_seeds`.
  This adds keys from the missing seeds, with the given values, so when the app starts up,
  some initial value is present.
- Web app startup writes out a cache of static strings from the database,
  to the files it will serve to the frontend.
- The frontend calls `/v1/meta/static_strings/<locale>/<namespace>.json`,
  which returns the pregenerated file.
- Whenever the text or another field is modified, `modified_at` is set.
- Every few minutes, a background thread wakes up. It checks for `modified_at` of namespaces
  modified since the files were last generated. It regenerates namespace files as needed.
- When `Rebuilder.notify` is called, files on all web workers are regenerated.
  This uses PG LISTEN/NOTIFY under the hood.
- Static strings can be dumped to `data/i18n/static_strings_seed.json` through `make i18n-export`.
- Static strings can be loaded from the seed file using `make i18n-import` or `make i18n-replace`.

## Message Localization

Messages are another type of static string.
`Message::Template` instances with `dynamic?` of `true`
will look up their content from the database rather than a file.
Message template static strings are stored in the `messages` namespace.
