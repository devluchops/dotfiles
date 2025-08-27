# =============================================================================
# AWS FUNCTIONS - Enhanced AWS CLI utilities
# =============================================================================

# Colors for better UX
typeset -A aws_colors
aws_colors=(
    red     $'\033[0;31m'
    green   $'\033[0;32m'
    yellow  $'\033[0;33m'
    blue    $'\033[0;34m'
    purple  $'\033[0;35m'
    cyan    $'\033[0;36m'
    nc      $'\033[0m'  # No Color
)

# Interactive AWS profile configuration
aws_configure() {
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo -e "${aws_colors[red]}❌ AWS CLI is not installed. Please install it first.${aws_colors[nc]}"
        return 1
    fi

    echo -e "${aws_colors[blue]}⚙️  AWS Profile Configuration${aws_colors[nc]}"
    echo -e "${aws_colors[blue]}=============================${aws_colors[nc]}"
    echo ""
    
    # Ask for profile name
    while true; do
        echo -ne "${aws_colors[yellow]}Enter profile name: ${aws_colors[nc]}"
        read -r profile_name
        
        if [[ -z "$profile_name" ]]; then
            echo -e "${aws_colors[red]}❌ Profile name cannot be empty${aws_colors[nc]}"
            continue
        fi
        
        # Check if profile already exists
        if aws configure list-profiles 2>/dev/null | grep -q "^$profile_name$"; then
            echo -ne "${aws_colors[yellow]}⚠️  Profile '$profile_name' already exists. Overwrite? (y/N): ${aws_colors[nc]}"
            read -r overwrite
            if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
                continue
            fi
        fi
        break
    done
    
    echo ""
    echo -e "${aws_colors[cyan]}Select profile type:${aws_colors[nc]}"
    echo -e "  ${aws_colors[yellow]}1)${aws_colors[nc]} SSO Profile"
    echo -e "  ${aws_colors[yellow]}2)${aws_colors[nc]} Traditional Profile (Access Key/Secret Key)"
    echo -e "  ${aws_colors[yellow]}3)${aws_colors[nc]} Cancel"
    echo ""
    
    while true; do
        echo -ne "${aws_colors[yellow]}Select type (enter number): ${aws_colors[nc]}"
        read -r type_choice
        
        case $type_choice in
            1)
                echo -e "${aws_colors[cyan]}🔐 Configuring SSO Profile: ${aws_colors[yellow]}$profile_name${aws_colors[nc]}"
                echo ""
                aws configure sso --profile "$profile_name"
                if [[ $? -eq 0 ]]; then
                    echo ""
                    echo -e "${aws_colors[green]}✅ SSO profile '$profile_name' configured successfully${aws_colors[nc]}"
                    echo -e "${aws_colors[yellow]}💡 Use 'aws_sso_login $profile_name' to login${aws_colors[nc]}"
                else
                    echo -e "${aws_colors[red]}❌ Failed to configure SSO profile${aws_colors[nc]}"
                fi
                break
                ;;
            2)
                echo -e "${aws_colors[cyan]}🔑 Configuring Traditional Profile: ${aws_colors[yellow]}$profile_name${aws_colors[nc]}"
                echo ""
                aws configure --profile "$profile_name"
                if [[ $? -eq 0 ]]; then
                    echo ""
                    echo -e "${aws_colors[green]}✅ Traditional profile '$profile_name' configured successfully${aws_colors[nc]}"
                    echo -e "${aws_colors[yellow]}💡 Use 'aws_login $profile_name' to activate${aws_colors[nc]}"
                else
                    echo -e "${aws_colors[red]}❌ Failed to configure traditional profile${aws_colors[nc]}"
                fi
                break
                ;;
            3)
                echo -e "${aws_colors[yellow]}👋 Configuration cancelled${aws_colors[nc]}"
                return 0
                ;;
            *)
                echo -e "${aws_colors[red]}❌ Invalid selection. Please try again.${aws_colors[nc]}"
                ;;
        esac
    done
}

# List all AWS profiles with colors
aws_list_profiles() {
    echo -e "${aws_colors[cyan]}Available AWS profiles:${aws_colors[nc]}"
    aws configure list-profiles | sed "s/^/  ${aws_colors[yellow]}- /" | sed "s/$/${aws_colors[nc]}/"
}

# Enhanced AWS SSO login with better error handling and color support
aws_sso_login() {
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo -e "${aws_colors[red]}❌ AWS CLI is not installed. Please install it first.${aws_colors[nc]}"
        return 1
    fi

    # Handle direct profile argument
    if [[ $# -eq 1 ]]; then
        local requested_profile="$1"
        
        # Check if profile exists
        if ! aws configure list-profiles 2>/dev/null | grep -q "^$requested_profile$"; then
            echo -e "${aws_colors[red]}❌ Profile '$requested_profile' not found${aws_colors[nc]}"
            echo ""
            aws_list_profiles
            return 1
        fi
        
        # Perform direct login
        echo -e "${aws_colors[cyan]}🔄 Logging into AWS profile: ${aws_colors[yellow]}$requested_profile${aws_colors[nc]}"
        echo ""
        
        if aws sso login --profile "$requested_profile"; then
            echo ""
            echo -e "${aws_colors[green]}✅ Successfully logged into profile: ${aws_colors[yellow]}$requested_profile${aws_colors[nc]}"
            
            # Set environment variable
            export AWS_PROFILE="$requested_profile"
            echo -e "${aws_colors[green]}✅ AWS_PROFILE set to: ${aws_colors[yellow]}$requested_profile${aws_colors[nc]}"
            
            # Export credentials
            if eval "$(aws configure export-credentials --profile $requested_profile --format env 2>/dev/null)"; then
                echo -e "${aws_colors[green]}✅ Credentials exported to environment${aws_colors[nc]}"
            else
                echo -e "${aws_colors[yellow]}⚠️  Warning: Could not export credentials to environment${aws_colors[nc]}"
            fi
            
            # Show caller identity
            aws_sts
        else
            echo ""
            echo -e "${aws_colors[red]}❌ Failed to login to profile: $requested_profile${aws_colors[nc]}"
            return 1
        fi
        return 0
    fi

    # Interactive mode - Get only SSO profiles
    local all_profiles=($(aws configure list-profiles 2>/dev/null))
    local profiles=()
    
    # Filter only SSO profiles
    for profile in "${all_profiles[@]}"; do
        # Check if profile has SSO configuration
        if aws configure get sso_start_url --profile "$profile" &>/dev/null || \
           aws configure get sso_session --profile "$profile" &>/dev/null; then
            profiles+=("$profile")
        fi
    done
    
    # Check if there are any SSO profiles
    if [ ${#profiles[@]} -eq 0 ]; then
        echo -e "${aws_colors[red]}❌ No AWS SSO profiles found. Please configure AWS SSO profiles first.${aws_colors[nc]}"
        echo -e "${aws_colors[yellow]}💡 Run: aws configure sso${aws_colors[nc]}"
        return 1
    fi

    # Add management options to the profiles
    profiles+=("Refresh profiles" "Quit")

    echo -e "${aws_colors[blue]}🔐 AWS SSO Login${aws_colors[nc]}"
    echo -e "${aws_colors[blue]}===============${aws_colors[nc]}"
    echo ""
    
    # Display profiles manually for better control
    local i=1
    for profile in "${profiles[@]}"; do
        echo -e "  ${aws_colors[yellow]}$i)${aws_colors[nc]} $profile"
        ((i++))
    done
    echo ""
    
    # Read user input manually
    while true; do
        echo -ne "${aws_colors[yellow]}Select an AWS profile (enter number): ${aws_colors[nc]}"
        read -r choice
        
        # Validate input
        if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt ${#profiles[@]} ]]; then
            echo -e "${aws_colors[red]}❌ Invalid selection. Please try again.${aws_colors[nc]}"
            echo ""
            continue
        fi
        
        # Get selected profile
        local selected_profile="${profiles[$choice]}"
        
        case $selected_profile in
            "Refresh profiles")
                echo -e "${aws_colors[cyan]}🔄 Refreshing profile list...${aws_colors[nc]}"
                echo ""
                aws_sso_login
                break
                ;;
            "Quit")
                echo -e "${aws_colors[yellow]}👋 Exiting AWS SSO login${aws_colors[nc]}"
                break
                ;;
            *)
                echo -e "${aws_colors[cyan]}🔄 Logging into AWS profile: ${aws_colors[yellow]}$selected_profile${aws_colors[nc]}"
                echo ""
                
                # Attempt SSO login
                if aws sso login --profile "$selected_profile"; then
                    echo ""
                    echo -e "${aws_colors[green]}✅ Successfully logged into profile: ${aws_colors[yellow]}$selected_profile${aws_colors[nc]}"
                    
                    # Set environment variable
                    export AWS_PROFILE="$selected_profile"
                    echo -e "${aws_colors[green]}✅ AWS_PROFILE set to: ${aws_colors[yellow]}$selected_profile${aws_colors[nc]}"
                    
                    # Export credentials
                    if eval "$(aws configure export-credentials --profile $selected_profile --format env 2>/dev/null)"; then
                        echo -e "${aws_colors[green]}✅ Credentials exported to environment${aws_colors[nc]}"
                    else
                        echo -e "${aws_colors[yellow]}⚠️  Warning: Could not export credentials to environment${aws_colors[nc]}"
                    fi
                    
                    # Show caller identity
                    aws_sts
                else
                    echo ""
                    echo -e "${aws_colors[red]}❌ Failed to login to profile: $selected_profile${aws_colors[nc]}"
                fi
                break
                ;;
        esac
    done
}

# AWS login for non-SSO profiles (traditional access key/secret key)
aws_login() {
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo -e "${aws_colors[red]}❌ AWS CLI is not installed. Please install it first.${aws_colors[nc]}"
        return 1
    fi

    # Handle direct profile argument
    if [[ $# -eq 1 ]]; then
        local requested_profile="$1"
        
        # Check if profile exists
        if ! aws configure list-profiles 2>/dev/null | grep -q "^$requested_profile$"; then
            echo -e "${aws_colors[red]}❌ Profile '$requested_profile' not found${aws_colors[nc]}"
            echo ""
            aws_list_profiles
            return 1
        fi
        
        # Check if it's not an SSO profile
        if aws configure get sso_start_url --profile "$requested_profile" &>/dev/null || \
           aws configure get sso_session --profile "$requested_profile" &>/dev/null; then
            echo -e "${aws_colors[red]}❌ Profile '$requested_profile' is an SSO profile. Use 'aws_sso' instead.${aws_colors[nc]}"
            return 1
        fi
        
        # Set profile and export credentials
        export AWS_PROFILE="$requested_profile"
        echo -e "${aws_colors[green]}✅ AWS_PROFILE set to: ${aws_colors[yellow]}$requested_profile${aws_colors[nc]}"
        
        # Show caller identity
        aws_sts
        return 0
    fi

    # Interactive mode - Get only non-SSO profiles
    local all_profiles=($(aws configure list-profiles 2>/dev/null))
    local profiles=()
    
    # Filter only non-SSO profiles
    for profile in "${all_profiles[@]}"; do
        # Check if profile does NOT have SSO configuration
        if ! aws configure get sso_start_url --profile "$profile" &>/dev/null && \
           ! aws configure get sso_session --profile "$profile" &>/dev/null; then
            profiles+=("$profile")
        fi
    done
    
    # Check if there are any non-SSO profiles
    if [ ${#profiles[@]} -eq 0 ]; then
        echo -e "${aws_colors[red]}❌ No traditional AWS profiles found. Please configure AWS CLI profiles first.${aws_colors[nc]}"
        echo -e "${aws_colors[yellow]}💡 Run: aws configure${aws_colors[nc]}"
        return 1
    fi

    # Add management options to the profiles
    profiles+=("Refresh profiles" "Quit")

    echo -e "${aws_colors[blue]}🔑 AWS Traditional Login${aws_colors[nc]}"
    echo -e "${aws_colors[blue]}=======================${aws_colors[nc]}"
    echo ""
    
    # Display profiles manually for better control
    local i=1
    for profile in "${profiles[@]}"; do
        echo -e "  ${aws_colors[yellow]}$i)${aws_colors[nc]} $profile"
        ((i++))
    done
    echo ""
    
    # Read user input manually
    while true; do
        echo -ne "${aws_colors[yellow]}Select an AWS profile (enter number): ${aws_colors[nc]}"
        read -r choice
        
        # Validate input
        if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt ${#profiles[@]} ]]; then
            echo -e "${aws_colors[red]}❌ Invalid selection. Please try again.${aws_colors[nc]}"
            echo ""
            continue
        fi
        
        # Get selected profile
        local selected_profile="${profiles[$choice]}"
        
        case $selected_profile in
            "Refresh profiles")
                echo -e "${aws_colors[cyan]}🔄 Refreshing profile list...${aws_colors[nc]}"
                echo ""
                aws_login
                break
                ;;
            "Quit")
                echo -e "${aws_colors[yellow]}👋 Exiting AWS traditional login${aws_colors[nc]}"
                break
                ;;
            *)
                echo -e "${aws_colors[cyan]}🔄 Setting AWS profile: ${aws_colors[yellow]}$selected_profile${aws_colors[nc]}"
                echo ""
                
                # Set environment variable
                export AWS_PROFILE="$selected_profile"
                echo -e "${aws_colors[green]}✅ AWS_PROFILE set to: ${aws_colors[yellow]}$selected_profile${aws_colors[nc]}"
                
                # Show caller identity
                aws_sts
                break
                ;;
        esac
    done
}

# Get current AWS identity with enhanced output and colors
aws_sts() {
    echo -e "${aws_colors[purple]}🔍 Current AWS Identity:${aws_colors[nc]}"
    echo -e "${aws_colors[purple]}=======================${aws_colors[nc]}"
    echo ""
    
    if aws sts get-caller-identity 2>/dev/null; then
        echo ""
        echo -e "${aws_colors[green]}✅ AWS credentials are valid${aws_colors[nc]}"
        
        # Show current profile if set
        if [[ -n "$AWS_PROFILE" ]]; then
            echo -e "${aws_colors[cyan]}📊 Active profile: ${aws_colors[yellow]}$AWS_PROFILE${aws_colors[nc]}"
        fi
        
        # Show region if set
        local region
        if [[ -n "$AWS_PROFILE" ]]; then
            region=$(aws configure get region --profile "$AWS_PROFILE" 2>/dev/null)
        else
            region=$(aws configure get region 2>/dev/null)
        fi
        if [[ -n "$region" ]]; then
            echo -e "${aws_colors[cyan]}🌍 Region: ${aws_colors[yellow]}$region${aws_colors[nc]}"
        fi
    else
        echo -e "${aws_colors[red]}❌ No valid AWS credentials found${aws_colors[nc]}"
        echo -e "${aws_colors[yellow]}💡 Run 'aws_sso_login' for SSO profiles or 'aws_login' for traditional profiles${aws_colors[nc]}"
        return 1
    fi
}



# Clear AWS credentials with color support
aws_clear() {
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    unset AWS_PROFILE
    echo -e "${aws_colors[green]}✅ AWS credentials cleared from environment${aws_colors[nc]}"
}

# List AWS regions
aws_regions() {
    echo -e "${aws_colors[cyan]}🌍 Available AWS regions:${aws_colors[nc]}"
    aws ec2 describe-regions --query 'Regions[*].RegionName' --output table 2>/dev/null || {
        echo -e "${aws_colors[red]}❌ Failed to fetch regions. Make sure you're logged in with 'aws_sso_login' or 'aws_login'${aws_colors[nc]}"
    }
}

# AWS Profile Manager - delete, clean, and manage profiles
aws_profile_manager() {
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo -e "${aws_colors[red]}❌ AWS CLI is not installed. Please install it first.${aws_colors[nc]}"
        return 1
    fi

    echo -e "${aws_colors[blue]}🛠️  AWS Profile Manager${aws_colors[nc]}"
    echo -e "${aws_colors[blue]}======================${aws_colors[nc]}"
    echo ""
    
    # Get all profiles
    local all_profiles=($(aws configure list-profiles 2>/dev/null))
    
    if [ ${#all_profiles[@]} -eq 0 ]; then
        echo -e "${aws_colors[red]}❌ No AWS profiles found${aws_colors[nc]}"
        return 1
    fi

    echo -e "${aws_colors[cyan]}Select action:${aws_colors[nc]}"
    echo -e "  ${aws_colors[yellow]}1)${aws_colors[nc]} Delete a profile"
    echo -e "  ${aws_colors[yellow]}2)${aws_colors[nc]} Clean SSO cache for a profile"
    echo -e "  ${aws_colors[yellow]}3)${aws_colors[nc]} View profile details"
    echo -e "  ${aws_colors[yellow]}4)${aws_colors[nc]} Clean all SSO cache"
    echo -e "  ${aws_colors[yellow]}5)${aws_colors[nc]} Quit"
    echo ""
    
    while true; do
        echo -ne "${aws_colors[yellow]}Select action (enter number): ${aws_colors[nc]}"
        read -r action_choice
        
        case $action_choice in
            1)
                # Delete profile
                echo ""
                echo -e "${aws_colors[cyan]}Available profiles:${aws_colors[nc]}"
                local i=1
                for profile in "${all_profiles[@]}"; do
                    echo -e "  ${aws_colors[yellow]}$i)${aws_colors[nc]} $profile"
                    ((i++))
                done
                echo ""
                
                echo -ne "${aws_colors[yellow]}Select profile to delete (enter number): ${aws_colors[nc]}"
                read -r profile_choice
                
                if [[ "$profile_choice" =~ ^[0-9]+$ ]] && [[ "$profile_choice" -ge 1 ]] && [[ "$profile_choice" -le ${#all_profiles[@]} ]]; then
                    local selected_profile="${all_profiles[$profile_choice]}"
                    echo ""
                    echo -ne "${aws_colors[red]}⚠️  Are you sure you want to delete profile '$selected_profile'? (y/N): ${aws_colors[nc]}"
                    read -r confirm
                    
                    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                        # Remove from config and credentials files
                        aws configure --profile "$selected_profile" set aws_access_key_id "" 2>/dev/null
                        aws configure --profile "$selected_profile" set aws_secret_access_key "" 2>/dev/null
                        aws configure --profile "$selected_profile" set region "" 2>/dev/null
                        aws configure --profile "$selected_profile" set output "" 2>/dev/null
                        aws configure --profile "$selected_profile" set sso_start_url "" 2>/dev/null
                        aws configure --profile "$selected_profile" set sso_region "" 2>/dev/null
                        aws configure --profile "$selected_profile" set sso_account_id "" 2>/dev/null
                        aws configure --profile "$selected_profile" set sso_role_name "" 2>/dev/null
                        aws configure --profile "$selected_profile" set sso_session "" 2>/dev/null
                        
                        # Clean up config files manually
                        if [[ "$OSTYPE" == "darwin"* ]]; then
                            sed -i '' "/^\[profile $selected_profile\]/,/^\[/d" ~/.aws/config 2>/dev/null
                            sed -i '' "/^\[$selected_profile\]/,/^\[/d" ~/.aws/credentials 2>/dev/null
                        else
                            sed -i "/^\[profile $selected_profile\]/,/^\[/d" ~/.aws/config 2>/dev/null
                            sed -i "/^\[$selected_profile\]/,/^\[/d" ~/.aws/credentials 2>/dev/null
                        fi
                        
                        echo -e "${aws_colors[green]}✅ Profile '$selected_profile' deleted successfully${aws_colors[nc]}"
                    else
                        echo -e "${aws_colors[yellow]}❌ Deletion cancelled${aws_colors[nc]}"
                    fi
                else
                    echo -e "${aws_colors[red]}❌ Invalid selection${aws_colors[nc]}"
                fi
                break
                ;;
            2)
                # Clean SSO cache for specific profile
                echo ""
                echo -e "${aws_colors[cyan]}Available profiles:${aws_colors[nc]}"
                local i=1
                for profile in "${all_profiles[@]}"; do
                    echo -e "  ${aws_colors[yellow]}$i)${aws_colors[nc]} $profile"
                    ((i++))
                done
                echo ""
                
                echo -ne "${aws_colors[yellow]}Select profile to clean SSO cache (enter number): ${aws_colors[nc]}"
                read -r profile_choice
                
                if [[ "$profile_choice" =~ ^[0-9]+$ ]] && [[ "$profile_choice" -ge 1 ]] && [[ "$profile_choice" -le ${#all_profiles[@]} ]]; then
                    local selected_profile="${all_profiles[$profile_choice]}"
                    echo ""
                    echo -e "${aws_colors[cyan]}🧹 Cleaning SSO cache for profile: ${aws_colors[yellow]}$selected_profile${aws_colors[nc]}"
                    
                    aws sso logout --profile "$selected_profile" 2>/dev/null
                    echo -e "${aws_colors[green]}✅ SSO cache cleaned for profile '$selected_profile'${aws_colors[nc]}"
                else
                    echo -e "${aws_colors[red]}❌ Invalid selection${aws_colors[nc]}"
                fi
                break
                ;;
            3)
                # View profile details
                echo ""
                echo -e "${aws_colors[cyan]}Available profiles:${aws_colors[nc]}"
                local i=1
                for profile in "${all_profiles[@]}"; do
                    echo -e "  ${aws_colors[yellow]}$i)${aws_colors[nc]} $profile"
                    ((i++))
                done
                echo ""
                
                echo -ne "${aws_colors[yellow]}Select profile to view details (enter number): ${aws_colors[nc]}"
                read -r profile_choice
                
                if [[ "$profile_choice" =~ ^[0-9]+$ ]] && [[ "$profile_choice" -ge 1 ]] && [[ "$profile_choice" -le ${#all_profiles[@]} ]]; then
                    local selected_profile="${all_profiles[$profile_choice]}"
                    echo ""
                    echo -e "${aws_colors[purple]}📊 Profile Details: ${aws_colors[yellow]}$selected_profile${aws_colors[nc]}"
                    echo -e "${aws_colors[purple]}===========================================${aws_colors[nc]}"
                    aws configure list --profile "$selected_profile"
                else
                    echo -e "${aws_colors[red]}❌ Invalid selection${aws_colors[nc]}"
                fi
                break
                ;;
            4)
                # Clean all SSO cache
                echo ""
                echo -ne "${aws_colors[yellow]}⚠️  This will log you out of all SSO sessions. Continue? (y/N): ${aws_colors[nc]}"
                read -r confirm
                
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    echo -e "${aws_colors[cyan]}🧹 Cleaning all SSO cache...${aws_colors[nc]}"
                    rm -rf ~/.aws/sso/cache/* 2>/dev/null
                    rm -rf ~/.aws/cli/cache/* 2>/dev/null
                    echo -e "${aws_colors[green]}✅ All SSO cache cleaned${aws_colors[nc]}"
                else
                    echo -e "${aws_colors[yellow]}❌ Cache cleaning cancelled${aws_colors[nc]}"
                fi
                break
                ;;
            5)
                echo -e "${aws_colors[yellow]}👋 Exiting Profile Manager${aws_colors[nc]}"
                return 0
                ;;
            *)
                echo -e "${aws_colors[red]}❌ Invalid selection. Please try again.${aws_colors[nc]}"
                ;;
        esac
    done
}

# Get AWS account info
aws_account_info() {
    echo -e "${aws_colors[purple]}📊 AWS Account Information:${aws_colors[nc]}"
    echo -e "${aws_colors[purple]}==========================${aws_colors[nc]}"
    echo ""
    
    local identity=$(aws sts get-caller-identity 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        if command -v jq &> /dev/null; then
            echo -e "${aws_colors[cyan]}Account: ${aws_colors[yellow]}$(echo "$identity" | jq -r '.Account')${aws_colors[nc]}"
            echo -e "${aws_colors[cyan]}User/Role: ${aws_colors[yellow]}$(echo "$identity" | jq -r '.Arn')${aws_colors[nc]}"
            echo -e "${aws_colors[cyan]}User ID: ${aws_colors[yellow]}$(echo "$identity" | jq -r '.UserId')${aws_colors[nc]}"
        else
            echo "$identity"
        fi
    else
        echo -e "${aws_colors[red]}❌ Could not retrieve account information${aws_colors[nc]}"
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
