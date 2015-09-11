chai = require 'chai'
sinon = require 'sinon'
# nock = require 'nock'
# using compiled JavaScript file here to be sure module works
genericCrawler = require '../lib/genericCrawler.js'

expect = chai.expect
chai.use require 'sinon-chai'

testOptions = 
	url : 'http://www.unitn.it/docente-e-staff/lavorare-unitrento'
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

# describe 'genericCrawler.retrieveContent', =>
# 	crawler = new genericCrawler(testOptions)

# 	it 'should return undefined and error "empty url" when url is empty', (done) =>
# 		crawler.retrieveContent undefined, undefined , undefined, (error, content) =>
# 			expect(content).to.eql undefined
# 			expect(error).to.eql 'Empty Url'
# 			done()

# 	it 'should return undefined and error "invalid url" when url is not a string', (done) =>
# 		crawler.retrieveContent 12343, undefined, undefined, (error, content) =>
# 			expect(content).to.eql undefined
# 			expect(error).to.eql 'Invalid Url'
# 			done()

# 	it 'should return the page content as text and no error when page is available', (done) =>
# 		validUrl = 'http://www.unitn.it/node/410'
# 		invalidUrl = 'http://www.unitn.it/ateneo/13/ricerca'
# 		pageContent = '<a href="'+ validUrl + '"> ciao </a> <a href="' + invalidUrl + '">altro ciao</a>'

# 		initialPageUrl = testOptions.url
# 		isValidUrl = (url) ->
# 			if url.path is undefined
# 				return false
# 			result = (url.path.indexOf '/docente-e-staff/lavorare-unitrento/') is 0
# 			result = result or ('in-atto' in url.path)
# 			result = result or ('/ateneo/bando' in url.path)
# 			if result
# 				console.log url.path
# 			result
# 			# (url.indexOf 'node') isnt -1

# 		# nock(initialPageUrl).get('/').reply(200, pageContent)

# 		crawler.retrieveContent initialPageUrl, isValidUrl, undefined, (error, content) =>
# 			expect(error).to.eql {}
# 			expect(content).to.have.property(testOptions.url)
# 			expect(content).to.have.property(validUrl)
# 			expecte(content).not.to.have.property(invalidUrl)
# 			done()