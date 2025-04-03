#!/bin/bash

#Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

VULN_FILE="vuln_report.txt"

# Function to check for vulnerabilities and process the report
check_vulnerabilities() {
    echo -e "${YELLOW}Checking for vulnerabilities...${NC}"

    if ! command -v govulncheck &>/dev/null; then
        echo -e "${RED}govulncheck is not installed. Installing...${NC}"
        go install golang.org/x/vuln/cmd/govulncheck@latest
    fi

    # Run govulncheck and save output
    govulncheck ./... > "$VULN_FILE"

    if [[ ! -s "$VULN_FILE" ]]; then
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

    # Show report 
    echo -e "${BOLD}${RED}=========================================${NC}"
    echo -e "${BOLD}${RED}         Vulnerabilities Report          ${NC}"
    echo -e "${BOLD}${RED}=========================================${NC}"
    VULNERABILITIES_COUNT=0
    for MODULE in "${!VULNERABILITIES[@]}"; do
        echo -e "${BOLD}${BLUE}Module:${NC} $MODULE"
        echo -e "${VULNERABILITIES[$MODULE]}"
        ((VULNERABILITIES_COUNT++))
    done

    update_vulnerable_packages

# Function to update vulnerable packages
update_vulnerable_packages() {
    echo -e "${YELLOW}Updating only vulnerable packages...${NC}"

    if [[ ${#VULNERABILITIES[@]} -eq 0 ]]; then
        echo -e "${GREEN}No vulnerable packages found.${NC}"
        return
    fi

    for MODULE in "${!VULNERABILITIES[@]}"; do
        echo -e "${BOLD}${BLUE}Module:${NC} $MODULE"
        echo -e "${VULNERABILITIES[$MODULE]}"

        echo -e "${BOLD}Options to update:${NC}"
        echo -e "${BOLD}1) Update to the fixed version${NC}"
        echo -e "${BOLD}2) Update to the latest available version${NC}"
        echo -e "${BOLD}3) Skip this package${NC}"
        read -p "Select an option (1, 2, or 3): " update_option

        case $update_option in
        1)
            fixed_version=$(echo -e "${VULNERABILITIES[$MODULE]}" | grep "Fixed in:" | awk '{print $NF}' | sed 's/\x1b\[[0-9;]*m//g')
            if [[ -n "$fixed_version" ]]; then
                echo -e "Updating ${BOLD}$MODULE${NC} to fixed version ${GREEN}$fixed_version${NC}..."
                go get "$fixed_version"
            else
                echo -e "${RED}No fixed version found.${NC}"
            fi
            ;;

        2)
            echo -e "Updating ${BOLD}$MODULE${NC} to ${GREEN}latest version${NC}..."
            go get -u "$MODULE@latest"
            ;;

        3)
            echo -e "${YELLOW}Skipping package $MODULE...${NC}"
            continue
            ;;

        *)
            echo -e "${BOLD}${RED}Invalid option. Skipping package.${NC}"
            continue
            ;;
        esac
    done
}

# Check module updates
check_updates() {
    echo -e "${YELLOW}Verificando actualizaciones de paquetes...${NC}"
    go list -m -u all | awk '{if ($3 != "") print $1, "(Actual: "$2", Disponible: "$3")"}' | while read -r line; do
        echo -e "${GREEN}$line${NC}"
    done
}

# Update 
update_packages() {
    echo -e "${YELLOW}Buscando paquetes desactualizados...${NC}"
    go list -m -u all | awk '{if ($3 != "") print $1, $2, $3}' | while read -r pkg curr_ver new_ver; do
        echo -e "${GREEN}$pkg${NC} (Actual: ${YELLOW}$curr_ver${NC}, Disponible: ${RED}$new_ver${NC})"
        read -p "¿Quieres actualizar $pkg? (s/n): " response
        if [[ "$response" == "s" ]]; then
            go get -u $pkg
            echo -e "${GREEN}$pkg actualizado a $new_ver${NC}"
        fi
    done
}

# Menú de opciones
echo -e "${YELLOW}Selecciona una opción:${NC}"
echo -e "1) Buscar vulnerabilidades y actualizar"
echo -e "2) Verificar actualizaciones de paquetes"
echo -e "3) Actualizar paquetes uno a uno"
read -p "Opción: " option

case $option in
1) check_vulnerabilities ;;
2) check_updates ;;
3) update_packages ;;
*) echo -e "${RED}Opción no válida.${NC}" ;;
esac
