Crawler = require 'simplecrawler'


class GenericCrawler

	constructor : (options) ->
		if !options.url or !options.pattern
			throw new Error 'MISSING PARAMETER'
		@url = options.url
		@pattern = options.pattern

	retrieveContent : (url, cb) ->
		if !url
			cb 'Empty Url', undefined
			return
		if (typeof url) isnt 'string'
			cb 'Invalid Url', undefined
			return

		cw = Crawler.crawl url
		cw.on 'fetchcomplete', (queueItem, responseBuffer, response) =>
			# console.log queueItem
			console.log responseBuffer.toString('UTF8')
			cw.start()
		cw.on 'complete', () =>

			cb undefined , 'content'


module.exports = GenericCrawler;