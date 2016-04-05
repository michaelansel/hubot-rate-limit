# hubot-rate-limit

Middleware for adding rate limits to commands

See [`src/rate-limit.coffee`](src/rate-limit.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-rate-limit --save`

Then add **hubot-rate-limit** to your `external-scripts.json`:

```json
[
  "hubot-rate-limit"
]
```

## Configuration

`HUBOT_RATE_LIMIT_NOTIFY_PERIOD` - default interval (seconds) between posting rate limiting messages in chat
`HUBOT_RATE_LIMIT_CMD_PERIOD` - default interval (seconds) between each invocation of a specific listener
`HUBOT_RATE_LIMIT_NOTIFY_MSG` - message to be sent when user has exceeded rate limit

`HUBOT_RATE_LIMIT_CMD_PERIOD` can be overridden using listener options:
```coffeescript
robot.hear /hi/, {rateLimits:{minPeriodMs:1000}} (msg) ->
  # stuff that will only be executed once per second
```

A rate limit period of 0 effectively means as fast as possible.

If notify period is greater than command period, then the notify period is lowered down to the command period. This is so that there is always at least one notification per transition from allowed to limiting.

## Sample Interaction

```
user1>> hubot hello
hubot>> hello!
user1>> hubot hello
hubot>> Rate limit hit! Please wait 5 seconds before trying again.
user1>> hubot hello
(no response)
user1>> hubot hello
(no response)
(wait 5 seconds)
user1>> hubot hello
hubot>> hello!
```

## Known Issues

If you are using the hubot-history script, it adds a catch-all listener that hubot-rate-limit then applies rate limiting to. This will result in spurious rate limiting messages and patchy logs (only one log message every second).
