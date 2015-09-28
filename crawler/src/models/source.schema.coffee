mongoose = require 'mongoose'
Schema = mongoose.Schema
SchemaTypes = mongoose.SchemaTypes

SourceSchema = new Schema
	name 	: String
	baseUrl	: String
	pattern : SchemaTypes.Mixed
	maxDepth : Number
	protocol : String
	fetchRegex : String
	saveRegex : String
	customCrawler : String

Source = mongoose.model 'Source', SourceSchema
module.exports = 
	Source : Source
	SourceSchema : SourceSchema