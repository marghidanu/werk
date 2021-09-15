FROM crystallang/crystal:1.1.1-alpine AS build

# hadolint ignore=DL3018
# RUN sed -i -e 's/v[[:digit:]]\..*\//edge\//g' /etc/apk/repositories \
#     && apk add --no-cache build-base crystal shards libressl-dev yaml-static zlib-static

WORKDIR /opt/app
COPY . .

RUN shards install --production --ignore-crystal-version \
    && shards build --release --no-debug --static

FROM alpine:3.13

COPY --from=build /opt/app/bin/werk /usr/local/bin/

CMD [ "werk" ]
