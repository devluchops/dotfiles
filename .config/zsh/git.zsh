# =============================================================================
# GIT FUNCTIONS - Enhanced Git utilities and workflows
# =============================================================================

# Enhanced git configuration with validation
git_setconfig() {
    # Set default values
    local default_git_username="Contract DEVOPS"
    local default_git_email="contractdevops@optimum-vector.com"
    
    echo "🔧 Git Configuration Setup"
    echo "=========================="
    
    # Prompt for Git username
    echo -n "Enter your Git username [$default_git_username]: "
    read git_username
    git_username=${git_username:-$default_git_username}
    
    # Prompt for Git email
    echo -n "Enter your Git email [$default_git_email]: "
    read git_email
    git_email=${git_email:-$default_git_email}
    
    # Validate email format
    if [[ ! "$git_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        echo "⚠️  Warning: Email format might be invalid"
    fi
    
    # Set Git configuration (local to current repo)
    git config user.name "$git_username"
    git config user.email "$git_email"
    
    echo "✅ Git identity set successfully:"
    echo "   Name: $git_username"
    echo "   Email: $git_email"
    
    # Show current git config
    echo ""
    echo "📋 Current Git configuration:"
    git config --list | grep -E "^user\.(name|email)" | sed 's/^/   /'
}

# Enhanced git clone with automatic configuration
git_clone() {
    if [ "$#" -lt 1 ]; then
        echo "Usage: git_clone <repository_url> [directory_name]"
        echo "Example: git_clone https://github.com/user/repo.git my-project"
        return 1
    fi
    
    local repo_url="$1"
    local target_dir="$2"
    
    # If no directory specified, extract from URL
    if [[ -z "$target_dir" ]]; then
        target_dir=$(basename "$repo_url" .git)
    fi
    
    echo "🔄 Cloning repository..."
    echo "   Source: $repo_url"
    echo "   Target: $target_dir"
    
    # Clone the repository
    if git clone "$repo_url" "$target_dir"; then
        echo "✅ Repository cloned successfully"
        
        # Change to the new directory and configure
        cd "$target_dir" || return 1
        
        echo ""
        echo "🔧 Setting up Git configuration for this repository..."
        git_setconfig
        
        echo ""
        echo "📁 Repository ready at: $(pwd)"
    else
        echo "❌ Failed to clone repository"
        return 1
    fi
}

# Set Git profile for Luis Valencia
git_config_lva() {
    # Check if we're in a git repository
    if git rev-parse --git-dir >/dev/null 2>&1; then
        git config user.name "Luis Valencia"
        git config user.email "lvalencia1286@gmail.com"
        echo "✅ Switched Git profile to: Luis Valencia (lvalencia1286@gmail.com) [LOCAL]"
    else
        echo "📍 Not in a git repository. Setting global configuration..."
        git config --global user.name "Luis Valencia"
        git config --global user.email "lvalencia1286@gmail.com"
        echo "✅ Switched Git profile to: Luis Valencia (lvalencia1286@gmail.com) [GLOBAL]"
    fi
}

# Set Git profile for work
git_config_work() {
    # Check if we're in a git repository
    if git rev-parse --git-dir >/dev/null 2>&1; then
        git config user.name "Contract DEVOPS"
        git config user.email "contractdevops@optimum-vector.com"
        echo "✅ Switched Git profile to: Contract DEVOPS (work) [LOCAL]"
    else
        echo "📍 Not in a git repository. Setting global configuration..."
        git config --global user.name "Contract DEVOPS"
        git config --global user.email "contractdevops@optimum-vector.com"
        echo "✅ Switched Git profile to: Contract DEVOPS (work) [GLOBAL]"
    fi
}

# Show current Git configuration
git_whoami() {
    echo "👤 Current Git Identity:"
    echo "======================"
    
    local name=$(git config user.name 2>/dev/null)
    local email=$(git config user.email 2>/dev/null)
    local global_name=$(git config --global user.name 2>/dev/null)
    local global_email=$(git config --global user.email 2>/dev/null)
    
    if [[ -n "$name" && -n "$email" ]]; then
        echo "📍 Local (this repository):"
        echo "   Name: $name"
        echo "   Email: $email"
    fi
    
    if [[ -n "$global_name" && -n "$global_email" ]]; then
        echo "🌍 Global:"
        echo "   Name: $global_name"
        echo "   Email: $global_email"
    fi
    
    if [[ -z "$name" && -z "$email" && -z "$global_name" && -z "$global_email" ]]; then
        echo "❌ No Git identity configured"
        echo "💡 Run 'git_setconfig' to set up your identity"
    fi
}

# Git status with enhanced output
git_status_enhanced() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "❌ Not a git repository"
        return 1
    fi
    
    echo "📊 Git Repository Status"
    echo "======================"
    
    # Current branch
    local branch=$(git branch --show-current 2>/dev/null)
    echo "🌿 Branch: $branch"
    
    # Remote info
    local remote=$(git remote get-url origin 2>/dev/null)
    if [[ -n "$remote" ]]; then
        echo "🔗 Remote: $remote"
    fi
    
    echo ""
    git status --short --branch
    
    # Show unpushed commits if any
    local unpushed=$(git log @{u}..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$unpushed" -gt 0 ]]; then
        echo ""
        echo "📤 Unpushed commits: $unpushed"
    fi
}

# Create and switch to new branch
git_new_branch() {
    if [[ -z "$1" ]]; then
        echo "Usage: git_new_branch <branch_name>"
        return 1
    fi
    
    local branch_name="$1"
    
    echo "🌿 Creating new branch: $branch_name"
    git checkout -b "$branch_name"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Successfully created and switched to branch: $branch_name"
    else
        echo "❌ Failed to create branch: $branch_name"
    fi
}

# Quick commit with message
git_quick_commit() {
    if [[ -z "$1" ]]; then
        echo "Usage: git_quick_commit <commit_message>"
        return 1
    fi
    
    echo "📝 Quick commit process:"
    echo "1. Adding all changes..."
    git add .
    
    echo "2. Committing with message: $1"
    git commit -m "$1"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Commit successful"
        
        # Ask if user wants to push
        echo -n "Push to remote? (y/N): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            git push
        fi
    else
        echo "❌ Commit failed"
    fi
}

# Undo last commit (soft reset)
git_undo_commit() {
    echo "↩️  Undoing last commit (keeping changes)..."
    git reset --soft HEAD~1
    echo "✅ Last commit undone. Changes are still staged."
}

# Show git log with nice formatting
git_log_pretty() {
    git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit "${@}"
}

# Clean up merged branches
git_cleanup_branches() {
    echo "🧹 Cleaning up merged branches..."
    
    # Get current branch
    local current_branch=$(git branch --show-current)
    
    # Find merged branches (excluding main/master and current)
    local merged_branches=$(git branch --merged | grep -v -E "(main|master|\*|$current_branch)" | xargs -n 1)
    
    if [[ -n "$merged_branches" ]]; then
        echo "Found merged branches:"
        echo "$merged_branches" | sed 's/^/  - /'
        
        echo -n "Delete these branches? (y/N): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "$merged_branches" | xargs -n 1 git branch -d
            echo "✅ Merged branches deleted"
        else
            echo "❌ Branch cleanup cancelled"
        fi
    else
        echo "✅ No merged branches to clean up"
    fi
}
