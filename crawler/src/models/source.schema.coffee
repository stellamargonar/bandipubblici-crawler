mongoose = require 'mongoose'
Schema = mongoose.Schema
SchemaTypes = mongoose.SchemaTypes

SourceSchema = new Schema
	name 	: String
	baseUrl	: String
	pattern : SchemaTypes.Mixed
	maxDepth : Number
	protocol : String

Source = mongoose.model 'Source', SourceSchema
module.exports = 
	Source : Source
	SourceSchema : SourceSchema