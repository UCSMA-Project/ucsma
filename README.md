# UCSMA Project - Main Repo

This repository contains the necessary submodules and scripts to build the firmware, kernel modules,
 and utilities to perform experiments with U-CSMA on the JS9331 development board.


## Dependencies:

1) A GNU/Linux system
2) All [prerequisite packages](https://wiki.openwrt.org/doc/howto/buildroot.exigence#table_of_known_prerequisites_and_their_corresponding_packages) for the OpenWRT build system must be installed.

## Building Everything

Simply running build.sh will proceed with building all of the components necessary for the experiment.
Build products will be located in the result folder after the build process completes.

## Notes

- The monitoring code for the Raspberry Pi used in the experiment is not built or included in this repo.
  It is recommended that the monitoring code be built on the Raspberry Pi. This can be done by cloning the
  [relevant Git repo](https://github.com/UCSMA-Project/ucsma-raspi-gpio.git) onto the Raspberry Pi, then running make.

# Development
## AR9331 SoC Login/Setup
- If you have flashed the chip, make sure to first disable the firewall (otherwise `ssh` will not work): `/etc/init.d/firewall disable`
- To `ssh` into the chip, run `ssh root@<ip_addr>` with password `root` (scp works the same way)
- Connecting via serial port is also possible with serial speed `115200`

## How to compile and use built modules
As mentioned above, running `build.sh` will build all of the components necessary for the experiment. Once built, these components can be found in the `/result` directory

#### Flashing the OS
The `result` directory contains two `OpenWrt` (OS) binary files, where one of which is a `sysupgrade`. To flash the system, use the non-`sysupgrade` (`factory`) version, otherwise files will not be overwritten. On the chip, run `sysupgrade <bin name>`.

#### Copying modules
Use `scp` to copy `packetspammer` and `unlock.ko` to each of the AR9331 boards. It may be helpful to use a script together with `ssh-pass` to pass in the password directly through the script

## How to use packetspammer and horst
#### Packetspammer
Packetspammer is a command line executable (for the AR9331 chip) that broadcasts packets as fast as it can on the specified monitor. On the AR9331 SoC, run command `./packetspammer -d <delay> <monitor id>` to begin sending packets

#### Horst
Horst is a network monitoring tool/sniffer that allows you to see the channel usage and received packets. On the AR9331 SoC, run command `horst -i <monitor id>` to open the sniffer - we recommend using a separate terminal to do this and to avoid doing it via a serial connection

## Frequently Encountered Issues
#### build.sh make/world error
If you see an error similar to this (when building in verbose mode):
```
Unescaped left brace in regex is illegal here in regex; marked by <-- HERE in m/\${ <-- HERE ([^ \t=:+{}]+)}/ at ./bin/automake.tmp line 3938.
Makefile:50: recipe for target '/openwrt-master/build_dir/host/automake-1.15/.configured' failed
make[3]: *** [openwrt-master/build_dir/host/automake-1.15/.configured] Error 255
make[3]: Leaving directory '/openwrt-master/tools/automake'
tools/Makefile:134: recipe for target 'tools/automake/compile' failed
make[2]: *** [tools/automake/compile] Error 2
make[2]: Leaving directory '/openwrt-master'tools/Makefile:133: recipe for target '/openwrt-master/staging_dir/target-x86_64_musl1.1.14/stamp/.tools_install_yynyynynynyyyyyyynyyynyyyyyyyyynyyyyynyyynynnyyynnnyy' failed
make[1]: *** [/openwrt-master/staging_dir/target-x86_64_musl1.1.14/stamp/.tools_install_yynyynynynyyyyyyynyyynyyyyyyyyynyyyyynyyynynnyyynnnyy] Error 2
make[1]: Leaving directory '/openwrt-master'/openwrt-master/include/toplevel.mk:192: recipe for target 'world' failed
make: *** [world] Error 2
```
Simply go into the `./bin/automake*` files and edit the unescaped curly braces on the lines specified. This is an error caused by a deprecated perl version on Ubuntu 18.04.

#### Packetspammer recorded throughput extremely high
This is an issue with packetspammer incrementing the throughput whenever the `ath9k`'s driver entry point is called, regardless of the buffer being actually sent. For example, if the software buffer is full, the function would immediately return with an error, but packetspammer would not detect this. For precise throughput, use the Raspberry Pi along with the `gpio_timeline.ko` and `unlock.ko` kernel modules in order to monitor throughput.
