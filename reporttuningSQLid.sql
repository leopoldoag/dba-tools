define SQLID = '&1'

select task_name, status
from dba_advisor_log
where task_name = 'sqltune_&&SQLID';

set long 10000000;
set longc 10000000;
set pagesize 1000
set linesize 220
set pagesize 500
select dbms_sqltune.report_tuning_task('sqltune_&&SQLID') as output
from dual;
