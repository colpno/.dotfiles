#!/bin/bash
TERMINAL_PACKAGES="git curl tree snapd vim zsh gnome-shell-extension-manager "
PIP_PACKAGES="gnome-extensions-cli"
ZSH_PLUGINS="https://github.com/zsh-users/zsh-syntax-highlighting https://github.com/zsh-users/zsh-autosuggestions https://github.com/marlonrichert/zsh-autocomplete.git"
VIM_PLUGINS="https://tpope.io/vim/surround.git"
GNOME_EXTENSIONS="blur-my-shell@aunetx Vitals@CoreCoding.com toggle-night-light@cansozbir.github.io BingWallpaper@ineffable-gmail.com"

DOTHOME="vim/vimrc zsh/zshrc zsh/p10k.zsh git/gitconfig"
DOTFILES="$(pwd)"

COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

title() {
    echo -e "\n${COLOR_PURPLE}$1${COLOR_NONE}"
    echo -e "${COLOR_GRAY}==============================${COLOR_NONE}\n"
}

error() {
    echo -e "${COLOR_RED}Error: ${COLOR_NONE}$1"
    exit 1
}

warning() {
    echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1"
}

info() {
    echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

success() {
    echo -e "${COLOR_GREEN}$1${COLOR_NONE}"
}

create_dir_if_not_exist() {
	if [ ! -d "$1" ]; then
		info "Creating folder $1"
		mkdir -pv "$1"
	else
		warning "Folder is exist: $1"
	fi
}

install_fonts() {
	title "Installing fonts"
	FONT_DIR="/usr/share/fonts"

	sudo find ./fonts -name "*.[ot]tf" -type f -exec cp -v {} "$FONT_DIR/" \;

	if which fc-cache >/dev/null 2>&1 ;
	then
		fc-cache -fv "$USER_FONT_DIR"
		source /etc/profile
	fi
}

setup_profile() {
	title "Installing profile"

	info "Installing oh-my-zsh"
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --skip-chsh --keep-zshrc

	info "Installing oh-my-zsh plugins"
	cd ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/plugins}
	for plugin in $ZSH_PLUGINS
	do
		info "Installing $plugin"
		git clone --depth=1 $plugin
	done

	info "Installing vim plugins"
	create_dir_if_not_exist "$HOME/.vim/pack/plugins/start"

	cd ~/.vim/pack/plugins/start
	for plugin in $VIM_PLUGINS
	do
		info "Installing $plugin"
		git clone --depth=1 $plugin 
	done

	cd $DOTFILES

	info "Installing themes"
	create_dir_if_not_exist "$HOME/.vim/pack/themes/start"

	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/themes/powerlevel10k}
	git clone --depth=1 https://github.com/dracula/vim.git ~/.vim/pack/theme/start/dracula

	info "Restoring terminal profile"

	dconf load /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/ < ${DOTFILES}/gnome-terminal/profile.dconf

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
}

setup_symlinks() {
	title "Creating symlinks"

	for path in $DOTHOME
	do
		filename=$(basename "$path")
		info "Creating symlink for $filename"

		rm -rf ~/."$filename"
		ln -sv "$DOTFILES/$path" ~/."$filename"
	done
}

setup_package_manager() {
	title "Installing package managers"

	flag=0
	read -p "What package manager do you use? [npm]: " pkgmng

	while [ $flag -eq 0 ];
	do
		case $pkgmng in
			npm)
				info "Installing nvm"
				curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
				source ~/.zshrc

				info "Installing npm"
				is_continue="y"
				while [ "$is_continue" == "y" ];
				do
					nvm ls
					printf "\n"
					read -p "Type in the version of npm [--lts/version]: " npm_version

					nvm install $npm_version

					read -p "Another version? [y/n]: " is_continue
				done

				flag=1
				;;
			*)
				warning "$pkgmng is not listed"
				read -p "What package manager do you use? [npm]: " pkgmng
				;;
		esac
	done
}

setup_git() {
	title "Creating github ssh key"

	ssh-keygen -t ed25519 -C "gvinhh@gmail.com"
	eval "$(ssh-agent -s)"
	ssh-add ~/.ssh/id_ed25519

	info "SSH key: "
	cat ~/.ssh/id_ed25519.pub

	flag=0
	while [ $flag -eq 0 ]; do
		printf "\n"
		read -p "Confirm that you've added the SSH public key to your account on GitHub: https://github.com/settings/ssh/new [y/n]: " opt

		if [[ $opt == "y" ]];
		then
			flag=1
		fi
	done
}

install_gnome_extensions() {
	title "Installing gnome extensions"

	for extension in $GNOME_EXTENSIONS
	do
		info "Installing $extension"
		gext install $extension
	done
}

bind_key() {
	title "Binding shortcut key"

	# Create key binding list
	gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"

	# Bind key
	gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name "'Launch terminal'"
	gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding "'gnome-terminal --maximize'"
	gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "'<Primary><Alt>t'"
}

install_program() {
	title "Installing programs"

	info "Installing VS Code"
	sudo snap install --classic code

	info "Installing OBS Studio"
	sudo add-apt-repository ppa:obsproject/obs-studio
	sudo apt install -y obs-studio

	info "Installing Postman"
	sudo snap install postman
}

install_pip_pkg() {
	title "Installing packages via pip"


	for package in $PIP_PACKAGES
	do
		info "Installing $package"
		pip3 install $package
	done
}

# Prerequisites

info "Updating apt repository"
sudo apt update

for package in $TERMINAL_PACKAGES
do
	info "Installing $package"
	sudo apt install -y "$package"
done

# Installation

installation_guide() {
	printf "\n${COLOR_YELLOW}0: ${COLOR_NONE}Automatically install"
	printf "\n${COLOR_YELLOW}1: ${COLOR_NONE}Install fonts"
	printf "\n${COLOR_YELLOW}2: ${COLOR_NONE}Set up profile"
	printf "\n${COLOR_YELLOW}3: ${COLOR_NONE}Create symlinks"
	printf "\n${COLOR_YELLOW}4: ${COLOR_NONE}Install package managers"
	printf "\n${COLOR_YELLOW}5: ${COLOR_NONE}Set up git"
	printf "\n${COLOR_YELLOW}6: ${COLOR_NONE}Install gnome extensions"
	printf "\n${COLOR_YELLOW}7: ${COLOR_NONE}Bind shortcut keys"
	printf "\n${COLOR_YELLOW}8: ${COLOR_NONE}Install programs"
	printf "\n${COLOR_YELLOW}q: ${COLOR_NONE}Exit"

	echo -ne "\nType in the option: "
	read opt

	return $opt
}

installation_guide

while [ "$opt" != "q" ];
do
	case "$opt" in
		0)
			install_fonts
			setup_profile
			setup_symlinks
			setup_package_manager
			setup_git
			install_gnome_extensions
			bind_key
			install_program

			sudo chsh -s $(which zsh)
			zsh
			;;
		1)
			install_fonts
			;;
		2)
			setup_profile
			;;
		3)
			setup_symlinks
			;;
		4)
			setup_package_manager
			;;
		5)
			setup_git
			;;
		6)
			install_gnome_extensions
			;;
		7)
			bind_key
			;;
		8)
			install_program
			;;
		q)
			exit 1
			;;
	esac

	installation_guide
done

success "Done"
