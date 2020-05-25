--Requires the View: v_gp_table_storage.sql

CREATE OR REPLACE VIEW public.v_gp_table_storage_summary AS
 SELECT tms,
        schema_name,
        regexp_replace(table_name::text, '_1_prt_.*$'::text, ''::text) AS table_name,
        storage_type,
        compr_type,
        compr_level,
        count(*)                            AS nr_of_partitions,
        sum(tabind_sz)                      AS tabind_size,
        sum(tabind_sz_gb)                   AS tabind_sz_gb,
        sum(tabind_sz_unc_gb)               AS tabind_sz_unc_gb--,
  --      round(avg(  )::numeric, 2)          AS avg_compr_ratio -- create new logic
   FROM public.v_gp_table_storage
  WHERE storage_type <> 'external'::text AND table_name !~~ 'err_%'::text AND not is_partitioned
  GROUP BY tms, schema_name, regexp_replace(table_name::text, '_1_prt_.*$'::text, ''::text), storage_type, compr_type, compr_level
;
