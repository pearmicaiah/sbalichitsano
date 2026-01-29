$htmlPath = "C:\Users\lenovo2\.gemini\antigravity\scratch\agrion_clone\index.html"
$baseDir = "C:\Users\lenovo2\.gemini\antigravity\scratch\agrion_clone"

if (-not (Test-Path $htmlPath)) {
    Write-Error "index.html not found!"
    exit 1
}

$content = Get-Content $htmlPath -Raw

# Regex patterns to find assets
$patterns = @(
    'href=["'']([^"'']+)["'']',
    'src=["'']([^"'']+)["'']',
    'url\(["'']?([^"'')]+)["'']?\)'
)

$missingAssets = @()

foreach ($pattern in $patterns) {
    $regex = [regex]::new($pattern)
    $matches = $regex.Matches($content)
    
    foreach ($match in $matches) {
        $path = $match.Groups[1].Value
        
        # Filter mostly for local assets
        if ($path -notmatch "^http" -and $path -notmatch "^#" -and $path -notmatch "^mailto:" -and $path -ne "" -and $path -notmatch "^tel:" -and $path -notmatch "^javascript:") {
            # Clean up path (remove query strings, etc)
            $cleanPath = $path.Split('?')[0].Split('#')[0]
            
            # Normalize path separators
            $cleanPath = $cleanPath -replace '/', '\'
            
            $fullPath = Join-Path $baseDir $cleanPath
            if (-not (Test-Path $fullPath)) {
                if ($cleanPath -notin $missingAssets) {
                    $missingAssets += $cleanPath
                    Write-Host "Missing: $cleanPath"
                }
            }
        }
    }
}

if ($missingAssets.Count -eq 0) {
    Write-Host "All assets appear to be present."
}
else {
    Write-Host "Found $($missingAssets.Count) missing assets."
    $missingAssets | Out-File (Join-Path $baseDir "missing_assets.txt")
}
