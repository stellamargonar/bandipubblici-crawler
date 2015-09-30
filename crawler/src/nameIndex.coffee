#mysql = require 'mysql'
pg = require 'pg'
config = require '../config'
mongoose = require 'mongoose'
async = require 'async'
Call = (require './models/call.schema.js').Call


class NameIndex

    constructor : () ->
      # establish connection
      mongoose.createConnection

      pg.connect config.psDatabase , (err, client, done ) ->
        console.error ('NAME INDEX ERROR connecting to database: ' + err) if err

        # create schema if not done yet
        createTable = 'CREATE TABLE IF NOT EXISTS name_index ( ' +
           'name       text PRIMARY KEY, ' +
           'valid_name text, ' +
           'validated  BOOLEAN ' +
           ')'

        createIndex = 'DO ' +
           '$$ ' +
           'DECLARE i_count integer; '+
           'BEGIN ' +
           'SELECT count(*) INTO i_count FROM pg_indexes WHERE schemaname=\'public\' and tablename=\'name_index\' and indexname =\'trgm_idx\' ; ' +
           'IF i_count = 0 THEN ' +
           'EXECUTE \'CREATE INDEX trgm_idx ON name_index USING gist (valid_name gist_trgm_ops)\'; ' +
           'END IF; END; $$ ;'

        client.query (createTable + ' ; ' + createIndex), (schemaErr) ->
          # important: release client
          client.end()
          console.error schemaErr if schemaErr


    _submitQuery : (query, callback) ->
      pg.connect config.psDatabase , (err, client) ->
        client.query query , (err, res) ->
          client.end()
          callback err, res


    ###
    insert in the index the key with the given value. Assigns the default status false, means not yet validated
    ###
    insert : (key, value, done) ->
      if !key or !value or !done
        throw new Error 'Missing Parameter'
      if (typeof done) isnt 'function'
        throw new Error 'Invalid Callback'

      insertQuery =
        text : 'INSERT INTO name_index (name, valid_name, validated) VALUES ( $1, $2, false)'
        values : [key, value]
      @_submitQuery insertQuery, (err) ->
        if err
          done err
        else
          done()



    ###
    retrieves the value (without status) corresponding to the given key
    ###
    get : (key, done) ->
      if !key or !done
        throw new Error 'Missing Parameter'
      if (typeof done) isnt 'function'
        throw new Error 'Invalid Callback'

      getQuery =
        text : 'SELECT valid_name FROM name_index WHERE name= $1',
        values : [key]
      @_submitQuery getQuery, (err, res) ->
        if err or !res or !res.rows or !res.rows[0]
          done undefined
        else
          done res.rows[0].valid_name

    ###
    retrieves all the values that are similar (based on the data storage fuzzy string algorithm) to the string in input
    ###
    # select valid_name, levenshtein(valid_name,'uni di trento')/13 as lev from name_index where levenshtein(valid_name, 'uni di trento')/13 < 1 order by lev;
    find : (key, done) ->
      if !key or !done
        throw new Error 'Missing Parameter'
      if (typeof done) isnt 'function'
        throw new Error 'Invalid Callback'

      findMatchQuery =
        text : 'SELECT valid_name, similarity(valid_name, $1) as sim FROM name_index WHERE similarity(valid_name, $1) > 0.4 order by sim desc'
        values : [key]

      @_submitQuery findMatchQuery, (err, res) ->
        distinctNames = {}
        for row in res.rows
          distinctNames[row.valid_name] = 1
        done Object.keys(distinctNames)

    ###
    updates the entry corresponding to the given key with the given value.
    Modifies the status to true (= validated)
    ###
    update : (key, value, done) ->
      if !key or !value or !done
        throw new Error 'Missing Parameter'
      if (typeof done) isnt 'function'
        throw new Error 'Invalid Callback'

      updateQuery =
        text: 'UPDATE name_index SET valid_name = $1 , validated = true WHERE name = $2'
        values : [value, key]
      @_submitQuery updateQuery , (err, res) ->
        if err or !res or !res.rowCount
          done 'Error ' + err
        else
          # update monog institutions
          Call.update {institution: key}, {institution: value}, (err) ->
            done (err || undefined)


    ###
    updates with the new value all the entries that had the old value
    Modifies the status to true (= validated)
    ###
    updateAll : (valueOld, valueNew, done) ->
      if !valueOld or !valueNew or !done
        throw new Error 'Missing Parameter'
      if (typeof done) isnt 'function'
        throw new Error 'Invalid Callback'

      updateQuery =
        text : 'UPDATE name_index SET valid_name = $1, validated = true WHERE valid_name = $2'
        values : [valueNew, valueOld]
      @_submitQuery updateQuery , (err, res) ->
        return done (err || 'Error')  if err or !res or !res.rowCount

        # propagate to main db
        Call.update {institution: valueOld}, {institution: valueNew}, (err) ->
          done (err || undefined)

    ###
    returns all the records that haven't yet been validated by the user
    ###
    getUnvalidated : (done) ->
      if !done
        throw new Error 'Missing Parameter'
      if (typeof done) isnt 'function'
        throw new Error 'Invalid Callback'

      unvalidQuery = 'SELECT name, valid_name FROM name_index WHERE validated=false'
      @_submitQuery unvalidQuery, (err, res) ->
        done res.rows


    init : (done) ->
      Call.find {}, (err, data) =>
        distinctNames = {}
        (distinctNames[call.institution] = 1 if call.institution and !distinctNames[call.institution]) for call in data
        fns = []
        insert = (name) =>
          (cb) => @insert name, name, cb
        (fns.push (insert name) ) for name of distinctNames
        async.series fns, done

module.exports = NameIndex