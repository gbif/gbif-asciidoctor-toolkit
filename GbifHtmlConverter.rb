# coding: utf-8
require 'asciidoctor-multipage'

module GbifHtmlConverterBase
  # Language names in their own language, for use linking to translated documents.
  @@language_names = {
    "ar" => "عربية",
    "bg" => "Български",
    "ca" => "català",
    "cs" => "česky",
    "da" => "dansk",
    "de" => "Deutsch",
    "el" => "Ελληνικά",
    "en" => "English",
    "es" => "español",
    "es-CO" => "español (Colombia)",
    "es-ES" => "español (España)",
    "es-419" => "español (Latinoamérica)",
    "eo" => "Esperanto",
    "fa" => "فارسی",
    "fr" => "français",
    "fr-FR" => "français (La France)",
    "gl" => "Galego",
    "hy" => "Հայերեն",
    "hr" => "hrvatski",
    "id" => "Indonesia",
    "it" => "Italiano",
    "he" => "עברית",
    "ko" => "한국어",
    "lt" => "Lietuvių",
    "hu" => "magyar",
    "nl" => "Nederlands",
    "ja" => "日本語",
    "nb" => "norsk (bokmål)",
    "pl" => "polski",
    "pt" => "Português",
    "pt-PT" => "Português (Portugal)",
    "ro" => "română",
    "ru" => "Русский",
    "sk" => "slovenčina",
    "fi" => "suomi",
    "sv" => "svenska",
    "ta" => "தமிழ் ",
    "vi" => "Tiếng Việt",
    "tr" => "Türkçe",
    "uk" => "українська",
    "zh" => "简体中文",
    "zh-CN" => "简体中文",
    "zh-TW" => "繁體中文"
  }

  # Languages written right-to-left
  @@rtl_languages = ['ar', 'fa', 'he', 'ps', 'ur']

  # Used when the label hasn't been translated
  @@fallback_label = '❓ ❓ ❓'

  def self.language_names
    @@language_names
  end

  # This is a COPY of Asciidoctor::Converter::Html5Converter:convert_document, with the
  # GBIF theme (logo, "Contribute" links etc) added around the table of contents.
  # TODO: handle subtitles.
  # TODO: Check MathJAX URL.
  def gbif_convert_document node, contribute_before
    br = %(<br#{slash = @void_element_slash}>)
    unless (asset_uri_scheme = (node.attr 'asset-uri-scheme', 'https')).empty?
      asset_uri_scheme = %(#{asset_uri_scheme}:)
    end
    cdn_base_url = %(#{asset_uri_scheme}//cdnjs.cloudflare.com/ajax/libs)
    linkcss = node.attr? 'linkcss'
    max_width_attr = (node.attr? 'max-width') ? %( style="max-width: #{node.attr 'max-width'};") : ''
    result = ['<!DOCTYPE html>']
    lang_attribute = (node.attr? 'nolang') ? '' : %( lang="#{node.attr 'lang', 'en'}")
    rtl_attribute = (@@rtl_languages.include? (node.attr 'lang')) ? %( dir="rtl") : ''
    result << %(<html#{@xml_mode ? ' xmlns="http://www.w3.org/1999/xhtml"' : ''}#{lang_attribute}#{rtl_attribute}>)
    result << %(<head>
<meta charset="#{node.attr 'encoding', 'UTF-8'}"#{slash}>
<meta http-equiv="X-UA-Compatible" content="IE=edge"#{slash}>
<meta name="viewport" content="width=device-width, initial-scale=1.0"#{slash}>
<meta name="generator" content="Asciidoctor #{node.attr 'asciidoctor-version'}"#{slash}>)
    result << %(<meta name="application-name" content="#{node.attr 'app-name'}"#{slash}>) if node.attr? 'app-name'
    result << %(<meta name="description" content="#{node.attr 'description'}"#{slash}>) if node.attr? 'description'
    result << %(<meta name="keywords" content="#{node.attr 'keywords'}"#{slash}>) if node.attr? 'keywords'
    result << %(<meta name="author" content="#{((authors = node.sub_replacements node.attr 'authors').include? '<') ? (authors.gsub XmlSanitizeRx, '') : authors}"#{slash}>) if node.attr? 'authors'
    result << %(<meta name="copyright" content="#{node.attr 'copyright'}"#{slash}>) if node.attr? 'copyright'
    if node.attr? 'favicon'
      if (icon_href = node.attr 'favicon').empty?
        icon_href = 'favicon.ico'
        icon_type = 'image/x-icon'
      elsif (icon_ext = Helpers.extname icon_href, nil)
        icon_type = icon_ext == '.ico' ? 'image/x-icon' : %(image/#{icon_ext.slice 1, icon_ext.length})
      else
        icon_type = 'image/x-icon'
      end
      result << %(<link rel="icon" type="#{icon_type}" href="#{icon_href}"#{slash}>)
    end
    result << %(<title>#{node.doctitle sanitize: true, use_fallback: true}</title>)

    if DEFAULT_STYLESHEET_KEYS.include?(node.attr 'stylesheet')
      if (webfonts = node.attr 'webfonts')
        result << %(<link rel="stylesheet" href="#{asset_uri_scheme}//fonts.googleapis.com/css?family=#{webfonts.empty? ? 'Open+Sans:300,300italic,400,400italic,600,600italic%7CNoto+Serif:400,400italic,700,700italic%7CDroid+Sans+Mono:400,700' : webfonts}"#{slash}>)
      end
      if linkcss
        result << %(<link rel="stylesheet" href="#{node.normalize_web_path DEFAULT_STYLESHEET_NAME, (node.attr 'stylesdir', ''), false}"#{slash}>)
      else
        result << %(<style>
#{Stylesheets.instance.primary_stylesheet_data}
</style>)
      end
    elsif node.attr? 'stylesheet'
      if linkcss
        result << %(<link rel="stylesheet" href="#{node.normalize_web_path((node.attr 'stylesheet'), (node.attr 'stylesdir', ''))}"#{slash}>)
      else
        result << %(<style>
#{node.read_contents (node.attr 'stylesheet'), start: (node.attr 'stylesdir'), warn_on_failure: true, label: 'stylesheet'}
</style>)
      end
    end

    if ENV["debug"]
      result << %(<style type="text/css">)
      # Mark over logo
      result << %(header a::after {content: '#{ENV["debug"]}'; font-size: 1.2em; font-weight: bolder; background: tomato; color: #fff; padding: 5px; border-radius: 3px; display: block; margin: 2px auto 0; text-align: center; })
      # Hatched background on TOC
      result << %(#toc.toc2 { background: repeating-linear-gradient(45deg, #f8f8f7, #f8f8f7 10px, #f4f4f4 10px, #f4f4f4 20px); })
      # Watermark
      result << %(body.article { background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' version='1.1' height='800px' width='800px'><text transform='translate(200, 200) rotate(-45)' text-anchor='middle' dominant-baseline='middle' fill='rgb(245,245,245)' font-size='80' font-family='sans-serif' font-weight='bold'>#{ENV["debug"]}</text></svg>")})
      result << %(</style>)
    end

    # Special flag emoji font for Windows only.
    # Based on https://github.com/talkjs/country-flag-emoji-polyfill
    result << %(<script type="text/javascript">
      if (/windows/i.test(navigator.userAgent)) {
        const style = document.createElement("style");
        style.textContent = `@font-face {
          font-family: "Twemoji Country Flags";
          unicode-range: U+1F1E6-1F1FF, U+1F3F4, U+E0062-E0063, U+E0065, U+E0067, U+E006C, U+E006E, U+E0073-E0074, U+E0077, U+E007F;
          src: url('https://cdn.jsdelivr.net/npm/country-flag-emoji-polyfill@0.1/dist/TwemojiCountryFlags.woff2') format('woff2');
          font-display: swap;
        }`;
        document.head.appendChild(style);
      }
    </script>)

    if node.attr? 'icons', 'font'
      if node.attr? 'iconfont-remote'
        result << %(<link rel="stylesheet" href="#{node.attr 'iconfont-cdn', %[#{cdn_base_url}/font-awesome/#{FONT_AWESOME_VERSION}/css/font-awesome.min.css]}"#{slash}>)
      else
        iconfont_stylesheet = %(#{node.attr 'iconfont-name', 'font-awesome'}.css)
        result << %(<link rel="stylesheet" href="#{node.normalize_web_path iconfont_stylesheet, (node.attr 'stylesdir', ''), false}"#{slash}>)
      end
    end

    if (syntax_hl = node.syntax_highlighter)
      result << (syntax_hl_docinfo_head_idx = result.size)
    end

    unless (docinfo_content = node.docinfo).empty?
      result << docinfo_content
    end

    result << '</head>'
    id_attr = node.id ? %( id="#{node.id}") : ''
    if (sectioned = node.sections?) && (node.attr? 'toc-class') && (node.attr? 'toc') && (node.attr? 'toc-placement', 'auto')
      classes = [node.doctype, (node.attr 'toc-class'), %(toc-#{node.attr 'toc-position', 'header'})]
    else
      classes = [node.doctype]
    end
    classes << node.role if node.role?
    result << %(<body#{id_attr} class="#{classes.join ' '}">)

    unless (docinfo_content = node.docinfo :header).empty?
      result << docinfo_content
    end

    unless node.noheader
      result << %(<div id="header"#{max_width_attr}>)
      if node.doctype == 'manpage'
        result << %(<h1>#{node.doctitle} Manual Page</h1>)
        if sectioned && (node.attr? 'toc') && (node.attr? 'toc-placement', 'auto')
          result << %(<div id="toc" class="#{node.attr 'toc-class', 'toc'}">
<div id="toctitle">#{node.attr 'toc-title'}</div>
#{node.converter.convert node, 'outline'}
</div>)
        end
        result << (generate_manname_section node) if node.attr? 'manpurpose'
      else
        if node.header?
          unless node.notitle
            segments = node.header.title.rpartition(': ')
            if segments.first.empty?
              result << %(<h1>#{node.header.title}</h1>)
            else
              result << %(<h1>#{segments.first} <small>#{segments.last}</small></h1>)
            end
          end
          details = []
          idx = 1
          node.authors.each do |author|
            details << %(<span id="author#{idx > 1 ? idx : ''}" class="author">#{node.sub_replacements author.name}</span>#{br})
            details << %(<span id="email#{idx > 1 ? idx : ''}" class="email">#{node.sub_macros author.email}</span>#{br}) if author.email
            idx += 1
          end
          if node.attr? 'revnumber'
            details << %(<span id="revnumber">#{((node.attr 'version-label') || '').downcase} #{node.attr 'revnumber'}#{(node.attr? 'revdate') ? ',' : ''}</span>)
          end
          if node.attr? 'revdate'
            details << %(<span id="revdate">#{node.attr 'revdate'}</span>)
          end
          if node.attr? 'revremark'
            details << %(#{br}<span id="revremark">#{node.attr 'revremark'}</span>)
          end
          unless details.empty?
            result << '<div class="details">'
            result.concat details
            result << '</div>'
          end
        end

        if sectioned && (node.attr? 'toc') && (node.attr? 'toc-placement', 'auto')
          result << %(<div id="toc" class="#{node.attr 'toc-class', 'toc'}">
<header id="logo">
  <a href="https://www.gbif.org/">
    <img src="https://docs.gbif.org/style/logo.svg" alt="GBIF – Global Biodiversity Information Facility"#{slash}>
  </a>
</header>
  #{br}
#{convert_alternate node}
  #{br})
          result << %(#{convert_contribute_edit node}#{br}) if contribute_before
          search_text = node.document.attributes['search_text'] || @@fallback_label
          result << %(<h3 id="search">#{search_text}</h3>
          <div id="search_form">
            <form onsubmit="return submitForm(event)" method="GET" style="display: flex;">
              <input type="search" name="q" value="" size="12" id="search_input" style="flex-grow: 1;" />
              <input type="submit" value="🔍" style="width: 3em;" />
            </form>
          </div>
          #{br})
          result << %(<div id="toctitle">#{node.attr 'toc-title'}</div>
#{node.converter.convert node, 'outline'})
          result << %(#{br}#{convert_contribute_edit node}) unless contribute_before
          result << %(#{br}#{convert_debugging_menu node})
          result << %(</div>)
        end
      end
      result << '</div>'
    end

    result << %(<div id="content"#{max_width_attr}>
#{node.content}
</div>)

    if node.footnotes? && !(node.attr? 'nofootnotes')
      result << %(<div id="footnotes"#{max_width_attr}>
<hr#{slash}>)
      node.footnotes.each do |footnote|
        result << %(<div class="footnote" id="_footnotedef_#{footnote.index}">
<a href="#_footnoteref_#{footnote.index}">#{footnote.index}</a>. #{footnote.text}
</div>)
      end
      result << '</div>'
    end

    unless node.nofooter
      result << %(<div id="footer"#{max_width_attr}>)
      result << '<div id="footer-text">'
      result << %(#{node.attr 'version-label'} #{node.attr 'revnumber'}#{br}) if node.attr? 'revnumber'
      result << %(#{node.attr 'last-update-label'} #{node.attr 'docdatetime'}) if (node.attr? 'last-update-label') && !(node.attr? 'reproducible')
      result << '</div>'
      result << '</div>'
    end

    # JavaScript (and auxiliary stylesheets) loaded at the end of body for performance reasons
    # See http://www.html5rocks.com/en/tutorials/speed/script-loading/

    if syntax_hl
      if syntax_hl.docinfo? :head
        result[syntax_hl_docinfo_head_idx] = syntax_hl.docinfo :head, node, cdn_base_url: cdn_base_url, linkcss: linkcss, self_closing_tag_slash: slash
      else
        result.delete_at syntax_hl_docinfo_head_idx
      end
      if syntax_hl.docinfo? :footer
        result << (syntax_hl.docinfo :footer, node, cdn_base_url: cdn_base_url, linkcss: linkcss, self_closing_tag_slash: slash)
      end
    end

    if node.attr? 'stem'
      eqnums_val = node.attr 'eqnums', 'none'
      eqnums_val = 'AMS' if eqnums_val.empty?
      eqnums_opt = %( equationNumbers: { autoNumber: "#{eqnums_val}" } )
      # IMPORTANT inspect calls on delimiter arrays are intentional for JavaScript compat (emulates JSON.stringify)
      result << %(<script type="text/x-mathjax-config">
MathJax.Hub.Config({
  messageStyle: "none",
  tex2jax: {
    inlineMath: [#{INLINE_MATH_DELIMITERS[:latexmath].inspect}],
    displayMath: [#{BLOCK_MATH_DELIMITERS[:latexmath].inspect}],
    ignoreClass: "nostem|nolatexmath"
  },
  asciimath2jax: {
    delimiters: [#{BLOCK_MATH_DELIMITERS[:asciimath].inspect}],
    ignoreClass: "nostem|noasciimath"
  },
  TeX: {#{eqnums_opt}}
})
MathJax.Hub.Register.StartupHook("AsciiMath Jax Ready", function () {
  MathJax.InputJax.AsciiMath.postfilterHooks.Add(function (data, node) {
    if ((node = data.script.parentNode) && (node = node.parentNode) && node.classList.contains("stemblock")) {
      data.math.root.display = "block"
    }
    return data
  })
})
</script>
<script src="#{cdn_base_url}/mathjax/#{MATHJAX_VERSION}/MathJax.js?config=TeX-MML-AM_HTMLorMML"></script>)
    end

    search_results_header_text = node.document.attributes['search_results_header_text'] || @@fallback_label
    search_results_query_text = node.document.attributes['search_results_query_text'] || @@fallback_label
    search_no_results_text = node.document.attributes['search_no_results_text'] || @@fallback_label
    result << %(<script src="https://unpkg.com/lunr/lunr.js"></script>)

    unless node.document.attributes['lang'] == 'en'
      result << %(<script src="https://unpkg.com/lunr-languages/lunr.stemmer.support.js"></script>)
      result << %(<script src="https://unpkg.com/lunr-languages/lunr.#{node.document.attributes['lang']}.js"></script>)
    end

    result << %(<script type="text/javascript">
      var inputField = document.getElementById('search_input');

      function searchResults(query) {
        var documentContent = document.getElementById('content');

        while (documentContent.firstChild) {
          documentContent.removeChild(documentContent.firstChild)
        }

        var searchResultsHeader = document.createElement('h2');
        documentContent.appendChild(searchResultsHeader);
        searchResultsHeader.innerHTML = `#{search_results_header_text}`
        window.scrollTo(searchResultsHeader);

        var searchResultsDescription = document.createElement('div');
        documentContent.appendChild(searchResultsDescription);
        searchResultsDescription.innerHTML = `#{search_results_query_text}`

        var searchResults = document.createElement('ul');
        documentContent.appendChild(searchResults);

        return searchResults;
      }

      function submitForm(event) {
        event.preventDefault();

        const query = inputField.value;

        const resultsHTML = searchResults(query);

        fetch('lunr-index.json')
          .then((response) => response.json())
          .then((data) => {
            idx = lunr.Index.load(data.index);
            store = data.store;
            var results = idx.search(query);
            console.log("Search for", query, "gave", results.length, "results.");
            if (results.length === 0) {
              resultsHTML.innerHTML = '#{search_no_results_text}';
              return true;
            }
            var pages = results.map((x) => {
              var anchorPosition = -1; //x.ref.indexOf('#');
              var storeKey = anchorPosition > 0 ? x.ref.substr(0, anchorPosition) : x.ref;
              return { data: store[storeKey], match: x };
            });
            var list = pages.map((x) => template(x));
            resultsHTML.innerHTML = list.join('');
          })
          .catch((err) => function(err){
            console.error(err);
            resultsHTML.innerHTML = 'Unable to complete search - please report the error';
          });

        return true;
      }

      var hlStart = '<span class="hl">';
      var hlEnd = '</span>';
      var template = ({ data, match }) => {
        var metadata = match.matchData.metadata;

        // use first 200 chars as fallback
        var text = `${data.text.substr(0, 200)}${data.text.length > 199 ? '...' : ''}`;

        // Lunr has no concept of highlighting it seems. The developer says it is the most frequent request.

        // Instead we try to do a lazy highlighting - I suspect that it will be fine in most cases.
        // If it isn't then we should look at something like mark.js which seem to solve this issue.

        // if there only one search term, then try to highlight it
        if (Object.keys(metadata).length === 1) {
          // only attempt with the first occurrences of the word
          // (though there may be many more)
          var matchedTerm = metadata[Object.keys(metadata)[0]];

          // sometimes it can be an a title that match. Lunr does not tell us which. WE cannot do much in that case
          if (matchedTerm.text && matchedTerm.text.position) {
            var matchText = matchedTerm.text.position[0];

            text = data.text.slice(0, matchText[0]) + hlStart + data.text.slice(matchText[0]);
            text = text.slice(0, matchText[0] + matchText[1] + hlStart.length) + hlEnd + text.slice(matchText[0] + matchText[1] + hlStart.length);
            var start = matchText[0];
            var length = matchText[1] + hlStart.length + hlEnd.length + 200;
            var begin = Math.max(0, start - 100);
            text = text.substr(begin, length)
          }
        }

        return `
        <li>
          <article>
            <h5>
              <a href="${match.ref}">${data.title}</a>
            </h5>
            <div>
              ... ${text} ...
            </div>
          </article>
        </li>
        `;
      };
    </script>
    )

    unless (docinfo_content = node.docinfo :footer).empty?
      result << docinfo_content
    end

    result << '</body>'
    result << '</html>'
    result.join LF
  end

  # Links to alternative versions of the same document (other formats, other languages).
  def convert_alternate node
    other_formats_text = node.document.attributes['other_formats_text'] || @@fallback_label
    # The style is hardcoded here, but should be migrated once we need a custom stylesheet.
    result = [%(<h3 id="otherformatstitle">#{other_formats_text}</h3>)]
    result << [%(<ul class="sectlevel1">)]

    currentLangCode = node.document.attributes['lang']
    if ! currentLangCode
      currentLangCode = 'en'
    end

    pdf_filename = node.document.attributes['pdf_filename']
    pdf_file_text = node.document.attributes['pdf_file_text'] || @@fallback_label
    result << %(<li><a hreflang="#{currentLangCode}" type="application/pdf" href="#{pdf_filename}">#{pdf_file_text}</a></li>)

    Dir["index.??.adoc", "index.??-??.adoc", "index.??-???.adoc"]
      .map { |file| file.match(/index\.(.+)\.adoc/)[1] }
      .sort.each do |langCode|
      if langCode != currentLangCode && !File.file?("translations/#{langCode}.hidden")
        result << %(<li><a hreflang="#{langCode}" href="../#{langCode}/">#{@@language_names[langCode]}</a></li>)
      end
    end

    result << '</ul>'
    result.join LF
  end

  # Link to a place to contribute edits, such as GitHub.
  def convert_contribute_edit node
    improve_url = node.document.attributes['improve_url']
    translate_url = node.document.attributes['translate_url']
    issue_url = node.document.attributes['issue_url']
    contribute_url = node.document.attributes['contribute_url']
    # contribute_system = 'GitHub'

    if ! improve_url.to_s.strip.empty? or ! issue_url.to_s.strip.empty? or ! contribute_url.to_s.strip.empty?
      contribute_title_text = node.document.attributes['contribute_title_text'] || @@fallback_label
      contribute_improve_text = node.document.attributes['contribute_improve_text'] || @@fallback_label
      contribute_translate_text = node.document.attributes['contribute_translate_text'] || @@fallback_label
      contribute_issue_text = node.document.attributes['contribute_issue_text'] || @@fallback_label
      contribute_edit_text = node.document.attributes['contribute_edit_text'] || @@fallback_label

      result = [%(<h3 id="contributetitle">#{contribute_title_text}</h3>)]

      if ! improve_url.to_s.strip.empty?
        result << %(<div id="improvetext"><a href="#{improve_url}"><img src="data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI5NiIgaGVpZ2h0PSI5NiIgaWQ9ImltcHJvdmUtbWFyayIgdmVyc2lvbj0iMS4xIj48Y2lyY2xlIHN0eWxlPSJmaWxsOiMxNzVjYTE7IiBjeD0iNDgiIGN5PSI0OCIgcj0iNDgiLz48ZyBzdHlsZT0iZmlsbDojZmZmZmZmIj48cGF0aCBkPSJtIDQ1LjA5OTk5NSwyNC4wMDk5NDggYSAxLjM3NDUwNjMsMS4zNjMyMDE4IDAgMCAxIDEuMzUzNjc5LDEuMzgyMzUxIHYgNC4zNzA3NTUgaCA0LjQwNzYxOCBhIDEuMzc0NTA2MywxLjM2MzIwMTggMCAxIDEgMCwyLjcyNTk4OCBoIC00LjQwNzYxOCB2IDQuMzcwNzU0IGEgMS4zNzQ1MDYzLDEuMzYzMjAxOCAwIDEgMSAtMi43NDg3OTksMCB2IC00LjM3MDc1NCBoIC00LjQxNzEwMyBhIDEuMzc0NTA2MywxLjM2MzIwMTggMCAxIDEgMCwtMi43MjU5ODggaCA0LjQxNzEwMyB2IC00LjM3MDc1NSBhIDEuMzc0NTA2MywxLjM2MzIwMTggMCAwIDEgMS4zOTUxMiwtMS4zODIzNTEgeiIvPjxwYXRoIGQ9Im0gMzQuNjY3OTMxLDE4LjAwMDE1MSBhIDEuMzc0NTA2MywxLjM2MzIwMTggMCAwIDEgMS4zNTM2NzksMS4zODIzNTIgdiAxLjc3NTM2MSBoIDEuNzgxMjg3IGEgMS4zNzQ1MDYzLDEuMzYzMjAxOCAwIDEgMSAwLDIuNzI1OTg4IEggMzYuMDIxNjEgdiAxLjc3NTM2MSBhIDEuMzc0NTA2MywxLjM2MzIwMTggMCAxIDEgLTIuNzQ4NTI1LDAgViAyMy44ODM4NTIgSCAzMS40ODI1MiBhIDEuMzc0NTA2MywxLjM2MzIwMTggMCAxIDEgMCwtMi43MjU5ODggaCAxLjc5MDU2NSB2IC0xLjc3NTM2MSBhIDEuMzc0NTA2MywxLjM2MzIwMTggMCAwIDEgMS4zOTQ4NDYsLTEuMzgyMzUyIHoiLz48cGF0aCBkPSJtIDMwLjQ1NDM5MiwzOC4wNzI4MzkgYSAxLjM3NDUwNjMsMS4zNjMyMDE4IDAgMCAxIDEuMzUzNjc5LDEuMzgyMzUxIHYgNC4zNzA3NTUgaCA0LjQwNzYxOSBhIDEuMzc0NTA2MywxLjM2MzIwMTggMCAxIDEgMCwyLjcyNjAwMSBoIC00LjQwNzYxOSB2IDQuMzcwNzU1IGEgMS4zNzQ1MDYzLDEuMzYzMjAxOCAwIDEgMSAtMi43NDg3MzEsMCB2IC00LjM3MDc1NSBoIC00LjQwNzY4NyBhIDEuMzc0NTA2MywxLjM2MzIwMTggMCAxIDEgMCwtMi43MjYwMDEgSCAyOS4wNTkzNCBWIDM5LjQ1NTE5IGEgMS4zNzQ1MDYzLDEuMzYzMjAxOCAwIDAgMSAxLjM5NTA1MiwtMS4zODIzNTEgeiIvPjxwYXRoIGQ9Im0gMjIuNTg0MDU3LDMwLjc0Njg3NCBhIDEuMzc0NTA2MywxLjM2MzIwMTggMCAwIDEgMS4zNTM2OCwxLjM4MjQyIHYgMS43NzUyOTMgaCAxLjc5MDU2NSBhIDEuMzc0NTA2MywxLjM2MzIwMTggMCAxIDEgMCwyLjcyNTk4OCBoIC0xLjc5MDU2NSB2IDEuNzc1MzYxIGEgMS4zNzQ1MDYzLDEuMzYzMjAxOCAwIDEgMSAtMi43NDg3MzEsMCB2IC0xLjc3NTM2MSBoIC0xLjc5MDQ5NyBhIDEuMzc0NTA2MywxLjM2MzIwMTggMCAxIDEgMCwtMi43MjU5ODggaCAxLjc5MDQ5NyB2IC0xLjc3NTI5MyBhIDEuMzc0NTA2MywxLjM2MzIwMTggMCAwIDEgMS4zOTUwNTEsLTEuMzgyNDIgeiIvPjxwYXRoIGQ9Im0gMjcuMDQ3OTYyLDIzLjgwODc0IGEgMS4zNzQ2MDIzLDEuMzYzMTA2NSAwIDAgMSAwLjk1MTU2OCwwLjM5ODg3MiBsIDQ5LjU5Nzk3NCw0OS4xODMyNTYgYSAxLjM3NDYwMjMsMS4zNjMxMDY1IDAgMCAxIDAsMS45Mjc0OTUgbCAtMi4zMDE2NzQsMi4yODI0NzEgYSAxLjM3NDYwMjMsMS4zNjMxMDY1IDAgMCAxIC0xLjk0MzgyMiwwIEwgMjMuNzU0MDM0LDI4LjQxNzY0NSBhIDEuMzc0NjAyMywxLjM2MzEwNjUgMCAwIDEgMCwtMS45Mjc1NjIgbCAyLjMwMTY3NCwtMi4yODI0NzEgYSAxLjM3NDYwMjMsMS4zNjMxMDY1IDAgMCAxIDAuOTkyMjU0LC0wLjM5ODg3MiB6Ii8+PC9nPjwvc3ZnPg==" alt="" style="height: 1.5rem; margin: 0.25em 0;"/> #{contribute_improve_text}</a></div>)
      end
      if ! issue_url.to_s.strip.empty?
        result << %(<div id="issuestext"><a href="#{issue_url}"><img src="data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI2NjEiIGhlaWdodD0iNjYxIiB2ZXJzaW9uPSIxLjEiIGlkPSJpc3N1ZS1tYXJrIiBzdHlsZT0iZmlsbC1ydWxlOmV2ZW5vZGQiPjxwYXRoIHN0eWxlPSJmaWxsOiM0ZDlhMzQiIGlkPSJtYXJrIiBkPSJNIDY2MSwzMzAuNSBDIDY2MSwxNDcuOTcyIDUxMy4wMjgsMCAzMzAuNSwwIDE0Ny45NzIsMCAwLDE0Ny45NzIgMCwzMzAuNSAwLDUxMy4wMjggMTQ3Ljk3Miw2NjEgMzMwLjUsNjYxIDUxMy4wMjgsNjYwLjk1NCA2NjEsNTEyLjk4MSA2NjEsMzMwLjUgWiIvPjxwYXRoIHN0eWxlPSJmaWxsOiNmZmZmZmYiIGQ9Im0gMzk0LDE0NSB2IDYwLjk5NyBDIDM5NCwyMjkuMzIxIDQxNS4wNzgsMjM0IDQzNS40ODcsMjM0IEggNDkxIFoiLz48cGF0aCBzdHlsZT0iZmlsbDojZmZmZmZmIiBkPSJNIDQ0OC4xNzcsMzM0LjkzMiBIIDI2My4zMDMgYyAtNi42MDEsMCAtMTEuOTQ3LC01LjM1MyAtMTEuOTQ3LC0xMS45NTEgMCwtNi42MDcgNS4zNDYsLTExLjk0MyAxMS45NDcsLTExLjk0MyBoIDE4NC44NzQgYyA2LjYwMSwwIDExLjk1NSw1LjMzNiAxMS45NTUsMTEuOTQzIDAsNi41ODkgLTUuMzU0LDExLjk1MSAtMTEuOTU1LDExLjk1MSBtIDAsNjYuMTgxIEggMjk3LjgzNiBjIC02LjYsMCAtMTEuOTQ2LC01LjMzNiAtMTEuOTQ2LC0xMS45NDIgMCwtNi41OSA1LjM1NCwtMTEuOTM0IDExLjk0NiwtMTEuOTM0IGggMTUwLjM0MSBjIDYuNjAxLDAgMTEuOTU1LDUuMzQ0IDExLjk1NSwxMS45MzQgMCw2LjYwNiAtNS4zNTQsMTEuOTQyIC0xMS45NTUsMTEuOTQyIG0gMCw2Ni4yMTYgaCAtMTI4LjU1IGMgLTYuNiwwIC0xMS45NDYsLTUuMzUzIC0xMS45NDYsLTExLjk1MSAwLC02LjYwNyA1LjM1NSwtMTEuOTUxIDExLjk0NiwtMTEuOTUxIGggMTI4LjU1IGMgNi42MDEsMCAxMS45NTUsNS4zNDQgMTEuOTU1LDExLjk1MSAwLDYuNTk4IC01LjM1NCwxMS45NTEgLTExLjk1NSwxMS45NTEgTSAyNjAuOTUsMjQ0LjgxNCBoIDY3LjcyNiBjIDYuNTkyLDAgMTEuOTQ3LDUuMzcgMTEuOTQ3LDExLjk2IDAsNi42MDcgLTUuMzU1LDExLjk0MiAtMTEuOTQ3LDExLjk0MiBIIDI2MC45NSBjIC02LjYxLDAgLTExLjk0NywtNS4zMzUgLTExLjk0NywtMTEuOTQyIDAsLTYuNTkgNS4zNDYsLTExLjk2IDExLjk0NywtMTEuOTYgbSAwLC02Ni4xOSBoIDY3LjcyNiBjIDYuNTkyLDAgMTEuOTQ3LDUuMzM2IDExLjk0NywxMS45NDMgMCw2LjU4IC01LjM1NSwxMS45NDIgLTExLjk0NywxMS45NDIgSCAyNjAuOTUgYyAtNi42MSwwIC0xMS45NDcsLTUuMzUzIC0xMS45NDcsLTExLjk0MiAwLC02LjYwNyA1LjM0NiwtMTEuOTQzIDExLjk0NywtMTEuOTQzIG0gMTUwLjQyNyw3NC41MjYgYyAtMTkuMjY1LDAgLTM4LjQ3OCwtMTYuMzUzIC0zOC40NzgsLTQwLjIzOCBWIDEzOSBIIDIyNi42MzIgYyAtMTEuODk1LDAgLTIxLjUzMiw5LjY2IC0yMS41MzIsMjEuNTMzIHYgMTE5LjE4MyBsIDcwLjkwMiwxNDkuODA1IC0xLjY0NCw4NS4zNzkgSCA0NzIuNDYgYyAxMS44OTQsMCAyMS41NCwtOS42MzMgMjEuNTQsLTIxLjUyNCBWIDI1My4xNSBaIE0gMjU4Ljg3Myw1MjIgbCAxLjQ4OCwtODcuNzIzIC03MS4wODMsMzQuMjcxIHogbSAtNjQuNjU1LC0yMjQuNzk4IC03MS4wODMsMzQuMjggNjAuNDE2LDEyNS4yMTkgNzEuMTAxLC0zNC4yODggeiBtIC0yMC45MzUsLTQzLjQwMyBjIC0yLjg2MywtNS45NDEgLTEwLjAxNywtOC40MzIgLTE1Ljk2OSwtNS41NjEgbCAtNDkuNTUyLDIzLjkwMyBjIC01Ljk0MywyLjg3MSAtOC40NDMsMTAuMDIyIC01LjU3MSwxNS45NDYgbCAxMy41OTEsMjguMTc1IDcxLjA5MSwtMzQuMjk3IHoiIC8+PC9zdmc+" alt="" style="height: 1.5rem; margin: 0.25em 0;"/> #{contribute_issue_text}</a></div>)
      end
      if ! contribute_url.to_s.strip.empty?
        result << %(<div id="contributetext"><a href="#{contribute_url}"><img src="data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjxzdmcKICAgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIgogICBpZD0iZ2l0aHViLW1hcmsiCiAgIHZlcnNpb249IjEuMSIKICAgdmlld0JveD0iMCAwIDExLjQ5MjkgMTEuMjA5NDY2IgogICBoZWlnaHQ9IjExLjIwOTQ2Nm1tIgogICB3aWR0aD0iMTEuNDkyOW1tIj4KICA8cGF0aAogICAgIGlkPSJtYXJrIgogICAgIHN0eWxlPSJmaWxsOiMxYjE4MTc7c3Ryb2tlOm5vbmUiCiAgICAgZD0iTSA1Ljc0NjA0LDAgQyAyLjU3MjgxMDEsMCAwLDIuNTcyODA4IDAsNS43NDY3NSBjIDAsMi41Mzg5NDA4IDEuNjQ2NDEsNC42OTI2NSAzLjkyOTk0LDUuNDUyODg2IDAuMjg3NTIsMC4wNTI1NiAwLjM5MjI5LC0wLjEyNDg4NCAwLjM5MjI5LC0wLjI3NzI4NCAwLC0wLjEzNjE3MiAtMC4wMDUsLTAuNDk3NzY5IC0wLjAwOCwtMC45NzcxOTQyIC0xLjU5ODQzOTksMC4zNDcxMzMyIC0xLjkzNTY4OTksLTAuNzcwNDY3IC0xLjkzNTY4OTksLTAuNzcwNDY3IC0wLjI2MTQxLC0wLjY2MzU3NSAtMC42MzgxOCwtMC44NDAzMTYgLTAuNjM4MTgsLTAuODQwMzE2IC0wLjUyMTc2MDEsLTAuMzU2NjU5IDAuMDM5NSwtMC4zNDk2MDMgMC4wMzk1LC0wLjM0OTYwMyAwLjU3NjgsMC4wNDA5MiAwLjg4MDE5LDAuNTkyMzE0IDAuODgwMTksMC41OTIzMTQgMC41MTI1OCwwLjg3ODA2NCAxLjM0NTEzOTksMC42MjQ0MTYgMS42NzI1MDk5LDAuNDc3NjYxIDAuMDUyMiwtMC4zNzE0NzUgMC4yMDAzOCwtMC42MjQ3NjkgMC4zNjQ3OCwtMC43NjgzNSBDIDMuNDIxMzQwMSw4LjE0MTQwNDggMi4wNzk3MzAxLDcuNjQ4MjIyIDIuMDc5NzMwMSw1LjQ0NjE4MyBjIDAsLTAuNjI3MjM5IDAuMjI0MDEsLTEuMTQwMTc4IDAuNTkxNiwtMS41NDE5OTEgLTAuMDU5MywtMC4xNDUzNDUgLTAuMjU2NDcsLTAuNzI5NTQ1IDAuMDU2MSwtMS41MjA4MjYgMCwwIDAuNDgyNiwtMC4xNTQ1MTYgMS41ODA0Mzk5LDAuNTg5MTM5IEMgNC43NjYxMywyLjg0NTE1MyA1LjI1NzksMi43ODEzIDUuNzQ2NSwyLjc3OTE4MyA2LjIzNDM5LDIuNzgxMjgzIDYuNzI2MTYsMi44NDUxNTMgNy4xODUxMywyLjk3MjUwNSA4LjI4MjI2LDIuMjI4ODUgOC43NjM4MSwyLjM4MzM2NiA4Ljc2MzgxLDIuMzgzMzY2IGMgMC4zMTM2MSwwLjc5MTI4MSAwLjExNjQxLDEuMzc1NDgxIDAuMDU3MSwxLjUyMDgyNiAwLjM2ODMsMC40MDE4MTMgMC41OTA5LDAuOTE0NzUyIDAuNTkwOSwxLjU0MTk5MSAwLDIuMjA3NjgzIC0xLjM0MzczLDIuNjkzNDU3OCAtMi42MjM5NiwyLjgzNTYyNzggMC4yMDYzNywwLjE3NzQ0NyAwLjM5MDE3LDAuNTI4MTA4IDAuMzkwMTcsMS4wNjQzMyAwLDAuNzY3OTk4MiAtMC4wMDcsMS4zODc4MjgyIC0wLjAwNywxLjU3NjIxMTIgMCwwLjE1MzgxMiAwLjEwMzM2LDAuMzMyNjcgMC4zOTUxMSwwLjI3NjU3OCBDIDkuODQ3OSwxMC40MzcyODMgMTEuNDkyOSw4LjI4NDk4NTggMTEuNDkyOSw1Ljc0Njc1IDExLjQ5MjksMi41NzI4MDggOC45MTk3NCwwIDUuNzQ1OCwwIiAvPgo8L3N2Zz4K" alt="" style="height: 1.5rem; margin: 0.25em 0;"/> #{contribute_edit_text}</a></div>)
      end
      if ! translate_url.to_s.strip.empty?
        result << %(<div id="translatetext"><a href="#{translate_url}"><img src="data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjxzdmcKICAgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIgogICB3aWR0aD0iMTEuNDkyODM5bW0iCiAgIGhlaWdodD0iMTEuNDkyODM5bW0iCiAgIHZpZXdCb3g9IjAgMCAxMS40OTI4MzkgMTEuNDkyODM5IgogICB2ZXJzaW9uPSIxLjEiCiAgIGlkPSJnaXRodWItbWFyayI+CiAgPHBhdGgKICAgICBpZD0ibWFyayIKICAgICBkPSJNIDUuNzQ2NDE5MiwwIEEgNS43NDY0ODUxLDUuNzQ2NDg1MSAwIDAgMCAwLDUuNzQ2NDE5MyA1Ljc0NjQ4NTEsNS43NDY0ODUxIDAgMCAwIDUuNzQ2NDE5MiwxMS40OTI4MzggNS43NDY0ODUxLDUuNzQ2NDg1MSAwIDAgMCAxMS40OTI4MzgsNS43NDY0MTkzIDUuNzQ2NDg1MSw1Ljc0NjQ4NTEgMCAwIDAgNS43NDY0MTkyLDAgWiBNIDYuNTU2MTg4OSwxLjg3OTQ3MTggQyA3LjYxMTEwNTQsMS44NjQ5NDY1IDguNjcxNTEwMSwyLjAwMjg5IDkuNjg4Mjk3NSwyLjI5MzQgYyAwLjExNjIwNCwwLjAzODczNCAwLjQ2NDk3NDUsMC4xMTYzODQ4IDAuMjcxMzAxMSwwLjMxMDA1ODYgLTAuMTE2MjA0MiwwLjExNjIwNDIgLTAuNjE5NjY4MSwwIC0wLjczNTg3MjMsMCBDIDguNDQ5MDMxMywyLjUyNTk4OSA3LjYzNTI1NzYsMi41MjYwMTE2IDYuODYwNTYzMiwyLjY0MjIxNiA2LjAwODM5ODUsMi43NTg0MjAyIDUuMTU2NDA3NCwzLjAyOTYxMSA0LjQ5NzkxNjYsMy42MTA2MzIyIDQuMTEwNTY5LDMuODgxNzc1NCAzLjUyOTUwMDMsNC44NDk5MDA5IDMuNTI5NTAwMyw0Ljk2NjEwNTEgMy40OTA3NjUzLDUuMDgyMzA5MyAzLjMzNTg2OTMsNS42MjQ0MTc4IDIuNzE2MTEzMiw1LjU0Njk0ODMgMi40ODM3MDQ4LDUuNTA4MjEzNiAyLjI5MDE4NjYsNS40MzExNDc2IDIuMDk2NTEyOCw1LjM1MzY3ODQgMS40NzY3NTY4LDUuMTk4NzM5MiAxLjU5MjY5MDMsNC41NDAyMDExIDEuNjMxNDI0OSw0LjM4NTI2MTkgMi4yMTI0NDYyLDIuNjgwOTMzIDQuMDMzMTY5NiwyLjA5OTUyMzIgNS41MDUwOTA0LDEuOTQ0NTg0MSA1Ljg1MzcwMywxLjkwNTg0OTQgNi4yMDQ1NSwxLjg4NDMxMzYgNi41NTYxODg5LDEuODc5NDcxOCBaIG0gMS4zNTAzMDUsMS4zODIzNDQ2IGMgMC43MzU5NjAyLDAgMS41MTA1MDIzLDAuMTE2MjcyIDEuNTEwNTAyMywwLjExNjI3MiAwLjA3NzQ3LDAgMC4xMTYyNzE5LDAuMDc3NTYgMC4xMTYyNzE5LDAuMTU1MDI5MSAwLDAuMDc3NDcgLTAuMDM4ODAyLDAuMTU0NTEyNyAtMC4xMTYyNzE5LDAuMTU0NTEyNyBIIDkuMTA3NDU0MyBjIC0xLjA0NTgzODQsMCAtMS43ODIxMTkzLDAuMTU1MjA5OSAtMi4zMjQ0MDU4LDAuNDY1MDg3OCBDIDYuMjQwNzYxNCw0LjQ2MjU5NjEgNS44NTM3NzAyLDQuOTI3MjE0OCA1LjYyMTM2MjMsNS41ODU3MDU1IDUuNTgyNjI4NCw1LjYyNDQzOTUgNS41MDQ5MDk5LDUuOTczMjU2MSA1LjE5NTAzMTgsNS45MzQ1MjEzIEwgNC40OTc5MTY2LDUuODU3MDA2NiBDIDQuMTg4MDM4NSw1Ljc0MDgwMjQgNC4xODc4ODA1LDUuNDY5OTA1MyA0LjIyNjYxNTIsNS4zOTI0MzU2IDQuMjY1MzUsNS4xMjEyOTI1IDQuMzgxNzEyNCw0Ljg0OTY5NzcgNC40OTc5MTY2LDQuNjE3Mjg5MyA0LjY5MTU5MDMsNC4zNDYxNDU5IDQuOTYyNjkwOCw0LjA3NTA5MDYgNS4zMTEzMDM3LDMuODgxNDE2OSA1Ljk2OTc5NDUsMy40OTQwNjkzIDYuODk5MzkwOCwzLjI2MTgxNjQgNy45MDY0OTM5LDMuMjYxODE2NCBaIE0gOC4yMzM2MDYsNC41MzYxNTcyIGMgMC4wOTMzNjYsLTAuMDAyMTIgMC4xOTA4MDk4LC0wLjAwMTIyIDAuMjkyNDg4NCwwLjAwMzYyIDAuMzg3MzQ3NiwwIDAuMTkzNjczOSwwLjI3MTMwMTEgMCwwLjI3MTMwMTQgQyA3LjU5NjQ2MDUsNC43NzIzNDA5IDcuMTcwNDg2Myw1LjM5MjI1NjggNi45MzgwNzc2LDUuOTczMjc4MyA2Ljg2MDYwNzksNi4xNjY5NTIgNi43MDU5MTUsNi4yMDU3OTk0IDYuNDczNTA2Niw2LjE2NzA2NSA2LjM1NzMwMjQsNi4xMjgzMzA1IDYuMjAyMjI4LDYuMTI4MTUgNi4yNDA5NjI3LDUuODU3MDA2MSA2LjM0OTkwNDEsNS4zNDg2MTI0IDYuODMzMTExOSw0LjU2NzkzMTIgOC4yMzM2MDYsNC41MzYxNTY2IFogTSAxLjk4MDI0MDksNi4xNjcwNjU1IGMgMC4yMzI0MDg0LDAgMC41ODEwMDExLDAuMTE1ODAwNCAwLjg1MjE0NDMsMC4xOTMyNjk2IDAuMzA5ODc3OSwwLjA3NzQ3IDAuNDY0NTcxMywwLjM0ODk1MTYgMC40NjQ1NzEzLDAuNTgxMzYgMCwxLjM5NDQ1MSAxLjIzOTUxNjUsMi4zMjM4ODkxIDEuNzgxODAzMSwyLjMyMzg4OTEgMC4yMzI0MDg2LDAgMC4xNTQ5NjIyLDAuMjcxMzAxNCAwLjAzODc1OCwwLjI3MTMwMTQgLTAuMTU0OTM5LDAuMDc3NDcgLTAuMzg3MTI0OSwwLjA3NzUxNSAtMC41MDMzMjg2LDAuMDc3NTE0IC0wLjI3MTE0MzEsMCAtMC41NDIyNDM2LC0wLjAzODc3OSAtMC44MTMzODcxLC0wLjA3NzUxNCBDIDMuMzc0NzE5NCw5LjQ1OTQxNjQgMy4wMjU5OTExLDkuMzQyOTYzNCAyLjcxNjExMzIsOS4xMTA1NTUgMS45ODAxNTMsOC42NDU3Mzc5IDEuNTUzODY1MSw3Ljc5Mzc5MjEgMS40NzYzOTU2LDYuODI1NDIzMiBjIDAsLTAuMjMyNDA4NyAtMC4wMzg0NDEsLTAuNjk3MDkyNyAwLjUwMzg0NTMsLTAuNjU4MzU3NyB6IG0gMi40Nzg5MTg1LDAuNDY0NTcxIDAuNjk3MTE0OSwwLjA3NzUxNSBjIDAuMTU0OTM4OSwwLjAzODczNCAwLjI3MTMyMzgsMC4xMTYzODQ3IDAuMzEwMDU4NiwwLjMxMDA1ODYgMC4xNTQ5Mzg5LDAuOTY4MzY4NiAwLjczNjA5OCwxLjM1NTU0MDMgMS4xMjM0NDU3LDEuNDcxNzQ0OCAwLjA3NzQ3LDAgMC4xMTU3NTUyLDAuMDM4ODAyIDAuMTE1NzU1MiwwLjExNjI3MTkgMCwwLjA3NzQ3IC0wLjAzODI4NSwwLjExNjI5NDQgLTAuMTE1NzU1MiwwLjE1NTAyOTIgLTAuMTkzNjczNywwIC0wLjM0ODkwNTgsOGUtNyAtMC41MDM4NDUzLDAgLTAuNTAzNTUxMywwIC0xLjAwNjg1OTksLTAuMjMyNzY5NiAtMS4zNTU0NzI4LC0wLjYyMDExNzIgQyA0LjQyMDU4MjMsNy43OTM1MjU5IDQuMjI2NTkzLDcuNDQ1MjkxOSA0LjE4Nzg1OCw3LjAxOTIwOTggNC4xNDkxMjMzLDYuNzA5MzMxNyA0LjMwNDIyMDIsNi42MzE2MzY1IDQuNDU5MTU5NCw2LjYzMTYzNjUgWiBtIDEuOTc1NTg5NywwLjE5Mzc4NjcgaCAwLjM0ODI5OTQgYyAwLjExNjIwNDIsMCAwLjE1NTAyOTEsMC4xNTUwNTE5IDAuMTU1MDI5MSwwLjE5Mzc4NjYgMC4wMzg3MzQsMC4zODczNDc0IDAuMjcxMzkxNiwwLjU0MjEzMSAwLjQyNjMzMDYsMC42MTk2MDA1IDAuMDc3NDcsMC4wMzg3MzQgMC4wMzg2NDQsMC4xOTM3ODYzIC0wLjE1NTAyOTIsMC4xOTM3ODYzIC0wLjIzMjQwODQsMCAtMC40MjU5MDQsLTAuMDc3NTgzIC0wLjU4MDg0MzIsLTAuMTkzNzg2MyBDIDYuNDM0ODYyMSw3LjQ4Mzg3MTEgNi4yNzk3Miw3LjI1MTU5NTUgNi4yNzk3Miw2Ljk4MDQ1MjMgYyAwLC0wLjE1NDkzODkgMC4xNTUwMjkxLC0wLjE1NTAyOTEgMC4xNTUwMjkxLC0wLjE1NTAyOTEgeiIKICAgICBzdHlsZT0iZmlsbDojMDAwMDAwO3N0cm9rZTpub25lOyIgLz4KPC9zdmc+Cg==" alt="" style="height: 1.5rem; margin: 0.25em 0;"/> #{contribute_translate_text}</a></div>)
      end

      result.join LF
    end
  end

  # Debugging links
  def convert_debugging_menu node

    if ENV["debug"]
      result = [%(<h3 id="debugging">Debugging</h3>)]

      result << %(<p style="font-style: italic; font-size: 80%;">This menu will not be shown on the published document.</p>)

      result << %(<div id="highlightanchors"><a href="javascript:(function(){ var anchors = document.body.querySelectorAll('[id], [name]'); Array.prototype.forEach.call(anchors, function (element) { var link = document.createElement('a'); var hash = '#'%20+%20element.id%20||%20element.name;%20link.href%20=%20hash;%20link.innerText%20=%20hash;%20link.style.cssText%20=%20'background:hotpink%20!important;%20color:white%20!important;';%20element.insertBefore(link,%20element.firstChild);%20});%20})();"><span style="height: 1.5rem; margin: 0.25em 0;"/>&#9875;</span> Highlight anchors</a></div>)

      result.join LF
    end
  end

  # Extend original convert_inline_quoted method to support inline syntax highlighting.
  #
  # Example: [source javascript]`map.put("value")` or [.source.javascript]`map.put("value")`.
  #
  # See https://github.com/asciidoctor/asciidoctor/issues/1043
  def convert_inline_quoted_impl node, quote_tags
    open, close, is_tag = quote_tags[node.type]
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

# Extend the HTML 5 converter with support for inline syntax highlighting
# and the GBIF theme (logo etc).
class GbifHtml5Converter < (Asciidoctor::Converter.for 'html5')
  include GbifHtmlConverterBase
  register_for 'html5'

  def convert_document(node)
    gbif_convert_document(node, true)
  end

  def convert_inline_quoted node
    convert_inline_quoted_impl node, QUOTE_TAGS
  end
end

# Extend the Multi-Page HTML 5 converter with support for inline syntax highlighting
# and the GBIF theme (logo etc).
class GbifMultipageHtml5Converter < (Asciidoctor::Converter.for 'multipage_html5')
  include GbifHtmlConverterBase
  register_for 'gbif_multipage_html5'

  # This is a COPY of MultipageHtml5Converter:convert_document, except the if node.processed → super
  # is replaced by a call to gbif_convert_document from above.
  # Process Document (either the original full document or a processed page)
  def convert_document(node)

    # make sure document has original converter reference
    check_root(node)

    if node.processed
      # This node (an individual page) can now be handled by
      # Html5Converter.
      # GBIF: super would be the MultipageHtml5Converter anyway, so the following line would be a hack
      #super
      #Asciidoctor::Converter::Html5Converter.instance_method(:convert_document).bind(self).call(node)
      # But we want the one mixed in here anyway:
      gbif_convert_document(node, false)
    else
      # This node is the original full document which has not yet been
      # processed; this is the entry point for the extension.

      # Turn off extensions to avoid running them twice.
      # FIXME: DocinfoProcessor, InlineMacroProcessor, and Postprocessor
      # extensions should be retained. Is this possible with the API?
      #Asciidoctor::Extensions.unregister_all

      # Check toclevels and multipage-level attributes
      mplevel = node.document.attr('multipage-level', 1).to_i
      toclevels = node.document.attr('toclevels', 2).to_i
      if toclevels < mplevel
        logger.warn 'toclevels attribute should be >= multipage-level'
      end
      if mplevel < 0
        logger.warn 'multipage-level attribute must be >= 0'
        mplevel = 0
      end
      node.document.set_attribute('multipage-level', mplevel.to_s)

      # Set multipage chunk types
      set_multipage_attrs(node)

      # FIXME: This can result in a duplicate ID without a warning.
      # Set the "id" attribute for the Document, using the "docname", which is
      # based on the file name. Then register the document ID using the
      # document title. This allows cross-references to refer to (1) the
      # top-level document itself or (2) anchors in top-level content (blocks
      # that are specified before any sections).
      node.id = node.attributes['docname']
      node.register(:refs, [node.id,
                            (Inline.new(parent = node,
                                        context = :anchor,
                                        text = node.doctitle,
                                        opts = {:type => :ref,
                                                :id => node.id})),
                            node.doctitle])

      # Generate navigation links for all pages
      generate_nav_links(node)

      # Create and save a skeleton document for generating the TOC lists,
      # but don't attempt to create outline for nested documents.
      unless node.nested?
        # if the original converter has the @full_outline set already, we are about
        # to replace it. That's not supposed to happen, and probably means we encountered
        # a document structure we aren't prepared for. Log an error and move on.
        logger.error "Regenerating document outline, something wrong?" if node.mp_root.full_outline
        node.mp_root.full_outline = new_outline_doc(node)
      end

      # Save the document catalog to use for each part/chapter page.
      @catalog = node.catalog

      # Retain any book intro blocks, delete others, and add a list of sections
      # for the book landing page.
      parts_list = Asciidoctor::List.new(node, :ulist)
      node.blocks.delete_if do |block|
        if block.context == :section
          part = block
          part.convert
          text = %(<<#{part.id},#{part.captioned_title}>>)
          if (desc = block.attr('desc')) then text << %( – #{desc}) end
          parts_list << Asciidoctor::ListItem.new(parts_list, text)
        end
      end
      # Matt: Hide the list of sections if we have a table of contents
      unless node.attr? 'toc'
        node << parts_list
      end

      # Add navigation links
      add_nav_links(node)

      # Mark page as processed and return converted result
      node.processed = true
      node.convert
    end
  end

  # This is a COPY of MultipageHtml5Converter:generate_nav_links, except the "Home" link
  # is shortened to omit the title, and the text Previous/Up/Next is removed.
  # Generate navigation links for all pages in document; save HTML to nav_links
  def generate_nav_links(doc)
    pages = doc.find_by(context: :section) {|section|
      [:root, :branch, :leaf].include?(section.mplevel)}
    pages.insert(0, doc)
    pages.each do |page|
      page_index = pages.find_index(page)
      links = []
      if page.mplevel != :root
        previous_page = pages[page_index-1]
        parent_page = page.parent
        home_page = doc
        # NOTE: There are some non-breaking spaces (U+00A0) below, in
        # the "links <<" lines and "links.join" line.
        if previous_page != parent_page
          links << %(← <<#{previous_page.id}>>)
        end
        links << %(↑ <<#{parent_page.id}>>) unless home_page == parent_page
        home_label = doc.attributes['navigation_home'] || @@fallback_label
        links << %(⌂ <<#{home_page.id},#{home_label}>>)
      end
      if page_index != pages.length-1
        next_page = pages[page_index+1]
        links << %(<<#{next_page.id}>> →)
      end
      block = Asciidoctor::Block.new(parent = doc,
                                     context = :paragraph,
                                     opts = {:source => links.join(' | '),
                                             :subs => :default})
      page.nav_links = block.content
    end
    return
  end

  # This is a COPY of MultipageHtml5Converter:convert_outline.  There are no changes,
  # I'm not sure why it's necessary — something to do with the class variable @@full_outline,
  # but I thought that was shared with all instances of the heirarchy.
  # Override Html5Converter convert_outline() to return a custom TOC
  # outline.
  def convert_outline(node, opts = {})
    doc = node.document
    # Find this node in the @full_outline skeleton document
    page_node = doc.mp_root.full_outline.find_by(id: node.id).first
    # Create a skeleton document for this particular page
    custom_outline_doc = new_outline_doc(doc.mp_root.full_outline, for_page: page_node)
    opts[:page_id] = node.id
    # Generate an extra TOC entry for the root page. Add additional styling if
    # the current page is the root page.
    root_file = %(#{doc.attr('docname')}#{doc.attr('outfilesuffix')})
    root_link = %(<a href="#{root_file}">#{doc.doctitle}</a>)
    classes = ['toc-root']
    classes << 'toc-current' if node.id == doc.attr('docname')
    root = %(<span class="#{classes.join(' ')}">#{root_link}</span>)
    # Create and return the HTML
    %(<p>#{root}</p>#{generate_outline(custom_outline_doc, opts)})
  end

  # This is a COPY of MultipageHtml5Converter:convert_section.  The mini-ToC has been commented.
  # Process a Section. Each Section will either be split off into its own page
  # or processed as normal by Html5Converter.
  def convert_section(node)
    doc = node.document
    if doc.processed
      # This node can now be handled by Html5Converter.
      super
    else
      # This node is from the original document and has not yet been processed.

      # Create a new page for this section
      page = Asciidoctor::Document.new([],
                                       {:attributes => doc.attributes.clone,
                                        :doctype => doc.doctype,
                                        :header_footer => !doc.attr?(:embedded),
                                        :safe => doc.safe})
      # Retain webfonts attribute (why is doc.attributes.clone not adequate?)
      page.set_attr('webfonts', doc.attr(:webfonts))
      # Save sectnum for use later (a Document object normally has no sectnum)
      if node.parent.respond_to?(:numbered) && node.parent.numbered
        page.sectnum = node.parent.sectnum
      end

      page.mp_root = doc.mp_root

      # Process node according to mplevel
      if node.mplevel == :branch
        # Retain any part intro blocks, delete others, and add a list
        # of sections for the part landing page.
        chapters_list = Asciidoctor::List.new(node, :ulist)
        node.blocks.delete_if do |block|
          if block.context == :section
            chapter = block
            chapter.convert
            text = %(<<#{chapter.id},#{chapter.captioned_title}>>)
            # NOTE, there is a non-breaking space (Unicode U+00A0) below.
            if desc = block.attr('desc') then text << %( – #{desc}) end
            #Matt: Commented.
            #chapters_list << Asciidoctor::ListItem.new(chapters_list, text)
            true
          end
        end
        # Add chapters list to node, reparent node to new page, add
        # node to page, mark as processed, and add page to @pages.
        node << chapters_list
        reparent(node, page)
        page.blocks << node
      else # :leaf
        # Reparent node to new page, add node to page, mark as
        # processed, and add page to @pages.
        reparent(node, page)
        page.blocks << node
      end

      # Add navigation links using saved HTML
      page.nav_links = node.nav_links
      add_nav_links(page)

      # Mark page as processed and add to collection of pages
      @pages << page
      page.id = node.id
      page.catalog = @catalog
      page.mplevel = node.mplevel
      page.processed = true
    end
  end

  def convert_inline_quoted node
    convert_inline_quoted_impl node, QUOTE_TAGS
  end
end

# Allow inline syntax highlighting with either Pygments or Coderay.
# Note the patch in inline-syntax-highlighting.patch, which replaces the root CSS class for Pygments.
# See also https://github.com/asciidoctor/asciidoctor/issues/1043#issuecomment-487235035
module SyntaxHighlighterBaseWithInline
  def format node, lang, opts
    class_attr_val = opts[:nowrap] ? %(#{@pre_class} highlight nowrap) : %(#{@pre_class} highlight)
    if (transform = opts[:transform])
      transform[(pre = { 'class' => class_attr_val }), (code = lang ? { 'data-lang' => lang } : {})]
      # NOTE: make sure data-lang is the last attribute on the code tag to remain consistent with 1.5.x
      if (lang = code.delete 'data-lang')
        code['data-lang'] = lang
      end
      if (node.block?)
        %(<pre#{pre.map {|k, v| %[ #{k}="#{v}"] }.join}><code#{code.map {|k, v| %[ #{k}="#{v}"] }.join}>#{node.content}</code></pre>)
      else
        %(<span#{pre.map {|k, v| %[ #{k}="#{v}"] }.join}><code#{code.map {|k, v| %[ #{k}="#{v}"] }.join}>#{node.text}</code></span>)
      end
    else
      if (node.block?)
        %(<pre class="#{class_attr_val}"><code#{lang ? %[ data-lang="#{lang}"] : ''}>#{node.content}</code></pre>)
      else
        %(<span class="#{class_attr_val}"><code#{lang ? %[ data-lang="#{lang}"] : ''}>#{node.text}</code></span>)
      end
    end
  end
end

class Asciidoctor::SyntaxHighlighter::CodeRayWithInlineAdapter < Asciidoctor::SyntaxHighlighter.for('coderay')
  include SyntaxHighlighterBaseWithInline
  register_for 'coderay'
end

class Asciidoctor::SyntaxHighlighter::PygmentsWithInlineAdapter < Asciidoctor::SyntaxHighlighter.for('pygments')
  include SyntaxHighlighterBaseWithInline
  register_for 'pygments'
end

# This (and the following method) adds support for defining
# :section-refsig: §, and not having it followed by a space.
# See https://github.com/asciidoctor/asciidoctor/issues/3498
# It is a copy of the original method, with the commented lines
# added/changed.
class Asciidoctor::Section
  # (see AbstractBlock#xreftext)
  def xreftext xrefstyle = nil
    if (val = reftext) && !val.empty?
      val
    elsif xrefstyle
      if @numbered
        case xrefstyle
        when 'full'
          if (type = @sectname) == 'chapter' || type == 'appendix'
            quoted_title = sub_placeholder (sub_quotes '_%s_'), title
          else
            quoted_title = sub_placeholder (sub_quotes @document.compat_mode ? %q(``%s'') : '"`%s`"'), title
          end
          if (signifier = @document.attributes[%(#{type}-refsig)])
            # These two lines added/modified.
            space = (signifier.match? /§$/) ? '' : ' '
            %(#{signifier}#{space}#{sectnum '.', ','} #{quoted_title})
          else
            %(#{sectnum '.', ','} #{quoted_title})
          end
        when 'short'
          if (signifier = @document.attributes[%(#{@sectname}-refsig)])
            # These two lines added/modified.
            space = (signifier.match? /§$/) ? '' : ' '
            %(#{signifier}#{space}#{sectnum '.', ''})
          else
            sectnum '.', ''
          end
        else # 'basic'
          (type = @sectname) == 'chapter' || type == 'appendix' ? (sub_placeholder (sub_quotes '_%s_'), title) : title
        end
      else # apply basic styling
        (type = @sectname) == 'chapter' || type == 'appendix' ? (sub_placeholder (sub_quotes '_%s_'), title) : title
      end
    else
      title
    end
  end
end

class Asciidoctor::AbstractBlock
  def xreftext xrefstyle = nil
    if (val = reftext) && !val.empty?
      val
    # NOTE xrefstyle only applies to blocks with a title and a caption or number
    elsif xrefstyle && @title && @caption
      case xrefstyle
      when 'full'
        quoted_title = sub_placeholder (sub_quotes @document.compat_mode ? %q(``%s'') : '"`%s`"'), title
        if @numeral && (caption_attr_name = CAPTION_ATTRIBUTE_NAMES[@context]) && (prefix = @document.attributes[caption_attr_name])
          # These two lines added/modified.
          space = (prefix.match? /§$/) ? '' : ' '
          %(#{prefix}#{space}#{@numeral}, #{quoted_title})
        else
          %(#{@caption.chomp '. '}, #{quoted_title})
        end
      when 'short'
        if @numeral && (caption_attr_name = CAPTION_ATTRIBUTE_NAMES[@context]) && (prefix = @document.attributes[caption_attr_name])
          # These two lines added/modified.
          space = (prefix.match? /§$/) ? '' : ' '
          %(#{prefix}#{space}#{@numeral})
        else
          @caption.chomp '. '
        end
      else # 'basic'
        title
      end
    else
      title
    end
  end
end
