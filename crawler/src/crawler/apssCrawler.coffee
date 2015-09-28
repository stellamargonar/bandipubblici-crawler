request = require 'request'
async = require 'async'

amqp = require 'amqp'
config = require '../../config'

parseXml = (require 'xml2js').parseString
#Crawler = require 'simplecrawler'


class ApssCrawler

  constructor : () ->
    connection = amqp.createConnection config.amqp.config
    connection.on 'ready' , () =>
      @_amqp_connection = connection

  retrieveContent : (source, done) ->
    if !source
      return cb 'Missing source', undefined
    url = source.baseUrl
    if !url
      return cb 'Empty Url', undefined
    if (typeof url) isnt 'string'
      return cb 'Invalid Url', undefined


    request.get url , (error, response, data) =>
      rssContent = data.toString 'UTF8'
      parseXml rssContent, (err, rssObject) =>

        # extract all the links
        linkFns = []

        getAndCrawlPage = (url) =>
          (cb1) =>
            request.get url, (err2, response2, data2) =>

              # send message for parsing page to the extractor
              message =
                page : (data2.toString 'UTF8')
                source : source
                url : url
              @_amqp_connection.publish config.amqp.queue.extractor, message, {}
              cb1 undefined, undefined

        # prepare requests for single call pages
        for item in rssObject.rss.channel[0].item
          if !item.link or !item.link[0] or !item.link[0].match '\/-\/concorso'
            continue
          linkFns.push (getAndCrawlPage item.link[0])

        async.series linkFns, done

  module.exports = ApssCrawler