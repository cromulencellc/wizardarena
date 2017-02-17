# ti-server in Rails

This is a reimplmentation of the CGC ti-server from virtual-competition. It aims
to be compatible with the ti-client and provided integration tests while using a
Postgres backend.

# Models

## Challenge Set

name, canonical_sha256, secret

## Team

name, secret

## Score

denormalization of scoring data for performance, with built-in history

team_id, round_id, points

## Message

sender_id, recipient_id, read_at, name, body

## Round

nickname, seed, started_at, ended_at, finalized_at

## Enablement

challenge_set_id, round_id

## Candidate

team_id, enablement_id

## Crash

round_id, replacement_id, file_name, timestamp, signal

## Poll

team_id, enablement_id, perf_memory, perf_time, func_timeout, func_connect

## Replacement

team_id, round_id, challenge_set_id, file_name, sha256

## Pov

team_id, round_id, challenge_set_id, throws, victim_id

## Ruleset

team_id, round_id, challenge_set_id, file_name, sha256
