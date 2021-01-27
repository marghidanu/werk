FROM crystallang/crystal:0.36.0-alpine AS build

WORKDIR /opt/app
COPY . .

RUN apk add --no-cache yaml-dev \
    && shards build --release --no-debug --static

FROM alpine:3.12

COPY --from=build /opt/app/bin/werk /usr/local/bin/

CMD [ "werk" ]