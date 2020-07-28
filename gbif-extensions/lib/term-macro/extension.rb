# coding: utf-8
require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

include Asciidoctor

class TermMacro < Extensions::InlineMacroProcessor
  use_dsl

  named :term
  using_format :short
  name_positional_attributes 'shortName'

  def process parent, target, attributes

    # Set role for PDF
    attributes['role'] = 'term'

    shortName = attributes['shortName']
    fullLink = "http://rs.tdwg.org/dwc/terms"+shortName
    anchor = %(<a class="term" href="#{fullLink}">#{shortName}</a>)

    Asciidoctor::Inline.new(parent, :quoted, anchor)
  end
end
