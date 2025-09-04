# =============================================================================
# MAIN ZSHRC - Modular Zsh Configuration
# =============================================================================

# Define dotfiles directory
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Git/dotfiles}"

# Function to safely source files
source_if_exists() {
    [[ -f "$1" ]] && source "$1"
}

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="robbyrussell"

plugins=(git)

source $ZSH/oh-my-zsh.sh

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh" || true

# Load modular zsh configuration
source_if_exists "$HOME/.config/zsh/exports.zsh"
source_if_exists "$HOME/.config/zsh/functions.zsh"
source_if_exists "$HOME/.config/zsh/aliases.zsh"
source_if_exists "$HOME/.config/zsh/aws.zsh"
source_if_exists "$HOME/.config/zsh/git.zsh"
source_if_exists "$HOME/.config/zsh/completions.zsh"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
eval "$(gh copilot alias -- zsh)"
export PATH="/usr/local/opt/postgresql@16/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/luisvalencia/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/luisvalencia/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/luisvalencia/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/luisvalencia/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

alias activate_venv="source /Users/luisvalencia/.venv/bin/activate"

alias g="git"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$HOME/.pyenv/shims:$PATH"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
export PATH="$(brew --prefix readline)/bin:$(brew --prefix ncurses)/bin:$PATH"
export LDFLAGS="-L$(brew --prefix readline)/lib -L$(brew --prefix ncurses)/lib -L$(xcrun --show-sdk-path)/usr/lib"
export CPPFLAGS="-I$(brew --prefix readline)/include -I$(brew --prefix ncurses)/include -I$(xcrun --show-sdk-path)/usr/include"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/luisvalencia/miniconda/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/luisvalencia/miniconda/etc/profile.d/conda.sh" ]; then
        . "/Users/luisvalencia/miniconda/etc/profile.d/conda.sh"
    else
        export PATH="/Users/luisvalencia/miniconda/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


# opencode
export PATH=/Users/luisvalencia/.opencode/bin:$PATH
