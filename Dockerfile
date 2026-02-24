FROM 84codes/crystal:1.19.1-alpine AS build

# hadolint ignore=DL3018
RUN apk add --no-cache yaml-static zlib-static

ARG APP_VERSION=0.0.0

WORKDIR /opt/app
COPY . .

RUN shards install --production --ignore-crystal-version \
    && APP_VERSION=${APP_VERSION} shards build --release --no-debug --static

FROM alpine:3.21

COPY --from=build /opt/app/bin/werk /usr/local/bin/

ENTRYPOINT [ "werk" ]
