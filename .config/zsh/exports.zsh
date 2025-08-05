# =============================================================================
# ENVIRONMENT VARIABLES - System and application configuration
# =============================================================================

# Path configurations
export PATH=$PATH:/Users/luisvalencia/Library/Python/3.9/bin
export PATH=$PATH:/usr/local/bin
export PATH=$PATH:/opt/homebrew/bin
export PATH=$PATH:$HOME/.local/bin

# Editor preferences
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"

# Language and locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# History configuration
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE="$HOME/.zsh_history"
export HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Docker configuration
export DOCKER_HOST=unix://$HOME/.docker/run/docker.sock

# Development tools
export NODE_ENV="development"
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# Less configuration (better pager experience)
export LESS='-R -M -i -j5'
export LESSHISTFILE='-'

# FZF configuration (if installed)
if command -v fzf &> /dev/null; then
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Homebrew configuration (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ -d "/opt/homebrew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# Load local environment variables (create this file for secrets)
# This should contain sensitive tokens and API keys
if [[ -f "$HOME/.env.local" ]]; then
    source "$HOME/.env.local"
elif [[ -f "$DOTFILES_DIR/.env.local" ]]; then
    source "$DOTFILES_DIR/.env.local"
fi

# Common directories
export PROJECTS_DIR="$HOME/Git"
export DOTFILES_DIR="$HOME/Git/dotfiles"

# Terminal colors
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# GPG TTY (for Git signing)
export GPG_TTY=$(tty)

# =============================================================================
# DEVELOPMENT ENVIRONMENTS
# =============================================================================

# Node.js (NVM)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Python (Pyenv)
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# Android development
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$ANDROID_HOME/platform-tools"

# PostgreSQL
export PATH="/usr/local/opt/postgresql@16/bin:$PATH"

# Python build dependencies (macOS)
export PATH="$(brew --prefix readline)/bin:$(brew --prefix ncurses)/bin:$PATH"
export LDFLAGS="-L$(brew --prefix readline)/lib -L$(brew --prefix ncurses)/lib -L$(xcrun --show-sdk-path)/usr/lib"
export CPPFLAGS="-I$(brew --prefix readline)/include -I$(brew --prefix ncurses)/include -I$(xcrun --show-sdk-path)/usr/include"

# OpenCode CLI
export PATH="$HOME/.opencode/bin:$PATH"

# GitHub Copilot CLI
eval "$(gh copilot alias -- zsh)"

# Google Cloud SDK
if [ -f '/Users/luisvalencia/Downloads/google-cloud-sdk/path.zsh.inc' ]; then 
    source '/Users/luisvalencia/Downloads/google-cloud-sdk/path.zsh.inc'
fi

if [ -f '/Users/luisvalencia/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then 
    source '/Users/luisvalencia/Downloads/google-cloud-sdk/completion.zsh.inc'
fi

# Conda initialization
__conda_setup="$('/Users/luisvalencia/miniconda/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/luisvalencia/miniconda/etc/profile.d/conda.sh" ]; then
        source "/Users/luisvalencia/miniconda/etc/profile.d/conda.sh"
    else
        export PATH="/Users/luisvalencia/miniconda/bin:$PATH"
    fi
fi
unset __conda_setup
