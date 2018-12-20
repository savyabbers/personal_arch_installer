#! /bin/bash


#check to see if we are in uefi mode
#for now we will asume this is supposed to be uefi install
if [ ! -e "/sys/firmware/efi/efivars" ] ; then
    echo "Not in UEFI"
    exit 1
fi

#implementation of to do uefi or bios installs
if [ ! -e "/sys/firmware/efi/efivars" ] ; then
    efi="0"
else
    efi="1"
fi

#want to check if we are connected to internet
#install needs to be connected to internet
wget -q --spider https://archlinux.org/
if [ $? -ne 0 ] ; then
    echo "Not connected to internet"
    exit 1
fi


while getopts "d:" opts ; do
    case ops in
        d)DISK="$OPTARG"    ;;
    esac
done

if [ $# -eq 0 ] ; then
    cat << EOI 
Usage: $(basename $0) [-d HardDrive]
    The harddrive that you input as an arg is used for the installation
    Later in the installation it will call up cfdisk to have the user
    input the partition. This script follows a Boot, Root, Swap partition.
EOI
    exit 0
fi

#partition the disk
cfdisk -z $DISK

# partition check
if [ ! -e "${DISK}1" ] ; then
    echo "No boot partition"
    exit 1
fi

if [ ! -e "${DISK}2" ] ; then
    echo "No root partition"
    exit 1
fi

if [ ! -e "${DISK}3" ] ; then
    echo "No swap Partition"
    exit 1
fi

#label root partition
e2label "${DISK}2" arch_os

#format the partition
mkfs.fat -F32 "${DISK}1" 
mkfs.ext4 "${DISK}2"
mkswap "${DISK}3"
swapon "${DISK}3"

mount "${DISK}2" /mnt
mkdir /mnt/boot
mount "${DISK}1" /mnt/boot

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

if [ $efi ] ; then  #if in efi
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
    
else    #if not in efi
    arch-chroot /mnt << EOF
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc
printf "en_US.UTF8 UTF8\n" >> /etc/locale.gen
local-gen
printf "LANG=en_US.UTF8\n" >> /etc/locale.conf
printf "hostname" > /etc/hostname
rustup toolchain install stable
rustup defult stable
pacman -S grub
grub-install -target=i368-pc $DISK
passwd
EOF

fi

echo "install Done!"
