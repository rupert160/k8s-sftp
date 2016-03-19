FROM alpine:latest

RUN apk add --update \
	bash \
    && rm -rf /var/cache/apk/*

# sshd needs this directory to run
RUN mkdir -p /var/run/sshd

COPY src/ .

VOLUME /etc/ssh

EXPOSE 22

ENTRYPOINT ["/entrypoint"]
