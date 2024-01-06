#!/bin/bash
TERMINAL_PACKAGES="git curl tree python3 snapd vim zsh gnome-shell-extensions"
ZSH_PLUGINS="https://github.com/zsh-users/zsh-syntax-highlighting https://github.com/zsh-users/zsh-autosuggestions https://github.com/marlonrichert/zsh-autocomplete.git"
VIM_PLUGINS="https://tpope.io/vim/surround.git"
GNOME_EXTENSIONS="blur-my-shell@aunetx Vitals@CoreCoding.com toggle-night-light@cansozbir.github.io BingWallpaper@ineffable-gmail.com"

DOTHOME="vim/vimrc zsh/zshrc zsh/p10k.zsh git/gitconfig"
MKDIRS="$HOME/.fonts $HOME/.oh-my-zsh/custom/plugins $HOME/.oh-my-zsh/custom/themes $HOME/.vim/pack/plugins/start $HOME/.vim/pack/theme/start"
DOTFILE_DIR="$HOME/.dotfiles"

# Prerequisites
if [ ! -d $DOTFILE_DIR ]; then
	echo "Can' find .dotfiles in home directory"
	exit
fi

sudo apt update

for dir in $MKDIRS do
	sudo mkdir -p $dir
done

# Install terminal packages
for package in $TERMINAL_PACKAGES do
	if ! dpkg-query -W -f='${Status}' git  | grep "ok installed" > /dev/null; then
		sudo apt install -y "$package"
	fi
done

# Install terminal

## Change shell to zsh
sudo chsh -s $(which zsh)

## Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install fonts

## Copy fonts to user fonts directory
find 'fonts' \( -name "*.[ot]tf" -or -name "*.pcf.gz" \) -type f -print0 | xargs -0 -n1 -I % cp "%" "$USER_FONT_DIR/"

## Reset font cache
if which fc-cache >/dev/null 2>&1 ; then
    fc-cache -f "$USER_FONT_DIR"
fi

# Install profile

## Install plugins
cd ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins
for plugin in $ZSH_PLUGINS do
	git clone --depth=1 $plugin 
done

cd ${HOME}/.vim/pack/plugins/start
for plugin in $VIM_PLUGINS do
	git clone --depth=1 $plugin 
done

## Install themes
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone --depth=1 https://github.com/dracula/vim.git ~/.vim/pack/theme/start/dracula

## Apply terminal profile config
dconf load /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9 < terminal/profile.dconf

add_list_id=b1dcc9dd-5262-4d8d-a863-c897e6d979b9
old_list=$(dconf read /org/gnome/terminal/legacy/profiles:/list | tr -d "]")

if [ -z "$old_list" ]
then
	front_list="["
else
	front_list="$old_list, "
fi

new_list="$front_list'$add_list_id']"
dconf write /org/gnome/terminal/legacy/profiles:/list "$new_list" 
dconf write /org/gnome/terminal/legacy/profiles:/default "'$add_list_id'"

## Create symlink
for path in $DOTHOME do
	filename=$(basename "$path")
	rm -rf ~/."$filename"
	ln -s "$DOTFILE_DIR/$path" ~/."$filename"
done

# Install package manager
read -p "What package manager do you use? [npm]: " pkgmng
flag=0
while [ $flag -eq 0 ]; do
	case pkgmng in
		npm)
			curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
			source ~/.zshrc

			nvm ls
			is_continue="y"
			printf "\n"
			while [ "$is_continue" == "y" ]; do
				read -p "Type in the version of npm [--lts/version]: " npm_version
				nvm install $npm_version
				read -p "Continue? [y/n]: " is_continue
			done

			flag=1
			;;
		*)
			read -p "What package manager do you use? [npm]: " pkgmng
			;;
	esac
done

# Generate SSH Key
ssh-keygen -t ed25519 -C "gvinhh@gmail.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

printf "SSH key:\n"
cat ~/.ssh/id_ed25519.pub

flag=0
while [ $flag -eq 0 ]; do
	printf "\n"
	read -p "Confirm that you've added the SSH public key to your account on GitHub: https://github.com/settings/ssh/new [y/n]: " opt

	if [ $opt == "y"]; then
		flag=1
	fi
done

# Install gnome extensions
for extension in $GNOME_EXTENSIONS do
	gnome-extensions install $extension
done

# Add key bindings

## Create key binding list
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"

## Bind key
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name "'Launch terminal'"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding "'gnome-terminal --maximize'"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "'<Primary><Alt>t'"

# Install programs

## VSCode
sudo snap install --classic code

## OBS Studio
sudo add-apt-repository ppa:obsproject/obs-studio
sudo apt install obs-studio

## Postman
sudo snap install postman

# Restart shell
exec zsh
