# Advanced UFW Hybrid Manager (CLI & TUI Mode)

A powerful, interactive, and user-friendly network firewall management tool built completely in Bash Scripting. It acts as an advanced wrapper around Linux's UFW (Uncomplicated Firewall), bridging the gap between complex network commands and effortless administration through both Classic CLI and Modern TUI (Text User Interface) modes.

---

## Key Features

* **Hybrid Interface Modes:** Choose between an interactive dialog-based TUI/GUI mode or a classic CLI text console upon startup.
* **Smart Background Validation:** 
  * Automatically checks for sudo/root privileges.
  * Verifies if UFW is installed, with an auto-install option if missing.
  * Dynamically installs missing dependencies (like dialog) silently in the background.
* **Preset Services Menu:** One-click configuration for industry-standard production ports:
  * SSH (22), HTTP/HTTPS (80, 443), MySQL (3306), PostgreSQL (5432), FTP (21), Redis (6379), MongoDB (27017), and Custom Apps (8080).
* **Advanced Port & Range Management:** Support for single custom ports, specific IP whitelisting, and TCP/UDP port ranges (e.g., 6000:6007).
* **Smart Descending Deletion Logic:** 
  * The Ultimate Edge-Case Fix: When deleting multiple rules simultaneously (e.g., rules 6, 3, and 1), standard deletion shifts indices and causes errors. This script automatically sorts inputs in Descending Order (deleting 6 first, then 3, then 1) to ensure absolute safety and zero index corruption.
* **Quick Quit/Cancel (q):** Press q at any prompt to safely abort an operation and return to the main menu without throwing syntax errors.
* **Safety & Security Prompts:** Double-confirmation steps for high-risk actions like enabling the firewall (protecting remote SSH sessions) or performing a factory reset.

---

## Prerequisites

* A Linux distribution (Ubuntu, Debian, Linux Mint, etc.)
* sudo privileges
* Bash shell environment

---

## Installation & Quick Start

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/YOUR_USERNAME/ufw-manager-cli.git](https://github.com/YOUR_USERNAME/ufw-manager-cli.git)
   cd ufw-manager-cli
Make the script executable:

Bash
chmod +x ufw_manager.sh
Run the tool (Requires Root/Sudo):

Bash
sudo ./ufw_manager.sh
How to Use
When you launch the script, you will be greeted with a launcher menu:

Plaintext
===============================================
        UFW FIREWALL MANAGER LAUNCHER         
===============================================
Select Interface Mode:

  1) GUI Mode (Interactive Dialog Box Window)
  2) CLI Mode (Standard Text Console)

===============================================
Main Menu Options:
Check UFW Status: Displays verbose firewall rules, policies, and logging states.

Enable / Disable UFW: Toggles the firewall with safety checks for remote server connections.

Allow Preset Services: Fast-tracks secure configuration for popular databases and web servers.

Allow Custom Port: Opens any specific port or service (e.g., 8080 or 53/udp).

Allow Port Range: Binds firewall rules across a sequence of ports for TCP, UDP, or both.

Block (Deny) Port: Explicitly drops incoming traffic on targeted ports.

Allow Specific IP: Whitelists specific trusted IP addresses.

Delete Rule(s): Lists active numbered rules and performs batch-deletions safely using descending sorting.

Reset UFW: Clears all custom configurations and reverts to factory defaults (requires explicit confirmation).

Code Highlights & Architecture
Automatic Cleanup (trap): Temporary log and text files created during status checks or rule parses are automatically purged upon exit using bash traps (trap 'rm -f /tmp/ufw_*.txt' EXIT).

Error Handling & Fallbacks: If the terminal environment lacks support for interactive dialog boxes, the script automatically falls back to standard CLI mode to ensure uninterrupted usage.

Contributing
Contributions, bug reports, and feature requests are always welcome! Feel free to open an issue or submit a pull request.

License
This project is open-source and available under the MIT License.
