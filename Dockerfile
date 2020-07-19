FROM ubuntu:18.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends shadowsocks-libev parallel polipo \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

EXPOSE 7550
EXPOSE 7551

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]