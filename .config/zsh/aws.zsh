# =============================================================================
# AWS FUNCTIONS - Enhanced AWS CLI utilities
# =============================================================================

# Colors for better UX
aws_red=$'\033[0;31m'
aws_green=$'\033[0;32m'
aws_yellow=$'\033[0;33m'
aws_blue=$'\033[0;34m'
aws_purple=$'\033[0;35m'
aws_cyan=$'\033[0;36m'
aws_nc=$'\033[0m'

# Interactive AWS profile configuration
aws_configure() {
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo -e "${aws_red}❌ AWS CLI is not installed. Please install it first.${aws_nc}"
        return 1
    fi

    echo -e "${aws_blue}⚙️  AWS Profile Configuration${aws_nc}"
    echo -e "${aws_blue}=============================${aws_nc}"
    echo ""
    
    # Ask for profile name
    while true; do
        echo -ne "${aws_yellow}Enter profile name: ${aws_nc}"
        read -r profile_name
        
        if [[ -z "$profile_name" ]]; then
            echo -e "${aws_red}❌ Profile name cannot be empty${aws_nc}"
            continue
        fi
        
        # Check if profile already exists
        if aws configure list-profiles 2>/dev/null | grep -q "^$profile_name$"; then
            echo -ne "${aws_yellow}⚠️  Profile '$profile_name' already exists. Overwrite? (y/N): ${aws_nc}"
            read -r overwrite
            if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
                continue
            fi
        fi
        break
    done
    
    echo ""
    echo -e "${aws_cyan}Select profile type:${aws_nc}"
    echo -e "  ${aws_yellow}1)${aws_nc} SSO Profile"
    echo -e "  ${aws_yellow}2)${aws_nc} Traditional Profile (Access Key/Secret Key)"
    echo -e "  ${aws_yellow}3)${aws_nc} Cancel"
    echo ""
    
    while true; do
        echo -ne "${aws_yellow}Select type (enter number): ${aws_nc}"
        read -r type_choice
        
        case $type_choice in
            1)
                echo -e "${aws_cyan}🔐 Configuring SSO Profile: ${aws_yellow}$profile_name${aws_nc}"
                echo ""
                aws configure sso --profile "$profile_name"
                if [[ $? -eq 0 ]]; then
                    echo ""
                    echo -e "${aws_green}✅ SSO profile '$profile_name' configured successfully${aws_nc}"
                    echo -e "${aws_yellow}💡 Use 'aws_sso_login $profile_name' to login${aws_nc}"
                else
                    echo -e "${aws_red}❌ Failed to configure SSO profile${aws_nc}"
                fi
                break
                ;;
            2)
                echo -e "${aws_cyan}🔑 Configuring Traditional Profile: ${aws_yellow}$profile_name${aws_nc}"
                echo ""
                aws configure --profile "$profile_name"
                if [[ $? -eq 0 ]]; then
                    echo ""
                    echo -e "${aws_green}✅ Traditional profile '$profile_name' configured successfully${aws_nc}"
                    echo -e "${aws_yellow}💡 Use 'aws_login $profile_name' to activate${aws_nc}"
                else
                    echo -e "${aws_red}❌ Failed to configure traditional profile${aws_nc}"
                fi
                break
                ;;
            3)
                echo -e "${aws_yellow}👋 Configuration cancelled${aws_nc}"
                return 0
                ;;
            *)
                echo -e "${aws_red}❌ Invalid selection. Please try again.${aws_nc}"
                ;;
        esac
    done
}

# List all AWS profiles with colors
aws_list_profiles() {
    echo -e "${aws_cyan}Available AWS profiles:${aws_nc}"
    aws configure list-profiles | sort | sed "s/^/  ${aws_yellow}- /" | sed "s/\$/${aws_nc}/"
}

# Enhanced AWS SSO login with better error handling and color support
aws_sso_login() {
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo -e "${aws_red}❌ AWS CLI is not installed. Please install it first.${aws_nc}"
        return 1
    fi

    # Handle direct profile argument
    if [[ $# -eq 1 ]]; then
        local requested_profile="$1"
        
        # Check if profile exists
        if ! aws configure list-profiles 2>/dev/null | grep -q "^$requested_profile$"; then
            echo -e "${aws_red}❌ Profile '$requested_profile' not found${aws_nc}"
            echo ""
            aws_list_profiles
            return 1
        fi
        
        # Perform direct login
        echo -e "${aws_cyan}🔄 Logging into AWS profile: ${aws_yellow}$requested_profile${aws_nc}"
        echo ""
        
        if aws sso login --profile "$requested_profile"; then
            echo ""
            echo -e "${aws_green}✅ Successfully logged into profile: ${aws_yellow}$requested_profile${aws_nc}"
            
            # Set environment variable
            export AWS_PROFILE="$requested_profile"
            echo -e "${aws_green}✅ AWS_PROFILE set to: ${aws_yellow}$requested_profile${aws_nc}"
            
            # Export credentials
            if eval "$(aws configure export-credentials --profile $requested_profile --format env 2>/dev/null)"; then
                echo -e "${aws_green}✅ Credentials exported to environment${aws_nc}"
            else
                echo -e "${aws_yellow}⚠️  Warning: Could not export credentials to environment${aws_nc}"
            fi
            
            # Show caller identity
            aws_sts
        else
            echo ""
            echo -e "${aws_red}❌ Failed to login to profile: $requested_profile${aws_nc}"
            return 1
        fi
        return 0
    fi

    # Interactive mode - Get only SSO profiles
    local profiles=()
    
    # Use the reliable method with aws configure
    local all_profiles=($(aws configure list-profiles 2>/dev/null))
    
    if [[ ${#all_profiles[@]} -gt 0 ]]; then
        echo -e "${aws_yellow}🔄 Scanning profiles for SSO configuration...${aws_nc}"
        
        # Check profiles for SSO configuration
        for profile in "${all_profiles[@]}"; do
            if aws configure get sso_start_url --profile "$profile" &>/dev/null || \
               aws configure get sso_session --profile "$profile" &>/dev/null; then
                profiles+=("$profile")
            fi
        done
        
        # Show result
        echo -e "${aws_green}✅ Found ${#profiles[@]} SSO profiles${aws_nc}"
    fi
    
    # Check if there are any SSO profiles
    if [ ${#profiles[@]} -eq 0 ]; then
        echo -e "${aws_red}❌ No AWS SSO profiles found. Please configure AWS SSO profiles first.${aws_nc}"
        echo -e "${aws_yellow}💡 Run: aws configure sso${aws_nc}"
        return 1
    fi

    echo -e "${aws_blue}🔐 AWS SSO Login${aws_nc}"
    echo -e "${aws_blue}===============${aws_nc}"
    echo ""
    
    # Sort profiles alphabetically
    IFS=$'\n' profiles=($(sort <<<"${profiles[*]}"))
    unset IFS
    
    # Display profiles manually for better control
    echo -e "${aws_cyan}Available SSO profiles:${aws_nc}"
    for profile in "${profiles[@]}"; do
        echo -e "  ${aws_yellow}- ${aws_nc}$profile"
    done
    echo ""
    
    # Read user input manually
    while true; do
        echo -ne "${aws_yellow}Enter AWS profile name (or 'refresh' to refresh, 'quit' to exit): ${aws_nc}"
        read -r choice
        
        # Normalize input - trim whitespace and convert to lowercase for comparison
        choice=$(echo "$choice" | xargs | tr '[:upper:]' '[:lower:]')
        
        # Handle special commands
        if [[ "$choice" == "refresh" ]]; then
            echo -e "${aws_cyan}🔄 Refreshing profile list...${aws_nc}"
            echo ""
            aws_sso_login
            break
        elif [[ "$choice" == "quit" || "$choice" == "exit" ]]; then
            echo -e "${aws_yellow}👋 Exiting AWS SSO login${aws_nc}"
            break
        else
            # Find matching profile (case insensitive)
            local selected_profile=""
            for profile in "${profiles[@]}"; do
                if [[ "$(echo "$profile" | tr '[:upper:]' '[:lower:]')" == "$choice" ]]; then
                    selected_profile="$profile"
                    break
                fi
            done
            
            # If no exact match found, check if it's a partial match
            if [[ -z "$selected_profile" ]]; then
                local matches=()
                for profile in "${profiles[@]}"; do
                    if [[ "$(echo "$profile" | tr '[:upper:]' '[:lower:]')" == *"$choice"* ]]; then
                        matches+=("$profile")
                    fi
                done
                
                if [[ ${#matches[@]} -eq 1 ]]; then
                    selected_profile="${matches[0]}"
                elif [[ ${#matches[@]} -gt 1 ]]; then
                    echo -e "${aws_yellow}Multiple matches found:${aws_nc}"
                    for match in "${matches[@]}"; do
                        echo -e "  ${aws_yellow}- ${aws_nc}$match"
                    done
                    echo -e "${aws_red}Please be more specific.${aws_nc}"
                    echo ""
                    continue
                else
                    echo -e "${aws_red}❌ Profile '$choice' not found. Please try again.${aws_nc}"
                    echo ""
                    continue
                fi
            fi
            
            echo -e "${aws_cyan}🔄 Logging into AWS profile: ${aws_yellow}$selected_profile${aws_nc}"
            echo ""
            
            # Attempt SSO login
            if aws sso login --profile "$selected_profile"; then
                echo ""
                echo -e "${aws_green}✅ Successfully logged into profile: ${aws_yellow}$selected_profile${aws_nc}"
                
                # Set environment variable
                export AWS_PROFILE="$selected_profile"
                echo -e "${aws_green}✅ AWS_PROFILE set to: ${aws_yellow}$selected_profile${aws_nc}"
                
                # Export credentials
                if eval "$(aws configure export-credentials --profile $selected_profile --format env 2>/dev/null)"; then
                    echo -e "${aws_green}✅ Credentials exported to environment${aws_nc}"
                else
                    echo -e "${aws_yellow}⚠️  Warning: Could not export credentials to environment${aws_nc}"
                fi
                
                # Show caller identity
                aws_sts
            else
                echo ""
                echo -e "${aws_red}❌ Failed to login to profile: $selected_profile${aws_nc}"
            fi
            break
        fi
    done
}

# AWS login for non-SSO profiles (traditional access key/secret key)
aws_login() {
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo -e "${aws_red}❌ AWS CLI is not installed. Please install it first.${aws_nc}"
        return 1
    fi

    # Handle direct profile argument
    if [[ $# -eq 1 ]]; then
        local requested_profile="$1"
        
        # Check if profile exists
        if ! aws configure list-profiles 2>/dev/null | grep -q "^$requested_profile$"; then
            echo -e "${aws_red}❌ Profile '$requested_profile' not found${aws_nc}"
            echo ""
            aws_list_profiles
            return 1
        fi
        
        # Check if it's not an SSO profile
        if aws configure get sso_start_url --profile "$requested_profile" &>/dev/null || \
           aws configure get sso_session --profile "$requested_profile" &>/dev/null; then
            echo -e "${aws_red}❌ Profile '$requested_profile' is an SSO profile. Use 'aws_sso_login' instead.${aws_nc}"
            return 1
        fi
        
        # Set profile and export credentials
        export AWS_PROFILE="$requested_profile"
        echo -e "${aws_green}✅ AWS_PROFILE set to: ${aws_yellow}$requested_profile${aws_nc}"
        
        # Show caller identity
        aws_sts
        return 0
    fi

    # Interactive mode - Get only non-SSO profiles
    local profiles=()
    
    # Use the optimized method with parallel checks
    local all_profiles=($(aws configure list-profiles 2>/dev/null))
    
    if [[ ${#all_profiles[@]} -gt 0 ]]; then
        echo -e "${aws_yellow}🔄 Scanning profiles for traditional configuration...${aws_nc}"
        
        # Check profiles for traditional configuration
        for profile in "${all_profiles[@]}"; do
            if ! aws configure get sso_start_url --profile "$profile" &>/dev/null && \
               ! aws configure get sso_session --profile "$profile" &>/dev/null; then
                profiles+=("$profile")
            fi
        done
        
        # Show result
        echo -e "${aws_green}✅ Found ${#profiles[@]} traditional profiles${aws_nc}"
    fi
    
    # Check if there are any non-SSO profiles
    if [ ${#profiles[@]} -eq 0 ]; then
        echo -e "${aws_red}❌ No traditional AWS profiles found. Please configure AWS CLI profiles first.${aws_nc}"
        echo -e "${aws_yellow}💡 Run: aws configure${aws_nc}"
        return 1
    fi

    echo -e "${aws_blue}🔑 AWS Traditional Login${aws_nc}"
    echo -e "${aws_blue}=======================${aws_nc}"
    echo ""
    
    # Sort profiles alphabetically
    IFS=$'\n' profiles=($(sort <<<"${profiles[*]}"))
    unset IFS
    
    # Display profiles manually for better control
    echo -e "${aws_cyan}Available traditional profiles:${aws_nc}"
    for profile in "${profiles[@]}"; do
        echo -e "  ${aws_yellow}- ${aws_nc}$profile"
    done
    echo ""
    
    # Read user input manually
    while true; do
        echo -ne "${aws_yellow}Enter AWS profile name (or 'refresh' to refresh, 'quit' to exit): ${aws_nc}"
        read -r choice
        
        # Normalize input - trim whitespace and convert to lowercase for comparison
        choice=$(echo "$choice" | xargs | tr '[:upper:]' '[:lower:]')
        
        # Handle special commands
        if [[ "$choice" == "refresh" ]]; then
            echo -e "${aws_cyan}🔄 Refreshing profile list...${aws_nc}"
            echo ""
            aws_login
            break
        elif [[ "$choice" == "quit" || "$choice" == "exit" ]]; then
            echo -e "${aws_yellow}👋 Exiting AWS traditional login${aws_nc}"
            break
        else
            # Find matching profile (case insensitive)
            local selected_profile=""
            for profile in "${profiles[@]}"; do
                if [[ "$(echo "$profile" | tr '[:upper:]' '[:lower:]')" == "$choice" ]]; then
                    selected_profile="$profile"
                    break
                fi
            done
            
            # If no exact match found, check if it's a partial match
            if [[ -z "$selected_profile" ]]; then
                local matches=()
                for profile in "${profiles[@]}"; do
                    if [[ "$(echo "$profile" | tr '[:upper:]' '[:lower:]')" == *"$choice"* ]]; then
                        matches+=("$profile")
                    fi
                done
                
                if [[ ${#matches[@]} -eq 1 ]]; then
                    selected_profile="${matches[0]}"
                elif [[ ${#matches[@]} -gt 1 ]]; then
                    echo -e "${aws_yellow}Multiple matches found:${aws_nc}"
                    for match in "${matches[@]}"; do
                        echo -e "  ${aws_yellow}- ${aws_nc}$match"
                    done
                    echo -e "${aws_red}Please be more specific.${aws_nc}"
                    echo ""
                    continue
                else
                    echo -e "${aws_red}❌ Profile '$choice' not found. Please try again.${aws_nc}"
                    echo ""
                    continue
                fi
            fi
            
            echo -e "${aws_cyan}🔄 Setting AWS profile: ${aws_yellow}$selected_profile${aws_nc}"
            echo ""
            
            # Set environment variable
            export AWS_PROFILE="$selected_profile"
            echo -e "${aws_green}✅ AWS_PROFILE set to: ${aws_yellow}$selected_profile${aws_nc}"
            
            # Show caller identity
            aws_sts
            break
        fi
    done
}

# Get current AWS identity with enhanced output and colors
aws_sts() {
    echo -e "${aws_purple}🔍 Current AWS Identity:${aws_nc}"
    echo -e "${aws_purple}=======================${aws_nc}"
    echo ""
    
    if aws sts get-caller-identity 2>/dev/null; then
        echo ""
        echo -e "${aws_green}✅ AWS credentials are valid${aws_nc}"
        
        # Show current profile if set
        if [[ -n "$AWS_PROFILE" ]]; then
            echo -e "${aws_cyan}📊 Active profile: ${aws_yellow}$AWS_PROFILE${aws_nc}"
        fi
        
        # Show region if set
        local region
        if [[ -n "$AWS_PROFILE" ]]; then
            region=$(aws configure get region --profile "$AWS_PROFILE" 2>/dev/null)
        else
            region=$(aws configure get region 2>/dev/null)
        fi
        if [[ -n "$region" ]]; then
            echo -e "${aws_cyan}🌍 Region: ${aws_yellow}$region${aws_nc}"
        fi
    else
        echo -e "${aws_red}❌ No valid AWS credentials found${aws_nc}"
        echo -e "${aws_yellow}💡 Run 'aws_sso_login' for SSO profiles or 'aws_login' for traditional profiles${aws_nc}"
        return 1
    fi
}



# Clear AWS credentials with color support
aws_clear() {
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    unset AWS_PROFILE
    echo -e "${aws_green}✅ AWS credentials cleared from environment${aws_nc}"
}

# List AWS regions
aws_regions() {
    echo -e "${aws_cyan}🌍 Available AWS regions:${aws_nc}"
    aws ec2 describe-regions --query 'Regions[*].RegionName' --output table 2>/dev/null || {
        echo -e "${aws_red}❌ Failed to fetch regions. Make sure you're logged in with 'aws_sso_login' or 'aws_login'${aws_nc}"
    }
}

# AWS Profile Manager - delete, clean, and manage profiles
aws_profile_manager() {
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo -e "${aws_red}❌ AWS CLI is not installed. Please install it first.${aws_nc}"
        return 1
    fi

    echo -e "${aws_blue}🛠️  AWS Profile Manager${aws_nc}"
    echo -e "${aws_blue}======================${aws_nc}"
    echo ""
    
    # Get all profiles and sort them
    local all_profiles=($(aws configure list-profiles 2>/dev/null | sort))
    
    if [ ${#all_profiles[@]} -eq 0 ]; then
        echo -e "${aws_red}❌ No AWS profiles found${aws_nc}"
        return 1
    fi

    echo -e "${aws_cyan}Select action:${aws_nc}"
    echo -e "  ${aws_yellow}1)${aws_nc} Delete a profile"
    echo -e "  ${aws_yellow}2)${aws_nc} Clean SSO cache for a profile"
    echo -e "  ${aws_yellow}3)${aws_nc} View profile details"
    echo -e "  ${aws_yellow}4)${aws_nc} Clean all SSO cache"
    echo -e "  ${aws_yellow}5)${aws_nc} Quit"
    echo ""
    
    while true; do
        echo -ne "${aws_yellow}Select action (enter number): ${aws_nc}"
        read -r action_choice
        
        case $action_choice in
            1)
                # Delete profile
                echo ""
                echo -e "${aws_cyan}Available profiles:${aws_nc}"
                local i=1
                for profile in "${all_profiles[@]}"; do
                    echo -e "  ${aws_yellow}$i)${aws_nc} $profile"
                    ((i++))
                done
                echo ""
                
                echo -ne "${aws_yellow}Select profile to delete (enter number): ${aws_nc}"
                read -r profile_choice
                
                if [[ "$profile_choice" =~ ^[0-9]+$ ]] && [[ "$profile_choice" -ge 1 ]] && [[ "$profile_choice" -le ${#all_profiles[@]} ]]; then
                    local selected_profile="${all_profiles[$profile_choice]}"
                    echo ""
                    echo -ne "${aws_red}⚠️  Are you sure you want to delete profile '$selected_profile'? (y/N): ${aws_nc}"
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
                        
                        echo -e "${aws_green}✅ Profile '$selected_profile' deleted successfully${aws_nc}"
                    else
                        echo -e "${aws_yellow}❌ Deletion cancelled${aws_nc}"
                    fi
                else
                    echo -e "${aws_red}❌ Invalid selection${aws_nc}"
                fi
                break
                ;;
            2)
                # Clean SSO cache for specific profile
                echo ""
                echo -e "${aws_cyan}Available profiles:${aws_nc}"
                local i=1
                for profile in "${all_profiles[@]}"; do
                    echo -e "  ${aws_yellow}$i)${aws_nc} $profile"
                    ((i++))
                done
                echo ""
                
                echo -ne "${aws_yellow}Select profile to clean SSO cache (enter number): ${aws_nc}"
                read -r profile_choice
                
                if [[ "$profile_choice" =~ ^[0-9]+$ ]] && [[ "$profile_choice" -ge 1 ]] && [[ "$profile_choice" -le ${#all_profiles[@]} ]]; then
                    local selected_profile="${all_profiles[$profile_choice]}"
                    echo ""
                    echo -e "${aws_cyan}🧹 Cleaning SSO cache for profile: ${aws_yellow}$selected_profile${aws_nc}"
                    
                    aws sso logout --profile "$selected_profile" 2>/dev/null
                    echo -e "${aws_green}✅ SSO cache cleaned for profile '$selected_profile'${aws_nc}"
                else
                    echo -e "${aws_red}❌ Invalid selection${aws_nc}"
                fi
                break
                ;;
            3)
                # View profile details
                echo ""
                echo -e "${aws_cyan}Available profiles:${aws_nc}"
                local i=1
                for profile in "${all_profiles[@]}"; do
                    echo -e "  ${aws_yellow}$i)${aws_nc} $profile"
                    ((i++))
                done
                echo ""
                
                echo -ne "${aws_yellow}Select profile to view details (enter number): ${aws_nc}"
                read -r profile_choice
                
                if [[ "$profile_choice" =~ ^[0-9]+$ ]] && [[ "$profile_choice" -ge 1 ]] && [[ "$profile_choice" -le ${#all_profiles[@]} ]]; then
                    local selected_profile="${all_profiles[$profile_choice]}"
                    echo ""
                    echo -e "${aws_purple}📊 Profile Details: ${aws_yellow}$selected_profile${aws_nc}"
                    echo -e "${aws_purple}===========================================${aws_nc}"
                    aws configure list --profile "$selected_profile"
                else
                    echo -e "${aws_red}❌ Invalid selection${aws_nc}"
                fi
                break
                ;;
            4)
                # Clean all SSO cache
                echo ""
                echo -ne "${aws_yellow}⚠️  This will log you out of all SSO sessions. Continue? (y/N): ${aws_nc}"
                read -r confirm
                
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    echo -e "${aws_cyan}🧹 Cleaning all SSO cache...${aws_nc}"
                    rm -rf ~/.aws/sso/cache/* 2>/dev/null
                    rm -rf ~/.aws/cli/cache/* 2>/dev/null
                    echo -e "${aws_green}✅ All SSO cache cleaned${aws_nc}"
                else
                    echo -e "${aws_yellow}❌ Cache cleaning cancelled${aws_nc}"
                fi
                break
                ;;
            5)
                echo -e "${aws_yellow}👋 Exiting Profile Manager${aws_nc}"
                return 0
                ;;
            *)
                echo -e "${aws_red}❌ Invalid selection. Please try again.${aws_nc}"
                ;;
        esac
    done
}

# Get AWS account info
aws_account_info() {
    echo -e "${aws_purple}📊 AWS Account Information:${aws_nc}"
    echo -e "${aws_purple}==========================${aws_nc}"
    echo ""
    
    local identity=$(aws sts get-caller-identity 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        if command -v jq &> /dev/null; then
            echo -e "${aws_cyan}Account: ${aws_yellow}$(echo "$identity" | jq -r '.Account')${aws_nc}"
            echo -e "${aws_cyan}User/Role: ${aws_yellow}$(echo "$identity" | jq -r '.Arn')${aws_nc}"
            echo -e "${aws_cyan}User ID: ${aws_yellow}$(echo "$identity" | jq -r '.UserId')${aws_nc}"
        else
            echo "$identity"
        fi
    else
        echo -e "${aws_red}❌ Could not retrieve account information${aws_nc}"
        return 1
    fi
}

# =============================================================================
# AWS SCRIPT ALIASES - Management tools
# =============================================================================

# AWS IAM management
alias aws-iam-create-user='$HOME/.scripts/python/aws-iam-create-user.py'

# AWS Route53 DNS management
alias aws-route53-add-cname='$HOME/.scripts/python/aws-route53-add-cname.py'
alias aws-route53-add-ns='$HOME/.scripts/python/aws-route53-add-ns.py'

