ARG REGISTRY_PROXY=""
FROM ${REGISTRY_PROXY}docker.io/library/debian:stable
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
