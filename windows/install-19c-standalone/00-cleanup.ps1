# Nettoyage complet avant de recommencer l'install a zero.
# Supprime : services Windows, cle de registre du home, groupes locaux ORA_*,
# et tous les fichiers sous C:\oracle (y compris le logiciel desarchive).
# Ne touche PAS a KEY_OracleClientForMicrosoftTools / ODP.NET (composants separes, sans lien).

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$OracleBase = "C:\oracle"

Write-Output "--- Arret et suppression des services Oracle (hors home client) ---"
Get-CimInstance Win32_Service | Where-Object { $_.Name -like "Oracle*" -and $_.PathName -like "*$OracleBase*" } | ForEach-Object {
    sc.exe stop $_.Name | Out-Null
    sc.exe delete $_.Name | Out-Null
    Write-Output "Supprime : $($_.Name)"
}

Write-Output "--- Suppression des cles de registre KEY_OraDB19Home* ---"
Get-ChildItem "HKLM:\SOFTWARE\ORACLE" -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -like "KEY_OraDB19Home*" } |
    ForEach-Object {
        Remove-Item -Path $_.PSPath -Recurse -Force
        Write-Output "Supprime : $($_.PSChildName)"
    }

Write-Output "--- Suppression des groupes locaux ORA_* ---"
Get-LocalGroup | Where-Object { $_.Name -like "ORA_*" } | ForEach-Object {
    Remove-LocalGroup -Name $_.Name
    Write-Output "Supprime : $($_.Name)"
}

Write-Output "--- Suppression de $OracleBase (logiciel + donnees + logs) ---"
Remove-Item -Path $OracleBase -Recurse -Force -ErrorAction SilentlyContinue

Write-Output "--- Verification finale ---"
Get-CimInstance Win32_Service | Where-Object { $_.Name -like "Oracle*" } | Select-Object Name
Get-LocalGroup | Where-Object { $_.Name -like "ORA_*" }
Test-Path $OracleBase

Write-Output "Nettoyage termine. Redesarchivez le zip 19c dans $OracleBase\product\19.3\db_home avant de relancer 01-install-software.ps1."
