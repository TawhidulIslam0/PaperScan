# Run from the PaperScan project root in PowerShell.
# Flutter generates the missing Gradle wrapper files; existing project files are backed up/restored.
$ErrorActionPreference = 'Stop'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error 'Flutter was not found in PATH. Install Flutter and reopen PowerShell.'
}
$root = (Get-Location).Path
$temp = Join-Path $env:TEMP ('paperscan_android_backup_' + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $temp | Out-Null
$preserve = @(
  'pubspec.yaml',
  'lib/main.dart',
  'analysis_options.yaml',
  '.gitignore',
  'android/app/build.gradle',
  'android/app/src/main/AndroidManifest.xml',
  'android/app/src/main/kotlin/com/example/paperscan/MainActivity.kt',
  'android/app/src/main/res',
  'android/settings.gradle',
  'android/build.gradle',
  'android/gradle.properties',
  'android/gradle/wrapper/gradle-wrapper.properties',
  'android/.gitignore'
)
foreach ($path in $preserve) {
  $source = Join-Path $root $path
  if (Test-Path $source) {
    $target = Join-Path $temp $path
    $targetParent = Split-Path $target -Parent
    New-Item -ItemType Directory -Force -Path $targetParent | Out-Null
    Copy-Item -Force -Recurse $source $target
  }
}
flutter create --platforms=android --project-name paperscan --org com.example --overwrite .
foreach ($path in $preserve) {
  $saved = Join-Path $temp $path
  $target = Join-Path $root $path
  if (Test-Path $saved) {
    $parent = Split-Path $target -Parent
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    if (Test-Path $target) { Remove-Item -Recurse -Force $target }
    Copy-Item -Force -Recurse $saved $target
  }
}
Remove-Item -Recurse -Force $temp
Write-Host 'Android wrapper files generated and PaperScan configuration restored.' -ForegroundColor Green
Write-Host 'Next run: flutter pub get, then flutter run.'
