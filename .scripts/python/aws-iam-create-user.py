#!/usr/bin/env python3
"""
Script to create IAM users and groups with AdministratorAccess
Follows the same pattern as the shell script create_iac_user.sh
"""

import boto3
import argparse
import sys
import os
import json
from botocore.exceptions import ClientError, NoCredentialsError


def get_current_aws_profile():
    """Get the current AWS profile being used"""
    try:
        # Check for AWS_PROFILE environment variable first
        profile = os.getenv('AWS_PROFILE')
        if profile:
            return profile
        
        # Try to get from boto3 session
        session = boto3.Session()
        if hasattr(session, 'profile_name') and session.profile_name:
            return session.profile_name
        
        return 'default'
    except:
        return 'default'


def get_current_aws_region(session):
    """Get the current AWS region from session"""
    try:
        # Try to get region from session
        if session.region_name:
            return session.region_name
        
        # Fallback to environment variable
        region = os.getenv('AWS_DEFAULT_REGION')
        if region:
            return region
        
        # Default fallback
        return 'us-east-1'
    except:
        return 'us-east-1'


def get_policy_arn(region):
    """Get the appropriate policy ARN based on the AWS region."""
    if region in ['us-gov-west-1', 'us-gov-east-1']:
        return "arn:aws-us-gov:iam::aws:policy/AdministratorAccess"
    return "arn:aws:iam::aws:policy/AdministratorAccess"


def confirm_action(group_name, user_name, environment_scope, region, policy_arn, profile):
    """Ask for user confirmation before making changes"""
    print("\n" + "="*70)
    print("CONFIRMATION - Review the IAM resources to be created:")
    print("="*70)
    print(f"AWS Profile:     {profile}")
    print(f"AWS Region:      {region}")
    print(f"Group Name:      {group_name}")
    print(f"User Name:       {user_name}")
    print(f"Environment:     {environment_scope}")
    print(f"Policy ARN:      {policy_arn}")
    print(f"Action:          CREATE new IAM group, user, and access keys")
    print("="*70)
    print("✅ This will CREATE a new IAM group and user with AdministratorAccess.")
    print("⚠️  The user will have full administrative permissions!")
    print("="*70)
    
    while True:
        response = input("\nDo you want to CREATE these IAM resources? (y/N): ").strip().lower()
        if response in ['y', 'yes']:
            return True
        elif response in ['n', 'no', '']:
            return False
        else:
            print("Please enter 'y' for yes or 'n' for no.")


def get_user_input():
    """Collect all required information from user interactively"""
    print("AWS IAM User Creator")
    print("=" * 40)
    
    # Get group name with default
    group_name = input("Enter IAM group name (default: github_iac): ").strip() or "github_iac"
    
    # Get user name with default
    user_name = input("Enter IAM user name (default: github_user): ").strip() or "github_user"
    
    # Get environment scope
    while True:
        environment_scope = input("Enter environment scope (e.g., staging, prod): ").strip()
        if environment_scope:
            break
        print("Environment scope cannot be empty. Please try again.")
    
    return group_name, user_name, environment_scope


def create_iam_resources(iam_client, group_name, user_name, environment_scope, region, policy_arn):
    """Create IAM group, user, and access keys"""
    try:
        # Create IAM group
        print(f"\nCreating IAM group: {group_name}...")
        try:
            iam_client.create_group(GroupName=group_name)
            print(f"✅ Group {group_name} created successfully")
        except ClientError as e:
            if e.response['Error']['Code'] == 'EntityAlreadyExists':
                print(f"⚠️  Group {group_name} already exists, continuing...")
            else:
                raise
        
        # Attach policy to group
        print(f"Attaching policy {policy_arn} to group: {group_name}...")
        iam_client.attach_group_policy(GroupName=group_name, PolicyArn=policy_arn)
        print(f"✅ Policy attached to group {group_name}")
        
        # Create IAM user
        print(f"Creating IAM user: {user_name}...")
        try:
            iam_client.create_user(UserName=user_name)
            print(f"✅ User {user_name} created successfully")
        except ClientError as e:
            if e.response['Error']['Code'] == 'EntityAlreadyExists':
                print(f"⚠️  User {user_name} already exists, continuing...")
            else:
                raise
        
        # Add user to group
        print(f"Adding user {user_name} to group {group_name}...")
        iam_client.add_user_to_group(UserName=user_name, GroupName=group_name)
        print(f"✅ User {user_name} added to group {group_name}")
        
        # Create access keys
        print(f"Creating access keys for user {user_name}...")
        response = iam_client.create_access_key(UserName=user_name)
        access_key = response['AccessKey']
        print(f"✅ Access keys created for user {user_name}")
        
        # Output in the desired format
        output = {
            "name": environment_scope,
            "branches": [environment_scope],
            "variables": [
                {
                    "name": "AWS_DEFAULT_REGION",
                    "value": region
                }
            ],
            "secrets": [
                {
                    "name": "AWS_ACCESS_KEY_ID",
                    "value": access_key['AccessKeyId']
                },
                {
                    "name": "AWS_SECRET_ACCESS_KEY",
                    "value": access_key['SecretAccessKey']
                }
            ]
        }
        
        print("\n" + "="*70)
        print("🎉 SUCCESS! IAM resources created successfully.")
        print("="*70)
        print("GitHub Environment JSON:")
        print(json.dumps(output, indent=4))
        
    except ClientError as e:
        print(f"❌ AWS Error: {e.response['Error']['Message']}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description='Create IAM user and group with AdministratorAccess')
    parser.add_argument('group_name', nargs='?', default='github_iac', help='IAM group name (default: github_iac)')
    parser.add_argument('user_name', nargs='?', default='github_user', help='IAM user name (default: github_user)')
    parser.add_argument('environment_scope', nargs='?', help='Environment scope (e.g., staging, prod)')
    parser.add_argument('--profile', help='AWS profile to use (defaults to current session)')
    parser.add_argument('--region', help='AWS region (defaults to AWS_DEFAULT_REGION env var)')
    parser.add_argument('--yes', '-y', action='store_true', help='Skip confirmation prompt')
    parser.add_argument('--interactive', '-i', action='store_true', help='Interactive mode (prompt for all inputs)')
    
    args = parser.parse_args()
    
    # Use interactive mode if no environment_scope provided or --interactive flag is used
    if args.interactive or not args.environment_scope:
        group_name, user_name, environment_scope = get_user_input()
    else:
        group_name = args.group_name or 'github_iac'
        user_name = args.user_name or 'github_user'
        environment_scope = args.environment_scope
    
    # Get AWS region
    session_kwargs = {}
    if args.profile:
        session_kwargs['profile_name'] = args.profile
    
    # Create session first to get region
    session = boto3.Session(**session_kwargs)
    region = args.region or get_current_aws_region(session)
    
    # Update session with region
    session_kwargs['region_name'] = region
    session = boto3.Session(**session_kwargs)
    
    # Get policy ARN based on region
    policy_arn = get_policy_arn(region)
    
    try:
        # Initialize boto3 session
        iam_client = session.client('iam')
        
        # Get current profile for display
        profile = args.profile or get_current_aws_profile()
        
        print(f"\nInitializing AWS IAM operations...")
        print(f"Profile: {profile}")
        print(f"Region: {region}")
        
        # Ask for confirmation unless --yes flag is used
        if not args.yes:
            if not confirm_action(group_name, user_name, environment_scope, region, policy_arn, profile):
                print("Operation cancelled by user.")
                sys.exit(0)
        
        # Create IAM resources
        create_iam_resources(iam_client, group_name, user_name, environment_scope, region, policy_arn)
        
    except NoCredentialsError:
        print("❌ Error: AWS credentials not found. Please configure your credentials.")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()