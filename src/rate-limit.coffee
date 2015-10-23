# Description
#   Middleware for adding rate limits to commands
#
# Configuration:
#   HUBOT_RATE_LIMIT_NOTIFY_PERIOD - how frequently to put rate limiting messages into chat (accounting done by listener)
#   HUBOT_RATE_LIMIT_CMD_PERIOD - how frequently to execute any single listener (can be overridden by the listener)
#
# Commands:
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   Michael Ansel <mansel@box.com>
#   Geoffrey Anderson <geoff@geoffreyanderson.net>

module.exports = (robot) ->
  # Map of listener ID to last time it was executed
  lastExecutedTime = {}
  # Map of listener ID to last time a reply was sent
  lastNotifiedTime = {}

  # Interval between mentioning that execution is rate limited
  if process.env.HUBOT_RATE_LIMIT_NOTIFY_PERIOD?
    notifyPeriodMs = parseInt(process.env.HUBOT_RATE_LIMIT_NOTIFY_PERIOD)*1000
  else
    notifyPeriodMs = 10*1000 # default: 10s

  robot.respond /debug rate limits/, {rateLimits:{minPeriodMs:0}}, (response) ->
    response.reply("""
      ```
      lastExecutedTime: #{JSON.stringify(lastExecutedTime, null, 4)}
      lastNotifiedTime: #{JSON.stringify(lastNotifiedTime, null, 4)}
      ```""")

  robot.listenerMiddleware (context, next, done) ->
    # Retrieve the listener id. If one hasn't been registered, fallback
    # to using the regex to uniquely identify the listener (even though
    # it is dirty).
    listenerID = context.listener.options?.id or context.listener.regex
    # Bail on unknown because we can't reliably track listeners
    return unless listenerID?
    try
      # Default to 1s unless listener or environment variable provides a
      # different minimum period (listener overrides win here).
      if context.listener.options?.rateLimits?.minPeriodMs?
        minPeriodMs = context.listener.options.rateLimits.minPeriodMs
      else if process.env.HUBOT_RATE_LIMIT_CMD_PERIOD?
        minPeriodMs = parseInt(process.env.HUBOT_RATE_LIMIT_CMD_PERIOD)*1000
      else
        minPeriodMs = 1*1000

      # Grab the room or user name that fired this listener.
      if context.response.message.user.room?
        roomOrUser = context.response.message.user.room
      else
        roomOrUser = context.response.message.user.name

      # Construct a key to rate limit on. If the response was from a room
      # then append the room name to the key. Otherwise, append the user name.
      listenerAndRoom = listenerID + "_" + roomOrUser
      # See if command has been executed recently in the same room (or with the same user)
      if lastExecutedTime.hasOwnProperty(listenerAndRoom) and
         lastExecutedTime[listenerAndRoom] > Date.now() - minPeriodMs
        # Command is being executed too quickly!
        robot.logger.debug "Rate limiting " + listenerID + " in " + roomOrUser + "; #{minPeriodMs} > #{Date.now() - lastExecutedTime[listenerAndRoom]}"
        # Notify at least once per rate limiting event
        myNotifyPeriodMs = minPeriodMs if notifyPeriodMs > minPeriodMs
        # If no notification sent recently
        if (lastNotifiedTime.hasOwnProperty(listenerAndRoom) and
            lastNotifiedTime[listenerAndRoom] < Date.now() - myNotifyPeriodMs) or
           not lastNotifiedTime.hasOwnProperty(listenerAndRoom)
          context.response.reply "Rate limit hit! Please wait #{minPeriodMs/1000} seconds before trying again."
          lastNotifiedTime[listenerAndRoom] = Date.now()
        # Bypass executing the listener callback
        done()
      else
        next () ->
          lastExecutedTime[listenerAndRoom] = Date.now()
          done()
    catch err
      robot.emit('error', err, context.response)
