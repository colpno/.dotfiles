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
- [Troubleshooting](#troubleshooting)
- [Acknowledgments](#acknowledgments)



## Installation

### Ubuntu

```sh
sudo apt update
sudo apt install git -y
git clone https://github.com/colpno/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles/ubuntu && ./install.sh
```

> After the installation, restart the system to get it working:
> ```sh
> sudo reboot
> ```

### Windows

1. Install [git](https://git-scm.com/download/win)
1. `git clone https://github.com/colpno/.dotfiles.git ~/.dotfiles`
1. `cd ~/.dotfiles/windows`
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



## Troubleshooting

### Wireless keyboard function keys

#### Description

The function keys work without pressing <kbd>Fn</kbd>. And it makes the original keys not functioning as usual.

#### Example

- Assign <kbd>F12</kbd> with increase volume.
- Pressing <kbd>Fn</kbd> and <kbd>F12</kbd>.
- Volume is increased instead.

#### Expected behavior

Function keys only work by pressing with <kbd>Fn</kbd>.

#### Solve

There are 2 ways:

#### Run a command

```sh
echo 0 | sudo tee /sys/module/hid_apple/parameters/fnmode
```

The inconvenient is that you will have to re-run the command every time you reboot.  
If you want to avoid this issue, please follow the [next way](#create-a-service-to-run-the-command).

#### Create a service to run the command

Create a new service file:

```sh
sudo vim /etc/systemd/system/fnmode.service
```

Add the following content to the file:

```sh
[Unit]
Description=Set fnmode for hid_apple

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo 0 | tee /sys/module/hid_apple/parameters/fnmode'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Save and close the file.

Reload the systemd daemon to recognize the new service:

```sh
sudo systemctl daemon-reload
```

Enable the service to run at startup:

```sh
sudo systemctl enable fnmode.service
```

Start the service immediately:

```sh
sudo systemctl start fnmode.service
```



## Acknowledgments

- [Add custom keybindings](https://techwiser.com/custom-keyboard-shortcuts-ubuntu/)
- [Linux terminal theme](https://github.com/ohmyzsh/ohmyzsh)
- [Window terminal theme](https://ohmyposh.dev/docs)
- [Install Visual Studio Code on Linux](https://code.visualstudio.com/docs/setup/linux#_installation)
- [Fix keyboard function keys work without pressing Fn key on Ubuntu](https://askubuntu.com/a/1194871)
- [Interact with dconf settings](https://askubuntu.com/questions/984205/how-to-save-gnome-settings-in-a-file)
- [Dual boot Windows and Ubuntu instruction](https://www.youtube.com/watch?v=lGR_VNwUfzk&list=PLWMFYxNitOVEX9u0ZNspjcmdyWmy7BCp8&index=1&t=658s)
- Path to where the original Spotify locates: `/var/lib/snapd/desktop/applications`

```spotify_spotify.desktop
[Desktop Entry]
X-SnapInstanceName=spotify
Type=Application
Name=Spotify
GenericName=Music Player
Icon=/snap/spotify/83/usr/share/spotify/icons/spotify-linux-128.png
X-SnapAppName=spotify
Exec=env BAMF_DESKTOP_FILE_HINT=/var/lib/snapd/desktop/applications/spotify_spotify.desktop /snap/bin/spotify %U
Terminal=false
MimeType=x-scheme-handler/spotify;
Categories=Audio;Music;Player;AudioVideo;
StartupWMClass=spotify
```

