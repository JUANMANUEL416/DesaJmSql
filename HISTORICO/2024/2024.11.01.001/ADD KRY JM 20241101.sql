IF NOT EXISTS(SELECT * FROM USVGS WHERE IDVARIABLE='IDSERMOVILIDAD')
BEGIN   
   INSERT INTO USVGS (IDVARIABLE,DESCRIPCION,TP_VARIABLE,DATO)
   SELECT 'IDSERMOVILIDAD','C�digo de Servicio Movilidad ','Alfanumerica',''
END
