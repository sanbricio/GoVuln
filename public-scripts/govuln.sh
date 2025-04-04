#!/bin/bash

# Source colors.sh using the absolute path
source "$HOME/.local/bin/govuln/utils/colors.sh"

VULN_FILE="$(pwd)/vuln_report.txt"

# Check if the directory contains a go.mod file
if [[ ! -f "go.mod" ]]; then
    echo -e "${RED}No go.mod file found in the current directory. This is not a Go project.${NC}"
    exit 1
fi

# Function to check for vulnerabilities and process the report
check_vulnerabilities() {
    echo -e "${YELLOW}Checking for vulnerabilities...${NC}"

    if ! command -v govulncheck &>/dev/null; then
        echo -e "${RED}govulncheck is not installed. Installing...${NC}"
        go install golang.org/x/vuln/cmd/govulncheck@latest
    fi

    govulncheck ./... >"$VULN_FILE"

    # Check if the file contains "No vulnerabilities found."
    if grep -q "No vulnerabilities found." "$VULN_FILE"; then
        echo -e "${GREEN}No vulnerabilities found.${NC}"
        return
    fi

    echo -e "${YELLOW}Processing vulnerability report...${NC}"
    process_vulnerability_report
}

declare -A VULNERABILITIES

# Function to process the vulnerability report
process_vulnerability_report() {
    local vuln_name="" module="" found="" fixed="" description=""

    while IFS= read -r line; do
        if [[ "$line" =~ Vulnerability\ #[0-9]+:\ (GO-[0-9]+-[0-9]+) ]]; then
            vuln_name="${BOLD}${RED}${BASH_REMATCH[1]}${NC}"
        elif [[ "$line" =~ More\ info:\ (https://.*) ]]; then
            description="${CYAN}${BASH_REMATCH[1]}${NC}"
        elif [[ "$line" =~ Module:\ (.+) ]]; then
            module="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ Found\ in:\ (.+) ]]; then
            found="${YELLOW}${BASH_REMATCH[1]}${NC}"
        elif [[ "$line" =~ Fixed\ in:\ (.+) ]]; then
            fixed="${GREEN}${BASH_REMATCH[1]}${NC}"
            if [[ -n "$module" && -n "$vuln_name" ]]; then
                VULNERABILITIES["$module"]+="${BOLD}Vulnerability:${NC} $vuln_name\n  ${BOLD}Description:${NC} $description\n  ${BOLD}Current version:${NC} $found\n  ${BOLD}Fixed in:${NC} $fixed\n----------------------------\n"
            fi
            vuln_name="" module="" found="" fixed="" description=""
        fi
    done <"$VULN_FILE"

    echo -e "${BOLD}${RED}=========================================${NC}"
    echo -e "${BOLD}${RED}         Vulnerabilities Report          ${NC}"
    echo -e "${BOLD}${RED}=========================================${NC}"

    for MODULE in "${!VULNERABILITIES[@]}"; do
        echo -e "${BOLD}${BLUE}Module:${NC} $MODULE"
        echo -e "${VULNERABILITIES[$MODULE]}"
    done
}

# Function to update vulnerable modules
update_vulnerable_modules() {
    echo -e "${YELLOW}Updating vulnerable modules...${NC}"

    if [[ ${#VULNERABILITIES[@]} -eq 0 ]]; then
        echo -e "${GREEN}No vulnerable modules found.${NC}"
        return
    fi

    for MODULE in "${!VULNERABILITIES[@]}"; do
        echo -e "${BOLD}${BLUE}Module:${NC} $MODULE"
        echo -e "${VULNERABILITIES[$MODULE]}"
        echo -e "Updating ${BOLD}$MODULE${NC} to latest version..."
        go get -u "$MODULE@latest"
    done
}

# Function to check for outdated modules
check_updates() {
    echo -e "${YELLOW}Checking for modules updates...${NC}"
    go list -m -u all | awk '{if ($3 != "") print $1, "(Current: "$2", Available: "$3")"}' | while read -r line; do
        echo -e "${GREEN}$line${NC}"
    done
}

# Function to update all outdated modules
update_modules() {
    echo -e "${YELLOW}Checking for outdated modules...${NC}"
    go list -m -u all | awk '{if ($3 != "") print $1, $2, $3}' | while read -r pkg curr_ver new_ver; do
        echo -e "${GREEN}$pkg${NC} (Current: ${YELLOW}$curr_ver${NC}, Available: ${RED}$new_ver${NC})"
        go get -u $pkg
        echo -e "${GREEN}$pkg updated to $new_ver${NC}"
    done
}

# Argument handling
case "$1" in
    up)
        check_vulnerabilities
        update_vulnerable_modules
        ;;
    scan)
        check_vulnerabilities
        ;;
    fix)
        update_vulnerable_modules
        ;;
    list)
        check_updates
        ;;
    upgrade)
        update_modules
        ;;
    help | *)
        echo -e "${BOLD}${CYAN}Usage:${NC}"
        echo -e "  ${BOLD} govuln up${NC}      - Check for vulnerabilities and update vulnerable modules"
        echo -e "  ${BOLD} govuln scan${NC}    - Check for modules vulnerabilities"
        echo -e "  ${BOLD} govuln fix${NC}     - Update only vulnerable modules"
        echo -e "  ${BOLD} govuln list${NC}    - List available modules to update"
        echo -e "  ${BOLD} govuln upgrade${NC} - Update all available modules"
        echo -e "  ${BOLD} govuln help${NC}    - Show this help message"
        ;;
esac