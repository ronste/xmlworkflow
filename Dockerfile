FROM debian:stable-slim

LABEL maintainer="Ronald Steffen, FU Berlin <r.steffen@fu-berlin.de>"

# Basic packages
ENV PACKAGES \
    wget \
	zip \
    nano \
	curl \
    unzip \
    sudo \
    # for pagedjs, Mathjax
    nodejs \
    npm \
    # for Saxon-HE
    default-jre \
    # for PDF conversion with Pandoc
    texlive \
    # for weasyprint
    weasyprint \
    python3 \
    pip \
    # for xml processing/validation
    libxml2-utils \
    xmlstarlet \
    # for pandoc custom writer
    build-essential \
    liblua5.4-dev \
    lua5.4 \
    libreadline-dev \
    pipx \ 
    # for pagedjs/chromium/pupeteer
    libxkbcommon-x11-0
    

# install packages
RUN set -xe && apt-get update  \
    && cd home \
	&& apt-get install -y $PACKAGES \
    && pipx install panflute \
    && pipx ensurepath

# install required tools not available through the Debian repository
RUN set -xe && cd root \
    && mkdir xmlworkflow \
    && mkdir xmlworkflow/lib \
    && mkdir xmlworkflow/work \
    && mkdir xmlworkflow/work/media \
    && mkdir xmlworkflow/work/metadata\
    && cd xmlworkflow/lib \
    # Pandoc
    && wget https://github.com/jgm/pandoc/releases/download/3.1.11.1/pandoc-3.1.11.1-linux-arm64.tar.gz \
    && tar xvzf pandoc-3.1.11.1-linux-arm64.tar.gz --strip-components 1 -C /usr/local/ \
    # Saxon-HE
    # Note: Current Debian Saxon-HE package is verion 9.9 !!!
    && wget https://github.com/Saxonica/Saxon-HE/releases/download/SaxonHE12-4/SaxonHE12-4J.zip \
    && unzip -d SaxonHE12-4J SaxonHE12-4J.zip \
    # mathjax, esm for weasyprint
    && npm install esm yargs mathjax-full \
    # pagedjs/puppeteer
    && npm install -g pagedjs-cli puppeteer \
    # for pandoc custom writer
    && wget https://luarocks.org/releases/luarocks-3.9.2.tar.gz \
    && tar zxpf luarocks-3.9.2.tar.gz \
    && cd luarocks-3.9.2 \
    && ./configure && make && sudo make install \
    && luarocks install xml2lua \
    && eval "$(luarocks path)" \
    && cd .. \
    ## clean up
    && rm pandoc-3.1.11.1-linux-arm64.tar.gz SaxonHE12-4J.zip luarocks-3.9.2.tar.gz \
    ## just
    && npm install -g just-install \
    # create an alias for the just command
    && echo '#!/usr/bin/env bash' >> /bin/processDocx \
    && echo "cd /root/xmlworkflow/work" \
    && echo 'just "$@"' >> /bin/processDocx \
    && chmod u+x /bin/processDocx

COPY "xmlContainer/themes" "/root/xmlworkflow/themes"
COPY "xmlContainer/work/Dummy_Article_Template.docx" "/root/xmlworkflow/work/Dummy_Article_Template.docx"

