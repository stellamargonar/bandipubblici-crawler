chai = require 'chai'
sinon = require 'sinon'
pg = require 'pg'
# get config for testing environment
process.env.NODE_ENV = 'testing'
config = require '../config'
mongoose = require 'mongoose'

# nock = require 'nock'
# using compiled JavaScript file here to be sure module works
nameIndexClass = require '../lib/nameIndex.js'

expect = chai.expect
chai.use require 'sinon-chai'

Call = (require '../lib/models/call.schema.js').Call

describe 'NameIndex', ->
  nameIndex = null

  beforeEach ->
    nameIndex = new nameIndexClass()

  afterEach (done) ->
    pg.connect config.psDatabase , (err, client ) ->
      client.query 'DELETE FROM name_index', (err, res) ->
        client.end()
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

    it 'should return error when key already exists', (done)->
      key = 'ciao'
      value = 'value'
      nameIndex.insert key, value, () ->
        nameIndex.insert key, value, (error) ->
          expect(error).to.be.not.undefined
          done()


    it 'should return undefined when the data has been saved', (done)->
      key = 'ciao'
      value = 'value'
      nameIndex.insert key, value, (error) ->
        expect(error).to.be.undefined
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
      pg.connect config.psDatabase , (err, client ) ->
        connection = client

        insertQuery = 'INSERT INTO name_index (name, valid_name, validated) VALUES (\'prova\', \'test\', true) ; INSERT INTO name_index (name, valid_name, validated) VALUES (\'prova2\', \'test2\', false);'
        connection.query insertQuery, (err)->
          connection.end()
          nameIndex.getUnvalidated (results) ->
            expect(results).to.be.not.undefined
            expect(results).to.be.not.empty
            expect(results.length).to.be.eql 1
            expect(results[0]).to.be.eql({name : 'prova2', valid_name: 'test2'})
            done()

  describe 'find' , ->
    connection = undefined

    it 'should throw error when key is missing', ->
      expect( -> nameIndex.find() ).to.throw('Missing Parameter')

    it 'should throw error when callback is missing', ->
      expect( -> nameIndex.find('ciao') ).to.throw('Missing Parameter')
    it 'should throw error when callback is not a function', ->
      expect( -> nameIndex.find('ciao', []) ).to.throw('Invalid Callback')

    it 'should return empty array when there are no record in index', (done) ->
      nameIndex.find 'key', (results) ->
        expect(results).to.be.not.undefined
        expect(results).to.be.empty
        done()

    it 'should return empty array when there are no similar (valid) names in index', (done) ->
      insertQuery = 'INSERT INTO name_index (name, valid_name, validated) VALUES (\'prova\', \'test\', true) ; INSERT INTO name_index (name, valid_name, validated) VALUES (\'prova2\', \'test2\', false);'
      pg.connect config.psDatabase , (err, client ) ->
        client.query insertQuery, (err)->
          client.end()
          nameIndex.find 'key', (results) ->
            expect(results).to.be.not.undefined
            expect(results).to.be.empty
            done()

    it 'should return array containing the valid name if already in index', (done) ->
      insertQuery = 'INSERT INTO name_index (name, valid_name, validated) VALUES (\'prova\', \'test\', true) ; INSERT INTO name_index (name, valid_name, validated) VALUES (\'prova2\', \'test2\', false);'
      pg.connect config.psDatabase , (err, client ) ->
        client.query insertQuery, (err)->
          client.end()
          nameIndex.find 'test', (results) ->
            expect(results).to.be.not.undefined
            expect(results).to.be.not.empty
            expect(results[0]).to.be.eql('test')
            done()

    it 'should return array containing the valid name if already in index but in different (lower/upper/mixed) case', (done) ->
      insertQuery = 'INSERT INTO name_index (name, valid_name, validated) VALUES (\'prova\', \'test\', true) ; INSERT INTO name_index (name, valid_name, validated) VALUES (\'prova2\', \'test2\', false);'
      pg.connect config.psDatabase , (err, client ) ->
        client.query insertQuery, (err)->
          client.end()
          nameIndex.find 'TEST', (results) ->
            expect(results).to.be.not.undefined
            expect(results).to.be.not.empty
            expect(results[0]).to.be.eql('test')
            done()

    it 'should return array containing the valid name if the key differs of few letters with the valid name', (done) ->
      insertQuery = 'INSERT INTO name_index (name, valid_name, validated) VALUES (\'prova\', \'test\', true) ; INSERT INTO name_index (name, valid_name, validated) VALUES (\'prova2\', \'test2\', false);'
      pg.connect config.psDatabase , (err, client ) ->
        client.query insertQuery, (err)->
          client.end()
          nameIndex.find 'TESTA', (results) ->
            expect(results).to.be.not.undefined
            expect(results).to.be.not.empty
            expect(results[0]).to.be.eql('test')
            done()


  describe 'update' , ->

    before (done) ->
      mongoose.connect ('mongodb://' + config.database.host + '/' + config.database.dbName)
      done()

    after (done) ->
      mongoose.connection.db.command { dropDatabase: 1 }, (err, result) ->
        mongoose.connection.close done

    beforeEach (done) ->
      pg.connect config.psDatabase , (err, client) ->
        client.query 'insert into name_index values (\'key\', \'old_name\',false)', ()->
          client.end()
          done()

    afterEach (done) ->
      pg.connect config.psDatabase , (err, client) ->
        client.query 'delete from name_index', ()->
          client.end()
          done()

    it 'should throw error when is missing key', ->
      expect( -> nameIndex.update() ).to.throw('Missing Parameter')
    it 'should throw error when is missing value', ->
      expect( -> nameIndex.update('ciao') ).to.throw('Missing Parameter')
    it 'should throw error when is missing callback', ->
      expect( -> nameIndex.update('ciao', 'ciao') ).to.throw('Missing Parameter')
    it 'should throw error when callback is not a function', ->
      expect( -> nameIndex.update('ciao','ciao','ciao') ).to.throw('Invalid Callback')
    it 'should return error when no entry exists with the given key' , (done) ->
      nameIndex.update 'new key', 'ciao', (err) ->
        expect(err).to.be.not.undefined
        done()
    it 'should modify the record with the given key modifying the valid_name and set validated = true', (done) ->
      nameIndex.update 'key', 'new_name', (err) ->
        expect(err).to.be.undefined
        pg.connect config.psDatabase , (err, client) ->
          client.query 'select * from name_index where name=\'key\'', (err, res) ->
            client.end()
            expect(res.rows[0]).to.be.eql {name: 'key', valid_name: 'new_name', validated: true}
            done()

    it 'should propagate edit to institution name also to mongoDB (if entry present in this db)', (done) ->
      #prepare mongo
      call = new Call({title: 'TITOLO_test', institution: 'key'})
      call.save () ->
        nameIndex.update 'key', 'new_name', (err) ->

          expect(err).to.be.undefined

          # check mongo
          Call.findOne {title: 'TITOLO_test'}, (err, res) ->
            expect(res).to.be.not.undefined
            expect(res.institution).to.be.eql 'new_name'
            done()


  describe 'updateAll' , ->

    before (done) ->
      mongoose.connect ('mongodb://' + config.database.host + '/' + config.database.dbName)
      done()

    after (done) ->
      mongoose.connection.db.command { dropDatabase: 1 }, (err, result) ->
        mongoose.connection.close done

    beforeEach (done) ->
      pg.connect config.psDatabase , (err, client) ->
        client.query 'insert into name_index values (\'name\', \'old_valid\',false)', ()->
          client.end()
          done()

    afterEach (done) ->
      pg.connect config.psDatabase , (err, client) ->
        client.query 'delete from name_index', ()->
          client.end()
          done()

    it 'should throw error when is missing old value', ->
      expect( -> nameIndex.updateAll() ).to.throw('Missing Parameter')
    it 'should throw error when is missing new value', ->
      expect( -> nameIndex.updateAll('ciao') ).to.throw('Missing Parameter')
    it 'should throw error when is missing callback', ->
      expect( -> nameIndex.updateAll('ciao', 'ciao') ).to.throw('Missing Parameter')
    it 'should throw error when callback is not a function', ->
      expect( -> nameIndex.updateAll('ciao','ciao','ciao') ).to.throw('Invalid Callback')
    it 'should return error when no entry exists with the given old value' , (done) ->
      nameIndex.updateAll 'non_esiste', 'ciao', (err) ->
        expect(err).to.be.not.undefined
        done()

    it 'should update all the records with valid_name=old to valid_name=true', (done) ->
      nameIndex.updateAll 'old_valid', 'new_valid', (err) ->
        expect(err).to.be.undefined

        pg.connect config.psDatabase , (err, client) ->
          client.query 'select * from name_index where valid_name=\'old_valid\'', (err, res) ->
            expect(res.rows).to.be.empty
            client.query 'select * from name_index where valid_name=\'new_valid\'', (err, res) ->
              client.end()
              expect(res.rows).to.be.not.empty
              done()

    it 'should update the call with institution = old value with the new value', (done) ->
      call = new Call {title: 'TITOLO_call', institution: 'old_valid'}
      call.save () ->

        nameIndex.updateAll 'old_valid', 'new_valid', (err) ->
          expect(err).to.be.undefined
          Call.find {title: 'TITOLO_call'}, (err, calls) ->
            expect(calls).to.be.not.empty
            expect(calls[0].institution).to.be.eql('new_valid')
            done()
