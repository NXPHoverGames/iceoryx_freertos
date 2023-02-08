# Copyright 2023 NXP

FROM ubuntu:22.04

RUN apt update

RUN apt-get install -y wget bzip2 qemu-system-arm cmake
WORKDIR /compiler
RUN wget -q https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2
RUN tar -xf gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2 && rm gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2

RUN echo 'export PATH=/compiler/gcc-arm-none-eabi-10.3-2021.10/bin:${PATH}' >> /etc/profile
RUN echo 'export PATH=/compiler/gcc-arm-none-eabi-10.3-2021.10/bin:${PATH}' >> /etc/bash.bashrc
ENV PATH="/compiler/gcc-arm-none-eabi-10.3-2021.10/bin:${PATH}"

COPY . /iceoryx_freertos
WORKDIR /iceoryx_freertos

RUN bash /iceoryx_freertos/build.sh

CMD ["qemu-system-arm", "-M", "vexpress-a9", "-m", "500M", "-nographic", "-semihosting", "-kernel", "build-example/iox_freertos_example"]
