# StopWatch

An interactive and visual exploration of distribution of shared state between Elixir processes on a node as well as via JSON/REST protocols to a web client.

Implements a "virtual stopwatch" with a Web UI that can be used to start, stop, reset, and change the timing/resolution of the stopwatch.  Multiple web clients can view and control the stopwatch simultaneously over links of various latencies and speeds.

This used to mostly be a playground for demonstrating Hub and HubRestApi, but it is now adapted to work with the experimental state pub/sub library [Informant](https://github.com/ghitchens/informant) as a way to explore Informant's characteristics as well as JSON/REST synchronization.  

It is the intent to completely replaced Hub and HubRestApi at some point in the future with Informant and an Informant-compatible HTTP layer, so this example will likely continue to evolve in that direction.  The Hub-based version has been archived in the "Hub" branch.

At this time, StopWatch is an exploration of the following technologies...

- Using [Informant](https://github.com/ghitchens/informant) to allow an Elixir
  process to publish rapid state updates, and respond to requests to change
  state (see lib/stopwatch/server.ex).
- Adapting Informant's notion of state change and updates to another system's
  notion of control and state change (lib/stopwatch/stopwatch/hub_adapter.ex)
- Using HTTP/REST/JSON transports to make requests and synchronize state with
  real time systems that share state among multiple clients, controlling a
  GenServer that implements Informant for both publishing state and control.
- Use of Angular/Javascript to build a UI that maps to an Informant server
  (for now, indirectly by HubRestAPI).
- Demonstrates use of elm-lang for client to HubRestAPI (work in progress).

## Building & Viewing On Your Machine

```sh
mix deps.get
mix run --no-halt
```

- Now, visit http://localhost:8888/
- Now, visit http://localhost:8888/ again in another web browser on your
  machine.
- Find out your machine's IP address and visit http://x.x.x.x:8888/ from
  another device on the same LAN -- perhaps an iphone or ipad?
- To view the elm version of the stopwatch UI (still a work in progress), go
  to http://localhost:8888/stopwatch.html. The elm version was built by
  running
  `elm make Stopwatch.elm --output=../web/stopwatch.html` from the `priv/elm` directory.

## See It Live (but slow)

  You can also see the demo on a test server, but because it is subject to the limitations of latencies, it is rather less impressive.

  http://104.131.9.126:8888/

  - Visit it with your web browser
  - Visit it in another window of your web browser
  - Visit it on your phone as well
  - To view the elm version of the stopwatch UI (still a work in progress), go
    to http://104.131.9.126:8888/stopwatch.html. The elm version was built by
    running
