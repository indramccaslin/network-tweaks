# Network Tweaks

[![GitHub release](https://img.shields.io/github/v/release/indramccaslin/network-tweaks?style=for-the-btag-square&color=22d3ee)](https://github.com/indramccaslin/network-tweaks/releases)
[![GitHub stars](https://img.shields.io/github/stars/indramccaslin/network-tweaks?style=for-the-badge&color=4f9bff)](https://github.com/indramccaslin/network-tweaks/stargazers)
[![License: MIT](https://img.shields.io/badge/License-MIT-34e3a4.svg?style=for-the-badge)](LICENSE)

Modern Magisk/KernelSU/KernelSU-Next module untuk mengoptimalkan stack jaringan Android demi latensi yang lebih rendah, koneksi lebih stabil, dan throughput maksimal sesuai kebutuhan.

---

## Features

- **4 Mode Profil** – `Global` (restore stok), `Gaming` (ultra low latency), `Streaming` (stabil & smooth), `Download` (max throughput)
- **Game Auto-Detection** – Otomatis switch ke profil `GAME` saat aplikasi di daftar game berada di foreground (hanya mode Gaming)
- **TCP Tuning** – Atur `tcp_congestion_control` (BBR/CUBIC/reno/dll), `tcp_fastopen`, `tcp_autocorking`, `tcp_slow_start_after_idle`, `tcp_no_metrics_save`, dan lainnya
- **Buffers & Backlog** – Pengaturan `rmem/wmem`, `tcp_rmem/tcp_wmem`, `somaxconn`, `netdev_max_backlog`, `tcp_max_syn_backlog`
- **QoS / Packet Scheduler** – Pilihan `fq`, `fq_codel`, `cake`, `pfifo_fast`
- **Latency Boost** – `tcp_notsent_lowat`, `busy_poll`, `busy_read` khusus untuk permainan online
- **MTU Custom** – Atur MTU interface secara manual (opsional)
- **DNS Custom** – Atur DNS kustom dan bisa otomatis overwrite `/etc/resolv.conf`
- **Modern WebUI** – Glassmorphism, glow cyan, modal app picker, toast notification, auto-detect nilai kernel aktif
- **Boot-safe & Auto-Apply** – Tanpa daemon berat, `service.sh` hanya deteksi foreground & apply via sysctl/ip link

---

## Compatibility

| Root Method | Status |
|---|---|
| **KernelSU-Next** | Tested & Recommended |
| **KernelSU** | Supported |
| **Magisk** | Supported |
| **APatch** | Supported (fallback update-binary) |

**Notes:** Butuh kernel yang expose `sysctl` jaringan (`/proc/sys/net/*`). Mayoritas kernel custom/stok modern mendukungnya.

---

## Installation

1. Download file `.zip` terbaru dari [Releases](https://github.com/indramccaslin/network-tweaks/releases)
2. Buka **KernelSU-Next / Magisk / APatch** → **Modules** → **Install from storage** → pilih `Network-Tweaks-vX.Y.Z.zip`
3. Tunggu instalasi selesai, **reboot** (disarankan)
4. Buka module **Network Tweaks** → **WebUI** untuk mulai mengatur

---

## Usage

### 1) Pilih Mode
Buka WebUI lalu pilih salah satu mode:

| Mode | Deskripsi | Saat dipakai |
|---|---|---|
| **Global** | Mengembalikan semua nilai jaringan ke kondisi sebelum module aktif | Pemakaian harian / kalo pengen netral |
| **Gaming** | Profil ultra low-latency dengan game auto-detect | Main game online (MLBB, PUBG Mobile, FF, dll) |
| **Streaming** | Seimbang antara latency & stabilitas | Youtube, Netflix, Twitch, Disney+, dll |
| **Download** | Buffer besar, backlog tinggi, fokus throughput | Unduh file besar, speedtest, torrenting |

### 2) Tambahkan Game (Mode Gaming)
Hanya muncul di mode **Gaming**:

1. Ketik manual nama paket (`com.mobile.legends`) atau tekan **Pilih dari Aplikasi**
2. Pilih game yang ingin di-auto apply
3. Simpan & Terapkan

Saat game tersebut aktif di foreground, module akan otomatis menerapkan profil **GAME**. Saat keluar game, akan kembali ke profil **BASE**.

### 3) Pengaturan Lanjutan
Kamu bisa mengubah langsung nilai berikut dari WebUI:

- **TCP & Congestion** – Algoritma, Fast Open, autocorking, slow-start-after-idle, metrics
- **Buffers & Backlog** – rmem/wmem, tcp_rmem/tcp_wmem, somaxconn, netdev_max_backlog, qdisc
- **Latency Boost** – notsent_lowat, busy_poll, busy_read
- **MTU** – Atur secara custom atau biarkan auto (0)
- **DNS** – Cloudflare (1.1.1.1/1.0.0.1), Google (8.8.8.8/8.8.4.4), atau custom lain

---

## WebUI Preview

- **Hero Header** – Mode, Congestion, Qdisc realtime
- **Mode Selector** – Card interaktif dengan glow
- **Game List** – Auto-detect + app picker
- **TCP & QoS Cards** – Pengaturan terpisah per kategori
- **Toast Notification** – Konfirmasi saat simpan/terapkan
- **Responsive Design** – Nyaman di layar HP

---

## File Structure
```text
network-tweaks/
├── META-INF/           # Installer Magisk/KernelSU
├── webroot/            # Modern WebUI
│   └── index.html
├── build.sh            # Build zip flashable
├── customize.sh        # Post-install script
├── gamelist.txt        # Daftar game untuk auto-detect
├── module.prop         # Info module
├── README.md
├── service.sh          # Worker service (foreground detection + sysctl apply)
├── tweak.conf          # Konfigurasi utama & profil (GAME/STREAM/DOWNLOAD/BASE)
└── uninstall.sh        # Restore pengaturan saat uninstall
```

---

## Troubleshooting

| Masalah | Solusi |
|---|---|
| **WebUI kebuka browser / error `mui.kernelsu.org`** | Copy `webroot/index.html` ke `/data/adb/modules/network-tweaks/webroot/`, lalu *Force Stop* aplikasi KernelSU-Next (atau clear cache aplikasi). Tidak perlu reboot. |
| **BBR tidak muncul** | Cek `cat /proc/sys/net/ipv4/tcp_available_congestion_control`. Jika tidak ada BBR, kernel kamu belum support. Bisa pakai `cubic`. |
| **Setting tidak berubah** | Pastikan mode bukan `Global`. Di mode `Global`, module akan restore ke stok. Gunakan `Gaming/Streaming/Download`. |
| **DNS tidak berubah di jaringan tertentu** | Beberapa VPN/Private DNS bisa override. Coba matikan Private DNS di pengaturan jaringan. |
| **Ping/latency malah naik** | Coba turunkan `busy_poll` / `busy_read` atau kembali ke default. Tidak semua kernel cocok dengan busy polling. |

---

## Disclaimer

- Module ini mengubah nilai sysctl jaringan. Penggunaan pada jaringan tertentu sangat jarang bermasalah, tapi tetap resiko pengguna sendiri.
- `busy_poll` bisa meningkatkan konsumsi CPU sedikit.
- `MTU` yang salah bisa bikin koneksi lambat/putus.
- Module ini **gratis & open source**. Jangan reupload zip mentah tanpa credit.

---

## License

[MIT License](LICENSE)

## Author

**GANÉS** – [@indramccaslin](https://github.com/indramccaslin)
