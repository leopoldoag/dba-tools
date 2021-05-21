define SQLID = '&1'
define BS = '&2'
define ES = '&3'

exec DBMS_SQLTUNE.DROP_TUNING_TASK('sqltune_&&SQLID');

DECLARE
  v_tune_taskid  VARCHAR2(100);
BEGIN
  v_tune_taskid := dbms_sqltune.create_tuning_task (
                          sql_id      => '&&SQLID',
                          begin_snap  => '&&BS',
                          end_snap    => '&&ES',
                          scope       => dbms_sqltune.scope_comprehensive,
                          time_limit  => 1800,
                          task_name   => 'sqltune_&&SQLID',
                          description => 'Tuning task sql_id &&SQLID');
  dbms_output.put_line('taskid = ' || v_tune_taskid);
END;
/

exec dbms_sqltune.execute_tuning_task(task_name => 'sqltune_&&SQLID');

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

--  execute dbms_sqltune.accept_sql_profile(task_name =>'sqltune_1jg9u0bvk4d4s', task_owner => 'SYS', replace => TRUE,profile_type => DBMS_SQLTUNE.PX_PROFILE);
/*

backup_admin/sagmty290$

