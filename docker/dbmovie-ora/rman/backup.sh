#!/bin/bash
mkdir -p /backup/rman
rman target / cmdfile=/rman_scripts/backup_database.rman log=/backup/rman/backup_$(date +%Y%m%d_%H%M%S).log
