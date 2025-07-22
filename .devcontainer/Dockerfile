ARG NODE_FOLDER=/nodejs

# Taken from official NodeJS Dockerfile
# But we extract the tarball to custom folder so it is easier to
# copy into /usr/local from this build image
FROM buildpack-deps:bookworm AS nodejs
ARG NODE_FOLDER
RUN mkdir -p "${NODE_FOLDER}"

ENV NODE_VERSION=22.17.1

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  # use pre-existing gpg directory, see https://github.com/nodejs/docker-node/pull/1895#issuecomment-1550389150
  && export GNUPGHOME="$(mktemp -d)" \
  # gpg keys listed at https://github.com/nodejs/node#release-keys
  && set -ex \
  && for key in \
    C0D6248439F1D5604AAFFB4021D900FFDB233756 \
    DD792F5973C6DE52C432CBDAC77ABFA00DDBF2B7 \
    CC68F5A3106FF448322E48ED27F5E38D5B0A215F \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    890C08DB8579162FEE0DF9DB8BEAB4DFCF555EF4 \
    C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
    108F52B48DB57BB0CC439B2997B01419BD92F80A \
    A363A499291CBBC940DD62E41F10027AF002F8B0 \
  ; do \
      { gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" && gpg --batch --fingerprint "$key"; } || \
      { gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" && gpg --batch --fingerprint "$key"; } ; \
  done \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && gpgconf --kill all \
  && rm -rf "$GNUPGHOME" \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C $NODE_FOLDER --strip-components=1 --no-same-owner 

# Base ubuntu image with a couple needed essentials
FROM ubuntu:noble AS basic
# hadolint ignore=DL3008
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get install -y --no-install-recommends \
    # So we can build things
    build-essential \ 
    # So we can communicate with websites using TLS at all
    ca-certificates \
    # It was this or wget :)
    curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*


FROM basic
# Consume global NODE_FOLDER build arg so we know where to
# copy the NodeJS files from in our NodeJS "build" image
ARG NODE_FOLDER
# Setup needed Rust/Cargo env variables
ENV PATH="/usr/local/cargo/bin:${PATH}"
ENV RUSTUP_HOME="/usr/local/rustup"
ENV CARGO_HOME="/usr/local/cargo"
ENV RUST_VERSION="1.88.0"
# Get Rust/Cargo
COPY --from=rust:1.88 /usr/local/cargo /usr/local/cargo
COPY --from=rust:1.88 /usr/local/rustup /usr/local/rustup
# Get NodeJS
COPY --from=nodejs "${NODE_FOLDER}" /usr/local
RUN corepack enable pnpm && corepack install -g pnpm
