# coding: utf-8
require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

include Asciidoctor

class TranslationLinksMacro < Extensions::InlineMacroProcessor
  use_dsl

  LANGUAGE_NAMES = {
    "ar" => "&#1593;&#1585;&#1576;&#1610;&#1577;&nbsp;(Arabiya)",
    "bg" => "&#1041;&#1098;&#1083;&#1075;&#1072;&#1088;&#1089;&#1082;&#1080;&nbsp;(B&#601;lgarski)",
    "ca" => "catal&agrave;",
    "cs" => "&#269;esky",
    "da" => "dansk",
    "de" => "Deutsch",
    "el" => "&#917;&#955;&#955;&#951;&#957;&#953;&#954;&#940;&nbsp;(Ellinika)",
    "en" => "English",
    "es" => "espa&ntilde;ol",
    "eo" => "Esperanto",
    "fa" => "&#x0641;&#x0627;&#x0631;&#x0633;&#x06cc;&nbsp;(Farsi)",
    "fr" => "fran&ccedil;ais",
    "gl" => "Galego",
    "hy" => "&#1344;&#1377;&#1397;&#1381;&#1408;&#1381;&#1398;&nbsp;(hayeren)",
    "hr" => "hrvatski",
    "id" => "Indonesia",
    "it" => "Italiano",
    "he" => "&#1506;&#1489;&#1512;&#1497;&#1514;&nbsp;(ivrit)",
    "ko" => "&#54620;&#44397;&#50612;&nbsp;(Korean)",
    "lt" => "Lietuvi&#371;",
    "hu" => "magyar",
    "nl" => "Nederlands",
    "ja" => "&#26085;&#26412;&#35486;&nbsp;(Nihongo)",
    "nb" => "norsk&nbsp;(bokm&aring;l)",
    "pl" => "polski",
    "pt" => "Portugu&ecirc;s",
    "ro" => "rom&acirc;n&#259;",
    "ru" => "&#1056;&#1091;&#1089;&#1089;&#1082;&#1080;&#1081;&nbsp;(Russkij)",
    "sk" => "slovenčina",
    "fi" => "suomi",
    "sv" => "svenska",
    "ta" => "&#2980;&#2990;&#3007;&#2996;&#3021;&nbsp;(Tamil)",
    "vi" => "Ti&#7871;ng Vi&#7879;t",
    "tr" => "T&uuml;rk&ccedil;e",
    "uk" => "&#1091;&#1082;&#1088;&#1072;&#1111;&#1085;&#1089;&#1100;&#1082;&#1072;&nbsp;(ukrajins'ka)",
    "zh" => "&#20013;&#25991;",
    "zh-CN" => "&#20013;&#25991;(&#31616;)",
    "zh-HK" => "&#20013;&#25991;(HK)",
    "zh-TW" => "&#20013;&#25991;(&#32321;)"
  }

  named :languageLinks
  name_positional_attributes 'preText', 'linkText', 'postText'

  def process parent, target, attributes
    currentLangCode = parent.document.attributes['lang']
    if ! currentLangCode
      currentLangCode = 'en'
    end

    pdfFilename = parent.document.attributes['pdf_filename']

    if target == 'pdf'
      linkText = attributes['linkText']
      %(#{attributes['preText']} <a hreflang="#{currentLangCode}" type="application/pdf" href="#{pdfFilename}">#{attributes['linkText']}</a> #{attributes['postText']})

    elsif target == 'languages'
      links = attributes['preText']

      Dir["index.??.adoc"].sort.each do |file|
        langCode = file[6,2]
        if langCode != currentLangCode
          if links.length > attributes['preText'].length
            links += ','
          end
          links += %( <a hreflang="#{langCode}" href="../#{langCode}/">#{LANGUAGE_NAMES[langCode]}</a>)
        end
      end

      if links.length == attributes['preText'].length
        # Only the main language, so abandon this.
        links = ''
      elsif attributes['linkText']
        # Close the sentance.
        links += attributes['linkText']
      end

      links
    elsif target == 'combined'
      preText = parent.document.attributes['also_links_pre_text'] || 'This document is also available in '
      pdfLinkText = parent.document.attributes['also_links_pdf_link_text'] || 'PDF format'
      langPreText = parent.document.attributes['also_links_languages_pre_text'] || ' and in other languages: '
      langSeparator = parent.document.attributes['also_links_languages_separator'] || ', '
      postText = parent.document.attributes['also_links_post_text'] || '.'

      pdfLink = %(#{preText}<a hreflang="#{currentLangCode}" type="application/pdf" href="#{pdfFilename}">#{pdfLinkText}</a>)
      allLinks = pdfLink + langPreText

      translationsExist = false
      Dir["index.??.adoc"].sort.each do |file|
        langCode = file[6,2]
        if langCode != currentLangCode
          if translationsExist
            allLinks += langSeparator
          end
          allLinks += %(<a hreflang="#{langCode}" href="../#{langCode}/">#{LANGUAGE_NAMES[langCode]}</a>)
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

      %(<em>#{allLinks}</em>)
    else
      %(Unknown syntax "#{target}")
    end
  end
end

class TranslationLinksDocinfoProcessor < Extensions::DocinfoProcessor
  use_dsl
  at_location :head

  def process doc
    links = ''

    currentLangCode = (doc.attr 'lang')
    if ! currentLangCode
      currentLangCode = 'en'
    end

    Dir["index.??.adoc"].sort.each do |file|
      langCode = file[6,2]
      if langCode != currentLangCode
        links += %(<link rel="alternate" hreflang="#{langCode}" href="../#{langCode}/" />)
      end
    end
    links
  end
end
