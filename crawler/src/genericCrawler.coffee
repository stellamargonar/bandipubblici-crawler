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
		cw.maxConcurrency = options.maxConcurrency || 2
		cw.userAgent = 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)'

		pagesFetching = []

		# add condition for urls to be followed and fetched
		cw.addFetchCondition (url) ->
			cond1 = (url.path.match isUrlToFetchRegex) isnt null
			# avoid cycles
			cond2 = url.path not in pagesFetching
			if (cond2)
				pagesFetching.push url.path
			cond1 and cond2

		cw.on 'fetchcomplete', (queueItem, responseBuffer, response) =>
			console.log 'Fetched ' + queueItem.url
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
		console.log 'testing source'
		console.log source
		@retrieveContent source.baseUrl, source.fetchRegex, source.saveRegex, source.options, (error, pageResults) =>
			fns = []

			requestExtract = (page) ->
				body = 
					page : page
					patterns : source.pattern
					baseUrl : source.baseUrl
				(cb) =>
					postOptions = 
						body : JSON.stringify body
						headers: {"Content-Type" : "application/json"}
						url : 'http://localhost:5000/calls/extract'
					request.post postOptions, (err, response, data) =>
						if (typeof data) is 'string'
							data = JSON.parse data
						cb (err || undefined) , data
			for url, page of pageResults
				fns.push requestExtract(page)
			async.parallel fns, done

module.exports = GenericCrawler;