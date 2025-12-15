# Claude Code Maximum Autonomy Configuration

This guide helps you configure your environment for maximum Claude Code autonomy with minimal interruptions.

## Quick Start

```bash
./setup-autonomous-claude.sh
```

## Claude Code Specific Settings

### 1. Launch with Dangerous Permissions Skip

Always launch Claude Code with the dangerous permissions flag:

```bash
claude --dangerously-skip-permissions
```

Or set as an alias:

```bash
echo 'alias claude="claude --dangerously-skip-permissions"' >> ~/.bashrc
source ~/.bashrc
```

### 2. Claude Code Configuration File

Check if Claude Code supports a config file (location may vary):

**~/.config/claude-code/config.json** or **~/.claude/settings.json**

```json
{
  "dangerously-skip-permissions": true,
  "auto-approve-tool-calls": true,
  "skip-confirmations": true,
  "verbose": false
}
```

### 3. Environment Variables for Claude Code

Add to your shell configuration:

```bash
# Claude Code specific
export CLAUDE_AUTO_APPROVE=true
export CLAUDE_SKIP_PERMISSIONS=true

# General development
export EDITOR=nano  # or vim, but nano is less interactive
export VISUAL=nano
export PAGER=cat    # Avoid 'less' pagination
```

## Autonomy Checklist

### System Configuration
- [x] **Passwordless sudo** - `/etc/sudoers.d/10-$USER-nopasswd`
- [x] **SSH keys** - `~/.ssh/id_ed25519` added to GitHub
- [x] **Git configured** - user.name, user.email set
- [x] **Git SSH preference** - HTTPS URLs rewritten to SSH
- [x] **Docker without sudo** - User in docker group
- [x] **npm without sudo** - `~/.npm-global` configured

### Git & GitHub
- [x] **gh CLI authenticated** - `gh auth status` succeeds
- [x] **SSH known hosts** - github.com, gitlab.com pre-accepted
- [x] **GPG signing disabled** - No passphrase prompts
- [x] **Credential caching** - 24-hour cache enabled
- [x] **Default branch 'main'** - `init.defaultBranch = main`

### Shell Configuration
- [x] **Non-interactive mode** - `DEBIAN_FRONTEND=noninteractive`
- [x] **Git prompt disabled** - `GIT_TERMINAL_PROMPT=0`
- [x] **ssh-agent auto-start** - Keys loaded automatically
- [x] **Unlimited history** - Full command context available

### Application-Specific
- [x] **Ansible** - `host_key_checking = False`
- [x] **Terraform** - Auto-approve flags (optional, dangerous)
- [x] **Package managers** - Auto-yes aliases (optional)

## Verification Tests

Run these commands to verify autonomous operation:

```bash
# Test 1: Sudo without password
sudo whoami
# Expected: root (no password prompt)

# Test 2: SSH to GitHub
ssh -T git@github.com
# Expected: "Hi username! You've successfully authenticated..."

# Test 3: Git operations
cd /tmp && git init test-repo && cd test-repo
git commit --allow-empty -m "test"
# Expected: No prompts for user.name or user.email

# Test 4: Docker without sudo (if installed)
docker ps
# Expected: Container list (no permission denied)

# Test 5: npm global install without sudo (if installed)
npm install -g cowsay
# Expected: Successful install without sudo
```

## Security Implications

⚠️ **CRITICAL WARNINGS:**

### High Risk
1. **Passwordless sudo** - Any process can execute root commands
2. **Dangerously-skip-permissions** - No file operation confirmations
3. **Auto-approve everything** - No human oversight

### Medium Risk
4. **SSH keys without passphrase** - Key theft = account access
5. **Credential caching** - Long-lived authentication tokens
6. **Docker group membership** - Equivalent to root access

### Mitigation Strategies

#### Option 1: Isolated Development VM
```bash
# Use a dedicated VM for Claude Code
# - VMware/VirtualBox/Parallels
# - Minimal network access
# - No production credentials
# - Snapshot before risky operations
```

#### Option 2: Docker Container Development
```bash
# Run all development in containers
docker run -it --rm \
  -v /home/clindevdep/AI:/workspace \
  -w /workspace \
  ubuntu:latest bash

# Claude Code operates inside container
# Host system remains protected
```

#### Option 3: Time-Limited Permissions
```bash
# Temporary passwordless sudo (expires on logout)
sudo bash -c 'echo "$USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/temp-$USER'
# ... work with Claude Code ...
sudo rm /etc/sudoers.d/temp-$USER
```

#### Option 4: Audit Logging
```bash
# Monitor all sudo commands
sudo apt-get install auditd
sudo auditctl -w /etc/sudoers -p wa
sudo auditctl -w /usr/bin/sudo -p x

# Review logs
sudo ausearch -k sudo
```

## Advanced: Tool-Specific Non-Interactive Configs

### Ansible
```ini
# ~/.ansible.cfg
[defaults]
host_key_checking = False
retry_files_enabled = False
gathering = explicit
timeout = 10
command_warnings = False

[privilege_escalation]
become_ask_pass = False
```

### Terraform
```bash
# Auto-approve (VERY DANGEROUS)
export TF_CLI_ARGS_apply="-auto-approve -input=false"
export TF_CLI_ARGS_destroy="-auto-approve -input=false"
export TF_IN_AUTOMATION=true
```

### Kubernetes
```bash
# Skip confirmation prompts
alias kubectl='kubectl --force'
export KUBECTL_APPLYSET=true
```

### Package Managers
```bash
# Debian/Ubuntu
export DEBIAN_FRONTEND=noninteractive
alias apt-get='apt-get -y -qq'
alias apt='apt -y -qq'

# Python pip
alias pip='pip --quiet --no-input'
export PIP_NO_INPUT=1

# Node npm
export npm_config_yes=true
alias npm='npm --yes'

# Ruby gems
alias gem='gem --no-document --no-user-install'
```

## Troubleshooting

### Claude Code Still Asks for Confirmation

1. **Check launch flags**: Ensure `--dangerously-skip-permissions` is used
2. **Check hooks**: Git hooks might be prompting (disable with `core.hooksPath`)
3. **Check env vars**: Some tools check environment for automation mode

### SSH Key Not Working

```bash
# Debug SSH connection
ssh -vT git@github.com

# Common fixes
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
ssh-add ~/.ssh/id_ed25519

# Ensure ssh-agent is running
eval "$(ssh-agent -s)"
```

### Sudo Still Asks for Password

```bash
# Verify sudoers file
sudo visudo -c

# Check your specific file
sudo cat /etc/sudoers.d/10-$USER-nopasswd

# Permissions must be 0440
sudo chmod 0440 /etc/sudoers.d/10-$USER-nopasswd

# Test without sudo cache
sudo -k && sudo whoami
```

### Git Credential Prompts

```bash
# Verify SSH is being used
git config --global --get url."git@github.com:".insteadof

# Convert existing repo to SSH
git remote set-url origin git@github.com:username/repo.git

# Disable all credential prompts
git config --global core.askPass ""
export GIT_TERMINAL_PROMPT=0
```

## Backup and Restore

### Create Backup
```bash
mkdir -p ~/backups/pre-autonomous-claude
cp ~/.gitconfig ~/backups/pre-autonomous-claude/
cp ~/.bashrc ~/backups/pre-autonomous-claude/
cp ~/.ssh/config ~/backups/pre-autonomous-claude/ 2>/dev/null || true
sudo cp /etc/sudoers.d/10-$USER-nopasswd ~/backups/pre-autonomous-claude/ 2>/dev/null || true
```

### Restore Backup
```bash
cp ~/backups/pre-autonomous-claude/.gitconfig ~/
cp ~/backups/pre-autonomous-claude/.bashrc ~/
sudo rm /etc/sudoers.d/10-$USER-nopasswd
```

## Best Practices

1. **Use a dedicated development machine** - Not your primary workstation
2. **Never use in production** - These settings are for development only
3. **Regular security audits** - Review command history and file changes
4. **Version control everything** - Commit frequently to catch unwanted changes
5. **Snapshot before major operations** - VM snapshots or git commits
6. **Review Claude's actions** - Don't blindly trust autonomous operations
7. **Limit network access** - Firewall rules for development VM
8. **Rotate credentials regularly** - Even in dev environments

## Further Optimization

### Preload Common Tools
```bash
# Install everything you might need
sudo apt-get update && sudo apt-get install -y \
  build-essential git gh curl wget \
  python3 python3-pip python3-venv \
  nodejs npm \
  docker.io docker-compose \
  ansible terraform kubectl helm \
  jq yq htop tmux vim
```

### Faster Package Operations
```bash
# Parallel downloads (apt)
echo 'Acquire::Queue-Mode "access";' | sudo tee /etc/apt/apt.conf.d/99parallel
echo 'APT::Acquire::Max-Jobs "10";' | sudo tee -a /etc/apt/apt.conf.d/99parallel

# Parallel downloads (pip)
echo '[global]' > ~/.pip/pip.conf
echo 'timeout = 10' >> ~/.pip/pip.conf
echo 'retries = 2' >> ~/.pip/pip.conf
```

### Shell Performance
```bash
# Faster bash startup
# Remove heavy items from .bashrc like NVM, RVM if not needed

# Use bash-completion only when interactive
if [ -n "$PS1" ]; then
    [ -f /etc/bash_completion ] && . /etc/bash_completion
fi
```

## Success Indicators

When properly configured, Claude Code should:

✅ Execute file operations without asking permission
✅ Run sudo commands without password prompts
✅ Push to GitHub without password/token prompts
✅ Install packages without confirmation
✅ Create commits without user.name/email prompts
✅ Execute Docker commands without sudo
✅ Complete todo lists without interruption
✅ Handle errors gracefully and continue

---

**Remember**: Autonomous operation means less oversight. Review changes frequently!
