# Ersoy Kardesler Linux-libre Build Script

A Linux ISO image build script based on [Minimal Linux Script](https://github.com/ivandavidov/minimal-linux-script)

Copyright (C) 2016-2021 John Davidson, 2021 Ercan Ersoy and Erdem Ersoy

The source bundles are downloaded and compiled automatically. The script requires cross musl-based toolchain. [Our toolchain build configuration](https://kod.pardus.org.tr/ersoy-kardesler/ersoy-kardesler-linux-libre/ersoy-kardesler-linux-libre-toolchain-build-configuration) is recommended.

If you are using [Pardus](https://www.pardus.org.tr), you should be able to resolve all build dependencies by executing the following command:

    sudo apt install wget make gawk gcc bc bison flex xorriso libelf-dev libssl-dev qemu-system-x86

The script doesn't require root privileges. In the end you should have a bootable ISO image named `ersoy_kardesler_linux.iso` in the same directory where you executed the script.
