express = require 'express'
sourceControllerClass = require './sourceController.js'

class WebWrapper
    
    SOURCE_PATH = 'sources'
    CALL_PATH = 'calls'
    ERROR_STATUS = 400
    SUCCESS_STATUS = 200

    constructor : (server) ->
        @_sourceController = new sourceControllerClass
        # @_localRouter = server

        
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
                    param = req.queryParams.url
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

        server.post '/' + SOURCE_PATH + '/test' , (req, res) =>
            console.log 'called test'
            console.log req.body
            try 
                @_sourceController.tryConfiguration req.body, (err, calls) =>
                    return res.status(ERROR_STATUS).json(err) if err
                    return res.status(SUCCESS_STATUS).send(calls);
            catch error
                return res.status(ERROR_STATUS).send({message: error})

        server.post '/' + CALL_PATH + '/extract' , (req, res) =>
            console.log 'called extract'
            try
                @_extractLoader.extractContentFromPage req.body, (err, call) =>
                    return res.status(ERROR_STATUS).json({message: err}) if err
                    return res.status(SUCCESS_STATUS).json(call)
            catch error
                res.status(ERROR_STATUS).send({message: error})
            

module.exports = WebWrapper;