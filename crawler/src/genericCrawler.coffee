Crawler = require 'simplecrawler'
urlparse = require 'url'

class GenericCrawler

	constructor : (options) ->
		if !options.url or !options.pattern
			throw new Error 'MISSING PARAMETER'
		@url = options.url
		@pattern = options.pattern

	retrieveContent : (url, isUrlToFetch, isUrlToSave, options={}, cb) ->
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
		cw.addFetchCondition(isUrlToFetch)

		cw.on 'fetchcomplete', (queueItem, responseBuffer, response) =>
			console.log 'gott url ' + queueItem.url

			# save page content only if it satisfies a certain condition
			if isUrlToSave queueItem.url
				pageContents[queueItem.url] = (pageContents[queueItem.url] || '') + (responseBuffer.toString 'UTF8')

		cw.on 'fetcherror', (queueItem, response) ->
			pageErrors[queueItem.url] = response

		cw.on 'complete', () =>
			console.log Object.keys(pageContents)
			cb pageErrors, pageContents

		cw.start()

module.exports = GenericCrawler;