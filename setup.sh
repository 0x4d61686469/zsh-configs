#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

tools=(nmap git zsh curl wget jq htop go masscan)
go_tools=(
    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
    "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
    "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    "github.com/projectdiscovery/httpx/cmd/httpx@latest"
    "github.com/tomnomnom/unfurl@latest"
    "github.com/tomnomnom/anew@latest"
    "github.com/tomnomnom/waybackurls@latest"
    "github.com/1ndianl33t/src@latest"
)

declare -A repos=(
    ["X9"]="https://github.com/Sh1Yo/X9"
    ["BackupKiller"]="https://github.com/0xKayala/BackupKiller"
    ["robofinder"]="https://github.com/devanshbatham/robofinder"
    ["LinkFinder"]="https://github.com/GerbenJavado/LinkFinder"
    ["wayback_downloader"]="https://github.com/hisxo/wayback_downloader"
    ["param_extractor"]="https://github.com/devanshbatham/param-extractor"
    ["altdns"]="https://github.com/infosec-au/altdns"
)

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
    echo -e "\nChecking essential tools:"
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "${GREEN}[✓] $tool${NC}"
        else
            echo -e "${RED}[✗] $tool${NC}"
        fi
    done

    echo -e "\nChecking Go-based tools:"
    for tool in "${go_tools[@]}"; do
        binary=$(basename "${tool%%@*}")
        if command -v "$binary" &> /dev/null; then
            echo -e "${GREEN}[✓] $binary${NC}"
        else
            echo -e "${RED}[✗] $binary${NC}"
        fi
    done

    echo -e "\nChecking GitHub repos:"
    for dir in "${!repos[@]}"; do
        target="$HOME/bugbounty-tools/$dir"
        if [[ -d "$target" ]]; then
            echo -e "${GREEN}[✓] $dir repo exists${NC}"
        else
            echo -e "${RED}[✗] $dir repo missing${NC}"
        fi
    done
}

install_tools() {
    pkgmgr=$(detect_package_manager)
    if [[ $pkgmgr == "unknown" ]]; then
        echo -e "${RED}No supported package manager found!${NC}"
        return
    fi

    echo -e "\nInstalling common tools using $pkgmgr..."
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${GREEN}Installing $tool...${NC}"
            case $pkgmgr in
                apt) sudo apt update && sudo apt install -y "$tool" ;;
                pacman) sudo pacman -Sy --noconfirm "$tool" ;;
                dnf) sudo dnf install -y "$tool" ;;
                zypper) sudo zypper install -y "$tool" ;;
                brew) brew install "$tool" ;;
            esac
        fi
    done

    if ! command -v go &> /dev/null; then
        echo -e "${RED}Go not installed. Please install it manually.${NC}"
        return
    fi

    export GOPATH="$HOME/go"
    export PATH="$GOPATH/bin:$PATH"

    echo -e "\nInstalling Go-based tools:"
    for tool in "${go_tools[@]}"; do
        binary=$(basename "${tool%%@*}")
        if ! command -v "$binary" &> /dev/null; then
            echo -e "${GREEN}Installing $binary...${NC}"
            go install "$tool"
        else
            echo -e "${GREEN}[✓] $binary already installed${NC}"
        fi
    done

    echo -e "\nCloning GitHub repos into ~/bugbounty-tools:"
    mkdir -p ~/bugbounty-tools
    for dir in "${!repos[@]}"; do
        target="$HOME/bugbounty-tools/$dir"
        if [[ ! -d "$target" ]]; then
            echo -e "${GREEN}Cloning ${repos[$dir]}...${NC}"
            git clone "${repos[$dir]}" "$target"
        else
            echo -e "${GREEN}[✓] $dir already cloned${NC}"
        fi
    done
}

add_zsh_configs() {
    ZSHRC="$HOME/.zshrc"
    SNIPPET='for file in ~/zsh-configs/*.zsh; do
    source "$file"
done
export PATH=$PATH:~/zsh-configs'

    if grep -q "zsh-configs" "$ZSHRC"; then
        echo -e "${GREEN}Zsh config already exists in .zshrc${NC}"
    else
        echo -e "${GREEN}Adding zsh configs to .zshrc...${NC}"
        echo -e "\n# Load custom zsh configs\n$SNIPPET" >> "$ZSHRC"
        echo -e "${GREEN}Done. Please restart your terminal or source ~/.zshrc${NC}"
    fi
}

main_menu() {
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
