FROM asciidoctor/docker-asciidoctor:1.0.0
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

# PO4A translation tool
RUN apk add --no-cache diffutils perl-unicode-linebreak po4a

# Git commit plugin
RUN apk add --no-cache openssl openssl-dev cmake ruby-dev ruby-rdoc gcc musl-dev
RUN gem install rugged

# BibTeX plugin
RUN gem install asciidoctor-bibtex
COPY gbif.csl /usr/lib/ruby/gems/2.5.0/gems/csl-styles-1.0.1.10/vendor/styles/

# A2S diagrams (needs Go)
#RUN apk add --no-cache git make musl-dev go
#ENV GOROOT /usr/lib/go
#ENV GOPATH /go
#ENV PATH /go/bin:$PATH
#RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin
#RUN apk add --no-cache go git gcc musl-dev
#go get github.com/asciitosvg/asciitosvg/cmd/a2s

# Stylesheet compiler:
RUN apk add --no-cache ruby-rdoc ruby-bundler
RUN gem install compass --version 0.12.7 && \
    gem install zurb-foundation --version 4.3.2

# Fonts for GBIF style (in particular, Chinese-Japanese-Korean support)
RUN mkdir -p /adoc/fonts && \
    curl -SsL https://download.gbif.org/2020/03/KaiGenGothic.txz | tar -JxvC /adoc/fonts && \
    curl -SsLO https://noto-website-2.storage.googleapis.com/pkgs/NotoSans-hinted.zip && unzip -jod /adoc/fonts NotoSans-hinted.zip && rm -f NotoSans-hinted.zip && \
    curl -SsLO https://noto-website-2.storage.googleapis.com/pkgs/NotoEmoji-unhinted.zip && unzip -jod /adoc/fonts NotoEmoji-unhinted.zip && rm -f NotoEmoji-unhinted.zip && \
    chmod a+r -R /adoc/fonts

# GNU Aspell for Oxford English (UN English) spellcheck
RUN apk add --no-cache aspell aspell-utils && \
    mkdir /adoc/aspell && \
    curl -Ss https://ftp.gnu.org/gnu/aspell/dict/en/aspell6-en-2019.10.06-0.tar.bz2 | tar -jxC /adoc/aspell && \
    cd /adoc/aspell/aspell6-en-2019.10.06-0 && \
    ./configure && make && make install && \
    rm -Rf /adoc/aspell

# Needed by build script.
RUN apk add --no-cache git python3 py3-setuptools
RUN pip3 install Unidecode

COPY inline-syntax-highlighting.patch /adoc/patches/
RUN cd /usr/lib/ruby/gems/2.5.0/gems/asciidoctor-2.0.10/ && patch -p1 < /adoc/patches/inline-syntax-highlighting.patch

COPY gbif-stylesheet/ /adoc/gbif-stylesheet/
RUN cd /adoc/gbif-stylesheet && compass compile

COPY asciidoctor-extensions-lab /adoc/asciidoctor-extensions-lab
COPY gbif-extensions/ /adoc/gbif-extensions/
COPY gbif-templates/ /adoc/gbif-templates/
COPY gbif-theme/ /adoc/gbif-theme/
COPY GbifHtmlConverter.rb /adoc/
COPY asciidoc.dict /adoc/

# GBIF build script
ENV PRIMARY_LANGUAGE=en
COPY build /usr/local/bin/build

WORKDIR /documents
VOLUME /documents

USER asciidoctor:asciidoctor
CMD ["/usr/local/bin/build"]
