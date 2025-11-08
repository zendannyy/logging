
# logging
logging_poc
=======
# Logging Proof of Concept (PoC)

A comprehensive logging and DFIR infrastructure demonstration using Docker, Wazuh, and Velociraptor.

## Overview

This project creates a complete logging and security monitoring stack for digital forensics and incident response (DFIR) purposes, it consists of:

- **[Wazuh](https://documentation.wazuh.com/current/index.html)**: SIEM/XDR platform for threat detection and security monitoring
- **[Velociraptor](https://docs.velociraptor.app/)**: General-purpose DFIR triage and investigation agent
- **Ubuntu Agents**: Containerized Linux systems with Wazuh agents and Velociraptor clients
- **[Elasticsearch](https://www.elastic.co/docs)**: Data indexing and storage backend
- **Wazuh Dashboard**: Web interface for security monitoring and analysis

## Prerequisites

- Docker (version 20.10+)
- Docker Compose (version 1.29+)
- At least 4GB RAM available on host
- Disk space: 10GB minimum for logs and data storage
- Linux/macOS (Windows with WSL2 supported)

## Project Structure

```
logging-poc/
├── docker-compose.yml          # Main orchestration file
├── .env                         # Environment variables
├── README.md                    # This file
│
├── agent/
│   └── Dockerfile              # Ubuntu agent base image with Wazuh & Velociraptor
│
├── wazuh/
│   └── ossec.conf             # Wazuh agent/manager configuration
│
├── velociraptor/
│   ├── server.config.yaml     # Velociraptor server configuration
│   └── acls.yaml              # Access control lists
│
├── config/
│   └── [Additional configurations]
│
└── scripts/
    ├── startup.sh             # Initialize and start all services
    ├── shutdown.sh            # Stop and clean up services
    ├── status.sh              # Check service health
    └── [Additional utilities]
```

## Quick Start

### 1. Clone/Navigate to Project

```bash
cd logging-poc
```

### 2. Start the Stack

```bash
./scripts/startup.sh
```

This will:
- Load environment configuration
- Build Docker images
- Start all services
- Wait for services to become healthy

### 3. Access Services

Once started, services are available at:

| Service | URL | Credentials |
|---------|-----|-------------|
| Wazuh Dashboard | https://localhost:443 | admin / SecurePassword123 |
| Velociraptor GUI | https://localhost:8000 | admin / admin |
| Elasticsearch API | http://localhost:9200 | admin / SecurePassword123 |
| Wazuh Manager API | https://localhost:9200 | wazuh / wazuh |

### 4. Verify Setup

Check the status of all services:

```bash
./scripts/status.sh
```

Or use Docker Compose directly:

```bash
docker-compose ps
docker-compose logs -f [service_name]
```

## Service Architecture

### Wazuh Manager
- **Port**: 1514 (agent communication), 1515 (agent enrollment), 514/UDP (syslog)
- **Role**: Central security monitoring and threat detection
- **Features**:
  - File integrity monitoring (FIM)
  - Log analysis and alerting
  - Vulnerability detection
  - DFIR capabilities

### Wazuh Indexer (Elasticsearch)
- **Port**: 9200, 9300
- **Role**: Data storage and indexing
- **Storage**: Persistent volume for log retention

### Wazuh Dashboard
- **Port**: 443 (HTTPS)
- **Role**: Web interface for monitoring and analysis
- **Access**: Browser-based dashboard

### Velociraptor Server
- **GUI Port**: 8000 (Web interface)
- **Client Port**: 8001 (Client communication)
- **Role**: DFIR triage and investigation
- **Features**:
  - Live endpoint investigation
  - Artifact collection
  - VQL queries for forensics
  - Hunt management

### Ubuntu Agents
- **Count**: 2 agents by default (ubuntu-agent-1, ubuntu-agent-2)
- **Components**: Wazuh agent + Velociraptor client
- **Logs**: Monitored and sent to Wazuh manager
- **Communication**: Secure connection to manager and Velociraptor server

## Configuration Details

### Wazuh Agent Configuration
Located in `wazuh/ossec.conf`:
- FIM: Monitors `/bin`, `/sbin`, `/usr/bin`, `/usr/sbin`, `/etc`, `/var/www`, `/var/ossec`
- Log monitoring: auth.log, syslog, sudo.log
- Rootcheck: Rootkit detection
- Syscollector: Hardware and software inventory
- Vulnerability detection enabled

### Velociraptor Configuration
Located in `velociraptor/server.config.yaml`:
- File-based datastore for PoC (can be upgraded to relational DB)
- TLS encryption for client communication
- Pre-configured DFIR artifacts for Linux systems
- Hunt capability for distributed investigations

### Environment Variables
Configure in `.env` file:
```bash
# Wazuh credentials
WAZUH_ADMIN_PASSWORD=SecurePassword123
WAZUH_INDEXER_PASSWORD=SecurePassword123

# Velociraptor
VELOCIRAPTOR_ADMIN_PASSWORD=admin

# Resources
ES_JAVA_OPTS=-Xms512m -Xmx512m
```

## Common Tasks

### View Real-time Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f wazuh-manager
docker-compose logs -f velociraptor-server
docker-compose logs -f ubuntu-agent-1
```

### Access Service Shells

```bash
# Access Ubuntu agent
docker-compose exec ubuntu-agent-1 /bin/bash

# Access Wazuh manager
docker-compose exec wazuh-manager /bin/bash

# Access Velociraptor
docker-compose exec velociraptor-server /bin/bash
```

### Generate Test Logs

```bash
# Generate logs on agent
docker-compose exec ubuntu-agent-1 /usr/local/bin/generate-logs.sh
```

### Check Wazuh Agent Status

```bash
# On agent container
/var/ossec/bin/wazuh-control status
```

### Run Velociraptor Hunts

1. Log into Velociraptor GUI: https://localhost:8000
2. Navigate to "Hunts" section
3. Create new hunt
4. Select clients to target
5. Choose artifact to collect
6. Monitor progress and review results

### Restart Services

```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart wazuh-manager
docker-compose restart velociraptor-server
```

## DFIR Use Cases

### 1. Host Monitoring
- Monitor file changes, system calls, and network connections
- Detect unauthorized changes to critical files
- Track user activity and login attempts

### 2. Incident Investigation
- Use Velociraptor to run targeted artifact collection
- Analyze timeline of events in Wazuh
- Correlate logs across multiple agents

### 3. Threat Hunting
- Execute VQL queries in Velociraptor
- Hunt for indicators of compromise (IoCs)
- Analyze suspicious processes and network connections

### 4. Compliance & Auditing
- Monitor system changes and access logs
- Generate audit reports
- Track system configuration changes

## Troubleshooting

### Services Won't Start

```bash
# Check Docker daemon
docker --version
docker ps

# View detailed logs
docker-compose logs

# Remove stuck containers
docker-compose down -v
./scripts/startup.sh
```

### High Memory Usage

```bash
# Reduce Elasticsearch memory allocation in .env
ES_JAVA_OPTS=-Xms256m -Xmx256m

# Restart services
docker-compose restart wazuh-indexer
```

### Agent Connection Issues

1. Check network connectivity:
   ```bash
   docker-compose exec ubuntu-agent-1 ping wazuh-manager
   ```

2. Verify Wazuh manager is listening:
   ```bash
   docker-compose exec wazuh-manager netstat -tlnp | grep 1514
   ```

3. Check agent logs:
   ```bash
   docker-compose exec ubuntu-agent-1 cat /var/ossec/logs/ossec.log
   ```

### Velociraptor Connection Issues

```bash
# Verify client configuration
docker-compose exec ubuntu-agent-1 cat /opt/velociraptor/client.config.yaml

# Check Velociraptor server logs
docker-compose logs velociraptor-server
```

## Performance Tuning

### For Production Use

1. **Elasticsearch Tuning**:
   - Increase heap size: `ES_JAVA_OPTS=-Xms2g -Xmx2g`
   - Use SSD storage for data
   - Configure index lifecycle policies

2. **Wazuh Tuning**:
   - Adjust log rotation settings
   - Configure active response rules
   - Optimize rule sets

3. **Velociraptor Tuning**:
   - Use relational database backend
   - Configure SSL certificates
   - Implement database replication

## Security Considerations

⚠️ **This is a PoC environment. For production:**

1. Change all default passwords
2. Configure proper SSL/TLS certificates
3. Enable authentication and authorization
4. Network segmentation and firewall rules
5. Regular backup and disaster recovery
6. Implement audit logging
7. Regular security updates and patching

## Cleanup

### Stop Services

```bash
./scripts/shutdown.sh
```

### Remove Everything (including data)

```bash
./scripts/shutdown.sh --force
```

This will remove all containers, networks, and volumes.

## Additional Resources

- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Velociraptor Documentation](https://docs.velociraptor.app/)
- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/7.17/index.html)
- [DFIR Best Practices](https://www.sans.org/white-papers/)

## Support & Contributing

For issues or contributions:
1. Check logs first: `docker-compose logs`
2. Review configuration files
3. Consult documentation links above 

## License

This PoC is provided as-is for educational and demonstration purposes.
