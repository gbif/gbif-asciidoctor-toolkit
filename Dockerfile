FROM asciidoctor/docker-asciidoctor:1.3.0
LABEL MAINTAINERS="Matthew Blissett <mblissett@gbif.org>"

# FixUID: https://github.com/boxboat/fixuid
RUN addgroup --gid 1000 asciidoctor && adduser --uid 1000 --ingroup asciidoctor --home /documents --shell /bin/bash --disabled-password --gecos "" asciidoctor
RUN USER=asciidoctor && \
    GROUP=asciidoctor && \
    curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.4/fixuid-0.4-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml
ENTRYPOINT ["fixuid", "-q"]

ARG gems_path=/usr/lib/ruby/gems/2.7.0/gems
ARG adoc_path=$gems_path/asciidoctor-2.0.12

# PO4A translation tool
RUN apk add --no-cache diffutils perl-unicode-linebreak perl-yaml-tiny po4a

# Git commit plugin
RUN apk add --no-cache openssl openssl-dev cmake ruby-dev ruby-rdoc gcc musl-dev
RUN gem install rugged

# A2S diagrams (needs Go)
#RUN apk add --no-cache make musl-dev go
#ENV GOROOT /usr/lib/go
#ENV GOPATH /go
#ENV PATH /go/bin:$PATH
#RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin
#RUN apk add --no-cache go gcc musl-dev
#go get github.com/asciitosvg/asciitosvg/cmd/a2s

# "Meme" diagram type
#RUN apk add --no-cache imagemagick

# Stylesheet compiler:
RUN apk add --no-cache ruby-rdoc ruby-bundler
RUN gem install compass --version 0.12.7 && \
    gem install zurb-foundation --version 4.3.2

# Required for PDF handling of certain images
RUN apk add graphicsmagick-dev
RUN gem install prawn-gmagick

# Fonts for GBIF style (in particular, Chinese-Japanese-Korean support)
RUN mkdir -p /adoc/fonts && \
    curl -SsL https://download.gbif.org/2020/03/KaiGenGothic.txz | tar -JxvC /adoc/fonts && \
    curl -SsLO https://noto-website-2.storage.googleapis.com/pkgs/NotoSans-hinted.zip && unzip -jod /adoc/fonts NotoSans-hinted.zip && rm -f NotoSans-hinted.zip && \
    curl -SsLO https://noto-website-2.storage.googleapis.com/pkgs/NotoEmoji-unhinted.zip && unzip -jod /adoc/fonts NotoEmoji-unhinted.zip && rm -f NotoEmoji-unhinted.zip && \
    chmod a+r -R /adoc/fonts

# GNU Aspell for Oxford English (UN English) spellcheck
RUN apk add --no-cache aspell aspell-utils && \
    mkdir /adoc/aspell && \
    curl -Ss https://ftp.gnu.org/gnu/aspell/dict/en/aspell6-en-2020.12.07-0.tar.bz2 | tar -jxC /adoc/aspell && \
    cd /adoc/aspell/aspell6-en-2020.12.07-0 && \
    ./configure && make && make install && \
    rm -Rf /adoc/aspell

# Python for Unidecode; inotify for continuous build script.  Image compression.
RUN apk add --no-cache python3 py3-setuptools py3-pip inotify-tools brotli libwebp-tools patch
RUN pip3 install Unidecode

COPY inline-syntax-highlighting.patch /adoc/patches/
RUN cd $adoc_path/ && patch -p1 < /adoc/patches/inline-syntax-highlighting.patch

# Use dashes for attribute translations language, and set zh to zh-CN.
RUN ln -s $adoc_path/data/locale/attributes-es.adoc $adoc_path/data/locale/attributes-es-419.adoc && \
    ln -s $adoc_path/data/locale/attributes-es.adoc $adoc_path/data/locale/attributes-es-CO.adoc && \
    ln -s $adoc_path/data/locale/attributes-es.adoc $adoc_path/data/locale/attributes-es-ES.adoc && \
    ln -s $adoc_path/data/locale/attributes-fr.adoc $adoc_path/data/locale/attributes-fr-FR.adoc && \
    ln -s $adoc_path/data/locale/attributes-pt.adoc $adoc_path/data/locale/attributes-pt-PT.adoc && \
    ln -s $adoc_path/data/locale/attributes-zh_CN.adoc $adoc_path/data/locale/attributes-zh.adoc

# RUN gem install asciidoctor-question
COPY asciidoctor-question /adoc/asciidoctor-question/
RUN cd /adoc/asciidoctor-question && rake build && rake install

RUN gem install asciidoctor-multipage

# Lunr.JS indexing
COPY lunr/ /adoc/lunr/
RUN apk add --no-cache nodejs npm && \
    cd /adoc/lunr && \
    npm install

COPY gbif-stylesheet/ /adoc/gbif-stylesheet/
RUN cd /adoc/gbif-stylesheet && compass compile

# BibTeX style
COPY gbif.csl $gems_path/csl-styles-1.0.1.10/vendor/styles/

COPY asciidoctor-extensions-lab/ /adoc/asciidoctor-extensions-lab/
COPY gbif-extensions/ /adoc/gbif-extensions/
COPY gbif-theme/ /adoc/gbif-theme/
COPY GbifHtmlConverter.rb asciidoc.dict /adoc/

# GBIF build scripts
ENV PRIMARY_LANGUAGE=en
COPY build continuous /usr/local/bin/

WORKDIR /documents
VOLUME /documents

USER asciidoctor:asciidoctor
CMD ["/usr/local/bin/build"]
