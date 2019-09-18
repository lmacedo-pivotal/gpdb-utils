select 
regexp_replace(table_name::text, '_1_prt_.*$'::text, ''::text) AS table_name,
count(*) - 1 as partition_count
from information_schema.tables
where table_schema = '<schema_name>'
group by 1
order by 2 desc
;
