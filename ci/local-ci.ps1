param(
    [switch]$SkipFmt,
    [switch]$SkipClippy,
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"

if (-not $SkipFmt) {
    cargo fmt --all --check
}

if (-not $SkipClippy) {
    cargo clippy --all-targets --all-features -- -D warnings
}

if (-not $SkipTests) {
    $env:RUST_BACKTRACE = "1"
    cargo test --all-features
}
