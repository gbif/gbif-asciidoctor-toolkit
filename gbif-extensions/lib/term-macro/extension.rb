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
    attributes['role'] = 'term'

    shortName = attributes['shortName']

    case target
    when "dwc"
      # Remove a dwc: prefix if it exists
      fullLink = "http://rs.tdwg.org/dwc/terms/"+(shortName.gsub(/^dwc:/, ''))
    when "dna"
      fullLink = "https://rs.gbif.org/extension/gbif/1.0/dna_derived_data_2021-07-05.xml#"+(shortName.gsub(/^dna:/, ''))
    when "mixs"
      fullLink = "https://rs.gbif.org/extension/gbif/1.0/dna_derived_data_2021-07-05.xml#"+(shortName.gsub(/^mixs:/, ''))
    end
    anchor = %(<a class="term" href="#{fullLink}" target="_blank">#{shortName}</a>)

    Asciidoctor::Inline.new(parent, :quoted, anchor)
  end
end
