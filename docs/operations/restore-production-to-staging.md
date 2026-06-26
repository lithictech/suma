## Restore Production DB to Staging

We can restore the production DB to staging,
and remove rows from non-admins.

First connect to a one-off dyno:

    $ heroku run bash --app=suma-staging

From the dyno:

```bash
set __OCWD=$PWD
mkdir -p /tmp/heroku-cli
cd /tmp/heroku-cli
curl -L https://cli-assets.heroku.com/heroku-linux-x64.tar.gz -o heroku.tar.gz
tar -xzf heroku.tar.gz
export PATH="/tmp/heroku-cli/heroku/bin:$PATH"
heroku --version
cd $__OCWD

heroku ps:scale web=0 worker=0 --app=suma-staging
export HEROKU_API_KEY=${SUMA_HEROKU_OAUTH_TOKEN}
heroku pg:backups:download --app suma-production -o /tmp/latest.dump

bundle exec rake release:restore_staging_db_from_dump[/tmp/latest.dump]
rm /tmp/latest.dump
heroku ps:scale web=1 worker=1 --app=suma-staging
```
