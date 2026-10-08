# IoT Essentials - Raspberry Pi 5 Auto-Setup

Eén script om een verse installatie van Raspberry Pi OS (Debian Bookworm) direct speelklaar te maken voor alle labo's van **IoT Essentials** aan Thomas More Geel.

## Wat doet dit script?
- ✅ Installeert alle benodigde build-tools en drivers (`swig`, `liblgpio-dev`, `mosquitto`, `mpd`, `i2c-tools`).
- ✅ Schakelt automatisch **I2C** en **SPI** in zonder gedoe met menu's.
- ✅ Start en activeert achtergronddiensten (lokale Mosquitto MQTT broker).
- ✅ Creëert de centrale Virtual Environment in `~/env` met `--system-site-packages`.
- ✅ Installeert CircuitPython, Blinka, lgpio, BMP280, SSD1306 en MQTT libraries.
- ✅ Voegt automatische venv-activatie toe aan `~/.bashrc` (nooit meer `externally-managed-environment` fouten).
- ✅ Bevat optionele ondersteuning voor MariaDB en OpenCV/YOLO.

## Gebruik op de Raspberry Pi

Open een terminal (lokaal of via SSH) en voer uit:

```bash
git clone https://github.com/<jouw-username>/<jouw-repo>.git
cd <jouw-repo>
chmod +x setup.sh
./setup.sh
```

Zodra het script klaar is, herstart je de Pi eenmalig:
```bash
sudo reboot
```
