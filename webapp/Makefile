.PHONY: help
.DEFAULT_GOAL := help

LOCAL_NETWORK_IP := `node tools/networkip.js`
LOCAL_NETWORK_ADDR := http://$(LOCAL_NETWORK_IP):22004

check-version:
	@node tools/checkversion

install: check-version
	npm install
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
	REACT_APP_CHAOS=0.5 npm start

start-network: check-version network-code
	BROWSER=none REACT_APP_API_HOST=http://$(LOCAL_NETWORK_IP):22001 npm start

network-code:
	@echo $(LOCAL_NETWORK_ADDR) | node node_modules/.bin/qrcode --small
	@echo "Go to $(LOCAL_NETWORK_ADDR) on your device or scan the above code, then press Enter."
	@read
