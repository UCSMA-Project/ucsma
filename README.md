# UCSMA Project - Main Repo

This repository contains the necessary submodules and scripts to build the firmware, kernel modules,
 and utilities to perform experiments with U-CSMA on the JS9331 development board.


## Dependencies:

1) A GNU/Linux system
2) All [prerequisite packages](https://wiki.openwrt.org/doc/howto/buildroot.exigence#table_of_known_prerequisites_and_their_corresponding_packages) for the OpenWRT build system must be installed.

## Building Everything

Simply running build.sh will proceed with building all of the components necessary for the experiment.
Build products will be located in the result folder after the build process completes.

# Notes

- The monitoring code for the Raspberry Pi used in the experiment is not built or included in this repo.
  It is recommended that the monitoring code be built on the Raspberry Pi. This can be done by cloning the
  [relevant Git repo](https://github.com/UCSMA-Project/ucsma-raspi-gpio.git) onto the Raspberry Pi, then running make.
