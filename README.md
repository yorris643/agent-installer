# 🤖 AI Agent Starter Kit v2.0

One-click installer untuk setup AI Agent pribadi dengan stack:
**Hermes + 9Router + Multi LLM Provider (NVIDIA NIM, MiMo, Groq, Pioneer AI)**

---

## ⚡ Quick Start

```bash
# Download dan jalankan installer
curl -O https://raw.githubusercontent.com/your-repo/ai-agent-starter-kit/main/install.sh
chmod +x install.sh
bash install.sh
```

Atau kalau sudah download manual:
```bash
chmod +x install.sh
bash install.sh
```

---

## 📋 Prasyarat

| Kebutuhan | Detail |
|---|---|
| **OS** | Ubuntu 22.04 atau 24.04 |
| **RAM** | Minimal 2GB (4GB recommended) |
| **Storage** | Minimal 10GB free |
| **Akses** | Root atau sudo |
| **Port** | 22, 80, 443 (20128 opsional) |

---

## 🔑 Data yang Diperlukan Saat Install

Siapkan data berikut sebelum menjalankan installer:

### Wajib
- **Nama agent** — nama bot kamu (contoh: Jokir)
- **Telegram Bot Token** — dari [@BotFather](https://t.me/BotFather)
- **Telegram Owner ID** — dari [@userinfobot](https://t.me/userinfobot)

### LLM Provider (minimal 1)
| Provider | Daftar | Format Key |
|---|---|---|
| **NVIDIA NIM** | [build.nvidia.com](https://build.nvidia.com) | `nvapi-...` |
| **MiMo Xiaomi** | [platform.xiaomimimo.com](https://platform.xiaomimimo.com) | `tp-...` |
| **Groq** | [console.groq.com](https://console.groq.com) | `gsk_...` |
| **Pioneer AI** | [pioneer.ai](https://pioneer.ai) | `pio_sk_...` |

### Opsional (untuk Cloudflare Named Tunnel)
- **Domain** yang sudah pointing ke Cloudflare
- **Subdomain** untuk dashboard 9Router

---

## 🎯 Fitur Installer

```
✅ Install Node.js 22
✅ Install & setup 9Router dengan systemd
✅ Setup Cloudflare Tunnel (named atau quick)
✅ Add multiple LLM providers ke 9Router
✅ Buat combo smart fallback otomatis
✅ Install Hermes AI Agent
✅ Setup .env dan model config
✅ Setup SOUL.md (kepribadian agent)
✅ Setup memory holographic
✅ Install & start gateway service
✅ Simpan info instalasi ke file
```

---

## 🔄 Alur Smart Fallback

Setelah install, bot akan otomatis fallback antar provider:

```
Request masuk
     ↓
MiMo V2.5-Pro  ← prioritas utama (kalau dipilih)
     ↓ limit/error
NVIDIA NIM     ← backup
     ↓ limit/error
Groq Llama     ← backup (kalau dipilih)
     ↓ limit/error
Pioneer AI     ← last resort (kalau dipilih)
```

---

## 📁 Struktur File Setelah Install

```
/root/
├── hermes-env/          # Python virtual environment Hermes
├── .hermes/
│   ├── .env             # API keys dan config
│   ├── config.yaml      # Hermes configuration
│   ├── SOUL.md          # Kepribadian agent
│   ├── install-info.txt # Info instalasi
│   └── memory_store.db  # Memory holographic
└── .9router/
    ├── db/
    │   └── data.sqlite  # Database 9Router
    ├── machine-id
    └── auth/
        └── cli-secret
```

---

## 🛠️ Command Berguna Setelah Install

```bash
# Aktifkan environment Hermes
source /root/hermes-env/bin/activate

# Cek status bot
hermes gateway status

# Restart bot
hermes gateway restart

# Lihat log bot
journalctl --user -u hermes-gateway -f

# Cek status 9Router
systemctl status 9router

# Lihat log 9Router
journalctl -u 9router -f

# Restart 9Router
systemctl restart 9router

# Cek info instalasi
cat /root/.hermes/install-info.txt
```

---

## 🔧 Konfigurasi Manual Setelah Install

### Update API Key
```bash
nano /root/.hermes/.env
# Edit OPENAI_API_KEY dan provider keys lainnya
```

### Update SOUL.md (kepribadian agent)
```bash
nano /root/.hermes/SOUL.md
# Edit kepribadian dan instruksi agent
source /root/hermes-env/bin/activate
hermes gateway restart
```

### Tambah LLM Provider Baru
```bash
# Generate token dulu
TOKEN=$(node -e "
const crypto = require('crypto');
const fs = require('fs');
const machineId = fs.readFileSync('/root/.9router/machine-id', 'utf8').trim();
const secret = fs.readFileSync('/root/.9router/auth/cli-secret', 'utf8').trim();
const token = crypto.createHash('sha256').update(machineId + '9r-cli-auth' + secret).digest('hex').substring(0, 16);
console.log(token);
")

# Tambah provider node
NODE_ID=$(curl -s -H "x-9r-cli-token: $TOKEN" -H "Content-Type: application/json" \
  -X POST http://localhost:20128/api/provider-nodes \
  -d '{"type":"openai-compatible","apiType":"chat","name":"Provider Baru","prefix":"prefix","baseUrl":"https://api.example.com/v1"}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['node']['id'])")

# Attach API key
curl -s -H "x-9r-cli-token: $TOKEN" -H "Content-Type: application/json" \
  -X POST http://localhost:20128/api/providers \
  -d "{\"provider\":\"$NODE_ID\",\"apiKey\":\"API_KEY_BARU\",\"name\":\"Provider Baru\"}"
```

---

## 🚨 Troubleshooting

| Masalah | Solusi |
|---|---|
| Bot tidak respond di Telegram | `hermes gateway status` → cek error |
| 9Router crash loop | `systemctl status 9router` → cek log |
| API key 401 | Generate key baru di provider → update `.env` |
| Dashboard 502 | `systemctl restart 9router && sleep 8` |
| Tunnel tidak jalan | `systemctl restart 9router-tunnel` |
| Memory error | `hermes memory setup` ulang |

---

## 💰 Estimasi Biaya Bulanan

| Komponen | Biaya |
|---|---|
| VPS 2GB | ~$5/bulan |
| NVIDIA NIM | **Gratis** |
| MiMo Xiaomi | **Gratis** (Token Plan) |
| Groq | **Gratis** |
| 9Router | **Gratis** |
| Hermes | **Gratis** |
| Cloudflare Tunnel | **Gratis** |
| **Total** | **~$5/bulan** |

---

## 📞 Support

Kalau ada masalah saat install, cek:
1. `cat /root/.hermes/install-info.txt` — info instalasi
2. `journalctl -u 9router -n 50` — log 9Router
3. `journalctl --user -u hermes-gateway -n 50` — log Hermes
