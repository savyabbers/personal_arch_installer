# Personal Install script.

-------------------------------------------------
## Untested Script
    Use at your own risk.
-------------------------------------------------
## Usage of script
    ./install -d /dev/xxx
-------------------------------------------------
Personal install script to make arch a little easier to install.

For now this script will assume that you have 3 partitions on a disk that you are installing arch on.
1st partition is the 550M fat32 bootloader for systemd
2nd partition is your root drive.
3rd is the swap.

You'll have to make the partitions on a GPT table drive

The script will install some of the common tools used for developers and install the KDE desktop with the base applications.

-------------------------------------------------

## Things todo...
* Add automatic disk partitioning
* extra command flag to install listed packages
* be able to install BIOS and EFI boot modes.
