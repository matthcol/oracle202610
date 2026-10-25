# Installe le LOGICIEL Oracle 19c uniquement (software-only), sans creer de base.
# Le zip Windows doit deja etre desarchive dans $OracleHome (setup.exe present a sa racine).

# Auto-elevation : relance ce script en administrateur si besoin. Evite l'echec silencieux
# quand le script est lance via double-clic / "Executer avec PowerShell" (pas d'UAC automatique
# pour un .ps1, contrairement a un .exe).
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

# Variables de process uniquement (ne touche pas aux variables ORACLE_* persistantes
# de la machine, qui servent encore au client installe sous C:\oracle)
$env:ORACLE_BASE     = $OracleBase
$env:ORACLE_HOME     = $OracleHome
$env:ORACLE_SID      = $OracleSid
$env:ORACLE_HOSTNAME = $OracleHostName

New-Item -ItemType Directory -Force -Path "$OracleBase\response" | Out-Null
$ResponseFile = "$OracleBase\response\db_install.rsp"

@"
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v19.0.0
oracle.install.option=INSTALL_DB_SWONLY
ORACLE_BASE=$OracleBase
oracle.install.db.InstallEdition=EE
oracle.install.db.OSDBA_GROUP=ORA_DBA
oracle.install.db.OSOPER_GROUP=ORA_OPER
oracle.install.db.isRACOneInstall=false
oracle.install.IsBuiltInAccount=false
oracle.install.IsVirtualAccount=true
oracle.install.OracleHomeUserName=
oracle.install.OracleHomeUserPassword=
DECLINE_SECURITY_UPDATES=true
SECURITY_UPDATES_VIA_MYORACLESUPPORT=false
"@ | Set-Content -Path $ResponseFile -Encoding ASCII

& "$OracleHome\setup.exe" -silent -ignorePrereqFailure -waitforcompletion -responseFile $ResponseFile

# ---- Verification ----
if (Test-Path "$OracleHome\bin\sqlplus.exe") {
    Write-Output "OK : logiciel installe (sqlplus.exe present dans $OracleHome\bin)"
} else {
    Write-Output "ECHEC : sqlplus.exe absent - voir les logs sous $OracleHome\cfgtoollogs\oui\"
}
