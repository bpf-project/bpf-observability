# BPF Observability Agents Guide

## Mandatory Graphify Review

Before making any change in this repository, inspect:

- this repo's `graphify-out/graph.json`
- the latest graphs for `bpf-application` and `bpf-groups-bridge` when the
  change may affect dashboards, alerts, or metrics contracts

This review is mandatory for every change. Observability work often tracks
other repos, so repo-local context alone is not enough.

## Context

- This repo stores Grafana dashboards, Prometheus config, and docs.
- Dashboard and alert changes should stay aligned with the services they watch.
- Keep edits minimal and avoid unrelated churn in generated JSON.
