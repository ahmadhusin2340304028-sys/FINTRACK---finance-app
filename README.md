<div align="center">

<img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Dart-3.3-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
<img src="https://img.shields.io/badge/Riverpod-2.5-00B4D8?style=for-the-badge" />
<img src="https://img.shields.io/badge/SQLite-local--db-003B57?style=for-the-badge&logo=sqlite&logoColor=white" />
<img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" />

# 💸 FinTrack

**Aplikasi Pencatatan Keuangan Mahasiswa yang Cerdas**

Kelola pemasukan, pengeluaran, budget, tabungan, dan hutang — semuanya dalam satu aplikasi Flutter offline-first yang elegan.

[Fitur](#-fitur) • [Tangkapan Layar](#-tangkapan-layar) • [Instalasi](#-instalasi) • [Arsitektur](#-arsitektur) • [Kontribusi](#-kontribusi)

</div>

---

## ✨ Fitur

### 💰 Manajemen Transaksi
- Catat pemasukan & pengeluaran dengan kategori lengkap
- Foto bukti transaksi (struk, nota)
- Filter & pencarian canggih (kategori, tanggal, kata kunci)
- Swipe-to-delete dengan konfirmasi
- Grouping transaksi per tanggal

### 📊 Budget Planner
- Buat budget per kategori (harian / mingguan / bulanan)
- Progress bar visual dengan peringatan otomatis (< 20% sisa)
- Sinkronisasi otomatis dengan transaksi terkait

### 🏦 Target Tabungan
- Buat multiple target tabungan dengan deadline
- Circular progress indicator
- Notifikasi milestone (25%, 50%, 75%, 100%)
- Kalkulasi otomatis nominal yang perlu ditabung per hari

### 🤝 Hutang & Piutang
- Pisahkan hutang (owed) dan piutang (receivable)
- Tandai lunas dengan satu tap
- Peringatan jatuh tempo otomatis
- Highlight merah untuk yang sudah overdue

### 📈 Rekap & Laporan
- Laporan harian, mingguan, bulanan, tahunan
- Pie chart pengeluaran per kategori
- Bar chart tren bulanan income vs expense
- **Export ke PDF** (laporan lengkap)
- **Export ke CSV** (data transaksi)

### ⚙️ Pengaturan & Profil
- Mode gelap / terang
- Atur uang saku bulanan → kalkulasi budget harian & mingguan otomatis
- Multi-bahasa (Indonesia & English)
- Edit profil & ganti password

---

## 📱 Tangkapan Layar

> *(Tambahkan screenshot aplikasi di folder `screenshots/` dan update tabel ini)*

| Dashboard | Transaksi | Budget | Tabungan |
|-----------|-----------|--------|----------|
| ![Dashboard](screenshots/dashboard.png) | ![Transaksi](screenshots/transaction.png) | ![Budget](screenshots/budget.png) | ![Hutang-Piutang](screenshots/hutang.png) |

---

## 🚀 Instalasi

### Prasyarat

| Tools | Versi Minimal |
|-------|---------------|
| Flutter SDK | 3.3.0 |
| Dart SDK | 3.3.0 |
| Android SDK | API 21+ (Android 5.0) |
| iOS | 12.0+ |

### Clone & Setup

```bash
# 1. Clone repository
git clone https://github.com/username/fintrack.git
cd fintrack

# 2. Install dependencies
flutter pub get

# 3. Buat folder assets (jika belum ada)
mkdir -p assets/images assets/icons

# 4. Jalankan aplikasi
flutter run
```

### Build Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (untuk Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 🗂️ Struktur Proyek

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart        # Palet warna & gradien
│   │   └── app_constants.dart     # Konstanta global (DB, kategori, dll)
│   ├── services/
│   │   ├── auth_service.dart      # Login, register, session
│   │   ├── notification_service.dart
│   │   ├── pdf_export_service.dart
│   │   └── csv_export_service.dart
│   ├── theme/
│   │   └── app_theme.dart         # Light & dark theme (Material 3)
│   ├── utils/
│   │   ├── currency_formatter.dart
│   │   └── validators.dart
│   └── widgets/
│       └── common_widgets.dart    # Shared widgets (GradientCard, EmptyState, dll)
│
├── data/
│   ├── database/
│   │   └── database_helper.dart   # SQLite singleton & schema
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── transaction_model.dart
│   │   ├── budget_model.dart
│   │   ├── debt_model.dart
│   │   ├── savings_model.dart
│   │   └── account_model.dart
│   └── repositories/
│       ├── user_repository.dart
│       ├── transaction_repository.dart
│       ├── budget_repository.dart
│       ├── debt_repository.dart
│       └── savings_repository.dart
│
├── features/
│   ├── auth/
│   │   ├── pages/           login_page, register_page
│   │   └── providers/       auth_provider
│   ├── dashboard/
│   │   ├── pages/           dashboard_page, main_shell
│   │   └── providers/       dashboard_provider
│   ├── transaction/
│   │   ├── pages/           transaction_page, add_transaction_page, detail_page
│   │   └── providers/       transaction_provider
│   ├── budget/
│   │   ├── pages/           budget_page, add_budget_page
│   │   └── providers/       budget_provider
│   ├── debt/
│   │   ├── pages/           debt_page, add_debt_page
│   │   └── providers/       debt_provider
│   ├── savings/
│   │   ├── pages/           savings_page, add_savings_page, savings_detail_page
│   │   └── providers/       savings_provider
│   ├── reports/
│   │   ├── pages/           reports_page
│   │   ├── providers/       report_provider
│   │   └── widgets/         export_button
│   └── settings/
│       ├── pages/           settings_page, profile_page
│       └── providers/       settings_provider
│
└── routes/
    └── app_router.dart            # Centralized named routing
```

---

## 🏛️ Arsitektur

FinTrack menggunakan arsitektur **Feature-First** dengan pola **Repository Pattern**.

```
UI (Pages / Widgets)
        ↓
   Providers (Riverpod StateNotifier)
        ↓
   Repositories
        ↓
   DatabaseHelper (SQLite via sqflite)
```

### State Management
- **flutter_riverpod** `StateNotifierProvider` untuk state yang mutable
- **Provider** untuk dependency injection (repository, service)
- **FutureProvider.family** untuk data async dengan parameter

### Database
- **SQLite** via `sqflite` — fully offline, tidak perlu internet
- Schema versi 1 dengan 6 tabel: `users`, `transactions`, `budgets`, `debts`, `savings`, `accounts`
- Indexed pada kolom yang sering diquery (`user_id`, `date`)

### Keamanan
- Password di-hash dengan **SHA-256** sebelum disimpan
- Session ID disimpan di `SharedPreferences`
- `flutter_secure_storage` tersedia untuk data sensitif

---

## 📦 Dependensi Utama

| Package | Kegunaan | Versi |
|---------|----------|-------|
| `flutter_riverpod` | State management | ^2.5.1 |
| `sqflite` | Local database SQLite | ^2.3.3 |
| `shared_preferences` | Penyimpanan preferensi | ^2.3.2 |
| `fl_chart` | Grafik pie & bar | ^0.69.0 |
| `pdf` | Generate laporan PDF | ^3.11.1 |
| `google_fonts` | Tipografi Poppins | ^6.2.1 |
| `flutter_local_notifications` | Push notifikasi lokal | ^18.0.1 |
| `image_picker` | Foto bukti transaksi | ^1.1.2 |
| `percent_indicator` | Progress bar & circular | ^4.2.3 |
| `crypto` | Hash password SHA-256 | ^3.0.5 |
| `intl` | Format currency & tanggal | ^0.19.0 |
| `uuid` | Generate unique ID | ^4.5.1 |

---

## 🗃️ Skema Database

```sql
-- Pengguna
users (id, name, email, password[SHA256], avatar, monthly_allowance, created_at, updated_at)

-- Transaksi
transactions (id, user_id, account_id, type[income|expense], amount, category, note, image_path, date, ...)

-- Budget
budgets (id, user_id, name, category, target, used, period[daily|weekly|monthly], start_date, end_date, ...)

-- Hutang & Piutang
debts (id, user_id, type[owed|receivable], person_name, amount, paid_amount, status[unpaid|paid], due_date, ...)

-- Tabungan
savings (id, user_id, goal_name, target_amount, current_amount, deadline, icon, is_completed, ...)

-- Akun (rekening/dompet)
accounts (id, user_id, name, type[Tunai|E-Wallet|Bank], balance, is_default, ...)
```

---

## 🎨 Design System

| Token | Nilai |
|-------|-------|
| **Primary** | `#FF4D94` (Pink) |
| **Success** | `#28C76F` (Green) |
| **Danger** | `#EA5455` (Red) |
| **Warning** | `#FF9F43` (Orange) |
| **Info** | `#00CFE8` (Cyan) |
| **Font** | Poppins (via Google Fonts) |
| **Border Radius** | 14–24dp (konsisten) |
| **Theme** | Material 3, Light & Dark |

---

## 🔔 Notifikasi Lokal

| Trigger | Pesan |
|---------|-------|
| Budget < 20% tersisa | "⚠️ Budget hampir habis" |
| Hutang jatuh tempo besok | "💸 Jatuh tempo hutang" |
| Milestone tabungan (25/50/75/100%) | "🎉 Milestone tercapai!" |

---

## 🛣️ Roadmap

- [ ] Sinkronisasi cloud (Firebase / Supabase)
- [ ] Multi-akun (Tunai, BCA, GoPay, dll)
- [ ] Widget home screen Android
- [ ] Recurring transaction (otomatis harian/bulanan)
- [ ] Biometric lock (fingerprint / Face ID)
- [ ] Import transaksi dari CSV/Excel
- [ ] Analisis AI pengeluaran

---

## 🤝 Kontribusi

Kontribusi sangat disambut! Silakan ikuti langkah berikut:

1. **Fork** repository ini
2. Buat branch fitur: `git checkout -b feat/nama-fitur`
3. Commit perubahan: `git commit -m "feat: deskripsi singkat"`
4. Push ke branch: `git push origin feat/nama-fitur`
5. Buat **Pull Request**

### Konvensi Commit

Gunakan format [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: tambah fitur baru
fix: perbaikan bug
docs: update dokumentasi
style: perubahan formatting
refactor: refactor kode tanpa perubahan fitur
test: tambah/update test
chore: update dependency/config
```

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah **MIT License** — lihat file [LICENSE](LICENSE) untuk detail.

---

<div align="center">

Dibuat dengan ❤️ untuk mahasiswa Indonesia

**⭐ Jika project ini bermanfaat, beri bintang ya!**

</div>
#   F I N T R A C K - - - f i n a n c e - a p p  
 