

class NameIndex

    constructor : () ->

    ###
    insert in the index the key with the given value. Assigns the default status false, means not yet validated
    ###
    insert : (key, value, done) ->

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
    updateAll : (valueOld, valueNew, done) ->

    ###
    returns all the records that haven't yet been validated by the user
    ###
    getUnvalidated : (done) ->


