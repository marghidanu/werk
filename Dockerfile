FROM alpine:3.15 AS build

# hadolint ignore=DL3018
RUN apk add --no-cache build-base crystal shards libressl-dev yaml-static zlib-static

WORKDIR /opt/app
COPY . .

RUN shards install --production --ignore-crystal-version \
    && shards build --release --no-debug --static

FROM alpine:3.15

COPY --from=build /opt/app/bin/werk /usr/local/bin/

ENTRYPOINT [ "werk" ]
