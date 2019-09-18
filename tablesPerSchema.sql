select table_schema, count(*) 
from information_schema.tables
where table_schema not in ('gp_toolkit','infomation_schema','pg_catalog')
group by 1
order by 2 desc
;
