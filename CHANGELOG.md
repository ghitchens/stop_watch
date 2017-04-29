# Changelog

## v0.2.0 (April 28, 2017)

- Stopwatch implementation now based on Informant.  The Stopwatch Server knows
  nothing about Hub, and all it's state change requests and notifications are
  handled by Informant.
- Added `hub_adapter` to allow REST/JSOn to continue to work until we replace
  HubRestApi with something else.
- Updated README and docs

## v0.0.1 (2016)

- added elm client

## v0.0.0 (2014) 

- initial implemenatation and Angular Client based on Hub and HubRestApi
