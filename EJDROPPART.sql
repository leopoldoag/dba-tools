CREATE OR REPLACE PROCEDURE ADMTPVS.SP_PARTICIONA IS

v_fecha              VARCHAR2(58);
v_table_name         VARCHAR2(50);
v_new_partition_name VARCHAR2(50);
v_old_partition_name VARCHAR2(50);
v_prefix_partition   VARCHAR2(10);
v_partition_exist    NUMBER;
v_highvalue          VARCHAR2(90);
v_partition_date     VARCHAR2(10);
v_depuration_date    VARCHAR2(10);

BEGIN
   -- Se debe generar una nueva particion y eliminar la particion mas antigua, considerando que siempre debe existir el mes actual y el anterior

   -- Prefijo de la particion
   v_prefix_partition := 'FEC_TRA';
   -- Nombre de la tabla a particionar
   v_table_name := 'AIPMPAPL';
   -- Nueva particion
   v_new_partition_name :=  v_prefix_partition || trim(TO_CHAR(TRUNC(SYSDATE),'mm'));
   -- Particion de 2 meses atras
   -- v_old_partition_name := v_prefix_partition || trim(TO_CHAR(ADD_MONTHS(SYSDATE,-2),'MM'));
   -- Se cambia el nombre de la particion
   SELECT partition_name into v_old_partition_name
   from all_tab_partitions where 1=1
   AND PARTITION_POSITION=1
   AND table_name=v_table_name;


   -- Se obtiene el primer dia del mes del mes actual + 1, para utilizarlo al crear la particion
   SELECT TO_CHAR(ADD_MONTHS(SYSDATE,1),'YYYY-MM-') || '01' INTO v_fecha FROM dual;

   -- Se consulta si existe la particion que se pretende borrar
   SELECT  count(partition_name) INTO v_partition_exist
   FROM    all_tab_partitions
   WHERE   table_name = v_table_name AND partition_name = v_old_partition_name;

   IF v_partition_exist<>0 THEN
      dbms_utility.exec_ddl_statement ('ALTER TABLE admtpvs.'||v_table_name||' DROP PARTITION '||v_old_partition_name||' UPDATE GLOBAL INDEXES');
      dbms_output.put_line('La particion ' || v_old_partition_name || ' ha sido borrada.');
   ELSE
      dbms_output.put_line('La particion ' || v_old_partition_name || ' no existe.');
   END IF;

   -- Se consulta si existe la particion que se pretende crear
   SELECT  count(partition_name) INTO v_partition_exist
   FROM    all_tab_partitions
   WHERE   table_name = v_table_name AND partition_name = v_new_partition_name;

   IF v_partition_exist<>0 THEN
      SELECT  HIGH_VALUE into v_highvalue
      FROM    all_tab_partitions
      WHERE   table_name = v_table_name AND partition_name = v_new_partition_name;

      v_partition_date := substr(v_highvalue,11,10);
      v_depuration_date := to_char(ADD_MONTHS(SYSDATE,-2), 'yyyy-mm-dd');
      -- Valida si la fecha de la particion es menor a la fecha del sistema - 2 meses
      IF v_partition_date < v_depuration_date THEN
         dbms_utility.exec_ddl_statement ('ALTER TABLE admtpvs.'||v_table_name||' DROP PARTITION '||v_new_partition_name||' UPDATE GLOBAL INDEXES');
         dbms_output.put_line('La particion ' || v_new_partition_name || ' (' || v_partition_date || ')' || ' ha sido borrada.');
         v_partition_exist := 0;
      ELSE
         dbms_output.put_line('La particion ' || v_new_partition_name || ' (' || v_partition_date || ')' || ' ya existe. No fue borrada porque es mas reciente a la fecha de depuracion (' || v_depuration_date || ').');

      END IF;
   END IF;

   IF v_partition_exist=0 THEN
      --dbms_utility.exec_ddl_statement ('ALTER TABLE admtpvs.'||v_table_name||' -
      --ADD PARTITION FEC_TRA'||trim(TO_CHAR(TRUNC(SYSDATE),'mm'))||' VALUES LESS THAN (TO_DATE('||''''||v_fecha||' 00:00:00'''||', ''YYYY-MM-DD HH24:MI:SS'',''NLS_CALENDAR=GREGORIAN'')) ');

      dbms_output.put_line('La particion ' || v_new_partition_name || ' (' || v_fecha || ')' || ' ha sido creada.');
   END IF;


EXCEPTION
  WHEN OTHERS THEN
  dbms_output.put_line('Error '||TO_CHAR(SQLCODE)||': '||SQLERRM);

END;
