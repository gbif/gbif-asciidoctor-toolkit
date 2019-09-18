require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

include Asciidoctor

# A preprocessor that adds the default translations to documents not written in English.
Extensions.register {
  if @document.attr? 'lang'
    preprocessor do
      process do |document, reader|
        path = '/usr/lib/ruby/gems/2.5.0/gems/asciidoctor-2.0.10/data/locale/attributes-'+document.attr('lang')+'.adoc'
        if File.file?(path)
          file = File.expand_path path
          data = File.read file
          reader.push_include data, file, path
        else
          puts "No default attribute translation file found at "+path
        end

        path = (::File.dirname __FILE__) + '/translate-labels/attributes-'+document.attr('lang')+'.adoc'
        if File.file?(path)
          file = File.expand_path path
          data = File.read file
          reader.push_include data, file, path
        else

          puts "No GBIF attribute translation file found at "+path
        end

        reader
      end
    end
  end
}
