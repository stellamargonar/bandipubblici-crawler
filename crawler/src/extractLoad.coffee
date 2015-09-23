cheerio = require 'cheerio'
mongoose = require 'mongoose'
Call = (require './models/call.schema.js').Call
config = require '../config'
async = require 'async'
momentjs = require 'moment'
urlparse = require 'url'

amqp = require 'amqp'
config = require '../config'



class ExtractLoad

	constructor : ->
		# mongoose.connect ('mongodb://' + config.database.host + '/' + config.database.dbName)
		@_amqp_connection = amqp.createConnection config.amqp.config
		@_amqp_connection.on 'ready' , () =>
			# subscribe to extrator queue
			@_amqp_connection.queue config.amqp.queue.extractor , (extractor_queue) =>
				extractor_queue.subscribe (message) =>
					# process message
					source = message.source
					page = message.page
					# retrieve content
					@extractCallFromPage page, source.pattern, message.url, (call) =>
						console.log 'EXTRACTOR : Completed extracting call from page ' + message.url
						if call
							@loadCall call, (errors, results) =>
								console.error errors if errors
						# if source.test
						# 	@_amqp_connection.queue config.amqp.queue.test , (queue) =>
						# 		console.log 'EXTRACTOR : send test call'
						# 		@_amqp_connection.publish config.amqp.queue.test, call 
						# @_amqp_connection.queue config.amqp.queue.saveCall , (queue) =>
						# 	@_amqp_connection.publish config.amqp.queue.saveCall, call 


			# # subscribe to save call queue
			# @_amqp_connection.queue config.amqp.queue.saveCall , (save_queue) =>
			# 	save_queue.subscribe (message) =>
			# 		# process message , is a call
			# 		call = message
			# 		# retrieve content
			# 		@loadCall call, (error, result) =>
			# 			console.error error if error


	###
	given an html page, extracts the call present in the page 
	accordinlgy to a specific pattern
	@param page
	@param callback
	###
	extractCallFromPage : (page, patterns, sourceUrl, done) ->
		if !page
			throw new Error 'MISSING_PARAMETER page'
		if !patterns or !patterns.call or !patterns.title
			throw new Error 'MISSING_PARAMETER patterns call and title'
		if !done
			throw new Error 'MISSING_PARAMETER callback'

		if typeof page isnt 'string'
			throw new TypeError 'INVALID PARAMETER page content ' + page
		if typeof done isnt 'function'
			throw new TypeError 'INVALID PARAMETER callback'

		dom = cheerio.load page
		context = patterns.call

		call = {}

		for property, pattern of patterns
			if property is 'call'
				continue
			if (pattern.slice(-2) is ' a') or (pattern.indexOf('a[') isnt -1) or (pattern.indexOf('a:') isnt -1) or (pattern.indexOf('>a') isnt -1)
				call[property] = dom(pattern, context).attr('href')
			else
				if pattern.match '^\".+\"$'
					call[property] = pattern.replace /\"/g, ''
				else
					call[property] = dom(pattern, context).text()
		if !call.title
			return done undefined
		return done (@_clean call, sourceUrl)

	_clean : (call, sourceUrl) ->
		# convert date
		if call.expiration
			call.expiration = momentjs call.expiration, ["DD MMMM, YYYY", "DD/MM/YY" ], 'it'  
			if call.expiration <= (new Date())
				return undefined

		# fix url
		if call.url
			parsedUrl  = urlparse.parse call.url 
			if !parsedUrl.host # something is missing in the url.. 
				sourceParsedUrl = urlparse.parse sourceUrl
				call.url = sourceParsedUrl.protocol + '//' + sourceParsedUrl.host + parsedUrl.path

		# assign category
		if !call.type
			if 'amministra' in call.title.toLowerCase()
				call.type = 'amministrazione'
			else if 'didattica' in call.title.toLowerCase()
				call.type = 'didattica' 
			else if 'universit' in call.institution.toLowerCase()
				call.type = 'ricerca'



		return call

	###
	add a call to the database, checking if the call is already stored
	###
	loadCall : (call, done) ->
		if !call
			done undefined, undefined 

		# check if call is already in the database
		checkDuplicate = (call) =>
			(cb) =>
				Call.find {$or: [{url: call.url}, {title: call.title}]}, cb


		# otherwise clean & save it
		saveCall = (call) =>
			(duplicates, cb) =>
				# if any duplicates
				if duplicates and duplicates.length > 0
					Call.update {_id: duplicates[0]._id }, call, {upsert: true}, (err) ->
						return cb (err || undefined) , call
				else
					console.log 'No duplicate, create ' + call.title
					newCall = new Call call
					newCall.save (err, result) =>
						return cb (err || undefined), result
		async.waterfall [(checkDuplicate call), (saveCall call)], done






module.exports = ExtractLoad;