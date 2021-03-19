/* Derived from generate-index.js in https://github.com/Mogztter/antora-lunr
 * MIT License.
 */

'use strict'

const lunr = require('lunr')
const cheerio = require('cheerio')
const Entities = require('html-entities').AllHtmlEntities
const entities = new Entities()

// Extract the text from a heading element
function headingText(node) {
  let text = '';
  for (var n = 0; n < node.children.length; n++) {
    if (node.children[n].type == 'text') {
      text += node.children[n].data + ' ';
    }
  }

  // Decode HTML
  text = entities.decode(text);
  // Strip HTML tags
  return text.replace(/(<([^>]+)>)/ig, '')
    .replace(/\n/g, ' ')
    .replace(/\r/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

// Extract all text from this element, including all descendants.
function extractText(node) {
  let text = '';

  if (node.type == 'tag') {
    for (var c = 0; c < node.children.length; c++) {
      text += extractText(node.children[c]);
    }
  }

  if (node.type == 'text') {
    text = node.data;
  }

  // Decode HTML
  text = entities.decode(text);
  // Strip HTML tags
  return text.replace(/(<([^>]+)>)/ig, '')
    .replace(/\n/g, ' ')
    .replace(/\r/g, ' ')
    .replace(/\s+/g, ' ');
}

// Depth-first reverse search to pull out titled sections from node.
function separateSections(foundSections, language, url, node) {

  //console.log(" — — — ");
  //console.log("At node", node.type, node.name, node.attribs);

  if (node.type != 'tag') {
    //console.log("Skipping "+node.type+" node");
    return [];
  }

  if (node.children == []) {
    return [];
  }

  // Depth-first, reverse order recursion on this node's children
  for (var c = node.children.length - 1; c >= 0; c--) {
    let child = node.children[c];
    //console.log("Subnode", child.name, child.attribs);
    separateSections(foundSections, language, url, child);
  }

  // Extract preamble nodes.
  if (node.attribs['id'] && node.attribs['id'].match(/^(preamble)$/)) {
    console.log("  Found " + node.attribs['id'] + " special section");

    // Add whole section to index, then remove this section.
    let text = extractText(node)

    const section = {
      language: language,
      text: text,
      title: 'Preamble',
      name: 'stem',
      url: url + '#' + node.attribs['id'],
      titles: []
    }

    foundSections.push(section);
    node.children = [];
  }

  // Extract sectN nodes.
  if (node.attribs['class'] && node.attribs['class'].match(/^sect[0-9]+$/)) {
    // The second child should be the header with an id
    // (The first child is a text node.)
    const heading = node.children[1];
    console.log("  Found " + node.attribs['class'] + " with anchor " + heading.attribs['id']);

    // Add whole section to index, then remove this section.
    let text = extractText(node)

    const section = {
      language: language,
      text: text,
      title: headingText(heading).trim(),
      name: 'stem',
      url: url + '#' + heading.attribs['id'],
      titles: [{text: headingText(heading).trim(), id: heading.attribs['id']}]
    }

    foundSections.push(section);
    node.children = [];
  }
  return foundSections
}

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
      const noIndex = metaRobotNoIndex
      return !noIndex
    })
    .map(({ page, $ }) => {
      const language = $('html').attr('lang')
      // Fetch just the article content, so we don't index the TOC and other on-page text
      const article = $('#content')
      // don't index navigation elements for pagination on each page
      // as these are the titles of other pages and it would otherwise pollute the index.
      $('.nav-footer', article).each(function () {
        $(this).remove()
      })

      // Run through the document, splitting it into sections with headings
      console.log("Indexing " + language + ": " + page.pub.url);
      return separateSections([], language, page.pub.url, article[0]);
    })
    .flat(1);

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
    self.metadataWhitelist = ['position']
    documents.forEach(function (doc) {
      self.add(doc)
      doc.titles.forEach(function (title) {
        self.add({
          title: title.text,
          url: `${doc.url}`
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
  //console.log('Indexing', path)

  return {
    contents: filesystem.readFileSync(path, 'utf8'),
    src: {
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
})
console.log("Index written to", process.argv[3])
