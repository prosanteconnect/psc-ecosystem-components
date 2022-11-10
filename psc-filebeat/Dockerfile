FROM frolvlad/alpine-glibc:alpine-3.11

WORKDIR /app

# install dumb-init, a simple process supervisor and init system
ENV DUMB_INIT_VERSION 1.2.2
RUN set -ex \
   && apk add --virtual build-tools --no-cache curl build-base bash \
  && curl -Lo dumb-init.tgz "https://github.com/Yelp/dumb-init/archive/v${DUMB_INIT_VERSION}.tar.gz" \
  && tar xzf dumb-init.tgz \
  && cd dumb-init-${DUMB_INIT_VERSION} \
  && make \
  && cp dumb-init /usr/bin \
  && cd .. \
  && rm -rf dumb-init*

ENV SIGIL_VERSION 0.5.0
RUN set -ex \
  && curl -Lo sigil.tgz "https://github.com/gliderlabs/sigil/releases/download/v${SIGIL_VERSION}/sigil_${SIGIL_VERSION}_Linux_x86_64.tgz" \
  && tar xzf sigil.tgz -C /usr/local/bin \
  && rm sigil.tgz

ENV FILEBEAT_VERSION=7.17.0
ENV FILEBEAT_SHA512=b89143d745c024f9f764933de77c2d3e88c4f52c9962f9dcdbbf45c656ad901e70935d8373166c90226c74c998db673aabdb8fcdb73a344aca2981672e072af3
RUN set -ex \
  && curl -Lo filebeat.tgz "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-linux-x86_64.tar.gz" \
  && echo "${FILEBEAT_SHA512}  filebeat.tgz" | sha512sum -c - \
  && tar xzf filebeat.tgz \
  && cp filebeat-*/filebeat /usr/local/bin \
  && cp filebeat-*/fields.yml ./ \
  && rm -rf filebeat* \
  && apk del --purge build-tools

COPY run.sh filebeat.yml.tmpl ./
RUN chmod 755 ./run.sh

ENTRYPOINT ["./run.sh"]
CMD ["filebeat", "-e"]
