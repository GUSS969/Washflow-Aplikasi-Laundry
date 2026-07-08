PRODUCT REQUIREMENTS DOCUMENT (PRD)
WashFlow – Smart Laundry Management System
Version1.0AuthorProduct ManagerTech StackFlutter • Laravel • MySQLStatusDraftLast UpdatedJuni 2025

1. Executive Summary
Overview
WashFlow adalah aplikasi manajemen laundry berbasis mobile yang dirancang untuk membantu pemilik usaha laundry dalam mengelola seluruh proses bisnis secara digital — mulai dari pencatatan pelanggan, transaksi, pelacakan status cucian, pembayaran, hingga laporan keuangan.
Saat ini, sebagian besar usaha laundry kecil hingga menengah masih mengandalkan pencatatan manual melalui buku atau aplikasi chat seperti WhatsApp. Kondisi ini menyebabkan kehilangan data, kesalahan pencatatan, dan sulitnya memonitor bisnis secara real-time.
WashFlow hadir sebagai solusi digital yang sederhana, cepat, dan mudah digunakan dengan memanfaatkan Flutter sebagai aplikasi mobile, Laravel sebagai REST API backend, dan MySQL sebagai database.
Vision

Menjadi platform manajemen laundry pilihan UMKM Indonesia yang meningkatkan efisiensi operasional, meminimalkan kesalahan administrasi, dan meningkatkan kepuasan pelanggan.

Target Market
SegmenDeskripsiLaundry KiloanUsaha laundry dengan tarif per kilogramLaundry SatuanUsaha laundry dengan tarif per itemLaundry SepatuSpesialis cuci sepatuLaundry Premium / Dry CleaningLayanan premium untuk pakaian khususLaundry HotelLaundry skala besar untuk hospitalityLaundry KampusLaundry di sekitar area perguruan tinggi
Value Proposition

✅ Input transaksi lebih cepat dan akurat
✅ Monitoring pesanan secara real-time
✅ Riwayat transaksi tersimpan aman di cloud
✅ Laporan pendapatan otomatis (harian, mingguan, bulanan)
✅ Notifikasi otomatis ke pelanggan
✅ Antarmuka yang sederhana dan mudah digunakan


2. Problem Statement
Permasalahan
Usaha laundry skala kecil hingga menengah menghadapi tantangan operasional yang bersumber dari ketergantungan pada sistem manual:
NoMasalahDampak1Pencatatan menggunakan buku tulisData mudah hilang atau rusak2Tidak ada sistem tracking status cucianPelanggan tidak tahu kapan cucian selesai3Perhitungan harga dilakukan manualRentan human error4Tidak ada laporan keuangan otomatisOwner sulit memantau pendapatan5Tidak ada riwayat transaksi terdigitalisasiSulit menangani komplain pelanggan6Pelanggan harus datang langsung untuk cek statusPengalaman pelanggan buruk7Tidak ada dashboard bisnisOwner kesulitan mengambil keputusan
Root Cause
Ketiadaan sistem digital yang terjangkau dan mudah digunakan khusus untuk segmen UMKM laundry.

3. Goals & Success Metrics
Business Goals

Digitalisasi operasional usaha laundry UMKM
Mengurangi ketergantungan pada pencatatan kertas
Meningkatkan produktivitas kasir dan staf
Memberikan visibilitas bisnis secara real-time kepada owner

Product Goals

Aplikasi mudah digunakan tanpa pelatihan teknis
Seluruh transaksi tersimpan otomatis dan aman
Status cucian dapat dipantau oleh pelanggan secara mandiri
Laporan keuangan dihasilkan secara otomatis
Sistem responsif dan stabil

Success Metrics (KPI)
KPIBaseline (Sekarang)TargetWaktu input transaksi~10 menit (manual)< 2 menitError pencatatanTinggiTurun 90%Kepuasan pelanggan-> 90%Waktu pencarian transaksiLama (cari di buku)< 5 detikPembuatan laporan keuangan30–60 menitInstan (otomatis)

4. User Persona
Persona 1 — Owner Laundry

"Saya ingin tahu berapa pemasukan hari ini tanpa harus ngitung manual."


Usia: 30–45 Tahun
Peran: Pemilik usaha, pengambil keputusan
Goals: Melihat laporan pendapatan, memantau kinerja staf, memonitor jumlah order masuk
Pain Points: Tidak tahu jumlah pemasukan harian, data tercecer, sulit mengevaluasi performa bisnis


Persona 2 — Kasir / Operator

"Saya perlu input order cepat, apalagi kalau lagi ramai pelanggan."


Usia: 18–30 Tahun
Peran: Penerima order, kasir, update status cucian
Goals: Input transaksi cepat, cetak nota, cari data pelanggan, update status cucian
Pain Points: Salah hitung harga, antrean panjang, sering salah tulis nama pelanggan


Persona 3 — Pelanggan

"Saya mau tahu cucian saya sudah selesai atau belum tanpa harus ke toko."


Usia: 17–40 Tahun
Peran: Pengguna akhir layanan laundry
Goals: Cek status cucian dari HP, terima notifikasi, lihat riwayat order
Pain Points: Tidak tahu status cucian, nota fisik hilang, harus telpon toko untuk cek status


5. User Flow
Owner
Login → Dashboard → Lihat Statistik & Grafik → Buka Laporan → Kelola Pegawai → Logout
Kasir
Login → Cari / Tambah Pelanggan → Input Order Laundry → Pilih Layanan & Berat
      → Harga Dihitung Otomatis → Proses Pembayaran → Cetak Nota → Update Status Cucian
Pelanggan
Login → Home → Lihat Status Laundry → Terima Notifikasi Selesai → Lihat Riwayat Order

6. Functional Requirements
6.1 Authentication
FiturDeskripsiRegisterPendaftaran akun baruLoginMasuk dengan email & passwordLogoutKeluar dari sesiForgot PasswordReset password via emailJWT AuthenticationKeamanan akses API menggunakan token

6.2 Dashboard
FiturDeskripsiTotal OrderMenampilkan jumlah order hari iniOrder DiprosesJumlah order yang sedang berjalanOrder SelesaiJumlah order yang telah selesaiPendapatan Hari IniTotal pendapatan harianGrafik PendapatanVisualisasi pendapatan mingguan/bulanan

6.3 Customer Management
FiturDeskripsiTambah PelangganInput data pelanggan baruEdit PelangganUbah data pelangganHapus PelangganHapus data pelangganCari PelangganPencarian cepat berdasarkan nama / nomor HP

6.4 Service Management
LayananSatuan HargaLaundry KiloanPer kgLaundry SatuanPer itemCuci SepatuPer pasangDry CleaningPer itemExpressTambahan biaya percepatan

6.5 Order Management
FiturDeskripsiBuat TransaksiInput order baru dengan pilih pelanggan dan layananNomor Invoice OtomatisGenerate nomor invoice unik secara otomatisHitung Harga OtomatisTotal harga dihitung berdasarkan berat / qty dan layananEstimasi SelesaiSistem memberikan estimasi tanggal selesaiUpdate StatusKasir mengupdate progres cucian

6.6 Status Laundry
Alur status cucian berjalan secara berurutan:
Diterima → Dicuci → Dikeringkan → Disetrika → Selesai → Sudah Diambil

6.7 Payment
Metode PembayaranStatusCash✅QRIS✅Transfer Bank✅
Status pembayaran: Lunas / Belum Lunas

6.8 Report
Jenis LaporanFormat ExportHarianPDF, ExcelMingguanPDF, ExcelBulananPDF, ExcelTahunanPDF, Excel

6.9 Notification
TriggerPenerimaLaundry selesai diprosesPelangganPembayaran berhasil diterimaKasir / OwnerReminder pengambilan cucianPelanggan

6.10 User Management & Role
RoleAksesAdmin / OwnerFull access — dashboard, laporan, manajemen user, semua transaksiKasirInput order, update status, pembayaran, cetak notaPelangganLihat status cucian, riwayat order, notifikasi

7. Non-Functional Requirements
KategoriRequirementPerformanceResponse API < 500 ms, loading screen < 2 detikSecurityJWT Auth, bcrypt password hashing, HTTPS, proteksi SQL Injection & XSSAvailabilityUptime minimal 99%ScalabilityMendukung >1.000 transaksi per hariCompatibilityAndroid, iOS, Web Admin PanelMaintainabilityArsitektur MVC + Repository Pattern pada Laravel

8. Database Design (ERD)
Tabel & Relasi
Users           Customers
-----           ---------
id (PK)         id (PK)
name            name
email           phone
password        address
role

Services        Orders                  Order_Details
--------        ------                  -------------
id (PK)         id (PK)                 id (PK)
service_name    invoice (UNIQUE)        order_id (FK)
price           customer_id (FK)        service_id (FK)
unit            user_id (FK)            weight
                status                  qty
                payment_status          subtotal
                total_price
                created_at

Payments        Notifications
--------        -------------
id (PK)         id (PK)
order_id (FK)   user_id (FK)
method          title
amount          message
payment_date    is_read
                created_at
Relasi Antar Tabel
Tabel ARelasiTabel BUser1 → NOrderCustomer1 → NOrderOrder1 → NOrder_DetailService1 → NOrder_DetailOrder1 → 1PaymentUser1 → NNotification

Catatan perbaikan: Kolom user_id ditambahkan ke tabel Orders untuk mencatat kasir yang melakukan input. Kolom is_read ditambahkan ke Notifications untuk tracking notifikasi yang belum dibaca.


9. REST API Endpoints
Authentication
POST   /api/register
POST   /api/login
POST   /api/logout
GET    /api/profile
PUT    /api/profile              ← TAMBAHAN: update profil
Customers
GET    /api/customers
GET    /api/customers/{id}       ← TAMBAHAN: detail pelanggan
POST   /api/customers
PUT    /api/customers/{id}
DELETE /api/customers/{id}
Services
GET    /api/services
GET    /api/services/{id}
POST   /api/services
PUT    /api/services/{id}
DELETE /api/services/{id}
Orders
GET    /api/orders
GET    /api/orders/{id}
POST   /api/orders
PUT    /api/orders/{id}
PATCH  /api/orders/{id}/status   ← TAMBAHAN: khusus update status cucian
DELETE /api/orders/{id}
Payments
POST   /api/payments
GET    /api/payments
GET    /api/payments/{id}        ← TAMBAHAN: detail pembayaran
Reports
GET    /api/reports/daily
GET    /api/reports/weekly       ← TAMBAHAN: laporan mingguan
GET    /api/reports/monthly
GET    /api/reports/yearly
Notifications
GET    /api/notifications
POST   /api/notifications/send
PATCH  /api/notifications/{id}/read   ← TAMBAHAN: tandai sudah dibaca

10. Product Roadmap
Phase 1 — MVP (Minggu 1–6)
Fondasi sistem yang wajib berjalan:

 Authentication (Login, Register, JWT)
 Dashboard statistik dasar
 Manajemen Pelanggan (CRUD)
 Manajemen Layanan (CRUD)
 Input & Kelola Order
 Proses Pembayaran (Cash)
 Tracking Status Cucian
 Laporan Harian

Phase 2 — Enhancement (Minggu 7–10)

 Push Notification (FCM)
 QR Code pada Invoice
 Export PDF & Excel
 Grafik pendapatan interaktif
 Pembayaran QRIS & Transfer
 Laporan Mingguan & Bulanan

Phase 3 — Growth (Minggu 11–15)

 Multi-cabang / Multi-outlet
 Membership & Loyalty Points
 Voucher & Diskon
 Integrasi Notifikasi WhatsApp
 Web Admin Panel

Phase 4 — Future (TBD)

 AI Prediksi Pendapatan
 AI Rekomendasi Promo
 Chatbot Pelanggan
 Booking Pickup & Delivery
 Driver Tracking (Delivery)
 Pembayaran Online (Payment Gateway)


11. UI Screens
Authentication

Splash Screen
Onboarding (3 halaman)
Login
Register
Forgot Password

Owner

Dashboard + Statistik
Laporan Keuangan
Manajemen Pegawai / User
Pengaturan Aplikasi

Kasir

Dashboard
Tambah Order
Detail Order
Data Pelanggan
Daftar Layanan
Proses Pembayaran
Riwayat Transaksi

Pelanggan

Home / Status Laundry
Tracking Cucian
Riwayat Order
Notifikasi
Profil

Shared Screens

Detail Order (lintas role)
Edit Profil
Pengaturan
About App


12. Tech Stack
Mobile
KomponenTeknologiFrameworkFlutter (Dart)State ManagementRiverpodHTTP ClientDioLocal StorageFlutter Secure Storage
Backend
KomponenTeknologiFrameworkLaravel 12RuntimePHP 8.3+AuthenticationLaravel Sanctum + JWTJob QueueLaravel QueueNotificationLaravel Notifications + FCM
Database & Storage
KomponenTeknologiDatabaseMySQL 8File StorageLaravel Storage (lokal / cloud)Push NotificationFirebase Cloud Messaging (FCM)
Development Tools

VS Code / Android Studio
Postman (API Testing)
Git + GitHub
Figma (UI Design)
Composer & Node.js

Arsitektur Sistem
+------------------------------+
|      Flutter Mobile App      |
|  (Owner / Kasir / Pelanggan) |
+-------------+----------------+
              |
         REST API (HTTPS)
              |
+-------------v----------------+
|         Laravel API          |
|  - Authentication            |
|  - Business Logic            |
|  - Queue & Notifications     |
+-------------+----------------+
              |
        Eloquent ORM
              |
+-------------v----------------+
|          MySQL 8             |
|  users, customers, services, |
|  orders, order_details,      |
|  payments, notifications     |
+------------------------------+
              |
+-------------v----------------+
|    Firebase Cloud Messaging  |
|    (Push Notification)       |
+------------------------------+

13. Risks & Mitigations

(Seksi ini ditambahkan — penting untuk PRD yang profesional)

RisikoKemungkinanDampakMitigasiServer down saat jam sibukSedangTinggiImplementasi caching & retry logicData pelanggan hilangRendahSangat TinggiBackup database otomatis harianKasir salah input beratTinggiSedangValidasi input + konfirmasi sebelum simpanToken JWT kedaluwarsa saat transaksiSedangTinggiImplementasi refresh token otomatisPelanggan tidak terima notifikasiSedangSedangFallback ke SMS / WhatsApp

14. Open Issues & Assumptions

(Seksi ini ditambahkan — mencegah ambiguitas saat development)

Assumptions

Setiap outlet hanya memiliki satu database (multi-cabang dipertimbangkan di Phase 3)
Pembayaran online (payment gateway) tidak termasuk dalam MVP
Pelanggan harus mendaftar sendiri sebelum bisa tracking order

Open Issues

 Apakah pelanggan bisa order secara online atau hanya walk-in?
 Bagaimana mekanisme jika pelanggan tidak memiliki smartphone?
 Apakah ada batas maksimum diskon untuk voucher?
 Format nomor invoice: manual atau auto-generate penuh?


WashFlow PRD v1.0 — Dokumen ini bersifat living document dan akan diperbarui seiring perkembangan proyek.