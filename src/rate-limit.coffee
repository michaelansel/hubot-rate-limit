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
    response.reply('lastExecutedTime: ' + JSON.stringify(lastExecutedTime))
    response.reply('lastNotifiedTime: ' + JSON.stringify(lastNotifiedTime))

  robot.listenerMiddleware (robot, context, next, done) ->
    # Fallback to regex even though it is dirty
    listenerID = context.listener.options?.id or context.listener.regex
    # Bail on unknown because we can't reliably track listeners
    return unless listenerID?
    try
      # Default to 1s unless listener provides a different minimum period
      if context.listener.options?.rateLimits?.minPeriodMs?
        minPeriodMs = context.listener.options.rateLimits.minPeriodMs
      else if process.env.HUBOT_RATE_LIMIT_CMD_PERIOD?
        minPeriodMs = parseInt(process.env.HUBOT_RATE_LIMIT_CMD_PERIOD)*1000
      else
        minPeriodMs = 1*1000

      # See if command has been executed recently
      if lastExecutedTime.hasOwnProperty(listenerID) and
         lastExecutedTime[listenerID] > Date.now() - minPeriodMs
        # Command is being executed too quickly!
        robot.logger.debug "Rate limiting " + listenerID + "; #{minPeriodMs} > #{Date.now() - lastExecutedTime[listenerID]}" 
        # Notify at least once per rate limiting event
        myNotifyPeriodMs = minPeriodMs if notifyPeriodMs > minPeriodMs
        # If no notification sent recently
        if (lastNotifiedTime.hasOwnProperty(listenerID) and
            lastNotifiedTime[listenerID] < Date.now() - myNotifyPeriodMs) or
           not lastNotifiedTime.hasOwnProperty(listenerID)
          context.response.reply "Rate limit hit! Please wait #{minPeriodMs/1000} seconds before trying again."
          lastNotifiedTime[listenerID] = Date.now()
        # Bypass executing the listener callback
        done()
      else
        next () ->
          lastExecutedTime[listenerID] = Date.now()
          done()
    catch err
      robot.emit('error', err, context.response)
