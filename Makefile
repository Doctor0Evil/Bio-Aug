.PHONY: ci fmt lint test

ci: fmt lint test

fmt:
	cargo fmt --all --check

lint:
	cargo clippy --all-targets --all-features -- -D warnings

test:
	RUST_BACKTRACE=1 cargo test --all-features
