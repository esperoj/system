# How to setup

Make sure make, sh, and curl are available.

```sh
apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    coreutils \
    curl \
    findutils \
    gawk \
    gnupg \
    iputils-ping \
    make \
    moreutils \
    rename \
    sed \
    sudo \
    time \
    wget \
    unzip \
    xz-utils
cd ~
mkdir -p ~/projects/system
cd ~/projects/system
git clone https://github.com/esperoj/system.git .
git remote set-url origin git@github.com:esperoj/system.git
./configure phone
make phone
```

# issues

vault open ssh and dont remember permission
