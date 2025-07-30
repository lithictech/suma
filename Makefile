.PHONY: build build-webapp build-adminapp

staging_app:=suma-staging
production_app:=suma-production

OUT ?= -
MESSAGE_LANG ?=
MESSAGE_TRANSPORT ?=

install:
	bundle install
cop:
	bundle exec rubocop
fix:
	bundle exec rubocop --autocorrect-all
fmt: fix
fmt-all:
	@make fmt
	@cd webapp && make fmt && make lint
	@cd adminapp && make fmt && make lint
audit:
	@bundle-audit check || echo "Try running 'bundle update --conservative <gem>' on vulnerable gems to update just the Gemfile.lock"

up:
	docker compose up -d
up-staging: cmd-exists-heroku
	heroku ps:scale web=1 worker=1 --app=$(staging_app)
down:
	docker compose stop
down-staging: cmd-exists-heroku
	heroku ps:scale web=0 worker=0 --app=$(staging_app)

release:
	bundle exec foreman start release
release-staging:
	MERGE_HEROKU_ENV=$(staging_app) bundle exec foreman start release

run:
	WEB_CONCURRENCY=0 bundle exec foreman start web
run-cluster:
	WEB_CONCURRENCY=2 bundle exec foreman start web
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
bootstrap-db:
	bundle exec rake bootstrap
reinit-staging-db:
	heroku ps:scale web=0 worker=0 --app $(staging_app)
	heroku pg:reset --app=$(staging_app) --confirm=$(staging_app)
	MERGE_HEROKU_ENV=$(staging_app) bundle exec foreman start release
	MERGE_HEROKU_ENV=$(staging_app) bundle exec rake bootstrap[true]
	heroku ps:scale web=1 worker=1 --app $(staging_app)
	@echo "Randomizing passwords for all users:"
	@MERGE_HEROKU_ENV=$(staging_app) bundle exec rake release:randomize_passwords

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

find-unused-associations:
	bundle exec ruby bin/find-unused-associations

integration-test:
	INTEGRATION_TESTS=true RACK_ENV=development bundle exec rspec integration/
	@./bin/notify "Integration tests finished"
integration-test-staging:
	INTEGRATION_TESTS=true MERGE_HEROKU_ENV=$(staging_app) bundle exec rspec integration/
integration-test-task:
	INTEGRATION_TESTS=true bundle exec rake specs:integration

annotate:
	RACK_ENV=test LOG_LEVEL=info bundle exec rake annotate

psql: cmd-exists-pgcli
	pgcli postgres://suma:suma@localhost:22005/suma
psql-test: cmd-exists-pgcli
	pgcli postgres://suma:suma@localhost:22006/suma_test
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
	@bundle exec rake 'message:render[$(MESSAGE), $(OUT), $(MESSAGE_LANG), $(MESSAGE_TRANSPORT)]'

i18n-import:
	@bundle exec rake i18n:import

i18n-export:
	@bundle exec rake i18n:export

analytics-reimport:
	@bundle exec rake analytics:truncate
	@bundle exec rake analytics:import

take-production-db-snapshot:
	heroku pg:backups:capture --app $(production_app)

download-production-dump:
	@mkdir -p temp
	@rm -f latest.dump
	heroku pg:backups:download --app $(production_app)
	@mv latest.dump temp/latest.dump

restore-db-from-dump:
	@mkdir -p temp
	@PGPASSWORD=suma psql postgres://suma:suma@localhost:22005/suma -c "CREATE SCHEMA IF NOT EXISTS heroku_ext; ALTER DATABASE suma SET search_path TO public,heroku_ext;"
	PGPASSWORD=suma pg_restore --clean --no-acl --no-owner -h 127.0.0.1 -p 22005 -U suma -d suma temp/latest.dump || true
	@PGPASSWORD=suma psql postgres://suma:suma@localhost:22005/suma -c "ALTER EXTENSION citext SET SCHEMA public"
	@bundle exec rake release:prepare_prod_db_for_testing
	@./bin/notify "Finished restoring database from production"


reinit-db-from-dump:
	docker compose down -v
	docker compose up -d
	sleep 5
	make restore-db-from-dump
	@echo "Remember to migrate your test DB before running tests by running 'make migrate-test'"

build-webapp:
	@bundle exec rake frontend:build_webapp

build-adminapp:
	@bundle exec rake frontend:build_adminapp

build-frontends: build-webapp build-adminapp ## Build the JS frontends and place them into their location so they can be served by Rack

goto-logging: cmd-exists-heroku
	heroku addons:open coralogix --app $(production_app)
goto-heroku:
	open 'https://dashboard.heroku.com/pipelines/e6dc59e6-757c-462f-bd72-15f48b2064d1'
goto-production:
	open 'https://dashboard.heroku.com/apps/$(production_app)'
goto-staging:
	open 'https://dashboard.heroku.com/apps/$(staging_app)'
goto-sidekiq: cmd-exists-heroku
	open "https://`heroku config:get ASYNC_WEB_USERNAME --app=$(production_app)`:`heroku config:get ASYNC_WEB_PASSWORD --app=$(production_app)`@$(production_app).herokuapp.com/sidekiq"
goto-sidekiq-staging: cmd-exists-heroku
	open "https://`heroku config:get ASYNC_WEB_USERNAME --app=$(staging_app)`:`heroku config:get ASYNC_WEB_PASSWORD --app=$(staging_app)`@$(staging_app).herokuapp.com/sidekiq"

env-%:
	@if [ -z '${${*}}' ]; then echo 'ERROR: variable $* not set' && exit 1; fi

cmd-exists-%:
	@hash $(*) > /dev/null 2>&1 || \
		(echo "ERROR: '$(*)' must be installed and available on your PATH."; exit 1)
