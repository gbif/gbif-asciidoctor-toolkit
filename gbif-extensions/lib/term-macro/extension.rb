# coding: utf-8
require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

include Asciidoctor

# Include a link to a Darwin Core term, with an optional namespace short prefix.
# Usage:
#   term:dwc[decimalLatitude]
#   term:dwc[dwc:geodeticDatum]
class TermMacro < Extensions::InlineMacroProcessor
  use_dsl

  named :term
  # TODO: support a short form term:[decimalLatitude] which defaults to DWC.
  #using_format :short
  name_positional_attributes 'shortName'

  def process parent, target, attributes
    # Set role for PDF
    attributes['role'] = 'term term_' + target

    shortName = attributes['shortName']

    case target
    when "dwc"
      # Remove a dwc: prefix if it exists
      fullLink = "https://rs.tdwg.org/dwc/terms/"+(shortName.gsub(/^dwc:/, ''))
    when "dna"
      fullLink = "https://rs.gbif.org/terms/1.0/DNADerivedData#"+(shortName.gsub(/^dna:/, ''))
    when "mixs"
      fullLink = "https://rs.gbif.org/terms/1.0/DNADerivedData#"+(shortName.gsub(/^mixs:/, ''))
    when "eco"
      fullLink = "https://rs.tdwg.org/eco/terms/"+(shortName.gsub(/^eco:/, ''))
    end
    anchor = %(<a class="term term_#{target}" href="#{fullLink}" target="_blank">#{shortName}</a>)

    Asciidoctor::Inline.new(parent, :quoted, anchor)
  end
end
