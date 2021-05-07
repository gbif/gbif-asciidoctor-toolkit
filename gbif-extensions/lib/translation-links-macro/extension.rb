# coding: utf-8
require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

include Asciidoctor

class TranslationLinksMacro < Extensions::InlineMacroProcessor
  use_dsl

  named :languageLinks
  name_positional_attributes 'preText', 'linkText', 'postText'

  def process parent, target, attributes
    currentLangCode = parent.document.attributes['lang']
    if ! currentLangCode
      currentLangCode = 'en'
    end

    language_names = GbifHtmlConverterBase.language_names

    pdfFilename = parent.document.attributes['pdf_filename']

    if target == 'pdf'
      linkText = attributes['linkText']
      %(#{attributes['preText']} <a hreflang="#{currentLangCode}" type="application/pdf" href="#{pdfFilename}">#{attributes['linkText']}</a> #{attributes['postText']})

    elsif target == 'languages'
      links = attributes['preText']

      Dir["index.??.adoc", "index.??-??.adoc", "index.??-???.adoc"]
        .map { |file| file.match(/index\.(.+)\.adoc/)[1] }
        .sort.each do |langCode|
        if langCode != currentLangCode && !File.file?("translations/#{langCode}.hidden")
          if links.length > attributes['preText'].length
            links += ','
          end
          links += %( <a hreflang="#{langCode}" href="../#{langCode}/">#{language_names[langCode]}</a>)
        end
      end

      if links.length == attributes['preText'].length
        # Only the main language, so abandon this.
        links = ''
      elsif attributes['linkText']
        # Close the sentance.
        links += attributes['linkText']
      end
    elsif target == 'combined'
      preText = parent.document.attributes['also_links_pre_text'] || 'This document is also available in '
      pdfLinkText = parent.document.attributes['also_links_pdf_link_text'] || 'PDF format'
      langPreText = parent.document.attributes['also_links_languages_pre_text'] || ' and in other languages: '
      langSeparator = parent.document.attributes['also_links_languages_separator'] || ', '
      postText = parent.document.attributes['also_links_post_text'] || '.'

      pdfLink = %(#{preText}<a hreflang="#{currentLangCode}" type="application/pdf" href="#{pdfFilename}">#{pdfLinkText}</a>)
      allLinks = pdfLink + langPreText

      translationsExist = false
      Dir["index.??.adoc", "index.??-??.adoc", "index.??-???.adoc"]
        .map { |file| file.match(/index\.(.+)\.adoc/)[1] }
        .sort.each do |langCode|
        if langCode != currentLangCode && !File.file?("translations/#{langCode}.hidden")
          if translationsExist
            allLinks += langSeparator
          end
          allLinks += %(<a hreflang="#{langCode}" href="../#{langCode}/">#{language_names[langCode]}</a>)
          translationsExist = true
        end
      end

      if not translationsExist
        # Only the main language, so abandon this.
        allLinks = pdfLink
      end

      if postText
        # Close the sentence.
        allLinks += postText
      end

      links = %(<p class="translationLinks"><em>#{allLinks}</em></p>)
    else
      links = %(Unknown syntax "#{target}")
    end

    Asciidoctor::Inline.new(parent, :quoted, links)
  end
end

class TranslationLinksDocinfoProcessor < Extensions::DocinfoProcessor
  use_dsl
  at_location :head

  def process doc
    currentLangCode = (doc.attr 'lang')
    if ! currentLangCode
      currentLangCode = 'en'
    end

    links = %(<link rel="alternate" hreflang="x-default" href="../" />\n)
    links += %(<link rel="alternate" hreflang="#{currentLangCode}" href="./" />\n)

    Dir["index.??.adoc", "index.??-??.adoc", "index.??-???.adoc"]
      .map { |file| file.match(/index\.(.+)\.adoc/)[1] }
      .sort.each do |langCode|
      if langCode != currentLangCode && !File.file?("translations/#{langCode}.hidden")
        links += %(<link rel="alternate" hreflang="#{langCode}" href="../#{langCode}/" />\n)
      end
    end
    links
  end
end
