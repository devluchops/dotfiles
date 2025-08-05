# 🚀 DevLuchOps's Dotfiles

A modern, modular, and well-organized dotfiles setup for macOS with enhanced productivity features.

## ✨ Features

- **Modular Configuration**: Organized into separate files for easy maintenance
- **Enhanced Git Workflows**: Improved Git functions with better UX
- **AWS CLI Utilities**: Enhanced AWS SSO and profile management
- **Modern Terminal Tools**: Support for Starship, fzf, zoxide, and more
- **Comprehensive Aliases**: Time-saving shortcuts for common commands
- **Utility Functions**: Helpful functions for daily development tasks
- **Safe Installation**: Automatic backup of existing configurations

## 📁 Structure

```
dotfiles/
├── install.sh          # Simplified installation script
├── .zshrc              # Clean modular zsh configuration
├── .env.local          # Local environment variables (sensitive data)
├── .gitignore          # Git ignore file for sensitive data
└── .config/            # XDG-compliant configuration
    ├── zsh/            # Zsh configuration modules
    │   ├── aliases.zsh     # Modern aliases and shortcuts
    │   ├── functions.zsh   # Utility functions
    │   ├── exports.zsh     # Environment variables and PATH
    │   ├── aws.zsh         # Enhanced AWS CLI utilities
    │   ├── git.zsh         # Enhanced Git workflows
    │   └── completions.zsh # Custom tab completions
    ├── nvim/           # Neovim configuration
    ├── tmux/           # Tmux configuration
    └── ghostty/        # Ghostty terminal configuration
```

## 🚀 Quick Start

### 1. Installation

```bash
cd ~/Git/dotfiles
chmod +x install.sh
./install.sh
```

The installer will:

- ✅ Backup your existing configurations automatically
- ✅ Install Oh My Zsh plugins (zsh-autosuggestions, zsh-syntax-highlighting)
- ✅ Copy modular zsh configuration to ~/.config/zsh/
- ✅ Set up clean .zshrc with modular loading
- ✅ Create environment file for sensitive variables

The installation process is streamlined - just confirm when prompted.

## 🛠️ Enhanced Features

### Git Utilities

- `git_setconfig` - Interactive Git identity setup
- `git_clone <url>` - Clone and auto-configure repository
- `git_config_lva` - Switch to personal Git profile
- `git_config_work` - Switch to work Git profile
- `git_whoami` - Show current Git identity
- `git_status_enhanced` - Enhanced Git status with extras
- `git_new_branch <name>` - Create and switch to new branch
- `git_quick_commit <message>` - Add, commit, and optionally push
- `git_undo_commit` - Undo last commit (soft reset)
- `git_log_pretty` - Beautiful Git log format
- `git_cleanup_branches` - Clean up merged branches

### AWS Utilities

- `aws_sso` - Interactive AWS SSO login with better UX
- `aws_sts` - Show current AWS identity with validation
- `aws_switch_profile <profile>` - Switch AWS profiles
- `aws_clear` - Clear AWS credentials from environment
- `aws_regions` - List available AWS regions
- `aws_account_info` - Show detailed account information

### Utility Functions

- `mkcd <dir>` - Create directory and change into it
- `extract <file>` - Extract any archive format
- `psg <process>` - Find processes by name
- `killp <process>` - Kill processes by name
- `weather [city]` - Quick weather check
- `backup <file>` - Create timestamped backup
- `ff <pattern>` - Find files by name pattern
- `httpserver [port]` - Quick HTTP server (renamed from serve)
- `genpass [length]` - Generate random password
- `myip` - Get public IP address
- `localip` - Get local IP address
- `note [message]` - Quick note taking
- `calc <expression>` - Command line calculator

### Modern Aliases

- **Git**: `gs`, `ga`, `gc`, `gp`, `gl`, `gd`, etc.
- **Navigation**: `ll`, `la`, `..`, `...`, etc.
- **Docker**: `d`, `dc`, `dps`, `di`, etc.
- **Kubernetes**: `k`, `kgp`, `kgs`, etc.
- **Development**: `serve8000` (Python HTTP server), `jsonpp` (JSON pretty print)
- **Personal**: `g` (git shortcut), `activate_venv` (Python virtual env)

## 🔧 Recommended Tools

Install these modern CLI tools for the best experience:

```bash
# Package manager (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Modern CLI tools
brew install bat exa fd ripgrep fzf zoxide starship
brew install htop jq tree wget curl

# Oh My Zsh plugins (automatically installed by install.sh)
# No manual installation needed - the script handles this
```

## 📝 Customization

### Local Configurations

The configuration automatically loads:
- `~/.env.local` - for sensitive environment variables
- `~/.config/zsh/*.zsh` - modular zsh files

### Environment Variables

The `.env.local` file is included in the repository as a template:

```bash
# Example ~/.env.local
export GITHUB_TOKEN="your_token_here"
export OPENAI_API_KEY="your_key_here"
```

### Adding Custom Functions

Add your functions to the appropriate modular file:

- `~/.config/zsh/functions.zsh` - for utility functions
- `~/.config/zsh/aliases.zsh` - for command shortcuts  
- `~/.config/zsh/exports.zsh` - for environment variables

```bash
# Example: Add to ~/.config/zsh/functions.zsh
my_function() {
    echo "Hello from custom function!"
}
```

## 🔄 Updates

To update your dotfiles:

```bash
cd ~/Git/dotfiles
git pull origin main
# Copy updated modules
cp .config/zsh/* ~/.config/zsh/
source ~/.zshrc
```

## 🛡️ Backup & Recovery

Your original configurations are automatically backed up to:
`~/.dotfiles_backup_YYYYMMDD_HHMMSS/`

To restore:

```bash
# Find your backup
ls -la ~/.dotfiles_backup_*

# Restore (example)
cp ~/.dotfiles_backup_20250804_143022/.zshrc ~/.zshrc
```

## 🤝 Contributing

Feel free to suggest improvements or add new features:

1. Add functions to appropriate `.zsh` files in `~/.config/zsh/`
2. Update the repository files in `.config/zsh/`
3. Document new features in this README
4. Test thoroughly before committing

## 📄 License

This dotfiles configuration is open source and available under the MIT License.

---

**Happy coding! 🎉**
