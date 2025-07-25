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
    or `SENTRY_DSN` into `VITE_SENTRY_DSN`. Because these values are
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

## Messages

Preview messages using `make message-render`. This is by far the easiest way to preview changes
when iterating on message templates. Each message will fixture its own data.
Some examples:

Render the verification message using the default language (English) and transport (SMS):

```
MESSAGE=verification make message-render
*** Created MessageDelivery: {:id=>8, :created_at=>2022-11-27 06:27:16.268154 +0000, :updated_at=>nil, :template=>"verification", :transport_type=>"sms", :transport_service=>"twilio", :transport_message_id=>nil, :to=>"12719355065", :recipient_id=>13, :extra_fields=>{}, :sent_at=>nil, :aborted_at=>nil, :template_language=>"en"}

Your Suma verification code is: 016155
```

Render the verification message using a different language and transport:

```
MESSAGE_LANG=es MESSAGE_TRANSPORT=email MESSAGE=verification make message-render
*** Created MessageDelivery: {:id=>6, :created_at=>2022-11-27 06:26:39.478303 +0000, :updated_at=>nil, :template=>"verification", :transport_type=>"email", :transport_service=>"none", :transport_message_id=>nil, :to=>"arianna.senger@ankunding.io", :recipient_id=>11, :extra_fields=>{}, :sent_at=>nil, :aborted_at=>nil, :template_language=>"es"}

*******************
Hola Erasmo Waters!
*******************

Tu código de verificación de Suma es:

852606

Si no solicitó un código, póngase en contacto respondiendo a
este correo electrónico.

Suma

*** Writing HTML output to stdout.
*** Redirect it to a file (> temp.html), pass OUT to write it to a file (OUT=temp.html).

<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
<html><body>
<h1>Hola Erasmo Waters!</h1>
<p>Tu c&oacute;digo de verificaci&oacute;n de Suma es:</p>
<p>852606</p>
<p>Si no solicit&oacute; un c&oacute;digo, p&oacute;ngase en contacto respondiendo a este correo electr&oacute;nico.</p>
<p>Suma</p>
</body></html>
```

As the instructions say, if you attach something to stdout or pass `OUT`,
you can write out the HTML so it can be previewed.

NOTE: We currently don't send emails, so some parts of this pipeline are pretty basic.
We will need to add styling, message previewing through admin, and hook up the `EmailTransport`
to send (probably via SMTP so we aren't tied to a 3rd party).

## License

Licensed under [AGPL-3.0-or-later](/LICENSE).
