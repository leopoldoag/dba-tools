select distinct CLIENT_INFO from v$session

select nvl(CLIENT_INFO,'bgprocessess:LOCAL:ORCL' ), count(*) from v$session group by CLIENT_INFO;

------------------------------------------------------------------------------------------------------------------------------------------------

create table sesiones (fecha date default sysdate, CLIENT_INFO varchar2(100) not null, sesiones number not null);

create or replace procedure p_clientinfo_log
as
 begin
  insert into sesiones (CLIENT_INFO, sesiones) select nvl(CLIENT_INFO, OSUSER||':'||program||':'||MACHINE ) AS CLIENT_INFO, count(*) from v$session group by nvl(CLIENT_INFO, OSUSER||':'||program||':'||MACHINE );
  commit;
end;
/


BEGIN
  DBMS_SCHEDULER.CREATE_JOB
    (
       job_name        => 'JOB_CLIENTINFO_LOG'
      ,start_date      => SYSDATE
      ,repeat_interval => 'FREQ=MINUTELY;INTERVAL=5'
      ,end_date        => SYSDATE + 3
      ,job_class       => 'DEFAULT_JOB_CLASS'
      ,job_type        => 'STORED_PROCEDURE'
      ,job_action      => 'P_CLIENTINFO_LOG'
      ,comments        => NULL
    );
  DBMS_SCHEDULER.ENABLE(name                  => 'JOB_CLIENTINFO_LOG');
END;
/

set lines 200
select CLIENT_INFO, sum(sesiones) from sesiones /*where client_info like '%TELESOFT'*/ group by CLIENT_INFO order by sum(sesiones) asc;

set pages 20
set lines 200
col CLIENT_INFO for a60
select name from v$database;
select CLIENT_INFO, sum(sesiones) from sesiones where client_info not like 'oracle:oracle@%'
AND client_info not like 'oracle:LOCAL%' 
AND client_info not like 'rman%' 
AND client_info not like 'bgprocessess:LOCAL%' 
group by CLIENT_INFO order by sum(sesiones) asc;


--- FALTA PROBAR

BEGIN
  DBMS_SCHEDULER.SET_ATTRIBUTE (
   name         =>  'JOB_CLIENTINFO_LOG',
   attribute    =>  'start_date',
   value        =>  SYSDATE);
   DBMS_SCHEDULER.SET_ATTRIBUTE (
   name         =>  'JOB_CLIENTINFO_LOG',
   attribute    =>  'end_date',
   value        =>  SYSDATE + 1);
END;
/

