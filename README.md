## What's in dotfiles?

### Ubuntu

- Install some packages (`git`, `curl`, `tree`, `snapd`, `vim`, `zsh`, `gnome-shell-extensions-manager`, `python3-pip`, `ibus-unikey`)
- Install some pip packages (`gnome-extensions-cli`)
- Config profile
- Config vim
- Create symlinks
- Install fonts (`Fira Code`, `Source Code Pro`)
- Generate ssh key
- Install some programs (`VSCode`, `Postman`, `OBS Studio`)
- Install some gnome extensions (`Blur my screen`, `Vitals`, `Toggle Night Light`, `Bing Wallpaper`)

### Windows

- Install terminal
- Install some apps (`TranslucentTB`)



## Installation

### Ubuntu

```bash
sudo apt update
```

```bash
sudo apt install git
```

```bash
git clone https://github.com/colpno/.dotfiles.git ~/.dotfiles
```

```bash
cd ~/.dotfiles && ./install.sh
```

After the installation, do the following:
1. Restart (Reboot) the system 
1. Add **Vietnamese (Unikey)** to **Input Source**
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
