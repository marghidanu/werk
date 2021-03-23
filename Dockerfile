FROM crystallang/crystal:1.0.0-alpine AS build

# hadolint ignore=DL3018
RUN apk add --no-cache yaml-static

WORKDIR /opt/app
COPY . .

RUN shards install --production --ignore-crystal-version \
    && shards build --release --no-debug --static

FROM alpine:3.12

COPY --from=build /opt/app/bin/werk /usr/local/bin/

CMD [ "werk" ]