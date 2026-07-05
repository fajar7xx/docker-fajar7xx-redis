# Redis Stack — Production-Grade Docker Setup

Redis Stack production-ready dengan ACL multi-user, RedisInsight, dan Redis Exporter untuk Prometheus.

## Filesystem

```
redis/
├── compose.yaml
├── .env
├── .env.example
├── config/
│   └── redis/
│       ├── redis.conf                  # Redis server configuration
│       ├── acl.conf.template           # ACL user definitions (envsubst)
│       └── docker-entrypoint.sh        # Entrypoint: renders ACL from template
└── README.md
```

## Quick Start

```bash
cp .env.example .env
nano .env                         # Ganti semua password wajib!
docker compose up -d
docker compose ps                 # Verifikasi healthy
```

## Services

### redis-stack
- Image: `redis/redis-stack:7.4.0-v1`
- Ports: `10001` (Redis), `13333` (RedisInsight) — keduanya `127.0.0.1` only
- `no-new-privileges:true` + selective capability drop
- Healthcheck via `redis-cli --user admin` ping

### redis-exporter
- Image: `oliver006/redis_exporter:v1.67.0`
- Port: `9121` (Prometheus metrics) — `127.0.0.1` only
- `no-new-privileges:true`
- Menunggu redis-stack healthy sebelum start (`depends_on condition: service_healthy`)

## ACL Users

| User      | Key Prefix     | Permission                                    | Use Case              |
|-----------|---------------|------------------------------------------------|-----------------------|
| `admin`   | `*` (all)     | `+@all`                                       | RedisInsight, exporter, ops |
| `app`     | `*` (all)     | All, NO `@dangerous`, `@admin`, flush, config | Application caching   |
| `session` | `session:*`   | Read/write keys + TTL ops only                | Session store         |
| `queue`   | `stream:*`    | Streams + Pub/Sub + read/write                | Message broker/queue  |

`default` user disabled. Setiap command destructive direname/disabled di `redis.conf`.

## Accessing Services

**Redis CLI (admin):**
```bash
docker compose exec redis-stack redis-cli --user admin --pass superadminpass123 --no-auth-warning
```

**Redis CLI (app user):**
```bash
docker compose exec redis-stack redis-cli --user app --pass myappsecret456 --no-auth-warning
```

**RedisInsight:**
Buka http://localhost:13333

Saat add database:
- Host: `redis-stack` (dari dalam Docker) atau `127.0.0.1` (dari host)
- Port: `6379` (dari dalam Docker) atau `10001` (dari host)
- Username: `admin`
- Password: (dari `.env`)

**Prometheus Metrics:**
http://localhost:9121/metrics

**Prometheus scrape config:**
```yaml
scrape_configs:
  - job_name: redis
    static_configs:
      - targets: ['redis-exporter:9121']
```

## Environment Variables (.env)

| Variable                  | Purpose                              |
|---------------------------|--------------------------------------|
| `REDIS_ADMIN_PASSWORD`    | ACL admin password                   |
| `REDIS_APP_PASSWORD`      | ACL app user password                |
| `REDIS_SESSION_PASSWORD`  | ACL session user password            |
| `REDIS_QUEUE_PASSWORD`    | ACL queue user password              |
| `REDIS_PORT`              | Host port for Redis                  |
| `REDISINSIGHT_PORT`       | Host port for RedisInsight           |
| `REDIS_EXPORTER_PORT`     | Host port for Prometheus exporter    |
| `REDIS_CPU_LIMIT`         | CPU limit (default: `2.0`)           |
| `REDIS_CPU_RESERVE`       | CPU reservation (default: `0.5`)     |
| `REDIS_MEM_LIMIT`         | Memory limit (default: `2560M`)      |
| `REDIS_MEM_RESERVE`       | Memory reservation (default: `256M`) |

## Performance Tuning

| Setting                     | Value       | Why                                      |
|-----------------------------|-------------|------------------------------------------|
| IO threads                  | 4 + reads   | Multi-threaded I/O for high throughput   |
| Lazyfree eviction/expire    | Yes         | Non-blocking eviction and expiry         |
| Active defragmentation      | Yes         | Prevents memory fragmentation over time  |
| AOF rewrite                 | 100% / 64mb | Auto-rewrite threshold                   |
| `vm.overcommit_memory`      | 1           | Set manual di host: `sudo sysctl vm.overcommit_memory=1` |
| `net.core.somaxconn`        | 65535       | High connection backlog                  |
| File descriptors (nofile)   | 65536       | High connection limit                    |
| `shm_size`                  | 512M        | Shared memory for COW snapshots          |

## Security Hardening

- Container runs as `redis` user (UID 999), bukan root
- Semua Linux capabilities di-drop kecuali `SETGID`, `SETUID`, `DAC_OVERRIDE`
- Root filesystem read-only
- `no-new-privileges:true`
- Semua ports bind ke `127.0.0.1` saja
- Custom bridge network `redis_net`
- Dangerous commands disabled: `FLUSHALL`, `FLUSHDB`, `DEBUG`, `SHUTDOWN`, `MODULE`, `SLAVEOF`, `CLUSTER`
- `CONFIG` renamed (obfuscated)
- `requirepass` diganti ACL system — `default` user `off`
- Setiap user punya key-prefix isolation: `session` user hanya bisa akses `session:*`, `queue` user hanya `stream:*`

## Data Persistence

Data disimpan di Docker named volumes:
- `redis_data` — RDB + AOF files
- `redis_insight` — RedisInsight configuration

```bash
docker volume ls
docker volume inspect redis_data redis_insight
```

**Force BGSAVE:**
```bash
docker compose exec redis-stack redis-cli --user admin --pass superadminpass123 --no-auth-warning BGSAVE
```

## Troubleshooting

**Logs:**
```bash
docker compose logs -f redis-stack
docker compose logs -f redis-exporter
```

**Cek ACL users:**
```bash
docker compose exec redis-stack redis-cli --user admin --pass superadminpass123 --no-auth-warning ACL LIST
```

**Cek health:**
```bash
docker compose ps
```

**Reset total (hapus semua data):**
```bash
docker compose down -v
docker compose up -d
```
