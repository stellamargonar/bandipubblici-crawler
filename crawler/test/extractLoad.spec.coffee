chai = require 'chai'
sinon = require 'sinon'

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

      it 'should parse also html as result of json queries', () ->
        html = '{"aaData": [["<div><div style=\'padding-bottom:5px;border-bottom: 1px dotted #aaa;\'><a href=\'http://www.albotelematico.tn.it/atto-pubb/201560413\'><b>BANDO PER LA COPERTURA DEL POSTO A TEMPO PIENO DI \'FUNZIONARIO ESPERTO IN MATERIA CONTABILE E DI FINANZA PUBBLICA\' - CATEGORIA D), LIVELLO EVOLUTO - ATTRAVERSO MOBILIT&Agrave; VOLONTARIA AI SENSI DELL\'ART. 73 DEL CONTRATTO COLLETTIVO PROVINCIALE DI LAVORO 20.10.2003 DEL PERSONALE DEL COMPARTO AUTONOMIE LOCALI, AREA NON DIRIGENZIALE.</b></a></div><div style=\'font-style:italic;margin-top:5px;\'><b>Periodo:</b> pubblicato il giorno <b>22/09/2015</b> e consultabile fino a tutto il: <b>06/11/2015</b></div><div>Atto pubblicato da <b>Comune di Daiano</b>.<br/></div><div style=\'margin-top:5px;\'><a download target=\'_blank\' href=\'http://www.albotelematico.tn.it/ftp/2015/22070/60413.pdf\' target=\'_blank\'><img src=\'http://www.albotelematico.tn.it/_site/_img/ico/pdf.jpg\' class=\'img_no_border\' alt=\'Scarica atto numero 60413 - 22070\' title=\'Scarica atto numero 60413 - 22070\' /> Scarica atto</a></div></div>","<div class=\'hidden-766-action\' style=\'text-align:center;\'>21/09/2015</div>",'+
        '"<a href=\'http://www.albotelematico.tn.it/bacheca/tutti/concorsi\'>Concorsi</a>","<div style=\'text-align:center;\'><div style=\'margin-top:5px;\'><a download target=\'_blank\' href=\'http://www.albotelematico.tn.it/ftp/2015/22070/60413.pdf\' target=\'_blank\'><img src=\'http://www.albotelematico.tn.it/_site/_img/ico/pdf.jpg\' class=\'img_no_border\' alt=\'Scarica atto numero 60413 - 22070\' title=\'Scarica atto numero 60413 - 22070\' /> Scarica atto</a></div></div>"],' +
          '["<div><div><a href=\'http://www.albotelematico.tn.it/atto-pubb/201560412\'><b>BANDO PER LA COPERTURA DEL POSTO A TEMPO PIENO DI \'FUNZIONARIO ESPERTO IN MATERIA CONTABILE E DI FINANZA PUBBLICA\' CAT. D), LIV: EVOLUTO - ATTRAVERSO MOLIBILITA\' VOLONTARIA</b></a></div><div><b>Periodo:</b> pubblicato il giorno <b>22/09/2015</b> e consultabile fino a tutto il: <b>06/11/2015</b></div><div>Atto pubblicato da <b>Comune di Cimone</b> per conto di: </span> <span><b>Comune di Cavalese</b>.<br/></div><div><a download href=\'http://www.albotelematico.tn.it/ftp/2015/22058/60412.pdf\' ><img src=\'http://www.albotelematico.tn.it/_site/_img/ico/pdf.jpg\' class=\'img_no_border\' alt=\'Scarica atto numero 60412 - 22058\' title=\'Scarica atto numero 60412 - 22058\' /> Scarica atto</a></div></div>"]]}'
        patterns = 
          call : 'div'
          title : 'div a b'
          expiration:   'div b:nth-child(3)'
          url : 'div:last-child a'
          institution : 'div>span>b'

        extractLoad.extractCallFromPage html, patterns, '' , (calls) =>
          expect(calls).to.be.not.undefined
          expect(calls.length).to.be.eql(2)
          call = calls[0]
          expect(call).to.have.property('title')
          expect(call).to.have.property('url')
          expect(call).to.have.property('expiration')

          
          
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

      # it 'should create new object when value array is longer than first array', () ->
      #   first_array = [{prop1: 'ciao'}]
      #   second_array = ['oggi', 'piove']
      #   result = extractLoad._arrayMap first_array, second_array, 'prop2'
      #   expect(result).to.be.not.undefined
      #   expect(result.length).to.be.eql(2)
      #   expect(result[0]).to.have.property('prop1')
      #   expect(result[0]).to.have.property('prop2')
      #   expect(result[1]).to.have.property('prop2')
      #   expect(result[1]).to.have.not.property('prop1')
















