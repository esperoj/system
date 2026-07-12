# How to setup

Make sure make, sh, and curl are available.

```sh
apt-get update -y && apt upgrade -y && apt-get install -y --no-install-recommends \
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
    termux-services
cd ~
mkdir -p ~/projects/system
cd ~/projects/system
git clone https://github.com/esperoj/system.git .
git remote set-url origin git@github.com:esperoj/system.git
./configure phone
make phone
```
# Things to do after setup

Put age keys. download vault. and
```
make -f ~/recipes/backup.mk resync
```
