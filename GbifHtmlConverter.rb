# coding: utf-8
class GbifHtmlConverter < (Asciidoctor::Converter.for 'html5')
  register_for 'html5'

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
    "zh-CN" => "&#20013;&#25991;(&#31616;)",
    "zh-HK" => "&#20013;&#25991;(HK)",
    "zh-TW" => "&#20013;&#25991;(&#32321;)"
  }

  def convert_alternate node
    result = [%(<ul class="sectlevel1">)]

    currentLangCode = node.document.attributes['lang']
    if ! currentLangCode
      currentLangCode = 'en'
    end

    pdfFilename = node.document.attributes['pdf_filename']
    linkText = 'PDF file'
    result << %(<li><a hreflang="#{currentLangCode}" type="application/pdf" href="#{pdfFilename}">#{linkText}</a></li>)

    Dir["index.??.adoc"].sort.each do |file|
      langCode = file[6,2]
      if langCode != currentLangCode
        result << %(<li><a hreflang="#{langCode}" href="../#{langCode}/">#{LANGUAGE_NAMES[langCode]}</a></li>)
      end
    end

    result << '</ul>'
    result.join LF
  end

  def convert_inline_quoted node
    open, close, is_tag = QUOTE_TAGS[node.type]
    if (role = node.role)
      if is_tag
        if role == 'source'
          # TODO: Read language attribute
          # TODO: Default to source-language attribute
          #puts node.attributes
          lang = node.attr 'language', 'javascript'
          if (syntax_hl = node.document.syntax_highlighter)
            opts = syntax_hl.highlight? ? {
              css_mode: ((doc_attrs = node.document.attributes)[%(#{syntax_hl.name}-css)] || :class).to_sym,
              style: doc_attrs[%(#{syntax_hl.name}-style)],
            } : {}

            # Tokenize
            highlighted, source_offset = syntax_hl.highlight node, node.text, lang, opts
            node.text = highlighted

            # Format
            result_text = syntax_hl.format node, lang, opts

            quoted_text = %(#{result_text})
          else
            quoted_text = %(#{open.chop}#{lang ? %[ class="language-#{lang}" data-lang="#{lang}"] : ''} class="#{role}">#{node.text}#{close})
          end
        else
          quoted_text = %(#{open.chop} class="#{role}">#{node.text}#{close})
        end
      else
        quoted_text = %(<span class="#{role}">#{open}#{node.text}#{close}</span>)
      end
    else
      quoted_text = %(#{open}#{node.text}#{close})
    end

    node.id ? %(<a id="#{node.id}"></a>#{quoted_text}) : quoted_text
  end
end
