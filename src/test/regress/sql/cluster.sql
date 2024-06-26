--
--  CLUSTER
--

CREATE TABLE clstr_tst_s (rf_a SERIAL PRIMARY KEY,
	b INT) DISTRIBUTED BY (rf_a);

CREATE TABLE clstr_tst (a SERIAL PRIMARY KEY,
	b INT,
	c TEXT,
	d TEXT,
	CONSTRAINT clstr_tst_con FOREIGN KEY (b) REFERENCES clstr_tst_s)
	DISTRIBUTED BY (a);

CREATE INDEX clstr_tst_b ON clstr_tst (b);
CREATE INDEX clstr_tst_c ON clstr_tst (c);
CREATE INDEX clstr_tst_c_b ON clstr_tst (c,b);
CREATE INDEX clstr_tst_b_c ON clstr_tst (b,c);

INSERT INTO clstr_tst_s (b) VALUES (0);
INSERT INTO clstr_tst_s (b) SELECT b FROM clstr_tst_s;
INSERT INTO clstr_tst_s (b) SELECT b FROM clstr_tst_s;
INSERT INTO clstr_tst_s (b) SELECT b FROM clstr_tst_s;
INSERT INTO clstr_tst_s (b) SELECT b FROM clstr_tst_s;
INSERT INTO clstr_tst_s (b) SELECT b FROM clstr_tst_s;

CREATE TABLE clstr_tst_inh () INHERITS (clstr_tst);

INSERT INTO clstr_tst (b, c) VALUES (11, 'once');
INSERT INTO clstr_tst (b, c) VALUES (10, 'diez');
INSERT INTO clstr_tst (b, c) VALUES (31, 'treinta y uno');
INSERT INTO clstr_tst (b, c) VALUES (22, 'veintidos');
INSERT INTO clstr_tst (b, c) VALUES (3, 'tres');
INSERT INTO clstr_tst (b, c) VALUES (20, 'veinte');
INSERT INTO clstr_tst (b, c) VALUES (23, 'veintitres');
INSERT INTO clstr_tst (b, c) VALUES (21, 'veintiuno');
INSERT INTO clstr_tst (b, c) VALUES (4, 'cuatro');
INSERT INTO clstr_tst (b, c) VALUES (14, 'catorce');
INSERT INTO clstr_tst (b, c) VALUES (2, 'dos');
INSERT INTO clstr_tst (b, c) VALUES (18, 'dieciocho');
INSERT INTO clstr_tst (b, c) VALUES (27, 'veintisiete');
INSERT INTO clstr_tst (b, c) VALUES (25, 'veinticinco');
INSERT INTO clstr_tst (b, c) VALUES (13, 'trece');
INSERT INTO clstr_tst (b, c) VALUES (28, 'veintiocho');
INSERT INTO clstr_tst (b, c) VALUES (32, 'treinta y dos');
INSERT INTO clstr_tst (b, c) VALUES (5, 'cinco');
INSERT INTO clstr_tst (b, c) VALUES (29, 'veintinueve');
INSERT INTO clstr_tst (b, c) VALUES (1, 'uno');
INSERT INTO clstr_tst (b, c) VALUES (24, 'veinticuatro');
INSERT INTO clstr_tst (b, c) VALUES (30, 'treinta');
INSERT INTO clstr_tst (b, c) VALUES (12, 'doce');
INSERT INTO clstr_tst (b, c) VALUES (17, 'diecisiete');
INSERT INTO clstr_tst (b, c) VALUES (9, 'nueve');
INSERT INTO clstr_tst (b, c) VALUES (19, 'diecinueve');
INSERT INTO clstr_tst (b, c) VALUES (26, 'veintiseis');
INSERT INTO clstr_tst (b, c) VALUES (15, 'quince');
INSERT INTO clstr_tst (b, c) VALUES (7, 'siete');
INSERT INTO clstr_tst (b, c) VALUES (16, 'dieciseis');
INSERT INTO clstr_tst (b, c) VALUES (8, 'ocho');
-- This entry is needed to test that TOASTED values are copied correctly.
INSERT INTO clstr_tst (b, c, d) VALUES (6, 'seis', repeat('xyzzy', 100000));

CLUSTER clstr_tst_c ON clstr_tst;

SELECT a,b,c,substring(d for 30), length(d) from clstr_tst;
SELECT a,b,c,substring(d for 30), length(d) from clstr_tst ORDER BY a;
SELECT a,b,c,substring(d for 30), length(d) from clstr_tst ORDER BY b;
SELECT a,b,c,substring(d for 30), length(d) from clstr_tst ORDER BY c;

-- Verify that inheritance link still works
INSERT INTO clstr_tst_inh VALUES (0, 100, 'in child table');
SELECT a,b,c,substring(d for 30), length(d) from clstr_tst;

-- Verify that foreign key link still works
INSERT INTO clstr_tst (b, c) VALUES (1111, 'this should fail');

SELECT conname FROM pg_constraint WHERE conrelid = 'clstr_tst'::regclass
ORDER BY 1;


SELECT relname, relkind,
    EXISTS(SELECT 1 FROM pg_class WHERE oid = c.reltoastrelid) AS hastoast
FROM pg_class c WHERE relname LIKE 'clstr_tst%' ORDER BY relname;

-- Verify that indisclustered is correctly set
SELECT pg_class.relname FROM pg_index, pg_class, pg_class AS pg_class_2
WHERE pg_class.oid=indexrelid
	AND indrelid=pg_class_2.oid
	AND pg_class_2.relname = 'clstr_tst'
	AND indisclustered;

-- Try changing indisclustered
ALTER TABLE clstr_tst CLUSTER ON clstr_tst_b_c;
SELECT pg_class.relname FROM pg_index, pg_class, pg_class AS pg_class_2
WHERE pg_class.oid=indexrelid
	AND indrelid=pg_class_2.oid
	AND pg_class_2.relname = 'clstr_tst'
	AND indisclustered;

-- Try turning off all clustering
ALTER TABLE clstr_tst SET WITHOUT CLUSTER;
SELECT pg_class.relname FROM pg_index, pg_class, pg_class AS pg_class_2
WHERE pg_class.oid=indexrelid
	AND indrelid=pg_class_2.oid
	AND pg_class_2.relname = 'clstr_tst'
	AND indisclustered;

-- Verify that clustering all tables does in fact cluster the right ones
CREATE USER regress_clstr_user;
CREATE TABLE clstr_1 (a INT PRIMARY KEY);
CREATE TABLE clstr_2 (a INT PRIMARY KEY);
CREATE TABLE clstr_3 (a INT PRIMARY KEY);
ALTER TABLE clstr_1 OWNER TO regress_clstr_user;
ALTER TABLE clstr_3 OWNER TO regress_clstr_user;
GRANT SELECT ON clstr_2 TO regress_clstr_user;
INSERT INTO clstr_1 VALUES (2);
INSERT INTO clstr_1 VALUES (1);
INSERT INTO clstr_2 VALUES (2);
INSERT INTO clstr_2 VALUES (1);
INSERT INTO clstr_3 VALUES (2);
INSERT INTO clstr_3 VALUES (1);

-- "CLUSTER <tablename>" on a table that hasn't been clustered
CLUSTER clstr_2;

CLUSTER clstr_1_pkey ON clstr_1;
CLUSTER clstr_2 USING clstr_2_pkey;
SELECT * FROM clstr_1 UNION ALL
  SELECT * FROM clstr_2 UNION ALL
  SELECT * FROM clstr_3;

-- revert to the original state
DELETE FROM clstr_1;
DELETE FROM clstr_2;
DELETE FROM clstr_3;
INSERT INTO clstr_1 VALUES (2);
INSERT INTO clstr_1 VALUES (1);
INSERT INTO clstr_2 VALUES (2);
INSERT INTO clstr_2 VALUES (1);
INSERT INTO clstr_3 VALUES (2);
INSERT INTO clstr_3 VALUES (1);

-- this user can only cluster clstr_1 and clstr_3, but the latter
-- has not been clustered
SET SESSION AUTHORIZATION regress_clstr_user;
CLUSTER;
SELECT * FROM clstr_1 UNION ALL
  SELECT * FROM clstr_2 UNION ALL
  SELECT * FROM clstr_3;

-- cluster a single table using the indisclustered bit previously set
DELETE FROM clstr_1;
INSERT INTO clstr_1 VALUES (2);
INSERT INTO clstr_1 VALUES (1);
CLUSTER clstr_1;
SELECT * FROM clstr_1;

-- Test MVCC-safety of cluster. There isn't much we can do to verify the
-- results with a single backend...

CREATE TABLE clustertest (key int, distkey int) DISTRIBUTED BY (distkey);
CREATE INDEX clustertest_pkey ON clustertest (key);

INSERT INTO clustertest VALUES (10, 1);
INSERT INTO clustertest VALUES (20, 2);
INSERT INTO clustertest VALUES (30, 1);
INSERT INTO clustertest VALUES (40, 2);
INSERT INTO clustertest VALUES (50, 3);

-- Use a transaction so that updates are not committed when CLUSTER sees 'em
BEGIN;

-- Test update where the old row version is found first in the scan
UPDATE clustertest SET key = 100 WHERE key = 10;

-- Test update where the new row version is found first in the scan
UPDATE clustertest SET key = 35 WHERE key = 40;

-- Test longer update chain
UPDATE clustertest SET key = 60 WHERE key = 50;
UPDATE clustertest SET key = 70 WHERE key = 60;
UPDATE clustertest SET key = 80 WHERE key = 70;

SELECT key FROM clustertest;
CLUSTER clustertest_pkey ON clustertest;
SELECT key FROM clustertest;

COMMIT;

SELECT key FROM clustertest;

-- check that temp tables can be clustered
create temp table clstr_temp (col1 int primary key, col2 text);
insert into clstr_temp values (2, 'two'), (1, 'one');
cluster clstr_temp using clstr_temp_pkey;
select * from clstr_temp;
drop table clstr_temp;

RESET SESSION AUTHORIZATION;

-- check clustering an empty table
DROP TABLE clustertest;
CREATE TABLE clustertest (f1 int PRIMARY KEY);
CLUSTER clustertest USING clustertest_pkey;
CLUSTER clustertest;

-- Check that partitioned tables cannot be clustered
CREATE TABLE clstrpart (a int) PARTITION BY RANGE (a);
CREATE INDEX clstrpart_idx ON clstrpart (a);
ALTER TABLE clstrpart CLUSTER ON clstrpart_idx;
CLUSTER clstrpart USING clstrpart_idx;
DROP TABLE clstrpart;

-- Test CLUSTER with external tuplesorting

-- The tests assume that the rows come out in the physical order, as
-- sorted by CLUSTER. In GPDB, add a dummy column to force all the rows to go
-- to the same segment, otherwise the rows come out in random order from the
-- segments.
create table clstr_4 as select 1 as dummy, * from tenk1 distributed by (dummy);
create index cluster_sort on clstr_4 (hundred, thousand, tenthous);
-- ensure we don't use the index in CLUSTER nor the checking SELECTs
set enable_indexscan = off;

-- Use external sort:
set maintenance_work_mem = '1MB';
cluster clstr_4 using cluster_sort;
select * from
(select hundred, lag(hundred) over () as lhundred,
        thousand, lag(thousand) over () as lthousand,
        tenthous, lag(tenthous) over () as ltenthous from clstr_4) ss
where row(hundred, thousand, tenthous) <= row(lhundred, lthousand, ltenthous);

reset enable_indexscan;
reset maintenance_work_mem;

-- test CLUSTER on expression index
CREATE TABLE clstr_expression(id serial primary key, a int, b text COLLATE "C");
INSERT INTO clstr_expression(a, b) SELECT g.i % 42, 'prefix'||g.i FROM generate_series(1, 133) g(i);
CREATE INDEX clstr_expression_minus_a ON clstr_expression ((-a), b);
CREATE INDEX clstr_expression_upper_b ON clstr_expression ((upper(b)));

-- enable to keep same plan with pg
SET gp_enable_relsize_collection= on;

-- verify indexes work before cluster
BEGIN;
SET LOCAL enable_seqscan = false;
EXPLAIN (COSTS OFF) SELECT * FROM clstr_expression WHERE upper(b) = 'PREFIX3';
SELECT * FROM clstr_expression WHERE upper(b) = 'PREFIX3';
EXPLAIN (COSTS OFF) SELECT * FROM clstr_expression WHERE -a = -3 ORDER BY -a, b;
SELECT * FROM clstr_expression WHERE -a = -3 ORDER BY -a, b;
COMMIT;

-- and after clustering on clstr_expression_minus_a
CLUSTER clstr_expression USING clstr_expression_minus_a;
WITH rows AS
  (SELECT ctid, lag(a) OVER (PARTITION BY gp_segment_id ORDER BY ctid) AS la, a FROM clstr_expression)
SELECT * FROM rows WHERE la < a;
BEGIN;
SET LOCAL enable_seqscan = false;
EXPLAIN (COSTS OFF) SELECT * FROM clstr_expression WHERE upper(b) = 'PREFIX3';
SELECT * FROM clstr_expression WHERE upper(b) = 'PREFIX3';
EXPLAIN (COSTS OFF) SELECT * FROM clstr_expression WHERE -a = -3 ORDER BY -a, b;
SELECT * FROM clstr_expression WHERE -a = -3 ORDER BY -a, b;
COMMIT;

-- and after clustering on clstr_expression_upper_b
CLUSTER clstr_expression USING clstr_expression_upper_b;
WITH rows AS
  (SELECT ctid, lag(b) OVER (PARTITION BY gp_segment_id ORDER BY ctid) AS lb, b FROM clstr_expression)
SELECT * FROM rows WHERE upper(lb) > upper(b);
BEGIN;
SET LOCAL enable_seqscan = false;
EXPLAIN (COSTS OFF) SELECT * FROM clstr_expression WHERE upper(b) = 'PREFIX3';
SELECT * FROM clstr_expression WHERE upper(b) = 'PREFIX3';
EXPLAIN (COSTS OFF) SELECT * FROM clstr_expression WHERE -a = -3 ORDER BY -a, b;
SELECT * FROM clstr_expression WHERE -a = -3 ORDER BY -a, b;
COMMIT;

-- clean up
SET gp_enable_relsize_collection= off;
DROP TABLE clustertest;
DROP TABLE clstr_1;
DROP TABLE clstr_2;
DROP TABLE clstr_3;
DROP TABLE clstr_4;
DROP TABLE clstr_expression;

DROP USER regress_clstr_user;

-- Test transactional safety of CLUSTER against heap
CREATE TABLE foo (a int, b varchar, c int) DISTRIBUTED BY (a);
INSERT INTO foo SELECT i, 'initial insert' || i, i FROM generate_series(1,10000)i;
CREATE index ifoo on foo using btree (b);
-- execute cluster in a transaction but don't commit the transaction
BEGIN;
CLUSTER foo USING ifoo;
ABORT;
-- try cluster again
CLUSTER foo USING ifoo;
DROP TABLE foo;
