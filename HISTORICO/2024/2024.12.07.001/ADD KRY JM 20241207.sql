IF NOT EXISTS(SELECT * FROM USPROH WHERE IDPROCEDIMIENTO='MENUQ_NOMINA' AND IDCONTROL='SubirEmpleados')
BEGIN
   INSERT INTO USPROH(IDPROCEDIMIENTO, IDCONTROL, TIPO, DESCRIPCION, WEB, RUTA, ICONO, AUTOMATICO, SEPARADOR, ORDEN, SUBLABEL)
   SELECT 'MENUQ_NOMINA', 'SubirEmpleados', 'M', 'Subir Empleados',1,'nom.Subiremp', 'fa-solid fa-cloud-arrow-up',0,0,910,'Crear Empleados'
END

IF EXISTS(SELECT NAME FROM SYSOBJECTS WHERE NAME='FK_NVAC_NVACCODEMP')
BEGIN
   ALTER TABLE NVAC  DROP CONSTRAINT FK_NVAC_NVACCODEMP
END