
expdp DIRECTORY=CALLCE_P_DIR DUMPFILE=TELESOFT-TS_CONTACTO-%U.dmp LOGFILE=eTELESOFT-TS_CONTACTO.log TABLES=TELESOFT.TS_CONTACTO PARALLEL=8 
impdp DIRECTORY=CALLCE_P_DIR DUMPFILE=TELESOFT-TS_CONTACTO-%U.dmp LOGFILE=iTELESOFT-TS_CONTACTO.log PARALLEL=8 REMAP_TABLESPACE=TS_INDX:TS1_DATA EXCLUDE=GRANT
impdp DIRECTORY=CALLCE_P_DIR DUMPFILE=TELESOFT-TS_CONTACTO-%U.dmp LOGFILE=iTELESOFT-TS_CONTACTO-PART.log PARALLEL=8 REMAP_TABLESPACE=TS_INDX:TS1_DATA EXCLUDE=GRANT,INDEX,TRIGGER,CONSTRAINT TABLE_EXISTS_ACTION=APPEND \
REMAP_TABLE=TELESOFT.TS_CONTACTO:TS_CONTACTO_INTERMIN


CREATE TABLE TELESOFT.TS_CONTACTO
(
  CONTACTO      NUMBER(10)                      DEFAULT 0                     NOT NULL,
  EMPRESA       CHAR(5 BYTE)                    DEFAULT ' '                   NOT NULL,
  TIPODOC       CHAR(3 BYTE)                    DEFAULT ' '                   NOT NULL,
  NRODOC        CHAR(15 BYTE)                   DEFAULT ' '                   NOT NULL,
  FECALTA       DATE,
  APELLIDO      CHAR(50 BYTE)                   DEFAULT ' '                   NOT NULL,
  NOMBRE        CHAR(40 BYTE)                   DEFAULT ' '                   NOT NULL,
  SEXO          CHAR(1 BYTE)                    DEFAULT ' '                   NOT NULL,
  MEDIO         NUMBER(3)                       DEFAULT 0                     NOT NULL,
  USUARIO       CHAR(8 BYTE)                    DEFAULT ' '                   NOT NULL,
  CAPTURADO     DATE,
  USUCAPTURADO  CHAR(8 BYTE)                    DEFAULT ' '                   NOT NULL,
  PERSONA       CHAR(1 BYTE)                    DEFAULT ' '                   NOT NULL,
  ULTOPERACION  NUMBER(10)                      DEFAULT 0                     NOT NULL,
  IDCLIENTE     CHAR(20 BYTE)                   DEFAULT ' '                   NOT NULL,
  BAJA          CHAR(1 BYTE)                    DEFAULT ' '                   NOT NULL,
  TIPOCLIENTE   VARCHAR2(3 BYTE)                DEFAULT ' '                   NOT NULL,
  CANAL         NUMBER(3)                       DEFAULT 0                     NOT NULL,
  USUULTACT     CHAR(8 BYTE)                    DEFAULT ' '                   NOT NULL,
  FECULTACT     DATE
)
PARTITION BY RANGE(CONTACTO) (
  partition p0 values less than (1000000)     TABLESPACE TS1_DATA, 
  partition p1 values less than (2000000)     TABLESPACE TS1_DATA,
  partition p2 values less than (3000000)     TABLESPACE TS1_DATA,
  partition p3 values less than (4000000)     TABLESPACE TS1_DATA,
  partition p4 values less than (5000000)     TABLESPACE TS1_DATA,
  partition p5 values less than (6000000)     TABLESPACE TS1_DATA,
  partition p6 values less than (7000000)     TABLESPACE TS1_DATA,
  partition p7 values less than (8000000)     TABLESPACE TS1_DATA,
  partition p8 values less than (9000000)     TABLESPACE TS1_DATA,
  partition p9 values less than (10000000)     TABLESPACE TS1_DATA,
  partition p10 values less than (11000000)     TABLESPACE TS1_DATA,
  partition p11 values less than (12000000)     TABLESPACE TS1_DATA,
  partition p12 values less than (13000000)     TABLESPACE TS1_DATA,
  partition p13 values less than (14000000)     TABLESPACE TS1_DATA,
  partition p14 values less than (15000000)     TABLESPACE TS1_DATA,
  partition p15 values less than (16000000)     TABLESPACE TS1_DATA,
  partition p16 values less than (17000000)     TABLESPACE TS1_DATA,
  partition p17 values less than (18000000)     TABLESPACE TS1_DATA,
  partition p18 values less than (19000000)     TABLESPACE TS1_DATA,
  partition p19 values less than (20000000)     TABLESPACE TS1_DATA,
  partition p values less than (MAXVALUE) tablespace TS1_DATA
)
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOLOGGING 
NOCOMPRESS 
NOCACHE
MONITORING
ENABLE ROW MOVEMENT;

alter session force parallel ddl;

CREATE INDEX TELESOFT.IDX$$_621CA0001 ON TELESOFT.TS_CONTACTO (UPPER("APELLIDO")) LOCAL;

CREATE INDEX TELESOFT.XAKCONTAC_APELLIDO ON TELESOFT.TS_CONTACTO  (APELLIDO, NOMBRE) LOCAL;

CREATE INDEX TELESOFT.XAKCONTAC_CAPTURADO ON TELESOFT.TS_CONTACTO (CAPTURADO) LOCAL;

CREATE INDEX TELESOFT.XAKCONTAC_IDCLIENTE ON TELESOFT.TS_CONTACTO (IDCLIENTE) LOCAL;

CREATE INDEX TELESOFT.XIFCONTAC_CANAL ON TELESOFT.TS_CONTACTO (CANAL) LOCAL;

CREATE INDEX TELESOFT.XIFCONTAC_EMPRESA ON TELESOFT.TS_CONTACTO  (EMPRESA) LOCAL;

CREATE INDEX TELESOFT.XIFCONTAC_TIPOCLIENTE ON TELESOFT.TS_CONTACTO  (TIPOCLIENTE) LOCAL;

CREATE INDEX TELESOFT.XIFCONTAC_USUULTACT ON TELESOFT.TS_CONTACTO (USUULTACT) LOCAL;

CREATE UNIQUE INDEX TELESOFT.XPKCONTACTO ON TELESOFT.TS_CONTACTO (CONTACTO) LOCAL;

CREATE OR REPLACE TRIGGER TELESOFT.TRD_CONTACTO 
/*
Objetivo..............:	Grabacion en TS_LogContacto
Entrada ..............:
Salida................:
Fecha.................:	30/07/2002
Autor.................: Claudia
Fecha Modif...........: 22/12/2004
Autor Modif...........: clongo
Modif.................: Se cambio NroDocNue a char manteniendose la compatibilidad con versiones anteriores que sigue siendo Decimal

Fecha Modif...........: 26/05/2005
Autor Modif...........: DBalseiro
Modif.................: Se agrega la empresa al SP

Fecha Modif..: 07-MAY-2008 	  11:08
Autor Modif..: Egatabria
Modificaci Se Agrega el parametro sUsuUltAct al sp Sp_Grabalogcontacto
Planilla.....: SE_9995_PT_ERS_90000_Egatabria_C.xls
*/
AFTER DELETE ON TELESOFT.TS_CONTACTO
FOR EACH ROW
DECLARE
sAccion	 CHAR(1);
sTipoDatoDocumento CHAR(1);
sNroDocNue CHAR(1);

BEGIN


	-- Accion BAJA
	sAccion := 'B';

	-- Obtengo el tipo de dato del campo NroDoc
	BEGIN
		SELECT Valor INTO sTipoDatoDocumento FROM Tbl_Parametro WHERE Parametro = 'TIPODATODOCUMENTO';
	EXCEPTION WHEN NO_DATA_FOUND THEN
		sTipoDatoDocumento := 'N';
	END;

	IF sTipoDatoDocumento = 'N' THEN
		sNroDocNue := '0';
	ELSE
		sNroDocNue := ' ';
	END IF;

	-- Grabo en la tabla de Log
	Sp_GrabalogContacto  (:OLD.Contacto,
			:OLD.IdCliente,
			sAccion,
			:OLD.TipoDoc,
			:OLD.NroDoc,
			:OLD.Apellido,
			:OLD.Nombre,
			:OLD.Persona,
			:OLD.Sexo,
			:OLD.TipoCliente,
			:OLD.IdCliente,
			:OLD.Empresa,
		      ' ', 	--TipoDocNue,
			sNroDocNue,	--NroDocNue,
			' ', 	--ApellidoNue,
			' ', 	--NombreNue,
			' ', 	--PersonaNue,
			' ', 	--SexoNue,
			' ', 	--TipoClienteNue,
			' ',	--EmpresaNue
			:OLD.UsuCapturado --sUsuUltAct
		);


END;
/


CREATE OR REPLACE TRIGGER TELESOFT.TRI_CONTACTO 
/*
Objetivo..............:	Grabacion en TS_LogContacto
Entrada ..............:
Salida................:
Fecha.................:	30/07/2002
Autor.................: Claudia
Fecha Modif...........: 22/12/2204
Autor Modif...........: Clongo
Modif.................: Se cambio NroDocAnt a char manteniendose la compatibilidad con versiones anteriores que sigue siendo Decimal

Fecha Modif...........: 26/05/2005
Autor Modif...........: DBalseiro
Modif.................: Se agrega el parametro Empresa al SP

Fecha Modif..: 07-MAY-2008 10	  10:59
Autor Modif..: Egatabria
Modificaci Se Agrega el parametro sUsuUltAct al sp Sp_Grabalogcontacto
Planilla.....: SE_9995_PT_ERS_90000_Egatabria_C.xls
*/
AFTER INSERT ON TELESOFT.TS_CONTACTO
FOR EACH ROW
DECLARE
sAccion	 CHAR(1);
sTipoDatoDocumento CHAR(1);
sNroDocAnt CHAR(1);
BEGIN
	-- Accion ALTA
	sAccion := 'A';
	-- Obtengo el tipo de dato del campo NroDoc
	BEGIN
		SELECT Valor INTO sTipoDatoDocumento FROM TBL_PARAMETRO WHERE Parametro = 'TIPODATODOCUMENTO';
	EXCEPTION WHEN NO_DATA_FOUND THEN
		sTipoDatoDocumento := 'N';
	END;
	IF sTipoDatoDocumento = 'N' THEN
		sNroDocAnt := '0';
	ELSE
		sNroDocAnt := ' ';
	END IF;
	-- Grabo en la tabla de Log
	Sp_Grabalogcontacto  (:NEW.Contacto,
			:NEW.IdCliente,
			sAccion,
		      ' ', 	--TipoDocAnt,
			sNroDocAnt,	--NroDocAnt,
			' ', 	--ApellidoAnt,
			' ', 	--NombreAnt,
			' ', 	--PersonaAnt,
			' ', 	--SexoAnt,
			' ', 	--TipoClienteAnt,
			' ', 	--IdClienteAnt,
			' ',	--EmpresaAnt
			:NEW.TipoDoc,
			:NEW.NroDoc,
			:NEW.Apellido,
			:NEW.Nombre,
			:NEW.Persona,
			:NEW.Sexo,
			:NEW.TipoCliente,
			:NEW.Empresa,
			:NEW.UsuUltAct);
END;
/


CREATE OR REPLACE TRIGGER TELESOFT.TRU_CONTACTO 
/*
Objetivo..............:	Grabacion en TS_LogContacto
Entrada ..............:
Salida................:
Fecha.................:	30/07/2002
Autor.................: Claudia

Fecha Modif...........: 26/05/2005
Autor Modif...........: DBalseiro
Modif.................: Se agrega el parametro empresa al SP

Fecha Modif..: 07-MAY-2008 10	  10:59
Autor Modif..: Egatabria
Modificaci Se Agrega el parametro sUsuUltAct al sp Sp_Grabalogcontacto
Planilla.....: SE_9995_PT_ERS_90000_Egatabria_C.xls
*/
AFTER UPDATE ON TELESOFT.TS_CONTACTO
FOR EACH ROW
DECLARE
sAccion	 CHAR(1);

BEGIN

	-- Accion MODIFICACION
	sAccion := 'M';

	-- verifico si cambio algun dato
	IF :OLD.IdCliente <> :NEW.IdCliente
		OR :OLD.TipoDoc <> :NEW.TipoDoc
		OR :OLD.NroDoc <> :NEW.NroDoc
		OR LTRIM(RTRIM(:OLD.Apellido)) <> LTRIM(RTRIM(:NEW.Apellido))
		OR LTRIM(RTRIM(:OLD.Nombre)) <> LTRIM(RTRIM(:NEW.Nombre))
		OR :OLD.Persona <> :NEW.Persona
		OR :OLD.Sexo <> :NEW.Sexo
		OR :OLD.TipoCliente <> :NEW.TipoCliente
		OR :OLD.Empresa <> :NEW.Empresa
	THEN
		-- Grabo en la tabla de Log
		Sp_Grabalogcontacto  (:NEW.Contacto,
			:NEW.IdCliente,
			sAccion,
			:OLD.TipoDoc,
			:OLD.NroDoc,
			:OLD.Apellido,
			:OLD.Nombre,
			:OLD.Persona,
			:OLD.Sexo,
			:OLD.TipoCliente,
			:OLD.IdCliente,
			:OLD.Empresa,
			:NEW.TipoDoc,
			:NEW.NroDoc,
			:NEW.Apellido,
			:NEW.Nombre,
			:NEW.Persona,
			:NEW.Sexo,
			:NEW.TipoCliente,
			:NEW.Empresa,
			:NEW.UsuUltAct
			);
	END IF;

END;
/


ALTER TABLE TELESOFT.TS_CONTACTO
  ADD (
  CONSTRAINT CONTAC_BAJA
  CHECK (Baja IN ('S', 'N', ' '))
  ENABLE VALIDATE,
  CONSTRAINT CONTAC_PERSONA
  CHECK (Persona IN ('F', 'J', ' '))
  ENABLE VALIDATE,
  CONSTRAINT CONTAC_SEXO
  CHECK (Sexo IN ('F', 'M', ' '))
  ENABLE VALIDATE,
  CONSTRAINT XPKCONTACTO
  PRIMARY KEY
  (CONTACTO)
  USING INDEX TELESOFT.XPKCONTACTO
  ENABLE VALIDATE);

