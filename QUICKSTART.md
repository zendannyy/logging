# Quick Start Guide

Get the Logging PoC up and running

(See README for general concept of project)
## Prerequisites

- Docker and Docker Compose installed
- 4GB+ RAM available
- 10GB+ disk space

## Step-by-Step

### 1. Start the Stack

```bash
cd logging-poc
./scripts/startup.sh
```

The script will:
- Build Docker images
- Pull required images
- Start all services
- Wait for health checks

⏱️ **Duration**: 2-3 minutes

### 2. Verify Services

```bash
./scripts/status.sh
```

All services should show as healthy.

### 3. Access the Services

**Wazuh Dashboard** (SIEM/Threat Detection)
- URL: https://localhost:443
- Username: `admin`
- Password: `SecurePassword123`

**Velociraptor** (DFIR Investigation)
- URL: https://localhost:8000
- Username: `admin`
- Password: `admin`

⚠️ **Note**: Your browser will warn about self-signed certificates. Accept the warning to proceed.

## Common Tasks

### View Logs in Real-Time

```bash
docker-compose logs -f wazuh-manager
```

### Access an Agent

```bash
docker-compose exec ubuntu-agent-1 bash
```

### Test Log Collection

```bash
./scripts/test.sh all
```

### Stop Everything

```bash
./scripts/shutdown.sh
```

### Clean Up (Delete All Data)

```bash
./scripts/shutdown.sh --force
```

## Next Steps

1. **Log In to Wazuh Dashboard**
   - Explore the Security Events tab
   - Review alerts and rules
   - Check agent status

2. **Log In to Velociraptor**
   - View connected clients
   - Create a hunt to collect artifacts
   - Analyze collected data

3. **Generate Logs**
   - Run: `./scripts/test.sh logs`
   - Watch alerts appear in Wazuh dashboard
   - Review logs in Velociraptor

4. **Read Full Documentation**
   - See `README.md` for detailed information
   - Explore configuration files for customization

## Troubleshooting

### What services are Not Starting?

```bash
# Check logs
docker-compose logs

# Remove containers and try again
./scripts/shutdown.sh --force
./scripts/startup.sh
```

### Can't Access Dashboard?

- Wait 2-3 minutes for services to fully initialize
- Check browser console for certificate errors
- Try a different browser
- Run `./scripts/status.sh` to verify service health

### Agent Not Reporting?

```bash
# Check agent logs
docker-compose exec ubuntu-agent-1 cat /var/ossec/logs/ossec.log

# Check connectivity
docker-compose exec ubuntu-agent-1 ping wazuh-manager
```

## Performance Tips

- Close unnecessary applications to free up RAM
- Use SSD storage for better performance
- Reduce Elasticsearch memory if needed: edit `.env` and restart

## What's Running?

| Component | Purpose | Port |
|-----------|---------|------|
| Wazuh Manager | Central monitoring | 1514 |
| Elasticsearch | Log storage | 9200 |
| Wazuh Dashboard | Web UI | 443 |
| Velociraptor | DFIR tool | 8000 |
| Ubuntu Agents | Log sources | - |

## Need Help?

- Check logs: `docker-compose logs [service]`
- Read README.md for detailed documentation
- Review configuration files in `wazuh/`, `velociraptor/` directories

---

**Ready to start?** Run:

```bash
./scripts/startup.sh
```
