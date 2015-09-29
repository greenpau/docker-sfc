# docker-sfc

Solarflare Firmware and Driver in a container

## Imaging Basics

Remove existing images:

```
docker images -q --filter "dangling=true" | xargs docker rmi
docker rmi greenpau/sfc
```

Create an image:

```
docker build --no-cache --rm=true --force-rm=true -t greenpau/sfc - < Dockerfile
```

Start a container with the image:

```
docker run --rm -i -t --name=sfc --privileged --cap-add all --net=host -v /tmp:/tmp  greenpau/sfc /bin/bash
```

## Firmware Update

First, identify Solarflare cards:

```
# lspci | grep Solar
04:00.0 Ethernet controller: Solarflare Communications SFC9020 [Solarstorm]
04:00.1 Ethernet controller: Solarflare Communications SFC9020 [Solarstorm]
# 
```

Then, update the firmware on the card:

```
# sfupdate -y --write
Solarstorm firmware update utility [v4.6.6]
Copyright Solarflare Communications 2006-2014, Level 5 Networks 2002-2005 
eno49: updating controller firmware from 3.3.0.6275 to 3.3.1.1003
eno49: will be disabled during controller firmware update
eno49: writing controller firmware
[100%] Complete                                                              
[100%] Complete                                                              
eno49: updating Boot ROM from 3.3.1.6312 to 4.4.0.1002
eno49: writing Boot ROM
[100%] Complete                                                              
eno49: writing version information
eno50: writing version information                                           
[100%] Complete                                                              
[100%] Complete                                                              
# 
```

Lastly, verify the update by running `sfupdate -V`. 
Please note that the `Boot ROM version` of the network card changed:

```
    Boot ROM version:   v3.3.1.6312
    Boot ROM version:   v4.4.0.1002
```


## Driver Update

First, unload existing `sfc` module from kernel:

```
rmmod sfc
```

Then, load updated `sfc` driver:

```
insmod /lib/modules/$(uname -r)/updates/sfc.ko
```

## Driver Reports

A user may generate a network card report. The report is necessary to troubleshoot issues with SolarFlare support. 

```
docker run --rm -i -t --name=sfc --privileged --cap-add all --net=host -v /tmp:/tmp greenpau/sfc sfupdate -V
docker run --rm -i -t --name=sfc --privileged --cap-add all --net=host -v /tmp:/tmp greenpau/sfc sfreport.pl /tmp/sfreport.pl.`hostname`.`date +"%Y%m%d.%H%M%S"`.html
```
