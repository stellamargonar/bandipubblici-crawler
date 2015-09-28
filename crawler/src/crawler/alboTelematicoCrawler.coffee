Crawler = require 'simplecrawler'
urlparse = require 'url'
cheerio = require 'cheerio'

amqp = require 'amqp'
config = require '../../config'

class AlboTelematicoCrawler
  ###
  This crawler uses the same implementation of the generic crawler, but customizes
  the way links are discovered in the body of a page, and the inital setup of the queue
  ###
  constructor : () ->
    connection = amqp.createConnection config.amqp.config
    connection.on 'ready' , () =>
      @_amqp_connection = connection

  retrieveContent : (source, cb) ->
    console.log 'CRAWLER ALBO : using custom Crawler Albo Telematico'
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

    # --- END of standard configuration ---

    cw.on 'fetchcomplete', (queueItem, responseBuffer, response) =>
      {path} = urlparse.parse queueItem.url

      # if the page is the list of calls
      if path.match '^\/\_site\/\_ajax\/getTableAtti\_v2\.php'
        # parse the content
        pageContent = responseBuffer.toString 'UTF8'
        pageObject = JSON.parse pageContent # page content is actually a JSON object, with HTML fields
        calls = pageObject.aaData

        # extract the link to the single call page
        for call in calls
          dom = cheerio.load call[0]
          callLink = (dom 'div div:first-child a:first-child').attr 'href'

          # add links to the queue
          cw.queueURL callLink, queueItem if callLink

      else
        # save page content only if it satisfies a certain condition
        if path.match isUrlToSaveRegex
          @_amqp_connection.queue config.amqp.queue.extractor , (queue) =>
            message =
              page : (responseBuffer.toString 'UTF8')
              source : source
              url : queueItem.url
            console.log 'CRAWLER : send page ' + queueItem.url
            @_amqp_connection.publish config.amqp.queue.extractor, message

    # setup of QUEUE
    @_customQueue(cw)

    # ok, now we're ready, START
    cw.start()


  _customQueue : (crawler) ->
    pageSize = 20
    baseUrl = 'http://www.albotelematico.tn.it/_site/_ajax/getTableAtti_v2.php?t=1&ta=concorsi&chiave_htaccess=bacheca&chiave_htaccess2=atto-pubb&iDisplayLength=' + pageSize + '&iDisplayStart='

    # create the urls for 25 pages
    for i in [0...20] by 1
      nextStart = i*pageSize
      crawler.queueURL (baseUrl + nextStart)
    return

module.exports = AlboTelematicoCrawler