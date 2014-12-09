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
