# A lancer APRES 01-install-software.ps1.
# Cree le listener (port 1521) via netca, qui l'enregistre comme un vrai service Windows
# (OracleOraDB19HomeX TNSListener), contrairement a un simple lsnrctl start.

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$ErrorActionPreference = "Stop"

# ===== Variables fixes =====
$OracleBase   = "C:\oracle"
$OracleHome   = "C:\oracle\product\19.3\db_home"
$ListenerPort = 1521

$env:ORACLE_BASE = $OracleBase
$env:ORACLE_HOME = $OracleHome
$env:PATH        = "$OracleHome\bin;$env:PATH"

# Idempotence : si on relance ce script apres un echec precedent, netca sauterait la creation
# en voyant un listener.ora deja existant. On repart propre.
Remove-Item "$OracleHome\network\admin\listener.ora*" -Force -ErrorAction SilentlyContinue

New-Item -ItemType Directory -Force -Path "$OracleBase\response" | Out-Null
$NetcaRsp = "$OracleBase\response\netca.rsp"

@"
[GENERAL]
RESPONSEFILE_VERSION="19.0"
CREATE_TYPE="CUSTOM"

[oracle.net.ca]
INSTALLED_COMPONENTS={"server","net8","javavm"}
INSTALL_TYPE=""typical""
LISTENER_NUMBER=1
LISTENER_NAMES={"LISTENER"}
LISTENER_PROTOCOLS={"TCP;$ListenerPort"}
LISTENER_START=""LISTENER""
NAMING_METHODS={"TNSNAMES","ONAMES","HOSTNAME"}
NSN_NUMBER=1
NSN_NAMES={"EXTPROC_CONNECTION_DATA"}
NSN_SERVICE={"PLSExtProc"}
NSN_PROTOCOLS={"TCP;HOSTNAME;1521"}
"@ | Set-Content -Path $NetcaRsp -Encoding ASCII

& "$OracleHome\bin\netca.bat" -silent -responsefile $NetcaRsp

# ---- Verification ----
Start-Sleep -Seconds 3
$svc = Get-Service -Name "*TNSListener*" -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq "Running") {
    Write-Output "OK : service $($svc.Name) cree et demarre"
} else {
    Write-Output "ECHEC : pas de service TNSListener actif - voir C:\oracle\cfgtoollogs\netca\"
}
