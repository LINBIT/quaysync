FROM alpine:latest
MAINTAINER Roland Kammerer <roland.kammerer@linbit.com>

RUN apk update \
	&& apk add ca-certificates docker jq bash \
	&& rm -rf /var/cache/apk/*

ADD ./entry.sh /

CMD ["-h"]
ENTRYPOINT ["/entry.sh"]
