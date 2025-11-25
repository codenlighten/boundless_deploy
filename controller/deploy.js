#!/usr/bin/env node

/**
 * Boundless Node Controller
 * Lumenbridge-compliant node orchestration for blockchain miners
 * 
 * Loads cluster.json, validates against schemas, and deploys nodes
 */

const fs = require('fs').promises;
const path = require('path');
const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);

// Configuration
const CLUSTER_FILE = path.join(__dirname, '../cluster.json');
const SCHEMAS_DIR = path.join(__dirname, '../schemas');
const IMAGE_URL = 'http://159.203.114.205/node/blockchain-image.tar.gz';

class BoundlessNodeController {
  constructor() {
    this.cluster = null;
    this.schemas = {};
  }

  /**
   * Load and validate cluster configuration
   */
  async loadCluster() {
    console.log('Loading cluster configuration...');
    const clusterData = await fs.readFile(CLUSTER_FILE, 'utf8');
    this.cluster = JSON.parse(clusterData);
    
    console.log(`✓ Loaded cluster: ${this.cluster.clusterId}`);
    console.log(`  Environment: ${this.cluster.environment}`);
    console.log(`  Nodes: ${this.cluster.nodes.length}`);
    return this.cluster;
  }

  /**
   * Load JSON schemas for validation
   */
  async loadSchemas() {
    console.log('\nLoading schemas...');
    const schemaFiles = await fs.readdir(SCHEMAS_DIR);
    
    for (const file of schemaFiles) {
      if (file.endsWith('.schema.json')) {
        const schemaPath = path.join(SCHEMAS_DIR, file);
        const schemaData = await fs.readFile(schemaPath, 'utf8');
        this.schemas[file] = JSON.parse(schemaData);
        console.log(`✓ Loaded schema: ${file}`);
      }
    }
  }

  /**
   * Generate or validate wallet address
   */
  async setupWalletAddress(node) {
    const { mining } = node.blockchainConfig || {};
    
    if (!mining || !mining.enabled) {
      return null; // Not a mining node
    }

    // Check if address is already configured
    if (mining.coinbase && mining.coinbase !== 'YOUR_ADDRESS_HERE') {
      console.log(`✓ Using configured address: ${mining.coinbase.substring(0, 16)}...`);
      return mining.coinbase;
    }

    // Offer to generate new wallet
    console.log('\n⚠ Mining address not configured');
    console.log('\nOptions:');
    console.log('  1. Generate new wallet automatically');
    console.log('  2. Configure address manually in cluster.json');
    console.log('  3. Exit and configure later');
    
    // For automated deployments, check environment variable
    const AUTO_GENERATE = process.env.AUTO_GENERATE_WALLET === 'true';
    
    if (AUTO_GENERATE) {
      console.log('\n📝 AUTO_GENERATE_WALLET=true detected');
      return await this.generateWallet(node.id);
    }

    // Interactive mode would require readline here
    // For now, throw error to force configuration
    throw new Error(
      `Node ${node.id}: Mining address not configured. ` +
      `Set blockchainConfig.mining.coinbase in your node spec or cluster.json`
    );
  }

  /**
   * Generate new wallet using keygen script
   */
  async generateWallet(nodeId) {
    console.log(`\n${'='.repeat(60)}`);
    console.log('Generating New Wallet');
    console.log(`${'='.repeat(60)}`);

    const keygenScript = path.join(__dirname, '../keygen/boundless_wallet_gen.py');
    const walletFile = `wallet_${nodeId}_${Date.now()}.json`;

    try {
      // Check if keygen script exists
      await fs.access(keygenScript);
    } catch {
      throw new Error(`Keygen script not found: ${keygenScript}`);
    }

    try {
      // Check Python dependencies
      await execAsync('python3 -c "import mnemonic, Crypto.Hash, nacl"');
    } catch {
      console.log('Installing Python dependencies...');
      await execAsync('pip3 install mnemonic PyNaCl pycryptodome');
    }

    // Generate wallet
    console.log('Generating wallet...');
    const { stdout } = await execAsync(
      `python3 ${keygenScript} generate --output ${walletFile}`
    );

    // Read wallet file
    const walletData = JSON.parse(await fs.readFile(walletFile, 'utf8'));
    
    console.log('\n✓ Wallet generated successfully');
    console.log(`\n📬 Address: ${walletData.address}`);
    console.log(`💾 Saved to: ${walletFile}`);
    console.log('\n🔐 IMPORTANT: Save your recovery phrase from the wallet file!');
    console.log(`   Mnemonic: ${walletData.mnemonic.substring(0, 50)}...`);
    console.log('\n⚠️  Write it down and store securely before continuing!');

    return walletData.address;
  }

  /**
   * Validate node configuration
   */
  validateNode(node) {
    console.log(`\nValidating node: ${node.id}`);
    
    // Basic required field validation
    const required = ['id', 'role', 'image', 'hubConnection'];
    for (const field of required) {
      if (!node[field]) {
        throw new Error(`Node ${node.id}: Missing required field '${field}'`);
      }
    }

    // Security hardening checks
    if (node.security) {
      if (!node.security.runAsUser || node.security.runAsUser === 0) {
        console.warn(`⚠ Node ${node.id}: Running as root (not recommended)`);
      }
      
      if (node.security.allowPrivilegeEscalation) {
        console.warn(`⚠ Node ${node.id}: Privilege escalation allowed`);
      }
    }

    // Blockchain-specific validation (address will be checked/generated later)
    if (node.role === 'blockchain-miner' && !node.blockchainConfig) {
      throw new Error(`Node ${node.id}: blockchain-miner role requires blockchainConfig`);
    }

    console.log(`✓ Node ${node.id} validated`);
    return true;
  }

  /**
   * Check Docker availability
   */
  async checkDocker() {
    try {
      await execAsync('docker info');
      console.log('✓ Docker is available');
      return true;
    } catch (error) {
      throw new Error('Docker is not running or not installed');
    }
  }

  /**
   * Download and load blockchain image
   */
  async loadBlockchainImage() {
    console.log('\nPreparing blockchain image...');
    const imageFile = 'blockchain-image.tar.gz';
    
    try {
      // Check if image already exists
      const { stdout } = await execAsync('docker images --format "{{.Repository}}:{{.Tag}}"');
      if (stdout.includes('boundless-bls-platform-blockchain:latest')) {
        console.log('✓ Image already loaded');
        return;
      }
    } catch (error) {
      // Image not found, continue with download
    }

    // Download image
    try {
      await fs.access(imageFile);
      console.log('✓ Image file exists, skipping download');
    } catch {
      console.log(`Downloading image from ${IMAGE_URL}...`);
      await execAsync(`curl -O ${IMAGE_URL}`);
      console.log('✓ Image downloaded');
    }

    // Load image
    console.log('Loading Docker image...');
    await execAsync(`docker load < ${imageFile}`);
    console.log('✓ Image loaded');
  }

  /**
   * Generate Docker run command from node spec
   */
  generateDockerCommand(node) {
    const cmd = ['docker run -d'];
    
    // Container name
    cmd.push(`--name ${node.id}`);
    
    // Restart policy
    if (node.updatePolicy?.autoRestartOnFailure) {
      cmd.push('--restart unless-stopped');
    }

    // Security settings
    if (node.security) {
      if (node.security.runAsUser) {
        cmd.push(`--user ${node.security.runAsUser}:${node.security.runAsGroup || node.security.runAsUser}`);
      }
      if (node.security.readOnlyRootFilesystem) {
        cmd.push('--read-only');
      }
      if (node.security.capabilities?.drop) {
        for (const cap of node.security.capabilities.drop) {
          cmd.push(`--cap-drop=${cap}`);
        }
      }
    }

    // Resources
    if (node.resources) {
      if (node.resources.cpu?.limit) {
        cmd.push(`--cpus=${node.resources.cpu.limit}`);
      }
      if (node.resources.memory?.limitMiB) {
        cmd.push(`--memory=${node.resources.memory.limitMiB}m`);
      }
    }

    // Networks
    if (node.networks && node.networks.length > 0) {
      for (const network of node.networks) {
        cmd.push(`--network ${network.name}`);
        if (network.aliases) {
          for (const alias of network.aliases) {
            cmd.push(`--network-alias ${alias}`);
          }
        }
      }
    }

    // Ports (blockchain-specific)
    if (node.blockchainConfig?.network) {
      const { p2pPort, rpcPort } = node.blockchainConfig.network;
      cmd.push(`-p ${p2pPort}:${p2pPort}`);
      cmd.push(`-p ${rpcPort}:${rpcPort}`);
      
      if (node.metrics?.enabled && node.metrics.port) {
        cmd.push(`-p ${node.metrics.port}:${node.metrics.port}`);
      }
    }

    // Volumes
    if (node.volumes) {
      for (const volume of node.volumes) {
        const volumeStr = volume.hostPath 
          ? `${volume.hostPath}:${volume.mountPath}`
          : `${volume.name}:${volume.mountPath}`;
        cmd.push(`-v ${volumeStr}${volume.readOnly ? ':ro' : ''}`);
      }
    }

    // Environment variables
    if (node.env) {
      for (const envVar of node.env) {
        if (envVar.value) {
          cmd.push(`-e ${envVar.name}="${envVar.value}"`);
        } else if (envVar.valueFromSecret) {
          // In production, load from secret manager
          const secretValue = process.env[envVar.valueFromSecret] || '';
          cmd.push(`-e ${envVar.name}="${secretValue}"`);
        }
      }
    }

    // Logging
    if (node.logging) {
      if (node.logging.driver) {
        cmd.push(`--log-driver ${node.logging.driver}`);
      }
      if (node.logging.maxSize) {
        cmd.push(`--log-opt max-size=${node.logging.maxSize}`);
      }
      if (node.logging.maxFiles) {
        cmd.push(`--log-opt max-file=${node.logging.maxFiles}`);
      }
    }

    // Image
    cmd.push(`${node.image.repository}:${node.image.tag}`);

    // Blockchain-specific args
    if (node.blockchainConfig) {
      const { mining, network, storage } = node.blockchainConfig;
      
      if (storage?.basePath) {
        cmd.push(`--base-path ${storage.basePath}`);
      }
      
      if (mining?.enabled) {
        cmd.push('--mining');
        if (mining.coinbase) {
          cmd.push(`--coinbase ${mining.coinbase}`);
        }
        if (mining.threads) {
          cmd.push(`--mining-threads ${mining.threads}`);
        }
      }
      
      if (network?.rpcHost) {
        cmd.push(`--rpc-host ${network.rpcHost}`);
      }
    }

    return cmd.join(' \\\n  ');
  }

  /**
   * Deploy a single node
   */
  async deployNode(node) {
    console.log(`\n${'='.repeat(60)}`);
    console.log(`Deploying node: ${node.id}`);
    console.log(`Role: ${node.role}`);
    console.log(`${'='.repeat(60)}`);

    // Validate node
    this.validateNode(node);

    // Setup wallet address if this is a mining node
    if (node.role === 'blockchain-miner') {
      const address = await this.setupWalletAddress(node);
      if (address && node.blockchainConfig && node.blockchainConfig.mining) {
        // Update node config with generated/validated address
        node.blockchainConfig.mining.coinbase = address;
      }
    }

    // Check if container exists
    try {
      const { stdout } = await execAsync(`docker ps -a --format "{{.Names}}" | grep "^${node.id}$"`);
      if (stdout.trim()) {
        console.log(`⚠ Container ${node.id} already exists`);
        console.log('Stopping and removing existing container...');
        await execAsync(`docker stop ${node.id} || true`);
        await execAsync(`docker rm ${node.id} || true`);
      }
    } catch (error) {
      // Container doesn't exist, continue
    }

    // Create network if needed
    if (node.networks && node.networks.length > 0) {
      for (const network of node.networks) {
        try {
          await execAsync(`docker network inspect ${network.name}`);
          console.log(`✓ Network ${network.name} exists`);
        } catch {
          console.log(`Creating network: ${network.name}`);
          await execAsync(`docker network create ${network.name}`);
          console.log(`✓ Network ${network.name} created`);
        }
      }
    }

    // Generate and execute Docker command
    const dockerCmd = this.generateDockerCommand(node);
    console.log('\nDocker command:');
    console.log(dockerCmd);
    console.log('');

    try {
      const { stdout, stderr } = await execAsync(dockerCmd);
      console.log(`✓ Container ${node.id} started`);
      if (stdout) console.log(`Container ID: ${stdout.trim()}`);
      if (stderr) console.log(`Warnings: ${stderr}`);
      
      // Wait a moment for container to start
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Check container status
      const { stdout: status } = await execAsync(`docker ps --filter name=${node.id} --format "{{.Status}}"`);
      console.log(`Status: ${status.trim()}`);
      
      return true;
    } catch (error) {
      console.error(`✗ Failed to start container: ${error.message}`);
      throw error;
    }
  }

  /**
   * Deploy all nodes in cluster
   */
  async deployCluster() {
    console.log(`\n${'='.repeat(60)}`);
    console.log(`DEPLOYING CLUSTER: ${this.cluster.clusterId}`);
    console.log(`${'='.repeat(60)}`);

    const strategy = this.cluster.orchestration?.deploymentStrategy || 'sequential';
    
    if (strategy === 'sequential') {
      for (const node of this.cluster.nodes) {
        await this.deployNode(node);
      }
    } else {
      // Parallel deployment
      await Promise.all(this.cluster.nodes.map(node => this.deployNode(node)));
    }

    console.log(`\n${'='.repeat(60)}`);
    console.log('DEPLOYMENT COMPLETE');
    console.log(`${'='.repeat(60)}`);
    this.printClusterStatus();
  }

  /**
   * Print cluster status
   */
  printClusterStatus() {
    console.log('\nCluster Status:');
    console.log(`  Cluster ID: ${this.cluster.clusterId}`);
    console.log(`  Environment: ${this.cluster.environment}`);
    console.log(`  Hub: ${this.cluster.hub.protocol}://${this.cluster.hub.host}:${this.cluster.hub.port}`);
    console.log(`  Nodes: ${this.cluster.nodes.length}`);
    
    console.log('\nUseful commands:');
    for (const node of this.cluster.nodes) {
      console.log(`\n  ${node.id}:`);
      console.log(`    View logs:    docker logs -f ${node.id}`);
      console.log(`    Stop:         docker stop ${node.id}`);
      console.log(`    Start:        docker start ${node.id}`);
      console.log(`    Restart:      docker restart ${node.id}`);
      console.log(`    Remove:       docker stop ${node.id} && docker rm ${node.id}`);
      console.log(`    Shell:        docker exec -it ${node.id} /bin/sh`);
      
      if (node.blockchainConfig?.network?.rpcPort) {
        console.log(`    RPC:          http://localhost:${node.blockchainConfig.network.rpcPort}`);
      }
      if (node.metrics?.enabled && node.metrics.port) {
        console.log(`    Metrics:      http://localhost:${node.metrics.port}${node.metrics.path}`);
      }
    }
    
    console.log('\nBlockchain Explorer: https://64.225.16.227/');
  }

  /**
   * Main execution flow
   */
  async run() {
    try {
      console.log('Boundless Node Controller - Lumenbridge Edition\n');
      
      await this.checkDocker();
      await this.loadSchemas();
      await this.loadCluster();
      await this.loadBlockchainImage();
      await this.deployCluster();
      
    } catch (error) {
      console.error(`\n✗ ERROR: ${error.message}`);
      console.error(error.stack);
      process.exit(1);
    }
  }
}

// Execute if run directly
if (require.main === module) {
  const controller = new BoundlessNodeController();
  controller.run();
}

module.exports = BoundlessNodeController;
