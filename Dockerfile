FROM crystallang/crystal:0.35.1-alpine
WORKDIR /opt/app
COPY . .
RUN shards build --release --static

FROM alpine:3.12
COPY --from=0 /opt/app/bin/werk /usr/local/bin/
CMD [ "werk" ]