--column Grant PII protection demo with join

create schema piidemo;

--Events of a customer
create table piidemo.cust_table (
ID_CUST_PII integer,
ID_CUST_NOPII integer,
AT_DATA_PII varchar(30),
AT_DATA_NOPII varchar(30)
);

insert into piidemo.cust_table values (1,10,'aaa','AAA');
insert into piidemo.cust_table values (2,20,'bbb','BBB');
insert into piidemo.cust_table values (3,30,'ccc','CCC');

select * from piidemo.cust_table ;

--Details from a customer
create table piidemo.cust_detail_table (
ID_CUST_PII integer,
ID_CUST_DETAIL_NOPII integer,
AT_CUST_DETAIL_PII varchar(30),
AT_CUST_DETAIL_NOPII varchar(30)
);

insert into piidemo.cust_detail_table values (1,9,'xxx','XXX');
insert into piidemo.cust_detail_table values (2,99,'yyy','YYY');
insert into piidemo.cust_detail_table values (3,999,'zzz','ZZZ');

select * from piidemo.cust_detail_table;

--View with join
create view piidemo.v_join_info as
select
f.ID_CUST_NOPII,
d.ID_CUST_DETAIL_NOPII,
f.AT_DATA_NOPII,
d.AT_CUST_DETAIL_NOPII
from piidemo.cust_table f join piidemo.cust_detail_table d
on f.ID_CUST_PII = d.ID_CUST_PII
;


-- grant select on no pii data to user test
grant usage on schema piidemo to test;

grant select 
(
ID_CUST_NOPII,
AT_DATA_NOPII 
)
on piidemo.cust_table to test;

grant select 
(
ID_CUST_DETAIL_NOPII,
AT_CUST_DETAIL_NOPII 
)
on piidemo.cust_detail_table to test;

grant select on piidemo.v_join_info to test;

-- pii column grant demo queries - log with test user

select 
ID_CUST_NOPII,
AT_DATA_NOPII 
from piidemo.cust_table; 

select 
ID_CUST_PII,
AT_DATA_PII 
from piidemo.cust_table; 


select
ID_CUST_DETAIL_NOPII,
AT_CUST_DETAIL_NOPII 
from piidemo.cust_detail_table;

select
ID_CUST_DETAIL_PII,
AT_CUST_DETAIL_PII 
from piidemo.cust_detail_table;


select 
*
from piidemo.v_join_info;


-- clean environment

--drop schema if exists piidemo cascade;
