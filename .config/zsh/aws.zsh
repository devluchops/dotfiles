# =============================================================================
# AWS FUNCTIONS - Enhanced AWS CLI utilities
# =============================================================================

# List all AWS profiles
aws_list_profiles() {
    echo "Available AWS profiles:"
    aws configure list-profiles | sed 's/^/  - /'
}

# Enhanced AWS SSO login with better error handling
aws_sso() {
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI is not installed. Please install it first."
        return 1
    fi

    # Get the AWS profiles
    local profiles=($(aws configure list-profiles 2>/dev/null))
    
    # Check if there are any profiles
    if [ ${#profiles[@]} -eq 0 ]; then
        echo "❌ No AWS profiles found. Please configure AWS CLI profiles first."
        echo "💡 Run: aws configure sso"
        return 1
    fi

    # Add a "Quit" option to the profiles
    profiles+=("Quit")

    echo "🔐 AWS SSO Login"
    echo "==============="
    
    # Display the menu
    PS3="Select an AWS profile (or Quit to exit): "
    select profile in "${profiles[@]}"; do
        case $profile in
            "Quit")
                echo "👋 Exiting AWS SSO login"
                break
                ;;
            "")
                echo "❌ Invalid selection. Please try again."
                ;;
            *)
                echo "🔄 Logging into AWS profile: $profile"
                
                # Attempt SSO login
                if aws sso login --profile "$profile" 2>/dev/null; then
                    echo "✅ Successfully logged into profile: $profile"
                    
                    # Export credentials
                    if eval "$(aws configure export-credentials --profile $profile --format env 2>/dev/null)"; then
                        echo "✅ Credentials exported to environment"
                    else
                        echo "⚠️  Warning: Could not export credentials to environment"
                    fi
                    
                    # Show caller identity
                    aws_sts
                else
                    echo "❌ Failed to login to profile: $profile"
                fi
                break
                ;;
        esac
    done
}

# Get current AWS identity with enhanced output
aws_sts() {
    echo "🔍 Current AWS Identity:"
    echo "======================="
    
    if aws sts get-caller-identity 2>/dev/null; then
        echo ""
        echo "✅ AWS credentials are valid"
        
        # Show current profile if set
        if [[ -n "$AWS_PROFILE" ]]; then
            echo "📊 Active profile: $AWS_PROFILE"
        fi
        
        # Show region if set
        local region=$(aws configure get region 2>/dev/null)
        if [[ -n "$region" ]]; then
            echo "🌍 Region: $region"
        fi
    else
        echo "❌ No valid AWS credentials found"
        echo "💡 Run 'aws_sso' to login"
        return 1
    fi
}

# Switch AWS profile
aws_switch_profile() {
    if [[ -z "$1" ]]; then
        echo "Usage: aws_switch_profile <profile_name>"
        echo "Available profiles:"
        aws_list_profiles
        return 1
    fi
    
    local profile="$1"
    
    # Check if profile exists
    if ! aws configure list-profiles | grep -q "^$profile$"; then
        echo "❌ Profile '$profile' not found"
        aws_list_profiles
        return 1
    fi
    
    # Set the profile
    export AWS_PROFILE="$profile"
    echo "✅ Switched to AWS profile: $profile"
    
    # Show current identity
    aws_sts
}

# Clear AWS credentials
aws_clear() {
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    unset AWS_PROFILE
    echo "✅ AWS credentials cleared from environment"
}

# List AWS regions
aws_regions() {
    echo "🌍 Available AWS regions:"
    aws ec2 describe-regions --query 'Regions[*].RegionName' --output table 2>/dev/null || {
        echo "❌ Failed to fetch regions. Make sure you're logged in with 'aws_sso'"
    }
}

# Get AWS account info
aws_account_info() {
    echo "📊 AWS Account Information:"
    echo "=========================="
    
    local identity=$(aws sts get-caller-identity 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        echo "$identity" | jq -r '"Account: " + .Account'
        echo "$identity" | jq -r '"User/Role: " + .Arn'
        echo "$identity" | jq -r '"User ID: " + .UserId'
    else
        echo "❌ Could not retrieve account information"
        return 1
    fi
}

# =============================================================================
# AWS VAULT FUNCTIONS - Secure credential management
# =============================================================================

# List aws-vault profiles
awsv_list() {
    echo "🔐 AWS Vault Profiles:"
    echo "====================="
    aws-vault list
}

# Execute command with aws-vault profile
awsv_exec() {
    if [[ -z "$1" ]]; then
        echo "Usage: awsv_exec <profile> [command]"
        echo "Available profiles:"
        awsv_list
        return 1
    fi
    
    local profile="$1"
    shift
    
    if [[ $# -eq 0 ]]; then
        # No command provided, start a shell
        echo "🚀 Starting shell with profile: $profile"
        aws-vault exec "$profile" -- zsh
    else
        # Execute the provided command
        echo "🚀 Executing with profile: $profile"
        aws-vault exec "$profile" -- "$@"
    fi
}

# Login to aws-vault profile
awsv_login() {
    if [[ -z "$1" ]]; then
        echo "Usage: awsv_login <profile>"
        echo "Available profiles:"
        awsv_list
        return 1
    fi
    
    local profile="$1"
    echo "🔐 Logging into aws-vault profile: $profile"
    aws-vault login "$profile"
}

# Add new aws-vault profile
awsv_add() {
    if [[ -z "$1" ]]; then
        echo "Usage: awsv_add <profile>"
        return 1
    fi
    
    local profile="$1"
    echo "➕ Adding aws-vault profile: $profile"
    aws-vault add "$profile"
}

# Remove aws-vault profile
awsv_remove() {
    if [[ -z "$1" ]]; then
        echo "Usage: awsv_remove <profile>"
        echo "Available profiles:"
        awsv_list
        return 1
    fi
    
    local profile="$1"
    echo "🗑️  Removing aws-vault profile: $profile"
    aws-vault remove "$profile"
}

# Clear aws-vault sessions
awsv_clear() {
    echo "🧹 Clearing aws-vault sessions..."
    aws-vault clear
}

# Get aws-vault version and status
awsv_status() {
    echo "📊 AWS Vault Status:"
    echo "==================="
    
    if command -v aws-vault &> /dev/null; then
        echo "✅ aws-vault is installed"
        aws-vault --version
        echo ""
        awsv_list
    else
        echo "❌ aws-vault is not installed"
        echo "💡 Install with: brew install aws-vault"
    fi
}

# Interactive aws-vault profile selector
awsv() {
    if ! command -v aws-vault &> /dev/null; then
        echo "❌ aws-vault is not installed"
        echo "💡 Install with: brew install aws-vault"
        return 1
    fi

    # Get available profiles
    local profiles=($(aws-vault list --profiles 2>/dev/null))
    
    if [ ${#profiles[@]} -eq 0 ]; then
        echo "❌ No aws-vault profiles found"
        echo "💡 Add a profile with: awsv_add <profile>"
        return 1
    fi

    # Add options to the profiles
    profiles+=("Add new profile" "Clear sessions" "Quit")

    echo "🔐 AWS Vault Manager"
    echo "==================="
    
    PS3="Select an option: "
    select option in "${profiles[@]}"; do
        case $option in
            "Add new profile")
                read -p "Enter profile name: " profile_name
                if [[ -n "$profile_name" ]]; then
                    awsv_add "$profile_name"
                fi
                break
                ;;
            "Clear sessions")
                awsv_clear
                break
                ;;
            "Quit")
                echo "👋 Exiting AWS Vault Manager"
                break
                ;;
            "")
                echo "❌ Invalid selection. Please try again."
                ;;
            *)
                echo "🚀 Starting shell with profile: $option"
                awsv_exec "$option"
                break
                ;;
        esac
    done
}

# Export credentials from aws-vault to environment
awsv_export() {
    if [[ -z "$1" ]]; then
        echo "Usage: awsv_export <profile>"
        echo "Available profiles:"
        awsv_list
        return 1
    fi
    
    local profile="$1"
    echo "📤 Exporting credentials for profile: $profile"
    
    # Export credentials to current shell
    eval "$(aws-vault exec "$profile" -- env | grep AWS_ | sed 's/^/export /')"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Credentials exported to current shell"
        aws_sts
    else
        echo "❌ Failed to export credentials"
    fi
}
