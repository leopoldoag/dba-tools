dbca -silent -createDatabase -templateName General_Purpose.dbc -gdbname dbase -sid dbase -responseFile NO_VALUE -characterSet AL32UTF8 -memoryPercentage 20 -emConfiguration NONE

dbca -silent -createDatabase -templateName General_Purpose.dbc -gdbName ORCL.banorte.com -sid ORCL -sysPassword 0r4cl3#1 -systemPassword 0r4cl3#1 \
-emConfiguration NONE -datafileDestination /dprod01/oradata -storageType FS -characterSet AL32UTF8 -memoryPercentage 10 -sampleSchema true

dbca -silent -deleteDatabase -sourceDB ORCL

/herramientas/oracle/product/112/assistants/dbca/dbca.rsp




select object_Name, OBJECT_TYPE from user_objects where CREATED > sysdate - .3/24;

select 'drop '||OBJECT_TYPE||' '||object_Name||';' from user_objects where CREATED > sysdate - .3/24;
