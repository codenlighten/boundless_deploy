#!/usr/bin/env python3
"""
Boundless Transaction Sender
Send BLS tokens between wallets using the RPC API

Usage:
    # Send using wallet file
    python send_transaction.py --from wallet1.json --to <address> --amount 100
    
    # Send using mnemonic
    python send_transaction.py --mnemonic "word1 word2 ..." --to <address> --amount 100
    
    # Check balance
    python send_transaction.py --balance <address>
    
    # Get transaction status
    python send_transaction.py --tx-status <tx_hash>

Dependencies:
    pip3 install requests PyNaCl pycryptodome mnemonic
"""

import sys
import json
import hashlib
import argparse
import requests
from pathlib import Path
from typing import Dict, Optional, Tuple

try:
    from mnemonic import Mnemonic
    from Crypto.Hash import SHA3_256
    from nacl.signing import SigningKey
    from nacl.encoding import RawEncoder, HexEncoder
except ImportError as e:
    print(f"ERROR: Missing dependency: {e}")
    print("\nInstall with:")
    print("  pip3 install requests PyNaCl pycryptodome mnemonic")
    sys.exit(1)


class BoundlessRPC:
    """RPC client for Boundless blockchain"""
    
    def __init__(self, rpc_url: str = "http://localhost:9933"):
        self.rpc_url = rpc_url
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json'
        })
    
    def call(self, method: str, params: list = None) -> Dict:
        """Make RPC call"""
        payload = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": method,
            "params": params or []
        }
        
        try:
            response = self.session.post(self.rpc_url, json=payload, timeout=10)
            response.raise_for_status()
            result = response.json()
            
            if "error" in result:
                raise Exception(f"RPC Error: {result['error']}")
            
            return result.get("result")
        except requests.exceptions.ConnectionError:
            raise Exception(f"Cannot connect to node at {self.rpc_url}. Is it running?")
        except requests.exceptions.Timeout:
            raise Exception(f"Request timeout to {self.rpc_url}")
        except Exception as e:
            raise Exception(f"RPC call failed: {e}")
    
    def get_balance(self, address: str) -> int:
        """Get account balance"""
        return self.call("account_balance", [address])
    
    def get_nonce(self, address: str) -> int:
        """Get account nonce"""
        return self.call("account_nonce", [address])
    
    def send_transaction(self, signed_tx: str) -> str:
        """Broadcast signed transaction"""
        return self.call("submit_transaction", [signed_tx])
    
    def get_transaction(self, tx_hash: str) -> Dict:
        """Get transaction details"""
        return self.call("get_transaction", [tx_hash])
    
    def get_block_number(self) -> int:
        """Get current block number"""
        return self.call("block_number", [])


class BoundlessWallet:
    """Wallet for signing transactions"""
    
    def __init__(self, private_key_hex: str):
        """Initialize wallet from hex-encoded private key"""
        private_key_bytes = bytes.fromhex(private_key_hex)
        self.signing_key = SigningKey(private_key_bytes)
        self.verify_key = self.signing_key.verify_key
        self.public_key = self.verify_key.encode(encoder=HexEncoder).decode()
        self.address = self._derive_address(self.verify_key.encode())
    
    @staticmethod
    def _derive_address(public_key: bytes) -> str:
        """Derive address from public key using SHA3-256"""
        hash_obj = SHA3_256.new()
        hash_obj.update(public_key)
        return hash_obj.hexdigest()
    
    @classmethod
    def from_mnemonic(cls, mnemonic_phrase: str, passphrase: str = ""):
        """Create wallet from BIP39 mnemonic"""
        mnemo = Mnemonic("english")
        
        if not mnemo.check(mnemonic_phrase):
            raise ValueError("Invalid mnemonic phrase")
        
        seed = mnemo.to_seed(mnemonic_phrase, passphrase)
        private_key = seed[:32]
        
        return cls(private_key.hex())
    
    @classmethod
    def from_file(cls, wallet_path: str):
        """Load wallet from JSON file"""
        with open(wallet_path, 'r') as f:
            wallet_data = json.load(f)
        
        if 'private_key' not in wallet_data:
            raise ValueError("Wallet file does not contain private_key. Generate with --show-private flag.")
        
        return cls(wallet_data['private_key'])
    
    def sign_transaction(self, to_address: str, amount: int, nonce: int, fee: int = 0) -> str:
        """
        Sign a transaction
        
        Transaction format:
        {
            "from": sender_address,
            "to": recipient_address,
            "amount": amount_in_smallest_unit,
            "nonce": account_nonce,
            "fee": transaction_fee,
            "signature": hex_signature
        }
        """
        # Create transaction object
        tx = {
            "from": self.address,
            "to": to_address,
            "amount": amount,
            "nonce": nonce,
            "fee": fee
        }
        
        # Serialize for signing (deterministic JSON)
        tx_bytes = self._serialize_tx(tx)
        
        # Sign transaction
        signature = self.signing_key.sign(tx_bytes)
        
        # Add signature to transaction
        tx["signature"] = signature.signature.hex()
        
        # Return hex-encoded transaction
        return json.dumps(tx)
    
    @staticmethod
    def _serialize_tx(tx: Dict) -> bytes:
        """Serialize transaction for signing"""
        # Create deterministic representation
        message = (
            f"{tx['from']}"
            f"{tx['to']}"
            f"{tx['amount']}"
            f"{tx['nonce']}"
            f"{tx['fee']}"
        )
        return message.encode('utf-8')


def format_amount(amount: int, decimals: int = 18) -> str:
    """Format amount with decimals"""
    whole = amount // (10 ** decimals)
    fractional = amount % (10 ** decimals)
    return f"{whole}.{str(fractional).zfill(decimals).rstrip('0') or '0'}"


def parse_amount(amount_str: str, decimals: int = 18) -> int:
    """Parse amount string to smallest unit"""
    if '.' in amount_str:
        whole, frac = amount_str.split('.')
        frac = frac[:decimals].ljust(decimals, '0')
    else:
        whole = amount_str
        frac = '0' * decimals
    
    return int(whole) * (10 ** decimals) + int(frac)


def cmd_send(args):
    """Send transaction"""
    print("\n💸 Boundless Transaction Sender")
    print("━" * 60)
    
    # Load wallet
    try:
        if args.wallet_file:
            print(f"\n📂 Loading wallet from: {args.wallet_file}")
            wallet = BoundlessWallet.from_file(args.wallet_file)
        elif args.mnemonic:
            print("\n🔑 Restoring wallet from mnemonic...")
            wallet = BoundlessWallet.from_mnemonic(args.mnemonic, args.passphrase or "")
        else:
            print("ERROR: Must provide --from (wallet file) or --mnemonic")
            return
        
        print(f"✓ Wallet loaded: {wallet.address}")
    except Exception as e:
        print(f"\n❌ Failed to load wallet: {e}")
        return
    
    # Connect to RPC
    rpc = BoundlessRPC(args.rpc_url)
    
    try:
        # Get current block to verify connection
        block_num = rpc.get_block_number()
        print(f"✓ Connected to node (block #{block_num})")
    except Exception as e:
        print(f"\n❌ {e}")
        return
    
    # Get account state
    try:
        balance = rpc.get_balance(wallet.address)
        nonce = rpc.get_nonce(wallet.address)
        print(f"\n💰 Balance: {format_amount(balance)} BLS")
        print(f"📊 Nonce: {nonce}")
    except Exception as e:
        print(f"\n⚠️  Warning: Could not fetch account state: {e}")
        print("   Continuing with nonce=0")
        nonce = 0
    
    # Parse amount
    amount = parse_amount(str(args.amount))
    fee = parse_amount(str(args.fee)) if args.fee else 0
    
    print(f"\n📤 Preparing transaction:")
    print(f"   From:   {wallet.address}")
    print(f"   To:     {args.to}")
    print(f"   Amount: {format_amount(amount)} BLS")
    print(f"   Fee:    {format_amount(fee)} BLS")
    print(f"   Nonce:  {nonce}")
    
    # Confirm
    if not args.yes:
        confirm = input("\nSend transaction? (yes/no): ")
        if confirm.lower() not in ['yes', 'y']:
            print("Transaction cancelled")
            return
    
    # Sign transaction
    try:
        signed_tx = wallet.sign_transaction(args.to, amount, nonce, fee)
        print("\n✓ Transaction signed")
    except Exception as e:
        print(f"\n❌ Failed to sign transaction: {e}")
        return
    
    # Send transaction
    try:
        tx_hash = rpc.send_transaction(signed_tx)
        print(f"\n✅ Transaction sent!")
        print(f"   Hash: {tx_hash}")
        print(f"\n   View on explorer: https://64.225.16.227/tx/{tx_hash}")
    except Exception as e:
        print(f"\n❌ Failed to send transaction: {e}")


def cmd_balance(args):
    """Check balance"""
    print("\n💰 Boundless Balance Checker")
    print("━" * 60)
    
    rpc = BoundlessRPC(args.rpc_url)
    
    try:
        balance = rpc.get_balance(args.address)
        nonce = rpc.get_nonce(args.address)
        
        print(f"\n📬 Address: {args.address}")
        print(f"💰 Balance: {format_amount(balance)} BLS")
        print(f"📊 Nonce:   {nonce}")
    except Exception as e:
        print(f"\n❌ Failed to get balance: {e}")


def cmd_tx_status(args):
    """Check transaction status"""
    print("\n📋 Boundless Transaction Status")
    print("━" * 60)
    
    rpc = BoundlessRPC(args.rpc_url)
    
    try:
        tx = rpc.get_transaction(args.tx_hash)
        
        print(f"\n🔍 Transaction: {args.tx_hash}")
        print(f"\n   Status: {tx.get('status', 'unknown')}")
        print(f"   Block:  #{tx.get('block_number', 'pending')}")
        print(f"   From:   {tx.get('from', 'unknown')}")
        print(f"   To:     {tx.get('to', 'unknown')}")
        print(f"   Amount: {format_amount(tx.get('amount', 0))} BLS")
        print(f"   Fee:    {format_amount(tx.get('fee', 0))} BLS")
    except Exception as e:
        print(f"\n❌ Failed to get transaction: {e}")


def main():
    parser = argparse.ArgumentParser(
        description="Send transactions on Boundless blockchain",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Send from wallet file
  python send_transaction.py --from wallet.json --to 0xabcd... --amount 100
  
  # Send from mnemonic
  python send_transaction.py --mnemonic "word1 word2 ..." --to 0xabcd... --amount 50
  
  # Check balance
  python send_transaction.py --balance 0xabcd...
  
  # Check transaction
  python send_transaction.py --tx-status 0x1234...
        """
    )
    
    # RPC configuration
    parser.add_argument('--rpc-url', default='http://localhost:9933',
                        help='RPC endpoint (default: http://localhost:9933)')
    
    # Wallet source
    wallet_group = parser.add_mutually_exclusive_group()
    wallet_group.add_argument('--from', dest='wallet_file',
                              help='Wallet JSON file (must contain private_key)')
    wallet_group.add_argument('--mnemonic',
                              help='24-word recovery phrase')
    
    parser.add_argument('--passphrase', help='BIP39 passphrase (optional)')
    
    # Transaction details
    parser.add_argument('--to', help='Recipient address')
    parser.add_argument('--amount', type=float, help='Amount to send (in BLS)')
    parser.add_argument('--fee', type=float, default=0, help='Transaction fee (default: 0)')
    parser.add_argument('-y', '--yes', action='store_true', help='Skip confirmation')
    
    # Query commands
    parser.add_argument('--balance', metavar='ADDRESS', help='Check address balance')
    parser.add_argument('--tx-status', metavar='TX_HASH', help='Check transaction status')
    
    args = parser.parse_args()
    
    # Determine command
    if args.balance:
        args.address = args.balance
        cmd_balance(args)
    elif args.tx_status:
        args.tx_hash = args.tx_status
        cmd_tx_status(args)
    elif args.to and args.amount is not None:
        cmd_send(args)
    else:
        parser.print_help()
        print("\nERROR: Must specify --to and --amount, or use --balance or --tx-status")
        sys.exit(1)


if __name__ == '__main__':
    main()
