select
table_name,
count(*) num_col
from information_schema.columns
where table_schema = '<schema_name>'
and table_name not like '%_1_prt_%' 
group by 1
order by 2 desc
;

select
table_schema,
table_name,
count(*) num_col
from information_schema.columns
where table_name not like '%_1_prt_%' 
group by 1,2
order by 1,3 desc
;
