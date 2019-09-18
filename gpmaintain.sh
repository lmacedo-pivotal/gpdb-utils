#!/bin/bash
set -e

logfile="$1"
if [ "$logfile" == "" ]; then
	echo "ERROR: Please provide the logfile to save logs"
	exit 1
fi
start_maintain()
{
	now=$(date +"%Y-%m-%d %H:%M:%S.%s")
	echo "Maintain Start: $now" > $logfile
	current_date=$(date +%Y%m%d)
}
end_maintain()
{
	now=$(date +"%Y-%m-%d %H:%M:%S.%s")
	echo "Maintain End: $now" >> $logfile
}
log_start()
{
	T="$(date +%s%N)"
}
log_end()
{
	#duration
	T="$(($(date +%s%N)-T))"
	# seconds
	S="$((T/1000000000))"
	# milliseconds
	M="$((T/1000000))"

	printf "$current_date|$db|$step|%02d:%02d:%02d.%03d\n" "$((S/3600%24))" "$((S/60%60))" "$((S%60))" "${M}"
}
vacuum_analyze_catalog()
{
	step="vacuum_analyze_catalog"
	echo "VACUUM ANALYZE pg_catalog" >> $logfile
	log_start
	psql -d $db -t -A -c "SELECT 'VACUUM ANALYZE \"' || n.nspname || '\".\"' || c.relname || '\";' FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid WHERE n.nspname = 'pg_catalog' AND c.relkind = 'r'" | psql -d $db -e >> $logfile 2>&1
	log_end
}
reindex_catalog()
{
	step="reindex_catalog"
	echo "** REINDEX the pg_catalog" >> $logfile 2>&1
	log_start
	psql -d $db -c "REINDEX SYSTEM \"$db\"" >> $logfile 2>&1
	log_end
}
vacuum_near_freeze_age()
{
	step="vacuum_near_freeze_age"
	echo "** VACUUM all tables near the vacuum_freeze_min_age to prevent transaction wraparound" >> $logfile
	log_start
	vacuum_freeze_min_age=$(psql -d $db -t -A -c "show vacuum_freeze_min_age;")
	psql -d $db -t -A -c "SELECT 'VACUUM \"' || n.nspname || '\".\"' || c.relname || '\";' FROM pg_class c join pg_namespace n ON c.relnamespace = n.oid WHERE age(relfrozenxid) > $vacuum_freeze_min_age AND c.relkind = 'r' AND c.relstorage <> 'x'" | psql -d $db -e >> $logfile 2>&1
	log_end
}
vacuum_heap_with_bloat()
{
	step="vacuum_heap_with_bloat"
	echo "** VACUUM all heap tables with bloat" >> $logfile
	log_start
	psql -d $db -t -A -c "SELECT 'VACUUM \"' || bdinspname || '\".\"' || bdirelname || '\";' FROM gp_toolkit.gp_bloat_diag WHERE bdinspname <> 'pg_catalog'" | psql -d $db -e >> $logfile 2>&1
	log_end
}
vacuum_ao_with_bloat()
{
	step="vacuum_ao_with_bloat"
	echo "** VACUUM all append optimized tables with bloat" >> $logfile
	log_start
	psql -d $db -t -A -c "SELECT 'VACUUM ANALYZE \"' || schema_name || '\".\"' || table_name || '\";'
	FROM    (
		SELECT n.nspname AS schema_name, c.relname AS table_name, c.reltuples AS num_rows, (gp_toolkit.__gp_aovisimap_hidden_info(c.oid)).total_tupcount AS ao_num_rows
		FROM pg_appendonly a
		JOIN pg_class c ON c.oid = a.relid
		JOIN pg_namespace n ON c.relnamespace = n.oid
		WHERE c.relkind = 'r' 
		AND c.reltuples > 0
		) AS sub
	GROUP BY schema_name, table_name, num_rows
	HAVING sum(ao_num_rows) > num_rows * 1.05" | psql -d $db -e >> $logfile 2>&1
	log_end
}
analyze_db()
{
	step="analyze_db"
	echo "** ANALYZE user tables with analyzedb" >> $logfile
	log_start
	echo "analyzedb -d $db -a" >> $logfile
	analyzedb -d $db -a >> $logfile 2>&1
	log_end
}

start_maintain

for db in $(psql -d postgres -t -A -c "SELECT datname FROM pg_database WHERE datname NOT IN ('postgres', 'template0', 'template1') ORDER BY datname"); do
	echo "** MAINTAIN database $db" >> $logfile
	vacuum_analyze_catalog
	reindex_catalog
	vacuum_near_freeze_age
	vacuum_heap_with_bloat
	vacuum_ao_with_bloat
	analyze_db
done

end_maintain
