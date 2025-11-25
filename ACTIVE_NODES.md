# Boundless Network - Active Nodes

## Production Deployments

### Node 1: patch-proof-api-g
- **IP:** 137.184.40.224
- **Status:** ✅ **MINING BLOCKS**
- **Deployed:** November 25, 2025
- **Method:** `boundless_deploy` automated script
- **Deployment URL:** https://github.com/codenlighten/boundless_deploy

---

## Network Statistics

**Mainnet Bootnode:** 159.203.114.205:30333  
**Explorer:** https://64.225.16.227/  
**P2P Port:** 30333  
**RPC Port:** 9933

---

## Deployment Success Metrics

✅ **One-command deployment working**  
✅ **Automatic dependency installation**  
✅ **Wallet generation functional**  
✅ **Node syncing with network**  
✅ **Mining blocks successfully**  
✅ **Production-ready on fresh Ubuntu**

---

## Quick Commands for Node Management

**View logs:**
```bash
docker logs -f boundless-node
```

**Check node status:**
```bash
docker ps | grep boundless-node
```

**Check mining stats:**
```bash
curl -s http://localhost:9933/health
```

**Restart node:**
```bash
docker restart boundless-node
```

---

## Add New Node

To deploy additional nodes:

```bash
# On new server
git clone https://github.com/codenlighten/boundless_deploy.git
cd boundless_deploy
./start_boundless_node.sh
```

---

## Explorer Links

- **Network Explorer:** https://64.225.16.227/
- **View your mining address:** Check the wallet file or logs
- **Monitor blocks:** Watch the explorer for new blocks

---

**Last Updated:** November 25, 2025  
**Network Status:** 🟢 **LIVE AND MINING**

🚀 **Deployment system validated in production!**
