FROM 84codes/crystal:1.19.1-alpine AS build

# hadolint ignore=DL3018
RUN apk add --no-cache yaml-static zlib-static

ARG APP_VERSION=0.0.0
ARG RELEASE=true

WORKDIR /opt/app
COPY shard.yml shard.lock ./
COPY src/ src/

RUN shards install --production --ignore-crystal-version \
    && shards build --no-debug --static ${RELEASE:+--release}

FROM alpine:3.21

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# hadolint ignore=DL3018
RUN apk add --no-cache curl \
    && GITLEAKS_VERSION=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | grep -o '"tag_name": "v[^"]*"' | cut -d'"' -f4 | sed 's/v//') \
    && curl -sSL "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" | tar xz -C /usr/local/bin gitleaks

COPY --from=build /opt/app/bin/werk /usr/local/bin/

ENTRYPOINT [ "werk" ]
