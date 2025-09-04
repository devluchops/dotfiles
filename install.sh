#!/bin/bash

# Dotfiles installation script
# Author: Luis Valencia

set -e

DOTFILES_DIR="$HOME/Git/dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    printf "${GREEN}[INFO]${NC} %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

log_step() {
    printf "${BLUE}[STEP]${NC} %s\n" "$1"
}

backup_existing() {
    local file="$1"
    local filepath="$HOME/$file"
    if [[ -f "$filepath" || -d "$filepath" ]]; then
        log_warn "Backing up existing $file to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        mv "$filepath" "$BACKUP_DIR/"
    fi
}

copy_file() {
    local source="$1"
    local target="$2"
    
    # Create target directory if it doesn't exist
    local target_dir=$(dirname "$target")
    mkdir -p "$target_dir"
    
    # Backup existing file if it exists
    if [[ -f "$target" ]]; then
        backup_existing "$(basename "$target")"
    fi
    
    log_info "Copying: $source -> $target"
    cp "$source" "$target"
}

copy_directory() {
    local source="$1"
    local target="$2"
    
    # Backup existing directory if it exists
    if [[ -d "$target" ]]; then
        backup_existing "$(basename "$target")"
    fi
    
    log_info "Copying directory: $source -> $target"
    cp -r "$source" "$target"
}

install_oh_my_zsh_plugins() {
    log_step "Installing Oh My Zsh plugins..."
    
    # Check if Oh My Zsh is installed
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_warn "Oh My Zsh not found. Please install it first:"
        echo "sh -c \"\$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
        return 1
    fi
    
    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    
    # Install zsh-autosuggestions
    if [[ ! -d "$custom_dir/zsh-autosuggestions" ]]; then
        log_info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_dir/zsh-autosuggestions"
    else
        log_info "zsh-autosuggestions already installed"
    fi
    
    # Install zsh-syntax-highlighting
    if [[ ! -d "$custom_dir/zsh-syntax-highlighting" ]]; then
        log_info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom_dir/zsh-syntax-highlighting"
    else
        log_info "zsh-syntax-highlighting already installed"
    fi
}

setup_environment_file() {
    log_step "Setting up environment file..."
    
    # Copy .env.local if it doesn't exist
    if [[ ! -f "$HOME/.env.local" && -f "$DOTFILES_DIR/.env.local" ]]; then
        log_info "Copying .env.local template to home directory"
        cp "$DOTFILES_DIR/.env.local" "$HOME/.env.local"
        log_warn "Please edit ~/.env.local with your actual tokens and secrets"
    elif [[ -f "$DOTFILES_DIR/.env.local" ]]; then
        log_info "Using existing .env.local from dotfiles directory"
    fi
}

check_dependencies() {
    log_step "Checking dependencies..."
    
    local missing_deps=()
    
    # Check for essential tools
    command -v git >/dev/null 2>&1 || missing_deps+=("git")
    command -v curl >/dev/null 2>&1 || missing_deps+=("curl")
    command -v python3 >/dev/null 2>&1 || missing_deps+=("python3")
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Please install them first"
        return 1
    fi
    
    log_info "All essential dependencies found"
}

recommend_tools() {
    log_step "Checking for recommended modern tools..."
    
    local recommended=()
    
    command -v bat >/dev/null 2>&1 || recommended+=("bat")
    command -v exa >/dev/null 2>&1 || recommended+=("exa") 
    command -v fd >/dev/null 2>&1 || recommended+=("fd")
    command -v rg >/dev/null 2>&1 || recommended+=("ripgrep")
    command -v fzf >/dev/null 2>&1 || recommended+=("fzf")
    command -v zoxide >/dev/null 2>&1 || recommended+=("zoxide")
    command -v starship >/dev/null 2>&1 || recommended+=("starship")
    
    if [[ ${#recommended[@]} -gt 0 ]]; then
        log_info "Consider installing these modern tools for enhanced experience:"
        printf '  %s\n' "${recommended[@]}"
        echo ""
        log_info "Install with: brew install ${recommended[*]}"
    else
        log_info "All recommended tools are installed!"
    fi
}

main() {
    echo "🚀 Luis Valencia's Dotfiles Installation"
    echo "========================================"
    echo ""
    
    # Check dependencies first
    check_dependencies || exit 1
    
    log_info "Installing dotfiles from $DOTFILES_DIR"
    
    # Check if dotfiles directory exists
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi
    
    cd "$DOTFILES_DIR"
    
    # Install Oh My Zsh plugins
    install_oh_my_zsh_plugins
    
    # Setup environment variables
    setup_environment_file
    
    # Create necessary directories
    log_step "Creating directory structure..."
    mkdir -p "$HOME/.config/zsh"
    mkdir -p "$HOME/.config/nvim"
    mkdir -p "$HOME/.config/tmux"
    mkdir -p "$HOME/.config/ghostty"
    mkdir -p "$HOME/.scripts/python"
    
    # Create symlinks for dotfiles
    log_step "Copying configuration files..."
    
    # Inform user about the configuration that will be installed
    echo ""
    log_info "This will install the improved modular zsh configuration with:"
    echo "  • Modular organization (aliases, functions, AWS/Git utilities)"
    echo "  • Enhanced completions and modern tool integrations"  
    echo "  • Environment variable management via .env.local"
    echo "  • Oh My Zsh with zsh-autosuggestions and zsh-syntax-highlighting"
    echo ""
    read -p "Continue with installation? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled by user"
        exit 0
    fi
    
    # Install the improved modular configuration
    copy_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    log_info "Installed improved modular zsh configuration"
    
    # Copy the zsh modules from .config/zsh to ~/.config/zsh
    if [[ -d "$DOTFILES_DIR/.config/zsh" ]]; then
        log_info "Copying zsh modules to ~/.config/zsh/"
        mkdir -p "$HOME/.config/zsh"
        # Copy individual files to avoid nested directory structure
        for file in "$DOTFILES_DIR/.config/zsh"/*; do
            if [[ -f "$file" ]]; then
                copy_file "$file" "$HOME/.config/zsh/$(basename "$file")"
            fi
        done
    fi
    
    # Copy .env.local to home directory if it doesn't exist there
    if [[ -f "$DOTFILES_DIR/.env.local" && ! -f "$HOME/.env.local" ]]; then
        copy_file "$DOTFILES_DIR/.env.local" "$HOME/.env.local"
        log_warn "Please edit ~/.env.local with your actual tokens and secrets"
    fi
    
    # Copy config directories if they exist
    if [[ -d "$DOTFILES_DIR/.config/nvim" ]]; then
        copy_directory "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"
    fi
    
    if [[ -d "$DOTFILES_DIR/.config/tmux" ]]; then
        copy_directory "$DOTFILES_DIR/.config/tmux" "$HOME/.config/tmux"
    fi
    
    if [[ -d "$DOTFILES_DIR/.config/ghostty" ]]; then
        copy_directory "$DOTFILES_DIR/.config/ghostty" "$HOME/.config/ghostty"
    fi
    
    # Copy scripts directory if it exists
    if [[ -d "$DOTFILES_DIR/.scripts" ]]; then
        copy_directory "$DOTFILES_DIR/.scripts" "$HOME/.scripts"
        log_info "Making Python scripts executable..."
        chmod +x "$HOME/.scripts/python"/*.py 2>/dev/null || true
    fi
    
    # Check for recommended tools
    recommend_tools
    
    echo ""
    log_info "✅ Dotfiles installation completed!"
    echo ""
    log_info "Next steps:"
    echo "  1. Restart your terminal or run: source ~/.zshrc"
    echo "  2. Edit ~/.env.local with your actual tokens (if needed)"
    echo "  3. Test your setup by running: git_whoami or myip"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        echo ""
        log_info "📁 Backup created at: $BACKUP_DIR"
    fi
    
    echo ""
    echo "🎉 Happy coding!"
}

main "$@"
