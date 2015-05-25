# Description:
#   A hubot scirpt that talks Akamai CCU REST API https://api.ccu.akamai.com/ccu/v2/docs/index.html
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_AKAMAI_CCU_USERNAME: User name for API authentication. Required.
#   HUBOT_AKAMAI_CCU_PASSWORD: Password for API authentication. Required.
#   HUBOT_AKAMAI_CCU_ALLOWED_URL_REGEXP: Regexp pattern to allow to purge. Optional. Default to all url.
#   HUBOT_AKAMAI_CCU_ALLOWED_CPCODE: Comma separated CP Codes to allow purge. Optional. Default to all CP Codes.
#
# Commands:
#   hubot akamai-ccu remove cache <urls> [on production|staging] - Remove cache of <urls> (comma separated).
#   hubot akamai-ccu remove cache <CP Codes> [on production|staging] - Remove cache of <CP Codes> (comma separated).
#   hubot akamai-ccu invalidate cache <urls> [on production|staging] - Invalidate cache of <urls> (comma separated).
#   hubot akamai-ccu invalidate cache <CP Codes> [on production|staging] - Invalidate cache of <CP Codes> (comma separated).
#   hubot akamai-ccu purge status <progressUri> - Check purge status of <progressUri>.
#   hubot akamai-ccu queue length - Check length of the queue to purge objects.
#
# Notes:
#   If you specify `on staging` or `on production` with `remove or invalidate cache` command, hubot request to staging or production domain. Default to production.
#   Also check the official document of Akamai CCU REST API https://api.ccu.akamai.com/ccu/v2/docs/index.html
#
# Author:
#   Kosei Moriyama <cou929@gmail.com>

username = process.env.HUBOT_AKAMAI_CCU_USERNAME
password = process.env.HUBOT_AKAMAI_CCU_PASSWORD

if not username or not password
  console.log "Missing HUBOT_AKAMAI_CCU_USERNAME or HUBOT_AKAMAI_CCU_PASSWORD in environment"
  process.exit 1

allowed_url_pattern = undefined
if process.env.HUBOT_AKAMAI_CCU_ALLOWED_URL_REGEXP
  allowed_url_pattern = new RegExp process.env.HUBOT_AKAMAI_CCU_ALLOWED_URL_REGEXP

allowed_cpcodes = undefined
if process.env.HUBOT_AKAMAI_CCU_ALLOWED_CPCODE
  allowed_cpcodes = process.env.HUBOT_AKAMAI_CCU_ALLOWED_CPCODE.split(',').filter((code) -> code)

auth_header = 'Basic ' + new Buffer(username + ':' + password).toString('base64')

endpoints =
  purge_request: 'https://api.ccu.akamai.com/ccu/v2/queues/default'
  purge_status: 'https://api.ccu.akamai.com'
  queue_length: 'https://api.ccu.akamai.com/ccu/v2/queues/default'

send_request = (robot, endpoint, headers, cb, content) ->
  method = if content then 'post' else 'get'

  robot.http(endpoint).headers(headers)[method](content) (err, res, body) ->
    if err
      error_message = "Encountered an error #{err}"
      cb(error_message, null)
      return

    if res.statusCode < 200 or 300 <= res.statusCode
      error_message = "Encountered an error #{res.statusCode} #{body}"
      cb(error_message, null)
      return

    data = null
    try
      data = JSON.parse body
    catch error
      error_message = "JSON parse error #{body}"
      cb(error_message, null)
      return

    return cb(null, data)

send_purge_request = (robot, content, cb) ->
  headers =
    Authorization: auth_header
    'Content-Type': 'application/json'

  send_request(robot, endpoints.purge_request, headers, cb, content)

check_purge_status = (robot, progress_uri, cb) ->
  headers =
    Authorization: auth_header

  send_request(robot, endpoints.purge_status + progress_uri, headers, cb)

check_queue_length = (robot, cb) ->
  headers =
    Authorization: auth_header

  send_request(robot, endpoints.queue_length, headers, cb)

module.exports = (robot) ->

  robot.respond /akamai-ccu (remove|invalidate) cache (https?\S+|[\d,]+)( on staging)?/i, (msg) ->
    action = msg.match[1]
    objects = msg.match[2].split ','
    type = if /^\d+$/.test objects[0] then 'cpcode' else 'arl'
    domain = if msg.match[3] is ' on staging' then 'staging' else 'production'

    if type is 'arl'
      has_no_url_string = objects.some (url) -> not /^https?:\/\//.test url
      if has_no_url_string
        msg.send "Invalid url: #{objects}"
        return

    if type is 'arl' and allowed_url_pattern
      has_invalid_url = objects.some (url) -> not allowed_url_pattern.test url
      if has_invalid_url
        msg.send "Forbidden url: #{objects}"
        return

    if type is 'cpcode'
      has_no_cpcode_string = objects.some (code) -> not /^\d+$/.test code
      if has_no_cpcode_string
        msg.send "invalid CP Code: #{objects}"
        return

    if type is 'cpcode' and allowed_cpcodes
      has_invalid_cpcode = objects.some (code) -> allowed_cpcodes.indexOf(code) < 0
      if has_invalid_cpcode
        msg.send "Forbidden CP Code: #{objects}"
        return

    content = JSON.stringify(
      type: type
      action: action
      domain: domain
      objects: objects
    )

    send_purge_request(robot, content, (err, data) ->
      if err
        msg.send err
        return
      msg.send [
        "Request accepted.",
        "The request would be completed in #{data.estimatedSeconds} seconds.",
        "You can check progress with `akamai-ccu purge status #{data.progressUri}`"
      ].join("\n")
    )

  robot.respond /akamai-ccu purge status (\/\S+)/i, (msg) ->
    progress_uri = msg.match[1]
    check_purge_status(robot, progress_uri, (err, data) ->
      if err
        msg.send err
        return
      msg.send [
        "purgeStatus: #{data.purgeStatus}",
        "originalEstimatedSeconds: #{data.originalEstimatedSeconds}",
        "originalQueueLength: #{data.originalQueueLength}",
        "purgeId: #{data.purgeId}",
        "submittedBy: #{data.submittedBy}",
        "progressUri: #{data.progressUri}"
      ].join("\n")
    )

  robot.respond /akamai-ccu queue length/i, (msg) ->
    check_queue_length(robot, (err, data) ->
      if err
        msg.send err
        return
      msg.send "The queue length is #{data.queueLength}"
    )
