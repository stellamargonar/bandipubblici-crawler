#mysql = require 'mysql'
pg = require 'pg'
config = require '../config'

class NameIndex

    constructor : () ->
      # establish connection
      pg.connect config.psDatabase , (err, client, done ) ->
        console.error ('NAME INDEX ERROR connecting to database: ' + err) if err

        # create schema if not done yet
        createTable = 'CREATE TABLE IF NOT EXISTS name_index ( ' +
           'name       VARCHAR(100) PRIMARY KEY, ' +
           'valid_name VARCHAR(100), ' +
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


    ###
    updates with the new value all the entries that had the old value
    Modifies the status to true (= validated)
    ###
    updateAll : (valueOld, valueNe, done) ->

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




module.exports = NameIndex