# FreeRADIUS Kubernetes Setup Guide

Panduan untuk men-deploy FreeRADIUS ke cluster Kubernetes menggunakan manifest yang tersedia di direktori ini.

## 🚀 Cara Deployment

1. **Buat Namespace**
   ```bash
   kubectl apply -f namespace.yaml
   ```

2. **Konfigurasi Kredensial (Secret)**
   Buka file `secret.yaml`, sesuaikan nilai `DB_HOST`, `DB_USER`, dan `DB_PASSWORD` dengan database external Anda, lalu jalankan:
   ```bash
   kubectl apply -f secret.yaml
   ```

3. **Terapkan Konfigurasi (ConfigMap)**
   ```bash
   kubectl apply -f configmap.yaml
   ```

4. **Deploy Server**
   ```bash
   kubectl apply -f deployment.yaml
   kubectl apply -f service.yaml
   ```

---

## 💾 Inisialisasi Database External

Jika database external Anda belum memiliki skema FreeRADIUS, Anda perlu mengimpor file SQL yang ada di folder `../radius-schema/`.

**Contoh Impor dari Local ke Postgres Pod (jika DB di K8s):**
```bash
# Ganti <pod-db> dengan nama pod postgres Anda
kubectl exec -i <pod-db> -n <namespace-db> -- psql -U radius -d radius < ../radius-schema/postgresql/schema.sql
kubectl exec -i <pod-db> -n <namespace-db> -- psql -U radius -d radius < ../radius-schema/postgresql/process-radacct.sql
```

---

## 🧪 Pengujian di Kubernetes

Setelah semua resource berjalan, Anda bisa menguji login dari dalam pod:

1. **Cek Pod Name**
   ```bash
   kubectl get pods -n free-radius
   ```

2. **Jalankan Test**
   ```bash
   kubectl exec -it <pod-name> -n free-radius -- radtest testuser testpass localhost 0 testing123
   ```

---

## 🔍 Catatan Penting

- **UDP Port**: Pastikan provider Kubernetes Anda mendukung Service tipe `LoadBalancer` dengan protokol `UDP`. Jika tidak, Anda mungkin perlu menggunakan `NodePort` atau host network.
- **Config persistence**: Konfigurasi `clients.conf` dan `sql` dimount melalui ConfigMap. Jika Anda mengubah ConfigMap, Pod perlu di-restart agar perubahan terbaca.
