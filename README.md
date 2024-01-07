## What's in dotfiles?

### Ubuntu

- Install some packages (`git`, `curl`, `tree`, `snapd`, `vim`, `zsh`, `gnome-shell-extensions-manager`, `python3-pip`)
- Config terminal profile
- Config vim
- Install fonts (`Fira Code`, `Source Code Pro`)
- Generate ssh key
- Install some programs (`VSCode`, `Postman`, `OBS Studio`)
- Bind shortcut (`Ctrl + Alt + t`)

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
cd ~/.dotfiles
```

```bash
./install.sh
```

### Windows

1. Install [git](https://git-scm.com/download/win)
1. `cd ~`
1. `git clone https://github.com/colpno/.dotfiles.git ~/.dotfiles`
1. `cd .dotfiles`
1. Run `install.bat`



## Acknowledgments

- [Add custom keybindings](https://techwiser.com/custom-keyboard-shortcuts-ubuntu/)
- [ohmyzsh](https://github.com/ohmyzsh/ohmyzsh)
- [ohmyposh](https://ohmyposh.dev/docs)
