.PHONY: help
.DEFAULT_GOAL := help

ifneq (, $(shell which ifconfig))
  LOCAL_NETWORK_IP := `ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`
else
  $(info ifconfig not found, figure out how to do this for your OS and add it here.)
endif
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
	@echo "Go to $(LOCAL_NETWORK_ADDR) on your device or scan this code, then press Enter:"
	@echo $(LOCAL_NETWORK_ADDR) | qrencode -t ANSI256 -m 1
	@read
