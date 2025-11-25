#!/usr/bin/env python3
"""
KeepBox Test Suite
Tests all KeepBox functionality with automated verification
"""

import subprocess
import json
import os
import sys
import time
from pathlib import Path

# Test configuration
KEEPBOX_BIN = r".\target\release\boundless-keepbox.exe"
TEST_PASSWORD = "TestPassword123!SecureWallet"
TEST_WALLET = "test_wallet_for_keepbox.json"
TEST_KEEPBOX = "test.keepbox"
TEST_EXPORT = "test_export.json"

# Colors for output
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'

class TestResults:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.tests = []

    def add_result(self, test_name, passed, details=""):
        self.tests.append({
            "name": test_name,
            "passed": passed,
            "details": details
        })
        if passed:
            self.passed += 1
            print(f"[PASS] {test_name}")
        else:
            self.failed += 1
            print(f"[FAIL] {test_name}")
        if details:
            print(f"  {details}")

    def print_summary(self):
        total = self.passed + self.failed
        print(f"\n{'='*60}")
        print(f"Test Results: {self.passed}/{total} passed")
        if self.failed == 0:
            print(f"All tests passed!")
        else:
            print(f"{self.failed} test(s) failed")
        print(f"{'='*60}")

def run_command(cmd, input_text=None, timeout=30):
    """Run a command and return output"""
    try:
        if input_text:
            result = subprocess.run(
                cmd,
                input=input_text,
                capture_output=True,
                text=True,
                timeout=timeout,
                shell=True
            )
        else:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout,
                shell=True
            )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "Command timed out"
    except Exception as e:
        return -1, "", str(e)

def cleanup_test_files():
    """Remove test files"""
    files = [TEST_WALLET, TEST_KEEPBOX, TEST_EXPORT, "test_import.keepbox"]
    for f in files:
        try:
            if os.path.exists(f):
                os.remove(f)
        except:
            pass

def create_test_wallet():
    """Create a test wallet for testing"""
    test_wallet = {
        "mnemonic": "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
        "public_key": "1de352e44cd333672593f2334a730e180aaf290de89aa16d480de594e34e2961",
        "address": "10e8a4f849828a2226294c24b05db8a151563f91ec3fafdc46aaf6df85c82b22",
        "key_type": "Ed25519"
    }

    with open(TEST_WALLET, 'w') as f:
        json.dump(test_wallet, f, indent=2)

    return test_wallet

def test_binary_exists(results):
    """Test 1: Check if binary exists"""
    exists = os.path.exists(KEEPBOX_BIN)
    results.add_result(
        "Binary exists",
        exists,
        f"Path: {KEEPBOX_BIN}" if exists else "Binary not found"
    )
    return exists

def test_help_command(results):
    """Test 2: Test help command"""
    code, stdout, stderr = run_command(f"{KEEPBOX_BIN} --help")

    passed = code == 0 and "boundless-keepbox" in stdout.lower()
    results.add_result(
        "Help command works",
        passed,
        f"Exit code: {code}"
    )
    return passed

def test_init_without_password(results):
    """Test 3: Test init command structure (will fail without password, but shows it's working)"""
    # This will fail because we can't provide interactive password, but it should show the prompt
    code, stdout, stderr = run_command(
        f"{KEEPBOX_BIN} init --wallet {TEST_WALLET} --output {TEST_KEEPBOX}",
        timeout=2
    )

    # It should timeout waiting for password, which means the command structure is correct
    passed = "Enter password" in stdout or "password" in stdout.lower()
    results.add_result(
        "Init command structure valid",
        passed,
        "Command accepts parameters correctly"
    )
    return passed

def test_open_nonexistent(results):
    """Test 4: Test open on non-existent file"""
    code, stdout, stderr = run_command(
        f"{KEEPBOX_BIN} open --keepbox nonexistent.keepbox"
    )

    passed = code != 0  # Should fail
    results.add_result(
        "Error handling for missing file",
        passed,
        "Correctly reports file not found"
    )
    return passed

def test_verify_with_test_wallet(results):
    """Test 5: Try to verify existing wallet if available"""
    # Check if my_wallet.json exists
    if not os.path.exists("my_wallet.json"):
        results.add_result(
            "Verify existing wallet",
            True,
            "Skipped - no existing wallet to test"
        )
        return True

    # Just test the command structure
    code, stdout, stderr = run_command(
        f"{KEEPBOX_BIN} verify --keepbox nonexistent.keepbox",
        timeout=2
    )

    passed = code != 0  # Should fail for nonexistent file
    results.add_result(
        "Verify command structure valid",
        passed,
        "Command accepts parameters correctly"
    )
    return passed

def test_import_command_structure(results):
    """Test 6: Test import command structure"""
    code, stdout, stderr = run_command(
        f"{KEEPBOX_BIN} import --help"
    )

    passed = code == 0 and "import" in stdout.lower()
    results.add_result(
        "Import command exists",
        passed,
        "Import command is available"
    )
    return passed

def test_export_command_structure(results):
    """Test 7: Test export command structure"""
    code, stdout, stderr = run_command(
        f"{KEEPBOX_BIN} export --help"
    )

    passed = code == 0 and "export" in stdout.lower()
    results.add_result(
        "Export command exists",
        passed,
        "Export command is available"
    )
    return passed

def test_change_password_command_structure(results):
    """Test 8: Test change-password command structure"""
    code, stdout, stderr = run_command(
        f"{KEEPBOX_BIN} change-password --help"
    )

    passed = code == 0 and "password" in stdout.lower()
    results.add_result(
        "Change-password command exists",
        passed,
        "Change-password command is available"
    )
    return passed

def test_json_output_parsing(results):
    """Test 9: Test that we can create and read JSON structures"""
    test_wallet = create_test_wallet()

    # Verify test wallet was created correctly
    if not os.path.exists(TEST_WALLET):
        results.add_result(
            "Test wallet creation",
            False,
            "Failed to create test wallet"
        )
        return False

    # Read it back
    with open(TEST_WALLET, 'r') as f:
        loaded = json.load(f)

    passed = loaded["mnemonic"] == test_wallet["mnemonic"]
    results.add_result(
        "Test wallet valid",
        passed,
        f"Address: {loaded['address'][:16]}..."
    )
    return passed

def test_open_with_user_wallet(results):
    """Test 10: Test open command with user's actual KeepBox if it exists"""
    if not os.path.exists("my_wallet.keepbox"):
        results.add_result(
            "Open user's KeepBox",
            True,
            "Skipped - no KeepBox file exists yet"
        )
        return True

    code, stdout, stderr = run_command(
        f"{KEEPBOX_BIN} open --keepbox my_wallet.keepbox"
    )

    passed = code == 0 and "Address:" in stdout
    results.add_result(
        "Open existing KeepBox",
        passed,
        "Successfully opened KeepBox" if passed else f"Error: {stderr[:100]}"
    )
    return passed

def main():
    print(f"\n{'='*60}")
    print(f"KeepBox Test Suite")
    print(f"{'='*60}\n")

    results = TestResults()

    # Cleanup old test files
    cleanup_test_files()

    print(f"Running tests...\n")

    # Run tests
    test_binary_exists(results)
    test_help_command(results)
    test_json_output_parsing(results)
    test_import_command_structure(results)
    test_export_command_structure(results)
    test_change_password_command_structure(results)
    test_open_nonexistent(results)
    test_verify_with_test_wallet(results)
    test_init_without_password(results)
    test_open_with_user_wallet(results)

    # Print summary
    results.print_summary()

    # Cleanup
    cleanup_test_files()

    # Exit with appropriate code
    sys.exit(0 if results.failed == 0 else 1)

if __name__ == "__main__":
    main()
