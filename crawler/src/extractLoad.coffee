cheerio = require 'cheerio'
mongoose = require 'mongoose'
Call = (require './models/call.schema.js').Call
config = require '../config'
async = require 'async'
momentjs = require 'moment'
urlparse = require 'url'

amqp = require 'amqp'
config = require '../config'

nameIndexModule = (require './nameIndex.js')

class ExtractLoad

  constructor: ->
    @_amqp_connection = amqp.createConnection config.amqp.config
    @_amqp_connection.on 'ready', () =>
      # subscribe to extrator queue
      @_amqp_connection.queue config.amqp.queue.extractor, (extractor_queue) =>
        extractor_queue.subscribe (message) =>
          # process message
          source = message.source
          page = message.page
          # retrieve content
          @extractCallFromPage page, source.pattern, message.url, (calls) =>
#            console.log 'EXTRACTOR : Completed extracting call (' + calls.length + ') from page ' + message.url
            console.error 'Cannot extract call' if !calls
            return if !calls

            fns = []
            (fns.push (@loadCall call)) for call in calls
            async.series fns, (errors) ->
              console.error errors if errors



  nameIndexInstance = null
  getNameIndex : () ->
    nameIndexInstance ?= new nameIndexModule()
    return nameIndexInstance


  ###
  given an html page, extracts the call present in the page
  accordinlgy to a specific pattern
  @param page
  @param callback
  ###

  extractCallFromPage: (page, patterns, provenanceUrl, done) ->
    if !page
      throw new Error 'MISSING_PARAMETER page'
    if !patterns or !patterns.call or !patterns.title
      throw new Error 'MISSING_PARAMETER patterns call and title'
    if !done
      throw new Error 'MISSING_PARAMETER callback'

    if typeof page isnt 'string'
      throw new TypeError 'INVALID PARAMETER page content '
    if typeof done isnt 'function'
      throw new TypeError 'INVALID PARAMETER callback'

    dom = cheerio.load page
    context = patterns.call

    calls = []
    calls.push {}   for elem in dom(patterns.call)
    call = {}

    for property, pattern of patterns
      if property is 'call'
        continue
      values = []

      processMultiCall = (pattern , map, arg = undefined) =>
        domTag = dom(pattern, context)
        domTag.each (i, elem) =>
          values.push dom(elem)[map](arg)
        calls = @_arrayMap calls, values, property

      # pattern contains link
      if (pattern.slice(-2) is ' a') or (pattern.indexOf('a[') isnt -1) or (pattern.indexOf('a:') isnt -1) or (pattern.indexOf('>a') isnt -1)
        processMultiCall pattern, 'attr', 'href'

      # pattern is exact value
      else if pattern.match '^\".+\"$'
        (values.push (pattern.replace /\"/g, ''))  for i in [0...(calls.length)]
        calls = @_arrayMap calls, values, property
      # normal case
      else
        processMultiCall pattern, 'text'

    if calls.length is 0
      return done undefined

    return done (@_clean calls, provenanceUrl)

  _arrayMap: (callArray, valueArray, property) ->
    if !valueArray or !property
      return callArray

    if callArray and callArray.length and callArray.length isnt valueArray.length
      return callArray

    for i in [0...(valueArray.length)] by 1
      callArray[i] = {} if !callArray[i]
      callArray[i][property] = valueArray[i]
    return callArray


  _clean: (calls, provenanceUrl) ->
    for i in [0...calls.length] by 1
      calls[i].provenance = provenanceUrl
      if !calls[i].title
        console.log 'EXTRACTOR : Missing title for call ' + provenanceUrl
        calls.splice(i, 1)
      else if 'esito' in calls[i].title.toLowerCase()
        console.log 'EXTRACTOR : Not a valid title ' + calls[i].title
        calls.splice(i, 1)

    i = 0
    for call in calls

      # convert date
      if call.expiration
        call.expiration = call.expiration.replace '&nbsp;', ''
        call.expiration = momentjs call.expiration, ["DD MMMM, YYYY", "DD/MM/YYYY"], 'it'
        if call.expiration <= (new Date())
          calls.splice i, 1
          continue
        call.expiration = undefined   if not call.expiration.isValid()
        # fix url
      if call.url
        parsedUrl = urlparse.parse call.url
        if !parsedUrl.host # something is missing in the url..
          sourceParsedUrl = urlparse.parse provenanceUrl
          call.url = sourceParsedUrl.protocol + '//' + sourceParsedUrl.host + parsedUrl.path

      # assign category
      if !call.type
        if 'amministra' in call.title.toLowerCase() or call.provenance.match '\/ateneo\/bando-pta' or 'funzionari' in call.title.toLowerCase()
          call.type = 'amministrazione'
        else if 'didattica' in call.title.toLowerCase()
          call.type = 'didattica'
        else if (call.institution) and (call.institution.toLowerCase().match 'universit')
          call.type = 'ricerca'
        else if call.title.toLowerCase().match 'bors(a|e)'
          call.type ?= 'premio'
      i++
    return calls

  ###
  add a call to the database, checking if the call is already stored
  ###
  loadCall: (call) ->
    (done) =>
      if !call or !call.title
        return done undefined, undefined

      # check not yet expired
      if call.expiration and call.expiration < new Date()
        return done undefined, undefined

      async.waterfall [
        # pre process call (Compute normalized title
        (next) =>
          normalized = call.title
          normalized = normalized.toLowerCase()
          # accenti
          normalized = normalized.replace /à|á|â|ä|æ|ã|å|ā/, 'a'
          normalized = normalized.replace /è|é|ê|ë|ē|ė|ę/, 'e'
          normalized = normalized.replace /î|ï|í|ī|į|ì/, 'i'
          normalized = normalized.replace /ô|ö|ò|ó|œ|ø|ō|õ/, 'o'
          normalized = normalized.replace /û|ü|ù|ú|ū/, 'u'

          # punteggiatura
          normalized = normalized.replace  /\[|\/|\.|,|-|#|!|\$|%|\^|&|\*|;|:|{|}|=|\-|_|`|~|\(|\)|\]|“|”|’|€/g, ' '
          # trim
          normalized = normalized.replace /\s{2,}/g, ' '
          normalized = normalized.trim()

          call.normalizedTitle = normalized
          return next undefined, call

        # check if call is already in the database
        (call, next) =>
          conditions = [{title: call.title}, {normalizedTitle: call.normalizedTitle}, {alternativeTitle: call.title}]
          conditions.push {url: call.url}   if call.url
          conditions.push {provenance: call.provenance} if call.provenance
          Call.find {$or: conditions}, next

        # replace institution with normalized name, or add to index
        (duplicates, next) =>
          if !call.institution
            return next undefined, duplicates
          @getNameIndex().get call.institution , (valid_name) =>
            if !valid_name
              @getNameIndex().insert call.institution, call.institution , () ->
                next undefined, duplicates
            else
              call.institution = valid_name
              next undefined, duplicates

        (duplicates, done) =>
          if duplicates and duplicates.length > 0
            @merge call, duplicates[0], done
          else
            newCall = new Call call
            newCall.save (err, result) =>
              return done (err || undefined), result


      ], done

  merge : (call1, call2 = undefined, done) ->
    if !call1  or !done
      throw new Error 'Missing Parameter'
    if (typeof done) isnt 'function'
      throw  new Error 'Invalid Callback'
    return done undefined, call1  if !call2


    buff = call1.alternativeTitle || []
    buff.push call2.title  if ((call2.title isnt call1.title) and (call2.title not in buff))
    if call2.alternativeTitle
      ((buff.push altTitle) if ((altTitle not in buff) and (altTitle isnt call1.title) ))     for altTitle in call2.alternativeTitle
    call1.alternativeTitle = buff

    buff = call1.provenances || []
    buff.push call2.provenance if ((call2.provenance isnt call1.provenance) and (call2.provenance not in buff))
    if call2.provenances
      ((buff.push prov)   if ((prov not in buff) and (prov isnt call1.provenance)))  for prov in call2.provenances
    call1.provenances = buff

    call1.institution ?= call2.institution
    call1.expiration ?= call2.expiration

    if call1.expiration > call2.expiration
      call1.expiration = call2.expiration
    call1.text ?= call2.text
    call1.type ?= call2.type
    call1.city ?= call2.city


    call1 = new Call call1    if !call1._id
    call1.save (err, res) ->
      return done (err||undefined), res if err or !call2._id

      call2.remove (err, removeRes) =>
        return done (err||undefined), res


module.exports = ExtractLoad;