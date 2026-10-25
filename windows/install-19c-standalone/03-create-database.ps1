# A lancer APRES 02-create-listener.ps1.
# Cree la base en mode silencieux : standalone (non-CDB), template General Purpose,
# gestion memoire automatique (un seul curseur).

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$ErrorActionPreference = "Stop"

# ===== Variables fixes =====
$OracleBase     = "C:\oracle"
$OracleHome     = "C:\oracle\product\19.3\db_home"
$OracleSid      = "ora19"
$OracleHostName = $env:COMPUTERNAME
$DbPassword     = "password1234"   # sys / system identiques

$env:ORACLE_BASE     = $OracleBase
$env:ORACLE_HOME     = $OracleHome
$env:ORACLE_SID      = $OracleSid
$env:ORACLE_HOSTNAME = $OracleHostName
$env:PATH            = "$OracleHome\bin;$env:PATH"

& "$OracleHome\bin\dbca.bat" -silent -createDatabase `
  -templateName General_Purpose.dbc `
  -gdbname $OracleSid `
  -sid $OracleSid `
  -createAsContainerDatabase false `
  -databaseType MULTIPURPOSE `
  -characterSet AL32UTF8 `
  -memoryPercentage 40 `
  -emConfiguration NONE `
  -datafileDestination "$OracleBase\oradata" `
  -recoveryAreaDestination "$OracleBase\fast_recovery_area" `
  -storageType FS `
  -listeners LISTENER `
  -sysPassword $DbPassword `
  -systemPassword $DbPassword `
  -sampleSchema false `
  -ignorePreReqs

# ---- Verification ----
$svc = Get-Service -Name "OracleService$OracleSid" -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq "Running") {
    Write-Output "OK : service OracleService$OracleSid cree et demarre"
} else {
    Write-Output "ECHEC : service OracleService$OracleSid absent/arrete - voir $OracleBase\cfgtoollogs\dbca\$OracleSid\"
}
