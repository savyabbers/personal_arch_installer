#! /bin/bash


#check to see if we are in uefi mode
#for now we will asume this is supposed to be uefi install
if [ ! -e "/sys/firmware/efi/efivars" ] ; then
    echo "Not in UEFI"
    exit 1
fi

#want to check if we are connected to internet
#install needs to be connected to internet
wget -q --spider https://archlinux.org/
if [ $? -ne 0 ] ; then
    echo "Not connected to internet"
    exit 1
fi

#maybe want to make use select a harddisk to install on
if [  ] ; then
    echo "No HardDrive selected"
    echo "Please use 'install /dev/xvy'"
    exit 1
fi

while getopts "d:" opts ; do
    case ops in
        d)Disk="$OPTARG"    ;;
    esac
done

if [ $# -eq 0 ] ; then
    echo "Usage: $(basename $0) [-d HardDrive]"
    echo "  This script ecpects to have a harddisk with 3 partions on it."
    echo "      dev/xxx1 - being the boot"
    echo "      dev/xxx2 - being the root"
    echo "      dev/xxx3 - being the swap"
    echo "  \nYou do not need to format. just make the disk sectors for now"
    exit 0
fi

#partition the disk
#partition will follow as
# Boot sector 514M
# Root / Max - Ram
# Swap for Ram
# we will also want to name the root os as arch_os
#
#fdisk $1 << EOF
#n
#p
#1
#
#w
#EOF

# partition check
if [ ! -e "${Disk}1" ] ; then
    echo "No boot partition"
    exit 1
fi

if [ ! -e "${Disk}2" ] ; then
    echo "No root partition"
    exit 1
fi

if [ ! -e "${Disk}3" ] ; then
    echo "No swap Partition"
    exit 1
fi

#label root partition
e2label "${Disk}2" arch_os

#format the partition
mkfs.fat -F32 "${Disk}1" 
mkfs.ext4 "${Disk}2"
mkswap "${Disk}3"
swapon "${Disk}3"

mount "${Disk}2" /mnt
mkdir /mnt/boot
mount "${Disk}1" /mnt/boot

# get pacman-contrib to rank list
wget -O mirrorlist "https://www.archlinux.org/mirrorlist/?country=US&protocol=https"
sed -i 's/^#Server/Server/' mirrorlist
rm /etc/pacman.d/mirrorlist
mv mirrorlist /etc/pacman.d/mirrorlist

# packages to be installed
base="base base-devel xorg-server ufw"
kde="plasma kdebase yakuake spectacle kdeconnect okular kate sddm"
extras="firefox ark libreoffice-fresh sshfs deluge filezilla vlc"
moredev="ghc rustup lua erlang clisp nasm git"

pacstrap /mnt $base $kde $extras $moredev

#generate a fstap
genfstab -U /mnt >> /mnt/etc/fstab

# arch-chroot
arch-chroot /mnt << EOF
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc
printf "en_US.UTF8 UTF8\n" >> /etc/locale.gen
local-gen
printf "LANG=en_US.UTF8\n" >> /etc/locale.conf
printf "hostname" > /etc/hostname
rustup toolchain install stable
rustup defult stable
passwd
bootctl --path=/boot/ install
exit
EOF


#fixing files in new comuter for proper boot
printf "default\tarch\ntimeout\t5\neditor\tno\n" > /mnt/boot/loader/loader.conf
#entry
printf "title\tArch Linux\nlinux \tvmlinuz-linux\n" >> /mnt/boot/loader/entries/arch.conf
printf "initrd\t/initramfs-linux.img\n" >> /mnt/boot/loader/entries/arch.conf
printf "options\troot=LABEL=arch_os rw\n" >> /mnt/boot/loader/entries/arch.conf


