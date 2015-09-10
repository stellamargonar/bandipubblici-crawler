chai = require 'chai'
sinon = require 'sinon'
# using compiled JavaScript file here to be sure module works
bandipubbliciCrawler = require '../lib/bandipubblici-crawler.js'

expect = chai.expect
chai.use require 'sinon-chai'

describe 'bandipubblici-crawler', ->
  it 'works', ->
    actual = bandipubbliciCrawler 'World'
    expect(actual).to.eql 'Hello World'
