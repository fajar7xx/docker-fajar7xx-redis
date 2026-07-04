# Redis Stack with Docker Compose

Redis Stack adalah paket lengkap Redis yang mencakup Redis core plus berbagai modul tambahan dan RedisInsight (GUI management tool).

## Compose Structure

```
redis/
├── compose.yaml
└── README.md
```

## Quick Start

**1. Setup environment variables:**

```bash
# Copy file .env.example ke .env
cp .env.example .env

# Edit .env dan sesuaikan konfigurasi
nano .env
```

**2. Menjalankan Redis Stack:**

```bash
docker compose up -d
```

**Melihat status:**

```bash
docker compose ps
```

**Melihat logs:**

```bash
docker compose logs -f
```

**Menghentikan service:**

```bash
docker compose down
```

## Services

### redis-stack

- **Image**: `redis/redis-stack:7.4.0-v1`
- **Ports**:
  - `10001`: Redis server port
  - `13333`: RedisInsight web interface (bound to localhost only)
- **Volumes**: 
  - `./data:/data` - Persistent storage untuk data Redis (bind mount lokal)
- **Environment**:
  - `REDIS_ARGS`: Konfigurasi Redis (password, AOF persistence, maxmemory policy, snapshotting)
- **Healthcheck**: Monitoring otomatis setiap 10 detik
- **Logging**: Rotasi log (max 10MB per file, max 3 file)
- **Resources**: Memory limit 512MB

## Accessing Services

**Redis CLI:**

```bash
docker compose exec redis-stack redis-cli
# Masukkan password saat diminta
AUTH yourpassword
```

**RedisInsight (Web UI):**

Buka browser: http://localhost:13333

## Configuration

Konfigurasi dilakukan melalui file `.env`:

```bash
# Redis Configuration
REDIS_PASSWORD=yourpassword
REDIS_PORT=6379
REDISINSIGHT_PORT=8001
```

**Environment Variables:**
- `REDIS_PASSWORD`: Password untuk akses Redis
- `REDIS_PORT`: Port untuk Redis server
- `REDISINSIGHT_PORT`: Port untuk RedisInsight web UI
- `REDIS_MAXMEMORY`: Maksimum memory Redis (default: `256mb`)
- `REDIS_MAXMEMORY_POLICY`: Kebijakan eviction saat memory penuh (default: `allkeys-lru`)

Jika tidak ada file `.env`, Docker Compose akan menggunakan nilai default yang ada di `compose.yaml` (dengan syntax `${VAR:-default}`).

## Data Persistence

Data Redis disimpan di bind mount `./data/`. Data akan tetap ada meskipun container dihapus.

**Backup data:**

```bash
docker compose exec redis-stack redis-cli --rdb /data/backup.rdb
```

**Melihat volume:**

```bash
docker volume ls
docker volume inspect redis_redis-data
```

## Security Notes

⚠️ **PENTING**: Ganti `yourpassword` dengan password yang kuat sebelum production!

Edit file `.env`:

```bash
REDIS_PASSWORD=your-strong-password-here
```

⚠️ **Jangan commit file `.env` ke git!** File ini sudah ada di `.gitignore`.

## Troubleshooting

**Melihat logs detail:**

```bash
docker compose logs redis-stack
```

**Restart service:**

```bash
docker compose restart redis-stack
```

**Reset semua data:**

```bash
docker compose down -v
docker compose up -d
```
