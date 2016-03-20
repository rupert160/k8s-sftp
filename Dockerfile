FROM alpine:latest

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

RUN mkdir /etc/dropbear
RUN touch /var/log/lastlog
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["dropbear", "-RFEmwg", "-p", "22"]
