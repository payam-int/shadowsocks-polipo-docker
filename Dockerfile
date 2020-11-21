FROM acrisliu/shadowsocks-libev

USER root

RUN set -xe \
    && apk add --no-cache build-base openssl \
    && wget https://github.com/jech/polipo/archive/master.zip -O polipo.zip \
    && unzip polipo.zip \
    && cd polipo-master \
    && make \
    && install polipo /usr/local/bin/ \
    && cd .. \
    && rm -rf polipo.zip polipo-master \
    && mkdir -p /usr/share/polipo/www /var/cache/polipo \
    && apk del build-base openssl


COPY entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

EXPOSE 7550
EXPOSE 7551

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
