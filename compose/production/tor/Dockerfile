FROM alpine:3.14.0

RUN apk update \
 && apk upgrade \
 && apk add tor \
 && rm /var/cache/apk/*

EXPOSE 9150

ADD ./torrc /etc/tor/torrc

USER tor
CMD /usr/bin/tor -f /etc/tor/torrc
