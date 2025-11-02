.PHONY: test
test:
	flow test --cover --covercode="contracts" --coverprofile="coverage.lcov" ./tests/**/*_test.cdc

.PHONY: test-specific
test-specific:
	flow test --cover --covercode="contracts" --coverprofile="coverage.lcov" $(TEST_PATH)

.PHONY: ci
ci: test

.PHONY: clean
clean:
	rm -f coverage.lcov

.PHONY: deps
deps:
	flow deps install --skip-alias --skip-deployments

.PHONY: lint
lint:
	flow cadence lint ./contracts/**/*.cdc
	flow cadence lint ./tests/**/*.cdc
	flow cadence lint ./transactions/**/*.cdc

.PHONY: check
check: lint test

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  test          - Run all tests with coverage"
	@echo "  test-specific - Run specific test (use TEST_PATH=path/to/test)"
	@echo "  ci            - Run CI pipeline (same as test)"
	@echo "  clean         - Remove coverage files"
	@echo "  deps          - Install Flow dependencies"
	@echo "  lint          - Run Cadence linter on contracts and tests"
	@echo "  check         - Run lint and test"
	@echo "  help          - Show this help message"