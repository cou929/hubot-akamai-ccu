chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'akamai-ccu', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()

    process.env.HUBOT_AKAMAI_CCU_USERNAME = 'username'
    process.env.HUBOT_AKAMAI_CCU_PASSWORD = 'password'

    require('../src/akamai-ccu')(@robot)

  it 'compiles', ->
    true
