#!/usr/bin/env bash
set -euo pipefail

# 1. Install host-side C compilation and documentation tools required by GMP
sudo apt update
sudo apt install -y m4 texinfo build-essential git curl unzip libcurl4-gnutls-dev

# 2. Configure Android NDK Root environment variable 
# (Update this path if your NDK location differs)
export ANDROID_NDK_ROOT="/usr/lib/android-ndk/android-ndk-r30"

# Add it permanently to your shell profile if desired:
if ! grep -q "ANDROID_NDK_ROOT" ~/.bashrc; then
    echo 'export ANDROID_NDK_ROOT="/usr/lib/android-ndk/android-ndk-r30"' >> ~/.bashrc
fi

# 3. Create or switch to your OCaml cross-compilation switch
# (Assuming OCaml 5.4.1 matches your target switch)
opam repo add android https://github.com/ocaml-cross/opam-cross-android.git || true
opam switch create android-switch ocaml-base-compiler.5.4.1 --repositories=default,android=git+https://github.com/ocaml-cross/opam-cross-android.git || opam switch set android-switch

eval $(opam env)

# 4. Install the core Android compiler toolchain and sysroot setup
opam install ocaml-android build-android-sysroot --yes

# 5. Build and install GMP for Android (requires m4 and texinfo)
opam install build-gmp-android --yes

# 6. Refresh sysroot registration so it detects the compiled GMP headers/libs
opam reinstall build-android-sysroot --yes

# 7. Install your project's target dependencies
if [ -f "./my_app-android.opam" ]; then
    opam install ./my_app-android.opam --deps-only --yes
else
    echo "Warning: ./my_app-android.opam not found in current directory."
fi

echo "Environment successfully set up and cached!"
