IF NOT EXISTS(SELECT  * FROM USPRO WHERE IDPROCEDIMIENTO='MENUQ_ESTERILIZACION')
BEGIN
   INSERT INTO USPRO(IDPROCEDIMIENTO, DESCPROCEDIMIENTO, WEB)
   SELECT 'MENUQ_ESTERILIZACION','Menu Esterilizacion',1
END
IF NOT EXISTS(SELECT  * FROM USPROH WHERE IDPROCEDIMIENTO='MENUQ_ESTERILIZACION' AND IDCONTROL='Configuracion')
BEGIN
   INSERT INTO USPROH(IDPROCEDIMIENTO, IDCONTROL, TIPO, DESCRIPCION, WEB, RUTA, ICONO, CODIGOPADRE, AUTOMATICO, SEPARADOR, ORDEN, SUBLABEL, CODIGO, PAISES)
   SELECT 'MENUQ_ESTERILIZACION','Configuracion','M','Configuración',1,'esteril.Config','fa-solid fa-gear',NULL,0,NULL,10,'Grupos,Equipos',NULL,NULL
END
IF NOT EXISTS(SELECT  * FROM USPROH WHERE IDPROCEDIMIENTO='MENUQ_ESTERILIZACION' AND IDCONTROL='Procesos')
BEGIN
   INSERT INTO USPROH(IDPROCEDIMIENTO, IDCONTROL, TIPO, DESCRIPCION, WEB, RUTA, ICONO, CODIGOPADRE, AUTOMATICO, SEPARADOR, ORDEN, SUBLABEL, CODIGO, PAISES)
   SELECT 'MENUQ_ESTERILIZACION','Procesos','M','Procesos de Esterilización',1,'esteril.Procesos','fa-solid fa-recycle',NULL,0,NULL,20,'Recepción,Entrega,Pruebas',NULL,NULL
END
