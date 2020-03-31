# coding: utf-8
class GbifHtmlConverter < (Asciidoctor::Converter.for 'html5')
  register_for 'html5'

  # Language names in their own language, for use linking to translated documents.
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
    "zh" => "&#20013;&#25991;(&#31616;)",
    "zh-HK" => "&#20013;&#25991;(HK)",
    "zh-TW" => "&#20013;&#25991;(&#32321;)"
  }

  # Used when the label hasn't been translated
  FALLBACK_LABEL = '&#x1f64a;&#x2753;'

  # Links to alternative versions of the same document (other formats, other languages).
  def convert_alternate node
    other_formats_text = node.document.attributes['other_formats_text'] || FALLBACK_LABEL
    # The style is hardcoded here, but should be migrated once we need a custom stylesheet.
    result = [%(<h3 id="otherformatstitle">#{other_formats_text}</h3>)]
    result << [%(<ul class="sectlevel1">)]

    currentLangCode = node.document.attributes['lang']
    if ! currentLangCode
      currentLangCode = 'en'
    end

    pdf_filename = node.document.attributes['pdf_filename']
    pdf_file_text = node.document.attributes['pdf_file_text'] || FALLBACK_LABEL
    result << %(<li><a hreflang="#{currentLangCode}" type="application/pdf" href="#{pdf_filename}">#{pdf_file_text}</a></li>)

    Dir["index.??.adoc"].sort.each do |file|
      langCode = file[6,2]
      if langCode != currentLangCode
        result << %(<li><a hreflang="#{langCode}" href="../#{langCode}/">#{LANGUAGE_NAMES[langCode]}</a></li>)
      end
    end

    result << '</ul>'
    result.join LF
  end

  # Link to a place to contribute edits, such as GitHub.
  def convert_contribute_edit node
    contribute_url = node.document.attributes['contribute_url']
    # contribute_system = 'GitHub'

    if contribute_url
      contribute_title_text = node.document.attributes['contribute_title_text'] || FALLBACK_LABEL
      contribute_edit_text = node.document.attributes['contribute_edit_text'] || FALLBACK_LABEL

      result = [%(<h3 id="contributetitle">#{contribute_title_text}</h3>)]
      result << %(<div id="contributetext"><a href="#{contribute_url}"><img src="data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjxzdmcKICAgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIgogICBpZD0iZ2l0aHViLW1hcmsiCiAgIHZlcnNpb249IjEuMSIKICAgdmlld0JveD0iMCAwIDExLjQ5MjkgMTEuMjA5NDY2IgogICBoZWlnaHQ9IjExLjIwOTQ2Nm1tIgogICB3aWR0aD0iMTEuNDkyOW1tIj4KICA8cGF0aAogICAgIGlkPSJtYXJrIgogICAgIHN0eWxlPSJmaWxsOiMxYjE4MTc7c3Ryb2tlOm5vbmUiCiAgICAgZD0iTSA1Ljc0NjA0LDAgQyAyLjU3MjgxMDEsMCAwLDIuNTcyODA4IDAsNS43NDY3NSBjIDAsMi41Mzg5NDA4IDEuNjQ2NDEsNC42OTI2NSAzLjkyOTk0LDUuNDUyODg2IDAuMjg3NTIsMC4wNTI1NiAwLjM5MjI5LC0wLjEyNDg4NCAwLjM5MjI5LC0wLjI3NzI4NCAwLC0wLjEzNjE3MiAtMC4wMDUsLTAuNDk3NzY5IC0wLjAwOCwtMC45NzcxOTQyIC0xLjU5ODQzOTksMC4zNDcxMzMyIC0xLjkzNTY4OTksLTAuNzcwNDY3IC0xLjkzNTY4OTksLTAuNzcwNDY3IC0wLjI2MTQxLC0wLjY2MzU3NSAtMC42MzgxOCwtMC44NDAzMTYgLTAuNjM4MTgsLTAuODQwMzE2IC0wLjUyMTc2MDEsLTAuMzU2NjU5IDAuMDM5NSwtMC4zNDk2MDMgMC4wMzk1LC0wLjM0OTYwMyAwLjU3NjgsMC4wNDA5MiAwLjg4MDE5LDAuNTkyMzE0IDAuODgwMTksMC41OTIzMTQgMC41MTI1OCwwLjg3ODA2NCAxLjM0NTEzOTksMC42MjQ0MTYgMS42NzI1MDk5LDAuNDc3NjYxIDAuMDUyMiwtMC4zNzE0NzUgMC4yMDAzOCwtMC42MjQ3NjkgMC4zNjQ3OCwtMC43NjgzNSBDIDMuNDIxMzQwMSw4LjE0MTQwNDggMi4wNzk3MzAxLDcuNjQ4MjIyIDIuMDc5NzMwMSw1LjQ0NjE4MyBjIDAsLTAuNjI3MjM5IDAuMjI0MDEsLTEuMTQwMTc4IDAuNTkxNiwtMS41NDE5OTEgLTAuMDU5MywtMC4xNDUzNDUgLTAuMjU2NDcsLTAuNzI5NTQ1IDAuMDU2MSwtMS41MjA4MjYgMCwwIDAuNDgyNiwtMC4xNTQ1MTYgMS41ODA0Mzk5LDAuNTg5MTM5IEMgNC43NjYxMywyLjg0NTE1MyA1LjI1NzksMi43ODEzIDUuNzQ2NSwyLjc3OTE4MyA2LjIzNDM5LDIuNzgxMjgzIDYuNzI2MTYsMi44NDUxNTMgNy4xODUxMywyLjk3MjUwNSA4LjI4MjI2LDIuMjI4ODUgOC43NjM4MSwyLjM4MzM2NiA4Ljc2MzgxLDIuMzgzMzY2IGMgMC4zMTM2MSwwLjc5MTI4MSAwLjExNjQxLDEuMzc1NDgxIDAuMDU3MSwxLjUyMDgyNiAwLjM2ODMsMC40MDE4MTMgMC41OTA5LDAuOTE0NzUyIDAuNTkwOSwxLjU0MTk5MSAwLDIuMjA3NjgzIC0xLjM0MzczLDIuNjkzNDU3OCAtMi42MjM5NiwyLjgzNTYyNzggMC4yMDYzNywwLjE3NzQ0NyAwLjM5MDE3LDAuNTI4MTA4IDAuMzkwMTcsMS4wNjQzMyAwLDAuNzY3OTk4MiAtMC4wMDcsMS4zODc4MjgyIC0wLjAwNywxLjU3NjIxMTIgMCwwLjE1MzgxMiAwLjEwMzM2LDAuMzMyNjcgMC4zOTUxMSwwLjI3NjU3OCBDIDkuODQ3OSwxMC40MzcyODMgMTEuNDkyOSw4LjI4NDk4NTggMTEuNDkyOSw1Ljc0Njc1IDExLjQ5MjksMi41NzI4MDggOC45MTk3NCwwIDUuNzQ1OCwwIiAvPgo8L3N2Zz4K" alt="" style="height: 1.75rem;"/> #{contribute_edit_text}</a></div>)

      result.join LF
    end
  end

  # Extend original convert_inline_quoted method to support inline syntax highlighting.
  #
  # Example: [source javascript]`map.put("value")` or [.source.javascript]`map.put("value")`.
  #
  # See https://github.com/asciidoctor/asciidoctor/issues/1043
  def convert_inline_quoted node
    open, close, is_tag = QUOTE_TAGS[node.type]
    if (role = node.role)
      if is_tag
        if node.has_role? 'source'
          lang = (language = node.roles[1] || node.document.attributes['source-language'])
          if (syntax_hl = node.document.syntax_highlighter)
            opts = syntax_hl.highlight? ? {
              css_mode: ((doc_attrs = node.document.attributes)[%(#{syntax_hl.name}-css)] || :class).to_sym,
              style: doc_attrs[%(#{syntax_hl.name}-style)],
            } : {}

            # Tokenize
            highlighted, source_offset = syntax_hl.highlight node, node.text, lang, opts
            # Chop off trailing newline
            node.text = highlighted.chomp

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
