Crawler = require 'simplecrawler'
urlparse = require 'url'
request = require 'request'
async = require 'async'

class GenericCrawler
	constructor : () ->

	# constructor : (options) ->
	# 	if !options.url or !options.pattern
	# 		throw new Error 'MISSING PARAMETER'
	# 	@url = options.url
	# 	@pattern = options.pattern

	retrieveContent : (url, isUrlToFetchRegex, isUrlToSaveRegex, options={}, cb) ->
		if !url
			cb 'Empty Url', undefined
			return
		if (typeof url) isnt 'string'
			cb 'Invalid Url', undefined
			return

		# map containing url : content of the page
		pageContents = {}
		pageErrors = {}

		# split url in domain and path
		{protocol, hostname, path}  = urlparse.parse url 

		cw = new Crawler hostname

		cw.path = options.path || path
		cw.initialPath = cw.path
		cw.maxDepth = options.maxDepth || 4
		cw.initialProtocol = options.initialProtocol || protocol || 'http'
		cw.maxConcurrency = options.maxConcurrency || 1
		cw.userAgent = 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)'

		# add condition for urls to be followed and fetched
		cw.addFetchCondition (url) ->
			res = (url.path.match isUrlToFetchRegex) isnt null
			if res
				console.log url.path
			return res

		cw.on 'fetchcomplete', (queueItem, responseBuffer, response) =>
			console.log 'gott url ' + queueItem.url
			{path} = urlparse.parse queueItem.url
			# save page content only if it satisfies a certain condition
			if path.match isUrlToSaveRegex
				pageContents[queueItem.url] = (pageContents[queueItem.url] || '') + (responseBuffer.toString 'UTF8')

		cw.on 'fetcherror', (queueItem, response) ->
			pageErrors[queueItem.url] = response

		cw.on 'complete', () =>
			console.log Object.keys(pageContents)
			cb pageErrors, pageContents

		cw.start()


	###
	runs the crawler for the given source giving the first round of test results, does not store anything in the system
	###
	testSource: (source, done) =>

		@retrieveContent source.baseUrl, source.fetchRegex, source.saveRegex, source.options, (error, pageResults) =>
			fns = []

			requestExtract = (page) ->
				(cb) =>
					postOptions = 
						body : page
						headers: {"Content-Type" : "application/json"}
						url : 'calls/extract'
					request.post postOptions, (err, response, data) =>
						cb err, data

			for url, page of pageResults
				fns.push requestExtract(page)

			async.parallel fns, done

module.exports = GenericCrawler;