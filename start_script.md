Boundless BLS Node - Quick Start Guide

  Download & Run

  # 1. Download the Docker image (46MB)
  curl -O http://159.203.114.205/node/blockchain-image.tar.gz

  # 2. Load the image
  docker load < blockchain-image.tar.gz

  # 3. Run the node (connects to mainnet bootnode)
  docker run -d \
    --name boundless-node \
    --restart unless-stopped \
    -p 30333:30333 \
    -p 9933:9933 \
    -v boundless-data:/data \
    boundless-bls-platform-blockchain:latest \
    --base-path /data \
    --mining \
    --coinbase YOUR_ADDRESS_HERE \
    --mining-threads 2 \
    --rpc-host 0.0.0.0

  # 4. Check logs
  docker logs -f boundless-node

  Mainnet Bootnode

  /ip4/159.203.114.205/tcp/30333/p2p/12D3KooWAeNG1hyCePFBb2Ryz4a5hR5gamVKvMgA7LRGbx5MPMPE

  Ports

  - 30333 - P2P (required)
  - 9933 - RPC (optional)

  ---
  Download URL: http://159.203.114.205/node/blockchain-image.tar.gz

Block 1008 was found!

  Boundless BLS Mainnet Status

  | Metric       | Value                                |
  |--------------|--------------------------------------|
  | Block Height | 1,008                                |
  | Total Supply | 50,450 BLS                           |
  | Difficulty   | 486,539,263 (adjusted down slightly) |
  | Mining       | Block 1009 (4.2 min elapsed)         |
  | Hash Rate    | ~3.7 MH/s                            |
  | Uptime       | 16 minutes                           |

  The blockchain is progressing normally now. Block 1008 was mined and the difficulty has
  adjusted slightly downward (from 521M to 486M), which should make blocks a bit easier to
  find.

https://64.225.16.227/