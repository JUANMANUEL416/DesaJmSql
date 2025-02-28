INSERT INTO USPRO(IDPROCEDIMIENTO,DESCPROCEDIMIENTO,WEB)
SELECT 'MENUQ_CONTABLE','M�dulo contable web', 1
WHERE NOT EXISTS(SELECT 1 FROM USPRO WHERE IDPROCEDIMIENTO='MENUQ_CONTABLE')

INSERT INTO USPROH(IDPROCEDIMIENTO, IDCONTROL, TIPO, DESCRIPCION, WEB, RUTA, ICONO, AUTOMATICO, SEPARADOR, ORDEN, SUBLABEL)
SELECT 'MENUQ_CENTRAL_WEB', 'CONTABLE', 'M', 'Contable', 1, 'cont', 'fa-solid fa-money-check-dollar', 0, 0, 400, 'Contralor�a'
WHERE NOT EXISTS(SELECT 1 FROM USPROH WHERE IDPROCEDIMIENTO='MENUQ_CENTRAL_WEB' AND IDCONTROL='CONTABLE')

INSERT INTO USPROH(IDPROCEDIMIENTO, IDCONTROL, TIPO, DESCRIPCION, WEB, RUTA, ICONO, AUTOMATICO, SEPARADOR, ORDEN, SUBLABEL)
SELECT 'MENUQ_CONTABLE', 'Liquida_Imp', 'M', 'Liquidaci�n Impuestos', 1, 'conta.liqimp', 'fa-solid fa-building-shield', 0, 0, 10, 'Retenci�n'
WHERE NOT EXISTS(SELECT 1 FROM USPROH WHERE IDPROCEDIMIENTO='MENUQ_CONTABLE' AND IDCONTROL='Liquida_Imp')

