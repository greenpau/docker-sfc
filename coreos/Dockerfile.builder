#
# This is a development Dockerfile
#
# Please use the below command when building this container:
#  $ docker build --no-cache --rm=true --force-rm=true -t greenpau/sfc - < Dockerfile
#

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
    wget --quiet "https://support.solarflare.com/index.php?option=com_cognidox&file=SF-107601-LS-35_Solarflare_Linux_Utilities_RPM_64bit.zip&task=download&format=raw&id=1945&Itemid=11" -O sfc_utils.zip && \
    wget --quiet "https://support.solarflare.com/index.php?option=com_cognidox&file=SF-103848-LS-36_Solarflare_NET_driver_source_RPM.zip&task=download&format=raw&id=1945&Itemid=11" -O sfc_driver.zip && \
    wget --quiet "https://support.solarflare.com/index.php?option=com_cognidox&file=SF-108317-LS-4_Solarflare_Linux_diagnostics_sfreport.tgz&task=download&format=raw&id=1945&Itemid=11" -O sfc_report.tgz && \
    tar xvzf sfc_report.tgz && cp sfreport.pl /bin/ && \
    SFC_UTILS_RPM=$(unzip -l sfc_utils.zip | grep ".rpm" | tr -s " " | cut -d" " -f5) && \
    unzip sfc_utils.zip && \
    rpm -ivh ${SFC_UTILS_RPM} && \
    sfctool --version

RUN cd /usr/src/kernels && COREOS_BRANCH=$(uname -r | sed 's/-r[0-9]//') && git clone -b v${COREOS_BRANCH} https://github.com/coreos/linux.git

RUN cd /opt/sfc && \
    SFC_DRIVER_RPM=$(unzip -l sfc_driver.zip | grep ".rpm" | tr -s " " | cut -d" " -f5) && \
    unzip sfc_driver.zip && \
    rpm2cpio ${SFC_DRIVER_RPM} | cpio -idmv && \
    SFC_DRIVER_SRC=$(find . -name "sfc*.tar.gz") && \
    tar xvzf ${SFC_DRIVER_SRC} && \
    SFC_DRIVER_SRC_DIR=$(find . -name "Makefile" -type f | grep linux_net | sed 's/Makefile//') && \
    find /usr/src/kernels/linux/drivers/net/ethernet/sfc/ -type f | grep -v "Kconfig" | xargs rm && \
    cp -R ${SFC_DRIVER_SRC_DIR}/* /usr/src/kernels/linux/drivers/net/ethernet/sfc/ && \
    COREOS_VERSION=$(uname -r | sed 's/.*-core/-core/') && \
    cd /usr/src/kernels/linux && zcat /proc/config.gz > .config && \
    sed -i '/EXTRAVERSION =/d' Makefile && \
    sed -i "3 a EXTRAVERSION = ${COREOS_VERSION}" Makefile && \
    sed -i 's/.*CONFIG_INITRAMFS_SOURCE.*/CONFIG_INITRAMFS_SOURCE=""/' .config && \
    make oldconfig && make prepare &&  make LOCALVERSION="" modules_prepare && make LOCALVERSION="" M=drivers/net/ethernet/sfc && \
    strip --strip-debug drivers/net/ethernet/sfc/sfc.ko

#RUN rm -rf /usr/src/kernels/linux && yum -y clean packages

#
# There are other tools. However, some of them exist with 1 when quering their version
#  * sfupdate -V
#  * sfboot -V
#  * fkey -V
#

#
# Next steps are:
#  1. cp /usr/src/kernels/linux/drivers/net/ethernet/sfc/sfc.ko /tmp/sfc.ko
#  2. sfupdate -y --write
#  3. rmmod sfc && insmod /usr/src/kernels/linux/drivers/net/ethernet/sfc/sfc.ko
#

#
# Additionally, a user may genereate a report using sfreport.pl and review it
#  $ sfreport.pl sfreport.`hostname`.`date +"%Y%m%d.%H%M%S"`.txt
#
