FROM debian:bookworm

LABEL maintainer="Ronald Steffen, FU Berlin <r.steffen@fu-berlin.de>"

# Basic packages
ENV SYS_PACKAGES \
    apt-utils \
    wget \
	zip \
    nano \
	curl \
    unzip \
    sudo

# development packages
ENV DEV_PACKAGES \
    # for pandoc custom writer
    build-essential \
    php \
    php-zip \
    php-xml

ENV DEV_PACKAGES_2 \
    # for weasyprint
    python3 \
    pip \
    # for Saxon-HE
    default-jre

ENV DEV_PACKAGES_3 \
    # for pagedjs, Mathjax
    nodejs \
    npm 

# tools
ENV TOOLS_PACKAGES \
    # for PDF conversion with Pandoc
    texlive \
    # for weasyprint
    weasyprint \
    # for xml processing/validation
    libxml2-utils \
    xmlstarlet

ENV TOOLS_PACKAGES_2 \
    # for pandoc custom writer
    liblua5.4-dev \
    lua5.4 \
    libreadline-dev \
    libpcre3 \
    libpcre3-dev \
    pipx \ 
    # for pagedjs/chromium/pupeteer
    libxkbcommon-x11-0

# install packages; packages are installed in separate runs due to frequent timeout errors with the Debian server 
RUN set -xe && apt-get update  \
    && cd home \
	&& apt-get install -y $SYS_PACKAGES
RUN set -xe && apt-get update  \
    && cd home \
	&& apt-get install -y $DEV_PACKAGES
RUN set -xe && apt-get update  \
    && cd home \
	&& apt-get install -y $DEV_PACKAGES_2
RUN set -xe && apt-get update  \
    && cd home \
	&& apt-get install -y $TOOLS_PACKAGES
RUN set -xe && apt-get update  \
    && cd home \
	&& apt-get install -y $TOOLS_PACKAGES_2
    # && pipx install panflute \
    # && pipx ensurepath
RUN set -xe && apt-get update  \
    && cd home \
	&& apt-get install -y $DEV_PACKAGES_3

# install required tools not available through the Debian repository
RUN set -xe && cd root \
    && git clone https://github.com/ronste/xmlworkflow.git \
    # && mkdir xmlworkflow \
    && mkdir xmlworkflow/lib \
    && mkdir xmlworkflow/work \
    && mkdir xmlworkflow/work/media \
    && mkdir xmlworkflow/work/metadata\
    && cd xmlworkflow/lib \
    ## docx2jats
    && git clone https://github.com/Vitaliy-1/docxToJats.git \
    # Pandoc
    # Install pandoc from source to support dynamic linking of lrexlib-pcre
    && wget https://hackage.haskell.org/package/pandoc-3.5/pandoc-3.5.tar.gz \
    && tar xvzf pandoc-3.5.tar.gz \
    && cd pandoc-3.5 \
    && curl -sSL https://get.haskellstack.org/ | sh \
    && curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh \
    && . /root/.ghcup/env \
    && cabal update \
    && cabal install pandoc-cli \
    && cd .. \
    && echo 'export PATH="$HOME/.cabal/bin:$PATH"' >> ~/.bashrc \
    && rm -rf pandoc-3.5
RUN set -xe && cd root \
    # Saxon-HE
    # Note: Current Debian Saxon-HE package is verion 9.9 !!!
    && wget https://github.com/Saxonica/Saxon-HE/releases/download/SaxonHE12-4/SaxonHE12-4J.zip \
    && unzip -d SaxonHE12-4J SaxonHE12-4J.zip \
    # mathjax, esm for weasyprint
    && npm install esm yargs mathjax-full \
    # pagedjs/puppeteer, html validation
    # RS: 15.10.2024 pagedjs-cli and puppeteer generate deprecation warnings, version 0.5 beta of pagedjs-cli exists but still contains deprecated dependencies
    && npm install -g pagedjs-cli puppeteer html-validate \
    # for pandoc custom writer
    && wget https://luarocks.org/releases/luarocks-3.9.2.tar.gz \
    && tar zxpf luarocks-3.9.2.tar.gz \
    && cd luarocks-3.9.2 \
    && ./configure && make && sudo make install \
    && luarocks install xml2lua \
    && luarocks install lrexlib-pcre \
    && eval "$(luarocks path)" \
    && cd .. \
    ## clean up
    # && rm pandoc-3.1.12.2-linux-${arch}.tar.gz \
    && rm SaxonHE12-4J.zip luarocks-3.9.2.tar.gz \
    ## just
    && npm install -g just-install \
    # create an alias for the just command and set cli completion
    && echo '#!/usr/bin/env bash' >> /bin/processDocx \
    && echo "cd /root/xmlworkflow/work" \
    && echo 'just "$@"' >> /bin/processDocx \
    && chmod u+x /bin/processDocx \
    && echo "complete -W '$(processDocx --summary)' processDocx" >> ~/.bashrc \
    && processDocx reset-jats-example

WORKDIR /root/xmlworkflow/work