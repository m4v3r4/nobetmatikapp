$ErrorActionPreference = "Stop"

$outDir = Join-Path $PSScriptRoot "screenshots\raw"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Save-Screen {
  param(
    [Parameter(Mandatory = $true)][string]$Name
  )

  $tmpDevicePath = "/sdcard/$Name"
  $localPath = Join-Path $outDir $Name

  adb shell screencap -p $tmpDevicePath | Out-Null
  adb pull $tmpDevicePath $localPath | Out-Null
  adb shell rm $tmpDevicePath | Out-Null
  Write-Host "Kaydedildi: $localPath"
}

Write-Host "ADB cihaz kontrolu..."
adb get-state | Out-Null

Write-Host "Ekranlari sirasiyla ac ve her adimda Enter'a bas."

$shots = @(
  "01-kisiler.png",
  "02-yerler.png",
  "03-plan-olustur.png",
  "04-plan.png",
  "05-pdf-kaydet.png",
  "06-yardim-ogretici.png"
)

foreach ($shot in $shots) {
  Read-Host "Hazirsa Enter (cekilecek: $shot)"
  Save-Screen -Name $shot
}

Write-Host "Tum ekranlar alindi."
