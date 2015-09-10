chai = require 'chai'
sinon = require 'sinon'
# nock = require 'nock'
# using compiled JavaScript file here to be sure module works
genericCrawler = require '../lib/genericCrawler.js'

expect = chai.expect
chai.use require 'sinon-chai'

testOptions = 
	url : 'http://test.ciao/index.html'
	pattern : 'pattern_di_prova'

describe 'genericCrawler.constructor', ->
  	it 'should throw error when is missing url option', ->
    	expect( -> new genericCrawler({patter: ''})).to.throw

  	it 'should throw error when is option is empty', ->
    	expect( -> new genericCrawler({})).to.throw

  	it 'should throw error when option is undefined', ->
    	expect( -> new genericCrawler(undefined)).to.throw

  	it 'should throw error when is missing pattern option', ->
    	expect( -> new genericCrawler({url: 1})).to.throw

describe 'genericCrawler.retrieveContent', =>
	crawler = new genericCrawler(testOptions)

	it 'should return undefined and error "empty url" when url is empty', (done) =>
		crawler.retrieveContent undefined, (error, content) =>
			expect(content).to.eql undefined
			expect(error).to.eql 'Empty Url'
			done()

	it 'should return undefined and error "invalid url" when url is not a string', (done) =>
		crawler.retrieveContent 12343, (error, content) =>
			expect(content).to.eql undefined
			expect(error).to.eql 'Invalid Url'
			done()

	it 'should return the page content as text and no error when page is available', (done) =>
		expectedContent = 'This is the content'
		url = testOptions.url
		url = "http://www.unitn.it/"

		# nock(url)
		# 	.get('/')
		# 	.reply(200, expectedContent)

		crawler.retrieveContent url, (error, content) =>
			expect(error).to.eql undefined
			expect(content).to.eql expectedContent