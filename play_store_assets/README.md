# Play Store Assets

Bu klasor, Play Store yukleme materyallerini duzenli tutmak icin olusturuldu.

## Klasorler

- `play_store_assets/screenshots/raw`: Cihazdan ham alinan goruntuler
- `play_store_assets/screenshots/edited`: Uzerine yazi/cerceve eklenmis son haller
- `play_store_assets/screenshots/phone`: Play Console'a yuklenecek telefon ekran goruntuleri
- `play_store_assets/screenshots/seven_inch`: 7" tablet goruntuleri (opsiyonel)
- `play_store_assets/screenshots/ten_inch`: 10" tablet goruntuleri (opsiyonel)

## Onerilen cekim listesi (telefon)

1. Kisiler ekrani
2. Yerler ekrani
3. Plan Olustur ekrani
4. Plan (takvim/liste) ekrani
5. PDF kaydetme akisindan bir ekran
6. Yardim/ogretici akisi

## Dosya isim semasi

- `01-kisiler.png`
- `02-yerler.png`
- `03-plan-olustur.png`
- `04-plan.png`
- `05-pdf-kaydet.png`
- `06-yardim-ogretici.png`

## Hizli kullanim

Android cihaza bagliyken:

```powershell
powershell -ExecutionPolicy Bypass -File .\play_store_assets\capture_android_screens.ps1
```

Script goruntuleri `play_store_assets/screenshots/raw` altina alir.

## Signed AAB (Play Store)

`v1.0` signed AAB almak icin:

```powershell
powershell -ExecutionPolicy Bypass -File .\play_store_assets\build_signed_aab.ps1 -BuildName 1.0 -BuildNumber 1
```

`keytool` PATH'te degilse:

```powershell
powershell -ExecutionPolicy Bypass -File .\play_store_assets\build_signed_aab.ps1 -BuildName 1.0 -BuildNumber 1 -KeytoolPath "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
```

Script sirasiyla:

1. Keystore yoksa olusturur
2. `android/key.properties` yazar
3. Signed release AAB build eder
4. Ciktiyi `play_store_assets/releases/nobetmatik-v1.0.aab` olarak kopyalar
