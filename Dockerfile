FROM crystallang/crystal:0.36.1-alpine AS build

# hadolint ignore=DL3018
RUN apk add --no-cache yaml-static

WORKDIR /opt/app
COPY . .

RUN shards build --release --no-debug --static

FROM alpine:3.12

COPY --from=build /opt/app/bin/werk /usr/local/bin/

CMD [ "werk" ]