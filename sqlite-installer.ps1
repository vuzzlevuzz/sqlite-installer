$sqliteUri = 'https://system.data.sqlite.org/blobs/1.0.113.0/sqlite-netFx40-setup-x64-2010-1.0.113.0.exe'
$sourceHash = '76AF226E5031EB04C34B9BE6D5E882DA26C85D60F5696520F570D08CE706276E'
$sqliteRegKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{02E43EC2-6B1C-45B5-9E48-941C3E1B204A}_is1'

function Write-OK ($message) { Write-Host "[ ok ] $message" -ForegroundColor Green }
function Write-Warn ($message) { Write-Host "[warn] $message" -ForegroundColor Yellow }
function Write-Fail ($message) { Write-Host "[FAIL] $message" -ForegroundColor Red }
function Write-Action ($message) { Write-Host "$message" -ForegroundColor Cyan }

function Test-Sqlite {
    try { 
        $sqliterootpath = "$(Get-ItemPropertyValue -Path $sqliteRegKey -Name 'InstallLocation' -ErrorAction Ignore )bin"
        $sqlitepath = "$($sqliterootpath)\System.Data.SQLite.dll"
        Add-Type -Path $sqlitepath
        return $true
    }
    catch { 
        return $false
    }
}

function Install-Sqlite {
    if ((Test-Sqlite) -eq $false) {
        Write-Action "Installing sqlite"
        $downloadFile = "$($env:USERPROFILE)\Downloads\$($sqliteUri.split('/')[-1])"
        # verify file hash
        $hashOk = $null
        # first check if we have already downloaded the correct file
        if (Test-Path -Path $downloadFile) {
            $downloadHash = (Get-FileHash -Path $downloadFile -Algorithm SHA256).Hash
            if ( $sourceHash -eq $downloadHash) { $hashOk = $true }
        }
        # if not already downloaded, download
        if (-not $hashOk) {
            Invoke-WebRequest $sqliteUri -Outfile $downloadFile
            $downloadHash = (Get-FileHash -Path $downloadFile -Algorithm SHA256).Hash
            if ( $sourceHash -eq $downloadHash) { $hashOk = $true }
        }
        if ($hashOk) {
            $logfile = "$($downloadFile).install.log"
            Start-Process -FilePath $downloadFile -ArgumentList "/VERYSILENT /NORESTART /NOCLOSEAPPLICATIONS /LOG=$($logfile)"
            # wait for installer to finish - NOTE the downloaded exe launches another process so can't rely on the /Wait switch to Start-Process above
            $timer = 300
            $interval = 1
            do {
                if ((Get-Process -Name 'sqlite*setup*')) {
                    Start-Sleep -Seconds $interval
                    $timer -= $interval
                }
                else {
                    break
                }
            } until ($timer -le 0)
            if ( (get-content $logfile | select-string 'Installation process succeeded.').Matches.length -eq 1) {
                Write-OK "Installation completed successfully"
            }
            else { Write-Fail "Installation process failed, check log: $logfile" }
        }
        else {
            Write-Fail "Downloaded filehash: $downloadHash expected: $sourceHash"
        }
    }
}

function Import-Sqlite {
    if ((Test-Sqlite) -eq $false) {
        Write-Fail "sqlite3 is not installed"
        Install-Sqlite
    }
    if ((Test-Sqlite)) { Write-OK 'sqlite3 is installed' }
    else { Write-Fail "sqlite3 is not installed" }
}

function Uninstall-Sqlite {
    if ((Test-Sqlite)) {
        $uninstallCommand = (Get-ItemPropertyValue -Path $sqliteRegKey -Name 'UninstallString')
        Start-Process -Wait -FilePath $uninstallCommand -ArgumentList '/SILENT /NORESTART'
        if ((Test-Sqlite)) { Write-Fail 'sqlite3 is still installed' }
        else { Write-OK "sqlite3 is not installed" }
    }
    else {
        Write-OK 'sqlite3 is not installed'
    }
}