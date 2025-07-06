#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

tools=(nmap git zsh curl wget jq htop go masscan x8 flinks libpcap-dev)

declare -A repos
declare -a go_tools

install_x8() {
    if command -v x8 >/dev/null; then
        echo -e "${GREEN}[✓] x8 is already installed${NC}"
        return 0
    fi
    
    echo -e "${GREEN}Installing x8...${NC}"
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

    echo -e "${GREEN}Installing FLinks...${NC}"
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

    echo -e "\nCloning GitHub repos to ~/bugbounty-tools:"
    mkdir -p "$HOME/bugbounty-tools"
    for dir in "${!repos[@]}"; do
        target="$HOME/bugbounty-tools/$dir"
        repo_path="${repos[$dir]}"
        repo_url="https://github.com/$repo_path.git"
        if [[ ! -d "$target" ]]; then
            echo -e "${GREEN}Cloning $repo_url...${NC}"
            git clone "$repo_url" "$target"
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
    SNIPPET='for file in ~/zsh-configs/*.zsh; do
    source "$file"
done
export PATH=$PATH:~/zsh-configs'

    GO_PATH_SNIPPET='export PATH=$PATH:~/go/bin'

    if grep -q "zsh-configs" "$ZSHRC"; then
        echo -e "${GREEN}Zsh config already exists in .zshrc${NC}"
    else
        echo -e "${GREEN}Adding zsh configs to .zshrc...${NC}"
        echo -e "\n# Load custom zsh configs\n$SNIPPET" >> "$ZSHRC"
    fi

    if grep -q "~/go/bin" "$ZSHRC"; then
        echo -e "${GREEN}Go path already exists in .zshrc${NC}"
    else
        echo -e "${GREEN}Adding Go path to .zshrc...${NC}"
        echo -e "\n# Add Go binary to PATH\n$GO_PATH_SNIPPET" >> "$ZSHRC"
    fi

    echo -e "${GREEN}Done. Please restart your terminal or run 'source ~/.zshrc'${NC}"
}


main_menu() {
    load_repos || return
    load_go_tools || return

    echo -e "\n${GREEN}Select an option:${NC}"
    echo "1. Check missing/installed tools and repos"
    echo "2. Install missing tools and clone repos"
    echo "3. Add ~/zsh-configs to Zsh config"
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
