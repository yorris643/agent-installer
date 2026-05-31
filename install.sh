#!/bin/bash
# ============================================================
#  AI AGENT STARTER KIT v2.0
#  One-click installer: Hermes + 9Router + Multi LLM Provider
#  Supported OS: Ubuntu 22.04 / 24.04
#  Author: AI Agent Starter Kit
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
  echo -e "${BOLD}${MAGENTA}║  $1$(printf '%*s' $((40 - ${#1})) '')║${NC}"
  echo -e "${BOLD}${MAGENTA}╚══════════════════════════════════════════╝${NC}"
  echo ""
}

# ─── CEK ROOT ────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  error "Jalankan sebagai root: sudo bash $0"
fi

# ─── CEK OS ──────────────────────────────────────────────────
OS_VERSION=$(lsb_release -rs 2>/dev/null || echo "unknown")
OS_NAME=$(lsb_release -is 2>/dev/null || echo "unknown")
if [[ "$OS_NAME" != "Ubuntu" ]]; then
  warn "Script ini dioptimalkan untuk Ubuntu. OS kamu: $OS_NAME $OS_VERSION"
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
     Starter Kit v2.0 — One-Click Installer
EOF
echo -e "${NC}"
echo -e "  ${BOLD}Stack:${NC} Hermes + 9Router + Multi LLM Provider"
echo -e "  ${BOLD}OS:${NC}    Ubuntu 22.04 / 24.04"
echo -e "  ${BOLD}Docs:${NC}  Baca README.md untuk panduan lengkap"
echo ""
echo -e "${YELLOW}Tekan Enter untuk mulai konfigurasi...${NC}"
read

# ════════════════════════════════════════
# BAGIAN 1: KONFIGURASI AWAL
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
  6)
    read -p "$(echo -e ${BOLD})Masukkan nama agent: $(echo -e ${NC})" AGENT_NAME
    [[ -z "$AGENT_NAME" ]] && error "Nama agent tidak boleh kosong"
    ;;
  *)
    read -p "$(echo -e ${BOLD})Masukkan nama agent: $(echo -e ${NC})" AGENT_NAME
    [[ -z "$AGENT_NAME" ]] && error "Nama agent tidak boleh kosong"
    ;;
esac
log "Nama agent: $AGENT_NAME"

read -p "$(echo -e ${BOLD})Telegram Bot Token (@BotFather): $(echo -e ${NC})" TELEGRAM_TOKEN
[[ -z "$TELEGRAM_TOKEN" ]] && error "Telegram Bot Token tidak boleh kosong"

read -p "$(echo -e ${BOLD})Telegram Owner ID: $(echo -e ${NC})" TELEGRAM_OWNER_ID
[[ -z "$TELEGRAM_OWNER_ID" ]] && error "Telegram Owner ID tidak boleh kosong"

# ─── BAHASA AGENT ────────────────────────────────────────────
echo ""
ask "Pilih bahasa default agent:"
echo "  1) Bahasa Indonesia"
echo "  2) Bahasa Inggris"
read -p "Pilihan [1-2]: " LANG_CHOICE
case $LANG_CHOICE in
  1) AGENT_LANG="indonesia" ;;
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

if [ "$ROUTER_CHOICE" = "1" ]; then
  INSTALL_9ROUTER=true
  ROUTER_BASE_URL="http://localhost:20128/v1"
  log "Akan install 9Router baru di VPS ini"
elif [ "$ROUTER_CHOICE" = "2" ]; then
  INSTALL_9ROUTER=false
  read -p "$(echo -e ${BOLD})Base URL 9Router (contoh: http://43.156.130.205:20128/v1): $(echo -e ${NC})" ROUTER_BASE_URL
  [[ -z "$ROUTER_BASE_URL" ]] && error "Base URL 9Router tidak boleh kosong"
  read -p "$(echo -e ${BOLD})API Key 9Router (sk-...): $(echo -e ${NC})" ROUTER_API_KEY
  log "Akan menggunakan 9Router di: $ROUTER_BASE_URL"
else
  error "Pilihan tidak valid"
fi

# ════════════════════════════════════════
# BAGIAN 3: KONFIGURASI LLM PROVIDER
# ════════════════════════════════════════
section "KONFIGURASI LLM PROVIDER"

info "Pilih provider LLM yang mau digunakan (bisa lebih dari 1):"
info "Provider akan dimasukkan ke smart fallback combo di 9Router"
echo ""

# Array untuk menyimpan provider
declare -a PROVIDERS=()
declare -a PROVIDER_NAMES=()
declare -a PROVIDER_KEYS=()
declare -a PROVIDER_URLS=()
declare -a PROVIDER_PREFIXES=()
declare -a COMBO_MODELS=()

# ─── NVIDIA NIM ──────────────────────────────────────────────
ask "Pakai NVIDIA NIM? (gratis, build.nvidia.com) [y/n]: "
read USE_NVIDIA
if [[ "$USE_NVIDIA" == "y" || "$USE_NVIDIA" == "Y" ]]; then
  read -p "$(echo -e ${BOLD})NVIDIA API Key (nvapi-...): $(echo -e ${NC})" NVIDIA_KEY
  if [[ -n "$NVIDIA_KEY" ]]; then
    PROVIDERS+=("nvidia")
    PROVIDER_NAMES+=("NVIDIA NIM")
    PROVIDER_KEYS+=("$NVIDIA_KEY")
    PROVIDER_URLS+=("https://integrate.api.nvidia.com/v1")
    PROVIDER_PREFIXES+=("nvidia")
    COMBO_MODELS+=("nvidia/meta/llama-3.3-70b-instruct")
    COMBO_MODELS+=("nvidia/deepseek-ai/deepseek-v3.1-terminus")
    COMBO_MODELS+=("nvidia/google/gemma-4-31b-it")
    log "NVIDIA NIM akan diinstall"
  fi
fi

# ─── MIMO XIAOMI ─────────────────────────────────────────────
ask "Pakai MiMo Xiaomi? (gratis, platform.xiaomimimo.com) [y/n]: "
read USE_MIMO
if [[ "$USE_MIMO" == "y" || "$USE_MIMO" == "Y" ]]; then
  read -p "$(echo -e ${BOLD})MiMo API Key (tp-...): $(echo -e ${NC})" MIMO_KEY
  if [[ -n "$MIMO_KEY" ]]; then
    PROVIDERS+=("mimo")
    PROVIDER_NAMES+=("MiMo")
    PROVIDER_KEYS+=("$MIMO_KEY")
    PROVIDER_URLS+=("https://token-plan-sgp.xiaomimimo.com/v1")
    PROVIDER_PREFIXES+=("xiaomi")
    COMBO_MODELS=("xiaomi/mimo-v2.5-pro" "xiaomi/mimo-v2.5" "xiaomi/mimo-v2-omni" "${COMBO_MODELS[@]}")
    log "MiMo Xiaomi akan diinstall"
  fi
fi

# ─── GROQ ────────────────────────────────────────────────────
ask "Pakai Groq? (gratis, Llama ultra-cepat, console.groq.com) [y/n]: "
read USE_GROQ
if [[ "$USE_GROQ" == "y" || "$USE_GROQ" == "Y" ]]; then
  read -p "$(echo -e ${BOLD})Groq API Key (gsk_...): $(echo -e ${NC})" GROQ_KEY
  if [[ -n "$GROQ_KEY" ]]; then
    PROVIDERS+=("groq")
    PROVIDER_NAMES+=("Groq")
    PROVIDER_KEYS+=("$GROQ_KEY")
    PROVIDER_URLS+=("https://api.groq.com/openai/v1")
    PROVIDER_PREFIXES+=("groq")
    COMBO_MODELS+=("groq/llama-3.3-70b-versatile")
    COMBO_MODELS+=("groq/llama-3.1-8b-instant")
    log "Groq akan diinstall"
  fi
fi

# ─── PIONEER AI ──────────────────────────────────────────────
ask "Pakai Pioneer AI? (pioneer.ai) [y/n]: "
read USE_PIONEER
if [[ "$USE_PIONEER" == "y" || "$USE_PIONEER" == "Y" ]]; then
  read -p "$(echo -e ${BOLD})Pioneer API Key (pio_sk_...): $(echo -e ${NC})" PIONEER_KEY
  if [[ -n "$PIONEER_KEY" ]]; then
    PROVIDERS+=("pioneer")
    PROVIDER_NAMES+=("Pioneer AI")
    PROVIDER_KEYS+=("$PIONEER_KEY")
    PROVIDER_URLS+=("https://api.pioneer.ai/v1")
    PROVIDER_PREFIXES+=("pioneer")
    COMBO_MODELS+=("pioneer/meta/llama-3.1-8b-instruct")
    log "Pioneer AI akan diinstall"
  fi
fi

# ─── CUSTOM LLM ──────────────────────────────────────────────
ask "Tambah custom LLM provider lain? [y/n]: "
read USE_CUSTOM
if [[ "$USE_CUSTOM" == "y" || "$USE_CUSTOM" == "Y" ]]; then
  read -p "$(echo -e ${BOLD})Nama provider: $(echo -e ${NC})" CUSTOM_NAME
  read -p "$(echo -e ${BOLD})Base URL (contoh: https://api.example.com/v1): $(echo -e ${NC})" CUSTOM_URL
  read -p "$(echo -e ${BOLD})API Key: $(echo -e ${NC})" CUSTOM_KEY
  read -p "$(echo -e ${BOLD})Prefix model (contoh: custom): $(echo -e ${NC})" CUSTOM_PREFIX
  read -p "$(echo -e ${BOLD})Contoh model name (contoh: gpt-4o): $(echo -e ${NC})" CUSTOM_MODEL
  if [[ -n "$CUSTOM_KEY" && -n "$CUSTOM_URL" ]]; then
    PROVIDERS+=("custom")
    PROVIDER_NAMES+=("$CUSTOM_NAME")
    PROVIDER_KEYS+=("$CUSTOM_KEY")
    PROVIDER_URLS+=("$CUSTOM_URL")
    PROVIDER_PREFIXES+=("$CUSTOM_PREFIX")
    COMBO_MODELS+=("$CUSTOM_PREFIX/$CUSTOM_MODEL")
    log "$CUSTOM_NAME akan diinstall"
  fi
fi

# Cek minimal 1 provider
if [ ${#PROVIDERS[@]} -eq 0 ]; then
  warn "Tidak ada LLM provider yang dipilih!"
  warn "Hermes akan menggunakan model default bawaan."
  USE_DEFAULT_LLM=true
else
  USE_DEFAULT_LLM=false
fi

# ════════════════════════════════════════
# BAGIAN 4: KONFIGURASI CLOUDFLARE TUNNEL
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
      INSTALL_TUNNEL=true
      USE_QUICK_TUNNEL=false
      read -p "$(echo -e ${BOLD})Domain (contoh: yourdomain.com): $(echo -e ${NC})" DOMAIN
      read -p "$(echo -e ${BOLD})Subdomain untuk 9Router (contoh: 9router): $(echo -e ${NC})" SUBDOMAIN
      FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"
      log "Named tunnel: https://$FULL_DOMAIN"
      ;;
    2)
      INSTALL_TUNNEL=true
      USE_QUICK_TUNNEL=true
      log "Quick tunnel akan disetup"
      ;;
    3)
      INSTALL_TUNNEL=false
      log "Tidak pakai tunnel — akses via IP:20128"
      ;;
  esac
fi

# ════════════════════════════════════════
# KONFIRMASI SEBELUM INSTALL
# ════════════════════════════════════════
section "KONFIRMASI INSTALASI"

echo -e "${BOLD}Ringkasan konfigurasi:${NC}"
echo -e "  Agent Name     : ${GREEN}$AGENT_NAME${NC}"
echo -e "  Bahasa         : ${GREEN}$AGENT_LANG${NC}"
echo -e "  Bot Token      : ${GREEN}${TELEGRAM_TOKEN:0:20}...${NC}"
echo -e "  Owner ID       : ${GREEN}$TELEGRAM_OWNER_ID${NC}"
echo -e "  9Router        : ${GREEN}$([ "$INSTALL_9ROUTER" = true ] && echo 'Install baru' || echo "Pakai existing ($ROUTER_BASE_URL)")${NC}"

echo -e "  LLM Providers  :"
for i in "${!PROVIDERS[@]}"; do
  echo -e "    - ${GREEN}${PROVIDER_NAMES[$i]}${NC}"
done

if [ "$INSTALL_TUNNEL" = true ]; then
  if [ "$USE_QUICK_TUNNEL" = true ]; then
    echo -e "  Tunnel         : ${GREEN}Quick tunnel (URL random)${NC}"
  else
    echo -e "  Tunnel         : ${GREEN}Named tunnel → https://$FULL_DOMAIN${NC}"
  fi
fi

echo ""
read -p "$(echo -e ${BOLD})Lanjutkan instalasi? (y/n): $(echo -e ${NC})" CONFIRM
[[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && echo "Instalasi dibatalkan." && exit 0

# ════════════════════════════════════════
# INSTALASI MULAI
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
NODE_VER=$(node -v)
log "Node.js $NODE_VER berhasil diinstall"

# ─── 9ROUTER (OPSIONAL) ──────────────────────────────────────
if [ "$INSTALL_9ROUTER" = true ]; then
  section "FASE 4 — Install 9Router"
  npm install -g 9router -q
  log "9Router berhasil diinstall"

  # Init 9Router
  info "Inisialisasi 9Router..."
  timeout 15 9router --tray --no-browser || true
  sleep 5

  # Systemd service
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
  sleep 10

  if ss -tlnp | grep -q 20128; then
    log "9Router jalan di port 20128"
  else
    warn "9Router belum listen, tunggu..."
    sleep 8
  fi
fi

# ─── CLOUDFLARE TUNNEL ───────────────────────────────────────
if [ "$INSTALL_TUNNEL" = true ]; then
  section "FASE 5 — Install Cloudflared"
  curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    -o /usr/local/bin/cloudflared -s
  chmod +x /usr/local/bin/cloudflared
  log "Cloudflared berhasil diinstall"

  if [ "$USE_QUICK_TUNNEL" = true ]; then
    # Quick tunnel via systemd
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
    sleep 5
    QUICK_URL=$(grep -o 'https://.*trycloudflare.com' /tmp/9router-tunnel.log | head -1)
    log "Quick tunnel aktif: $QUICK_URL"
    warn "URL ini akan berubah setiap restart!"

  else
    # Named tunnel
    echo ""
    warn "Sekarang perlu login ke Cloudflare."
    warn "Salin URL → buka browser → login → pilih domain $DOMAIN → authorize."
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

# ─── SETUP LLM PROVIDERS DI 9ROUTER ─────────────────────────
if [ "$INSTALL_9ROUTER" = true ] && [ ${#PROVIDERS[@]} -gt 0 ]; then
  section "FASE 6 — Setup LLM Providers di 9Router"

  # Generate CLI token
  TOKEN=$(node -e "
const crypto = require('crypto');
const fs = require('fs');
const machineId = fs.readFileSync('/root/.9router/machine-id', 'utf8').trim();
const secret = fs.readFileSync('/root/.9router/auth/cli-secret', 'utf8').trim();
const token = crypto.createHash('sha256').update(machineId + '9r-cli-auth' + secret).digest('hex').substring(0, 16);
console.log(token);
  ")
  log "CLI Token generated"

  # Add setiap provider
  declare -a NODE_IDS=()
  for i in "${!PROVIDERS[@]}"; do
    PNAME="${PROVIDER_NAMES[$i]}"
    PKEY="${PROVIDER_KEYS[$i]}"
    PURL="${PROVIDER_URLS[$i]}"
    PPREFIX="${PROVIDER_PREFIXES[$i]}"

    info "Menambahkan $PNAME..."
    NODE_ID=$(curl -s -H "x-9r-cli-token: $TOKEN" -H "Content-Type: application/json" \
      -X POST http://localhost:20128/api/provider-nodes \
      -d "{\"type\":\"openai-compatible\",\"apiType\":\"chat\",\"name\":\"$PNAME\",\"prefix\":\"$PPREFIX\",\"baseUrl\":\"$PURL\"}" \
      | python3 -c "import sys,json;print(json.load(sys.stdin)['node']['id'])" 2>/dev/null || echo "")

    if [[ -n "$NODE_ID" ]]; then
      curl -s -H "x-9r-cli-token: $TOKEN" -H "Content-Type: application/json" \
        -X POST http://localhost:20128/api/providers \
        -d "{\"provider\":\"$NODE_ID\",\"apiKey\":\"$PKEY\",\"name\":\"$PNAME\"}" > /dev/null
      NODE_IDS+=("$NODE_ID")
      log "$PNAME berhasil ditambahkan"
    else
      warn "Gagal tambah $PNAME — bisa ditambah manual di dashboard"
    fi
  done

  # Buat combo smart fallback
  info "Membuat combo smart_fallback..."
  COMBO_PAYLOAD=$(python3 -c "
import json
models = $(python3 -c "import json; print(json.dumps(${COMBO_MODELS[@]@Q}.split()))" 2>/dev/null || echo '[]')
print(json.dumps({'name': 'free_smart_fallback', 'description': 'Smart fallback combo', 'models': [m for m in '''${COMBO_MODELS[*]}'''.split()]}))
  " 2>/dev/null || echo '{"name":"free_smart_fallback","models":[]}')

  MODELS_JSON="["
  for i in "${!COMBO_MODELS[@]}"; do
    [[ $i -gt 0 ]] && MODELS_JSON+=","
    MODELS_JSON+="\"${COMBO_MODELS[$i]}\""
  done
  MODELS_JSON+="]"

  COMBO_ID=$(curl -s -H "x-9r-cli-token: $TOKEN" -H "Content-Type: application/json" \
    -X POST http://localhost:20128/api/combos \
    -d '{"name":"free_smart_fallback","description":"Smart fallback combo"}' \
    | python3 -c "import sys,json;print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "")

  if [[ -n "$COMBO_ID" ]]; then
    curl -s -H "x-9r-cli-token: $TOKEN" -H "Content-Type: application/json" \
      -X PUT http://localhost:20128/api/combos/$COMBO_ID \
      -d "{\"name\":\"free_smart_fallback\",\"models\":$MODELS_JSON}" > /dev/null
    log "Combo free_smart_fallback berhasil dibuat dengan ${#COMBO_MODELS[@]} model"
  fi

  # Buat API key untuk agent
  info "Membuat API Key untuk $AGENT_NAME..."
  AGENT_API_KEY=$(curl -s -H "x-9r-cli-token: $TOKEN" -H "Content-Type: application/json" \
    -X POST http://localhost:20128/api/keys \
    -d "{\"name\":\"$AGENT_NAME\"}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('key', d.get('apiKey', '')))" 2>/dev/null || echo "")

  if [[ -z "$AGENT_API_KEY" ]]; then
    warn "API key belum bisa dibuat otomatis — buat manual di dashboard"
    AGENT_API_KEY="BUAT_MANUAL_DI_DASHBOARD"
  else
    log "API Key agent berhasil dibuat: ${AGENT_API_KEY:0:20}..."
  fi

elif [ "$INSTALL_9ROUTER" = false ]; then
  AGENT_API_KEY="$ROUTER_API_KEY"
fi

# ─── INSTALL HERMES ──────────────────────────────────────────
section "FASE 7 — Install Hermes"
python3 -m venv /root/hermes-env
source /root/hermes-env/bin/activate
pip install hermes-agent -q
HERMES_VER=$(hermes --version 2>/dev/null | head -1)
log "$HERMES_VER berhasil diinstall"

# ─── SETUP .ENV ──────────────────────────────────────────────
section "FASE 8 — Setup Konfigurasi"
mkdir -p /root/.hermes

# Build env file
cat > /root/.hermes/.env << EOF
TELEGRAM_BOT_TOKEN=$TELEGRAM_TOKEN
TELEGRAM_OWNER_ID=$TELEGRAM_OWNER_ID
TELEGRAM_ALLOWED_USERS=$TELEGRAM_OWNER_ID
OPENAI_API_KEY=${AGENT_API_KEY:-sk-placeholder}
OPENAI_BASE_URL=${ROUTER_BASE_URL}
EOF

# Tambah API keys LLM ke env
for i in "${!PROVIDERS[@]}"; do
  PNAME_UPPER=$(echo "${PROVIDERS[$i]}" | tr '[:lower:]' '[:upper:]')
  echo "${PNAME_UPPER}_API_KEY=${PROVIDER_KEYS[$i]}" >> /root/.hermes/.env
done

chmod 600 /root/.hermes/.env
log ".env berhasil dibuat"

# ─── SETUP MODEL ─────────────────────────────────────────────
hermes config set model.provider custom 2>/dev/null || true
hermes config set model.name free_smart_fallback 2>/dev/null || true
hermes config set model.base_url "${ROUTER_BASE_URL}" 2>/dev/null || true
hermes config set model.api_key "${AGENT_API_KEY:-sk-placeholder}" 2>/dev/null || true
hermes config set model.api_mode chat_completions 2>/dev/null || true
log "Model terset ke free_smart_fallback"

# ─── SETUP SOUL.MD ───────────────────────────────────────────
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
- Istilah teknis: tetap English (API, deploy, smart contract, endpoint, dll)
- Tone: direct, no preamble, no hype, no sycophancy
- Jawab singkat dan langsung ke inti — jangan pembuka seperti "pertanyaan bagus!"
- Kalau tidak tahu, bilang jujur — jangan mengarang

# Capabilities
# [EDIT: isi dengan akun, tool, wallet, email, platform yang bisa dipakai agent]
# Contoh:
# - Server VPS: akses via terminal lokal
# - GitHub: PAT tersimpan di ~/.hermes/.env
# - Email: -
# - Browser: via web_fetch dan web_search tool

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
- Private data tetap private — jangan bocorkan ke group chat atau multi-user session
- Credentials tidak pernah muncul verbatim di output — selalu reference by path
- Bukan proxy user di group chat — aku partisipan terpisah
- Jangan simpan credential apapun langsung di memory

# Memory Rules
- Simpan: preferensi user, workflow yang disetujui, koreksi, fakta stabil tentang project
- Jangan simpan: credential, password, private key, task yang sudah selesai, data sementara
- Bedakan: memory (always-on facts) vs skills (prosedur/cara kerja)

# Resource Management
- Pola: start → use → stop
- Jangan biarkan service atau container idle tanpa alasan
- Long-lived process (server, monitor) adalah pengecualian yang harus di-noted

# Verification
- Setelah eksekusi command: cek exit code dan output aktual
- Setelah edit file: baca ulang bagian yang diubah
- Setelah install: verifikasi dengan version check atau test sederhana
- Jangan klaim berhasil kalau belum diverifikasi

# Escalation
- Berhenti dan minta bantuan kalau: error berulang >3x dengan approach berbeda
- Berhenti kalau: aksi berikutnya irreversible dan tidak yakin
- Berhenti kalau: ada konflik antara instruksi user dan boundaries di atas
- Eskalasi dengan jelas: jelaskan apa yang terjadi, apa yang sudah dicoba, apa yang dibutuhkan

# Default Disposition
- Asumsi: user tahu apa yang mereka lakukan
- Kalau request terlihat aneh: tanya konteks dulu, jangan langsung refuse atau lecture
- 1-2 pertanyaan spesifik jauh lebih berguna dari 1 paragraf caveats
- Kalau ada ambiguitas: tanya, bukan asumsikan
ENDSOUL
else
cat > /root/.hermes/SOUL.md << ENDSOUL
# Identity
Name: $AGENT_NAME
Role: Familiar / AI Assistant
Language: English for all interactions and files
Relation: Partner — not just an assistant

# Communication
- All interactions: English
- File, code, documentation: English
- Emoji: use sparingly when appropriate
- Technical terms: keep as-is (API, deploy, endpoint, etc.)
- Tone: direct, no preamble, no hype, no sycophancy
- Answer concisely and directly — no openers like "great question!"
- If uncertain: say so honestly — never fabricate

# Capabilities
# [EDIT: fill in accounts, tools, wallets, emails, platforms agent can use]
# Example:
# - VPS Server: local terminal access
# - GitHub: PAT stored in ~/.hermes/.env
# - Email: -
# - Browser: via web_fetch and web_search tool

# Autonomy
## Fully autonomous (no permission needed)
- Read files, read logs, check system status
- Run read-only commands (ls, cat, ps, df, free)
- Web search and fetch public information
- Answer questions and analyze data

## Autonomous + log (runs but logged)
- Install Python/npm packages
- Edit configuration files
- Restart already-running services

## Must confirm (always ask permission)
- Send email, messages, or post to public platforms
- Delete files or databases
- Deploy to production
- Financial transactions or fund transfers
- Any irreversible actions

# Boundaries
- Private data stays private — never leak to group chats or multi-user sessions
- Credentials never appear verbatim in output — always reference by path
- Not a user proxy in group chats — I am a separate participant
- Never store credentials directly in memory

# Memory Rules
- Store: user preferences, approved workflows, corrections, stable project facts
- Don't store: credentials, passwords, private keys, completed tasks, temporary data
- Distinguish: memory (always-on facts) vs skills (procedures)

# Resource Management
- Pattern: start → use → stop
- Don't leave services or containers idle without reason
- Long-lived processes (servers, monitors) are exceptions that must be noted

# Verification
- After executing commands: check exit code and actual output
- After editing files: re-read the changed sections
- After installing: verify with version check or simple test
- Never claim success without verification

# Escalation
- Stop and ask for help if: same error repeats >3x with different approaches
- Stop if: next action is irreversible and uncertain
- Stop if: conflict between user instructions and boundaries above
- Escalate clearly: explain what happened, what was tried, what is needed

# Default Disposition
- Assume: user knows what they are doing
- If request looks unusual: ask for context first, don't refuse or lecture
- 1-2 specific questions >> 1 paragraph of caveats
- If ambiguous: ask, don't assume
ENDSOUL
fi
log "SOUL.md berhasil dibuat untuk $AGENT_NAME"

# ─── SETUP MEMORY ────────────────────────────────────────────
section "FASE 10 — Setup Memory"
hermes memory setup << 'MEMEOF'


0.5
1024
MEMEOF
log "Memory holographic berhasil disetup"

# ─── INSTALL GATEWAY ─────────────────────────────────────────
section "FASE 11 — Install Gateway Service"
hermes gateway install
hermes gateway start
sleep 5

GATEWAY_STATUS=$(hermes gateway status 2>/dev/null | grep -c "running" || echo "0")
if [ "$GATEWAY_STATUS" -gt 0 ]; then
  log "Hermes Gateway aktif dan jalan"
else
  warn "Gateway mungkin butuh waktu untuk start — cek dengan: hermes gateway status"
fi

# ════════════════════════════════════════
# SELESAI
# ════════════════════════════════════════
section "INSTALASI SELESAI!"

# Simpan info instalasi
cat > /root/.hermes/install-info.txt << EOF
AI Agent Starter Kit — Install Info
====================================
Agent Name    : $AGENT_NAME
Install Date  : $(date)
Hermes        : $(hermes --version 2>/dev/null | head -1)
9Router       : $([ "$INSTALL_9ROUTER" = true ] && echo "Installed" || echo "External: $ROUTER_BASE_URL")
LLM Providers : ${PROVIDER_NAMES[*]}
API Key       : $AGENT_API_KEY
Dashboard     : $([ -n "$FULL_DOMAIN" ] && echo "https://$FULL_DOMAIN" || echo "http://localhost:20128")
EOF

echo -e "${BOLD}${GREEN}🎉 $AGENT_NAME berhasil diinstall!${NC}\n"
echo -e "${BOLD}Ringkasan:${NC}"
echo -e "  Agent          : ${GREEN}$AGENT_NAME${NC}"
echo -e "  Bahasa         : ${GREEN}$AGENT_LANG${NC}"
echo -e "  LLM Providers  : ${GREEN}${PROVIDER_NAMES[*]}${NC}"
echo -e "  Model          : ${GREEN}free_smart_fallback${NC}"
echo -e "  Memory         : ${GREEN}Holographic (local)${NC}"
echo -e "  Gateway        : ${GREEN}Active${NC}"

if [ -n "$FULL_DOMAIN" ]; then
  echo -e "  Dashboard      : ${GREEN}https://$FULL_DOMAIN${NC}"
elif [ "$INSTALL_9ROUTER" = true ]; then
  echo -e "  Dashboard      : ${GREEN}http://$(curl -s ifconfig.me):20128${NC}"
fi

if [ "$AGENT_API_KEY" = "BUAT_MANUAL_DI_DASHBOARD" ]; then
  echo ""
  echo -e "${YELLOW}⚠️  LANGKAH TAMBAHAN DIPERLUKAN:${NC}"
  echo -e "  1. Buka dashboard 9Router"
  echo -e "  2. Endpoint → New Key → nama '$AGENT_NAME' → copy key"
  echo -e "  3. Update: nano /root/.hermes/.env → isi OPENAI_API_KEY"
  echo -e "  4. Update: hermes config set model.api_key <key>"
  echo -e "  5. Restart: source /root/hermes-env/bin/activate && hermes gateway restart"
fi

echo ""
echo -e "${BOLD}Command berguna:${NC}"
echo -e "  ${CYAN}source /root/hermes-env/bin/activate${NC}  # aktifkan Hermes"
echo -e "  ${CYAN}hermes gateway status${NC}                 # cek status bot"
echo -e "  ${CYAN}hermes gateway restart${NC}                # restart bot"
echo -e "  ${CYAN}systemctl status 9router${NC}              # cek 9Router"
echo -e "  ${CYAN}cat /root/.hermes/install-info.txt${NC}    # lihat info instalasi"
echo ""
echo -e "${BOLD}${CYAN}Selamat menggunakan $AGENT_NAME! 🚀${NC}"
echo -e "${CYAN}Info lengkap: cat README.md${NC}"
