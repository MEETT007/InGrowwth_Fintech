param(
  [ValidateSet('Chrome','Android')][string]$Target = 'Chrome',
  [string]$DeviceId
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$api = if ($Target -eq 'Android') { 'http://10.0.2.2:8080' } else { 'http://127.0.0.1:8080' }
Write-Host "Starting HomeEase AI for $Target. Backend: $api"
Write-Host 'Start backend/Start-EmployeePortal.ps1 in another terminal first.'
& flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Could not resolve Flutter dependencies.' }
if ($Target -eq 'Chrome') {
  & flutter run -d chrome "--dart-define=API_BASE_URL=$api"
} elseif ($DeviceId) {
  & flutter run -d $DeviceId "--dart-define=API_BASE_URL=$api"
} else {
  Write-Host 'Choose the running Android emulator if Flutter asks you to select a device.'
  & flutter run "--dart-define=API_BASE_URL=$api"
}
if ($LASTEXITCODE -ne 0) { throw 'Flutter stopped with an error. Check the output above.' }
