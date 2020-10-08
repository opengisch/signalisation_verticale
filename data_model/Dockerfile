FROM alpine:3.12
RUN apk --update add postgresql-client gettext && rm -rf /var/cache/apk/*

ADD migrate.sh /migrate.sh
RUN chmod +x /migrate.sh

ADD ./infrastructure.sql /infrastructure.sql
ONBUILD ADD ./datamodel /datamodel

CMD /migrate.sh
