#!/bin/bash
#
# check-prerequisites.sh
# Checks that the Mac has all prerequisites needed to build, test, and run MenuBar World Clock
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Minimum required versions
MIN_MACOS_VERSION="15.0"
MIN_XCODE_VERSION="16.0"
MIN_SWIFT_VERSION="6.0"

# Track if all checks pass
ALL_PASSED=true

print_header() {
    echo ""
    echo "============================================"
    echo "  MenuBar World Clock - Prerequisite Check"
    echo "============================================"
    echo ""
}

print_result() {
    local name="$1"
    local status="$2"
    local details="$3"

    if [ "$status" = "pass" ]; then
        echo -e "${GREEN}✓${NC} $name: $details"
    elif [ "$status" = "warn" ]; then
        echo -e "${YELLOW}⚠${NC} $name: $details"
    else
        echo -e "${RED}✗${NC} $name: $details"
        ALL_PASSED=false
    fi
}

version_gte() {
    # Returns 0 (true) if $1 >= $2
    [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

check_macos_version() {
    local macos_version
    macos_version=$(sw_vers -productVersion)

    if version_gte "$macos_version" "$MIN_MACOS_VERSION"; then
        print_result "macOS" "pass" "$macos_version (required: $MIN_MACOS_VERSION+)"
    else
        print_result "macOS" "fail" "$macos_version (required: $MIN_MACOS_VERSION+)"
    fi
}

check_xcode_installed() {
    if ! command -v xcodebuild &> /dev/null; then
        print_result "Xcode" "fail" "Not installed"
        return 1
    fi

    local xcode_version
    xcode_version=$(xcodebuild -version 2>/dev/null | head -n1 | awk '{print $2}')

    if [ -z "$xcode_version" ]; then
        print_result "Xcode" "fail" "Unable to determine version"
        return 1
    fi

    if version_gte "$xcode_version" "$MIN_XCODE_VERSION"; then
        print_result "Xcode" "pass" "$xcode_version (required: $MIN_XCODE_VERSION+)"
    else
        print_result "Xcode" "fail" "$xcode_version (required: $MIN_XCODE_VERSION+)"
    fi
}

check_xcode_cli_tools() {
    if xcode-select -p &> /dev/null; then
        local path
        path=$(xcode-select -p)
        print_result "Xcode CLI Tools" "pass" "Installed at $path"
    else
        print_result "Xcode CLI Tools" "fail" "Not installed (run: xcode-select --install)"
    fi
}

check_swift_version() {
    if ! command -v swift &> /dev/null; then
        print_result "Swift" "fail" "Not installed"
        return 1
    fi

    local swift_version
    swift_version=$(swift --version 2>/dev/null | head -n1 | sed -E 's/.*version ([0-9]+\.[0-9]+).*/\1/')

    if [ -z "$swift_version" ]; then
        print_result "Swift" "fail" "Unable to determine version"
        return 1
    fi

    if version_gte "$swift_version" "$MIN_SWIFT_VERSION"; then
        print_result "Swift" "pass" "$swift_version (required: $MIN_SWIFT_VERSION+)"
    else
        print_result "Swift" "fail" "$swift_version (required: $MIN_SWIFT_VERSION+)"
    fi
}

check_git() {
    if command -v git &> /dev/null; then
        local git_version
        git_version=$(git --version | awk '{print $3}')
        print_result "Git" "pass" "$git_version"
    else
        print_result "Git" "warn" "Not installed (optional, needed for version control)"
    fi
}

check_swift_package_manager() {
    if swift package --version &> /dev/null; then
        local spm_version
        spm_version=$(swift package --version 2>/dev/null | head -n1)
        print_result "Swift Package Manager" "pass" "$spm_version"
    else
        print_result "Swift Package Manager" "fail" "Not available"
    fi
}

check_code_signing() {
    # Check if any valid signing identities exist
    local identities
    identities=$(security find-identity -v -p codesigning 2>/dev/null | grep -c "valid identities found" || true)

    if security find-identity -v -p codesigning 2>/dev/null | grep -q "Apple Development\|Mac Developer\|Developer ID"; then
        print_result "Code Signing" "pass" "Development certificate available"
    else
        print_result "Code Signing" "warn" "No development certificate (app will run unsigned locally)"
    fi
}

check_disk_space() {
    # Check for at least 1GB free space
    local free_space_mb
    free_space_mb=$(df -m . | tail -1 | awk '{print $4}')

    if [ "$free_space_mb" -ge 1024 ]; then
        local free_space_gb
        free_space_gb=$(echo "scale=1; $free_space_mb / 1024" | bc)
        print_result "Disk Space" "pass" "${free_space_gb}GB available"
    else
        print_result "Disk Space" "warn" "${free_space_mb}MB available (recommend 1GB+)"
    fi
}

check_architecture() {
    local arch
    arch=$(uname -m)

    if [ "$arch" = "arm64" ]; then
        print_result "Architecture" "pass" "Apple Silicon ($arch)"
    elif [ "$arch" = "x86_64" ]; then
        print_result "Architecture" "pass" "Intel ($arch)"
    else
        print_result "Architecture" "warn" "Unknown architecture: $arch"
    fi
}

test_swift_build() {
    echo ""
    echo "Running build test..."

    # Get the script directory and project root
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root
    project_root="$(dirname "$script_dir")"

    if [ -f "$project_root/Package.swift" ]; then
        if (cd "$project_root" && swift build 2>/dev/null); then
            print_result "Swift Build" "pass" "Project builds successfully"
        else
            print_result "Swift Build" "fail" "Build failed"
        fi
    else
        print_result "Swift Build" "warn" "Package.swift not found, skipping build test"
    fi
}

test_swift_test() {
    echo ""
    echo "Running test suite..."

    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root
    project_root="$(dirname "$script_dir")"

    if [ -f "$project_root/Package.swift" ]; then
        if (cd "$project_root" && swift test 2>/dev/null); then
            print_result "Swift Test" "pass" "All tests pass"
        else
            print_result "Swift Test" "fail" "Tests failed"
        fi
    else
        print_result "Swift Test" "warn" "Package.swift not found, skipping tests"
    fi
}

print_summary() {
    echo ""
    echo "============================================"
    if [ "$ALL_PASSED" = true ]; then
        echo -e "${GREEN}All prerequisite checks passed!${NC}"
        echo "You can build the project with: swift build"
        echo "You can run tests with: swift test"
        echo "You can run the app with: swift run"
    else
        echo -e "${RED}Some prerequisite checks failed.${NC}"
        echo "Please address the issues above before building."
    fi
    echo "============================================"
    echo ""
}

main() {
    print_header

    echo "Checking system requirements..."
    echo ""

    check_macos_version
    check_xcode_installed
    check_xcode_cli_tools
    check_swift_version
    check_swift_package_manager
    check_git
    check_code_signing
    check_disk_space
    check_architecture

    # Optional: run actual build and test
    if [ "${1:-}" = "--test" ] || [ "${1:-}" = "-t" ]; then
        test_swift_build
        test_swift_test
    fi

    print_summary

    if [ "$ALL_PASSED" = true ]; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
