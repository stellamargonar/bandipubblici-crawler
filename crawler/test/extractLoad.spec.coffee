chai = require 'chai'
sinon = require 'sinon'
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
        extractLoad.extractCallFromPage {content: html}, patterns, (result) =>
          expect(result).to.be.undefined
          done()

      it 'should return the call with the title when pattern match the page', (done) ->
        html = '<body><h2>MAIN TITLE</h2><div><h2>title</h2></div></body>'
        patterns =
          call : 'div'
          title : 'h2'
        extractLoad.extractCallFromPage {content: html}, patterns, (result) =>
          expect(result).to.be.not.undefined
          expect(result).to.have.property('title')
          expect(result.title).to.be.eql('title');
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
          link : 'div.field-field-bando-allegati div:first-child a'

        extractLoad.extractCallFromPage {content: html}, patterns, (result) =>
          expect(result).to.be.not.undefined
          expect(result).to.have.property('title')
          expect(result.title).to.be.eql('Dipartimento di Ingegneria industriale – Avviso di selezione per il conferimento di n. 1 incarico di Prestazione d’Opera Intellettuale (Decreto n. 143/2015)')
          expect(result).to.have.property('expire_date')
          expect(result.expire_date).to.be.eql('14 Settembre, 2015')
          expect(result).to.have.property('description')
          expect(result.description).to.be.eql(' È indetta una selezione per titoli ed eventuale colloquio per il conferimento n. 1 incarico di prestazione d’opera intellettuale di natura occasionale/professionale presso il Dipartimento di Ingegneria industriale. ')
          expect(result).to.have.property('link')
          expect(result.link).to.be.eql('http://web.unitn.it/files/download/39242/bando_def.pdf')
          done()