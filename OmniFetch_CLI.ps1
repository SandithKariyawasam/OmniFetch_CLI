<#
.SYNOPSIS
    OmniFetch_CLI v1.3 - Continuous Loop Edition
#>

# --- CONFIGURATION (Runs once at startup) ---
$DownloadFolder = Join-Path $PSScriptRoot "Downloads"
$YtDlpPath = Join-Path $PSScriptRoot "yt-dlp.exe"
$FFmpegPath = Join-Path $PSScriptRoot "ffmpeg.exe"

# Create Downloads Directory
if (-not (Test-Path $DownloadFolder)) { New-Item -ItemType Directory -Path $DownloadFolder | Out-Null }

# --- HELPER FUNCTIONS ---
function Format-Bytes {
    param ([long]$Bytes)
    switch ($Bytes) {
        {$_ -gt 1GB} { return "{0:N2} GB" -f ($Bytes / 1GB) }
        {$_ -gt 1MB} { return "{0:N2} MB" -f ($Bytes / 1MB) }
        {$_ -gt 1KB} { return "{0:N2} KB" -f ($Bytes / 1KB) }
        default      { return "{0:N0} Bytes" -f $Bytes }
    }
}

function Get-ExtensionFromMime {
    param ([string]$MimeType)
    $MimeMap = @{
        'video/mp4'='.mp4'; 'video/webm'='.webm'; 'video/x-matroska'='.mkv'; 'video/quicktime'='.mov';
        'image/jpeg'='.jpg'; 'image/png'='.png'; 'image/gif'='.gif'; 'image/webp'='.webp';
        'audio/mpeg'='.mp3'; 'audio/wav'='.wav'; 'audio/ogg'='.ogg'; 'application/zip'='.zip';
        'application/pdf'='.pdf'; 'text/plain'='.txt'; 'application/vnd.rar'='.rar'
    }
    if ($MimeMap.ContainsKey($MimeType)) { return $MimeMap[$MimeType] }
    return ""
}

# ==========================================
# MAIN LOOP START
# ==========================================
do {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   OmniFetch_CLI v1.3 (Continuous)        " -ForegroundColor White
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   Type 'exit' to close the program       " -ForegroundColor DarkGray
    Write-Host "==========================================" -ForegroundColor Cyan

    # 1. Get URL
    $Url = Read-Host "`nPaste URL"
    
    if ([string]::IsNullOrWhiteSpace($Url)) { continue }
    if ($Url.ToLower() -eq "exit") { break }

    # 2. Smart Mode Selection
    Write-Host "`n[?] Select Download Mode:" -ForegroundColor Yellow
    Write-Host "    [1] Direct File  (For .zip, .exe, .mp4 links)" -ForegroundColor Gray
    Write-Host "    [2] Web Video    (For YouTube, Streaming, Hidden m3u8)" -ForegroundColor Gray

    $DefaultMode = "2"
    if ($Url -match "\.(zip|rar|exe|iso|pdf|jpg|png)$") { $DefaultMode = "1" }

    $ModeChoice = Read-Host "    Enter [1] or [2] (Default: $DefaultMode)"
    if ([string]::IsNullOrWhiteSpace($ModeChoice)) { $ModeChoice = $DefaultMode }

    # --- EXECUTION ---

    if ($ModeChoice -eq "2") {
        # ==========================================
        # MODE: WEB VIDEO / ADVANCED
        # ==========================================
        Write-Host "`n[MODE] Web Video Extraction" -ForegroundColor Cyan
        
        if (-not (Test-Path $YtDlpPath)) {
            Write-Host "`n[X] ERROR: yt-dlp.exe is missing!" -ForegroundColor Red
            Read-Host "Press Enter to continue..."
            continue
        }

        # --- AUTO-SNIFFER ---
        if ($Url -notmatch "\.m3u8$") {
            Write-Host "Scanning page for hidden streams..." -ForegroundColor Yellow
            try {
                $WebReq = [System.Net.HttpWebRequest]::Create($Url)
                $WebReq.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                $WebResp = $WebReq.GetResponse()
                $StreamReader = [System.IO.StreamReader]::new($WebResp.GetResponseStream())
                $HtmlContent = $StreamReader.ReadToEnd()
                $StreamReader.Close(); $WebResp.Close()

                if ($HtmlContent -match '["''](https?:\/\/[^"''\s]+\.m3u8.*?)["'']') {
                    $HiddenLink = $matches[1]
                    Write-Host "    Target switched to hidden stream!" -ForegroundColor Green
                    $Url = $HiddenLink
                }
            } catch {
                Write-Host "    Scanner skipped (Page protected)." -ForegroundColor DarkGray
            }
        }

        Write-Host "Engaging engine..." -ForegroundColor Cyan
        $ArgsList = @(
            "-o", "$DownloadFolder\%(title)s.%(ext)s",
            "--merge-output-format", "mp4",
            "--no-playlist",
            "--referer", $Url,
            $Url
        )

        Start-Process -FilePath $YtDlpPath -ArgumentList $ArgsList -Wait -NoNewWindow
        Write-Host "`n[√] Process Finished." -ForegroundColor Green

    } else {
        # ==========================================
        # MODE: DIRECT DOWNLOAD
        # ==========================================
        Write-Host "`n[MODE] Direct File Download" -ForegroundColor Cyan

        try {
            Write-Host "[1/3] Connecting..." -ForegroundColor Yellow
            $Request = [System.Net.HttpWebRequest]::Create($Url)
            $Request.Method = "HEAD"
            $Response = $Request.GetResponse()
            
            $TotalSize = $Response.ContentLength
            $MimeType = $Response.ContentType.Split(';')[0]
            $RemoteName = $Response.ResponseUri.Segments[-1]
            $Response.Close()

            $Extension = Get-ExtensionFromMime $MimeType
            if (-not $Extension) { $Extension = [System.IO.Path]::GetExtension($RemoteName) }
            
            $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($RemoteName)
            $BaseName = $BaseName -replace '[\\/:*?"<>|]', '_'
            if ([string]::IsNullOrWhiteSpace($BaseName)) { $BaseName = "downloaded_file" }
            
            $FileName = "$BaseName$Extension"
            $FilePath = Join-Path $DownloadFolder $FileName
            $PartFilePath = "$FilePath.part"

            Write-Host "File: $FileName" -ForegroundColor Green
            Write-Host "Size: $(Format-Bytes $TotalSize)" -ForegroundColor Green

            $StartByte = 0
            $FileMode = [System.IO.FileMode]::Create

            if (Test-Path $PartFilePath) {
                $CurrentPartSize = (Get-Item $PartFilePath).Length
                Write-Host "`n[!] Partial download found ($(Format-Bytes $CurrentPartSize))." -ForegroundColor Yellow
                $ResChoice = Read-Host "Resume (Y) or Restart (N)? [Y/N]"
                if ($ResChoice -eq 'Y' -or $ResChoice -eq '') {
                    $StartByte = $CurrentPartSize
                    $FileMode = [System.IO.FileMode]::Append
                }
            } elseif (Test-Path $FilePath) {
                Write-Warning "File already exists!"
                $ConflictChoice = Read-Host "Overwrite (O), Rename (R), Cancel (C)? [O/R/C]"
                switch ($ConflictChoice.ToUpper()) {
                    'O' { Remove-Item $FilePath }
                    'R' { 
                        $NewName = Read-Host "Enter new name"
                        $FileName = $NewName
                        $FilePath = Join-Path $DownloadFolder $FileName
                        $PartFilePath = "$FilePath.part"
                    }
                    default { continue } # Go back to start of loop
                }
            }

            if ($TotalSize -gt 0 -and $StartByte -ge $TotalSize) {
                Write-Host "Download already complete." -ForegroundColor Green
                Move-Item $PartFilePath $FilePath -Force -ErrorAction SilentlyContinue
                continue # Go back to start
            }

            Write-Host "`n[2/3] Downloading..." -ForegroundColor Yellow
            $WebRequest = [System.Net.HttpWebRequest]::Create($Url)
            if ($StartByte -gt 0) { $WebRequest.AddRange($StartByte) }
            
            $WebResponse = $WebRequest.GetResponse()
            $RemoteStream = $WebResponse.GetResponseStream()
            $LocalStream = [System.IO.FileStream]::new($PartFilePath, $FileMode, [System.IO.FileAccess]::Write)

            $Buffer = New-Object byte[] (32 * 1024)
            $TotalRead = $StartByte
            $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $LastUpdate = $Stopwatch.Elapsed.TotalSeconds

            while (($BytesRead = $RemoteStream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
                $LocalStream.Write($Buffer, 0, $BytesRead)
                $TotalRead += $BytesRead
                
                if ($Stopwatch.Elapsed.TotalSeconds - $LastUpdate -gt 0.2) {
                    $Speed = ($TotalRead - $StartByte) / $Stopwatch.Elapsed.TotalSeconds
                    $Percent = if ($TotalSize -gt 0) { ($TotalRead / $TotalSize) * 100 } else { 0 }
                    
                    $Filled = [math]::Floor($Percent / 2)
                    $ProgressBar = "[" + ("#" * $Filled) + ("-" * (50 - $Filled)) + "]"
                    
                    Write-Host -NoNewline ("`r$ProgressBar {0:N1}% | {1}/s " -f $Percent, (Format-Bytes $Speed))
                    $LastUpdate = $Stopwatch.Elapsed.TotalSeconds
                }
            }

            $LocalStream.Close(); $RemoteStream.Close(); $WebResponse.Close(); $Stopwatch.Stop()

            if (Test-Path $FilePath) { Remove-Item $FilePath }
            Rename-Item $PartFilePath $FileName
            
            Write-Host "`n`n[3/3] Download Complete!" -ForegroundColor Green

        } catch {
            Write-Error "`nError: $_"
            if ($LocalStream) { $LocalStream.Close() }
        }
    }

    # Pause briefly before clearing screen for the next job
    Write-Host "`n------------------------------------------" -ForegroundColor DarkGray
    Write-Host "Ready for next download..." -ForegroundColor Gray
    Start-Sleep -Seconds 2

} while ($true) # Loop forever until 'break' is called