Crawler = require 'simplecrawler'
urlparse = require 'url'
request = require 'request'
async = require 'async'

amqp = require 'amqp'
config = require '../config'

parseXml = (require 'xml2js').parseString


class GenericCrawler
	constructor : () ->
		connection = amqp.createConnection config.amqp.config
		connection.on 'ready' , () =>
			@_amqp_connection = connection
			connection.queue config.amqp.queue.crawler , (crawler_queue) =>

				crawler_queue.subscribe (message) =>
					console.log 'CRAWLER : message received'
					# process message (a source)
					source = message
					# retrieve content
					@retrieveContent source, (error, pageResults) =>
						console.log 'CRAWLER : Completed crawling source ' + source.name

	# constructor : (options) ->
	# 	if !options.url or !options.pattern
	# 		throw new Error 'MISSING PARAMETER'
	# 	@url = options.url
	# 	@pattern = options.pattern

	# retrieveContent : (url, isUrlToFetchRegex, isUrlToSaveRegex, options={}, cb) ->
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
		console.log url
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
			console.log 'GOT ' + queueItem.url
			console.log responseBuffer.toString 'UTF8'
			# save page content only if it satisfies a certain condition
			if path.match isUrlToSaveRegex
				@_amqp_connection.queue config.amqp.queue.extractor , (queue) =>
					message =
						page : (responseBuffer.toString 'UTF8')
						source : source
						url : queueItem.url
					console.log 'CRAWLER : send page ' + queueItem.url 
					@_amqp_connection.publish config.amqp.queue.extractor, message, () ->
						console.log 'CRAWLER : Saved ' + queueItem.url
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
		# custom QUEUE (albo telematico)
		if source.name is 'Albo Telematico'
			console.log 'Custom queeu...'
			@_customQueue(cw)

		# manage RSS (for APSS)
		if url.match 'rss$'
			request.get url , (error, response, data) =>
				rssContent = data.toString 'UTF8'
				parseXml rssContent, (err, rssObject) =>
					# extract all the links
					linkFns = []

					getAndCrawlPage = (url) =>
						(cb1) =>
							console.log 'requesting ' + url
							request.get url, (err2, response2, data2) =>
								message =
									page : (data2.toString 'UTF8')
									source : source
									url : url
								
								@_amqp_connection.publish config.amqp.queue.extractor, message, {}, () ->
									console.log 'CRAWLER: saved'
								cb1 undefined, undefined	


					for item in rssObject.rss.channel[0].item
						if !item.link or !item.link[0] or !item.link[0].match '\/-\/concorso'
							continue
						linkFns.push (getAndCrawlPage item.link[0])
					async.series linkFns, cb
					# cw.queueURL aDiscoveredURL, queueItem
		else
			cw.start()


	_customQueue : (crawler) ->
		pageSize = 20
		baseUrl = 'http://www.albotelematico.tn.it/_site/_ajax/getTableAtti_v2.php?t=1&ta=concorsi&chiave_htaccess=bacheca&chiave_htaccess2=atto-pubb&iDisplayLength=' + pageSize + '&iDisplayStart='
		
		# create the urls for 25 pages
		for i in [1...25] by 1
			nextStart = i*pageSize
			crawler.queueURL (baseUrl + nextStart)
		console.log 'Queue ready'
		return 

	###
	runs the crawler for the given source giving the first round of test results, does not store anything in the system
	###
	# testSource: (source, done) =>
	# 	console.log 'testing source'
	# 	console.log source
	# 	@retrieveContent source.baseUrl, source.fetchRegex, source.saveRegex, source.options, (error, pageResults) =>
	# 		fns = []

	# 		requestExtract = (page) ->
	# 			body = 
	# 				page : page
	# 				patterns : source.pattern
	# 				baseUrl : source.baseUrl
	# 			(cb) =>
	# 				postOptions = 
	# 					body : JSON.stringify body
	# 					headers: {"Content-Type" : "application/json"}
	# 					url : 'http://localhost:5000/calls/extract'
	# 				request.post postOptions, (err, response, data) =>
	# 					if (typeof data) is 'string'
	# 						data = JSON.parse data
	# 					cb (err || undefined) , data
	# 		for url, page of pageResults
	# 			fns.push requestExtract(page)
	# 		async.parallel fns, done

module.exports = GenericCrawler;