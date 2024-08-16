#!/bin/bash
APT_PACKAGES="git curl tree snapd vim zsh gnome-shell-extension-manager pipx ibus-unikey make cargo gpg apt-transport-https xsel wl-clipboard gpaste"
ZSH_PLUGINS="https://github.com/zsh-users/zsh-syntax-highlighting https://github.com/zsh-users/zsh-autosuggestions https://github.com/marlonrichert/zsh-autocomplete.git"
GNOME_EXTENSIONS="blur-my-shell@aunetx BingWallpaper@ineffable-gmail.com Vitals@CoreCoding.com bluetooth-battery@michalw.github.com"
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

value_in_array() {
    local match="$1"
    shift
    for e; do
        [[ $e == *"$match"* ]] && return 0
    done
    return 1
}

multiple_select() {
	local question="$1"
	shift
    local options=("$@")
    selected=()

    menu() {
		clear
        for i in ${!options[@]}; do
            printf "%3d[%s] %s\n" $((i+1)) "${choices[i]:- }" "${options[i]}"
        done
        [[ "$msg" ]] && echo "$msg"; :
    }

    local prompt="$question (again to uncheck, ENTER when done): "
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

	{
		sudo find "$DOTFILES/fonts" -name "*.[ot]tf" -type f -exec cp -v {} "$FONT_DIR/" \;

		if which fc-cache >/dev/null 2>&1 ;
		then
			fc-cache -fv "$USER_FONT_DIR"
			source /etc/profile
		fi

		success "Fonts are installed"
	} || {
		error "Failed to install fonts"
	}

}

setup_terminal_profile() {
	title "Configuring profile"

	info "Installing oh-my-zsh"
	{
		sh -cv "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
		success "oh-my-zsh is installed"
	} || {
		error "Failed to install oh-my-zsh"
	}

	info "Installing oh-my-zsh's plugins"
	{
		cd ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/plugins}
		for plugin in $ZSH_PLUGINS
		do
			info "Installing $plugin"
			git clone --depth=1 $plugin
			success "$plugin is installed"
		done
	} || {
		error "Failed to install oh-my-zsh plugins"
	}
	cd $DOTFILES

	info "Installing Powerlevel10k"
	{
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/themes/powerlevel10k}
		success "Powerlevel10k is installed"
	} || {
		error "Failed to install Powerlevel10k"
	}

	info "Restoring user dconf"
	{
		dconf load / < ${DOTFILES}/gnome-terminal/user.dconf
		success "User dconf is restored"
	} || {
		error "Failed to restore user dconf"
	}
}

create_symlinks() {
	title "Creating symlinks"

	for path in $SYMLINKS_HOME
	do
		{
			local filename=$(basename "$path")
			info "Creating symlink for $filename"
			rm -rfv "$filename"
			ln -svf "$DOTFILES/$path" ~/."$filename"
			success "Symlink of $filename is created"
		} || {
			error "Failed to create symlink for $filename"
		}
	done

	{
		info "Creating symlink for todotxt config"
		rm -rfv ~/.todo
		create_dir_if_not_exist ~/.todo
		ln -svf "$DOTFILES/todotxt/config" ~/.todo/config
		success "Symlink of todo config is created"
	} || {
		error "Failed to create symlink for todotxt config"
	}
}

install_js_pkg_managers() {
	title "Installing Javascript package managers"

	local packages=("$@")

	if [[ "${packages[@]}" =~ "npm" ]]; then
		info "Installing NVM"
		{
			curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
			source ~/.zshrc
			success "NVM is installed"
		} || {
			error "Failed to install NVM"
		}

		info "Installing NPM"
		{
			nvm install --lts
			success "Latest NPM version is installed"
		} || {
			error "Failed to install NPM"
		}
	fi

	if [[ "${packages[@]}" =~ "yarn" ]]; then
		info "Installing Yarn"
		{
			curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
			echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
			sudo apt update
			sudo apt install --no-install-recommends yarn
			success "Latest Yarn version is installed"
		} || {
			error "Failed to install Yarn"
		}
	fi
}

setup_github_ssh() {
	title "Generating Github SSH key"

	{
		ssh-keygen -t ed25519 -C "gvinhh@gmail.com"
		eval "$(ssh-agent -s)"
		ssh-add ~/.ssh/id_ed25519

		info "SSH key: "
		cat ~/.ssh/id_ed25519.pub
		read -p "ENTER when done Github SSH establishing"
	} || {
		error "Failed to generate Github SSH key"
	}
}

install_gnome_extensions() {
	title "Installing gnome extensions"

	{
		pipx install gnome-extensions-cli
		for extension in $GNOME_EXTENSIONS
		do
			{
				info "Installing $extension"
				gext install $extension
				success "$extension is installed"
			} || {
				error "Failed to install $extension"
			}
		done
	} || {
		error "Failed to install gnome-extensions-cli"
	}

}

install_programs() {
	title "Installing programs"

	local programs=("$@")

	if [[ "${programs[@]}" =~ "VS Code" ]]; then
		info "Installing VS Code"

		{
			wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
			sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
			sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
			rm -f packages.microsoft.gpg
			sudo apt update
			sudo apt install code

			success "VS Code is installed"
		} || {
			error "Failed to install VS Code"
		}
	fi

	if [[ "${programs[@]}" =~ "OBS Studio" ]]; then
		info "Installing OBS Studio"

		{
			sudo add-apt-repository ppa:obsproject/obs-studio
			sudo apt install -y obs-studio

			success "OBS Studio is installed"
		} || {
			error "Failed to install OBS Studio"
		}
	fi

	if [[ "${programs[@]}" =~ "Postman" ]]; then
		info "Installing Postman"

		{
			sudo snap install postman
			success "Postman is installed"
		} || {
			error "Failed to install Postman"
		}
	fi

	if [[ "${programs[@]}" =~ "Spotify" ]]; then
		info "Installing Spotify"

		{
			git clone --depth=1 https://github.com/abba23/spotify-adblock.git
			if [ $? -eq 0 ]; then
				cd spotify-adblock && make && sudo make install && cd ../ && rm -rf spotify-adblock
			else
				cd archive/spotify-adblock && make && sudo make install && cd "$DOTFILES"
			fi

			success "Spotify is installed"
		} || {
			error "Failed to install Spotify"
		}
	fi
}

install_apt_pkg() {
	title "Installing terminal packages"

	for package in $APT_PACKAGES
	do
		{
			info "Installing $package"
			sudo apt install -y "$package"
			success  "$package is installed"
		} || {
			error "Failed to install $package"
		}
	done

	title "Installing todotxt"
	{
		local DIR="$HOME/.todo"
		local GIT_FOLDER="$DIR/git-folder"
		create_dir_if_not_exist "$DIR"
		create_dir_if_not_exist "$GIT_FOLDER"
		git clone --depth=1 git@github.com:todotxt/todo.txt-cli.git "$GIT_FOLDER"
		cd "$GIT_FOLDER" && make && sudo make install CONFIG_DIR=$DIR
		rm -rfv "$GIT_FOLDER"
		success "todotxt is installed"
	} || {
		error "Failed to install todotxt"
	}
}

install_laravel() {
	title "Installing Laravel"

	info "Installing PHP"
	{
		sudo apt install -y php php-common php-cli php-gd php-mysqlnd php-curl php-intl php-mbstring php-bcmath php-xml php-zip
		success "PHP is installed"
	} || {
		error "Failed to install PHP"
	}

	info "Installing Composer"
	{
		curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
		success "Composer is installed"
	} || {
		error "Failed to install Composer"
	}

	info "Installing MySQL"
	{
		sudo apt install -y mysql-server
		success "MySQL is installed"
	} || {
		error "Failed to install MySQL"
	}
}

clean_up() {
	title "Cleaning up"

	for package in $CLEAN_UP_APT_PACKAGES
	do
		info "Uninstalling $package"
		{
			sudo apt remove --purge -y "$package"
		} || {
			error "Failed to uninstall $package"
		}
	done

	sudo apt autoremove -y

	success "Cleaned up"
}

install() {
	local selected_pkg_mngrs=()
	local selected_programs=()
	local selected_installation=()

	# options to choose what to install
	local installation_setup_terminal="Setup terminal"
	local installation_github_ssh="Github SSH"
	local installation_create_symlinks="Create symlinks"
	local installation_install_fonts="Install fonts"
	local installation_install_apt_pkgs="Install apt packages"
	local installation_install_js_pkg_mng="Install Javascript package managers"
	local installation_install_gnome_exts="Install gnome extensions"
	local installation_install_programs="Install programs"
	local installation_install_laravel="Install Laravel"
	local installation_clean_up="Clean up"

	local installation=("$installation_setup_terminal" "$installation_github_ssh" "$installation_create_symlinks" "$installation_install_fonts" "$installation_install_apt_pkgs" "$installation_install_js_pkg_mng" "$installation_install_gnome_exts" "$installation_install_programs" "$installation_install_laravel" "$installation_clean_up")
	multiple_select "Choose what to install" "${installation[@]}"
	selected_installation="${selected[@]}"

	if value_in_array "$installation_install_js_pkg_mng" "${selected_installation[@]}"; then
		local pkg_mngrs=("npm" "yarn")
		multiple_select "Choose the package manager(s)" "${pkg_mngrs[@]}"
		selected_pkg_mngrs="${selected[@]}"
	fi

	if value_in_array "$installation_install_programs" "${selected_installation[@]}"; then
		local programs=("VS Code" "OBS Studio" "Postman" "Spotify")
		multiple_select "Choose the program(s)" "${programs[@]}"
		selected_programs="${selected[@]}"
	fi
	if value_in_array "Spotify" "${selected_programs[@]}"; then
		while true; do
			read -p "Please firstly install original spotify on https://www.spotify.com/us/download/linux in another tab, then enter [y/Y] to continue" input
			if [[ $input == [yY] ]]; then
				break
			fi
		done
	fi

	if [ ${#selected_installation[@]} -gt 0 ]; then
		title "Updating apt repository"
		sudo apt update
	fi

	if value_in_array "$installation_github_ssh" "${selected_installation[@]}"; then setup_github_ssh; fi
	if value_in_array "$installation_install_fonts" "${selected_installation[@]}"; then install_fonts; fi
	if value_in_array "$installation_install_apt_pkgs" "${selected_installation[@]}"; then install_apt_pkg; fi
	if value_in_array "$installation_install_js_pkg_mng" "${selected_installation[@]}"; then install_js_pkg_managers "${selected_pkg_mngrs[@]}"; fi
	if value_in_array "$installation_install_gnome_exts" "${selected_installation[@]}"; then install_gnome_extensions; fi
	if value_in_array "$installation_install_programs" "${selected_installation[@]}"; then install_programs "${selected_programs[@]}"; fi
	if value_in_array "$installation_setup_terminal" "${selected_installation[@]}"; then setup_terminal_profile; fi
	if value_in_array "$installation_install_laravel" "${selected_installation[@]}"; then install_laravel; fi
	if value_in_array "$installation_create_symlinks" "${selected_installation[@]}"; then create_symlinks; fi
	if value_in_array "$installation_clean_up" "${selected_installation[@]}"; then clean_up; fi
	if value_in_array "$installation_setup_terminal" "${selected_installation[@]}"; then chsh -s /usr/bin/zsh && zsh; fi
}

install
success "Done"
