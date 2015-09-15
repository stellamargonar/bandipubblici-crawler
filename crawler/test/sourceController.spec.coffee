chai = require 'chai'
sinon = require 'sinon'
mongoose = require 'mongoose'

# get config for testing environment
process.env.NODE_ENV = 'testing'
config = require '../config'

# using compiled JavaScript file here to be sure module works
sourceControllerClass = require '../lib/sourceController.js'
Source = (require '../lib/models/source.schema.js').Source

expect = chai.expect
chai.use require 'sinon-chai'

describe 'sourceController', ->
    sourceController = null

    before (done) ->
      mongoose.connect ('mongodb://' + config.database.host + '/' + config.database.dbName), done
      sourceController = new sourceControllerClass()
 
    afterEach (done) ->
      Source.remove {}, () ->
        done()

    after (done) ->
      mongoose.connection.db.command { dropDatabase: 1 }, (err, result) ->
        mongoose.connection.close done


    describe 'create', ->
    	it 'should throw error when object is missing', ->
      	expect( -> sourceController.create() ).to.throw

      it 'should throw error when is missing the callback', ->
        expect( -> sourceController.create({})  ).to.throw

      it 'should throw error when is missing the source url and patterns properties in the object', ->
        expect( -> sourceController.create({}, () -> undefined) ).to.throw

      it 'should create the new source in db when url and patterns, and returned the db instance', (done)->
        object = 
          name: 'Test Source'
          baseUrl : 'http://www.google.it'
          protocol : 'http'
          pattern : 
            call: 'pattern_call'
            title : 'pattern_title'
            
        sourceController.create object, (err) =>
          expect(err).to.be.undefined
          Source.findOne {baseUrl: 'http://www.google.it'}, (dbErr, dbResult) =>
            expect(dbResult).to.be.not.null
            expect(dbResult._id).to.be.not.undefined
            done()

      it 'should update the source when one with the same name is present without overwriting missing properties', (done) ->
        objectOld = 
          name : 'Test'
          baseUrl : 'http://unitn.it/'
          protocol : 'http'
          pattern : 
            call : 'pattern_call'
            title : 'pattern_title'

        Source.create objectOld , () ->

          objectNew = 
            name : 'Test'
            baseUrl : 'http://unitn.it/jobs/'
            pattern :
              call : 'pattern_call1'
              title : 'pattern_title1'

          sourceController.create objectNew, (err) ->
            expect(err).to.be.undefined
            Source.findOne {name: 'Test'}, (dbErr, dbResult) ->
              expect(dbResult).to.be.not.undefined
              expect(dbResult.baseUrl).to.be.eql('http://unitn.it/jobs/')
              expect(dbResult.pattern.title).to.be.eql('pattern_title1')
              done()

      it 'should update the source when one with the same baseUrl is present without overwriting missing properties', (done) ->
        objectOld = 
          name : 'Test Old'
          baseUrl : 'http://unitn.it/'
          protocol : 'http'
          pattern : 
            call : 'pattern_call'
            title : 'pattern_title'

        Source.create objectOld , () ->

          objectNew = 
            name : 'Test New'
            baseUrl : 'http://unitn.it/'
            pattern :
              call : 'pattern_call1'
              title : 'pattern_title1'

          sourceController.create objectNew, (err) ->
            expect(err).to.be.undefined
            Source.findOne {baseUrl: 'http://unitn.it/'}, (dbErr, dbResult) ->
              expect(dbResult).to.be.not.undefined
              expect(dbResult.baseUrl).to.be.eql('http://unitn.it/')
              expect(dbResult.name).to.be.eql('Test New')
              expect(dbResult.pattern.title).to.be.eql('pattern_title1')
              done()

      it 'should update the source when one with the same baseUrl and one with same name is present without overwriting missing properties', (done) ->
        objectOld1 = 
          name : 'Test1'
          baseUrl : 'url1'
          pattern : 
            title : 'pattern_title1'

        objectOld2 =
          name : 'Test2'
          baseUrl : 'url2'

        objectNew = 
          name : 'Test1'
          baseUrl : 'url2'

        Source.create [objectOld1, objectOld2] , () ->
          sourceController.create objectNew, (err) ->
            expect(err).to.be.undefined
            Source.find {$or : [{name: 'Test1'}, {baseUrl: 'url2'}]}, (dbErr, dbResults) ->
              expect(dbResults).to.be.not.undefined
              expect(dbResults.length).to.be.eql(1)
              dbResult = dbResults[0]
              expect(dbResult.baseUrl).to.be.eql('url2')
              expect(dbResult.name).to.be.eql('Test1')
              expect(dbResult.pattern.title).to.be.eql('pattern_title1')
              done()


    describe 'delete' , ->
      it 'should throw error when id is missing', ->
        expect( -> sourceController.delete() ).to.throw

      it 'should throw error when callback is missing', ->
        expect( -> sourceController.delete('sda') ).to.throw

      it 'should return error when id does not exists in the db', (done) ->
        id = 'fake id'
        sourceController.delete id, (err) =>
          expect(err).to.be.not.undefined
          done()

      it 'should return undefined when id exists in the db, and delete the object', (done) ->
        object = 
          name: 'Test Source'
          baseUrl : 'http://www.google.it'
        
        Source.create object, (err, res) =>
          id = res._id
          sourceController.delete id, (err) =>
            expect(err).to.be.undefined
            Source.findOne {_id: id}, (err, res) =>
              expect(res).to.be.null
              done()


    describe 'readByName' , ->
      it 'should throw error when name is missing', ->
        expect( -> sourceController.readByName() ).to.throw

      it 'should throw error when callback is missing', ->
        expect( -> sourceController.readByName('name') ).to.throw

      it 'should return undefined when no source correspond to that name', (done) ->
        sourceController.readByName 'fakename', (res) ->
          expect(res).to.be.undefined
          done()

      it 'should return the one source corresponding to that name', (done) ->
        object = 
          name: 'Test Source'
          baseUrl : 'http://www.google.it'
          protocol : 'http'
          pattern : 
            call: 'pattern_call'
            title : 'pattern_title'
        Source.create object , (err, resDB) =>
          sourceController.readByName 'Test Source', (res) ->
            expect(res).to.be.not.undefined
            expect(res._id).to.be.eql(resDB._id)
            done()


    describe 'readByUrl' , ->
      it 'should throw error when name is missing', ->
        expect( -> sourceController.readByUrl() ).to.throw

      it 'should throw error when callback is missing', ->
        expect( -> sourceController.readByUrl('name') ).to.throw

      it 'should return undefined when no source correspond to that name', (done) ->
        sourceController.readByUrl 'www', (res) ->
          expect(res).to.be.undefined
          done()

      it 'should return the one source corresponding to that name', (done) ->
        object = 
          name: 'Test Source'
          baseUrl : 'www'
          protocol : 'http'
          pattern : 
            call: 'pattern_call'
            title : 'pattern_title'
        Source.create object , (err, resDB) =>
          sourceController.readByUrl 'www', (res) ->
            expect(res).to.be.not.undefined
            expect(res._id).to.be.eql(resDB._id)
            done()

















