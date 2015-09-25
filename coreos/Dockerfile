FROM centos:latest

MAINTAINER Paul Greenberg @greenpau

RUN yum -y install vim epel-release

RUN yum -y update

RUN yum -y install zlib zlib-devel zlib-static bzip2 bzip2-libs bzip2-devel \
 ncurses ncurses-libs ncurses-devel ncurses-static openssl openssl-devel \
 openssl-static openssl-libs wget pcre pcre-devel pcre-static pcre-tools \
 libstdc++ libstdc++-devel libstdc++-static libstdc++-docs gcc g++ gcc-c++ \
 glibc* glibc-static glibc-utils kernel-headers unzip git binutils make vim \
 kmod pciutils bc rpm-build dkms

RUN mkdir -p /opt/sfc && cd /opt/sfc && \
    wget --quiet "https://support.solarflare.com/index.php?option=com_cognidox&file=SF-107601-LS-33_Solarflare_Linux_Utilities_RPM_64bit.zip&task=download&format=raw&id=1945&Itemid=11" -O sfutils.zip && \
    wget --quiet "https://support.solarflare.com/index.php?option=com_cognidox&file=SF-103848-LS-35_Solarflare_NET_driver_source_RPM.zip&task=download&format=raw&id=1945&Itemid=11" -O sfcdriver.zip && \
    wget --quiet "https://support.solarflare.com/index.php?option=com_cognidox&file=SF-108317-LS-4_Solarflare_Linux_diagnostics_sfreport.tgz&task=download&format=raw&id=1945" \
    -O SF-108317-LS-4_Solarflare_Linux_diagnostics_sfreport.tgz && \
    tar xvzf SF-108317-LS-4_Solarflare_Linux_diagnostics_sfreport.tgz && \
    cp sfreport.pl /bin/ && \
    unzip sfutils.zip && \
    unzip sfcdriver.zip && \
    rpm -ivh sfutils-4.6.6.1002-1.x86_64.rpm && \
    sfctool --version

RUN cd /usr/src/kernels && git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git

RUN cd /usr/src/kernels/linux-stable && git checkout v4.2-rc1 && \
 zcat /proc/config.gz > .config && \
 sed -i 's/^EXTRAVERSION.*/EXTRAVERSION = -coreos-r1/' Makefile && \
 sed -i 's/.*CONFIG_INITRAMFS_SOURCE.*/CONFIG_INITRAMFS_SOURCE=""/' .config && \
 make LOCALVERSION="" && make modules_install

RUN cd /opt/sfc && rpmbuild --rebuild sfc-4.5.1.1020-1.src.rpm && \
    rpm -Uvh /root/rpmbuild/RPMS/x86_64/kernel-module-sfc--$(uname -r)-4.5.1.1020-1.x86_64.rpm

#
# There are other tools. However, some of them exist with 1 when quering their version
#  * sfupdate -V
#  * sfboot -V
#  * fkey -V
#

#
# Next steps are:
#  1. sfupdate -y --write
#  2. rmmod sfc && insmod /lib/modules/$(uname -r)/extra/sfc.ko
#

#
# Additionally, a user may genereate a report using sfreport.pl and review it
#
