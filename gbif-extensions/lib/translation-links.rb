RUBY_ENGINE == 'opal' ? (require 'translation-links-macro/extension') : (require_relative 'translation-links-macro/extension')

Asciidoctor::Extensions.register do
  if @document.backend == 'revealjs'
    inline_macro HideTranslationLinksMacro
    docinfo_processor TranslationLinksDocinfoProcessor
  else
    if @document.basebackend? 'html'
      inline_macro TranslationLinksMacro
      docinfo_processor TranslationLinksDocinfoProcessor
    end
  end
end
