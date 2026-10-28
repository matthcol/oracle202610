# Fiche : Statistiques & Optimisation Oracle Database

NB: Rédigée à l'aide de Claude AI

## 1. Vue d'ensemble

L'optimiseur Oracle (CBO - Cost Based Optimizer) choisit un plan d'exécution en fonction
des **statistiques** collectées sur les objets (tables, index, colonnes) et sur le système.
Sans stats à jour → plans foireux → requêtes lentes. Tout tourne autour de ça.

Chaîne logique : `stats fraîches -> estimation cardinalités correcte -> bon plan -> perf`

---

## 2. Tables / vues contenant les statistiques

### 2.1 Statistiques d'objets (tables, colonnes, index, partitions)

| Vue | Contenu |
|---|---|
| `DBA_TABLES` | `NUM_ROWS`, `BLOCKS`, `AVG_ROW_LEN`, `LAST_ANALYZED`, `STALE_STATS` |
| `DBA_TAB_STATISTICS` | stats détaillées table/partition, `STATTYPE_LOCKED` |
| `DBA_TAB_COL_STATISTICS` | `NUM_DISTINCT`, `DENSITY`, `NUM_NULLS`, `LOW_VALUE`/`HIGH_VALUE`, `LAST_ANALYZED` |
| `DBA_TAB_COLUMNS` | infos colonnes + `NUM_DISTINCT`, `NUM_NULLS` (jointure pratique avec le nom de colonne) |
| `DBA_TAB_HISTOGRAMS` | histogrammes par colonne (répartition des valeurs) |
| `DBA_INDEXES` | `NUM_ROWS`, `DISTINCT_KEYS`, `BLEVEL`, `LEAF_BLOCKS`, `CLUSTERING_FACTOR`, `STATUS` |
| `DBA_IND_STATISTICS` | stats détaillées index/partition d'index |
| `DBA_PART_TABLES` / `DBA_TAB_PARTITIONS` | stats au niveau partition |
| `DBA_TAB_MODIFICATIONS` | compteur d'inserts/updates/deletes depuis le dernier `GATHER` -> détecte les stats obsolètes |
| `DBA_TAB_STATS_HISTORY` | historique des collectes (sert à `RESTORE_TABLE_STATS`) |
| `DBA_OPTSTAT_OPERATIONS` | historique des opérations DBMS_STATS (jobs auto, manuels) |
| `DBA_TABLES.STALE_STATS` | colonne indicatrice directe "stats à rafraîchir" |

```sql
-- stats table + statut "stale"
SELECT table_name, num_rows, blocks, last_analyzed, stale_stats
FROM   dba_tab_statistics
WHERE  owner = 'UMOVIE';

-- stats colonnes
SELECT column_name, num_distinct, density, num_nulls, histogram, last_analyzed
FROM   dba_tab_col_statistics
WHERE  owner = 'UMOVIE' AND table_name = 'MOVIE';

-- modifications depuis dernière collecte
SELECT table_name, inserts, updates, deletes, truncated, timestamp
FROM   dba_tab_modifications
WHERE  table_owner = 'UMOVIE';
```

### 2.2 Statistiques système (CPU, I/O)

```sql
SELECT pname, pval1 FROM sys.aux_stats$;   -- CPUSPEED, IOSEEKTIM, IOTFRSPEED, SREADTIM, MREADTIM...
```

### 2.3 Stats du dictionnaire / objets fixes

```sql
EXEC DBMS_STATS.GATHER_DICTIONARY_STATS;   -- stats des tables SYS (dictionnaire)
EXEC DBMS_STATS.GATHER_FIXED_OBJECTS_STATS; -- stats des vues X$/V$ (à faire après charge représentative)
```

### 2.4 Préférences de collecte

```sql
SELECT DBMS_STATS.GET_PREFS('ESTIMATE_PERCENT') FROM dual;
SELECT DBMS_STATS.GET_PREFS('STALE_PERCENT', 'UMOVIE', 'MOVIE') FROM dual;
```

---

## 3. Rafraîchissement des statistiques

### 3.1 Automatique

Oracle lance par défaut un job planifié **"auto optimizer stats job"** (Scheduler) la nuit,
qui appelle `DBMS_STATS.GATHER_DATABASE_STATS_JOB_PROC` et ne retraite que les objets
dont les stats sont **stale** (seuil par défaut : 10% de lignes modifiées, `STALE_PERCENT`).

```sql
-- voir le job auto
SELECT client_name, status, enabled
FROM   dba_autotask_client
WHERE  client_name = 'auto optimizer stats collection';

-- fenêtres d'exécution (par défaut nuit + weekend)
SELECT * FROM dba_autotask_window_clients;

-- activer/désactiver le job auto
EXEC DBMS_AUTO_TASK_ADMIN.ENABLE('auto optimizer stats collection', NULL, NULL);
EXEC DBMS_AUTO_TASK_ADMIN.DISABLE('auto optimizer stats collection', NULL, NULL);
```

### 3.1 bis Planification personnalisée (différente du job par défaut)

Le job auto ne tourne que dans les fenêtres de maintenance (nuit en semaine + week-end) et
ne retraite que les objets stale. Si on veut une autre logique — horaire fixe, schéma
ciblé, recalcul complet plutôt que "seulement stale" — on crée son **propre job
`DBMS_SCHEDULER`**, indépendant du mécanisme auto :

```sql
BEGIN
  DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'UMOVIE_STATS_JOB',
    job_type        => 'PLSQL_BLOCK',
    job_action       => 'BEGIN DBMS_STATS.GATHER_SCHEMA_STATS(
                            ownname => ''UMOVIE'', options => ''GATHER AUTO''); END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY;BYHOUR=3;BYMINUTE=0;BYSECOND=0',  -- tous les jours à 3h
    enabled         => TRUE,
    comments        => 'Collecte stats schema UMOVIE, independante du job auto');
END;
/
```

On peut typiquement couper le job auto en parallèle (`DBMS_AUTO_TASK_ADMIN.DISABLE` ci-dessus)
si on veut garder le contrôle total et éviter que les deux tournent en double.

**Voir cette programmation :**

```sql
-- déclaration du job : planification, statut, prochaine exécution
SELECT job_name, enabled, state, repeat_interval, next_run_date, last_start_date
FROM   dba_scheduler_jobs
WHERE  job_name = 'UMOVIE_STATS_JOB';

-- action réellement exécutée par le job
SELECT job_name, job_action
FROM   dba_scheduler_jobs
WHERE  job_name = 'UMOVIE_STATS_JOB';

-- historique des exécutions passées (succès, durée, erreur éventuelle)
SELECT job_name, status, actual_start_date, run_duration, error#
FROM   dba_scheduler_job_run_details
WHERE  job_name = 'UMOVIE_STATS_JOB'
ORDER  BY actual_start_date DESC;

-- vue d'ensemble de tous les jobs scheduler du schéma courant (pas que celui-ci)
SELECT job_name, program_name, schedule_name, enabled, state
FROM   user_scheduler_jobs;
```

### 3.2 Manuel

```sql
-- une table
EXEC DBMS_STATS.GATHER_TABLE_STATS(
       ownname => 'UMOVIE', tabname => 'MOVIE',
       estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
       method_opt       => 'FOR ALL COLUMNS SIZE AUTO',
       cascade          => TRUE,   -- recalcule aussi les index de la table
       degree           => DBMS_STATS.AUTO_DEGREE);

-- tout un schéma
EXEC DBMS_STATS.GATHER_SCHEMA_STATS('UMOVIE');

-- toute la base
EXEC DBMS_STATS.GATHER_DATABASE_STATS;

-- uniquement les objets stale (plus rapide, comme le job auto)
EXEC DBMS_STATS.GATHER_SCHEMA_STATS('UMOVIE', options => 'GATHER STALE');
EXEC DBMS_STATS.GATHER_SCHEMA_STATS('UMOVIE', options => 'GATHER AUTO');

-- un seul index
EXEC DBMS_STATS.GATHER_INDEX_STATS('UMOVIE', 'IDX_MOVIE_TITLE');
```

### 3.3 Verrouiller / restaurer / supprimer

```sql
-- empêcher tout recalcul (table de référence stable, volumétrie figée...)
EXEC DBMS_STATS.LOCK_TABLE_STATS('UMOVIE', 'MOVIE');
EXEC DBMS_STATS.UNLOCK_TABLE_STATS('UMOVIE', 'MOVIE');

-- revenir à un état antérieur (utile si un GATHER a dégradé les perfs)
EXEC DBMS_STATS.RESTORE_TABLE_STATS('UMOVIE', 'MOVIE', SYSTIMESTAMP - 1);
```

### 3.3 bis Personnalisation par table : changer le ratio de staleness (`STALE_PERCENT`)

Par défaut, une table est considérée "stale" (donc reprise par le `GATHER ... STALE` /
job auto) dès que **10%** de ses lignes ont été modifiées (insert+update+delete) depuis
la dernière collecte. Pour une table volumineuse et peu mouvante, ou au contraire une
table très volatile qu'on veut retraiter plus souvent, on ajuste ce ratio **au niveau
de la table** (sans toucher au défaut global) :

```sql
-- valeur actuelle (hérite du défaut global si rien n'a été fixé pour cette table)
SELECT DBMS_STATS.GET_PREFS('STALE_PERCENT', 'UMOVIE', 'MOVIE') FROM dual;  -- 10 par défaut

-- ex. table très grosse, peu de DML relatif à son volume -> on relève le seuil à 20%
-- (évite un recalcul "pour pas grand chose" qui coûterait cher en CPU/IO)
EXEC DBMS_STATS.SET_TABLE_PREFS('UMOVIE', 'MOVIE', 'STALE_PERCENT', '20');

-- ex. table petite mais très volatile (file d'attente, table de staging...)
-- -> on abaisse le seuil à 5% pour la retraiter plus tôt
EXEC DBMS_STATS.SET_TABLE_PREFS('UMOVIE', 'PLAY', 'STALE_PERCENT', '5');
```

```sql
-- vérifier après coup
SELECT DBMS_STATS.GET_PREFS('STALE_PERCENT', 'UMOVIE', 'MOVIE') FROM dual;  -- 20

-- lister toutes les préférences personnalisées (différentes du défaut global) d'un schéma
SELECT table_name, preference_name, preference_value
FROM   dba_tab_stat_prefs
WHERE  owner = 'UMOVIE';

-- revenir au défaut global pour cette table
EXEC DBMS_STATS.DELETE_TABLE_PREFS('UMOVIE', 'MOVIE', 'STALE_PERCENT');
```

Même principe pour d'autres préférences par table : `ESTIMATE_PERCENT`, `METHOD_OPT`,
`CASCADE`, `INCREMENTAL`, `PUBLISH`... (`SET_TABLE_PREFS` au lieu de `SET_GLOBAL_PREFS`).

-- supprimer les stats (force un recalcul / dynamic sampling)
EXEC DBMS_STATS.DELETE_TABLE_STATS('UMOVIE', 'MOVIE');
```

### 3.4 Stats en attente (pending) — tester avant publication

```sql
EXEC DBMS_STATS.SET_TABLE_PREFS('UMOVIE', 'MOVIE', 'PUBLISH', 'FALSE');
EXEC DBMS_STATS.GATHER_TABLE_STATS('UMOVIE', 'MOVIE');   -- va dans les stats "pending"
-- tester avec : ALTER SESSION SET optimizer_use_pending_statistics = TRUE;
EXEC DBMS_STATS.PUBLISH_PENDING_STATS('UMOVIE', 'MOVIE'); -- ou DELETE_PENDING_STATS
```

### 3.5 Stats incrémentales (tables partitionnées)

```sql
EXEC DBMS_STATS.SET_TABLE_PREFS('UMOVIE', 'MOVIE', 'INCREMENTAL', 'TRUE');
-- ne recalcule que les partitions modifiées, synthèse via "synopsis" au niveau global
```

---

## 4. Index / Plan d'exécution / Hints

### 4.1 Index

```sql
-- catalogue des index
SELECT index_name, index_type, uniqueness, status, blevel, leaf_blocks, clustering_factor
FROM   dba_indexes
WHERE  table_owner = 'UMOVIE' AND table_name = 'MOVIE';

SELECT index_name, column_name, column_position
FROM   dba_ind_columns
WHERE  table_owner = 'UMOVIE' AND table_name = 'MOVIE'
ORDER  BY index_name, column_position;
```

Types courants : B-tree (défaut), **bitmap** (colonnes à faible cardinalité, DWH),
**function-based** (`CREATE INDEX ... ON t(UPPER(col))`), **composite** (multi-colonnes,
ordre important), **invisible** (`ALTER INDEX i INVISIBLE` — testable sans impacter les
plans existants via `optimizer_use_invisible_indexes`).

```sql
-- index inutilisés ?
ALTER INDEX idx_movie_title MONITORING USAGE;
SELECT * FROM v$object_usage WHERE index_name = 'IDX_MOVIE_TITLE';  -- 11g
-- 12c+ :
SELECT * FROM dba_index_usage WHERE name = 'IDX_MOVIE_TITLE';

-- reconstruire un index (fragmenté / UNUSABLE après move de table)
ALTER INDEX idx_movie_title REBUILD ONLINE;

-- santé d'un index
ANALYZE INDEX idx_movie_title VALIDATE STRUCTURE;
SELECT height, lf_rows, del_lf_rows, br_rows FROM index_stats; -- del_lf_rows élevé = fragmenté
```

### 4.2 Plan d'exécution

```sql
EXPLAIN PLAN FOR
SELECT * FROM umovie.movie WHERE title LIKE 'Matrix%';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- plan réel après exécution (avec stats réelles ligne/mémoire)
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

-- SQL*Plus
SET AUTOTRACE ON EXPLAIN STATISTICS;
```

Points de lecture : `Cost`, `Rows` (estimé) vs `A-Rows` (réel, si gather_plan_statistics),
accès `TABLE ACCESS FULL` vs `INDEX RANGE SCAN`, jointures `NESTED LOOPS` / `HASH JOIN` /
`MERGE JOIN`, opérations `SORT`, `PARTITION`.

```sql
-- forcer la capture des stats réelles d'exécution (diag ponctuel, coûte en perf)
ALTER SESSION SET statistics_level = ALL;
-- ou hint : SELECT /*+ GATHER_PLAN_STATISTICS */ ...
```

### 4.3 Hints

Syntaxe : `/*+ HINT */` juste après le mot-clé (SELECT/INSERT/UPDATE/DELETE/MERGE).

| Hint | Usage |
|---|---|
| `FULL(t)` | forcer un full scan |
| `INDEX(t idx)` / `NO_INDEX(t idx)` | forcer / interdire un index |
| `USE_NL(a b)` / `USE_HASH(a b)` / `USE_MERGE(a b)` | forcer le type de jointure |
| `LEADING(a b)` | ordre des tables dans la jointure |
| `PARALLEL(t 4)` | degré de parallélisme |
| `GATHER_PLAN_STATISTICS` | capturer stats réelles pour `DISPLAY_CURSOR` |
| `RESULT_CACHE` | mettre le résultat en cache |
| `DYNAMIC_SAMPLING(t 4)` | forcer un échantillonnage dynamique si stats absentes/mauvaises |

```sql
SELECT /*+ INDEX(m idx_movie_title) */ *
FROM   movie m
WHERE  title LIKE 'Matrix%';
```

⚠️ Un hint n'est qu'une **suggestion** (sauf quelques-uns) : l'optimiseur peut l'ignorer
s'il est syntaxiquement invalide ou incohérent avec le plan possible. À utiliser en dernier
recours — préférer corriger les stats / l'écriture de la requête.

### 4.4 Outils d'aide à la décision

```sql
-- SQL Tuning Advisor (diagnostic + recommandations : index, stats, SQL profile, réécriture)
DECLARE
  v_task VARCHAR2(30);
BEGIN
  v_task := DBMS_SQLTUNE.CREATE_TUNING_TASK(sql_id => '7f7xyz123abcd');
  DBMS_SQLTUNE.EXECUTE_TUNING_TASK(v_task);
END;
/
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK(v_task) FROM dual;

-- SQL Plan Baseline : fige un plan stable connu comme bon, évite les régressions
SELECT * FROM dba_sql_plan_baselines;

-- SQL Access Advisor : recommandations d'index/MV pour une charge donnée
```

---

## 5. Fragmentation des tablespaces

### 5.1 Diagnostiquer

```sql
-- espace libre par tablespace + fragmentation (nb. de trous)
SELECT tablespace_name,
       COUNT(*)              AS nb_fragments,
       ROUND(SUM(bytes)/1024/1024) AS free_mb,
       ROUND(MAX(bytes)/1024/1024) AS max_chunk_mb
FROM   dba_free_space
GROUP  BY tablespace_name
ORDER  BY nb_fragments DESC;

-- segments et leur taille réelle vs allouée (high water mark)
SELECT segment_name, segment_type, tablespace_name, bytes/1024/1024 AS mb
FROM   dba_segments
WHERE  owner = 'UMOVIE'
ORDER  BY bytes DESC;

-- extents d'un objet (dispersion physique)
SELECT segment_name, extent_id, bytes, blocks
FROM   dba_extents
WHERE  owner = 'UMOVIE' AND segment_name = 'MOVIE';

-- espace "gaspillé" dans une table (lignes supprimées, HWM haut)
SELECT table_name, num_rows, blocks, empty_blocks, avg_row_len
FROM   dba_tables
WHERE  owner = 'UMOVIE';
```

### 5.2 Corriger

```sql
-- fusionner les trous de libre contigus (tablespaces DMT historiques, rarement utile en LMT/ASSM)
ALTER TABLESPACE users COALESCE;

-- compacter une table/partition (libère l'espace sous le HWM, rend à vue au tablespace)
ALTER TABLE umovie.movie SHRINK SPACE;              -- nécessite ROW MOVEMENT activé
ALTER TABLE umovie.movie ENABLE ROW MOVEMENT;
ALTER TABLE umovie.movie SHRINK SPACE COMPACT;      -- compacte sans relâcher l'espace (évite lock long)

-- réorganiser complètement (hors ligne ou online selon édition)
ALTER TABLE umovie.movie MOVE;                       -- déplace dans le même tablespace, recompacte
ALTER TABLE umovie.movie MOVE TABLESPACE new_ts;     -- + change de tablespace
-- après un MOVE, les index deviennent UNUSABLE -> à rebuild :
ALTER INDEX idx_movie_title REBUILD;
```

En 12c+ avec ASSM (Automatic Segment Space Management, par défaut sur les tablespaces
LMT), la fragmentation "classique" (chaînage d'extents libres) est beaucoup plus rare :
le vrai sujet devient surtout la **fragmentation logique** (lignes supprimées sous le HWM)
que `SHRINK`/`MOVE` résolvent.

---

## 6. Supervision des espaces disques et requêtes coûteuses

### 6.1 Espace disque / tablespaces

```sql
-- occupation par tablespace (taille, utilisé, libre, % used)
SELECT df.tablespace_name,
       ROUND(df.bytes/1024/1024)                         AS size_mb,
       ROUND((df.bytes - NVL(fs.bytes,0))/1024/1024)      AS used_mb,
       ROUND(NVL(fs.bytes,0)/1024/1024)                   AS free_mb,
       ROUND((1 - NVL(fs.bytes,0)/df.bytes)*100, 1)       AS pct_used
FROM (SELECT tablespace_name, SUM(bytes) bytes FROM dba_data_files GROUP BY tablespace_name) df
LEFT JOIN (SELECT tablespace_name, SUM(bytes) bytes FROM dba_free_space GROUP BY tablespace_name) fs
       ON df.tablespace_name = fs.tablespace_name
ORDER BY pct_used DESC;

-- vue "métier" toute prête (Oracle 12c+)
SELECT tablespace_name, used_percent, used_space, tablespace_size
FROM   dba_tablespace_usage_metrics;

-- fichiers de données et leur autoextend
SELECT file_name, tablespace_name, bytes/1024/1024 AS mb,
       autoextensible, maxbytes/1024/1024 AS max_mb
FROM   dba_data_files;

-- alertes seuils (générées par MMON si thresholds configurés)
SELECT * FROM dba_outstanding_alerts;
SELECT * FROM dba_thresholds WHERE warning_operator IS NOT NULL;
```

### 6.2 Requêtes coûteuses (temps réel / cache SQL)

```sql
-- top SQL par conso CPU / IO / elapsed, actuellement en cache
SELECT sql_id, child_number, executions, buffer_gets, disk_reads,
       round(elapsed_time/1e6,2) AS elapsed_sec,
       round(cpu_time/1e6,2)     AS cpu_sec,
       sql_text
FROM   v$sql
ORDER  BY elapsed_time DESC
FETCH FIRST 20 ROWS ONLY;

-- vue consolidée (toutes les exécutions cumulées d'un même sql_id)
SELECT sql_id, executions, buffer_gets, disk_reads, elapsed_time, sql_text
FROM   v$sqlarea
ORDER  BY buffer_gets DESC
FETCH FIRST 20 ROWS ONLY;

-- sessions actives en ce moment, ce qu'elles attendent (lock, I/O, CPU...)
SELECT sid, serial#, username, status, event, seconds_in_wait, sql_id
FROM   v$session
WHERE  status = 'ACTIVE' AND username IS NOT NULL;
```

### 6.3 Historique (AWR) — nécessite licence Diagnostics Pack

```sql
-- snapshots disponibles
SELECT snap_id, begin_interval_time, end_interval_time FROM dba_hist_snapshot ORDER BY snap_id DESC;

-- top SQL historique (au-delà du cache courant, purgé)
SELECT sql_id, plan_hash_value, executions_delta, elapsed_time_delta, buffer_gets_delta
FROM   dba_hist_sqlstat
WHERE  snap_id BETWEEN 100 AND 110
ORDER  BY elapsed_time_delta DESC;

-- rapport AWR texte (sur une plage de snapshots)
SELECT * FROM TABLE(DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_TEXT(
  l_dbid => (SELECT dbid FROM v$database), l_inst_num => 1,
  l_bid => 100, l_eid => 110));

-- ADDM : recommandations automatiques d'optimisation entre 2 snapshots
EXEC DBMS_ADVISOR.ANALYZE_DB(start_snap => 100, end_snap => 110, task_name => 'addm_run1');
SELECT DBMS_ADVISOR.GET_TASK_REPORT('addm_run1') FROM dual;
```

### 6.4 Statspack (alternative gratuite à AWR, pas besoin de Diagnostics Pack)

```sql
@?/rdbms/admin/spcreate.sql   -- installation
EXEC statspack.snap;          -- prise de snapshot
@?/rdbms/admin/spreport.sql   -- rapport entre deux snapshots
```

---

## 7. Checklist pratique "requête lente"

1. `EXPLAIN PLAN` / `DBMS_XPLAN.DISPLAY_CURSOR` → repérer `FULL TABLE SCAN` inattendu,
   cardinalités estimées très éloignées du réel (`Rows` vs `A-Rows`).
2. `DBA_TAB_STATISTICS.LAST_ANALYZED` / `STALE_STATS` → stats à jour ?
3. `DBA_TAB_MODIFICATIONS` → beaucoup de DML depuis la dernière collecte ?
4. Index adapté présent (`DBA_INDEXES` / `DBA_IND_COLUMNS`), pas `UNUSABLE`, pas trop
   fragmenté (`clustering_factor`, `index_stats`) ?
5. `v$sql` → `buffer_gets`/`disk_reads` par exécution anormalement hauts ?
6. Espace du tablespace sain (pas d'autoextend qui galère, pas de `MOVE`/`SHRINK` en attente) ?
7. Si besoin, `SQL Tuning Advisor` pour une recommandation automatisée.
