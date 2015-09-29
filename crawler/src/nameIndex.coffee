mysql = require 'mysql'
config = require '../config'

class NameIndex

    constructor : () ->
      # establish connection
      @connection = mysql.createConnection config.mysqlDatabase
      @connection.connect (connectionError, connectionResult) =>
        # create name index table(s)
        createTableQuery = 'CREATE TABLE IF NOT EXISTS name_index (' +
          ' name VARCHAR(100) PRIMARY KEY, ' +
          ' valid_name VARCHAR(100),' +
          ' validated BOOLEAN, ' +
          ' FULLTEXT INDEX ngram_idx(valid_name) WITH PARSER ngram ' +
          ') ENGINE=InnoDB CHARACTER SET utf8mb4;'
        @connection.query createTableQuery , (err, result) ->
          console.log ('NAME INDEX: ERROR creating table ' + err) if err

    ###
    insert in the index the key with the given value. Assigns the default status false, means not yet validated
    ###
    insert : (key, value, done) ->
      if !key or !value or !done
        throw new Error 'Missing Parameter'
      if (typeof done) isnt 'function'
        throw new Error 'Invalid Callback'

      insertQuery = 'INSERT INTO name_index (name, valid_name, validated) VALUES (' + @connection.escape(key) + ',' + @connection.escape(value) + ',false)'
      @connection.query insertQuery , (err) ->
        if err
          done err
        else
          done()

    ###
    retrieves the value (without status) corresponding to the given key
    ###
    get : (key, done) ->


    ###
    retrieves all the values that are similar (based on the data storage fuzzy string algorithm) to the string in input
    ###
    find : (key, done) ->

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




module.exports = NameIndex