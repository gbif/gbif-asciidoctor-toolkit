require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

# A docinfo processor that appends the Plausible.io code to the bottom of the HTML.
#
# Usage
#
#   :plausible-analytics-data-domain: yourdomain.com
#
# Requires Asciidoctor >= 1.5.2
Asciidoctor::Extensions.register do
  if @document.basebackend? 'html'
    docinfo_processor do
      at_location :footer
      process do |doc|
        next unless (plausible_id = doc.attr 'plausible-analytics-data-domain')
        %(<script defer data-domain="#{plausible_id}" src="https://plausible.io/js/script.file-downloads.js"></script>)
      end
    end
  end
end
