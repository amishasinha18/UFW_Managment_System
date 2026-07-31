#!/bin/bash

# Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Cleanup temporary files on exit
trap 'rm -f /tmp/ufw_*.txt' EXIT

# Check 1: Root Privileges Check
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR] Please run this script with sudo privileges!${NC}"
  echo "Example: sudo ./ufw_manager.sh"
  exit 1
fi

# Check 2: UFW Installation Check & Auto-Install Option
if ! command -v ufw &> /dev/null; then
  echo -e "${YELLOW}[!] UFW is not installed on this system.${NC}"
  read -p "Do you want to install it now? (y/n): " install_choice
  if [[ "$install_choice" == "y" || "$install_choice" == "Y" ]]; then
    apt update && apt install ufw -y
    echo -e "${GREEN}[+] UFW installed successfully!${NC}"
  else
    echo -e "${RED}[-] UFW is required to run this tool. Exiting.${NC}"
    exit 1
  fi
fi

# Check 3: Dialog Installation Check for GUI mode (Silent Install)
if ! command -v dialog &> /dev/null; then
  echo -e "${CYAN}[*] Setting up dependencies for GUI mode (this will take a few seconds)...${NC}"
  apt-get update > /dev/null 2>&1
  apt-get install dialog -y > /dev/null 2>&1
fi

# ==============================================================================
# GUI MODE FUNCTION
# ==============================================================================
gui_mode() {
  while true; do
    CHOICE=$(dialog --clear --backtitle "Advanced UFW Manager GUI" \
      --title " MAIN MENU " \
      --cancel-label "Exit" \
      --menu "Choose a Firewall Operation:" 20 65 11 \
      1 "Check UFW Status (Verbose)" \
      2 "Enable UFW Firewall" \
      3 "Disable UFW Firewall" \
      4 "Allow Preset Services (Databases, Web, etc.)" \
      5 "Allow Custom Port / Service" \
      6 "Allow Port Range (TCP/UDP)" \
      7 "Block (Deny) Port / Service" \
      8 "Allow Specific IP Address" \
      9 "Delete Rule(s) (Auto-sorted Descending)" \
      10 "Reset UFW (Factory Reset)" \
      11 "Exit" 2>&1 >/dev/tty)
      
    # If user presses Cancel or ESC
    if [ $? -ne 0 ] || [ -z "$CHOICE" ] || [ "$CHOICE" -eq 11 ]; then
      clear
      echo -e "${GREEN}Exiting UFW Manager. Goodbye!${NC}\n"
      exit 0
    fi

    case $CHOICE in
      1)
        ufw status verbose > /tmp/ufw_status.txt
        dialog --title " UFW Status " --textbox /tmp/ufw_status.txt 20 70
        ;;
      2)
        dialog --title " Enable UFW " --yesno "WARNING: Make sure SSH (Port 22) is allowed if you are on a remote server!\n\nAre you sure you want to enable UFW?" 10 50
        if [ $? -eq 0 ]; then
          ufw --force enable > /tmp/ufw_enable.txt
          dialog --title " Success " --msgbox "UFW has been enabled." 8 40
        fi
        ;;
      3)
        dialog --title " Disable UFW " --yesno "Are you sure you want to disable the firewall?" 8 50
        if [ $? -eq 0 ]; then
          ufw disable > /tmp/ufw_disable.txt
          dialog --title " Success " --msgbox "UFW disabled successfully." 8 40
        fi
        ;;
      4)
        PRESET=$(dialog --clear --backtitle "Advanced UFW Manager GUI" \
          --title " PRESET SERVICES " \
          --cancel-label "Back" \
          --menu "Select a service to allow:" 20 65 9 \
          1 "Open SSH (Port 22)" \
          2 "Open Web Server (HTTP 80 & HTTPS 443)" \
          3 "Open MySQL Database (Port 3306)" \
          4 "Open PostgreSQL Database (Port 5432)" \
          5 "Open FTP (Port 21)" \
          6 "Open Redis Cache (Port 6379)" \
          7 "Open MongoDB (Port 27017)" \
          8 "Open Custom API / App (Port 8080)" \
          9 "Back to Main Menu" 2>&1 >/dev/tty)
        
        if [ $? -eq 0 ] && [ "$PRESET" != "9" ]; then
          case $PRESET in
            1) ufw allow ssh > /dev/null; MSG="SSH allowed!" ;;
            2) ufw allow http > /dev/null; ufw allow https > /dev/null; MSG="HTTP & HTTPS allowed!" ;;
            3) ufw allow 3306/tcp > /dev/null; MSG="MySQL port 3306 allowed!" ;;
            4) ufw allow 5432/tcp > /dev/null; MSG="PostgreSQL port 5432 allowed!" ;;
            5) ufw allow 21/tcp > /dev/null; MSG="FTP port 21 allowed!" ;;
            6) ufw allow 6379/tcp > /dev/null; MSG="Redis port 6379 allowed!" ;;
            7) ufw allow 27017/tcp > /dev/null; MSG="MongoDB port 27017 allowed!" ;;
            8) ufw allow 8080/tcp > /dev/null; MSG="Port 8080 allowed!" ;;
          esac
          dialog --title " Success " --msgbox "$MSG" 8 40
        fi
        ;;
      5)
        PORT=$(dialog --title " Allow Custom Port " --inputbox "Enter port number (e.g., 8080 or 53/udp):" 8 50 2>&1 >/dev/tty)
        if [ $? -eq 0 ] && [ -n "$PORT" ]; then
          ufw allow "$PORT" > /dev/null
          dialog --title " Success " --msgbox "Port $PORT allowed successfully!" 8 40
        fi
        ;;
      6)
        RANGE=$(dialog --title " Allow Port Range " --inputbox "Enter port range (e.g., 6000:6007):" 8 50 2>&1 >/dev/tty)
        if [ $? -eq 0 ] && [ -n "$RANGE" ]; then
          PROTO=$(dialog --title " Protocol " --menu "Select Protocol:" 12 40 3 \
            1 "TCP" 2 "UDP" 3 "Both TCP & UDP" 2>&1 >/dev/tty)
          if [ $? -eq 0 ]; then
            case $PROTO in
              1) ufw allow "$RANGE/tcp" > /dev/null; MSG="TCP Port range $RANGE allowed!" ;;
              2) ufw allow "$RANGE/udp" > /dev/null; MSG="UDP Port range $RANGE allowed!" ;;
              3) ufw allow "$RANGE/tcp" > /dev/null; ufw allow "$RANGE/udp" > /dev/null; MSG="Both TCP & UDP range $RANGE allowed!" ;;
            esac
            dialog --title " Success " --msgbox "$MSG" 8 45
          fi
        fi
        ;;
      7)
        PORT=$(dialog --title " Block Port " --inputbox "Enter port number to block:" 8 50 2>&1 >/dev/tty)
        if [ $? -eq 0 ] && [ -n "$PORT" ]; then
          ufw deny "$PORT" > /dev/null
          dialog --title " Success " --msgbox "Port $PORT blocked successfully!" 8 40
        fi
        ;;
      8)
        IP=$(dialog --title " Allow IP Address " --inputbox "Enter the IP address (e.g., 192.168.1.50):" 8 50 2>&1 >/dev/tty)
        if [ $? -eq 0 ] && [ -n "$IP" ]; then
          ufw allow from "$IP" > /dev/null
          dialog --title " Success " --msgbox "Traffic allowed from $IP!" 8 40
        fi
        ;;
      9)
        ufw status numbered > /tmp/ufw_rules.txt
        dialog --title " Current Rules " --textbox /tmp/ufw_rules.txt 20 70
        RULES=$(dialog --title " Delete Rules " --inputbox "Aap space dekar multiple rules de sakte hain (jaise: 6 3 1).\n\nEnter rule number(s) to delete:" 10 60 2>&1 >/dev/tty)
        if [ $? -eq 0 ] && [ -n "$RULES" ]; then
          rule_array=($RULES)
          sorted_rules=($(printf '%s\n' "${rule_array[@]}" | sort -nr))
          for rnum in "${sorted_rules[@]}"; do
            ufw --force delete "$rnum" >/dev/null 2>&1
          done
          dialog --title " Success " --msgbox "Deletion process completed successfully!" 8 45
        fi
        ;;
      10)
        dialog --title " Factory Reset UFW " --yesno "WARNING: This will delete ALL custom rules!\n\nAre you sure you want to reset UFW?" 10 50
        if [ $? -eq 0 ]; then
          ufw --force reset > /dev/null
          dialog --title " Success " --msgbox "UFW reset successfully." 8 40
        fi
        ;;
    esac
  done
}

# ==============================================================================
# CLI MODE FUNCTION
# ==============================================================================
cli_mode() {
  while true; do
    clear
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${YELLOW}       ADVANCED UFW CLI MANAGER TOOL           ${NC}"
    echo -e "${CYAN}===============================================${NC}"
    echo " 1. Check UFW Status (Verbose)"
    echo " 2. Enable UFW Firewall"
    echo " 3. Disable UFW Firewall"
    echo " 4. Allow Preset Services (Databases, Web, FTP, etc.)"
    echo " 5. Allow Custom Port / Service"
    echo " 6. Allow Port Range (TCP/UDP)"
    echo " 7. Block (Deny) Port / Service"
    echo " 8. Allow Specific IP Address"
    echo " 9. Delete Rule(s) (Auto-sorted Descending)"
    echo " 10. Reset UFW (Factory Reset)"
    echo " 11. Exit"
    echo -e "${CYAN}===============================================${NC}"
    
    read -p "Enter your choice [1-11]: " choice

    case $choice in
        1)
            echo -e "\n${YELLOW}--- UFW Status ---${NC}"
            ufw status verbose
            echo ""
            read -p "Press Enter to continue..."
            ;;
        2)
            echo -e "\n${YELLOW}--- Enabling UFW ---${NC}"
            echo -e "${RED}[WARNING] Make sure SSH (Port 22) is allowed if you are on a remote server!${NC}"
            read -p "Are you sure you want to enable UFW? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                ufw enable
            fi
            read -p "Press Enter to continue..."
            ;;
        3)
            echo -e "\n${YELLOW}--- Disabling UFW ---${NC}"
            read -p "Are you sure you want to disable the firewall? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                ufw disable
                echo -e "${GREEN}[+] UFW disabled successfully.${NC}"
            fi
            read -p "Press Enter to continue..."
            ;;
        4)
            echo -e "\n${YELLOW}--- Preset Services Menu ---${NC}"
            echo " 1. Open SSH (Port 22)"
            echo " 2. Open Web Server (HTTP: 80 & HTTPS: 443)"
            echo " 3. Open MySQL Database (Port 3306)"
            echo " 4. Open PostgreSQL Database (Port 5432)"
            echo " 5. Open FTP (Port 21)"
            echo " 6. Open Redis Cache (Port 6379)"
            echo " 7. Open MongoDB (Port 27017)"
            echo " 8. Open Custom API / App (Port 8080)"
            echo " 9. Back to Main Menu"
            read -p "Select preset [1-9] (or press 'q' to cancel): " preset_choice
            
            if [[ "$preset_choice" == "q" || "$preset_choice" == "Q" ]]; then
                continue
            fi
            
            case $preset_choice in
                1) ufw allow ssh; echo -e "${GREEN}[+] SSH allowed!${NC}" ;;
                2) ufw allow http; ufw allow https; echo -e "${GREEN}[+] HTTP & HTTPS allowed!${NC}" ;;
                3) ufw allow 3306/tcp; echo -e "${GREEN}[+] MySQL port 3306 allowed!${NC}" ;;
                4) ufw allow 5432/tcp; echo -e "${GREEN}[+] PostgreSQL port 5432 allowed!${NC}" ;;
                5) ufw allow 21/tcp; echo -e "${GREEN}[+] FTP port 21 allowed!${NC}" ;;
                6) ufw allow 6379/tcp; echo -e "${GREEN}[+] Redis port 6379 allowed!${NC}" ;;
                7) ufw allow 27017/tcp; echo -e "${GREEN}[+] MongoDB port 27017 allowed!${NC}" ;;
                8) ufw allow 8080/tcp; echo -e "${GREEN}[+] Port 8080 allowed!${NC}" ;;
                *) echo "Returning to main menu..." ;;
            esac
            read -p "Press Enter to continue..."
            ;;
        5)
            echo -e "\n${YELLOW}--- Allow Custom Port ---${NC}"
            read -p "Enter port number (e.g., 8080 or 53/udp) [Type 'q' to cancel]: " port
            
            if [[ "$port" == "q" || "$port" == "Q" ]]; then
                continue
            fi
            
            if [ -n "$port" ]; then
                ufw allow "$port"
                echo -e "${GREEN}[+] Port $port allowed successfully!${NC}"
            else
                echo -e "${RED}[-] Input cannot be empty!${NC}"
            fi
            read -p "Press Enter to continue..."
            ;;
        6)
            echo -e "\n${YELLOW}--- Allow Port Range (TCP/UDP) ---${NC}"
            read -p "Enter port range (e.g., 6000:6007) [Type 'q' to cancel]: " port_range
            
            if [[ "$port_range" == "q" || "$port_range" == "Q" ]]; then
                continue
            fi
            
            read -p "Select protocol - 1. TCP, 2. UDP, 3. Both (or 'q' to cancel): " proto_choice
            
            if [[ "$proto_choice" == "q" || "$proto_choice" == "Q" ]]; then
                continue
            fi
            
            if [ -n "$port_range" ]; then
                case $proto_choice in
                    1)
                        ufw allow "$port_range/tcp"
                        echo -e "${GREEN}[+] TCP Port range $port_range allowed successfully!${NC}"
                        ;;
                    2)
                        ufw allow "$port_range/udp"
                        echo -e "${GREEN}[+] UDP Port range $port_range allowed successfully!${NC}"
                        ;;
                    3)
                        ufw allow "$port_range/tcp"
                        ufw allow "$port_range/udp"
                        echo -e "${GREEN}[+] Both TCP & UDP Port range $port_range allowed successfully!${NC}"
                        ;;
                    *)
                        echo -e "${RED}[-] Invalid protocol choice!${NC}"
                        ;;
                esac
            else
                echo -e "${RED}[-] Port range cannot be empty!${NC}"
            fi
            read -p "Press Enter to continue..."
            ;;
        7)
            echo -e "\n${YELLOW}--- Block (Deny) Port ---${NC}"
            read -p "Enter port number to block [Type 'q' to cancel]: " port
            
            if [[ "$port" == "q" || "$port" == "Q" ]]; then
                continue
            fi
            
            if [ -n "$port" ]; then
                ufw deny "$port"
                echo -e "${GREEN}[+] Port $port blocked successfully!${NC}"
            else
                echo -e "${RED}[-] Input cannot be empty!${NC}"
            fi
            read -p "Press Enter to continue..."
            ;;
        8)
            echo -e "\n${YELLOW}--- Allow Specific IP Address ---${NC}"
            read -p "Enter the IP address (e.g., 192.168.1.50) [Type 'q' to cancel]: " ip_addr
            
            if [[ "$ip_addr" == "q" || "$ip_addr" == "Q" ]]; then
                continue
            fi
            
            if [ -n "$ip_addr" ]; then
                ufw allow from "$ip_addr"
                echo -e "${GREEN}[+] Traffic allowed from $ip_addr!${NC}"
            else
                echo -e "${RED}[-] Input cannot be empty!${NC}"
            fi
            read -p "Press Enter to continue..."
            ;;
        9)
            echo -e "\n${YELLOW}--- Current Rules List ---${NC}"
            ufw status numbered
            echo ""
            echo -e "${CYAN}Tip: Aap space dekar multiple rules de sakte hain (jaise: 6 3 1) [Type 'q' to cancel]${NC}"
            read -p "Enter rule number(s) to delete: " -a rule_nums
            
            if [[ "${rule_nums[0]}" == "q" || "${rule_nums[0]}" == "Q" ]]; then
                continue
            fi
            
            if [ ${#rule_nums[@]} -gt 0 ]; then
                sorted_rules=($(printf '%s\n' "${rule_nums[@]}" | sort -nr))
                for rnum in "${sorted_rules[@]}"; do
                    echo -e "${YELLOW}Deleting rule number: $rnum${NC}"
                    ufw --force delete "$rnum"
                done
                echo -e "${GREEN}[+] Deletion process completed successfully!${NC}"
            else
                echo -e "${RED}[-] Input cannot be empty!${NC}"
            fi
            read -p "Press Enter to continue..."
            ;;
        10)
            echo -e "\n${RED}--- Reset UFW to Default Settings ---${NC}"
            read -p "WARNING: This will delete ALL custom rules! Type 'yes' to confirm (or 'q' to cancel): " confirm_reset
            if [ "$confirm_reset" == "yes" ]; then
                ufw --force reset
                echo -e "${GREEN}[+] UFW reset successfully.${NC}"
            else
                echo -e "${YELLOW}[!] Reset cancelled.${NC}"
            fi
            read -p "Press Enter to continue..."
            ;;
        11)
            echo -e "\n${GREEN}Exiting UFW Manager. Goodbye!${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}[-] Invalid choice! Please select between 1-11.${NC}"
            sleep 2
            ;;
    esac
  done
}

# ==============================================================================
# ENTRY POINT: MODE SELECTION
# ==============================================================================
clear
echo -e "${CYAN}===============================================${NC}"
echo -e "${YELLOW}        UFW FIREWALL MANAGER LAUNCHER          ${NC}"
echo -e "${CYAN}===============================================${NC}"
echo -e "Select Interface Mode:\n"
echo "  1) GUI Mode (Interactive Dialog)"
echo "  2) CLI Mode (Standard Text Console)"
echo -e "\n${CYAN}===============================================${NC}"

read -p "Choice [1/2]: " mode_choice

if [ "$mode_choice" == "1" ]; then
    # Double check if dialog installed successfully, fallback to CLI if it failed
    if command -v dialog &> /dev/null; then
        gui_mode
    else
        echo -e "\n${RED}[!] Dialog could not be installed. Falling back to CLI mode...${NC}"
        sleep 2
        cli_mode
    fi
elif [ "$mode_choice" == "2" ]; then
    cli_mode
else
    echo -e "${RED}Invalid choice. Defaulting to CLI Mode.${NC}"
    sleep 1
    cli_mode
fi
