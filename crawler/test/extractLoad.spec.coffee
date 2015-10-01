chai = require 'chai'
sinon = require 'sinon'
mongoose = require 'mongoose'
Call = (require '../lib/models/call.schema.js').Call
pg = require 'pg'

# get config for testing environment
process.env.NODE_ENV = 'testing'
config = require '../config'

# nock = require 'nock'
# using compiled JavaScript file here to be sure module works
extractLoadClass = require '../lib/extractLoad.js'

expect = chai.expect
chai.use require 'sinon-chai'

console.log 'start tests'

describe 'extractLoad', ->
    extractLoad = null

    beforeEach ->
      extractLoad = new extractLoadClass()

    describe 'extractCallFromPage', ->

    	it 'should throw error when is missing the page object', ->
      	expect( -> extractLoad.extractCallFromPage() ).to.throw

      it 'should throw error when is missing the callback', ->
        expect( -> extractLoad.extractCallFromPage({content: 'ciao', url: 'ciao'})  ).to.throw

      it 'should throw error when is missing the source patterns object', ->
        expect( -> extractLoad.extractCallFromPage({content: 'ciao', url: 'http://www.google.it'}, () -> undefined) ).to.throw

      it 'should return undefined when page has no content', ->
        expect( -> extractLoad.extractCallFromPage({content: '', url: 'http://www.google.it'}, {call: 'dsadas', title: 'dsadjlas'},() -> undefined) ).to.throw

      it 'should return undefined when the pattern is not present in the page', (done) ->
        html = '<body><h1>title</h1></body>'
        patterns =
          call : 'div'
          title : 'h2'
        extractLoad.extractCallFromPage html, patterns, '', (result) =>
          expect(result).to.be.undefined
          done()

      it 'should return the call with the title when pattern match the page', (done) ->
        html = '<body><h2>MAIN TITLE</h2><div><h2>title</h2></div></body>'
        patterns =
          call : 'div'
          title : 'h2'
        extractLoad.extractCallFromPage html, patterns, '', (result) =>
          expect(result).to.be.not.undefined
          expect(result).to.be.not.empty
          expect(result[0]).to.have.property('title')
          expect(result[0].title).to.be.eql('title');
          done()

      it 'should extract the fields given the specified patterns for each attribute', (done) ->

        html = '<span class="field-content">
  <div>
    <h1 class="title">Dipartimento di Ingegneria industriale – Avviso di selezione per il conferimento di n. 1 incarico di Prestazione d’Opera Intellettuale (Decreto n. 143/2015)</h1>
    <div id="web-unitn-node-39242" class="">
      <div class="node-inner">
        <div class="content">
          <div class="field field-type-date field-field-bando-data-pubblicazione">
            <div class="field-items">
              <div class="field-item odd">
                <div class="field-label-inline-first">Data di pubblicazione:&nbsp;</div>
                <span class="date-display-single">31 Agosto, 2015</span>
              </div>
            </div>
          </div>
          <div class="field field-type-date field-field-bando-data-scadenza">
            <div class="field-items">
              <div class="field-item odd">
                <div class="field-label-inline-first">Scadenza:&nbsp;</div>
                <span class="date-display-single">14 Settembre, 2015</span>
              </div>
            </div>
          </div>
        <div class="field field-type-content-taxonomy field-field-bando-struttura">
          <div class="field-items">
            <div class="field-item odd">
              <div class="field-label-inline-first">Struttura:&nbsp;</div>
              Dipartimento di Ingegneria industriale
            </div>
          </div>
        </div>
      <p class="rtejustify">
         &Egrave; indetta una selezione per titoli ed eventuale colloquio per il conferimento <strong><u>n. 1 incarico di prestazione d&rsquo;opera intellettuale di natura occasionale/professionale</u></strong>&nbsp;presso il Dipartimento di Ingegneria industriale.&nbsp;</p>
      <div class="field field-type-text field-field-bando-resp-scientifico">
        <div class="field-items">
          <div class="field-item odd">
            <div class="field-label-inline-first">Responsabile scientifico:&nbsp;</div>
              Prof. Dario Petri
          </div>
        </div>
      </div>
      <div class="field field-type-text field-field-bando-contatti">
        <div class="field-items">
          <div class="field-item odd">
            <div class="field-label-inline-first">
        Contatti:&nbsp;</div>
              Ufficio Contratti - Servizi Amministrativi per la Didattica e la Ricerca Polo Collina selezionipolocollina@unitn.it  Tel. +39 0461 281969-1914-1620-1694        
          </div>
        </div>
      </div>
      <div class="field field-type-filefield field-field-bando-allegati">
        <div class="field-label">Allegati:&nbsp;</div>
        <div class="field-items">
          <div class="field-item odd">
            <div class="filefield-file"><img class="filefield-icon field-icon-application-pdf"  alt="application/pdf icon" src="http://web.unitn.it/sites/web.unitn.it/modules/filefield/icons/application-pdf.png" /><a href="http://web.unitn.it/files/download/39242/bando_def.pdf" type="application/pdf; length=481732" title="bando_def.pdf">Bando</a></div> 
          </div>
          <div class="field-item even">
            <div class="filefield-file"><img class="filefield-icon field-icon-application-pdf"  alt="application/pdf icon" src="http://web.unitn.it/sites/web.unitn.it/modules/filefield/icons/application-pdf.png" /><a href="http://web.unitn.it/files/download/39242/domanda_di_ammissione.pdf" type="application/pdf; length=717331" title="domanda_di_ammissione.pdf">Domanda di ammissione</a></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</span>
'
        patterns =
          call : 'span.field-content'
          title : 'h1'
          expire_date : '.field-field-bando-data-scadenza .date-display-single'
          description : 'p.rtejustify'
          url : 'div.field-field-bando-allegati div:first-child a:contains("ando")'

        extractLoad.extractCallFromPage html, patterns, '', (result) =>
          expect(result).to.be.not.undefined
          expect(result).to.be.not.empty
          expect(result[0]).to.have.property('title')
          expect(result[0].title).to.be.eql('Dipartimento di Ingegneria industriale – Avviso di selezione per il conferimento di n. 1 incarico di Prestazione d’Opera Intellettuale (Decreto n. 143/2015)')
          expect(result[0]).to.have.property('expire_date')
          expect(result[0].expire_date).to.be.eql('14 Settembre, 2015')
          expect(result[0]).to.have.property('description')
          expect(result[0].description).to.be.eql(' È indetta una selezione per titoli ed eventuale colloquio per il conferimento n. 1 incarico di prestazione d’opera intellettuale di natura occasionale/professionale presso il Dipartimento di Ingegneria industriale. ')
          expect(result[0]).to.have.property('url')
          expect(result[0].url).to.be.eql('http://web.unitn.it/files/download/39242/bando_def.pdf')
          done()

      it 'should return multiple calls when page contains more than one', (done) ->
        html = '<div class="bando"><h1>Title1</h1></div>' + '<div class="bando"><h1>Title2</h1></div>'
        patterns = 
          call : '.bando'
          title : 'h1'

        extractLoad.extractCallFromPage html, patterns, '', (result) =>
          expect(result).to.be.not.undefined
          expect(result.length).to.be.eql(2)
          expect(result[0]).to.have.property('title')
          expect(result[0].title).to.be.eql('Title1')
          expect(result[1]).to.have.property('title')
          expect(result[1].title).to.be.eql('Title2')
          done()

          
    describe '_arrayMap', ->
      it 'should return first array when second array is undefined', () ->
        first_array = ['ciao']
        result = extractLoad._arrayMap ['ciao'], undefined, 'prop'
        expect(result).to.be.eql(first_array)

      it 'should return empty array when second array is empty', () ->
        first_array = ['ciao']
        result = extractLoad._arrayMap ['ciao'], [], 'prop'
        expect(result).to.be.eql(first_array)

      it 'should return the original array when property is missing', () ->
        first_array = ['ciao']
        result = extractLoad._arrayMap ['ciao'], ['prova'], ''
        expect(result).to.be.eql(first_array)

      it 'should create the object in first array when not existing', () ->
        first_array = []
        second_array = ['ciao', 'oggi', 'piove']
        property = 'prop'
        result = extractLoad._arrayMap first_array, second_array, property

        expect(result).to.be.not.undefined
        expect(result).to.be.not.empty
        expect(result.length).to.be.eql(second_array.length)
        expect(result[0]).to.have.property(property)
        expect(result[0][property]).to.be.eql('ciao')
        expect(result[1][property]).to.be.eql('oggi')
        expect(result[2][property]).to.be.eql('piove')
        
      it 'should modify only the specified property, not other pre existing', () ->
        first_array = [{prop1: 'ciao'}]
        second_array = ['oggi']
        result = extractLoad._arrayMap first_array, second_array, 'prop2'

        expect(result).to.be.not.undefined
        expect(result).to.be.not.empty
        expect(result.length).to.be.eql(1)
        expect(result[0]).to.have.property('prop1')
        expect(result[0]).to.have.property('prop2')
        expect(result[0].prop1).to.be.eql('ciao')
        expect(result[0].prop2).to.be.eql('oggi')

      it 'should return original array when valuesarray has a different length', ()->
        first_array = [{prop1: 'ciao'}]
        second_array = ['oggi', 'piove']
        result = extractLoad._arrayMap [{prop1: 'ciao'}], second_array, 'prop2'
        expect(result).to.be.eql(first_array)



    describe 'loadCall' , ->
      before (done) ->
        mongoose.connect ('mongodb://' + config.database.host + '/' + config.database.dbName)
        done()

      after (done) ->
        mongoose.connection.db.command { dropDatabase: 1 }, (err, result) ->
          mongoose.connection.close done

      afterEach (done) ->
        pg.connect config.psDatabase , (err, client) ->
          client.query 'delete from name_index', ()->
            client.end()
            done()

      it 'should return no error and no result when call is missing', (done) ->
        (extractLoad.loadCall()) (err, results) ->
          expect(err).to.be.undefined
          expect(results).to.be.undefined
          done()

      it 'should save the call when there is no call with same title or same url', (done) ->
        call = {title : 'Titolo1', url : 'ciao'}
        (extractLoad.loadCall call) (err, res) ->
          expect(res).to.be.not.undefined
          expect(err).to.be.undefined

          # check stored
          Call.find {title: 'Titolo1'}, (err, calls) ->
            expect(calls).to.be.not.undefined
            expect(calls).to.be.not.empty
            expect(calls[0].url).to.be.eql('ciao')
            done()

      it 'should update call if already in the db', (done) ->
        call = new Call { title: 'Titolo2', url: 'myurl'}
        call.save () ->
          sameCall = { title: 'Titolo2', url: 'myurl', institution: 'comune'}
          (extractLoad.loadCall sameCall) (err, res) ->
            expect(err).to.be.undefined
            expect(res).to.be.not.undefined

            Call.find {title: 'Titolo2'}, (err, calls) ->
              expect(calls).to.be.not.undefined
              expect(calls).to.be.not.empty
              expect(calls[0].url).to.be.eql('myurl')
              expect(calls[0].institution).to.be.eql('comune')
              done()

      it 'should compute and store the normalized title', (done) ->
        title = '  Selezione AdR2458/15 per il conferimento di 1 assegno di ricerca nel SSD ING-INF/05 SISTEMI DI ELABORAZIONE DELLE INFORMAZIONI, per l’attuazione del seguente programma di ricerca: “Studio di tecniche per la generazione automatica di codice a supporto dello sviluppo di applicazioni web centrate sui dati”, finanziato per un ammontare di € 23.140,00 nell’ambito del bando Joint Project 2014, progetto “uGene”, codice CUP B32C14000120003. [città]  '
        normalized = 'selezione adr2458 15 per il conferimento di 1 assegno di ricerca nel ssd ing inf 05 sistemi di elaborazione delle informazioni per l attuazione del seguente programma di ricerca studio di tecniche per la generazione automatica di codice a supporto dello sviluppo di applicazioni web centrate sui dati finanziato per un ammontare di 23 140 00 nell ambito del bando joint project 2014 progetto ugene codice cup b32c14000120003 citta'
        call = {title : title, url : 'ciao'}
        (extractLoad.loadCall call) (err, res) ->
          expect(res).to.be.not.undefined
          expect(err).to.be.undefined

          # check stored
          Call.find {title: title}, (err, calls) ->
            expect(calls).to.be.not.undefined
            expect(calls).to.be.not.empty
            expect(calls[0].url).to.be.eql('ciao')
            expect(calls[0].normalizedTitle).to.be.eql(normalized)
            done()

      it 'should recognized as duplicate calls with the same normalized title, overwrite previous call property', (done) ->
        title = 'Titolò'
        call = new Call {title : title, url : 'ciao', normalizedTitle : 'titolo'}
        call.save () ->
          titolo2 = 'TITOLO'
          sameCall = {title: titolo2, url : 'other url'}
          (extractLoad.loadCall sameCall) (err, res) ->
            expect(res).to.be.not.undefined
            expect(err).to.be.undefined

            # check stored
            Call.find  {$or: [{title: title}, {title: titolo2}]}, (err, calls) ->
              expect(calls).to.be.not.undefined
              expect(calls).to.be.not.empty
              expect(calls[0].title).to.be.eql(titolo2)
              expect(calls[0].url).to.be.eql('other url')
              done()

      it 'should store all the provenances when recognize a duplicate', (done) ->
        call = new Call {title: 't1', url: 'u1', provenance : 'p1'}
        call.save () ->
          sameCall = {title: 't2', url : 'u1', provenance : 'p2'}
          (extractLoad.loadCall sameCall) (err, res) ->
            expect(res).to.be.not.undefined
            expect(err).to.be.undefined

            Call.find {url: 'u1'}, (err, calls) ->
              expect(calls).to.be.not.undefined
              expect(calls).to.be.not.empty
              expect(calls[0].provenances).contain('p1')
              done()

      it 'should store distinct provenances ', (done) ->
        call = new Call {title: 't1', url: 'u1', provenance : 'p1'}
        call.save () ->
          sameCall = {title: 't2', url : 'u1', provenance : 'p2'}
          sameCall2 = {title: 't3', url: 'u1', provenance: 'p3'}
          (extractLoad.loadCall sameCall) (err, res) ->
            (extractLoad.loadCall sameCall2) (err, res) ->

              Call.find {url: 'u1'}, (err, calls) ->
                expect(calls).to.be.not.undefined
                expect(calls).to.be.not.empty

                expect(calls[0].provenances).contain('p2')
                expect(calls[0].provenances).contain('p1')
                done()

      it 'should store only calls that are not yet expired', (done) ->

        call = {title : 'ciao', url: 'ciao', expiration: new Date(2014,10,4)}
        (extractLoad.loadCall call) (err, res) ->
          expect(err).to.be.undefined
          expect(res).to.be.undefined
          Call.find {title: 'ciao'}, (err, calls) ->
            expect(calls).to.be.not.undefined
            expect(calls).to.be.empty
            done()

      it 'should check name index and if institution is not present, add entry', (done) ->
          call = {title : 'titolo', institution: 'input_name'}
          (extractLoad.loadCall call) (err, res) ->
            Call.find {title:'titolo'}, (err, calls) ->
              expect(calls).to.be.not.empty
              expect(calls[0].institution).to.be.eql('input_name')

              pg.connect config.psDatabase , (err, client) ->
                client.query 'select * from name_index where name=\'input_name\' ', (err, res) ->
                  client.end()
                  expect(res.rows).to.be.not.empty
                  expect(res.rows[0].valid_name).to.be.eql 'input_name'
                  done()

      it 'should check name index and if institution is present substitute with that name', (done) ->
        pg.connect config.psDatabase , (err, client) ->
          client.query 'insert into name_index values (\'input_name\',\'valid_name\', true)', () ->
            client.end()
            call = {title : 'titolo', institution: 'input_name'}
            (extractLoad.loadCall call) (err, res) ->
              Call.find {title:'titolo'}, (err, calls) ->
                expect(calls).to.be.not.empty
                expect(calls[0].institution).to.be.eql('valid_name')
                done()
