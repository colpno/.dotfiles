#!/bin/bash
APT_PACKAGES="git curl tree snapd vim zsh gnome-shell-extension-manager python3-pip ibus-unikey make cargo gpg apt-transport-https xsel wl-clipboard gpaste"
ZSH_PLUGINS="https://github.com/zsh-users/zsh-syntax-highlighting https://github.com/zsh-users/zsh-autosuggestions https://github.com/marlonrichert/zsh-autocomplete.git"
GNOME_EXTENSIONS="blur-my-shell@aunetx BingWallpaper@ineffable-gmail.com toggle-night-light@cansozbir.github.io Vitals@CoreCoding.com theme-switcher@fthx"
CLEAN_UP_APT_PACKAGES="make cargo gpg apt-transport-https"

SYMLINKS_HOME="vim/vimrc zsh/zshrc zsh/p10k.zsh git/gitconfig"
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

multiple_select_question="Choose"
multiple_select() {
    local options=("$@")
    selected=()

    menu() {
		clear
        for i in ${!options[@]}; do
            printf "%3d[%s] %s\n" $((i+1)) "${choices[i]:- }" "${options[i]}"
        done
        [[ "$msg" ]] && echo "$msg"; :
    }

    local prompt="$multiple_select_question (again to uncheck, ENTER when done): "
    while menu && read -rp "$prompt" num && [[ "$num" ]]; do
        case $num in
            q|Q) 
				selected=()
				break ;;
        esac
        [[ "$num" != *[![:digit:]]* ]] &&
        (( num > 0 && num <= ${#options[@]} )) ||
        { msg="Invalid option: $num"; continue; }
        ((num--)); msg=""
        [[ "${choices[num]}" ]] && choices[num]="" || choices[num]="+"
    done

    for i in ${!options[@]}; do
        [[ "${choices[i]}" ]] && selected+=("${options[i]}")
    done

	options=()
	choices=()
}

install_fonts() {
	title "Installing fonts"
	local FONT_DIR="/usr/share/fonts"

	sudo find ./fonts -name "*.[ot]tf" -type f -exec cp -v {} "$FONT_DIR/" \;

	if which fc-cache >/dev/null 2>&1 ;
	then
		fc-cache -fv "$USER_FONT_DIR"
		source /etc/profile
	fi

	success "Fonts are installed"
}

setup_terminal_profile() {
	title "Configuring profile"

	info "Installing oh-my-zsh"
	sh -cv "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
	success "oh-my-zsh is installed"

	info "Installing oh-my-zsh's plugins"
	cd ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/plugins}
	for plugin in $ZSH_PLUGINS
	do
		info "Installing $plugin"
		git clone --depth=1 $plugin
		success "$plugin is installed"
	done
	cd $DOTFILES

	info "Installing powerlevel10k theme"
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/themes/powerlevel10k}
	success "powerlevel10k is installed"

	info "Restoring user dconf"
	dconf load / < ${DOTFILES}/gnome-terminal/user.dconf

	success "Profile is configured"
}

create_symlinks() {
	title "Creating symlinks"

	for path in $SYMLINKS_HOME
	do
		local filename=$(basename "$path")
		info "Creating symlink for $filename"
		ln -svf "$DOTFILES/$path" ~/."$filename"
		success "Symlink of $filename is created"
	done

	mkdir -v ~/.todo
	ln -svf "$DOTFILES/todotxt/config" ~/.todo/config
	success "Symlink of todo config is created"
}

install_js_pkg_managers() {
	title "Installing Javascript package managers"

	local packages=("$@")

	if [[ "${packages[@]}" =~ "npm" ]]; then
		info "Installing nvm"
		curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
		source ~/.zshrc
		success "nvm is installed"

		info "Installing npm"
		local is_continue="y"
		while [ "$is_continue" == "y" ];
		do
			nvm ls
			printf "\n"
			read -p "Type in the version of npm [--lts/version]: " npm_version

			nvm install $npm_version
			success "npm $npm_version is installed"

			read -p "Another version? [y/n]: " is_continue
		done
	fi
}

setup_github_ssh() {
	title "Creating github ssh key"

	ssh-keygen -t ed25519 -C "gvinhh@gmail.com"
	eval "$(ssh-agent -s)"
	ssh-add ~/.ssh/id_ed25519

	info "SSH key: "
	cat ~/.ssh/id_ed25519.pub

	local flag=0
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

	pip3 install --upgrade gnome-extensions-cli

	for extension in $GNOME_EXTENSIONS
	do
		info "Installing $extension"
		gext install $extension
		success "$extension is installed"
	done
}

install_programs() {
	title "Installing programs"

	local programs=("$@")

	if [[ "${programs[@]}" =~ "VS Code" ]]; then
		info "Installing VS Code"

		wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
		sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
		sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
		rm -f packages.microsoft.gpg
		sudo apt update
		sudo apt install code

		success "VS Code is installed"
	fi

	if [[ "${programs[@]}" =~ "OBS Studio" ]]; then
		info "Installing OBS Studio"

		sudo add-apt-repository ppa:obsproject/obs-studio
		sudo apt install -y obs-studio

		success "OBS Studio is installed"
	fi

	if [[ "${programs[@]}" =~ "Postman" ]]; then
		info "Installing Postman"

		sudo snap install postman

		success "Postman is installed"
	fi

	if [[ "${programs[@]}" =~ "Spotify" ]]; then
		info "Installing Spotify"

		curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
		echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
		sudo apt-get update && sudo apt-get install spotify-client
		git clone --depth=1 https://github.com/abba23/spotify-adblock.git
		cd spotify-adblock && make
		sudo make install
		cd ../ && rm -rf spotify-adblock

		success "Spotify is installed"
	fi
}

install_apt_pkg() {
	title "Installing terminal packages"

	for package in $APT_PACKAGES
	do
		info "Installing $package"
		sudo apt install -y "$package"
		success  "$package is installed"
	done

	title "Installing todo.txt"
	git clone --depth=1 git@github.com:todotxt/todo.txt-cli.git
	cd todo.txt-cli
	sudo make
	sudo make install
	cp -fv todo.cfg ~/.todo/config
	cd ../ && rm -rfv todo.txt-cli
	success "todo.txt is installed"
}

install_laravel() {
	title "Installing Laravel"

	info "Installing PHP"
	sudo apt install -y php php-common php-cli php-gd php-mysqlnd php-curl php-intl php-mbstring php-bcmath php-xml php-zip
	success "PHP is installed"

	info "Installing Composer"
	curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
	success "Composer is installed"

	info "Installing MySQL"
	sudo apt install -y mysql-server
	success "MySQL is installed"
}

clean_up() {
	title "Cleaning up"

	for package in $CLEAN_UP_APT_PACKAGES
	do
		info "Uninstalling $package"
		sudo apt remove --purge -y "$package"
	done

	sudo apt autoremove -y

	success "Cleaned up"
}

installation() {
	local selected_pkg_mngrs=""
	local selected_programs=""
	local laravel=""

	multiple_select_question="Choose the package manager(s)"
	local pkg_mngrs=("npm")
	multiple_select "${pkg_mngrs[@]}"
	selected_pkg_mngrs="${selected[@]}"

	multiple_select_question="Choose the program(s)"
	local programs=("VS Code" "OBS Studio" "Postman" "Spotify")
	multiple_select "${programs[@]}"
	selected_programs="${selected[@]}"

	clear
	PS3="Do you want to install Laravel? "
	select opt in yes no; do
		case $opt in
			yes) 
				laravel="yes"
				break ;;
			no) 
				laravel="no"
				break ;;
			*) echo "Invalid option $opt" ;;
		esac
	done

	title "Updating apt repository"
	sudo apt update

	install_apt_pkg
	create_symlinks
	install_fonts
	install_js_pkg_managers "${selected_pkg_mngrs[@]}"
	setup_github_ssh
	install_gnome_extensions
	install_programs "${selected_programs[@]}"
	setup_terminal_profile
	[[ "$laravel" = "yes" ]] && install_laravel
	clean_up

	chsh -s /usr/bin/zsh
	zsh
}

installation
success "Done"
