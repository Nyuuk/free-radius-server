# FreeRADIUS with PostgreSQL Setup Guide

Pedoman langkah demi langkah untuk menjalankan FreeRADIUS Server dengan backend database PostgreSQL menggunakan Docker Compose.

## 🚀 Persiapan Cepat (Quick Start)

1. **Jalankan Container**
   Pastikan Anda berada di direktori `infrastructure/free-radius`, lalu jalankan:
   ```bash
   docker-compose up -d
   ```

2. **Verifikasi Status**
   Cek apakah kedua layanan (database dan freeradius) sudah berjalan:
   ```bash
   docker-compose ps
   ```

---

## 🏗️ Struktur Proyek

- `docker-compose.yaml`: Definisi service DB (Postgres 15) dan FreeRADIUS.
- `config/`: Berisi konfigurasi mounting untuk `clients.conf` (definisi router) dan module `sql`.
- `radius-schema/`: Berisi file SQL untuk inisialisasi database PostgreSQL.
- `Dockerfile`: Resep build FreeRADIUS v3.2.x dengan dukungan PostgreSQL module.

---

## 💾 Langkah Migrasi / Inisialisasi Database

Setelah container database berjalan, Anda perlu memasukkan skema (tabel) FreeRADIUS ke dalam PostgreSQL.

### 1. Masuk ke Container Database
```bash
docker exec -it radius-db bash
```

### 2. Jalankan Skema Utama
Masuk ke direktori schema dan eksekusi `schema.sql`. Kita akan menggunakan user `radius` yang sudah dibuat otomatis via environment variable di `docker-compose.yaml`.

```bash
# Di dalam container radius-db
psql -U radius -d radius -f /radius-schema/postgresql/schema.sql
```
*(Catatan: Folder `/radius-schema` di dalam container dipetakan ke direktori lokal `./radius-schema`)*

### 3. Jalankan Setup Hak Akses (Opsional)
Jika Anda ingin mengatur izin akses yang lebih spesifik atau memastikan sequence diatur dengan benar:
```bash
psql -U radius -d radius -f /radius-schema/postgresql/setup.sql
```
*Note: Jika muncul error "role 'radius' already exists", itu normal karena user sudah dibuat oleh Docker Compose.*

### 4. Aktivasi Fitur Lanjutan (Reporting & Accounting)
Sangat disarankan untuk menjalankan skema tambahan untuk pengolahan data pemakaian (bandwidth):
```bash
psql -U radius -d radius -f /radius-schema/postgresql/process-radacct.sql
```

---

## ⚙️ Penyesuaian Konfigurasi

### Menambah Router (NAS)
Edit file `config/clients.conf` untuk menambahkan router Mikrotik Anda:
```conf
client mikrotik_1 {
    ipaddr      = 192.168.1.1   # IP Router
    secret      = shared_secret # Password yang sama di setting Radius Mikrotik
    shortname   = mikrotik-hub
}
```

### Mengatur Koneksi SQL
Konfigurasi database ada di `config/sql`. Secara default sudah diarahkan ke service `db` dengan password yang sesuai dengan `docker-compose.yaml`.

---

## 🧪 Cara Pengujian

Anda dapat menguji apakah Radius sudah bisa berkomunikasi dengan DB dengan melakukan `radtest` dari dalam container:

1. **Masukkan Data Uji ke DB**
   ```bash
   docker exec -it radius-db psql -U radius -d radius -c "INSERT INTO radcheck (username, attribute, op, value) VALUES ('testuser', 'Cleartext-Password', ':=', 'testpass');"
   ```

2. **Jalankan Auth Test**
   ```bash
   docker exec -it freeradius-server radtest testuser testpass localhost 0 testing123
   ```
   Jika berhasil, Anda akan menerima pesan **Access-Accept**.

---

## 🔍 Troubleshooting

- **Melihat Log Realtime**: 
  ```bash
  docker logs -f freeradius-server
  ```
- **Mode Debug**:
  Jika ingin melihat detail query SQL yang dijalankan Radius, ubah `CMD` di Dockerfile ke `["radiusd", "-f", "-X"]` lalu build ulang:
  ```bash
  docker-compose up -d --build
  ```

---
*Dibuat oleh Senior Engineer - Proyek Mikhmon V3*
