staging_app:=suma-staging
production_app:=suma-production

OUT ?= -

install:
	bundle install
cop:
	bundle exec rubocop
fix:
	bundle exec rubocop --auto-correct-all
fmt: fix

up:
	docker-compose up -d
up-staging: cmd-exists-heroku
	heroku ps:scale web=1 worker=1 --app=$(staging_app)
down:
	docker-compose stop
down-staging: cmd-exists-heroku
	heroku ps:scale web=0 worker=0 --app=$(staging_app)

release:
	bundle exec foreman start release
release-staging:
	MERGE_HEROKU_ENV=$(staging_app) bundle exec foreman start release

run:
	CUSTOMER_SKIP_EMAIL_VERIFICATION=true CUSTOMER_SKIP_PHONE_VERIFICATION=true bundle exec foreman start web
run-with-verification:
	bundle exec foreman start web
run-workers:
	bundle exec foreman start worker

migrate:
	bundle exec rake db:migrate
migrate-staging:
	MERGE_HEROKU_ENV=$(staging_app) bundle exec rake db:migrate
migrate-to-%:
	bundle exec rake db:migrate[$(*)]
migrate-staging-to-%:
	MERGE_HEROKU_ENV=$(staging_app) bundle exec rake db:migrate[$(*)]
migrate-app-to-%: env-APP
	MERGE_HEROKU_ENV=$(APP) bundle exec rake db:migrate[$(*)]

reset-db:
	bundle exec rake db:reset
reset-db-staging:
	MERGE_HEROKU_ENV=$(staging_app) bundle exec rake db:reset

reset-sidekiq-redis:
	bundle exec rake sidekiq:reset
reset-sidekiq-redis-staging:
	MERGE_HEROKU_ENV=$(staging_app) bundle exec rake sidekiq:reset

test:
	RACK_ENV=test bundle exec rspec spec/
	@./bin/notify "Tests finished"
testf:
	RACK_ENV=test bundle exec rspec spec/ --fail-fast --seed=1
	@./bin/notify "Tests finished"
migrate-test:
	RACK_ENV=test bundle exec rake db:drop_tables
	RACK_ENV=test bundle exec rake db:migrate
wipe-test-db:
	RACK_ENV=test bundle exec rake db:wipe

integration-test:
	INTEGRATION_TESTS=true RACK_ENV=development bundle exec rspec integration/
	@./bin/notify "Integration tests finished"
integration-test-staging:
	INTEGRATION_TESTS=true MERGE_HEROKU_ENV=$(staging_app) bundle exec rspec integration/
integration-test-task:
	INTEGRATION_TESTS=true bundle exec rake specs:integration

annotate:
	LOG_LEVEL=info bundle exec rake annotate

psql: cmd-exists-pgcli
	pgcli postgres://suma:suma@localhost:17005/suma
psql-test: cmd-exists-pgcli
	pgcli postgres://suma:suma@localhost:17006/suma_test
psql-%: cmd-exists-pgcli
	pgcli `heroku config:get DATABASE_URL --app=$($(*)_app)`
psql-app: env-APP cmd-exists-pgcli
	pgcli `heroku config:get DATABASE_URL --app=$(APP)`

pry:
	@bundle exec pry
pry-remote-%: cmd-exists-heroku
	heroku run 'bundle exec pry' --app $($(*)_app)
pry-app: env-APP
	MERGE_HEROKU_ENV=$(APP) bundle exec pry
pry-%:
	MERGE_HEROKU_ENV=$($(*)_app) bundle exec pry

message-render: env-MESSAGE
	@bundle exec rake 'message:render[$(MESSAGE), $(OUT)]'

take-production-db-snapshot:
	heroku pg:backups:capture --app $(production_app)

download-production-dump:
	@mkdir -p temp
	@rm -f latest.dump
	heroku pg:backups:download --app $(production_app)
	@mv latest.dump temp/latest.dump

restore-db-from-dump:
	@mkdir -p temp
	PGPASSWORD=suma pg_restore --clean --no-acl --no-owner -h 127.0.0.1 -p 17005 -U suma -d suma temp/latest.dump || true
	@./bin/notify "Finished restoring database from production"


reinit-db-from-dump:
	docker-compose down -v
	docker-compose up -d
	sleep 5
	make restore-db-from-dump
	@echo "Remember to migrate your test DB before running tests by running 'make migrate-test'"

goto-logging: cmd-exists-heroku
	heroku addons:open coralogix --app $(production_app)
goto-heroku:
	open 'https://dashboard.heroku.com/pipelines/fa5aa9ca-5544-41f3-957f-990aec652f43'
goto-production:
	open 'https://dashboard.heroku.com/apps/$(production_app)'
goto-staging:
	open 'https://dashboard.heroku.com/apps/$(staging_app)'
goto-sidekiq: cmd-exists-heroku
	open "https://`heroku config:get USERNAME --app=suma-sidekiq-dash`:`heroku config:get PASSWORD --app=suma-sidekiq-dash`@suma-sidekiq-dash.herokuapp.com"

env-%:
	@if [ -z '${${*}}' ]; then echo 'ERROR: variable $* not set' && exit 1; fi

cmd-exists-%:
	@hash $(*) > /dev/null 2>&1 || \
		(echo "ERROR: '$(*)' must be installed and available on your PATH."; exit 1)

register-address:
	bundle exec rake 'lob:register_address[Company Name,Address1,Address2,City,State,Zip]'

register-bank-account:
	bundle exec rake 'lob:register_bank_account[routing_number,account_number,signatory,account_type]'
