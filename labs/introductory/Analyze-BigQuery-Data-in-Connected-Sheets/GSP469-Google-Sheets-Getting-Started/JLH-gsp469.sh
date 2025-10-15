#!/bin/bash

# GSP469 - Google Sheets: Getting Started
# Automated Lab Script
# This script provides guidance for the GSP469 Google Sheets Getting Started lab
# Note: This is primarily a web-based lab that doesn't require GCP resource creation
# Usage: ./JLH-gsp469.sh [--verbose|-v] [cleanup]
# Status: verified on 2025-10-15

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to get user input
get_input() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"

    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        eval "$var_name=\${input:-$default}"
    else
        read -p "$prompt: " input
        eval "$var_name=\"$input\""
    fi
}

# Function to confirm before proceeding
confirm() {
    local message="$1"
    local response

    read -p "$message (y/N): " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for user confirmation
wait_for_user() {
    local message="$1"
    echo
    print_warning "$message"
    read -p "Press Enter to continue..."
}

# Function to open URL in browser
open_url() {
    local url="$1"
    local description="$2"

    print_step "Opening: $description"
    print_warning "URL: $url"

    if command_exists open; then
        # macOS
        open "$url"
    elif command_exists xdg-open; then
        # Linux
        xdg-open "$url"
    elif command_exists start; then
        # Windows (Git Bash)
        start "$url"
    else
        print_warning "Please manually open the following URL in your browser:"
        echo "$url"
    fi

    wait_for_user "Complete the task in your browser, then return here"
}

# Function to check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites"

    # Check if we have basic tools
    if ! command_exists curl && ! command_exists wget; then
        print_warning "Neither curl nor wget found. Some features may not work."
    fi

    print_success "Prerequisites check completed"
    print_warning "This lab requires:"
    echo "  - Google account"
    echo "  - Web browser"
    echo "  - Internet connection"
}

# Function to demonstrate Google Sheets operations (web-based)
demonstrate_sheets() {
    print_step "Google Sheets Lab Demonstration"

    print_warning "This lab is primarily web-based and requires manual interaction"
    echo
    print_warning "The script will open relevant URLs to guide you through the lab"
    echo

    # Step 1: Open sample spreadsheet
    open_url "https://docs.google.com/spreadsheets/d/19iLO-XbrqqWRuqphkXTax0lFn71NW6crJK504JvAxoU/edit#gid=599358521" "Sample Spreadsheet (Task 1)"

    # Step 2: Open Google Drive
    open_url "https://drive.google.com/" "Google Drive (Task 2 & 3)"

    # Step 3: Open Google Sheets app selector
    open_url "https://sheets.google.com" "Google Sheets Home (Task 4)"
}

# Function to show lab structure
show_lab_structure() {
    print_step "Lab Structure Overview"

    echo "GSP469 - Google Sheets: Getting Started"
    echo "====================================="
    echo
    echo "Tasks to complete:"
    echo "1. ✅ Open and copy sample spreadsheet"
    echo "2. ✅ Export data as CSV"
    echo "3. ✅ Import CSV to Google Drive and convert to Sheets"
    echo "4. ✅ Create new spreadsheet and customize"
    echo "5. ✅ Share and collaborate features"
    echo
    print_warning "Most steps require manual completion in the web interface"
}

# Function to show mobile app info
show_mobile_info() {
    print_step "Mobile App Information"

    echo "For mobile access:"
    echo "📱 Android: https://play.google.com/store/apps/details?id=com.google.android.apps.docs.editors.sheets"
    echo "📱 iOS: https://itunes.apple.com/app/google-sheets/id842849113"
    echo
}

# Function to show additional resources
show_resources() {
    print_step "Additional Resources"

    echo "📚 Google Sheets Documentation:"
    echo "   - Official Docs: https://support.google.com/docs/answer/6000292"
    echo "   - Function List: https://support.google.com/docs/table/25273"
    echo "   - Drive Help: https://support.google.com/drive"
    echo "   - Collaboration: https://support.google.com/a/users/answer/9282959"
    echo
}

# Cleanup function (minimal for this lab)
cleanup() {
    print_step "Cleanup"

    print_warning "This lab doesn't create GCP resources that need cleanup"
    print_warning "However, you may want to:"
    echo "  - Delete test spreadsheets you created"
    echo "  - Remove uploaded CSV files from Google Drive"
    echo "  - Clean up local downloaded files"

    print_success "Cleanup guidance provided"
}

# Main function
main() {
    local verbose=false
    local do_cleanup=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose|-v)
                verbose=true
                shift
                ;;
            cleanup)
                do_cleanup=true
                shift
                ;;
            *)
                print_error "Unknown argument: $1"
                echo "Usage: $0 [--verbose|-v] [cleanup]"
                exit 1
                ;;
        esac
    done

    echo "GSP469 - Google Sheets: Getting Started"
    echo "======================================"
    echo

    if $do_cleanup; then
        cleanup
        exit 0
    fi

    # Welcome message
    print_warning "IMPORTANT: This is a web-based lab that requires manual interaction"
    print_warning "The script will open URLs and provide guidance"
    echo
    print_warning "What you'll learn:"
    echo "- Create, update, and customize spreadsheets"
    echo "- Analyze data with Sheets"
    echo "- Share and collaborate on spreadsheets"
    echo "- Access other apps from Sheets"
    echo

    if ! confirm "Do you want to proceed with the guided lab?"; then
        print_warning "Lab cancelled by user"
        exit 0
    fi

    # Run the lab guidance
    check_prerequisites
    show_lab_structure
    demonstrate_sheets
    show_mobile_info
    show_resources

    echo
    print_success "GSP469 Google Sheets lab guidance completed!"
    print_warning "Remember to complete all manual steps in your web browser"
    print_warning "Don't forget to clean up when done: $0 cleanup"
}

# Run main function with all arguments
main "$@"
