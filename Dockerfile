FROM alpine

RUN apk add --no-cache bash curl git

RUN git clone https://github.com/tfutils/tfenv.git ~/.tfenv \
 && ln -s ~/.tfenv/bin/* /usr/local/bin

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
