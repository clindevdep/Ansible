# Ubuntu Quick Installation System

## Overview
Automated Ubuntu workstation setup using a single bootstrap script that installs Ansible, pulls configuration from GitHub, and applies dotfiles.

## Installation Flow

### Phase 1: Fresh Ubuntu Installation
- Install Ubuntu 25.10 (or target version)
- Complete basic OS setup (user creation, timezone, etc.)
- Ensure internet connectivity

### Phase 2: Bootstrap Script Execution
```bash
curl -fsSL https://raw.githubusercontent.com/clindevdep/Ansible/main/Fresh_Install.sh | bash
```

### Phase 3: Automated Setup
The Fresh_Install.sh script performs the following steps in order:

## Fresh_Install.sh Strategy

### Step 1: Pre-flight Checks
- Verify running on Ubuntu (check /etc/os-release)
- Verify internet connectivity (ping 8.8.8.8 or curl github.com)
- Check if running as regular user (not root)
- Verify sudo access without requiring the script to run as root

### Step 2: Install Ansible
```bash
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
```

Alternative for Ubuntu 25.10+:
```bash
sudo apt update
sudo apt install -y ansible
```

### Step 3: Pull Ansible Playbook from GitHub
```bash
cd /tmp
git clone https://github.com/clindevdep/Ansible.git
cd Ansible
```

### Step 4: Run Ansible Playbook
```bash
ansible-playbook workstation.yml --ask-become-pass
```

Considerations:
- Use `--ask-become-pass` to prompt for sudo password
- Add error handling if playbook fails
- Log output to file for debugging: `| tee ~/ansible-install.log`

### Step 5: Chezmoi Integration
Chezmoi is handled by the Ansible playbook (lines 271-299 in workstation.yml), but requires:
- Age encryption key must be manually placed at `~/.config/chezmoi/key.txt` BEFORE running the playbook
- Alternative: Modify script to prompt for key or fetch from secure location

### Step 6: Post-Installation
- Display success message
- Remind user to:
  - Restart terminal or source shell config
  - Log out/log in for shell changes to take effect
  - Verify npm global packages are in PATH

## Implementation Details

### Error Handling
```bash
set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failures
```

### Logging
- Log all output to `~/fresh-install-$(date +%Y%m%d-%H%M%S).log`
- Use tee to display and log simultaneously
- Color-coded output for different stages

### Idempotency
- Script should be safe to run multiple times
- Ansible playbook is already idempotent
- Check if Ansible already installed before installing
- Check if repo already cloned before cloning

### User Interaction Points
1. Initial confirmation: "This will install and configure your workstation. Continue? (y/n)"
2. Sudo password prompt (via Ansible)
3. Age key placement reminder (if not present)

## Fresh_Install.sh Structure

```bash
#!/bin/bash
# Fresh Ubuntu Installation Bootstrap Script

# Configuration
REPO_URL="https://github.com/clindevdep/Ansible.git"
WORK_DIR="/tmp/ansible-bootstrap-$$"
LOG_FILE="$HOME/fresh-install-$(date +%Y%m%d-%H%M%S).log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"; }

# Main sections
preflight_checks() { ... }
install_ansible() { ... }
clone_playbook() { ... }
run_playbook() { ... }
post_install() { ... }
```

## Security Considerations

### Trust on First Use
- Script pulled via curl from GitHub
- Verify SSL certificate (curl -fsSL)
- Consider adding SHA256 checksum verification

### Secrets Management
- Age key for Chezmoi encryption must be handled securely
- Options:
  1. Manual placement before running (current approach)
  2. Prompt user to paste key during script execution
  3. Fetch from password manager CLI (1Password, Bitwarden)
  4. Use environment variable (less secure)

### Sudo Access
- Script needs sudo for package installation
- Use `--ask-become-pass` instead of passwordless sudo
- Never store sudo password in script

## Dependency Chain

```
Fresh_Install.sh
├── System packages (git, curl, sudo)
├── Ansible
│   └── Python3 (usually pre-installed)
├── Ansible Playbook (workstation.yml)
│   ├── APT packages (build-essential, zsh, etc.)
│   ├── Third-party repos (Brave, NodeSource)
│   ├── Snap packages (chezmoi)
│   ├── NPM global packages (tldr, claude-code, etc.)
│   └── Oh My Zsh
└── Chezmoi
    ├── Age encryption key (manual prerequisite)
    └── Dotfiles repo (https://github.com/clindevdep/dotfiles.git)
```

## Edge Cases to Handle

### Network Issues
- GitHub down or unreachable
- APT repository failures
- NPM registry issues
- Timeout handling

### Permission Issues
- User not in sudoers
- Sudo password incorrect
- File permission conflicts

### Partial Installations
- Script interrupted mid-execution
- Ansible playbook fails halfway
- Package installation failures

### System State
- Already configured system
- Conflicting packages installed
- Different Ubuntu version than expected

## Testing Strategy

### Test Environments
1. Fresh Ubuntu 25.10 VM
2. Fresh Ubuntu 24.04 LTS VM (compatibility)
3. Partially configured system (idempotency)
4. System without internet (error handling)

### Test Scenarios
- [ ] Fresh install on new system
- [ ] Re-run on already configured system
- [ ] Run without sudo password known
- [ ] Run without Age key
- [ ] Interrupt and resume
- [ ] Network failure during package install

## Optimization Opportunities

### Parallel Installation
- Some packages can install in parallel
- Consider using `ansible-playbook --forks=N`

### Caching
- Cache APT packages for faster reinstall
- Cache npm packages
- Keep local copy of repos

### Minimal vs Full Install
- Add flag for minimal installation
- Add flag to skip GPU packages
- Add flag to skip optional tools

## Future Enhancements

### Interactive Mode
- Prompt for optional components
- Select which package groups to install
- Choose dotfiles repo

### Declarative Configuration
- YAML config file for customization
- Override default package lists
- Specify custom repos

### Rollback Capability
- Snapshot system state before changes
- Timeshift integration for easy rollback
- Backup existing dotfiles before Chezmoi

### Multi-Distribution Support
- Detect Ubuntu version automatically
- Support Debian, Pop!_OS, Linux Mint
- Different package managers (DNF for Fedora)

### Remote Execution
- SSH-based installation on remote machines
- Deploy to multiple workstations
- Cloud instance provisioning integration

## File Structure

```
Ansible/
├── Fresh_Install.sh          # Main bootstrap script
├── workstation.yml            # Ansible playbook
├── Ansible.md                 # This documentation
├── README.md                  # Project overview
└── autonomous-setup.md        # Autonomous setup docs (existing)
```

## Usage Example

```bash
# On fresh Ubuntu installation
wget https://raw.githubusercontent.com/clindevdep/Ansible/main/Fresh_Install.sh
chmod +x Fresh_Install.sh
./Fresh_Install.sh

# Or one-liner
curl -fsSL https://raw.githubusercontent.com/clindevdep/Ansible/main/Fresh_Install.sh | bash
```

## Success Criteria

After successful execution:
- [x] All APT packages installed
- [x] Brave browser installed and configured
- [x] Node.js 22.x installed
- [x] ZSH set as default shell
- [x] Oh My Zsh installed
- [x] Chezmoi initialized with dotfiles
- [x] NPM global packages available in PATH
- [x] User can immediately start working

## Maintenance

### When to Update
- Ubuntu version changes
- New tools added to workstation.yml
- Package repository URLs change
- Security vulnerabilities discovered

### Version Control
- Tag releases (v1.0, v1.1, etc.)
- Maintain changelog
- Test before pushing to main branch

---

**Created**: 2025-12-19
**Last Updated**: 2025-12-19
**Status**: Planning Phase
