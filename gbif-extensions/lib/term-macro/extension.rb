# coding: utf-8
require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

include Asciidoctor

# Include a link to a Darwin Core term, with an optional namespace short prefix.
# Usage:
#   term:[decimalLatitude]
#   term:[dwc:geodeticDatum]
class TermMacro < Extensions::InlineMacroProcessor
  use_dsl

  named :term
  using_format :short
  name_positional_attributes 'shortName'

  def process parent, target, attributes

    # Set role for PDF
    attributes['role'] = 'term'

    shortName = attributes['shortName']
    # Remove a dwc: prefix if it exists
    fullLink = "http://rs.tdwg.org/dwc/terms/"+(shortName.gsub(/^dwc:/, ''))
    anchor = %(<a class="term" href="#{fullLink}">#{shortName}</a>)

    Asciidoctor::Inline.new(parent, :quoted, anchor)
  end
end
