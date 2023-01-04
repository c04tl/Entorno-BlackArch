#!/bin/bash
# Disco de 20 GB
# sda1 300M
# sda2 18.5G
# sda3 1.2G

echo -e "$(tput setaf 1)\n##########		FORMATO DE PARTICIONES		##########$(tput setaf 7)"
mkfs.fat -F 32 /dev/sda1
mkfs.ext4 /dev/sda2
mkswap /dev/sda3
swapon /dev/sda3


echo -e "$(tput setaf 2)\n##########		MONTAJE DE PARTICIONES		##########$(tput setaf 7)"
mount /dev/sda2 /mnt
mount --mkdir /dev/sda1 /mnt/boot/efi


echo -e "$(tput setaf 3)\n##########		INSTALACIÓN DE SISTEMA BASE		##########$(tput setaf 7)"
pacman -Sy archlinux-keyring --noconfirm
pacstrap /mnt base base-devel linux linux-firmware networkmanager grub vim sudo efibootmgr
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt


echo -e "$(tput setaf 4)\n##########		IDIOMA		##########$(tput setaf 7)"
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc
sed -i 's/#es_MX.UTF-8/es_MX.UTF-8/g' /etc/locale.gen
locale-gen
echo "LANG=es_MX.UTF-8" > /etc/locale.conf
echo "KEYMAP=la-latin1" > /etc/vconsole.conf


echo -e "$(tput setaf 5)\n##########		MÁQUINA, USR, PERMISOS		##########$(tput setaf 7)"
usuario="c04tl"
maquina="olinki"
url="192.168.0.2:8000"
echo $maquina > /etc/hostname
echo -e "127.0.0.1\t\t$maquina" >> /etc/hosts
echo -e "::1\t\t$maquina" >> /etc/hosts
echo -e "127.0.0.1\t\t$maquina"".localhost\t$maquina" >> /etc/hosts
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
useradd -m $usuario -s /usr/bin/zsh -G wheel
echo "$usuario:password" | chpasswd
echo "root:password" | chpasswd


echo -e "$(tput setaf 6)\n##########		INSTALACIÓN GRUB		##########$(tput setaf 7)"
grub-install --efi-directory=/boot/efi --target=x86_64-efi /dev/sda
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg


echo -e "$(tput setaf 6)\n##########		Mirror y DNS		##########$(tput setaf 7)"
#Cambiar los mirrrors y cambiar el namserver en /etc/resolv.conf
#https://archlinux.org/mirrorlist/
echo 'Server = https://arch.jsc.mx/$repo/os/$arch' > /etc/pacman.d/mirrorlist


echo -e "$(tput setaf 5)\n##########		i3-gaps		##########$(tput setaf 7)"
pacman -S i3-gaps i3blocks i3status xorg-server xorg-xset xorg-xrandr lightdm lightdm-gtk-greeter --noconfirm

# VirtualBox
pacman -S virtualbox-guest-utils --noconfirm
systemctl enable vboxservice

# VMware
# https://www.reddit.com/r/archlinux/comments/b0ona0/vmtools_on_arch_linux_full_screen_or_resizing/
#pacman -S gtkmm3 open-vm-tools xf86-input-vmmouse xf86-video-vmware mesa --noconfirm
#echo "needs_root_rights=yes" > /etc/X11/Xwrapper.config
#systemctl enable vmtoolsd vmware-vmblock-fuse


echo -e "$(tput setaf 4)\n##########		Habilitar servicios		##########$(tput setaf 7)"
systemctl enable NetworkManager lightdm


echo -e "$(tput setaf 3)\n##########		Paquetes esenciales		##########$(tput setaf 7)"
pacman -S git unzip wget firefox pcmanfm lxappearance zoxide fzf feh ttf-font-awesome picom zsh exa bat neovim cool-retro-term rofi picom --noconfirm


echo -e "$(tput setaf 5)\n##########		Plugins ZSH		##########$(tput setaf 7)"
mkdir /usr/share/zsh-plugins/
cd /usr/share/zsh-plugins/
wget "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh"
git clone https://github.com/zsh-users/zsh-autosuggestions


echo -e "$(tput setaf 5)\n##########		BLACKARCH ;)		##########$(tput setaf 7)"
mkdir -p /home/$usuario/Repos

cd /home/$usuario/Repos
git clone https://aur.archlinux.org/paru-bin.git

wget https://blackarch.org/strap.sh
chmod +x strap.sh
./strap.sh


echo -e "$(tput setaf 5)\n##########		Personalización		##########$(tput setaf 7)"
# Omite vsyn para maquinas virutales
sed -i 's/vsync = true/\# vsync = true/g' /etc/xdg/picom.conf

usermod --shell /usr/bin/zsh root
usermod --shell /usr/bin/zsh c04tl

mkdir -p /home/$usuario/.config/i3/ /home/$usuario/.config/i3blocks/ /home/$usuario/Wallpapers
wget "$url/i3/config" -O /home/$usuario/.config/i3/config
wget "$url/i3blocks/config" -O /home/$usuario/.config/i3blocks/config
wget "$url/i3blocks/cpu.sh" -O /home/$usuario/.config/i3blocks/cpu.sh

wget "$url/.zshrc" -O /home/$usuario/.zshrc
wget "$url/.p10k.zsh" -O /home/$usuario/.p10k.zsh


for (( i = 1; i < 7; i++ )); do
	wget "$url/Wallpapers/$i.jpg" -O /home/$usuario/Wallpapers/$i.jpg
done

chown -R $usuario:$usuario /home/$usuario/


su $usuario
cd ~

wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/SourceCodePro.zip
mkdir -p .local/share/fonts/
unzip SourceCodePro.zip -d .local/share/fonts/
fc-cache .local/share/fonts
rm SourceCodePro.zip


cd Repos/paru-bin
makepkg -si --noconfirm

paru -Sy

echo -e "$(tput setaf 5)\n##########		ZSH y Herramientas de Hacking		##########$(tput setaf 7)"
paru -S zsh-theme-powerlevel10k-git --noconfirm
paru -S python3 openvpn openssh nmap hydra dirb wfuzz ffuf seclists metasploit exploitdb radare2 sslscan whatweb nikto ssb smbclient impacket rubeus evilwinrm hashcat john --noconfirm


echo -e "$(tput setaf 3)\n##########		NVCHAD		##########$(tput setaf 7)"
git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1 && nvim
