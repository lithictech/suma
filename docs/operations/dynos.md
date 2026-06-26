
## Restore Production DB to Staging

From local:

    $ heroku run bash --app=suma-staging

From the dyno:

```bash
set __X=$PWD
mkdir -p /tmp/heroku-cli
cd /tmp/heroku-cli
curl -L https://cli-assets.heroku.com/heroku-linux-x64.tar.gz -o heroku.tar.gz
tar -xzf heroku.tar.gz
export PATH="/tmp/heroku-cli/heroku/bin:$PATH"
heroku --version
cd ~

export HEROKU_API_KEY=<get this from https://dashboard.heroku.com/account/applications>
heroku pg:backups:download --app suma-production -o /tmp/latest.dump

bundle exec rake release:restore_staging_db_from_dump[/tmp/latest.dump]
```