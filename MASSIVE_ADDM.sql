-- This generates ADDM reports from all the nodes for the input start and end timings
-- Works for 10gR2
-- How to execute.
-- Save this script in ADDM_gen_script.sql
-- sql> @ADDM_gen_script.sql 20100915_1400 20100915_1500
-- Param 1 = start time YYYYMMDD_HH24MI format
-- Param 2 = end time YYYYMMDD_HH24MI format
--
-- All the ADDM reports ( one from each node ) will be created in output_dir variable. Defaults to c:\
-- This can be run from client or server. Just change the output_dir depending on OS. Window c:\ or Unix $HOME/
-- This create a temporary sql file ADDM_run_script.sql in the current directory

SET FEED OFF
SET VERIFY OFF
SET HEADING OFF
SET TERMOUT OFF
SET ECHO OFF
SET LINESIZE 32767
SET PAGES 0
SET WRAP OFF
SET SCAN ON
SET TRIM ON
SET TRIMS ON
SET TAB OFF
SET SERVEROUTPUT ON
SET PAUSE OFF
SET TIMING OFF

spool ADDM_run_script.sql
PROMPT SET FEED OFF
PROMPT SET VERIFY OFF
PROMPT SET HEADING OFF
PROMPT SET TERMOUT ON
PROMPT SET ECHO OFF
PROMPT SET LINESIZE 32767
PROMPT SET PAGES 0
PROMPT SET WRAP ON
PROMPT SET SCAN ON
PROMPT SET TRIM ON
PROMPT SET TRIMS ON
PROMPT SET TAB ON
PROMPT SET SERVEROUTPUT ON
PROMPT SET PAUSE ON
PROMPT SET TIMING OFF

DECLARE

-- output must end with a slash. CHANGE THIS IF NEEDED.
output_dir VARCHAR2(40) := '/tmp/run1/' ;

begin_time VARCHAR2(40);
end_time VARCHAR2(40);
snap_begin_time VARCHAR2(40);
snap_end_time VARCHAR2(40);
snap_begin_snap number;
snap_end_snap number;
snap_delta number:=1;
v_dbid number;
v_dbname varchar(20);
v_instance_number number;
v_instance_name varchar(20);

v_instance number;

tid number; -- Task ID
tname varchar2(100); -- Task Name
tdesc varchar2(500); -- Task Description

BEGIN

-- begin_time := '1';
-- end_time := '2';
-- DBMS_OUTPUT.PUT_LINE('-- Begin Time = ' || begin_time);
-- DBMS_OUTPUT.PUT_LINE('-- End Time = ' || end_time);
select dbid,name into v_dbid, v_dbname from v$database;
select instance_number, instance_name into v_instance_number, v_instance_name from gv$instance order by 1;

for x in ( select SNAP_ID snap_begin_snap, (SNAP_ID+snap_delta) snap_end_snap  from DBA_HIST_SNAPSHOT where DBID=v_dbid and SNAP_ID < (select max(SNAP_ID)-snap_delta-1 from DBA_HIST_SNAPSHOT ) /*and rownum < 11*/ order by 1 ) loop

-- Get the snap id for the input begin_time
SELECT to_char(max(end_interval_time),'YYYYMMDD_HH24MI') INTO snap_begin_time
FROM DBA_HIST_SNAPSHOT
where instance_number= v_instance_number
and SNAP_ID=x.snap_begin_snap;

-- Get the snap id for the input end_time
SELECT to_char(min(end_interval_time),'YYYYMMDD_HH24MI') INTO snap_end_time
FROM DBA_HIST_SNAPSHOT
where instance_number= v_instance_number
and SNAP_ID=x.snap_end_snap;

tname := 'ADDM:' || v_instance_name || '_' || x.snap_begin_snap || '_' || x.snap_end_snap;
tdesc := 'ADDM manual run: snapshots [' || x.snap_begin_snap || ',' || x.snap_end_snap || '], ' || v_instance_name;

DBMS_OUTPUT.PUT_LINE('DECLARE');
DBMS_OUTPUT.PUT_LINE(chr(9) || 'tid NUMBER; -- Task ID');
DBMS_OUTPUT.PUT_LINE(chr(9) || 'tname VARCHAR2(30); -- Task Name');
DBMS_OUTPUT.PUT_LINE(chr(9) || 'tdesc VARCHAR2(256); -- Task Description');

DBMS_OUTPUT.PUT_LINE('BEGIN');
DBMS_OUTPUT.PUT_LINE(chr(9) || 'tname := ''' || tname || ''' ;');
DBMS_OUTPUT.PUT_LINE(chr(9) || 'tdesc := ''' || tdesc || ''';');
DBMS_OUTPUT.PUT_LINE(chr(9) || 'DBMS_ADVISOR.CREATE_TASK( ''ADDM'', tid, tname, tdesc );');
DBMS_OUTPUT.PUT_LINE(chr(9) || 'DBMS_ADVISOR.SET_TASK_PARAMETER( tname, ''START_SNAPSHOT'',' || x.snap_begin_snap || ' );' );
DBMS_OUTPUT.PUT_LINE(chr(9) || 'DBMS_ADVISOR.SET_TASK_PARAMETER( tname, ''END_SNAPSHOT'' ,' || x.snap_end_snap || ' );');
DBMS_OUTPUT.PUT_LINE(chr(9) || 'dbms_advisor.set_task_parameter( tname, ''INSTANCE'',' || v_instance_number || ');');
DBMS_OUTPUT.PUT_LINE(chr(9) || 'dbms_advisor.set_task_parameter( tname, ''DB_ID'',' || v_dbid || ');');
DBMS_OUTPUT.PUT_LINE(chr(9) || 'DBMS_ADVISOR.EXECUTE_TASK( tname );');

DBMS_OUTPUT.PUT_LINE('END;');
DBMS_OUTPUT.PUT_LINE('/');

DBMS_OUTPUT.PUT_LINE('set long 1000000 pagesize 0 longchunksize 1000');
DBMS_OUTPUT.PUT_LINE('column get_clob format a80');
DBMS_OUTPUT.PUT_LINE('spool ' || output_dir || 'ADDM_' || v_instance_name ||'_'|| snap_begin_time ||'_to_' || snap_end_time ||'.txt' );
DBMS_OUTPUT.PUT_LINE('select dbms_advisor.get_task_report(''' || tname || ''', ''TEXT'', ''TYPICAL'') from sys.dual;');
DBMS_OUTPUT.PUT_LINE('spool off;');
DBMS_OUTPUT.PUT_LINE('exec DBMS_ADVISOR.DELETE_TASK('''|| tname ||''');');
DBMS_OUTPUT.PUT_LINE(chr(10));

end loop;

end;
/
spool off
@ADDM_run_script.sql
exit


/* USEFUL GREPS

 7563  24/10/19 16:38:46 cd /tmp/run1/
 7564  24/10/19 16:38:47 ls
 7565  24/10/19 16:38:58 ls -l | wc -l
 7566  24/10/19 16:39:11 grep "CPU was not a bottleneck for the instance." ADDM_BNTOIM2P_201910* | wc -l
 7567  24/10/19 16:39:20 more ADDM_BNTOIM2P_20191020_0100_to_20191020_0800.txt
 7568  24/10/19 16:39:50 grep 'Unusual "Application" Wait Event' ADDM_BNTOIM2P_201910* | wc -l
 7569  24/10/19 16:39:58 grep 'Unusual "Application" Wait Event' ADDM_BNTOIM2P_201910*
 7570  24/10/19 16:40:16 grep 'Finding 2: Unusual "Application" Wait Event' ADDM_BNTOIM2P_201910* | wc -l
 7571  24/10/19 16:40:28 more ADDM_BNTOIM2P_20191024_0700_to_20191024_1400.txt
 7572  24/10/19 16:40:58 grep 'SQL statement with SQL_ID "62jbb6xccf5cm"' ADDM_BNTOIM2P_201910*
 7573  24/10/19 16:41:07 grep 'SQL statement with SQL_ID "62jbb6xccf5cm"' ADDM_BNTOIM2P_201910* | wc -l
 7574  24/10/19 16:41:26 grep -h 'SQL statement with SQL_ID "62jbb6xccf5cm"' ADDM_BNTOIM2P_201910*
 7575  24/10/19 16:41:37 grep -h 'SQL statement with SQL_ID "62jbb6xccf5cm"' ADDM_BNTOIM2P_201910*  | sort | uniq
 7576  24/10/19 16:41:53 grep -h 'SQL statement with SQL_ID "62jbb6xccf5cm"' ADDM_BNTOIM2P_201910*  | sort | uniq | sort -k 8n
 7577  24/10/19 16:42:42 grep -A1 'SQL statement with SQL_ID "62jbb6xccf5cm"' ADDM_BNTOIM2P_201910*
 7578  24/10/19 16:42:55 grep -h -A1 'SQL statement with SQL_ID "62jbb6xccf5cm"' ADDM_BNTOIM2P_201910*
 7579  24/10/19 16:43:06 grep -h -A1 'SQL statement with SQL_ID "62jbb6xccf5cm"' ADDM_BNTOIM2P_201910* | grep elapsed
 7580  24/10/19 16:43:27 grep -h -A1 'SQL statement with SQL_ID "62jbb6xccf5cm"' ADDM_BNTOIM2P_201910* | grep elapsed | sort | uniq | sort -k 6n

*/
