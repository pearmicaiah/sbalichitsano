$baseUrl = "https://pixydrops.com/agrionhtml/main-html/"
$baseDir = "C:\Users\lenovo2\.gemini\antigravity\scratch\agrion_clone"
$htmlPath = Join-Path $baseDir "index.html"

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

$assetsToDownload = @()

foreach ($pattern in $patterns) {
    $regex = [regex]::new($pattern)
    $matches = $regex.Matches($content)
    
    foreach ($match in $matches) {
        $path = $match.Groups[1].Value
        
        # Filter mostly for local assets
        if ($path -notmatch "^http" -and $path -notmatch "^#" -and $path -notmatch "^mailto:" -and $path -ne "" -and $path -notmatch "^tel:") {
            # Clean up path (remove query strings, etc)
            $cleanPath = $path.Split('?')[0].Split('#')[0]
            
            # Normalize path separators
            $cleanPath = $cleanPath -replace '/', '\'
            
            if ($cleanPath -notin $assetsToDownload) {
                $assetsToDownload += $cleanPath
            }
        }
    }
}

# Add likely missing font files or known vendor assets if they are usually dynamic or not in index
# For now, stick to index.html extraction.

foreach ($asset in $assetsToDownload) {
    # Fix regex/split issues where path might start with \ or similar
    $asset = $asset.TrimStart('\').TrimStart('/')
    
    # Original URL path uses forward slashes
    $urlPath = $asset -replace '\\', '/'
    $url = $baseUrl + $urlPath
    
    $output = Join-Path $baseDir $asset
    $dir = Split-Path $output
    
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    
    if (!(Test-Path $output)) {
        Write-Host "Downloading $asset..."
        try {
            $webRequest = Invoke-WebRequest -Uri $url -OutFile $output -UserAgent "Mozilla/5.0" -ErrorAction Stop
        }
        catch {
            Write-Host "Failed to download $asset : $_"
        }
    }
    else {
        Write-Host "Skipping $asset (already exists)"
    }
}
