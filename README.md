## Table of Contents

- [Installation](#installation)
	- [Ubuntu](#ubuntu)
	- [Windows](#windows)
- [Usage](#usage)
	- [Vim](#vim)
	- [Todo.txt](#todotxt)
	- [Unikey (Telex)](#unikey-telex)
	- [Jump to visited folder with z](#jump-to-visited-folder)
- [Configuration](#configuration)
	- [Windows terminal theme](#windows-terminal-theme-ohmyposh)
	- [Linux terminal theme](#linux-terminal-theme-ohmyzsh-powerlevel10k)
	- [Vim](#vim-1)
	- [Dconf](#dconf)
	- [Todo.txt](#todotxt-1)
- [Acknowledgments](#acknowledgments)



## Installation

### Ubuntu

```sh
sudo apt update
sudo apt install git -y
git clone https://github.com/colpno/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh
```

> After the installation, restart the system to get it working:
> ```sh
> sudo reboot
> ```

### Windows

1. Install [git](https://git-scm.com/download/win)
1. `git clone https://github.com/colpno/.dotfiles.git ~/.dotfiles`
1. `cd ~/.dotfiles`
1. Run `install.bat`



## Usage

### Vim

type `vim`, then a file or path to file.

### Todo.txt

##### Add

```sh
t add "todo"
```

##### Remove the todo on line 1

```sh
t rm 1
```

##### Replace the todo on line 1 with updated

```sh
t replace 1 "updated"
```

##### List tasks

```sh
t ls
```

##### Mark the task on line 1 as done

```sh
t do 1
```

### Unikey (Telex)

<kbd>Super</kbd> + <kbd>Space</kbd>

### Jump to visited folder with z

```sh
z folder
```



## Configuration

### Windows terminal theme (ohmyposh)

Visit [Configuration page](https://ohmyposh.dev/docs/configuration/general) for customizing.

### Linux terminal theme (ohmyzsh, powerlevel10k)

run `~/.dotfiles/gnome-terminal/print-256-colors.sh` to print colors to console.

#### ohmyzsh

Read [ohmyzsh wiki](https://github.com/ohmyzsh/ohmyzsh/wiki).

#### powerlevel10k

Read inline comments in `p10k.zsh` file.

### Font

If you want to add a **new font**, then add a folder of `.tff` files in `fonts`.  

To delete a font, find its name in `/usr/share/fonts` and delete all related.

### Vim

Type `:options` while using vim.

### Dconf

For exporting system dconf settings to a file:
```sh
dconf dump / > settings.dconf
```

For importing an exist dconf file to system:
```sh
dconf load / < settings.dconf
```

### Todo.txt

Read inline comments in `config` file.



## Acknowledgments

- [Add custom keybindings](https://techwiser.com/custom-keyboard-shortcuts-ubuntu/)
- [Linux terminal theme](https://github.com/ohmyzsh/ohmyzsh)
- [Window terminal theme](https://ohmyposh.dev/docs)
- [Install Visual Studio Code on Linux](https://code.visualstudio.com/docs/setup/linux#_installation)
