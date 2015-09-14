cheerio = require 'cheerio'

class ExtractLoad

	constructor : ->


	###
	given an html page, extracts the call present in the page 
	accordinlgy to a specific pattern
	@param page
	@param callback
	###
	extractCallFromPage : (page, patterns, done) ->
		if !page or !page.content
			throw new Error 'MISSING_PARAMETER page'
		if !patterns or !patterns.call or !patterns.title
			throw new Error 'MISSING_PARAMETER patterns call and title'
		if !done
			throw new Error 'MISSING_PARAMETER callback'

		if typeof page.content isnt 'string'
			throw new TypeError 'INVALID PARAMETER page content ' + page.content
		if typeof done isnt 'function'
			throw new TypeError 'INVALID PARAMETER callback'

		dom = cheerio.load page.content
		context = patterns.call

		call = {}

		for property, pattern of patterns
			if property is 'call'
				continue
			if pattern.slice(-2) is ' a'
				call[property] = dom(pattern, context).attr('href')
			else
				call[property] = dom(pattern, context).text()
		
		if !call.title
			return done undefined

		return done call


	###
	add a call to the database, checking if the call is already stored
	###
	loadCall : (call, done) ->







module.exports = ExtractLoad;