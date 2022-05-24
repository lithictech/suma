.PHONY: help
.DEFAULT_GOAL := help

check-version:
	@node tools/checkversion

install: check-version
	@npm install --legacy-peer-deps # See https://stackoverflow.com/questions/71713111/mui-installation-doesnt-work-with-react-18
test: check-version
	CI=true npm test
test-watch: check-version
	npm test

fmt: check-version
	npm run prettier-fix
fmt-check: check-version
	npm run prettier-check
lint: check-version
	npm run eslint-fix
lint-check:
	npm run eslint-check
check: fmt-check lint-check test

start: check-version
	npm start

sync-shared: check-version
	cp -r ../webapp/src/shared src
