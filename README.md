## What's in dotfiles?

### Ubuntu

- Install some necessary packages (`git`, `curl`, `tree`, `snapd`, `vim`, `zsh`, `gnome-shell-extensions-manager`, `python3-pip`, `ibus-unikey`)
- Install some pip packages (`gnome-extensions-cli`)
- Config profile
- Config vim
- Create symlinks
- Install fonts (`Fira Code`, `Source Code Pro`)
- Generate ssh key
- Install some programs (`VSCode`, `Postman`, `OBS Studio`)
- Install some gnome extensions (`blur-my-shell`, `Vitals`, `toggle-night-light`, `BingWallpaper`, `theme-switcher`)
- Optionally install Laravel + MySQL

### Windows

- Install terminal
- Install some apps (`TranslucentTB`)



## Installation

### Ubuntu

```bash
sudo apt update
sudo apt install git -y
git clone https://github.com/colpno/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh
```

#### NOTE:
After the installation, do the following:
1. Restart (Reboot) the system 
1. Change **Keyboard input method system** to **none** in **Language Support**

### Windows

1. Install [git](https://git-scm.com/download/win)
1. `git clone https://github.com/colpno/.dotfiles.git ~/.dotfiles`
1. `cd ~/.dotfiles`
1. Run `install.bat`



## Acknowledgments

- [Add custom keybindings](https://techwiser.com/custom-keyboard-shortcuts-ubuntu/)
- [ohmyzsh](https://github.com/ohmyzsh/ohmyzsh)
- [ohmyposh](https://ohmyposh.dev/docs)
- [Install MySQL on Ubuntu](https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-20-04)
