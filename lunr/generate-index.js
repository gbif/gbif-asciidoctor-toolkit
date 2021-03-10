/* Derived from generate-index.js in https://github.com/Mogztter/antora-lunr
 * MIT License.
 */

'use strict'

const lunr = require('lunr')
const cheerio = require('cheerio')
const Entities = require('html-entities').AllHtmlEntities
const entities = new Entities()

/**
 * Generate a Lunr index.
 *
 * Iterates over the specified pages and creates a Lunr index.
 *
 * @memberof generate-index
 *
 * @param {Array<File>} pages - The publishable pages to map.
 * @returns {Object} A JSON object with a Lunr index and a documents store.
 */
function generateIndex (pages) {
  // Uses relative links when site URL is not set
  let siteUrl = ''
  //if (siteUrl.charAt(siteUrl.length - 1) === '/') siteUrl = siteUrl.substr(0, siteUrl.length - 1)
  if (!pages.length) return {}

  // Map of Lunr ref to document
  const documentsStore = {}
  const documents = pages
    .map((page) => {
      const html = page.contents.toString()
      const $ = cheerio.load(html)
      return { page, $ }
    })
    // Exclude pages marked as "noindex"
    .filter(({ page, $ }) => {
      const $metaRobots = $('meta[name=robots]')
      const metaRobotNoIndex = $metaRobots && $metaRobots.attr('content') === 'noindex'
      const noIndex = metaRobotNoIndex //|| pageNoIndex
      return !noIndex
    })
    .map(({ page, $ }) => {
      const language = $('html').attr('lang')
      // Fetch just the article content, so we don't index the TOC and other on-page text
      // Remove any found headings, to improve search results
      const article = $('#content')
      const $heading = $('h1,h2,h3,h4,h5,h6', article)
      const documentTitle = $heading.first().text()
      $heading.first().remove()
      const titles = []
      $('h1,h2,h3,h4,h5,h6', article).each(function () {
        const $title = $(this)
        // If the title does not have an id then Lunr will throw a TypeError
        // cannot read property 'text' of undefined.
        if ($title.attr('id')) {
          titles.push({
            text: $title.text(),
            id: $title.attr('id')
          })
        }
        $title.remove()
      })

      // don't index navigation elements for pagination on each page
      // as these are the titles of other pages and it would otherwise pollute the index.
      // TODO for HP
      $('nav.pagination', article).each(function () {
        $(this).remove()
      })

      // Pull the text from the article, and convert entities
      let text = article.text()
      // Decode HTML
      text = entities.decode(text)
      // Strip HTML tags
      text = text.replace(/(<([^>]+)>)/ig, '')
        .replace(/\n/g, ' ')
        .replace(/\r/g, ' ')
        .replace(/\s+/g, ' ')
        .trim()

      // Return the indexable content, organized by type
      return {
        language: language,
        text: text,
        title: documentTitle,
        component: page.src.component,
        version: page.src.version,
        name: page.src.stem,
        url: page.pub.url,
        titles: titles // TODO get title id to be able to use fragment identifier
      }
    })

//  const languages = ['en']
  const unique = (value, index, self) => {
    return self.indexOf(value) === index
  }
  const languages = documents.map(doc => doc.language).filter(unique)
  console.log("Index with languages", languages)

  const enabledLanguages = []
  if (languages.length > 1 || !languages.includes('en')) {
    if (languages.length > 1 && typeof lunr.multiLanguage === 'undefined') {
      // required, otherwise lunr.multiLanguage will be undefined
      require('lunr-languages/lunr.multi')(lunr)
    }
    // required, to load additional languages
    require('lunr-languages/lunr.stemmer.support')(lunr)
    languages.forEach((language) => {
      if (language === 'ja' && typeof lunr.TinySegmenter === 'undefined') {
        require('lunr-languages/tinyseg')(lunr) // needed for Japanese Support
      }
      if (language === 'th' && typeof lunr.wordcut === 'undefined') {
        lunr.wordcut = require('lunr-languages/wordcut') // needed for Thai support
      }
      if (language !== 'en' && typeof lunr[language] === 'undefined') {
        try {
          require(`lunr-languages/lunr.${language}`)(lunr)
          enabledLanguages.push(language)
        }
        catch (e) {
          console.warn('Language', language, 'is not available in this version of Lunr.JS.  It will not be possible to search pages in this language')
        }
      }
    })
  }

  if (enabledLanguages.length == 0) {
    enabledLanguages.push('en')
  }

  // Construct the lunr index from the composed content
  const lunrIndex = lunr(function () {
    const self = this
    if (enabledLanguages.length > 1) {
      self.use(lunr.multiLanguage(...enabledLanguages))
    } else if (!enabledLanguages.includes('en')) {
      self.use(lunr[enabledLanguages[0]])
    } else {
      // default language (English)
    }
    self.ref('url')
    self.field('title', { boost: 10 })
    self.field('name')
    self.field('text')
    self.field('component')
    self.metadataWhitelist = ['position']
    documents.forEach(function (doc) {
      self.add(doc)
      doc.titles.forEach(function (title) {
        self.add({
          title: title.text,
          url: `${doc.url}#${title.id}`
        })
      }, self)
    }, self)
  })

  // Place all indexed documents into the store
  documents.forEach(function (doc) {
    documentsStore[doc.url] = doc
  })

  // Return the completed index, store, and component map
  return {
    index: lunrIndex,
    store: documentsStore
  }
}

const filesystem = require("fs")
const path = require("path")

var documentDirectory = process.argv[2];
console.log('Creating index from documents in', documentDirectory);

const pages = filesystem.readdirSync(documentDirectory).filter(item => path.extname(item) === '.html').map(item => {
  const path = documentDirectory + '/' + item
  console.log('Indexing', path)

  return {
    contents: filesystem.readFileSync(path, 'utf8'),
    src: {
      component: 'component-a',
      version: '1.0',
      stem: 'stem'
    },
    pub: {
      url: item
    }
  }
})

const index = generateIndex(pages)
var serializedIdx = JSON.stringify(index)

filesystem.writeFile(process.argv[3], serializedIdx, (err) => {
  if (err) throw err
  console.log("Index written to", process.argv[3])
})

//idx = lunr.Index.load(index)
//console.log(idx.search('quality'))
