$baseUrl = "https://pixydrops.com/agrionhtml/main-html/"
$baseDir = "C:\Users\lenovo2\.gemini\antigravity\scratch\agrion_clone"

function Download-Asset($relativeUrl, $localPath) {
    if (Test-Path $localPath) {
        # Write-Host "Skipping $relativeUrl (exists)"
        return
    }
    
    $fullUrl = $baseUrl + ($relativeUrl -replace '\\', '/')
    $dir = Split-Path $localPath
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    
    Write-Host "Downloading $fullUrl to $localPath"
    try {
        Invoke-WebRequest -Uri $fullUrl -OutFile $localPath -UserAgent "Mozilla/5.0" -ErrorAction Stop
    }
    catch {
        Write-Host "Failed: $fullUrl"
    }
}

# 1. Re-scan all HTML files
Get-ChildItem -Path $baseDir -Filter "*.html" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $matches = [regex]::Matches($content, '(?:href|src|data-src|data-img-url)=["'']([^"'']+)["'']')
    foreach ($m in $matches) {
        $path = $m.Groups[1].Value
        if ($path -notmatch "^http" -and $path -notmatch "^#" -and $path -notmatch "^mailto:" -and $path -ne "" -and $path -notmatch "^tel:") {
            $cleanPath = $path.Split('?')[0].Split('#')[0]
            Download-Asset $cleanPath (Join-Path $baseDir $cleanPath)
        }
    }
}

# 2. Scan all CSS files for url()
Get-ChildItem -Path $baseDir -Filter "*.css" -Recurse | ForEach-Object {
    $cssFile = $_
    $content = Get-Content $cssFile.FullName -Raw
    $matches = [regex]::Matches($content, 'url\(["'']?([^"'')]+)["'']?\)')
    foreach ($m in $matches) {
        $path = $m.Groups[1].Value
        if ($path -notmatch "^http" -and $path -notmatch "^data:" -and $path -ne "") {
            $cleanPath = $path.Split('?')[0].Split('#')[0]
            
            # Resolve relative path
            # If path is 'fonts/foo.woff' and CSS is in 'assets/css/style.css', local path is 'assets/css/fonts/foo.woff'
            # If path is '../fonts/foo.woff' and CSS is in 'assets/css/style.css', local path is 'assets/fonts/foo.woff'
            
            $cssDir = Split-Path $cssFile.FullName
            $relativeToAgrionClone = (Resolve-Path (Join-Path $cssDir $cleanPath) -ErrorAction SilentlyContinue).Path
            
            if ($null -eq $relativeToAgrionClone) {
                # Mannually resolve if file doesn't exist yet
                $combined = [System.IO.Path]::GetFullPath((Join-Path $cssDir $cleanPath))
                $sourceRoot = [System.IO.Path]::GetFullPath($baseDir)
                
                if ($combined.StartsWith($sourceRoot)) {
                    $localRelative = $combined.Substring($sourceRoot.Length).TrimStart('\')
                    Download-Asset ($localRelative -replace '\\', '/') $combined
                }
            }
        }
    }
}

# 3. Known missing vendor assets (manually injected if common)
$extraAssets = @(
    "assets/images/loader.png",
    "assets/vendors/agrion-icons/fonts/icomoon.woff",
    "assets/vendors/agrion-icons/fonts/icomoon.ttf",
    "assets/vendors/fontawesome/webfonts/fa-solid-900.woff2",
    "assets/vendors/fontawesome/webfonts/fa-brands-400.woff2",
    "assets/vendors/fontawesome/webfonts/fa-regular-400.woff2"
)

foreach ($asset in $extraAssets) {
    Download-Asset $asset (Join-Path $baseDir $asset)
}
