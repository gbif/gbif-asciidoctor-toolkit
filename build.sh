#!/bin/bash -e

# Run:
#   docker run --rm -it -v $PWD:/documents/ mb.gbif.org:5000/docker-asciidoctor:2.0.6

# Enable the **/*.en.adoc below.
shopt -s globstar
# In case there are no translations.
shopt -s nullglob

# Produce the translated adoc source from the po-files.
if [[ -e po4a.conf ]]; then
	echo "Translating sources"
	po4a -v po4a.conf
	for lang in translations/??.po; do
		langcode=$(basename $lang .po)
		# Replace include and image links to translated alternatives
		for tdoc in $(grep -l -E -e '\.[a-z][a-z]\.adoc' **/*.$langcode.adoc); do
			echo "Replacing includes in $tdoc for $langcode"
			perl -pi -e 's/([A-Za-z0-9_-]+).en.adoc/\1.'$langcode'.adoc/' $tdoc
		done
	done
	echo "Translating source files completed"
else
	echo "No po4a.conf exists, this document will not be translated"
fi
echo

# Generate the output HTML and PDF.
rm -f **/*.??.html **/*.??.pdf *.??.asis
for lang in en translations/??.po; do
	langcode=$(basename $lang .po)
	echo "Building language $langcode"
	mkdir -p $langcode

	# Document title for PDF filename
	title=$(grep -m 1 '^=[^=]' index.$langcode.adoc | rev | cut -d: -f2- | rev | tr : - | tr / - | sed 's/^= *//; s/ /-/g; s/-+/-/g;' | tr '[:upper:]' '[:lower:]')
	echo "Document title in $langcode is “$title”"

	asciidoctor -a lang=$langcode \
				-a imagesdir=../ \
				-a pdf_filename=$title.$langcode.pdf \
				-r asciidoctor-diagram \
				-r /asciidoctor-extensions-lab/lib/git-metadata-preprocessor.rb \
				-r /gbif-extensions/lib/license-url-docinfoprocessor.rb \
				-r /gbif-extensions/lib/translation-links.rb \
				-o $langcode/index.$langcode.html \
				--trace \
				index.$langcode.adoc
				#-T ./asciidoctor-backends/slim/html5/

	asciidoctor-pdf -a lang=$langcode \
					-a media=print \
					-r asciidoctor-diagram \
					-r /asciidoctor-extensions-lab/lib/git-metadata-preprocessor.rb \
					-o $langcode/$title.$langcode.pdf \
					--trace \
					index.$langcode.adoc

	cat > index.$langcode.asis <<-EOF
		Status: 303 See Other
		Location: ./$langcode/
		Content-Type: text/html; charset=UTF-8
		Content-Language: $langcode
		Vary: negotiate,accept-language

		See <a href="./$langcode/">$langcode</a>.
	EOF

	echo "$langcode completed"
	echo
done

# Make translation template
# po4a-gettextize -f asciidoc -M utf-8 -m index.adoc -p translations/index.pot

# Update translation
# po4a-updatepo -f asciidoc -M utf-8 -m index.adoc -p translations/da.po

# po4a-normalize -f asciidoc -M utf-8 translations/da.po

# Translate
# po4a-translate -f asciidoc -M utf-8 -m index.adoc -p translations/da.po -k 0 -l index.da.adoc
