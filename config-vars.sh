#!/bin/bash

# Detect the real location of the script and the repository
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source colors.sh using the absolute path relative to SCRIPT_DIR
source "$SCRIPT_DIR/utils/colors.sh"

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
