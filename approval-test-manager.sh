#!/bin/bash

# Approval Test Manager for FileOrganizer
# Manages approved/received test output files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPROVED_DIR="$SCRIPT_DIR/ApprovedOutputs"
RECEIVED_DIR="$SCRIPT_DIR/ReceivedOutputs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_usage() {
    echo "📋 Approval Test Manager"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  status     - Show status of all approval tests"
    echo "  approve    - Approve all pending changes"
    echo "  approve <test_name> - Approve specific test"
    echo "  diff       - Show differences for all failed tests"
    echo "  diff <test_name> - Show diff for specific test"
    echo "  clean      - Remove all received files"
    echo "  reset      - Remove all approved files (use with caution)"
    echo "  setup      - Create initial directory structure"
}

setup_directories() {
    echo "🔧 Setting up approval test directories..."
    mkdir -p "$APPROVED_DIR"
    mkdir -p "$RECEIVED_DIR"
    echo "✅ Directories created:"
    echo "   📁 $APPROVED_DIR"
    echo "   📁 $RECEIVED_DIR"
}

show_status() {
    echo "📊 Approval Test Status"
    echo "======================"
    
    if [[ ! -d "$RECEIVED_DIR" ]]; then
        echo "🟢 No pending changes (no received files)"
        return 0
    fi
    
    local pending_count=0
    local approved_count=0
    
    # Check for received files (pending approval)
    if [[ -d "$RECEIVED_DIR" && $(ls -A "$RECEIVED_DIR" 2>/dev/null) ]]; then
        echo ""
        echo -e "${YELLOW}⏳ Pending Approval:${NC}"
        for received_file in "$RECEIVED_DIR"/*.received.txt; do
            if [[ -f "$received_file" ]]; then
                local test_name=$(basename "$received_file" .received.txt)
                echo "   📄 $test_name"
                ((pending_count++))
            fi
        done
    fi
    
    # Check approved files
    if [[ -d "$APPROVED_DIR" && $(ls -A "$APPROVED_DIR" 2>/dev/null) ]]; then
        echo ""
        echo -e "${GREEN}✅ Approved Tests:${NC}"
        for approved_file in "$APPROVED_DIR"/*.approved.txt; do
            if [[ -f "$approved_file" ]]; then
                local test_name=$(basename "$approved_file" .approved.txt)
                echo "   📄 $test_name"
                ((approved_count++))
            fi
        done
    fi
    
    echo ""
    echo "Summary: $approved_count approved, $pending_count pending"
    
    if [[ $pending_count -gt 0 ]]; then
        echo ""
        echo -e "${BLUE}💡 Run './approval-test-manager.sh approve' to approve all changes${NC}"
        echo -e "${BLUE}💡 Run './approval-test-manager.sh diff' to see what changed${NC}"
    fi
}

show_diff() {
    local test_name="$1"
    
    if [[ -n "$test_name" ]]; then
        # Show diff for specific test
        local received_file="$RECEIVED_DIR/${test_name}.received.txt"
        local approved_file="$APPROVED_DIR/${test_name}.approved.txt"
        
        if [[ ! -f "$received_file" ]]; then
            echo "❌ No received file found for test: $test_name"
            return 1
        fi
        
        if [[ ! -f "$approved_file" ]]; then
            echo "📝 New test: $test_name"
            echo "Content:"
            cat "$received_file"
            return 0
        fi
        
        echo "📊 Diff for test: $test_name"
        echo "================================"
        if command -v diff &> /dev/null; then
            diff -u "$approved_file" "$received_file" || true
        else
            echo "⚠️  diff command not available, showing file contents:"
            echo ""
            echo "APPROVED:"
            cat "$approved_file"
            echo ""
            echo "RECEIVED:"
            cat "$received_file"
        fi
    else
        # Show diff for all tests
        local has_diffs=false
        
        for received_file in "$RECEIVED_DIR"/*.received.txt; do
            if [[ -f "$received_file" ]]; then
                local test_name=$(basename "$received_file" .received.txt)
                echo ""
                show_diff "$test_name"
                has_diffs=true
            fi
        done
        
        if [[ "$has_diffs" == false ]]; then
            echo "🟢 No pending changes to show"
        fi
    fi
}

approve_changes() {
    local test_name="$1"
    
    if [[ -n "$test_name" ]]; then
        # Approve specific test
        local received_file="$RECEIVED_DIR/${test_name}.received.txt"
        local approved_file="$APPROVED_DIR/${test_name}.approved.txt"
        
        if [[ ! -f "$received_file" ]]; then
            echo "❌ No received file found for test: $test_name"
            return 1
        fi
        
        cp "$received_file" "$approved_file"
        rm "$received_file"
        echo "✅ Approved test: $test_name"
    else
        # Approve all tests
        local approved_count=0
        
        for received_file in "$RECEIVED_DIR"/*.received.txt; do
            if [[ -f "$received_file" ]]; then
                local test_name=$(basename "$received_file" .received.txt)
                local approved_file="$APPROVED_DIR/${test_name}.approved.txt"
                
                cp "$received_file" "$approved_file"
                rm "$received_file"
                echo "✅ Approved: $test_name"
                ((approved_count++))
            fi
        done
        
        if [[ $approved_count -eq 0 ]]; then
            echo "🟢 No pending changes to approve"
        else
            echo ""
            echo "🎉 Approved $approved_count test(s)"
        fi
    fi
}

clean_received() {
    echo "🧹 Cleaning received files..."
    if [[ -d "$RECEIVED_DIR" ]]; then
        rm -rf "$RECEIVED_DIR"/*.received.txt 2>/dev/null || true
        echo "✅ Received files cleaned"
    else
        echo "🟢 No received files to clean"
    fi
}

reset_approved() {
    echo "⚠️  This will remove ALL approved baselines!"
    echo "   You will need to re-run tests to recreate them."
    echo ""
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing approved files..."
        if [[ -d "$APPROVED_DIR" ]]; then
            rm -rf "$APPROVED_DIR"/*.approved.txt 2>/dev/null || true
            echo "✅ Approved files removed"
        else
            echo "🟢 No approved files to remove"
        fi
    else
        echo "❌ Reset cancelled"
    fi
}

# Main command handling
case "$1" in
    "status"|"")
        show_status
        ;;
    "approve")
        approve_changes "$2"
        ;;
    "diff")
        show_diff "$2"
        ;;
    "clean")
        clean_received
        ;;
    "reset")
        reset_approved
        ;;
    "setup")
        setup_directories
        ;;
    *)
        show_usage
        exit 1
        ;;
esac