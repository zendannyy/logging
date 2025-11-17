# Quick Start Guide

Get the Logging PoC up and running

(See README for general concept of project)
## Prerequisites

- Docker and Docker Compose installed
- 4GB+ RAM available
- 10GB+ disk space

## Step-by-Step

### 0. Configure Environment Variables

**First-time setup:** Create your `.env` file from the template:

```bash
cd logging-poc
cp .env.example .env
```

**Customize (optional):** Edit `.env` to change default passwords, ports, or other settings:

```bash
# Edit with your preferred editor
nano .env
# or
vim .env
```

**Important:** The `.env` file contains sensitive credentials. It's already in `.gitignore` and won't be committed to version control.

**⚠️ Set passwords BEFORE first startup!** After first startup, some passwords are stored in volumes and harder to change. See `CREDENTIALS.md` for details.

**Default values work for testing**, but you should change passwords for production use.

### 1. Start the Stack

```bash
cd logging-poc
./scripts/startup.sh
```

The script will:
- Build and Pull required Docker images
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
   - Explore config files for customization

## Environment Configuration

### Creating the .env File

The `.env` file is required for the project to run. It contains all configurable settings:

1. **Copy the template:**
   ```bash
   cp .env.example .env
   ```

2. **Customize (optional):** Edit `.env` to set:
   - Passwords (change from defaults for security)
   - Ports (if you need to avoid conflicts)
   - Memory settings (if you have limited RAM)
   - Timezone

3. **The `.env` file is git-ignored** - your secrets won't be committed.

### What's in .env?

- **Wazuh credentials:** Indexer, API, and Dashboard passwords
- **Velociraptor credentials:** Admin credentials
- **Port mappings:** All service ports
- **Resource limits:** Java heap sizes, memory settings
- **Timezone:** For consistent log timestamps

**See `CREDENTIALS.md` for detailed information on:**
- How credentials are initialized
- Which can be changed after setup
- How to change passwords if needed

### Portability Best Practices

1. **Always use `.env.example` as a template** - it documents all required variables
2. **Never commit `.env`** - it's in `.gitignore` for security
3. **Document custom values** - if you change defaults, note why in your deployment docs
4. **Use different `.env` files per environment:**
   ```bash
   # Development
   cp .env.example .env.dev
   
   # Production
   cp .env.example .env.prod
   
   # Load specific env
   export ENV_FILE=.env.prod
   ```

## Troubleshooting

### To see what services are not starting

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

## Debugging

- Check logs: `docker-compose logs [service]`
- Read README.md for detailed documentation
- Review configuration files in `wazuh/`, `velociraptor/` directories
---

**Ready to start?** Run:

```bash
./scripts/startup.sh
```
