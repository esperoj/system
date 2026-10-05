ARG REGISTRY_PROXY=""
ARG DEBIAN_VERSION=13-slim

FROM ${REGISTRY_PROXY}docker.io/library/debian:${DEBIAN_VERSION}

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C \
    LC_ALL=C

# 1. Configure APT: globally disable recommends, suggests, and cache retention
RUN echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/99no-recommends \
    && echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/99no-recommends \

# 2. Bare minimum host prep: install sudo for delegation and create user
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

# 3. Bootstrap target profile and purge all apt cache in the same layer
RUN rm -rf ~/.bashrc ~/.profile \
    && ./bootstrap docker-base \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /home/esperoj

CMD ["/bin/bash"]
