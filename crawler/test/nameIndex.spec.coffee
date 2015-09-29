chai = require 'chai'
sinon = require 'sinon'

# get config for testing environment
process.env.NODE_ENV = 'testing'
config = require '../config'

# nock = require 'nock'
# using compiled JavaScript file here to be sure module works
nameIndexClass = require '../lib/nameIndex.js'

expect = chai.expect
chai.use require 'sinon-chai'

describe 'NameIndex', ->
  nameIndex = null

  beforeEach ->
    nameIndex = new nameIndexClass()

  describe 'insert', ->

    it 'should throw error when is missing key', ->
      expect( -> nameIndex.insert() ).to.throw('MISSING PARAMETER')
    it 'should return error when is missing value', ->
      expect( -> nameIndex.insert('ciao', '') ).to.throw('MISSING PARAMETER')
    it 'should return error when is missing callback', ->
      expect( -> nameIndex.insert('ciao', 'ciao') ).to.throw('MISSING PARAMETER')
    it 'should return error when callback is not a function', ->
      expect( -> nameIndex.insert('ciao', 'ciao', []) ).to.throw('Invalid Callback')

    it 'should return undefined when the data has been saved', (done)->
      nameIndex.insert key, value, (error) ->
        expect(error).to.be.undefined
        done()

    it 'should return error when key already exists', (done)->
      nameIndex.insert key, value, () ->
        nameIndex.insert key, value, (error) ->
          expect(error).to.be.not.undefined
          done()


