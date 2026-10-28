# Dumps Oracle
# - imp/exp : "SQL" - historique - deprecated
# - impdp/expdp : Data Pump - Binaire
# - SQL*loader

# NB: pour avoir un export coherent à chaud bien rajouter
# le parametre FLASHBACK_SCN ou FLASHBACK_TIME

# Exemple d'export avec grain schema
# utiliser le user system ou sys
expdp PARFILE=export_dbmovie.param

# checkup repertoire DATA_PUMP_DIR (default)
ls -lh /oracle/admin/ora19/dpdump/

# Exemple d'import avec grain table et remap de nom de table
impdp PARFILE=import_table_play_remap.param
