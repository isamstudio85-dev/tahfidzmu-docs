# ============================================================
# download_quran.ps1
# Downloads all 114 surahs (Arabic + Indonesian translation)
# from AlQuran Cloud API and saves as local JSON assets.
# Run once: pwsh -File tools/download_quran.ps1
#           or: powershell -File tools/download_quran.ps1
# ============================================================

$outDir  = "e:\Tahfidz\assets\data\quran"
$baseUrl = "https://api.alquran.cloud/v1"

if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

# ── 1. Download surah list ──────────────────────────────────
Write-Host "Downloading surah list..." -ForegroundColor Cyan
try {
    $resp     = Invoke-RestMethod -Uri "$baseUrl/surah" -TimeoutSec 30
    $listData = $resp.data | ForEach-Object {
        [ordered]@{
            number         = $_.number
            name           = $_.name
            englishName    = $_.englishName
            numberOfAyahs  = $_.numberOfAyahs
            revelationType = $_.revelationType
        }
    }
    $listJson = ConvertTo-Json $listData -Depth 3 -Compress:$false
    [System.IO.File]::WriteAllText("$outDir\surah_list.json", $listJson,
        [System.Text.Encoding]::UTF8)
    Write-Host "  Saved surah_list.json (${($listData.Count)} entries)" -ForegroundColor Green
} catch {
    Write-Host "  FAILED surah_list: $_" -ForegroundColor Red
    exit 1
}

# ── 2. Download each surah ─────────────────────────────────
$total   = 114
$success = 0
$failed  = @()

for ($i = 1; $i -le $total; $i++) {
    $padded  = $i.ToString("000")
    $outFile = "$outDir\surah_$padded.json"

    # Skip if already downloaded (resume support)
    if (Test-Path $outFile) {
        Write-Host "[$i/$total] surah_$padded.json already exists, skipping." -ForegroundColor DarkGray
        $success++
        continue
    }

    try {
        $url  = "$baseUrl/surah/$i/editions/quran-uthmani,id.indonesian"
        $resp = Invoke-RestMethod -Uri $url -TimeoutSec 30

        $arabicEdition = $resp.data[0]
        $transEdition  = $resp.data[1]

        $ayahs = for ($j = 0; $j -lt $arabicEdition.ayahs.Count; $j++) {
            [ordered]@{
                numberInSurah = [int]$arabicEdition.ayahs[$j].numberInSurah
                arabic        = $arabicEdition.ayahs[$j].text
                translation   = $transEdition.ayahs[$j].text
            }
        }

        $surahObj = [ordered]@{
            number         = [int]$arabicEdition.number
            name           = $arabicEdition.name
            englishName    = $arabicEdition.englishName
            numberOfAyahs  = [int]$arabicEdition.numberOfAyahs
            revelationType = $arabicEdition.revelationType
            ayahs          = @($ayahs)
        }

        $json = ConvertTo-Json $surahObj -Depth 5
        [System.IO.File]::WriteAllText($outFile, $json,
            [System.Text.Encoding]::UTF8)

        $success++
        Write-Host "[$i/$total] surah_$padded.json  ($($arabicEdition.englishName))" `
            -ForegroundColor Green

        # Be gentle on the free API
        Start-Sleep -Milliseconds 250

    } catch {
        $failed += $i
        Write-Host "[$i/$total] ERROR: $_" -ForegroundColor Red
        Start-Sleep -Milliseconds 1000
    }
}

# ── 3. Summary ─────────────────────────────────────────────
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Done: $success/$total surahs saved to $outDir"  -ForegroundColor Cyan
if ($failed.Count -gt 0) {
    Write-Host "Failed surahs: $($failed -join ', ')" -ForegroundColor Yellow
    Write-Host "Re-run the script to retry failed ones (existing files are skipped)."
}
Write-Host "================================================" -ForegroundColor Cyan
