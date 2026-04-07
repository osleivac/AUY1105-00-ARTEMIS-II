#!/bin/bash
# ─────────────────────────────────────────────────────────────
# install.sh  –  Aprovisionamiento EC2 Ubuntu 24.04 LTS
# ─────────────────────────────────────────────────────────────
set -euo pipefail
LOG="/var/log/install.log"
exec > >(tee -a "$LOG") 2>&1

echo "=============================="
echo "Inicio de aprovisionamiento EC2"
echo "Fecha: $(date)"
echo "=============================="

handle_error() {
  echo "ERROR: Fallo en el paso $1. Revisa $LOG"
  exit 1
}

# 1. Actualizar e instalar dependencias (apt)
export DEBIAN_FRONTEND=noninteractive
apt-get update -y || handle_error "1.1 (apt-get update)"
apt-get install -y curl unzip python3-pip software-properties-common || handle_error "1.2 (apt install)"

# 2. Instalar Checkov
pip3 install checkov --break-system-packages || handle_error "2 (pip3 install checkov)"

# 3. Instalar Terraform (HashiCorp Repo)
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update -y && apt-get install terraform -y || handle_error "3 (Instalar Terraform)"

# 4. Instalar TFLint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash || handle_error "4 (Instalar TFLint)"

# 5. Instalar OPA
curl -sSL "https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static" -o /usr/local/bin/opa || handle_error "5.1 (descarga OPA)"
chmod +x /usr/local/bin/opa || handle_error "5.2 (chmod OPA)"

echo "[✓] Instalación completada con éxito."