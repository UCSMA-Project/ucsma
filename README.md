# UCSMA Project - Main Repo
This repository contains the necessary submodules and scripts to build the firmware, kernel modules,
 and utilities to perform experiments with U-CSMA on the JS9331 development board.

## Dependencies:
1) A GNU/Linux system
2) All [prerequisite packages](https://wiki.openwrt.org/doc/howto/buildroot.exigence#table_of_known_prerequisites_and_their_corresponding_packages) for the OpenWRT build system must be installed.

## Building Everything
Simply running build.sh will proceed with building all of the components necessary for the experiment.
Build products will be located in the result folder after the build process completes.

## AR9331 SoC Login/Setup
- If you have flashed the chip, make sure to first disable the firewall (otherwise `ssh` will not work): `/etc/init.d/firewall disable`
- To `ssh` into the chip, run `ssh root@<ip_addr>` with password `root` (scp works the same way)
- Connecting via serial port is also possible with serial speed `115200`

## How to compile and use built modules
As mentioned above, running `build.sh` will build all of the components necessary for the experiment. Once built, these components can be found in the `/result` directory

#### Flashing the OS
The `result` directory contains two `OpenWRT` (OS) binary files, where one of which is a `sysupgrade`. To flash the system, use the non-`sysupgrade` (`factory`) version, otherwise files will not be overwritten. On the chip, run `sysupgrade <bin name>`.

#### Copying modules
Use `scp` to copy `packetspammer` and `unlock.ko` to each of the AR9331 boards. It may be helpful to use a script together with `ssh-pass` to pass in the password directly through the script

## Setting up the experiment with three node topology
### On the AR9331 Boards
#### Install ath9k module
1. Copy the relevant files to the AR9331 boards.
2. Install ath9k module with command `insmod ath9k`. (default model) Uninstall ath9k module with command `rmmod ath9k`.
3. Set noise floor and txpower by running `init.sh` script sometimes the noise floor need to be set angin manully after running `init.sh` script.
| parameters | noise floor | txpower |
|-|-------------|---------|
|left and/or right | -56 | 100 |
| mid | -95 | 2000 |
3. Run packetspammer on three boards with command `./packetspammer -d0 mon0`. 
4. Run horst on three boards with command `horst -i mon0` (horst can be helpful when adjusting the topology.)
5. Observe the throughput of each device to make sure the topology holds.

#### Install unlock module and rate control module
1. Copy the relevant files to the AR9331 boards.
2. Run packetspammer before install unlock module by command `./packetspammer -d0 mon0` to send a packet first.
3. Install unlock module with command `insmod unlock.ko`.
4. Install buffer_number module with command `insmod buffer_number.ko`.
5. Set parameters for unlock module. (T and Delta) The default values of these two parameters are (T = 20000 microsecond, Delta = 100 microsecond) with command `echo $1 > /sys/module/unlock/parameters/T` and `echo $1 > /sys/module/unlock/parameters/Delta`.
6. Run packetspammer with command `./packetspammer -d0 mon0` and observe the result with Raspberry Pi or by the printed throughput by packetspammer.

### On the Raspberry Pi
1. Copy the `gpio_timeline` repository into the Raspberry Pi
2. Run `rpi-update` and update the entire operating system to the newest version (make sure this is done properly as it ensures the kernel headers match.
3. Run `sudo apt-get install raspberrypi-kernel-headers`.
4. `cd` into the repository and run make.
5. To install the `gpio_timeline` kernel module, run `sudo insmod gpio_timeline.ko human_readable_output=<1 or 0> max_log_count=<# logs>`.
    The Raspberry Pi will then log for the `max_log_count` number of events and flush logs into the kernel ring buffer. It will no longer log after that so a `rmmod` and a subsequent `insmod` is required
6. To view logs, run `sudo dmesg`.
7. To remove the kernel module, run `sudo rmmod gpio_timeline`

### Physically
1. Place three nodes 2.5 meters apart each, in the same orientation, and then connect them to power.
2. Make sure antennas are firmly attached to each of the three boards.
3. Connect the three nodes to a router using the WAN ethernet port. (This is to allow us to `ssh` into the boards)
4. (TODO: Add pin assignment instructions)

## How to use packetspammer and horst on the AR9331
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

#### All nodes are able to see each other despite being a sufficient physical distance apart
Check the `TX_Power` and `noise_floor` settings in the monitor.

#### Can't find the `ath9k` directory used for building the network driver
It's `OpenWRT-14.07-JS9331/build_dir/target-mips_34kc_uClibc-0.9.33.2/linux-ar71xx_generic/compat-wireless-2014-05-22/drivers/net/wireless/ath/ath9k/`

#### Can't find the compiled kernel modules
It's `OpenWRT-14.07-JS9331/staging_dir/target-mips_34kc_uClibc-0.9.33.2/root-ar71xx/lib/modules/3.10.49`

#### I wan't to just compile the network driver
Within the `OpenWRT` directory, run `make package/compile`
