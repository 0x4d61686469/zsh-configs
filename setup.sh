#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

tools=(pipx nmap git zsh curl wget jq htop go masscan x8 flinks git-lfs bbot uro)

declare -A repos
declare -a go_tools

load_repos() {
    if [[ ! -f repos.txt ]]; then
        echo -e "${RED}repos.txt not found!${NC}"
        return 1
    fi
    repos=()
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        key=$(basename "$line")
        repos["$key"]="$line"
    done < repos.txt
}

load_go_tools() {
    if [[ ! -f go_tools.txt ]]; then
        echo -e "${RED}go_tools.txt not found!${NC}"
        return 1
    fi
    go_tools=()
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        go_tools+=("$line")
    done < go_tools.txt
}

detect_package_manager() {
    if command -v apt &> /dev/null; then echo "apt"
    elif command -v pacman &> /dev/null; then echo "pacman"
    elif command -v dnf &> /dev/null; then echo "dnf"
    elif command -v zypper &> /dev/null; then echo "zypper"
    elif command -v brew &> /dev/null; then echo "brew"
    else echo "unknown"
    fi
}

check_status() {
    echo -e "\nChecking system tools:"
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "${GREEN}[✓] $tool${NC}"
        else
            echo -e "${RED}[✗] $tool${NC}"
        fi
    done

    echo -e "\nChecking Go tools:"
    for tool in "${go_tools[@]}"; do
        # Split the line into binary name and package path
        binary=$(echo "$tool" | awk '{print $1}')
        package=$(echo "$tool" | awk '{print $2}')
        if command -v "$binary" &> /dev/null; then
            echo -e "${GREEN}[✓] $binary${NC}"
        else
            echo -e "${RED}[✗] $binary${NC}"
        fi
    done

    echo -e "\nChecking GitHub repos:"
    for dir in "${!repos[@]}"; do
        if [[ -d "$HOME/bugbounty-tools/$dir" ]]; then
            echo -e "${GREEN}[✓] $dir${NC}"
        else
            echo -e "${RED}[✗] $dir${NC}"
        fi
    done
}

install_x8() {
    if command -v x8 >/dev/null; then
        echo -e "${GREEN}[✓] x8 is already installed${NC}"
        return 0
    fi
    
    TMP_DIR=$(mktemp -d)
    echo -e "${GREEN}Downloading x8...${NC}"
    if curl -L -o "$TMP_DIR/x8.gz" https://github.com/Sh1Yo/x8/releases/download/v4.3.0/x86_64-linux-x8.gz; then
        echo -e "${GREEN}Extracting x8...${NC}"
        gunzip "$TMP_DIR/x8.gz" &&
        chmod +x "$TMP_DIR/x8" &&
        echo -e "${GREEN}Moving x8 to /usr/local/bin/...${NC}"
        sudo mv "$TMP_DIR/x8" /usr/local/bin/ &&
        rm -rf "$TMP_DIR" &&
        echo -e "${GREEN}✓ x8 installed successfully!${NC}"
    else
        echo -e "${RED}Failed to download x8${NC}"
        rm -rf "$TMP_DIR"
        return 1
    fi
}


install_flinks() {
    if command -v flinks >/dev/null; then
        echo -e "${GREEN}[✓] flinks is already installed${NC}"
        return 0
    fi

    local flinks_dir="$HOME/bugbounty-tools/FLinks"
    if [[ ! -d "$flinks_dir" ]]; then
        echo -e "${RED}FLinks directory not found. Please run option 2 first to clone the repository.${NC}"
        return 1
    fi

    cd "$flinks_dir" && {
        chmod +x install.sh
        ./install.sh
        cd - > /dev/null
        if command -v flinks >/dev/null; then
            echo -e "${GREEN}[✓] flinks installed successfully!${NC}"
        else
            echo -e "${RED}Failed to install flinks${NC}"
            return 1
        fi
    }
}

install_bbot() {
    if command -v bbot >/dev/null; then
        echo -e "${GREEN}[✓] bbot is already installed${NC}"
        return 0
    fi

    pipx install bbot
    if command -v bbot >/dev/null; then
        echo -e "${GREEN}[✓] bbot installed successfully!${NC}"
    else
        echo -e "${RED}Failed to install bbot${NC}"
        return 1
    fi
}

install_uro() {
    if command -v uro >/dev/null; then
        echo -e "${GREEN}[✓] uro is already installed${NC}"
        return 0
    fi

    pipx install uro
    if command -v uro >/dev/null; then
        echo -e "${GREEN}[✓] uro installed successfully!${NC}"
    else
        echo -e "${RED}Failed to install uro${NC}"
        return 1
    fi
}

install_tools() {
    pkgmgr=$(detect_package_manager)
    if [[ $pkgmgr == "unknown" ]]; then
        echo -e "${RED}No supported package manager found!${NC}"
        return 1
    fi

    echo -e "\nInstalling system tools using $pkgmgr..."
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${GREEN}Installing $tool...${NC}"
            case $tool in
                flinks)
                    install_flinks
                    ;;
                x8)
                    install_x8
                    ;;
                bbot)
                    install_bbot
                    ;;
                uro)
                    install_uro
                    ;;
                *)
                    case $pkgmgr in
                        apt) sudo apt update && sudo apt install -y "$tool" ;;
                        pacman) sudo pacman -Sy --noconfirm "$tool" ;;
                        dnf) sudo dnf install -y "$tool" ;;
                        zypper) sudo zypper install -y "$tool" ;;
                        brew) brew install "$tool" ;;
                    esac
                    ;;
            esac
        fi
    done

    echo -e "\nCloning GitHub repos to $HOME/bugbounty-tools:"
    mkdir -p "$HOME/bugbounty-tools"
    for dir in "${!repos[@]}"; do
        target="$HOME/bugbounty-tools/$dir"
        repo_path="${repos[$dir]}"
        repo_url="https://github.com/$repo_path.git"
        if [[ ! -d "$target" ]]; then
            echo -e "${GREEN}Cloning $repo_url...${NC}"
            gh repo clone "$repo_path" "$target"
        else
            echo -e "${GREEN}[✓] $dir already exists${NC}"
        fi
    done

    if ! command -v go &> /dev/null; then
        echo -e "${RED}Go is not installed. Please install it manually.${NC}"
        return 1
    fi

    export GOPATH="$HOME/go"
    export PATH="$GOPATH/bin:$PATH"

    echo -e "\nInstalling Go tools:"
    for tool in "${go_tools[@]}"; do
        # Split the line into binary name and package path
        binary=$(echo "$tool" | awk '{print $1}')
        package=$(echo "$tool" | awk '{print $2}')
        if ! command -v "$binary" &> /dev/null; then
            echo -e "${GREEN}Installing $binary...${NC}"
            go install "$package"
        else
            echo -e "${GREEN}[✓] $binary already installed${NC}"
        fi
    done
}

add_zsh_configs() {
    ZSHRC="$HOME/.zshrc"
    ROOT_ZSHRC="/root/.zshrc"
    USER_HOME="$HOME"

    add_if_missing() {
        local snippet="$1"
        local desc="$2"
        if grep -Fxq "$snippet" "$ZSHRC"; then
            echo -e "${GREEN}${desc} already exists in .zshrc${NC}"
        else
            echo -e "${GREEN}Adding ${desc} to .zshrc...${NC}"
            echo -e "\n# ${desc}\n$snippet" >> "$ZSHRC"
        fi
    }

add_if_missing_root() {
        local snippet="$1"
        local desc="$2"
        if sudo grep -Fxq "$snippet" "$ROOT_ZSHRC"; then
            echo -e "${GREEN}${desc} already exists in .zshrc${NC}"
        else
            echo -e "${GREEN}Adding ${desc} to .zshrc...${NC}"
            echo -e "\n# ${desc}\n$snippet" | sudo tee -a "$ROOT_ZSHRC"
        fi
    }

    add_if_missing 'for file in $HOME/zsh-configs/*.zsh; do
    source "$file"
done
export PATH=$PATH:$HOME/zsh-configs' "Load custom zsh configs"

    add_if_missing 'export PATH=$PATH:$HOME/go/bin' "Go path"
    add_if_missing 'export PATH=$PATH:$HOME/.local/bin' "pipx path"

    # root .zshrc
    add_if_missing_root "for file in $USER_HOME/zsh-configs/*.zsh; do
    source "\$file"
done
export PATH=\$PATH:$USER_HOME/zsh-configs" "Load custom zsh configs"

    add_if_missing_root "export PATH=\$PATH:$USER_HOME/go/bin" "Go path"
    add_if_missing_root "export PATH=\$PATH:$USER_HOME/.local/bin" "pipx path"

    echo -e "${GREEN}Done. Please restart your terminal'${NC}"
}



main_menu() {
    load_repos || return
    load_go_tools || return

    echo -e "\n${GREEN}Select an option:${NC}"
    echo "1. Check missing/installed tools and repos"
    echo "2. Install missing tools and clone repos"
    echo "3. Add $HOME/zsh-configs to Zsh config"
    echo "q. Quit"
    read -p "Enter choice: " choice

    case "$choice" in
        1) check_status ;;
        2) install_tools ;;
        3) add_zsh_configs ;;
        q|Q) echo "Exiting..." && exit 0 ;;
        *) echo -e "${RED}Invalid choice${NC}" && main_menu ;;
    esac
}

main_menu
