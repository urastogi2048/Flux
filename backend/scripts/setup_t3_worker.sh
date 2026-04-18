#!/usr/bin/env bash
set -Eeuo pipefail

# One-file setup for Ubuntu LTS on AWS t3.micro (10 GB disk friendly).
# Installs system packages (Python, Tesseract, Poppler), creates venv,
# installs worker dependencies, writes env template, and configures systemd.

APP_USER="${APP_USER:-ubuntu}"
APP_DIR="${APP_DIR:-/opt/flux}"
BACKEND_DIR="${BACKEND_DIR:-${APP_DIR}/backend}"
VENV_DIR="${VENV_DIR:-${BACKEND_DIR}/.venv}"
ENV_FILE="${ENV_FILE:-${BACKEND_DIR}/.env}"
SERVICE_NAME="${SERVICE_NAME:-flux-worker}"
REPO_URL="${REPO_URL:-}"
REPO_BRANCH="${REPO_BRANCH:-main}"
INSTALL_SERVICE="${INSTALL_SERVICE:-1}"

export DEBIAN_FRONTEND=noninteractive

log() {
  echo "[setup] $*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

if [ "${EUID}" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    log "Re-running with sudo"
    exec sudo -E bash "$0"
  else
    echo "Run as root or install sudo." >&2
    exit 1
  fi
fi

require_cmd apt-get

log "Installing system dependencies (minimal footprint)"
apt-get update -y
apt-get install -y --no-install-recommends \
  ca-certificates \
  git \
  python3 \
  python3-pip \
  python3-venv \
  build-essential \
  libpq-dev \
  tesseract-ocr \
  poppler-utils

log "Cleaning apt cache to save disk"
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

if ! id -u "${APP_USER}" >/dev/null 2>&1; then
  echo "User ${APP_USER} does not exist. Set APP_USER or create the user first." >&2
  exit 1
fi

if [ ! -d "${APP_DIR}" ]; then
  mkdir -p "${APP_DIR}"
fi

chown -R "${APP_USER}:${APP_USER}" "${APP_DIR}"

if [ ! -d "${BACKEND_DIR}" ]; then
  if [ -z "${REPO_URL}" ]; then
    echo "Backend directory ${BACKEND_DIR} not found and REPO_URL is empty." >&2
    echo "Set REPO_URL to auto-clone, or copy your repo to ${APP_DIR}." >&2
    exit 1
  fi

  log "Cloning repository"
  sudo -u "${APP_USER}" git clone --depth 1 --branch "${REPO_BRANCH}" "${REPO_URL}" "${APP_DIR}"
fi

if [ ! -f "${BACKEND_DIR}/worker_requirement.txt" ]; then
  echo "Could not find worker requirements at ${BACKEND_DIR}/worker_requirement.txt" >&2
  exit 1
fi

log "Creating Python virtual environment and installing worker dependencies"
sudo -u "${APP_USER}" bash -lc "
  set -Eeuo pipefail
  cd '${BACKEND_DIR}'
  python3 -m venv '${VENV_DIR}'
  source '${VENV_DIR}/bin/activate'
  python -m pip install --upgrade pip setuptools wheel
  pip install --no-cache-dir -r worker_requirement.txt
"

if [ ! -f "${ENV_FILE}" ]; then
  log "Creating ${ENV_FILE} template"
  cat > "${ENV_FILE}" <<'EOF'
AWS_ACCESS_KEY=
AWS_SECRET_KEY=
AWS_REGION=ap-south-1
S3_BUCKET=flux-ngouploads
DATABASE_URL=

# Linux defaults for OCR binaries.
TESSERACT_CMD=/usr/bin/tesseract
POPPLER_PATH=
EOF
  chown "${APP_USER}:${APP_USER}" "${ENV_FILE}"
  chmod 600 "${ENV_FILE}"
fi

if [ "${INSTALL_SERVICE}" = "1" ]; then
  log "Creating systemd worker service: ${SERVICE_NAME}"
  cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=Flux OCR Worker
After=network.target

[Service]
Type=simple
User=${APP_USER}
Group=${APP_USER}
WorkingDirectory=${BACKEND_DIR}
EnvironmentFile=${ENV_FILE}
Environment=PYTHONUNBUFFERED=1
ExecStart=${VENV_DIR}/bin/python worker.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable "${SERVICE_NAME}"
  systemctl restart "${SERVICE_NAME}"
fi

log "Verifying OCR binaries"
which tesseract
tesseract --version | head -n 1
which pdftoppm

log "Setup complete"
echo
echo "Next steps:"
echo "1) Edit ${ENV_FILE} with real AWS and DATABASE_URL values"
echo "2) Restart service: sudo systemctl restart ${SERVICE_NAME}"
echo "3) Stream logs:    sudo journalctl -u ${SERVICE_NAME} -f"