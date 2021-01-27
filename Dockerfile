FROM crystallang/crystal:0.36.0-alpine AS build

WORKDIR /opt/app
COPY . .

# hadolint ignore=DL3018
RUN apk add --no-cache yaml-static \
    && shards build --release --no-debug --static

FROM alpine:3.12

COPY --from=build /opt/app/bin/werk /usr/local/bin/

CMD [ "werk" ]