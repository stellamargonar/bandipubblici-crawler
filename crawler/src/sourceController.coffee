mongoose = require 'mongoose'
async = require 'async'
config = require '../config'
Source = (require './models/source.schema.js').Source
ObjectId = mongoose.Types.ObjectId;

genericCrawlerClass = require './genericCrawler.js'

class SourceController

	# Source = mongoose.model 'Source'

	constructor : () ->
#		mongoose.connect ('mongodb://' + config.database.host + '/' + config.database.dbName)

	###
	stores in the database the new source / or update if already existing
	given the properties in input
	###
	create : (object, done) ->
		if !object or !done or Object.keys(object).length is 0
			throw new Error 'MISSING PARAMETER'

		#  check if there is already a source witht he same name or baseUrl
		query = {}
		if object.name and object.baseUrl
			query = 
				$or : [
					{'name' : object.name},
					{'baseUrl' : object.baseUrl} 
				]
		else
			query.name = object.name if object.name
			query.baseUrl = object.baseUrl if object.baseUrl
		Source.find query, (err, docs) =>
			if docs && docs[0]
				if docs.length > 1
					# check if there are conflicts
					doc1 = docs[0].toObject()
					doc2 = docs[1].toObject()
					for key, property of object
						delete doc1[key]
						delete doc2[key]

					for key,property of doc1
						if key in ['_id', '__v']
							continue
						if doc2[key] isnt undefined and doc2[key] isnt doc1[key]
							return done 'Update Source conflict, for property ' + key + ' in sources ' + doc1._id + ', ' + doc2._id , undefined
					
					# update first doc
					funct1 = (d1,newDoc) ->
						(cb) =>
							Source.update {_id: d1._id}, newDoc, {upsert : true}, (err, res1) =>
								if !err and res1.ok is 1
									cb undefined, d1._id
								else
									cb (err|| 'No update'), d1._id

					# read updated doc
					funct2 = (id, cb) ->
						Source.findOne {_id: id}, (err, result) =>
							if result
								result = result.toObject()
								delete result._id
							cb err, result 

					# update second doc
					funct3 = (d1) ->
						(newDoc, cb) =>
							Source.update {_id: d1._id}, newDoc, {upsert : true}, (err, res1) =>
								if !err and res1.ok is 1
									cb undefined, d1._id
								else
									cb (err|| 'No update'), d1._id

					# delete (old) first doc
					funct4 = (idToDelete) ->
						(oldresult, cb) =>
							Source.remove {_id: idToDelete}, (err, result) =>
								return cb err, result

					idToDelete = doc1._id
					async.waterfall [funct1(doc1,object) , funct2, funct3(doc2), funct4(idToDelete)], (werrors, wresults) =>
						return done (werrors || undefined)

				else 
					doc = docs[0].toObject()
					Source.update {_id: doc._id}, object, {upsert: true}, (err, updatedResult) =>
						return done (err || undefined) 
			
			else
				newSource = new Source object
				newSource.save (err, result) =>
					return done (err || undefined)

	delete : (id, done) ->
		if !id or !done
			throw new Error 'MISSING PARAMETER'
		Source.remove {_id : id} , (err, res) =>
			if !res
				return done 'ID ' + id + ' does not exist'
			return done undefined

	readByName : (name, done) ->
		if !name or !done
			throw new Error 'MISSING PARAMETER'
		Source.find {name : name}, (err, res) =>
			return done (res[0] || undefined) 

	readByUrl : (url, done) ->
		if !url or !done
			throw new Error 'MISSING PARAMETER'
		Source.findOne {baseUrl : url}, (err, res) =>
			return done (res || undefined) 

	readById : (id, done) ->
		if !id or !done
			throw new Error 'MISSING PARAMETER'
		Source.findById new ObjectId(id), (err, res) =>
			console.log err
			return done (res || undefined) 

	readAll : (done) ->
		Source.find {} , (err, data) =>
			done err, data

	_getCrawler : () ->
		console.log 'Called Original Function'
		return new genericCrawlerClass()

	tryConfiguration : (source, done) ->
		if !source or !done or !source.baseUrl or !source.pattern.call
			throw new Error 'MISSING PARAMETER'

		crawler = @_getCrawler()
		crawler.testSource source, (errors, calls) ->
			console.log errors
			console.log calls
			done errors, calls






module.exports = SourceController