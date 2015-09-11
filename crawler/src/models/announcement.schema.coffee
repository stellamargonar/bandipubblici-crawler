mongoose = require 'mongoose'
Schema = mongoose.Schema

AnnouncementSchema = new Schema(
    url             : String
    title           : String
    publishedOn     : Timestamp
    isActive        : Boolean
    institution     : Schema.Types.Mixed
)

Announcement = mongoose.model 'Announcement', AnnouncementSchema

module.exports =
    Announcement : Announcement,
    AnnouncementSchema : AnnouncementSchema
