# SILONET - Setup para Vercel + GitHub Gist
# ===========================================
Write-Host "=== SILONET - Setup Vercel ===" -ForegroundColor Cyan
Write-Host ""

# 1. Pedir token
$token = $null
while (-not $token) {
  $token = Read-Host "Pegá tu GitHub Token (classic, con scope 'gist')"
  if (-not $token) { Write-Host "El token no puede estar vacío." -ForegroundColor Red }
}

Write-Host ""
Write-Host "Creando gist..." -ForegroundColor Yellow

# 2. Crear gist con archivos vacíos
$body = @{
  description = "SILONET password manager - vault storage"
  public = $false
  files = @{
    "1-vault.json" = @{ content = "{}" }
    "1-salt.txt" = @{ content = "" }
    "2-vault.json" = @{ content = "{}" }
    "2-salt.txt" = @{ content = "" }
  }
} | ConvertTo-Json

try {
  $resp = Invoke-RestMethod -Uri "https://api.github.com/gists" -Method Post -Headers @{
    Authorization = "token $token"
    "Content-Type" = "application/json"
    Accept = "application/vnd.github.v3+json"
  } -Body $body
} catch {
  Write-Host "ERROR al crear gist: $_" -ForegroundColor Red
  Write-Host "Verificá que el token sea válido y tenga scope 'gist'." -ForegroundColor Yellow
  exit 1
}

$gistId = $resp.id
Write-Host ""
Write-Host "=== Gist creado exitosamente ===" -ForegroundColor Green
Write-Host "Gist ID: $gistId" -ForegroundColor Cyan
Write-Host "URL: $($resp.html_url)" -ForegroundColor Cyan

# 3. Instrucciones para Vercel
Write-Host ""
Write-Host "=== Próximos pasos ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Instalá Vercel CLI (si no lo tenés):"
Write-Host "   npm install -g vercel"
Write-Host ""
Write-Host "2. Deployá el proyecto desde esta carpeta:"
Write-Host "   cd $PWD"
Write-Host "   vercel deploy --prod"
Write-Host ""
Write-Host "3. Configurá las variables de entorno en Vercel:"
Write-Host "   GITHUB_TOKEN = $($token.Substring(0,10))...$($token.Substring($token.Length-4))" -ForegroundColor Green
Write-Host "   GIST_ID = $gistId" -ForegroundColor Green
Write-Host ""
Write-Host "   Alternativa por línea de comandos:"
Write-Host "   cd $PWD"
Write-Host '   vercel env add GITHUB_TOKEN'
Write-Host '   vercel env add GIST_ID'
Write-Host "   vercel deploy --prod"
Write-Host ""
Write-Host "4. Abrí la URL que te dé Vercel y usá SILONET desde cualquier dispositivo" -ForegroundColor Cyan
Write-Host ""
$token = $null  # limpiar
