# =============================================================================
# CUSTOM COMPLETIONS - Enhanced tab completions for commands
# =============================================================================

# Docker completion enhancements
if command -v docker &> /dev/null; then
    # Custom docker completions for common workflows
    _docker_custom() {
        local cur=${COMP_WORDS[COMP_CWORD]}
        case ${COMP_WORDS[1]} in
            logs)
                COMPREPLY=($(compgen -W "$(docker ps --format '{{.Names}}')" -- $cur))
                ;;
            exec)
                COMPREPLY=($(compgen -W "$(docker ps --format '{{.Names}}')" -- $cur))
                ;;
        esac
    }
fi

# Git completion enhancements
if command -v git &> /dev/null; then
    # Custom git branch completion for common workflows
    _git_custom_branch() {
        local branches=$(git branch --format='%(refname:short)' 2>/dev/null)
        COMPREPLY=($(compgen -W "$branches" -- ${COMP_WORDS[COMP_CWORD]}))
    }
    
    # Alias completions for custom git functions
    complete -F _git_custom_branch git_new_branch 2>/dev/null || true
fi

# AWS CLI completion enhancements
if command -v aws &> /dev/null; then
    # Custom AWS profile completion
    _aws_profiles() {
        local profiles=$(aws configure list-profiles 2>/dev/null)
        COMPREPLY=($(compgen -W "$profiles" -- ${COMP_WORDS[COMP_CWORD]}))
    }
    
    # Complete custom AWS functions
    complete -F _aws_profiles aws_switch_profile 2>/dev/null || true
fi

# kubectl completion enhancements
if command -v kubectl &> /dev/null; then
    # Custom kubectl context completion
    _kubectl_contexts() {
        local contexts=$(kubectl config get-contexts -o name 2>/dev/null)
        COMPREPLY=($(compgen -W "$contexts" -- ${COMP_WORDS[COMP_CWORD]}))
    }
fi

# Terraform completion enhancements
if command -v terraform &> /dev/null; then
    # Custom terraform workspace completion
    _terraform_workspaces() {
        local workspaces=$(terraform workspace list 2>/dev/null | sed 's/^[* ] //')
        COMPREPLY=($(compgen -W "$workspaces" -- ${COMP_WORDS[COMP_CWORD]}))
    }
fi

# Custom completion for extract function
_extract_completion() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=($(compgen -f -X '!*.@(tar|tgz|tar.gz|tar.bz2|tbz2|zip|rar|7z|Z|tar.xz)' -- "$cur"))
}
complete -F _extract_completion extract 2>/dev/null || true

# Custom completion for project directories
_project_dirs() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local project_dirs=$(find "$PROJECTS_DIR" -maxdepth 2 -type d -name .git -exec dirname {} \; 2>/dev/null | sed "s|$PROJECTS_DIR/||")
    COMPREPLY=($(compgen -W "$project_dirs" -- "$cur"))
}

# Custom completion for note function
_note_completion() {
    if [[ ${#COMP_WORDS[@]} -eq 2 ]]; then
        COMPREPLY=($(compgen -W "list clear" -- ${COMP_WORDS[1]}))
    fi
}
complete -F _note_completion note 2>/dev/null || true
