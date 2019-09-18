select
n.nspname AS schema_name,
c.relname AS table_name,
CASE
  WHEN c.relstorage = 'a'::"char" THEN 'row append-only'::text
  WHEN c.relstorage = 'c'::"char" THEN 'column append-only'::text
  WHEN c.relstorage = 'h'::"char" THEN 'heap'::text
  WHEN c.relstorage = 'x'::"char" THEN 'external'::text
  ELSE NULL::text
END AS storage_type
FROM pg_class c
LEFT JOIN pg_namespace n
ON n.oid = c.relnamespace
where n.nspname in ('<schema>') --schema name
and c.relname like '%' --table name if needed
order by 1,2
;
