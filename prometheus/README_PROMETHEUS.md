# Prometheus examples

This directory contains example Prometheus scrape configs and metric templates used by the daily research scripts.

Files:
- `daily_scrape_config.example.yml` — example scrape config for daily nodes
- `cyberaug_daily_scrape_config.example.yml` — example scrape config for cybernetic daily nodes
- `cyberaug_adjacent_scrape_config.example.yml` — scrape config for adjacent-domain nodes

The `tools/daily_*` scripts generate daily metrics templates under `prometheus/` automatically, but storing example configs here makes it easy to reuse them in CI or local testing.

To include the metrics in your cluster, copy the example scrape config(s) into your Prometheus config and restart your Prometheus server or reload the config.
