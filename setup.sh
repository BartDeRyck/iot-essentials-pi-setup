#!/usr/bin/env bash
# ==============================================================================
# IoT Essentials - Raspberry Pi 5 Auto-Setup & Bootstrap Script
# Auteur: Bart De Ryck & Thomas More IT Student Community
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}  🚀 Start IoT Essentials Auto-Setup (Raspberry Pi 5) ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# 1. Veiligheidscontrole: Niet uitvoeren als root direct
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}[FOUT] Voer dit script uit als je normale gebruiker (bv. pi), NIET direct met 'sudo ./setup.sh'!${NC}"
    echo "Het script vraagt zelf om sudo waar nodig. Dit voorkomt dat je venv in /root terechtkomt."
    exit 1
fi

CURRENT_USER="$USER"
USER_HOME="$HOME"
VENV_DIR="$USER_HOME/env"

echo -e "${YELLOW}>> Gebruiker: $CURRENT_USER | Home: $USER_HOME${NC}"

# 2. APT Systeem Updates & Basis Systeempakketten
echo -e "\n${BLUE}[Stap 1/6] Systeempakketten bijwerken en installeren via apt...${NC}"
sudo apt update -y
sudo apt install -y \
    git \
    curl \
    wget \
    build-essential \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-setuptools \
    swig \
    liblgpio-dev \
    python3-lgpio \
    i2c-tools \
    mosquitto \
    mosquitto-clients \
    python3-pil \
    mpd \
    mpc \
    alsa-utils

# 3. Hardware interfaces inschakelen (I2C en SPI via non-interactive raspi-config)
echo -e "\n${BLUE}[Stap 2/6] Hardware interfaces (I2C & SPI) inschakelen...${NC}"
if command -v raspi-config >/dev/null 2>&1; then
    sudo raspi-config nonint do_i2c 0
    sudo raspi-config nonint do_spi 0
    echo -e "${GREEN}✓ I2C en SPI interfaces geactiveerd.${NC}"
else
    echo -e "${YELLOW}! raspi-config niet gevonden. Controleer interfaces handmatig.${NC}"
fi

# 4. Systeemdiensten inschakelen en starten
echo -e "\n${BLUE}[Stap 3/6] Systeemdiensten inschakelen (Mosquitto & MPD)...${NC}"
sudo systemctl enable --now mosquitto
sudo systemctl enable --now mpd
echo -e "${GREEN}✓ Mosquitto broker en MPD radio deamon actief.${NC}"

# 5. Virtual Environment opzetten (~/env conform lesmethode)
echo -e "\n${BLUE}[Stap 4/6] Virtual Environment instellen in $VENV_DIR...${NC}"
if [ ! -d "$VENV_DIR" ]; then
    echo "Aanmaken van venv met --system-site-packages..."
    python3 -m venv --system-site-packages "$VENV_DIR"
    echo -e "${GREEN}✓ Virtual environment aangemaakt.${NC}"
else
    echo -e "${YELLOW}✓ Bestaande venv gevonden in $VENV_DIR. Overslaan aanmaken.${NC}"
fi

"$VENV_DIR/bin/pip" install --upgrade pip setuptools wheel

# 6. Python packages installeren
echo -e "\n${BLUE}[Stap 5/6] Python dependencies installeren in de venv...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/requirements.txt" ]; then
    "$VENV_DIR/bin/pip" install -r "$SCRIPT_DIR/requirements.txt"
    echo -e "${GREEN}✓ Core Python libraries geïnstalleerd.${NC}"
else
    echo -e "${RED}[FOUT] requirements.txt niet gevonden in $SCRIPT_DIR!${NC}"
    exit 1
fi

# 7. Automatische activatie in ~/.bashrc (Idempotent!)
echo -e "\n${BLUE}[Stap 6/6] Automatische venv activatie instellen in ~/.bashrc...${NC}"
BASHRC="$USER_HOME/.bashrc"
ACTIVATE_LINE="source $VENV_DIR/bin/activate"

if grep -Fxq "$ACTIVATE_LINE" "$BASHRC"; then
    echo -e "${YELLOW}✓ Activatieregel staat reeds in $BASHRC.${NC}"
else
    echo "" >> "$BASHRC"
    echo "# Automatische activatie IoT Essentials (Thomas More)" >> "$BASHRC"
    echo "$ACTIVATE_LINE" >> "$BASHRC"
    echo -e "${GREEN}✓ Activatieregel toegevoegd aan $BASHRC.${NC}"
fi

# Optionele vraag voor zware modules (Module 8: DB & AI)
echo -e "\n${YELLOW}-----------------------------------------------------${NC}"
read -rp "Wil je ook de optionele zware modules installeren (MariaDB/Apache & AI/OpenCV/YOLO)? (j/N): " answer
if [[ "$answer" =~ ^[jJyY]$ ]]; then
    echo -e "\n${BLUE}>> Installeren van optionele APT pakketten (DB, Webserver, AI, Audio, Vision)...${NC}"
    sudo apt install -y \
        mariadb-server \
        php-mysql \
        libmariadb-dev \
        apache2 \
        portaudio19-dev \
        python3-pyaudio \
        libopencv-dev \
        python3-opencv \
        tesseract-ocr \
        libtesseract-dev

    if [ -f "$SCRIPT_DIR/requirements-extra.txt" ]; then
        echo ">> Installeren van optionele Python packages..."
        "$VENV_DIR/bin/pip" install -r "$SCRIPT_DIR/requirements-extra.txt"
    fi
    echo -e "${GREEN}✓ Optionele modules geïnstalleerd.${NC}"
fi

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}  🎉 Installatie succesvol afgerond!                ${NC}"
echo -e "${GREEN}=====================================================${NC}"
echo -e "Belangrijk:"
echo -e "1. ${YELLOW}Herstart de Pi eenmalig${NC} via: '${BLUE}sudo reboot${NC}' om de I2C/SPI hardware bussen definitief te activeren."
echo -e "2. Bij elke nieuwe terminalsessie staat je omgeving direct in '${BLUE}(env)${NC}'."
echo -e "3. Snelle test: '${BLUE}python3 -c \"import board, digitalio; print('Blinka werkt!')\"${NC}'"
