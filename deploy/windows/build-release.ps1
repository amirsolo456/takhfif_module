param(
    [Parameter(Mandatory = $true)]
    [string]$ApiBaseUrl,
    [ValidateSet('windows', 'apk')]
    [string]$Target = 'windows'
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    throw 'ApiBaseUrl is required. Example: https://api.example.ir'
}

$ApiBaseUrl = $ApiBaseUrl.TrimEnd('/')

Write-Host "Building Flutter $Target release with API: $ApiBaseUrl" -ForegroundColor Cyan

flutter clean
flutter pub get

if ($Target -eq 'windows') {
    flutter build windows --release --dart-define=API_BASE_URL=$ApiBaseUrl
}
else {
    flutter build apk --release --dart-define=API_BASE_URL=$ApiBaseUrl
}

Write-Host 'Release build completed successfully.' -ForegroundColor Green
