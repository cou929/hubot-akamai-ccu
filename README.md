# hubot-akamai-ccu [![npm version](https://badge.fury.io/js/hubot-akamai-ccu.svg)](http://badge.fury.io/js/hubot-akamai-ccu) [![Build Status](https://travis-ci.org/cou929/hubot-akamai-ccu.svg?branch=master)](https://travis-ci.org/cou929/hubot-akamai-ccu)

A hubot scirpt that talks Akamai CCU REST API https://api.ccu.akamai.com/ccu/v2/docs/index.html

See [`src/akamai-ccu.coffee`](src/akamai-ccu.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-akamai-ccu --save`

Then add **hubot-akamai-ccu** to your `external-scripts.json`:

```json
["hubot-akamai-ccu"]
```

## Sample Interaction

```
user1> hubot akamai-ccu remove cache http://your.domain/foo on staging
hubot> Request accepted.
The request would be completed in 240 seconds.
You can check progress with `akamai-ccu purge status /ccu/v2/purges/foo-bar-baz`

user1> hubot akamai-ccu purge status /ccu/v2/purges/foo-bar-baz
hubot> originalEstimatedSeconds: 240
originalQueueLength: 0
purgeId: foo-bar-baz
purgeStatus: In-Progress
submittedBy: you@exmple.com
progressUri: /ccu/v2/purges/foo-bar-baz

user1> hubot akamai-ccu queue length
hubot> The queue length is 1
```

## Configuration

- `HUBOT_AKAMAI_CCU_USERNAME`
  - User name for API authentication. Required.
- `HUBOT_AKAMAI_CCU_PASSWORD`
  - Password for API authentication. Required.
- `HUBOT_AKAMAI_CCU_ALLOWED_URL_REGEXP`
  - Regexp pattern to allow to purge. Optional. Default to all url.
- `HUBOT_AKAMAI_CCU_ALLOWED_CPCODE`
  - Comma separated CP Codes to allow purge. Optional. Default to all CP Codes.
