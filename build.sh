#!/bin/sh

mkdir iso initrd
echo Downloading iso
wget -q https://ftp.debian.org/debian/dists/stable/main/installer-amd64/current/images/netboot/mini.iso
echo Unpacking iso
xorriso -osirrox on -indev mini.iso -extract / iso
echo Unpacking initrd
cd initrd && gzip -dc ../iso/initrd.gz | cpio -idm
rm -rf ../iso/initrd.gz
rm ../mini.iso

echo Configuring
sudo tee ../iso/boot/grub/grub.cfg > /dev/null <<'EOF'
set timeout=0
set default=0

if [ x$feature_default_font_path = xy ] ; then
   font=unicode
else
   font=$prefix/font.pf2
fi

if loadfont $font ; then
  set gfxmode=800x600
  set gfxpayload=keep
  insmod efi_gop
  insmod efi_uga
  insmod video_bochs
  insmod video_cirrus
  insmod gfxterm
  insmod png
  echo "Loading bootloader..."
  terminal_output gfxterm
fi

set menu_color_normal=cyan/blue
set menu_color_highlight=white/blue

insmod play
play 960 440 1 0 4 440 1

menuentry 'Install' {
    set background_color=black
    linux    /linux vga=788 --- auto=true priority=high preseed/file=/etc/preseed.cfg
    initrd   /initrd.gz
}
EOF

tee ./etc/preseed.cfg > /dev/null <<'EOF'
### Locale / keyboard

d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us

### Network

d-i netcfg/get_hostname string dodeb
d-i netcfg/get_domain string local

### Mirrors

d-i apt-setup/use_mirror boolean true

d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
d-i mirror/http/directory string /debian

d-i mirror/http/proxy seen false

### APT / packages

d-i apt-setup/contrib boolean false
d-i apt-setup/non-free boolean false
d-i apt-setup/non-free-firmware boolean false
d-i apt-setup/cdrom/set-first boolean false

d-i base-installer/install-recommends boolean false
d-i pkgsel/install-language-support boolean false

popularity-contest popularity-contest/participate boolean false

### NO TASKSEL

tasksel tasksel/first multiselect

### Minimal packages only

d-i pkgsel/include string \
openssh-server nano mc curl wget busybox-static zstd ca-certificates

### Bootloader

d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean false

### Time

d-i clock-setup/utc boolean true
d-i time/zone string UTC

### Late command

d-i preseed/late_command string \
in-target apt-get update; \
in-target apt-get install -y --no-install-recommends docker.io docker-cli docker-compose; \
in-target systemctl enable docker || true; \
in-target systemctl enable ssh || true; \
in-target mkdir -p /etc/initramfs-tools/conf.d; \
in-target sh -c 'echo MODULES=dep > /etc/initramfs-tools/conf.d/minimal'; \
in-target sh -c 'echo COMPRESS=zstd >> /etc/initramfs-tools/conf.d/minimal'; \
in-target update-initramfs -u || true; \
in-target sed -i 's/errors=remount-ro/errors=remount-ro,noatime,discard/' /etc/fstab || true; \
in-target sed -i 's/^GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/' /etc/default/grub || true; \
in-target sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=true/' /etc/default/grub || true; \
in-target sh -c 'grep -q "^GRUB_DISABLE_RECOVERY=" /etc/default/grub || echo GRUB_DISABLE_RECOVERY=true >> /etc/default/grub'; \
in-target update-grub || true; \
in-target mkdir -p /etc/systemd/journald.conf.d; \
in-target sh -c 'printf "[Journal]\nStorage=volatile\nRuntimeMaxUse=64M\n" > /etc/systemd/journald.conf.d/volatile.conf'; \
in-target mkdir -p /etc/dpkg/dpkg.cfg.d; \
in-target sh -c 'printf "path-exclude=/usr/share/doc/*\npath-include=/usr/share/doc/*/copyright\npath-exclude=/usr/share/man/*\npath-exclude=/usr/share/info/*\npath-exclude=/usr/share/locale/*\npath-include=/usr/share/locale/en*\n" > /etc/dpkg/dpkg.cfg.d/01_nodoc'; \
in-target apt-get -y purge tasksel tasksel-data installation-report os-prober man-db info apt-listchanges eject || true; \
in-target apt-get autoremove -y || true; \
in-target apt-get clean; \
in-target find /usr/share/doc -mindepth 1 ! -name copyright -delete || true; \
in-target rm -rf /usr/share/man/*; \
in-target rm -rf /usr/share/info/*; \
in-target passwd -l root
EOF

echo Packing initrd
find . | cpio -H newc -o | gzip -9 > ../iso/initrd.gz

echo Packing iso
cd .. && xorriso -as mkisofs \
  -r -V "dodeb" \
  -o dodeb.iso \
  -J -joliet-long \
  -cache-inodes \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -partition_offset 16 \
  -A "dodeb" \
  -b /isolinux.bin \
  -c /boot.cat \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e boot/grub/efi.img \
  -no-emul-boot \
  iso

echo Done