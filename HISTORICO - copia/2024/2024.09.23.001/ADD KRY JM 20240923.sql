IF NOT EXISTS(SELECT * FROM USVGS WHERE IDVARIABLE='RAZONSOCIALENSEDES')
BEGIN   
   INSERT INTO USVGS (IDVARIABLE,DESCRIPCION,TP_VARIABLE,DATO)
   SELECT 'RAZONSOCIALENSEDES','Razon social que sale en la factura? FACTSEDE= SI -SEDE|TER ','Alfanumerica',''
END
