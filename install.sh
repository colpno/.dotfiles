#!/bin/bash
TERMINAL_PACKAGES="git curl tree snapd vim zsh gnome-shell-extension-manager python3-pip ibus-unikey make cargo gpg apt-transport-https"
PIP_PACKAGES="gnome-extensions-cli"
ZSH_PLUGINS="https://github.com/zsh-users/zsh-syntax-highlighting https://github.com/zsh-users/zsh-autosuggestions https://github.com/marlonrichert/zsh-autocomplete.git"
VIM_PLUGINS="https://tpope.io/vim/surround.git"
GNOME_EXTENSIONS="blur-my-shell@aunetx BingWallpaper@ineffable-gmail.com toggle-night-light@cansozbir.github.io Vitals@CoreCoding.com theme-switcher@fthx"
UNINSTALL_PACKAGES="make cargo gpg apt-transport-https"

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
	sh -cv "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc

	info "Installing oh-my-zsh plugins"
	cd ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/plugins}
	for plugin in $ZSH_PLUGINS
	do
		info "Installing $plugin"
		git clone --depth=1 $plugin
	done
	cd $DOTFILES

	info "Installing themes"
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/themes/powerlevel10k}

	info "Restoring user dconf"
	dconf load / < ${DOTFILES}/gnome-terminal/user.dconf
}

setup_symlinks() {
	title "Creating symlinks"

	for path in $DOTHOME
	do
		filename=$(basename "$path")
		info "Creating symlink for $filename"
		ln -svf "$DOTFILES/$path" ~/."$filename"
	done

	info "Creating symlink for todotxt"
	mkdir -v ~/.todo
	ln -svf "$DOTFILES/todotxt/config" ~/.todo/config
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

install_program() {
	read -p "Do you want to install the programs? [y/n]: " opt
	if [[ "$opt" == "y" ]]; then
		title "Installing programs"

		info "Installing VS Code"
		wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
		sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
		sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
		rm -f packages.microsoft.gpg
		sudo apt update
		sudo apt install code

		info "Installing OBS Studio"
		sudo add-apt-repository ppa:obsproject/obs-studio
		sudo apt install -y obs-studio

		info "Installing Postman"
		sudo snap install postman

		info "Installing Spotify"
		curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
		echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
		sudo apt-get update && sudo apt-get install spotify-client
		git clone --depth=1 https://github.com/abba23/spotify-adblock.git
		cd spotify-adblock && make
		sudo make install
		cd ../ && rm -rf spotify-adblock
	fi
}

install_pip_pkg() {
	title "Installing pip packages"

	for package in $PIP_PACKAGES
	do
		info "Installing $package"
		pip3 install --upgrade "$package"
	done
}

install_terminal_pkg() {
	title "Installing terminal packages"

	for package in $TERMINAL_PACKAGES
	do
		info "Installing $package"
		sudo apt install -y "$package"
	done

	info "Installing todo.txt"
	git clone --depth=1 git@github.com:todotxt/todo.txt-cli.git
	cd todo.txt-cli
	sudo make
	sudo make install
	cp -fv todo.cfg ~/.todo/config
	cd ../ && rm -rfv todo.txt-cli
}

install_laravel() {
	title "Installing Laravel"

	info "Installing php"
	sudo apt install -y php php-common php-cli php-gd php-mysqlnd php-curl php-intl php-mbstring php-bcmath php-xml php-zip

	info "Installing composer"
	curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

	title "Installing mysql"
	sudo apt install -y mysql-server
}

clean_up() {
	title "Cleaning up"

	for package in $UNINSTALL_PACKAGES
	do
		info "Uninstalling $package"
		sudo apt remove --purge -y "$package"
	done

	sudo apt autoremove -y
}

installation_guide() {
	printf "\n${COLOR_YELLOW}0: ${COLOR_NONE}Automatically install"
	printf "\n${COLOR_YELLOW}1: ${COLOR_NONE}Install fonts"
	printf "\n${COLOR_YELLOW}2: ${COLOR_NONE}Install package managers"
	printf "\n${COLOR_YELLOW}3: ${COLOR_NONE}Set up git"
	printf "\n${COLOR_YELLOW}4: ${COLOR_NONE}Install gnome extensions"
	printf "\n${COLOR_YELLOW}5: ${COLOR_NONE}Install programs"
	printf "\n${COLOR_YELLOW}6: ${COLOR_NONE}Set up profile"
	printf "\n${COLOR_YELLOW}7: ${COLOR_NONE}Clean up"
	printf "\n${COLOR_YELLOW}8: ${COLOR_NONE}Restart zsh"
	printf "\n${COLOR_YELLOW}9: ${COLOR_NONE}Install Laravel"
	printf "\n${COLOR_YELLOW}q: ${COLOR_NONE}Exit"

	echo -ne "\nType in the option: "
	read opt
}

title "Updating apt repository"
sudo apt update

installation_guide

while [ "$opt" != "q" ];
do
	case "$opt" in
		[0-9]*)
			case "$opt" in
				0)
					install_terminal_pkg
					setup_symlinks
					install_pip_pkg

					install_fonts
					setup_package_manager
					setup_git
					install_gnome_extensions
					install_program
					setup_profile
					clean_up

					chsh -s /usr/bin/zsh
					zsh
					;;
				1)
					install_fonts
					;;
				2)
					setup_package_manager
					;;
				3)
					setup_git
					;;
				4)
					install_gnome_extensions
					;;
				5)
					install_program
					;;
				6)
					setup_profile
					;;
				7)
					clean_up
					;;
				8)
					chsh -s /usr/bin/zsh
					zsh
					;;
				9)
					install_laravel
					;;
				*)
					echo "Invalid option"
					;;
			esac
			;;
		[A-Za-z]*)
			case "$opt" in
				q)
					exit 1
					;;
				*)
					echo "Invalid option"
					;;
			esac
			;;
		*)
			echo "Invalid option"
			;;
	esac

	installation_guide
done

success "\nDone"

