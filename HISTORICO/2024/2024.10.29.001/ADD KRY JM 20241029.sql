IF NOT EXISTS(SELECT * FROM USPROH WHERE IDPROCEDIMIENTO='MENUQ_CONFIGURACION' AND IDCONTROL='CONTRATOSESPE')
BEGIN
   INSERT INTO USPROH(IDPROCEDIMIENTO, IDCONTROL, TIPO, DESCRIPCION, WEB, RUTA, ICONO, CODIGOPADRE, AUTOMATICO, SEPARADOR, ORDEN, SUBLABEL, CODIGO, PAISES)
   SELECT 'MENUQ_CONFIGURACION', 'CONTRATOSESPE', 'M', 'Contratos Especiales', 1, 'conf.contraEspe', 'fa-solid fa-list', 6, 0, 0, 80, 'Copogos fijos, Movilidad', NULL, NULL
END
IF NOT EXISTS(SELECT NAME FROM SYSOBJECTS WHERE NAME='PPTCNT' AND XTYPE='U')
BEGIN
   CREATE TABLE PPTCNT (
   ID INT IDENTITY (1,1) NOT NULL,
   IDTERCERO VARCHAR(20) NOT NULL,
   IDPLAN VARCHAR(6) NOT NULL,
   PREFIJO VARCHAR(6) NOT NULL,
   COPAFIJO DECIMAL(7,2),
   COPAVAR  DECIMAL(7,2),
   PRCOPAFIJO DECIMAL(7,2),
   PRCOPAVAR  DECIMAL(7,2),  
   MOVILIDAD BIT,
   IDMOVILIDAD INT
   )
END
IF NOT EXISTS(SELECT  * FROM SYS.objects WHERE name='PPTCNTID')
BEGIN
   ALTER TABLE PPTCNT  ADD CONSTRAINT PPTCNTID PRIMARY KEY CLUSTERED (ID)
END
IF NOT EXISTS(SELECT * FROM SYS.indexes WHERE name='PPTCNTIDTERCEROIDPLANPREFIJO')
BEGIN
   CREATE INDEX PPTCNTIDTERCEROIDPLANPREFIJO ON PPTCNT (IDTERCERO,IDPLAN,PREFIJO)
END