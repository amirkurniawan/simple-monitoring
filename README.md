# Simple Monitoring with Netdata

Setup basic monitoring dashboard menggunakan Netdata untuk memantau kesehatan sistem secara real-time.

Project reference: [roadmap.sh/projects/simple-monitoring](https://roadmap.sh/projects/simple-monitoring)

---

## Apa itu Netdata?

Netdata adalah tool monitoring open-source yang powerful dengan fitur:

- **Real-time** - Update setiap detik
- **Zero configuration** - Langsung jalan setelah install
- **Lightweight** - Resource usage minimal
- **2000+ metrics** - CPU, RAM, Disk, Network, Processes, dll
- **Beautiful dashboard** - Web UI yang interaktif
- **Alerting** - Notifikasi saat ada masalah

---

## Preview

```
┌─────────────────────────────────────────────────────────────────┐
│  NETDATA DASHBOARD                           http://IP:19999    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  CPU Usage          Memory Usage         Disk I/O              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│  │ ▃▅▇█▅▃▂▅▇█ │    │ █████████░░ │    │ ▂▄▆█▄▂▁▄▆█ │        │
│  │    45%     │    │    85%      │    │   Read/Write │        │
│  └─────────────┘    └─────────────┘    └─────────────┘        │
│                                                                 │
│  Network Traffic    System Load         Processes              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│  │ ↑ 5.2 MB/s │    │  1.25       │    │    142      │        │
│  │ ↓ 12.8MB/s │    │  1min avg   │    │   running   │        │
│  └─────────────┘    └─────────────┘    └─────────────┘        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Quick Start

```bash
# Clone repository
git clone https://github.com/amirkurniawan/simple-monitoring.git
cd simple-monitoring

# Install Netdata
sudo ./setup.sh

# Buka browser
# http://<SERVER_IP>:19999
```

---

## Project Structure

```
simple-monitoring/
├── setup.sh            # Install dan configure Netdata
├── test_dashboard.sh   # Generate load untuk testing
├── cleanup.sh          # Uninstall Netdata
└── README.md           # Documentation
```

---

## Scripts

### setup.sh

Install Netdata dan konfigurasi custom alerts.

```bash
sudo ./setup.sh
```

**Yang dilakukan:**
1. Update system packages
2. Install Netdata dari official repository
3. Configure Netdata untuk akses remote
4. Setup custom alerts (CPU > 80%, RAM > 85%, Disk > 90%)
5. Start dan enable service

---

### test_dashboard.sh

Generate load untuk test monitoring dashboard.

```bash
# Test CPU load
./test_dashboard.sh cpu

# Test memory load
./test_dashboard.sh memory

# Test disk I/O
./test_dashboard.sh disk

# Run semua test
./test_dashboard.sh all
```

**Test yang tersedia:**
| Test | Duration | Description |
|------|----------|-------------|
| cpu | 30s | Stress semua CPU cores |
| memory | 30s | Allocate 512MB RAM |
| disk | varies | Write/read 500MB file |
| all | ~2min | Run semua test |

---

### cleanup.sh

Hapus Netdata dari sistem.

```bash
sudo ./cleanup.sh
```

**Yang dihapus:**
- Netdata service dan packages
- Configuration files (`/etc/netdata`)
- Data files (`/var/lib/netdata`)
- Log files (`/var/log/netdata`)
- Netdata user dan group

---

## Manual Setup

Jika ingin install manual tanpa script:

### 1. Install Netdata

```bash
# Update system
sudo apt update

# Install menggunakan official script
wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh
sudo bash /tmp/netdata-kickstart.sh --non-interactive
```

### 2. Configure Remote Access

```bash
sudo nano /etc/netdata/netdata.conf
```

Tambahkan/edit:
```ini
[global]
    bind to = 0.0.0.0

[web]
    allow connections from = *
    allow dashboard from = *
```

### 3. Restart Service

```bash
sudo systemctl restart netdata
```

### 4. Access Dashboard

Buka browser: `http://<SERVER_IP>:19999`

---

## Custom Alerts

Script setup.sh membuat 3 custom alerts:

### CPU Alert
```yaml
File: /etc/netdata/health.d/cpu_custom.conf

Trigger:
  Warning:  CPU > 80%
  Critical: CPU > 95%
```

### Memory Alert
```yaml
File: /etc/netdata/health.d/memory_custom.conf

Trigger:
  Warning:  RAM > 85%
  Critical: RAM > 95%
```

### Disk Alert
```yaml
File: /etc/netdata/health.d/disk_custom.conf

Trigger:
  Warning:  Disk > 90%
  Critical: Disk > 95%
```

### View Active Alerts

Di dashboard: Menu → Alerts → Active

Atau via CLI:
```bash
curl -s http://localhost:19999/api/v1/alarms | jq
```

---

## Useful Commands

### Service Management

```bash
# Status
sudo systemctl status netdata

# Start/Stop/Restart
sudo systemctl start netdata
sudo systemctl stop netdata
sudo systemctl restart netdata

# View logs
sudo journalctl -u netdata -f
```

### Configuration

```bash
# Main config
sudo nano /etc/netdata/netdata.conf

# Alerts config
sudo nano /etc/netdata/health.d/

# Test config
sudo netdatacli reload-health
```

### API Access

```bash
# System info
curl http://localhost:19999/api/v1/info

# CPU metrics
curl http://localhost:19999/api/v1/data?chart=system.cpu

# Memory metrics
curl http://localhost:19999/api/v1/data?chart=system.ram

# All charts list
curl http://localhost:19999/api/v1/charts
```

---

## Dashboard Features

### Main Sections

| Section | Metrics |
|---------|---------|
| System Overview | CPU, Load, RAM, Disk, Network |
| CPU | Per-core usage, Interrupts, Context switches |
| Memory | RAM, Swap, Buffers, Cache |
| Disks | I/O, Latency, Space usage |
| Network | Bandwidth, Packets, Errors |
| Processes | Running, Blocked, Forked |
| Users | Logged in users |

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `D` | Toggle dark mode |
| `F` | Toggle fullscreen |
| `P` | Pause/Resume |
| `←` `→` | Navigate time |
| `Esc` | Reset zoom |

---

## Firewall Configuration

Jika menggunakan firewall:

```bash
# UFW
sudo ufw allow 19999/tcp
sudo ufw reload

# firewalld
sudo firewall-cmd --add-port=19999/tcp --permanent
sudo firewall-cmd --reload
```

---

## Troubleshooting

### Dashboard tidak bisa diakses

```bash
# Cek service running
sudo systemctl status netdata

# Cek port listening
sudo ss -tlnp | grep 19999

# Cek firewall
sudo ufw status
```

### High memory usage by Netdata

```bash
# Edit config
sudo nano /etc/netdata/netdata.conf

# Reduce history
[global]
    history = 1800  # 30 minutes instead of 1 hour
    
# Restart
sudo systemctl restart netdata
```

### Alerts not working

```bash
# Reload health config
sudo netdatacli reload-health

# Check health log
sudo tail -f /var/log/netdata/health.log
```

---

## What I Learned

1. **Monitoring Basics** - Understanding system metrics (CPU, RAM, Disk I/O, Network)
2. **Alerting** - Setting up threshold-based alerts
3. **Netdata** - Installation, configuration, and customization
4. **Shell Scripting** - Automation scripts for setup, testing, and cleanup
5. **System Load Testing** - How to simulate system load for testing

---

## Next Steps

Setelah project ini, bisa lanjut ke monitoring yang lebih advanced:

- **Prometheus + Grafana** - Industry standard monitoring stack
- **ELK Stack** - Log aggregation dan analysis
- **Zabbix** - Enterprise monitoring solution
- **SigNoz** - OpenTelemetry-based observability

---

## References

- [Netdata Documentation](https://learn.netdata.cloud/)
- [Netdata GitHub](https://github.com/netdata/netdata)
- [Netdata Configuration](https://learn.netdata.cloud/docs/configuring/configuration)
- [Netdata Alerts](https://learn.netdata.cloud/docs/alerting/health-configuration-reference)

---

*Project completed as part of DevOps learning journey*
