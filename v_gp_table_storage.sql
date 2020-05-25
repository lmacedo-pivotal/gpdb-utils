DROP VIEW public.v_gp_table_storage CASCADE;

CREATE OR REPLACE VIEW public.v_gp_table_storage AS
 SELECT
 current_timestamp AS tms,
 n.nspname AS schema_name,
 c.relname AS table_name,
        CASE
            WHEN c.relstorage = 'a'::"char" THEN 'row append-only'::text
            WHEN c.relstorage = 'c'::"char" THEN 'column append-only'::text
            WHEN c.relstorage = 'h'::"char" THEN 'heap'::text
            WHEN c.relstorage = 'x'::"char" THEN 'external'::text
            ELSE NULL::text
        END AS storage_type,
              a.compresstype  AS compr_type,
              a.compresslevel AS compr_level,
              sotailtablesizedisk                                   as tabind_sz,
              (sotailtablesizedisk         / 1024^3)::numeric(20,2) as tabind_sz_gb,
              (sotailtablesizeuncompressed / 1024^3)::numeric(20,2) as tabind_sz_unc_gb,
              case WHEN coalesce(sotailtablesizedisk,0)=0 THEN -1 ELSE (sotailtablesizeuncompressed/sotailtablesizedisk)::numeric(6,1) END as compr_ratio
              , c.relhassubclass as is_partitioned
   FROM pg_class c
   LEFT JOIN pg_appendonly a ON c.oid = a.relid
   LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
   LEFT JOIN gp_toolkit.gp_size_of_table_and_indexes_licensing sot ON sot.sotailoid = c.oid
  WHERE (n.nspname <> ALL (ARRAY['information_schema'::name, 'pg_catalog'::name, 'pg_toast'::name, 'gp_toolkit'::name])) AND c.relkind = 'r'::"char"
;
