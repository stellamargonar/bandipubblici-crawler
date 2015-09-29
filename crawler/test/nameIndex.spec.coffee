chai = require 'chai'
sinon = require 'sinon'
mysql = require 'mysql'

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

  afterEach (done) ->
    connection = mysql.createConnection config.mysqlDatabase
    connection.connect () ->
      connection.query 'delete from name_index', ()->
        done()

  describe 'insert', ->

    it 'should throw error when is missing key', ->
      expect( -> nameIndex.insert() ).to.throw('Missing Parameter')
    it 'should return error when is missing value', ->
      expect( -> nameIndex.insert('ciao', '') ).to.throw('Missing Parameter')
    it 'should return error when is missing callback', ->
      expect( -> nameIndex.insert('ciao', 'ciao') ).to.throw('Missing Parameter')
    it 'should return error when callback is not a function', ->
      expect( -> nameIndex.insert('ciao', 'ciao', []) ).to.throw('Invalid Callback')

    it 'should return undefined when the data has been saved', (done)->
      key = 'ciao'
      value = 'value'
      nameIndex.insert key, value, (error) ->
        expect(error).to.be.undefined
        done()

    it 'should return error when key already exists', (done)->
      key = 'ciao'
      value = 'value'
      nameIndex.insert key, value, () ->
        nameIndex.insert key, value, (error) ->
          expect(error).to.be.not.undefined
          done()

  describe 'get', ->
    it 'should throw error when is missing key', ->
      expect( -> nameIndex.get() ).to.throw('Missing Parameter')
    it 'should throw error when is missing callback', ->
      expect( -> nameIndex.get('ciao') ).to.throw('Missing Parameter')
    it 'should throw error when callback is not a function', ->
      expect( -> nameIndex.get('ciao', 'ciao') ).to.throw('Invalid Callback')

    it 'should return undefined when key is not in the database', (done) ->
      nameIndex.get 'missing key', (res) ->
        expect(res).to.be.undefined
        done()
    it 'should return the value associated to the given key when present', (done) ->
      nameIndex.insert 'key', 'value', () ->
        nameIndex.get 'key', (res) ->
          expect(res).to.be.not.undefined
          expect(res).to.be.eql 'value'
          done()

  describe 'getUnvalidated' , ->
    it 'should throw error when callback is not a function', ->
      expect( -> nameIndex.getUnvalidated [] ).to.throw('Invalid Callback')

    it 'should return empty array when there are no unvalidated records', (done) ->
      nameIndex.getUnvalidated (results) ->
        expect(results).to.be.not.undefined
        expect(results).to.be.empty
        done()

    it 'should return only the records that are not validated', (done) ->
      conf = config.mysqlDatabase
      conf.multipleStatements= true
      connection = mysql.createConnection conf

      connection.connect () ->
        insertQuery = 'INSERT INTO name_index (name, valid_name, validated) VALUES (\'prova\', \'test\', true) ; INSERT INTO name_index (name, valid_name, validated) VALUES (\'prova2\', \'test2\', false);'
        connection.query insertQuery, (err)->
          connection.end()
          nameIndex.getUnvalidated (results) ->
            expect(results).to.be.not.undefined
            expect(results).to.be.not.empty
            expect(results.length).to.be.eql 1
            expect(results[0]).to.be.eql({name : 'prova2', valid_name: 'test2'})
            done()