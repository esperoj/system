ARG REGISTRY_PROXY=""
ARG DEBIAN_VERSION=stable

FROM ${REGISTRY_PROXY}docker.io/library/debian:${DEBIAN_VERSION}

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C \
    LC_ALL=C

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        coreutils \
        curl \
        findutils \
        gawk \
        gnupg \
        git \
        make \
        moreutils \
        sed \
        sudo \
        time \
        wget \
        unzip \
        xz-utils \
        zstd \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -s /bin/bash -G sudo esperoj \
    && echo "esperoj ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/esperoj \
    && chmod 0440 /etc/sudoers.d/esperoj \
    && mkdir -p /home/esperoj/projects/system \
    && chown -R esperoj:esperoj /home/esperoj/projects

COPY --chown=esperoj:esperoj . /home/esperoj/projects/system/

USER esperoj
WORKDIR /home/esperoj/projects/system

RUN rm -rf ~/.bashrc ~/.profile \
    && ./configure docker-base \
    && make docker-base

WORKDIR /home/esperoj

CMD ["/bin/bash"]