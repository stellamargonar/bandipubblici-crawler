# Example model

mongoose = require 'mongoose'
Schema   = mongoose.Schema

CallSchema = new Schema(
  title         : String
  url           : String
  text          : String
  institution   : String
  type          : String
  expiration    : Date
  city          : String
  
)

CallSchema.virtual('date')
  .get (-> this._id.getTimestamp())

Call = mongoose.model 'Call', CallSchema

module.exports = 
	Call : Call
	CallSchema : CallSchema