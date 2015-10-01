express = require 'express'
sourceControllerClass = require './sourceController.js'
extractLoadClass = require './extractLoad.js'
Call = (require './models/call.schema.js').Call
crawlerClass = require './genericCrawler.js'
nameIndexClass = require './nameIndex.js'
async = require 'async'
amqp = require 'amqp'
config = require '../config'

class WebWrapper
    
    SOURCE_PATH = 'sources'
    CALL_PATH = 'calls'
    CLEAN_PATH = 'clean'
    ERROR_STATUS = 400
    SUCCESS_STATUS = 200

    constructor : (server) ->
        @createChannel (connection) =>
            @_connection = connection

            @_sourceController = new sourceControllerClass()
            @_extractLoader = new extractLoadClass()
            @_crawler = new crawlerClass()
            @_nameIndex = new nameIndexClass()

            server.get '/' + SOURCE_PATH , (req, res) =>
                console.log req.query
                if req.query and Object.keys(req.query).length isnt 0
                    # search by param
                    funct = undefined
                    param = undefined

                    if req.query.name
                        funct = 'readByName'
                        param = req.query.name
                    else if req.query.url
                        funct = 'readByUrl'
                        param = req.query.url
                    else if req.query.id
                        funct = 'readById'
                        param = req.query.id
                    else
                        return res.status(ERROR_STATUS).json({error: 'Cannot query by attribute ' + Object.keys(req.query)})

                    @_sourceController[funct] param, (err, data) =>
                        return res.status(ERROR_STATUS).json(err) if err or !data
                        return res.status(SUCCESS_STATUS).json(data)
                else
                    # LIST ALL
                    @_sourceController.readAll (err, data) =>
                        return res.status(ERROR_STATUS).json(err) if err or !data
                        return res.status(SUCCESS_STATUS).json(data)

            server.post '/' + SOURCE_PATH , (req, res) =>
                try
                    @_sourceController.create req.body, (err) =>
                        return res.status(ERROR_STATUS).json(err) if err
                        return res.status(SUCCESS_STATUS).send();
                catch error
                    return res.status(ERROR_STATUS)

            server.delete '/' + SOURCE_PATH + '/:id' , (req, res) =>
                try 
                    @_sourceController.delete req.params.id, (err) =>
                        return res.status(ERROR_STATUS).json({message: err}) if err
                        return res.status(SUCCESS_STATUS).send();
                catch error
                    return res.status(ERROR_STATUS).send()


            server.post '/' + SOURCE_PATH + '/crawl/:id', (req, res) =>
                try
                    # read source by id
                    sourceId = req.params.id
                    @_sourceController.readById sourceId, (source) =>
                        async.parallel [@_crawlSingleSource(source)], (errors, results) =>
                            return res.status(ERROR_STATUS).send(errors) if errors
                            return res.status(SUCCESS_STATUS).send({message: 'Successfully crawled ' + source.name + '.'})
                catch catch_error
                    console.error catch_error
                    return res.status(ERROR_STATUS).send({message: catch_error})

            
            server.post '/' + SOURCE_PATH + '/crawl', (req, res) =>

                try
                    @_sourceController.readAll (err, sources) =>
                        fns = {}
                        for source in sources
                            if source.name.indexOf('Albo') isnt -1
                                fns[source._id] = (@_crawlSingleSource source)
                        async.series fns, (errors, results) =>
                            return res.status(ERROR_STATUS).send(errors) if errors
                            return res.status(SUCCESS_STATUS).send(results)
                catch catch_error
                    console.error catch_error
                    return res.status(ERROR_STATUS).send({message: catch_error})

            server.get '/' + CALL_PATH + '/', (req, res) =>
                Call.find {}, (err, data) =>
                    return res.status(ERROR_STATUS).send(err) if err
                    return res.status(SUCCESS_STATUS).send(data)


            server.get '/' + CLEAN_PATH + '/unvalidated', (req, res) =>
                try
                    @_nameIndex.getUnvalidated (data) =>
                        return res.status(SUCCESS_STATUS).send(data)   if data
                        return res.status(ERROR_STATUS).send([])
                catch catch_error
                    console.error catch_error

            server.get '/' + CLEAN_PATH + '/init', (req, res) =>
                try
                    @_nameIndex.init (err, results) =>
                        return res.status(SUCCESS_STATUS).send('Done')
                catch catch_error
                    console.error catch_error

            server.get '/' + CLEAN_PATH + '/propagate' , (req, res) =>
                @_nameIndex.propagateToCalls (err, results) =>
                    return res.status(ERROR_STATUS).send err    if err
                    return res.status(SUCCESS_STATUS).send('OK')

            server.get '/' + CLEAN_PATH + '/find', (req, res) =>
                if !req.query.name
                    return res.status(ERROR_STATUS).send('Missing parameter name')
                try
                    @_nameIndex.find req.query.name, (candidates) =>
                        return res.status(SUCCESS_STATUS).send(candidates) if candidates
                        return res.status(ERROR_STATUS).send([])
                catch catch_error
                    console.error catch_error

            server.post '/' + CLEAN_PATH + '/update' , (req, res) =>
                console.log 'POST clean/update'
                if ! req.body or !req.body.name or !req.body.valid_name
                    return res.status(ERROR_STATUS).send('Missing properties in payload')
                @_nameIndex.update req.body.name, req.body.valid_name, (err) =>
                    console.log err if err
                    return res.status(ERROR_STATUS).send(err) if err
                    return res.status(SUCCESS_STATUS).send()


            server.get '/' + CLEAN_PATH + '/normalize', (req, res) =>
                console.log 'Start normalize'
                Call.find {}, (err, calls) =>
                    fns = []
                    reimport = (c) =>
                        (done) =>
                            (@_extractLoader.loadCall c) done
                    (fns.push (reimport call))    for call in calls
                    console.log 'completed cycle'
                    async.series fns, (errors, results) =>
                        console.log errors if errors
                        res.status(SUCCESS_STATUS).send('DONE')

    _crawlSingleSource : (source) ->
        (cb) =>
            @_connection.queue config.amqp.queue.crawler , (queue) =>
                console.log 'sending message to crawler...'
                @_connection.publish config.amqp.queue.crawler, source, () =>
                    console.log '..message sent!'
                    cb undefined, {message : 'Started crawling source ' + source.name}

    createChannel : (done) ->
        connection = amqp.createConnection config.amqp.config
        connection.on 'ready' , (err) =>
            done connection

module.exports = WebWrapper;