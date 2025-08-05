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
