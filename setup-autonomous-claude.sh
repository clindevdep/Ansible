#!/bin/bash
# Setup script for maximum Claude Code autonomy
# ⚠️  WARNING: This reduces security. Only use on development machines!

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config/autonomous-claude-backups/$(date +%Y%m%d-%H%M%S)"

echo "===================================="
echo "Claude Code Autonomy Setup Script"
echo "===================================="
echo ""
echo "⚠️  WARNING: This will modify system security settings!"
echo "This is intended for isolated development environments only."
echo ""
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Setup cancelled."
    exit 0
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"
echo "Backups will be stored in: $BACKUP_DIR"

# ============================================================================
# 1. GIT CONFIGURATION
# ============================================================================
echo ""
echo "📝 Configuring Git..."

# Backup existing git config
cp ~/.gitconfig "$BACKUP_DIR/gitconfig" 2>/dev/null || true

# Set default branch to main
git config --global init.defaultBranch main

# Disable GPG signing to avoid passphrase prompts
git config --global commit.gpgsign false
git config --global tag.gpgsign false

# Set user info if not already set
if [ -z "$(git config --global user.name)" ]; then
    read -p "Enter your Git name: " GIT_NAME
    git config --global user.name "$GIT_NAME"
fi

if [ -z "$(git config --global user.email)" ]; then
    read -p "Enter your Git email: " GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
fi

# Disable terminal prompts for git credentials
git config --global core.askPass ""
git config --global credential.helper 'cache --timeout=86400'

# Disable advice messages
git config --global advice.defaultBranchName false
git config --global advice.detachedHead false

echo "✅ Git configured"

# ============================================================================
# 2. SSH KEYS FOR GITHUB (No password prompts)
# ============================================================================
echo ""
echo "🔑 Setting up SSH keys..."

if [ ! -f ~/.ssh/id_ed25519 ]; then
    read -p "Generate SSH key for GitHub? (yes/no): " GEN_SSH
    if [ "$GEN_SSH" = "yes" ]; then
        ssh-keygen -t ed25519 -C "$(git config --global user.email)" -N "" -f ~/.ssh/id_ed25519
        echo "✅ SSH key generated at ~/.ssh/id_ed25519"

        # Start ssh-agent and add key
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519

        echo ""
        echo "📋 Your public key (copy this to GitHub):"
        cat ~/.ssh/id_ed25519.pub
        echo ""
        echo "Add it at: https://github.com/settings/ssh/new"
        read -p "Press Enter once you've added the key to GitHub..."

        # Test connection
        ssh -T git@github.com || true
    fi
else
    echo "✅ SSH key already exists"
fi

# Pre-accept known hosts
ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null || true
ssh-keyscan gitlab.com >> ~/.ssh/known_hosts 2>/dev/null || true

# Configure git to prefer SSH over HTTPS
git config --global url."git@github.com:".insteadOf "https://github.com/"

echo "✅ SSH configured"

# ============================================================================
# 3. PASSWORDLESS SUDO
# ============================================================================
echo ""
echo "🔓 Setting up passwordless sudo..."

SUDOERS_FILE="/etc/sudoers.d/10-$USER-nopasswd"
if [ ! -f "$SUDOERS_FILE" ]; then
    echo "This requires your password one last time:"
    echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee "$SUDOERS_FILE" > /dev/null
    sudo chmod 0440 "$SUDOERS_FILE"
    echo "✅ Passwordless sudo configured"
else
    echo "✅ Passwordless sudo already configured"
fi

# ============================================================================
# 4. DOCKER WITHOUT SUDO
# ============================================================================
echo ""
echo "🐳 Configuring Docker..."

if command -v docker &> /dev/null; then
    if ! groups $USER | grep -q docker; then
        sudo usermod -aG docker $USER
        echo "✅ Added $USER to docker group (logout/login required)"
    else
        echo "✅ Docker already configured"
    fi
else
    echo "⚠️  Docker not installed, skipping"
fi

# ============================================================================
# 5. NPM WITHOUT SUDO
# ============================================================================
echo ""
echo "📦 Configuring npm..."

if command -v npm &> /dev/null; then
    if [ ! -d ~/.npm-global ]; then
        mkdir -p ~/.npm-global
        npm config set prefix '~/.npm-global'
        echo "✅ npm configured for global packages without sudo"
    else
        echo "✅ npm already configured"
    fi
else
    echo "⚠️  npm not installed, skipping"
fi

# ============================================================================
# 6. SHELL CONFIGURATION (Bash)
# ============================================================================
echo ""
echo "🐚 Configuring shell..."

SHELL_CONFIG="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && SHELL_CONFIG="$HOME/.zshrc"

# Backup shell config
cp "$SHELL_CONFIG" "$BACKUP_DIR/$(basename $SHELL_CONFIG)"

# Add autonomous settings
cat >> "$SHELL_CONFIG" << 'EOF'

# ============================================
# Claude Code Autonomous Configuration
# ============================================

# Non-interactive frontend for package managers
export DEBIAN_FRONTEND=noninteractive

# Disable git terminal prompts
export GIT_TERMINAL_PROMPT=0

# Add npm global bin to PATH
export PATH=~/.npm-global/bin:$PATH

# Unlimited history for better context
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoredups:erasedups

# Terraform auto-approve (DANGEROUS - only for dev)
# export TF_CLI_ARGS_apply="-auto-approve"
# export TF_CLI_ARGS_destroy="-auto-approve"

# Auto-start ssh-agent
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null 2>&1
    ssh-add ~/.ssh/id_ed25519 2>/dev/null || true
fi

EOF

echo "✅ Shell configured"

# ============================================================================
# 7. ANSIBLE CONFIGURATION
# ============================================================================
echo ""
echo "⚙️  Configuring Ansible..."

ANSIBLE_CFG="$HOME/.ansible.cfg"
if [ -f ansible.cfg ]; then
    # Backup existing
    [ -f "$ANSIBLE_CFG" ] && cp "$ANSIBLE_CFG" "$BACKUP_DIR/ansible.cfg"

    cat > "$ANSIBLE_CFG" << 'EOF'
[defaults]
host_key_checking = False
retry_files_enabled = False
command_warnings = False
deprecation_warnings = False
stdout_callback = yaml
interpreter_python = auto_silent

[privilege_escalation]
become_ask_pass = False
EOF
    echo "✅ Ansible configured"
else
    echo "⚠️  Not in Ansible directory, skipping"
fi

# ============================================================================
# 8. GITHUB CLI AUTHENTICATION
# ============================================================================
echo ""
echo "🔐 GitHub CLI status..."

if command -v gh &> /dev/null; then
    if gh auth status &>/dev/null; then
        echo "✅ GitHub CLI authenticated"
    else
        echo "⚠️  GitHub CLI not authenticated"
        read -p "Authenticate now? (yes/no): " AUTH_GH
        if [ "$AUTH_GH" = "yes" ]; then
            gh auth login
        fi
    fi
else
    echo "⚠️  GitHub CLI not installed"
    read -p "Install GitHub CLI? (yes/no): " INSTALL_GH
    if [ "$INSTALL_GH" = "yes" ]; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update
        sudo apt install -y gh
        gh auth login
    fi
fi

# ============================================================================
# 9. SUMMARY
# ============================================================================
echo ""
echo "===================================="
echo "✅ Setup Complete!"
echo "===================================="
echo ""
echo "Configured:"
echo "  ✓ Git (SSH, no GPG, credentials cached)"
echo "  ✓ SSH keys for GitHub"
echo "  ✓ Passwordless sudo"
echo "  ✓ Docker without sudo (if installed)"
echo "  ✓ npm without sudo (if installed)"
echo "  ✓ Shell environment"
echo "  ✓ Ansible (if applicable)"
echo ""
echo "⚠️  IMPORTANT NEXT STEPS:"
echo "  1. Log out and log back in (or run: source $SHELL_CONFIG)"
echo "  2. Test: 'sudo whoami' (should not ask password)"
echo "  3. Test: 'ssh -T git@github.com' (should authenticate)"
echo ""
echo "Backups saved to: $BACKUP_DIR"
echo ""
echo "To revert changes, restore from backups or remove:"
echo "  - /etc/sudoers.d/10-$USER-nopasswd"
echo "  - ~/.gitconfig"
echo "  - Lines added to $SHELL_CONFIG"
echo ""
