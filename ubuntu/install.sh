#!/bin/bash

DOTFILES="$(pwd)"
FONT_USER_DIR="/usr/share/fonts"
TODOTXT_DIR="$HOME/.todo"
TODOTXT_GIT_FOLDER="$TODOTXT_DIR/git-folder"

APT_PACKAGES="git curl tree snapd vim zsh gnome-shell-extension-manager pipx ibus-unikey make cargo gpg apt-transport-https xsel wl-clipboard gpaste-2"
ZSH_PLUGINS="https://github.com/zsh-users/zsh-syntax-highlighting https://github.com/zsh-users/zsh-autosuggestions https://github.com/marlonrichert/zsh-autocomplete.git"
GNOME_EXTENSIONS="blur-my-shell@aunetx BingWallpaper@ineffable-gmail.com Vitals@CoreCoding.com Bluetooth-Battery-Meter@maniacx.github.com clipboard-history@alexsaveau.dev cloudflare-warp-toggle@khaled.is-a.dev"
CLEAN_UP_APT_PACKAGES="make cargo gpg apt-transport-https"

SYMLINKS_HOME="vimrc zsh/zshrc zsh/p10k.zsh gitconfig"

COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

error_counter=0

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

confirm_before_continuing() {
	while true; do
		read -p "$1 (Enter [y/Y] to continue): " input

		if [[ $input == [yY] ]]; then
			break
		fi
	done
}

install_fonts() {
	title "Installing fonts"

	{
		sudo find "$DOTFILES/fonts" -name "*.[ot]tf" -type f -exec cp -v {} "$FONT_USER_DIR/" \;

		if which fc-cache >/dev/null 2>&1 ;
		then
			fc-cache -fv "$FONT_USER_DIR"
			sudo source /etc/profile
		fi

		success "Fonts are installed"
	} || {
		error "Failed to install fonts"
		error_counter=$((error_counter+1))
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
		error_counter=$((error_counter+1))
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
		error_counter=$((error_counter+1))
	}
	cd $DOTFILES

	info "Installing Powerlevel10k"
	{
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/themes/powerlevel10k}
		success "Powerlevel10k is installed"
	} || {
		error "Failed to install Powerlevel10k"
		error_counter=$((error_counter+1))
	}

	info "Restoring dconf settings"
	{
		dconf load / < ${DOTFILES}/gnome-terminal/dconf-settings.ini
		success "User dconf is restored"
	} || {
		error "Failed to restore user dconf"
		error_counter=$((error_counter+1))
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
			error_counter=$((error_counter+1))
		}
	done

	{
		info "Creating symlink for todotxt config"
		rm -rfv ~/.todo
		create_dir_if_not_exist ~/.todo
		ln -svf "$DOTFILES/todotxtconfig" ~/.todo/config
		success "Symlink of todo config is created"
	} || {
		error "Failed to create symlink for todotxt config"
		error_counter=$((error_counter+1))
	}
}

install_cloudflare() {
	curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
	echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
	sudo apt-get update && sudo apt-get install cloudflare-warp
	warp-cli registration new
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
			error_counter=$((error_counter+1))
		}

		info "Installing NPM"
		{
			nvm install --lts
			success "Latest NPM version is installed"
		} || {
			error "Failed to install NPM"
			error_counter=$((error_counter+1))
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
			error_counter=$((error_counter+1))
		}
	fi
}

setup_github_ssh() {
	title "Generating Github SSH key"

	{
		ssh-keygen -t ed25519 -C "gvinhh@gmail.com"
		eval "$(ssh-agent -s)"
		ssh-add ~/.ssh/id_ed25519

		xsel --clipboard < ~/.ssh/id_ed25519.pub
		success "Gibhub SSH key has been copied to clipboard"
		confirm_before_continuing "Confirm the establishment of Github SSH"

		git remote set-url origin git@github.com:colpno/.dotfiles.git
	} || {
		error "Failed to generate Github SSH key"
		error_counter=$((error_counter+1))
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
				error_counter=$((error_counter+1))
			}
		done
	} || {
		error "Failed to install gnome-extensions-cli"
		error_counter=$((error_counter+1))
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
			error_counter=$((error_counter+1))
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
			error_counter=$((error_counter+1))
		}
	fi

	if [[ "${programs[@]}" =~ "Postman" ]]; then
		info "Installing Postman"

		{
			sudo snap install postman
			success "Postman is installed"
		} || {
			error "Failed to install Postman"
			error_counter=$((error_counter+1))
		}
	fi

	if [[ "${programs[@]}" =~ "Spotify" ]]; then
		info "Installing Spotify"

		{
			curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
			echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

			if [ $? -eq 0 ]; then
				sudo apt-get update && sudo apt-get install spotify-client

				if [ $? -eq 0 ]; then
					bash <(curl -sSL https://spotx-official.github.io/run.sh)
				fi
			fi

			success "Spotify is installed"
		} || {
			error "Failed to install Spotify"
			error_counter=$((error_counter+1))
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
			error_counter=$((error_counter+1))
		}
	done
}

install_todotxt() {
	title "Installing todotxt"

	{
		create_dir_if_not_exist "$TODOTXT_DIR"
		create_dir_if_not_exist "$TODOTXT_GIT_FOLDER"
		git clone --depth=1 git@github.com:todotxt/todo.txt-cli.git "$TODOTXT_GIT_FOLDER"
		cd "$TODOTXT_GIT_FOLDER" && make && sudo make install CONFIG_DIR=$TODOTXT_DIR
		rm -rfv "$TODOTXT_GIT_FOLDER"
		success "todotxt is installed"
	} || {
		error "Failed to install todotxt"
		error_counter=$((error_counter+1))
	}
}

install_php() {
	local apps=("$@")

	if [[ "${apps[@]}" =~ "PHP" ]];
	then
		info "Installing PHP"
		{
			sudo apt install -y php php-common php-cli php-gd php-mysqlnd php-curl php-intl php-mbstring php-bcmath php-xml php-zip
			success "PHP is installed"
		} || {
			error "Failed to install PHP"
			error_counter=$((error_counter+1))
		}
	fi

	if [[ "${apps[@]}" =~ "Composer" ]];
	then
		info "Installing Composer"
		{
			curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
			success "Composer is installed"
		} || {
			error "Failed to install Composer"
			error_counter=$((error_counter+1))
		}
	fi

	if [[ "${apps[@]}" =~ "MySQL" ]];
	then
		info "Installing MySQL"
		{
			sudo apt install -y mysql-server
			success "MySQL is installed"
		} || {
			error "Failed to install MySQL"
			error_counter=$((error_counter+1))
		}
	fi
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
			error_counter=$((error_counter+1))
		}
	done

	sudo apt autoremove -y

	success "Cleaned up"
}

install() {
	local selected_pkg_mngrs=()
	local selected_programs=()
	local selected_installation=()
	local selected_php_apps=()

	# options to choose what to install
	local installation_setup_terminal="Setup terminal"
	local installation_github_ssh="Github SSH"
	local installation_create_symlinks="Create symlinks"
	local installation_install_fonts="Install fonts"
	local installation_install_apt_pkgs="Install apt packages"
	local installation_install_js_pkg_mng="Install Javascript package managers"
	local installation_install_gnome_exts="Install gnome extensions"
	local installation_install_programs="Install programs"
	local installation_install_php="Install PHP"
	local installation_install_todotxt="Install Todo.txt"
	local installation_install_cloudflare="Install Cloudflare 1.1.1.1"
	local installation_clean_up="Clean up"

	local installation=("$installation_setup_terminal" "$installation_github_ssh" "$installation_create_symlinks" "$installation_install_fonts" "$installation_install_apt_pkgs" "$installation_install_js_pkg_mng" "$installation_install_todotxt" "$installation_install_gnome_exts" "$installation_install_programs" "$installation_install_php" "$installation_install_cloudflare" "$installation_clean_up")
	multiple_select "Choose what to install" "${installation[@]}"
	selected_installation="${selected[@]}"

	if value_in_array "$installation_install_js_pkg_mng" "${selected_installation[@]}"; then
		local pkg_mngrs=("npm" "yarn")
		multiple_select "Choose package manager(s)" "${pkg_mngrs[@]}"
		selected_pkg_mngrs="${selected[@]}"
	fi

	if value_in_array "$installation_install_js_pkg_mng" "${selected_installation[@]}"; then
		local phps=("PHP" "Composer" "MySQL")
		multiple_select "Choose php application(s)" "${phps[@]}"
		selected_php_apps="${selected[@]}"
	fi

	if value_in_array "$installation_install_programs" "${selected_installation[@]}"; then
		local programs=("VS Code" "OBS Studio" "Postman" "Spotify")
		multiple_select "Choose program(s)" "${programs[@]}"
		selected_programs="${selected[@]}"
	fi

	if [ ${#selected_installation[@]} -gt 0 ]; then
		title "Updating apt repository"
		sudo apt update
	fi

	if value_in_array "$installation_install_apt_pkgs" "${selected_installation[@]}"; then install_apt_pkg; fi
	if value_in_array "$installation_create_symlinks" "${selected_installation[@]}"; then create_symlinks; fi
	if value_in_array "$installation_github_ssh" "${selected_installation[@]}"; then setup_github_ssh; fi
	if value_in_array "$installation_install_fonts" "${selected_installation[@]}"; then install_fonts; fi
	if value_in_array "$installation_install_js_pkg_mng" "${selected_installation[@]}"; then install_js_pkg_managers "${selected_pkg_mngrs[@]}"; fi
	if value_in_array "$installation_install_todotxt" "${selected_installation[@]}"; then install_todotxt; fi
	if value_in_array "$installation_install_gnome_exts" "${selected_installation[@]}"; then install_gnome_extensions; fi
	if value_in_array "$installation_install_programs" "${selected_installation[@]}"; then install_programs "${selected_programs[@]}"; fi
	if value_in_array "$installation_setup_terminal" "${selected_installation[@]}"; then setup_terminal_profile; fi
	if value_in_array "$installation_install_php" "${selected_installation[@]}"; then install_php "${selected_php_apps[@]}"; fi
	if value_in_array "$installation_install_cloudflare" "${selected_installation[@]}"; then install_cloudflare; fi
	if value_in_array "$installation_clean_up" "${selected_installation[@]}"; then clean_up; fi

	info "The number of errors: $error_counter"
	if value_in_array "$installation_setup_terminal" "${selected_installation[@]}"; then chsh -s /usr/bin/zsh && zsh; fi
}

install
success "Done"
