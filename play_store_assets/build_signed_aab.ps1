param(
  [string]$BuildName = "1.0",
  [int]$BuildNumber = 1,
  [string]$AppName = "nobetmatik",
  [string]$KeystorePath = "android/upload-keystore.jks",
  [string]$KeyAlias = "upload",
  [string]$KeytoolPath = "",
  [string]$StorePassword = "",
  [string]$KeyPassword = "",
  [string]$DName = ""
)

$ErrorActionPreference = "Stop"

function Require-Command {
  param([Parameter(Mandatory = $true)][string]$Name)
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Gerekli komut bulunamadi: $Name"
  }
}

function Resolve-Keytool {
  param([string]$ExplicitPath)

  if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
    if (Test-Path $ExplicitPath) { return (Resolve-Path $ExplicitPath).Path }
    throw "Belirtilen keytool bulunamadi: $ExplicitPath"
  }

  $fromPath = Get-Command keytool -ErrorAction SilentlyContinue
  if ($fromPath) { return $fromPath.Source }

  $candidates = @()
  if (-not [string]::IsNullOrWhiteSpace($env:JAVA_HOME)) {
    $candidates += (Join-Path $env:JAVA_HOME "bin\keytool.exe")
    $candidates += (Join-Path $env:JAVA_HOME "bin\keytool")
  }

  $candidates += "$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe"
  $candidates += "${env:ProgramFiles(x86)}\Android\Android Studio\jbr\bin\keytool.exe"
  $candidates += "$env:ProgramFiles\Android\Android Studio\jre\bin\keytool.exe"
  $candidates += "${env:ProgramFiles(x86)}\Android\Android Studio\jre\bin\keytool.exe"
  $candidates += "D:\android\jbr\bin\keytool.exe"

  try {
    $doctorOutput = & flutter doctor -v 2>$null
    $javaLine = $doctorOutput | Where-Object { $_ -match "Java binary at:" } | Select-Object -First 1
    if ($javaLine) {
      $javaPath = ($javaLine -replace ".*Java binary at:\s*", "").Trim()
      if (-not [string]::IsNullOrWhiteSpace($javaPath)) {
        $javaDir = Split-Path $javaPath -Parent
        $candidates += (Join-Path $javaDir "keytool.exe")
        $candidates += (Join-Path $javaDir "keytool")
      }
    }
  } catch {
    # Flutter doctor okunamazsa aday listesinden devam et
  }

  foreach ($c in $candidates) {
    if (-not [string]::IsNullOrWhiteSpace($c) -and (Test-Path $c)) {
      return (Resolve-Path $c).Path
    }
  }

  throw "keytool bulunamadi. JAVA_HOME ayarla veya -KeytoolPath parametresi ver."
}

function Ask-NonEmpty {
  param([Parameter(Mandatory = $true)][string]$Prompt)
  while ($true) {
    $value = Read-Host $Prompt
    if (-not [string]::IsNullOrWhiteSpace($value)) { return $value }
    Write-Host "Bos birakilamaz."
  }
}

function Get-RelativePathFromApp {
  param(
    [Parameter(Mandatory = $true)][string]$RepoRoot,
    [Parameter(Mandatory = $true)][string]$TargetPath
  )

  $appDir = Join-Path $RepoRoot "android\app"
  $appFull = [System.IO.Path]::GetFullPath($appDir)
  $targetFull = [System.IO.Path]::GetFullPath($TargetPath)

  $appUri = New-Object System.Uri(($appFull.TrimEnd('\') + '\'))
  $targetUri = New-Object System.Uri($targetFull)
  $rel = $appUri.MakeRelativeUri($targetUri).ToString()
  return $rel
}

Require-Command -Name "flutter"
$resolvedKeytool = Resolve-Keytool -ExplicitPath $KeytoolPath

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

$androidKeyPropsPath = Join-Path $repoRoot "android\key.properties"
$keystoreFullPath = Join-Path $repoRoot $KeystorePath

if (-not (Test-Path $keystoreFullPath)) {
  Write-Host "Keystore bulunamadi, yeni keystore olusturulacak: $keystoreFullPath"
  $effectiveStorePassword = if ([string]::IsNullOrWhiteSpace($StorePassword)) {
    Ask-NonEmpty -Prompt "Keystore sifresi (storePassword)"
  } else { $StorePassword }
  $effectiveKeyPassword = if ([string]::IsNullOrWhiteSpace($KeyPassword)) {
    Ask-NonEmpty -Prompt "Key sifresi (keyPassword)"
  } else { $KeyPassword }
  $effectiveDName = if ([string]::IsNullOrWhiteSpace($DName)) {
    Ask-NonEmpty -Prompt "Sertifika bilgisi (ornek: CN=Ad Soyad,OU=Dev,O=Sirket,L=Istanbul,ST=Istanbul,C=TR)"
  } else { $DName }

  $keytoolArgs = @(
    "-genkeypair",
    "-v",
    "-keystore", $keystoreFullPath,
    "-alias", $KeyAlias,
    "-keyalg", "RSA",
    "-keysize", "2048",
    "-validity", "10000",
    "-storepass", $effectiveStorePassword,
    "-keypass", $effectiveKeyPassword,
    "-dname", $effectiveDName
  )
  & $resolvedKeytool @keytoolArgs
} else {
  Write-Host "Mevcut keystore bulundu: $keystoreFullPath"
  $effectiveStorePassword = if ([string]::IsNullOrWhiteSpace($StorePassword)) {
    Ask-NonEmpty -Prompt "Keystore sifresi (storePassword)"
  } else { $StorePassword }
  $effectiveKeyPassword = if ([string]::IsNullOrWhiteSpace($KeyPassword)) {
    Ask-NonEmpty -Prompt "Key sifresi (keyPassword)"
  } else { $KeyPassword }
}

# PKCS12 keystore'larda keyPassword/storePassword farkli oldugunda
# Android sign islemi "final block not properly padded" hatasi verebilir.
# Guvenli yol: ikisini ayni kullan.
if ($effectiveKeyPassword -ne $effectiveStorePassword) {
  Write-Host "Uyari: keyPassword storePassword ile aynilandi (PKCS12 uyumlulugu)."
  $effectiveKeyPassword = $effectiveStorePassword
}

$keyPropsContent = @(
  "storePassword=$effectiveStorePassword"
  "keyPassword=$effectiveKeyPassword"
  "keyAlias=$KeyAlias"
  "storeFile=$(Get-RelativePathFromApp -RepoRoot $repoRoot -TargetPath $keystoreFullPath)"
) -join "`n"

Set-Content -Path $androidKeyPropsPath -Value $keyPropsContent -Encoding ASCII
Write-Host "Yazildi: $androidKeyPropsPath"

Write-Host "Signed AAB build basliyor..."
& flutter build appbundle --release --build-name=$BuildName --build-number=$BuildNumber
if ($LASTEXITCODE -ne 0) {
  throw "Flutter build basarisiz. Exit code: $LASTEXITCODE"
}

$builtAab = Join-Path $repoRoot "build\app\outputs\bundle\release\app-release.aab"
if (-not (Test-Path $builtAab)) {
  throw "AAB olusmadi: $builtAab"
}

$releaseDir = Join-Path $repoRoot "play_store_assets\releases"
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

$targetAab = Join-Path $releaseDir "$AppName-v$BuildName.aab"
Copy-Item -Force $builtAab $targetAab

Write-Host "Tamamlandi."
Write-Host "Signed AAB: $targetAab"
