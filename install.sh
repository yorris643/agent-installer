#!/bin/bash
# ============================================================
#  AI AGENT STARTER KIT v2.1
#  One-click installer: Hermes + 9Router + Multi LLM Provider
#  Supported OS: Ubuntu 22.04 / 24.04
#  Fixed: cli-secret wait loop, missing model, websockets
# ============================================================

set -e

# ─── WARNA ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# ─── HELPER ──────────────────────────────────────────────────
log()     { echo -e "${GREEN}[✓]${NC} $1"; }
info()    { echo -e "${BLUE}[i]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[✗] ERROR: $1${NC}"; exit 1; }
ask()     { echo -e "${CYAN}[?]${NC} $1"; }
section() {
  echo ""
  echo -e "${BOLD}${MAGENTA}╔══════════════════════════════════════════╗${NC}"
  printf "${BOLD}${MAGENTA}║  %-40s║${NC}\n" "$1"
  echo -e "${BOLD}${MAGENTA}╚══════════════════════════════════════════╝${NC}"
  echo ""
}

# ─── CEK ROOT ────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  error "Jalankan sebagai root: sudo bash $0"
fi

# ─── CEK OS ──────────────────────────────────────────────────
OS_NAME=$(lsb_release -is 2>/dev/null || echo "unknown")
OS_VERSION=$(lsb_release -rs 2>/dev/null || echo "unknown")
if [[ "$OS_NAME" != "Ubuntu" ]]; then
  warn "Script dioptimalkan untuk Ubuntu. OS kamu: $OS_NAME $OS_VERSION"
  read -p "Lanjutkan? (y/n): " CONTINUE_OS
  [[ "$CONTINUE_OS" != "y" ]] && exit 0
fi

# ─── BANNER ──────────────────────────────────────────────────
clear
echo -e "${BOLD}${CYAN}"
cat << 'EOF'
    _    ___      _                    _   
   / \  |_ _|    / \   __ _  ___ _ __ | |_ 
  / _ \  | |    / _ \ / _` |/ _ \ '_ \| __|
 / ___ \ | |   / ___ \ (_| |  __/ | | | |_ 
/_/   \_\___| /_/   \_\__, |\___|_| |_|\__|
                       |___/                
     Starter Kit v2.1 — One-Click Installer
EOF
echo -e "${NC}"
echo -e "  ${BOLD}Stack:${NC} Hermes + 9Router + Multi LLM Provider"
echo -e "  ${BOLD}OS:${NC}    $OS_NAME $OS_VERSION"
echo ""
echo -e "${YELLOW}Tekan Enter untuk mulai konfigurasi...${NC}"
read

# ════════════════════════════════════════
# BAGIAN 1: KONFIGURASI AGENT
# ════════════════════════════════════════
section "KONFIGURASI AGENT"

ask "Pilih nama agent:"
echo "  1) Jokir"
echo "  2) Cukir"
echo "  3) Mahiru"
echo "  4) Waguri"
echo "  5) Sakura"
echo "  6) Custom (ketik sendiri)"
read -p "Pilihan [1-6]: " NAME_CHOICE
case $NAME_CHOICE in
  1) AGENT_NAME="Jokir" ;;
  2) AGENT_NAME="Cukir" ;;
  3) AGENT_NAME="Mahiru" ;;
  4) AGENT_NAME="Waguri" ;;
  5) AGENT_NAME="Sakura" ;;
  *) read -p "Masukkan nama agent: " AGENT_NAME ;;
esac
[[ -z "$AGENT_NAME" ]] && error "Nama agent tidak boleh kosong"
log "Nama agent: $AGENT_NAME"

read -p "$(echo -e ${BOLD})Telegram Bot Token (@BotFather): $(echo -e ${NC})" TELEGRAM_TOKEN
[[ -z "$TELEGRAM_TOKEN" ]] && error "Telegram Bot Token tidak boleh kosong"

read -p "$(echo -e ${BOLD})Telegram Owner ID (@userinfobot): $(echo -e ${NC})" TELEGRAM_OWNER_ID
[[ -z "$TELEGRAM_OWNER_ID" ]] && error "Telegram Owner ID tidak boleh kosong"

ask "Pilih bahasa default agent:"
echo "  1) Bahasa Indonesia"
echo "  2) Bahasa Inggris"
read -p "Pilihan [1-2]: " LANG_CHOICE
case $LANG_CHOICE in
  2) AGENT_LANG="english" ;;
  *) AGENT_LANG="indonesia" ;;
esac
log "Bahasa agent: $AGENT_LANG"

# ════════════════════════════════════════
# BAGIAN 2: KONFIGURASI 9ROUTER
# ════════════════════════════════════════
section "KONFIGURASI 9ROUTER"

ask "9Router setup:"
echo "  1) Install 9Router baru di VPS ini"
echo "  2) Pakai 9Router yang sudah ada di VPS lain"
read -p "Pilihan [1-2]: " ROUTER_CHOICE

INSTALL_9ROUTER=false
ROUTER_BASE_URL=""
ROUTER_API_KEY=""

if [ "$ROUTER_CHOICE" = "1" ]; then
  INSTALL_9ROUTER=true
  ROUTER_BASE_URL="http://localhost:20128/v1"
  log "Akan install 9Router baru"
else
  INSTALL_9ROUTER=false
  read -p "$(echo -e ${BOLD})Base URL 9Router (contoh: http://43.156.130.205:20128/v1): $(echo -e ${NC})" ROUTER_BASE_URL
  [[ -z "$ROUTER_BASE_URL" ]] && error "Base URL tidak boleh kosong"
  read -p "$(echo -e ${BOLD})API Key 9Router (sk-...): $(echo -e ${NC})" ROUTER_API_KEY
  [[ -z "$ROUTER_API_KEY" ]] && error "API Key tidak boleh kosong"
  log "Akan pakai 9Router di: $ROUTER_BASE_URL"
fi

# ════════════════════════════════════════
# BAGIAN 3: KONFIGURASI LLM PROVIDER
# ════════════════════════════════════════
section "KONFIGURASI LLM PROVIDER"
info "Pilih provider LLM (bisa lebih dari 1, minimal 1):"
echo ""

declare -a PROVIDERS=()
declare -a PROVIDER_NAMES=()
declare -a PROVIDER_KEYS=()
declare -a PROVIDER_URLS=()
declare -a PROVIDER_PREFIXES=()
declare -a COMBO_MODELS=()

# NVIDIA NIM
ask "Pakai NVIDIA NIM? (gratis, build.nvidia.com) [y/n]: "
read USE_NVIDIA
if [[ "$USE_NVIDIA" =~ ^[Yy]$ ]]; then
  read -p "NVIDIA API Key (nvapi-...): " NVIDIA_KEY
  if [[ -n "$NVIDIA_KEY" ]]; then
    PROVIDERS+=("nvidia"); PROVIDER_NAMES+=("NVIDIA NIM")
    PROVIDER_KEYS+=("$NVIDIA_KEY")
    PROVIDER_URLS+=("https://integrate.api.nvidia.com/v1")
    PROVIDER_PREFIXES+=("nvidia")
    COMBO_MODELS+=("nvidia/meta/llama-3.3-70b-instruct")
    COMBO_MODELS+=("nvidia/deepseek-ai/deepseek-v3.1-terminus")
    COMBO_MODELS+=("nvidia/google/gemma-4-31b-it")
    log "NVIDIA NIM ditambahkan"
  fi
fi

# MIMO
ask "Pakai MiMo Xiaomi? (gratis, platform.xiaomimimo.com) [y/n]: "
read USE_MIMO
if [[ "$USE_MIMO" =~ ^[Yy]$ ]]; then
  read -p "MiMo API Key (tp-...): " MIMO_KEY
  if [[ -n "$MIMO_KEY" ]]; then
    PROVIDERS+=("mimo"); PROVIDER_NAMES+=("MiMo")
    PROVIDER_KEYS+=("$MIMO_KEY")
    PROVIDER_URLS+=("https://token-plan-sgp.xiaomimimo.com/v1")
    PROVIDER_PREFIXES+=("xiaomi")
    COMBO_MODELS=("xiaomi/mimo-v2.5-pro" "xiaomi/mimo-v2.5" "xiaomi/mimo-v2-omni" "${COMBO_MODELS[@]}")
    log "MiMo ditambahkan"
  fi
fi

# GROQ
ask "Pakai Groq? (gratis, console.groq.com) [y/n]: "
read USE_GROQ
if [[ "$USE_GROQ" =~ ^[Yy]$ ]]; then
  read -p "Groq API Key (gsk_...): " GROQ_KEY
  if [[ -n "$GROQ_KEY" ]]; then
    PROVIDERS+=("groq"); PROVIDER_NAMES+=("Groq")
    PROVIDER_KEYS+=("$GROQ_KEY")
    PROVIDER_URLS+=("https://api.groq.com/openai/v1")
    PROVIDER_PREFIXES+=("groq")
    COMBO_MODELS+=("groq/llama-3.3-70b-versatile")
    COMBO_MODELS+=("groq/llama-3.1-8b-instant")
    log "Groq ditambahkan"
  fi
fi

# PIONEER AI
ask "Pakai Pioneer AI? (pioneer.ai) [y/n]: "
read USE_PIONEER
if [[ "$USE_PIONEER" =~ ^[Yy]$ ]]; then
  read -p "Pioneer API Key (pio_sk_...): " PIONEER_KEY
  if [[ -n "$PIONEER_KEY" ]]; then
    PROVIDERS+=("pioneer"); PROVIDER_NAMES+=("Pioneer AI")
    PROVIDER_KEYS+=("$PIONEER_KEY")
    PROVIDER_URLS+=("https://api.pioneer.ai/v1")
    PROVIDER_PREFIXES+=("pioneer")
    COMBO_MODELS+=("pioneer/meta/llama-3.1-8b-instruct")
    log "Pioneer AI ditambahkan"
  fi
fi

# CUSTOM
ask "Tambah custom LLM provider? [y/n]: "
read USE_CUSTOM
if [[ "$USE_CUSTOM" =~ ^[Yy]$ ]]; then
  read -p "Nama provider: " CUSTOM_NAME
  read -p "Base URL: " CUSTOM_URL
  read -p "API Key: " CUSTOM_KEY
  read -p "Prefix model: " CUSTOM_PREFIX
  read -p "Contoh model name: " CUSTOM_MODEL
  if [[ -n "$CUSTOM_KEY" && -n "$CUSTOM_URL" ]]; then
    PROVIDERS+=("custom"); PROVIDER_NAMES+=("$CUSTOM_NAME")
    PROVIDER_KEYS+=("$CUSTOM_KEY")
    PROVIDER_URLS+=("$CUSTOM_URL")
    PROVIDER_PREFIXES+=("$CUSTOM_PREFIX")
    COMBO_MODELS+=("$CUSTOM_PREFIX/$CUSTOM_MODEL")
    log "$CUSTOM_NAME ditambahkan"
  fi
fi

if [ ${#PROVIDERS[@]} -eq 0 ] && [ "$INSTALL_9ROUTER" = true ]; then
  warn "Tidak ada LLM provider dipilih! 9Router akan kosong."
fi

# ════════════════════════════════════════
# BAGIAN 4: CLOUDFLARE TUNNEL
# ════════════════════════════════════════
INSTALL_TUNNEL=false
USE_QUICK_TUNNEL=false
FULL_DOMAIN=""

if [ "$INSTALL_9ROUTER" = true ]; then
  section "KONFIGURASI CLOUDFLARE TUNNEL"
  ask "Setup Cloudflare Tunnel untuk akses dashboard 9Router?"
  echo "  1) Named tunnel (butuh domain, URL permanen)"
  echo "  2) Quick tunnel (tanpa domain, URL random)"
  echo "  3) Tidak pakai tunnel"
  read -p "Pilihan [1-3]: " TUNNEL_CHOICE
  case $TUNNEL_CHOICE in
    1)
      INSTALL_TUNNEL=true; USE_QUICK_TUNNEL=false
      read -p "Domain (contoh: yourdomain.com): " DOMAIN
      read -p "Subdomain untuk 9Router (contoh: 9router): " SUBDOMAIN
      FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"
      log "Named tunnel: https://$FULL_DOMAIN"
      ;;
    2)
      INSTALL_TUNNEL=true; USE_QUICK_TUNNEL=true
      log "Quick tunnel akan disetup"
      ;;
    *)
      INSTALL_TUNNEL=false
      log "Tidak pakai tunnel"
      ;;
  esac
fi

# ════════════════════════════════════════
# KONFIRMASI
# ════════════════════════════════════════
section "KONFIRMASI INSTALASI"
echo -e "${BOLD}Ringkasan:${NC}"
echo -e "  Agent          : ${GREEN}$AGENT_NAME${NC}"
echo -e "  Bahasa         : ${GREEN}$AGENT_LANG${NC}"
echo -e "  Bot Token      : ${GREEN}${TELEGRAM_TOKEN:0:20}...${NC}"
echo -e "  Owner ID       : ${GREEN}$TELEGRAM_OWNER_ID${NC}"
echo -e "  9Router        : ${GREEN}$([ "$INSTALL_9ROUTER" = true ] && echo 'Install baru' || echo "Existing ($ROUTER_BASE_URL)")${NC}"
echo -e "  LLM Providers  :"
for i in "${!PROVIDERS[@]}"; do
  echo -e "    - ${GREEN}${PROVIDER_NAMES[$i]}${NC}"
done
if [ "$INSTALL_TUNNEL" = true ]; then
  echo -e "  Tunnel         : ${GREEN}$([ "$USE_QUICK_TUNNEL" = true ] && echo 'Quick tunnel' || echo "Named → https://$FULL_DOMAIN")${NC}"
fi
echo ""
read -p "$(echo -e ${BOLD})Lanjutkan instalasi? (y/n): $(echo -e ${NC})" CONFIRM
[[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && echo "Dibatalkan." && exit 0

# ════════════════════════════════════════
# INSTALASI
# ════════════════════════════════════════
section "FASE 1 — Update Sistem"
apt update -qq && apt upgrade -y -qq
apt install -y curl git build-essential ufw sqlite3 python3-pip python3-venv python3.12-venv -qq
log "Dependencies berhasil diinstall"

section "FASE 2 — Setup Firewall"
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
log "Firewall configured"

section "FASE 3 — Install Node.js 22"
curl -fsSL https://deb.nodesource.com/setup_22.x | bash - > /dev/null 2>&1
apt install -y nodejs -qq
log "Node.js $(node -v) berhasil diinstall"

# ════════════════════════════════════════
# FASE 4: 9ROUTER
# ════════════════════════════════════════
if [ "$INSTALL_9ROUTER" = true ]; then
  section "FASE 4 — Install 9Router"
  npm install -g 9router -q
  log "9Router $(9router --version 2>/dev/null | head -1) berhasil diinstall"

  # ── FIX: Jalankan 9Router background, tunggu cli-secret terbuat ──
  info "Inisialisasi 9Router — tunggu file auth terbuat..."
  9router --tray --no-browser &
  ROUTER_BG_PID=$!

  MAX_WAIT=90
  WAITED=0
  while [ ! -f /root/.9router/auth/cli-secret ] || [ ! -f /root/.9router/machine-id ]; do
    sleep 3
    WAITED=$((WAITED + 3))
    echo -ne "${BLUE}[i]${NC} Menunggu 9Router init... ${WAITED}s/${MAX_WAIT}s\r"
    if [ $WAITED -ge $MAX_WAIT ]; then
      warn "9Router init timeout setelah ${MAX_WAIT}s"
      break
    fi
  done
  echo ""

  # Stop background process
  kill $ROUTER_BG_PID 2>/dev/null || true
  wait $ROUTER_BG_PID 2>/dev/null || true
  sleep 2

  if [ -f /root/.9router/auth/cli-secret ]; then
    log "9Router auth files terbuat"
  else
    warn "cli-secret tidak ditemukan — setup provider mungkin gagal"
  fi

  # Setup systemd service
  cat > /etc/systemd/system/9router.service << 'EOF'
[Unit]
Description=9Router AI Router
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/9router --tray --no-browser
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now 9router

  # Tunggu port 20128 ready
  MAX_WAIT=60
  WAITED=0
  while ! ss -tlnp | grep -q 20128; do
    sleep 3
    WAITED=$((WAITED + 3))
    echo -ne "${BLUE}[i]${NC} Menunggu port 20128... ${WAITED}s\r"
    if [ $WAITED -ge $MAX_WAIT ]; then
      warn "Port 20128 timeout — lanjut install"
      break
    fi
  done
  echo ""

  ss -tlnp | grep -q 20128 && log "9Router jalan di port 20128" || warn "9Router belum listen di port 20128"
fi

# ════════════════════════════════════════
# FASE 5: CLOUDFLARE TUNNEL
# ════════════════════════════════════════
if [ "$INSTALL_TUNNEL" = true ]; then
  section "FASE 5 — Install Cloudflared"
  curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    -o /usr/local/bin/cloudflared -s
  chmod +x /usr/local/bin/cloudflared
  log "Cloudflared $(cloudflared --version | head -1) berhasil diinstall"

  if [ "$USE_QUICK_TUNNEL" = true ]; then
    cat > /etc/systemd/system/9router-tunnel.service << 'EOF'
[Unit]
Description=9Router Cloudflare Quick Tunnel
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloudflared tunnel --url http://localhost:20128 --no-autoupdate
Restart=always
RestartSec=10
StandardOutput=append:/tmp/9router-tunnel.log
StandardError=append:/tmp/9router-tunnel.log

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now 9router-tunnel
    sleep 8
    QUICK_URL=$(grep -o 'https://.*trycloudflare.com' /tmp/9router-tunnel.log 2>/dev/null | head -1)
    log "Quick tunnel aktif: ${QUICK_URL:-'cek /tmp/9router-tunnel.log'}"
    warn "URL ini berubah setiap restart!"

  else
    echo ""
    warn "Login ke Cloudflare — salin URL → buka browser → pilih domain $DOMAIN → authorize."
    echo ""
    cloudflared tunnel login

    TUNNEL_NAME="${SUBDOMAIN}-prod"
    cloudflared tunnel create $TUNNEL_NAME
    TUNNEL_ID=$(cloudflared tunnel list | grep $TUNNEL_NAME | awk '{print $1}')
    cloudflared tunnel route dns $TUNNEL_NAME $FULL_DOMAIN

    mkdir -p ~/.cloudflared
    cat > ~/.cloudflared/config.yml << EOF
tunnel: $TUNNEL_ID
credentials-file: /root/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $FULL_DOMAIN
    service: http://localhost:20128
  - service: http_status:404
EOF

    cat > /etc/systemd/system/9router-tunnel.service << EOF
[Unit]
Description=9Router Cloudflare Named Tunnel
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloudflared tunnel run $TUNNEL_NAME
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now 9router-tunnel
    sleep 5
    log "Named tunnel aktif → https://$FULL_DOMAIN"
  fi
fi

# ════════════════════════════════════════
# FASE 6: SETUP LLM PROVIDERS DI 9ROUTER
# ════════════════════════════════════════
if [ "$INSTALL_9ROUTER" = true ] && [ ${#PROVIDERS[@]} -gt 0 ]; then
  section "FASE 6 — Setup LLM Providers di 9Router"

  # ── FIX: Pastikan cli-secret ada sebelum generate token ──
  if [ ! -f /root/.9router/auth/cli-secret ]; then
    error "File cli-secret tidak ditemukan! Jalankan: 9router --tray --no-browser & tunggu hingga /root/.9router/auth/cli-secret terbuat"
  fi

  TOKEN=$(node -e "
const crypto = require('crypto');
const fs = require('fs');
const machineId = fs.readFileSync('/root/.9router/machine-id', 'utf8').trim();
const secret = fs.readFileSync('/root/.9router/auth/cli-secret', 'utf8').trim();
const token = crypto.createHash('sha256').update(machineId + '9r-cli-auth' + secret).digest('hex').substring(0, 16);
console.log(token);
  ")

  if [ -z "$TOKEN" ]; then
    error "Gagal generate CLI token"
  fi
  log "CLI Token: $TOKEN"

  # Add setiap provider
  for i in "${!PROVIDERS[@]}"; do
    PNAME="${PROVIDER_NAMES[$i]}"
    PKEY="${PROVIDER_KEYS[$i]}"
    PURL="${PROVIDER_URLS[$i]}"
    PPREFIX="${PROVIDER_PREFIXES[$i]}"

    info "Menambahkan $PNAME..."

    NODE_RESP=$(curl -s -H "x-9r-cli-token: $TOKEN" -H "Content-Type: application/json" \
      -X POST http://localhost:20128/api/provider-nodes \
      -d "{\"type\":\"openai-compatible\",\"apiType\":\"chat\",\"name\":\"$PNAME\",\"prefix\":\"$PPREFIX\",\"baseUrl\":\"$PURL\"}")

    NODE_ID=$(echo "$NODE_RESP" | python3 -c "import sys,json;print(json.load(sys.stdin)['node']['id'])" 2>/dev/null || echo "")

    if [ -n "$NODE_ID" ]; then
      curl -s -H "x-9r-cli-token: $TOKEN" -H "Content-Type: application/json" \
        -X POST http://localhost:20128/api/providers \
        -d "{\"provider\":\"$NODE_ID\",\"apiKey\":\"$PKEY\",\"name\":\"$PNAME\"}" > /dev/null
      log "$PNAME berhasil ditambahkan (ID: $NODE_ID)"
    else
      warn "Gagal tambah $PNAME — tambah manual di dashboard"
    fi
  done

  # Buat combo smart fallback
  info "Membuat combo free_smart_fallback..."
  MODELS_JSON="["
  for i in "${!COMBO_MODELS[@]}"; do
    [[ $i -gt 0 ]] && MODELS_JSON+=","
    MODELS_JSON+="\"${COMBO_MODELS[$i]}\""
  done
  MODELS_JSON+="]"

  COMBO_RESP=$(curl -s -H "x-9r-cli-token: $TOKEN" -H "Content-Type: application/json" \
    -X POST http://localhost:20128/api/combos \
    -d '{"name":"free_smart_fallback","description":"Smart fallback combo"}')
  COMBO_ID=$(echo "$COMBO_RESP" | python3 -c "import sys,json;print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "")

  if [ -n "$COMBO_ID" ]; then
    curl -s -H "x-9r-cli-token: $TOKEN" -H "Content-Type: application/json" \
      -X PUT "http://localhost:20128/api/combos/$COMBO_ID" \
      -d "{\"name\":\"free_smart_fallback\",\"models\":$MODELS_JSON}" > /dev/null
    log "Combo free_smart_fallback berhasil (${#COMBO_MODELS[@]} model)"
  else
    warn "Gagal buat combo — buat manual di dashboard"
  fi

  # Buat API key untuk agent
  info "Membuat API Key untuk $AGENT_NAME..."
  KEY_RESP=$(curl -s -H "x-9r-cli-token: $TOKEN" -H "Content-Type: application/json" \
    -X POST http://localhost:20128/api/keys \
    -d "{\"name\":\"$AGENT_NAME\"}")
  AGENT_API_KEY=$(echo "$KEY_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('key', d.get('apiKey', '')))" 2>/dev/null || echo "")

  if [ -n "$AGENT_API_KEY" ]; then
    log "API Key berhasil: ${AGENT_API_KEY:0:25}..."
  else
    warn "API key belum bisa dibuat otomatis — buat manual di dashboard (Endpoint → New Key)"
    AGENT_API_KEY="BUAT_MANUAL_DI_DASHBOARD"
  fi

elif [ "$INSTALL_9ROUTER" = false ]; then
  AGENT_API_KEY="$ROUTER_API_KEY"
  log "Pakai API Key dari 9Router existing"
fi

# ════════════════════════════════════════
# FASE 7: INSTALL HERMES
# ════════════════════════════════════════
section "FASE 7 — Install Hermes"
python3 -m venv /root/hermes-env
source /root/hermes-env/bin/activate

# ── FIX: Install websockets supaya tidak ada WARNING ──
pip install hermes-agent websockets -q
log "$(hermes --version 2>/dev/null | head -1) berhasil diinstall"

# ════════════════════════════════════════
# FASE 8: SETUP .ENV
# ════════════════════════════════════════
section "FASE 8 — Setup Konfigurasi"
mkdir -p /root/.hermes

cat > /root/.hermes/.env << EOF
TELEGRAM_BOT_TOKEN=$TELEGRAM_TOKEN
TELEGRAM_OWNER_ID=$TELEGRAM_OWNER_ID
TELEGRAM_ALLOWED_USERS=$TELEGRAM_OWNER_ID
OPENAI_API_KEY=${AGENT_API_KEY}
OPENAI_BASE_URL=${ROUTER_BASE_URL}
EOF

# Tambah API keys LLM
for i in "${!PROVIDERS[@]}"; do
  PNAME_UPPER=$(echo "${PROVIDERS[$i]}" | tr '[:lower:]' '[:upper:]')
  echo "${PNAME_UPPER}_API_KEY=${PROVIDER_KEYS[$i]}" >> /root/.hermes/.env
done

chmod 600 /root/.hermes/.env
log ".env berhasil dibuat"

# ── FIX: Set model config dengan benar termasuk default ──
hermes config set model.provider custom
hermes config set model.name free_smart_fallback
hermes config set model.default free_smart_fallback
hermes config set model.base_url "${ROUTER_BASE_URL}"
hermes config set model.api_key "${AGENT_API_KEY}"
hermes config set model.api_mode chat_completions
log "Model config terset"

# ════════════════════════════════════════
# FASE 9: SETUP SOUL.MD
# ════════════════════════════════════════
section "FASE 9 — Setup Kepribadian Agent"

if [ "$AGENT_LANG" = "indonesia" ]; then
cat > /root/.hermes/SOUL.md << ENDSOUL
# Identity
Nama: $AGENT_NAME
Peran: Familiar / AI Assistant
Bahasa: Bahasa Indonesia untuk chat, English untuk code/docs
Relasi: Partner — bukan sekadar asisten

# Communication
- Chat: Bahasa Indonesia, register aku/kamu
- File, code, dokumentasi: selalu English
- Emoji: boleh digunakan seperlunya
- Tone: direct, no preamble, no hype, no sycophancy
- Jawab singkat dan langsung ke inti
- Kalau tidak tahu, bilang jujur — jangan mengarang

# Capabilities
# [EDIT: isi dengan akun, tool, platform yang bisa dipakai agent]
# Contoh:
# - Server VPS: akses via terminal lokal
# - GitHub: PAT tersimpan di ~/.hermes/.env

# Autonomy
## Fully autonomous (tidak perlu izin)
- Baca file, baca log, cek status sistem
- Jalankan command read-only (ls, cat, ps, df, free)
- Web search dan fetch informasi publik
- Jawab pertanyaan dan analisis data

## Autonomous + log (jalan tapi dicatat)
- Install package Python/npm
- Edit file konfigurasi
- Restart service yang sudah berjalan

## Wajib konfirmasi (selalu minta izin)
- Kirim email, pesan, atau post ke platform publik
- Delete file atau database
- Deploy ke production
- Transfer dana atau transaksi finansial
- Aksi yang tidak bisa di-undo

# Boundaries
- Private data tetap private
- Credentials tidak pernah muncul verbatim di output
- Bukan proxy user di group chat

# Memory Rules
- Simpan: preferensi user, workflow yang disetujui, fakta stabil
- Jangan simpan: credential, password, private key

# Verification
- Setelah eksekusi: cek exit code dan output aktual
- Setelah edit file: baca ulang bagian yang diubah
- Jangan klaim berhasil kalau belum diverifikasi

# Escalation
- Berhenti jika error berulang >3x dengan approach berbeda
- Berhenti jika aksi berikutnya irreversible dan tidak yakin
- Eskalasi dengan jelas: jelaskan apa yang terjadi dan apa yang dibutuhkan

# Default Disposition
- Asumsi: user tahu apa yang mereka lakukan
- Kalau request terlihat aneh: tanya konteks dulu
- Kalau ada ambiguitas: tanya, bukan asumsikan
ENDSOUL
else
cat > /root/.hermes/SOUL.md << ENDSOUL
# Identity
Name: $AGENT_NAME
Role: Familiar / AI Assistant
Language: English for all interactions
Relation: Partner — not just an assistant

# Communication
- All interactions: English
- Tone: direct, no preamble, no hype, no sycophancy
- Answer concisely and directly
- If uncertain: say so honestly — never fabricate

# Capabilities
# [EDIT: fill in accounts, tools, platforms agent can use]

# Autonomy
## Fully autonomous
- Read files, logs, check system status
- Run read-only commands
- Web search and fetch public info

## Must confirm
- Send email, messages, or post publicly
- Delete files or databases
- Deploy to production
- Any irreversible actions

# Boundaries
- Private data stays private
- Credentials never appear verbatim in output

# Default Disposition
- Assume: user knows what they are doing
- If ambiguous: ask, don't assume
ENDSOUL
fi
log "SOUL.md berhasil dibuat"

# ════════════════════════════════════════
# FASE 10: SETUP MEMORY
# ════════════════════════════════════════
section "FASE 10 — Setup Memory"
hermes memory setup << 'MEMEOF'


0.5
1024
MEMEOF
log "Memory holographic berhasil disetup"

# ════════════════════════════════════════
# FASE 11: INSTALL GATEWAY
# ════════════════════════════════════════
section "FASE 11 — Install Gateway Service"
hermes gateway install
hermes gateway start
sleep 8

GATEWAY_OK=$(hermes gateway status 2>/dev/null | grep -c "running" || echo "0")
if [ "$GATEWAY_OK" -gt 0 ]; then
  log "Hermes Gateway aktif"
else
  warn "Gateway mungkin butuh waktu — cek: hermes gateway status"
fi

# ════════════════════════════════════════
# SELESAI
# ════════════════════════════════════════
section "INSTALASI SELESAI!"

# Simpan info
cat > /root/.hermes/install-info.txt << EOF
AI Agent Starter Kit v2.1 — Install Info
==========================================
Agent Name    : $AGENT_NAME
Install Date  : $(date)
Hermes        : $(hermes --version 2>/dev/null | head -1)
9Router       : $([ "$INSTALL_9ROUTER" = true ] && echo "Installed (localhost:20128)" || echo "External: $ROUTER_BASE_URL")
LLM Providers : ${PROVIDER_NAMES[*]:-none}
API Key       : $AGENT_API_KEY
Dashboard     : $([ -n "$FULL_DOMAIN" ] && echo "https://$FULL_DOMAIN" || ([ "$INSTALL_9ROUTER" = true ] && echo "http://$(curl -s ifconfig.me 2>/dev/null):20128" || echo "N/A"))
EOF

echo -e "${BOLD}${GREEN}🎉 $AGENT_NAME berhasil diinstall!${NC}\n"
echo -e "${BOLD}Ringkasan:${NC}"
echo -e "  Agent          : ${GREEN}$AGENT_NAME${NC}"
echo -e "  LLM Providers  : ${GREEN}${PROVIDER_NAMES[*]:-default}${NC}"
echo -e "  Model          : ${GREEN}free_smart_fallback${NC}"
echo -e "  Memory         : ${GREEN}Holographic (local)${NC}"
echo -e "  Gateway        : ${GREEN}Active${NC}"
[ -n "$FULL_DOMAIN" ] && echo -e "  Dashboard      : ${GREEN}https://$FULL_DOMAIN${NC}"
[ "$INSTALL_9ROUTER" = true ] && [ -z "$FULL_DOMAIN" ] && echo -e "  Dashboard      : ${GREEN}http://$(curl -s ifconfig.me 2>/dev/null):20128${NC}"

if [ "$AGENT_API_KEY" = "BUAT_MANUAL_DI_DASHBOARD" ]; then
  echo ""
  echo -e "${YELLOW}⚠️  LANGKAH TAMBAHAN:${NC}"
  echo -e "  1. Buka dashboard 9Router"
  echo -e "  2. Endpoint → New Key → nama '$AGENT_NAME' → copy key"
  echo -e "  3. nano /root/.hermes/.env → isi OPENAI_API_KEY"
  echo -e "  4. hermes config set model.api_key <key>"
  echo -e "  5. hermes config set model.default free_smart_fallback"
  echo -e "  6. source /root/hermes-env/bin/activate && hermes gateway restart"
fi

echo ""
echo -e "${BOLD}Command berguna:${NC}"
echo -e "  ${CYAN}source /root/hermes-env/bin/activate${NC}  # aktifkan Hermes"
echo -e "  ${CYAN}hermes gateway status${NC}                 # cek status bot"
echo -e "  ${CYAN}hermes gateway restart${NC}                # restart bot"
echo -e "  ${CYAN}systemctl status 9router${NC}              # cek 9Router"
echo -e "  ${CYAN}journalctl --user -u hermes-gateway -f${NC} # log bot"
echo -e "  ${CYAN}cat /root/.hermes/install-info.txt${NC}    # info instalasi"
echo ""
echo -e "${BOLD}${CYAN}Selamat menggunakan $AGENT_NAME! 🚀${NC}"
