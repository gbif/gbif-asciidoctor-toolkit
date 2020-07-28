RUBY_ENGINE == 'opal' ? (require 'term-macro/extension') : (require_relative 'term-macro/extension')

Asciidoctor::Extensions.register do
  inline_macro TermMacro
end
