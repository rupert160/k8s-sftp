FROM alpine:latest

MAINTAINER Open Source Services [opensourceservices.fr]

ENV REFRESHED_AT 2016-02-27
RUN apk add --update \
	openssh \
    && rm -rf /var/cache/apk/*

RUN apk update \
    && apk upgrade \
    && apk add \
    openssh-sftp-server \
    dropbear \
    && rm -rf /var/cache/apk/*

COPY docker-entrypoint.sh /

VOLUME ["/data"]

RUN mkdir /etc/dropbear \
    && touch /var/log/lastlog \
    && chmod +x /docker-entrypoint.sh

LABEL "original"="https://github.com/rlesouef/alpine-sftp"

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["dropbear", "-RFEwg", "-p", "22"]
