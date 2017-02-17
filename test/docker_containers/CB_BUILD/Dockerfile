FROM m0elnx/ubuntu-32bit
MAINTAINER Dustin Fraze <df@cromulence.com>

RUN apt update
COPY debs/ /debs

COPY decree_version /etc/decree_version
RUN apt-get -y install build-essential \
                       python-support \
                       python-matplotlib \
                       make \
                       python-yaml \
                       python-lxml \
                       openssh-client \
                       tcpdump

RUN dpkg -i /debs/binutils-cgc-i386_2.24-9082-cfe-rc4_i386.deb \
            /debs/libcgc_9082-cfe-rc4_i386.deb \
            /debs/libcgcef0_9082-cfe-rc4_i386.deb \
            /debs/libcgcdwarf_9082-cfe-rc4_i386.deb \
            /debs/libpov_9082-cfe-rc4_i386.deb \
            /debs/cgcef-verify_9082-cfe-rc4_all.deb \
            /debs/clang-cgc_3.4-9085-cfe-rc4_i386.deb \
            /debs/cgc2elf_9082-cfe-rc4_i386.deb \
            /debs/poll-generator_9082-cfe-rc4_all.deb \
            /debs/cgc-service-launcher_9082-cfe-rc4_i386.deb \
            /debs/cb-testing_9082-cfe-rc4_all.deb \
            /debs/cgc-sample-challenges_9116-cfe-rc4_i386.deb

CMD ["/bin/bash"]
