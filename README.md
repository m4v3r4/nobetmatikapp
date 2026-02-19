# Nobetmatik

Flutter ile geliştirilen offline nöbet planlama MVP uygulaması.

## Kapsam (MVP)
- Kişi yönetimi
- Nöbet yeri yönetimi
- Nöbet şablonu yönetimi
- Haftalık/Aylık plan üretimi
- Plan liste görünümü
- Doldurulamayan slot raporu

## Mimari (Modüler)
- `lib/models`: veri modelleri
- `lib/services`: planlama servisi + local storage servisi
- `lib/controller`: uygulama state ve iş akışı
- `lib/screens`: ekranlar
- `lib/app`: uygulama kabuğu
- `lib/utils`: formatlama yardımcıları

## Local Kayıt
Veriler cihazda `shared_preferences` ile saklanır.

Kalıcı tutulan alanlar:
- Kişiler
- Nöbet yerleri
- Nöbet şablonları
- ID sayaçları
- Plan oluşturma ayarları (dönem tipi, başlangıç tarihi, min dinlenme, haftalık max)

## Veri Modeli

### Person
- `id`
- `adSoyad`
- `aktifMi`

### DutyLocation
- `id`
- `ad`
- `kapasite`

### ShiftTemplate
- `id`
- `locationId`
- `baslangicSaati`
- `bitisSaati`
- `sureSaat`

### ScheduleRequest
- `donemTipi`
- `baslangicTarihi`
- `bitisTarihi`
- `kurallar`

### Assignment
- `tarih`
- `locationId`
- `shiftStart`
- `shiftEnd`
- `durationHours`
- `personId`

## Kural Seti (MVP)
- Eşitlik: toplam saat bazlı
- Min dinlenme: varsayılan 24 saat
- Haftalık max: varsayılan 2 nöbet
- Aynı slotta çakışma: yasak
- Uygunluk alanı yoksa: 7/24 uygun kabul edilir

## Çalıştırma
```bash
flutter pub get
flutter run
```

## Reklam Altyapısı
- Mobil (Android/iOS): AdMob servisi kullanılır.
- Web: AdSense servisi kullanılır.

Web'de AdSense aktif etmek için:
```bash
flutter run -d chrome \
  --dart-define=ADSENSE_CLIENT=ca-pub-xxxxxxxxxxxxxxxx \
  --dart-define=ADSENSE_BANNER_SLOT=1234567890
```

## GitHub Pages Yayını
- Workflow dosyası: `.github/workflows/deploy-web.yml`
- `main` branch'e her push sonrası web build alınıp GitHub Pages'e deploy edilir.
- Build sırasında `--base-href "/<repo-adi>/"` otomatik verilir.
- Flutter SPA rotalama için `build/web/404.html` otomatik oluşturulur.
