ARG REGISTRY_PROXY=""
ARG DEBIAN_VERSION=13-slim

FROM ${REGISTRY_PROXY}docker.io/library/debian:${DEBIAN_VERSION}

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C \
    LC_ALL=C

RUN echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/99no-recommends && \
    echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/99no-recommends && \
    echo "path-exclude=/usr/share/man/*" > /etc/dpkg/dpkg.cfg.d/excludes && \
    echo "path-exclude=/usr/share/doc/*" >> /etc/dpkg/dpkg.cfg.d/excludes && \
    echo "path-include=/usr/share/doc/*/copyright" >> /etc/dpkg/dpkg.cfg.d/excludes
RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && useradd -m -s /bin/bash -G sudo esperoj \
    && echo "esperoj ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/esperoj \
    && chmod 0440 /etc/sudoers.d/esperoj \
    && mkdir -p /home/esperoj/projects/system \
    && chown -R esperoj:esperoj /home/esperoj/projects

COPY --chown=esperoj:esperoj . /home/esperoj/projects/system/

USER esperoj
WORKDIR /home/esperoj/projects/system

RUN rm -rf ~/.bashrc ~/.profile \
    && ./bootstrap docker-base \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /home/esperoj

CMD ["/bin/bash"]
