#!/bin/bash

# Function to install or update govuln
install_or_update_govuln() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    INSTALL_DIR="$HOME/.local/bin"
    GOVULN="govuln"
    SCRIPT_SOURCE="$SCRIPT_DIR/public-scripts/govuln.sh"
    SCRIPT_DEST="$INSTALL_DIR/govuln/public-scripts/govuln.sh"
    COLORS_SOURCE="$SCRIPT_DIR/utils/colors.sh"
    COLORS_DEST="$INSTALL_DIR/govuln/utils/colors.sh"

    # Create necessary directories
    mkdir -p "$INSTALL_DIR/govuln/public-scripts"
    mkdir -p "$INSTALL_DIR/govuln/utils"

    # Check if the script is already installed and compare
    if [[ -f "$SCRIPT_DEST" ]]; then
        if [[ "$SCRIPT_SOURCE" -nt "$SCRIPT_DEST" ]]; then
            echo -e "${YELLOW}🔄 Updating $GOVULN...${NC}"
            cp "$SCRIPT_SOURCE" "$SCRIPT_DEST"
            cp "$COLORS_SOURCE" "$COLORS_DEST"
            chmod +x "$SCRIPT_DEST"
            chmod +x "$COLORS_DEST"
            echo -e "${GREEN}✅ $GOVULN updated in $INSTALL_DIR${NC}"
            
            # Only update PATH if the script was updated
            if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
                export PATH="$INSTALL_DIR:$PATH"
                echo -e "${CYAN}🔄 PATH updated. Restart your terminal or run 'source ~/.bashrc'${NC}"
            fi
        else
            echo -e "${GREEN}✅ $GOVULN is already up to date.${NC}"
        fi
    else
        cp "$SCRIPT_SOURCE" "$SCRIPT_DEST"
        cp "$COLORS_SOURCE" "$COLORS_DEST"
        chmod +x "$SCRIPT_DEST"
        chmod +x "$COLORS_DEST"
        echo -e "${GREEN}✅ $GOVULN installed in $INSTALL_DIR${NC}"
        
        # Ensure $INSTALL_DIR is in the PATH after installation
        if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
            export PATH="$INSTALL_DIR:$PATH"
            echo -e "${CYAN}🔄 PATH updated. Restart your terminal or run 'source ~/.bashrc'${NC}"
        else
            echo -e "${GREEN}✅ $GOVULN is available in the PATH.${NC}"
        fi
    fi
}

# Main logic
if [ $# -eq 0 ]; then
    export DEV_ENV_CONFIG_REPO_ROOT=$PWD
    export PATH="$PATH:$DEV_ENV_CONFIG_REPO_ROOT/public-scripts"

    if [ -f ~/.bashrc ]; then
        sed -i "/DEV_ENV_CONFIG_REPO_ROOT/d" ~/.bashrc
        echo "export DEV_ENV_CONFIG_REPO_ROOT=$PWD" >> ~/.bashrc
        echo 'export PATH="$PATH:$DEV_ENV_CONFIG_REPO_ROOT/public-scripts"' >> ~/.bashrc
    fi

    echo -e "\nEnvironment variables created successfully"
    echo -e "DEV_ENV_CONFIG_REPO_ROOT set to $PWD\n"

    # Option to install or update govuln
    install_or_update_govuln

elif [ $# -eq 1 ] && [ -f ~/.bashrc ] && [[ $1 == "--delete" ]]; then
    sed -i "/DEV_ENV_CONFIG_REPO_ROOT/d" ~/.bashrc
    echo -e "\nEnvironment variables deleted successfully\n"
else
    echo "USAGE: $0 [--delete]"
fi
