FROM alpine

RUN apk add --no-cache bash curl git

ARG TFENV_VERSION=v2.2.1
RUN git clone --branch ${TFENV_VERSION} --depth 1 https://github.com/tfutils/tfenv.git ~/.tfenv \
 && ln -s ~/.tfenv/bin/* /usr/local/bin

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
