# coding: utf-8
require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

include Asciidoctor

# Include a link to a term term, with an optional namespace short prefix.
# Usage:
#   term:dwc[decimalLatitude]     Generates the link https://rs.tdwg.org/dwc/terms/decimalLatitude
#   term:dwc[dwc:geodeticDatum]   Generates the link https://rs.tdwg.org/dwc/terms/geodeticDatum
#   term:dwciri[behavior]         Generates the link https://rs.tdwg.org/dwc/iri/behavior
#   term:dna[samp_name]           Generates the link https://rs.gbif.org/terms/1.0/DNADerivedData#samp_name
#   term:mixs[samp_name]          Generates the link https://rs.gbif.org/terms/1.0/DNADerivedData#samp_name
#   term:eco[absentTaxa]          Generates the link https://rs.tdwg.org/eco/terms/absentTaxa
#   term:obis[measurementTypeID]  Generates the link http://rs.iobis.org/obis/terms/measurementTypeID
#   term:gbif[datasetKey]         Generates the link http://rs.gbif.org/terms/1.0/datasetKey
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
    when "dwciri"
      # Remove a dwc: prefix if it exists
      fullLink = "https://rs.tdwg.org/dwc/iri/"+(shortName.gsub(/^dwciri:/, ''))
    when "dna"
      fullLink = "https://rs.gbif.org/terms/1.0/DNADerivedData#"+(shortName.gsub(/^dna:/, ''))
    when "mixs"
      fullLink = "https://rs.gbif.org/terms/1.0/DNADerivedData#"+(shortName.gsub(/^mixs:/, ''))
    when "eco"
      fullLink = "https://rs.tdwg.org/eco/terms/"+(shortName.gsub(/^eco:/, ''))
    when "obis"
      fullLink = "http://rs.iobis.org/obis/terms/"+(shortName.gsub(/^obis:/, ''))
    when "gbif"
      fullLink = "http://rs.gbif.org/terms/1.0/"+(shortName.gsub(/^gbif:/, ''))
    end
    anchor = %(<a class="term term_#{target}" href="#{fullLink}" target="_blank">#{shortName}</a>)

    Asciidoctor::Inline.new(parent, :quoted, anchor)
  end
end
