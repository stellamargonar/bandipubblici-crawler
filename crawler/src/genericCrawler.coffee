Crawler = require 'simplecrawler'
urlparse = require 'url'
request = require 'request'
async = require 'async'

amqp = require 'amqp'
config = require '../config'


class GenericCrawler
	constructor : () ->
		connection = amqp.createConnection config.amqp.config
		connection.on 'ready' , () =>
			@_amqp_connection = connection
			connection.queue config.amqp.queue.crawler , (crawler_queue) =>

				crawler_queue.subscribe (message) =>
					# process message (a source)
					source = message

					# get the custom crawler, if specified
					customCrawlerClass = require('./crawler/' + source.customCrawler + '.js') if source.customCrawler
					customCrawler = (new customCrawlerClass if customCrawlerClass) || this

					# retrieve content (using the specified crawler)
					customCrawler.retrieveContent source, (error, pageResults) =>
						console.log 'CRAWLER : Completed crawling source ' + source.name

	retrieveContent : (source, cb) ->
		if !source
			return cb 'Missing source', undefined
		url = source.baseUrl
		if !url
			return cb 'Empty Url', undefined
		if (typeof url) isnt 'string'
			return cb 'Invalid Url', undefined

		options = source.options || {}
		isUrlToFetchRegex = source.fetchRegex
		isUrlToSaveRegex = source.saveRegex

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
			{path} = urlparse.parse queueItem.url
			# save page content only if it satisfies a certain condition
			if path.match isUrlToSaveRegex
				@_amqp_connection.queue config.amqp.queue.extractor , (queue) =>
					message =
						page : (responseBuffer.toString 'UTF8')
						source : source
						url : queueItem.url
					console.log 'CRAWLER : send page ' + queueItem.url
					@_amqp_connection.publish config.amqp.queue.extractor, message
				# pageContents[queueItem.url] = (pageContents[queueItem.url] || '') + (responseBuffer.toString 'UTF8')

		cw.on 'fetcherror', (queueItem, response) ->
			console.log response
			pageErrors[queueItem.url] = response

		cw.on 'complete', () =>
			cb pageErrors, pageContents

		cw.on 'fetchredirect',  (queueItem, requestOptions) =>
			console.log 'fetching redirect'
			console.log queueItem.url

		cw.on 'fetch404',  (queueItem, requestOptions) =>
			console.log '404 fetching'
			console.log queueItem.url

		cw.start()


module.exports = GenericCrawler;