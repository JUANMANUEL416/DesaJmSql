CREATE OR ALTER PROCEDURE DBO.SPK_JSON_FTR_PERU_INTERFAX
@N_FACTURA  VARCHAR(20)
WITH ENCRYPTION
AS 
DECLARE 
 @JSON VARCHAR(MAX)
,@JSOND VARCHAR(MAX)                    ,@CODDOC VARCHAR(4)                      ,@PREFACT VARCHAR(4)                     ,@NFACTURA VARCHAR(20)
,@F_EMISION VARCHAR(10)                 ,@H_EMISION VARCHAR(8)                   ,@F_VENCE   VARCHAR(10)                  ,@TIPODOC   VARCHAR(2)
,@CODPAIS1  VARCHAR(3)                  ,@PERINICIAL  VARCHAR(10)                ,@PERFINAL  VARCHAR(10)                  ,@NOADMISION  VARCHAR(20)
,@GUIA1  VARCHAR(20)                    ,@TGUIA1 VARCHAR(2)                      ,@GUIA2  VARCHAR(20)                     ,@TGUIA2 VARCHAR(2)
,@NITEMISOR VARCHAR(20)                 ,@DVEMISIOR VARCHAR(1)                   ,@RAZONSOCIALEMI VARCHAR(125)            ,@CODPOSTALEMI VARCHAR(10)
,@DIRECCIOEMI VARCHAR(255)              ,@CIUDADEMI   VARCHAR(45)                ,@DEPAREMI   VARCHAR(45)                 ,@DISTRIEMI   VARCHAR(45)
,@PAISEMI   VARCHAR(2)                  ,@NITRECEP VARCHAR(20)                   ,@DVRECEP VARCHAR(1)                     ,@RAZONSOCIALRECEP VARCHAR(125)
,@CODPOSTALRECEP VARCHAR(10)            ,@DIRECCIORECEP VARCHAR(255)             ,@CIUDADRECEP   VARCHAR(45)              ,@DEPARRECEP   VARCHAR(45)
,@DISTRIRECEP  VARCHAR(45)              ,@PAISRECEP   VARCHAR(2)                 ,@CODSUNAT   VARCHAR(4)                  ,@VR_BRUTO DECIMAL(14,2)
,@VR_AFECTO DECIMAL(14,2)               ,@VR_INAFECTO DECIMAL(14,2)              ,@VR_COPAFECTO DECIMAL(14,2)             ,@VR_COPINAFECTO DECIMAL(14,2)
,@VR_IVA DECIMAL(14,2)                  ,@NOMBREI VARCHAR(1)                     ,@CODIMP  VARCHAR(4)                     ,@IMP     VARCHAR(4)
,@CODINTER VARCHAR(4)                   ,@VR_BRUTO1 DECIMAL(14,2)                ,@VR_NETO DECIMAL(14,2)                  ,@VR_IVA1 DECIMAL(14,2)
,@PVIVA   DECIMAL(7,2)                  ,@VR_LETRAS VARCHAR(2048)                ,@DNI   VARCHAR(20)                      ,@NOMBEPTE VARCHAR(120)
,@VRCOPAGO DECIMAL(14,2)                ,@LEYENDA VARCHAR(520)                   ,@OBSERVACION VARCHAR(255)               ,@NBOLE INT                              
,@B     INT                             ,@PORCO DECIMAL(7,4)                     ,@PORCOAFE DECIMAL(7,4)                  ,@PORCOINA DECIMAL(7,4)                  
,@ITEM VARCHAR(4)                        ,@CANTIDAD VARCHAR(4)
,@VALOR1 VARCHAR(20)                    ,@VALOR2 VARCHAR(20)                     ,@VALOR3 VARCHAR(20)                     ,@VALOR4 VARCHAR(20)
,@VALOR5 VARCHAR(20)                    ,@VALOR6 VARCHAR(20)                     ,@ANEXO VARCHAR(255)                     ,@REFERENCIA VARCHAR(20)
,@VALOR7 VARCHAR(20)                    ,@VALOR8 VARCHAR(20)                     ,@VALOR9 VARCHAR(20)                     
,@OK VARCHAR(10)                        ,@AFECTA SMALLINT                        ,@MIXTA BIT                              ,@FACTEP VARCHAR(10)
,@ERFACTEP VARCHAR(60)                  ,@ESPAQ BIT                              ,@TIPOFACT VARCHAR(2) --INDIVIDUAL,MASIVA 
,@CORRELATIVO VARCHAR(20)               ,@MAILRECEPTOR VARCHAR(256)              ,@USUARIOFACT VARCHAR(20)                 ,@NROITEM SMALLINT
,@TOKEN VARCHAR(50)                     ,@CODQR VARCHAR(100)                     ,@CODHASH VARCHAR(50)                     ,@ESTDOC  VARCHAR(10)
,@URLFACTEP VARCHAR(256)                ,@DESCSUNAT VARCHAR(MAX)                 ,@ERRORES VARCHAR(MAX)                    ,@sUrl VARCHAR(MAX) 
,@obj INT                               ,@valorDeRegreso INT                     ,@response VARCHAR(8000)                  ,@src VARCHAR(255)
,@desc VARCHAR(255)                     ,@URLFACT VARCHAR(255)                   ,@BODY VARCHAR(MAX)                       ,@PAQUETE BIT
,@DIASVENCE SMALLINT                    ,@F_FACTURA DATETIME                     ,@MNT_PENDIENTE VARCHAR(20)               ,@NCUOTAS SMALLINT
,@VLR_CUOTA DECIMAL(14,2)               ,@VLR_PENDIENTE DECIMAL(14,2)            ,@PROCEDENCIAFTR VARCHAR(20)              ,@CNSFCT VARCHAR(20)
,@TIPODOC_AFI VARCHAR(1)                ,@NOMBRES VARCHAR(60)                    ,@PAPELLIDO VARCHAR(100)                  ,@SAPELLIDO VARCHAR(100)
,@DIRECCION_AFI VARCHAR(40)             ,@TELEFONO_AFI VARCHAR(40)               ,@EMAIL_AFI VARCHAR(40)                   ,@PAIS_AFI VARCHAR(40)
,@CIUDAD_AFI VARCHAR(40)                ,@DISTRITO_AFI VARCHAR(40)               ,@SITTEDS VARCHAR(40)                     ,@PREFIJO VARCHAR(20)
,@NPREFIJO VARCHAR(120)                 ,@FECHAPRES VARCHAR(10)                  ,@IDPLAN VARCHAR(6)                       ,@USUMEDICO VARCHAR(20)
,@ESPECIALIDAD VARCHAR(10) 
DECLARE @BOLETA TABLE(N_FACTURA VARCHAR(20), VALOR DECIMAL(14,2),ID INT IDENTITY(1,1))
DECLARE @RPTA TABLE(ID INT,DATOS VARCHAR(500))
BEGIN  

   SELECT @FACTEP=FTR.FACTEP,@CNSFCT=CONVERT(VARCHAR,CONCAT(CONVERT(INT,FTR.IDSEDE),CONVERT(INT,RIGHT(CNSFCT,LEN(FTR.IDSEDE)))),20),@ERFACTEP=RAZONANULACION,@CODDOC='0101',@PREFACT=REPLACE(FDIAN.PREFIJO,'-',''),@NFACTURA=FTR.N_FACTURA,@F_FACTURA=F_FACTURA,@F_EMISION=REPLACE(CONVERT(VARCHAR,F_FACTURA,102),'.','-'),
   @H_EMISION=REPLACE(CONVERT(VARCHAR,F_FACTURA,108),'.',''),@F_VENCE= REPLACE(CONVERT(VARCHAR,F_VENCE,102),'.','-'),@TIPODOC= CASE WHEN TIPOFIN='N' THEN '03' ELSE '01' END,@CODPAIS1='PE',
   @PERINICIAL=REPLACE(CONVERT(VARCHAR,CAST('01/'+CASE WHEN MONTH(F_FACTURA)<10 THEN '0' ELSE '' END+CAST(MONTH(F_FACTURA) AS VARCHAR(2))+'/'+CAST(YEAR(F_FACTURA) AS VARCHAR(4))AS DATETIME),102),'.','-'),
   @PERFINAL=REPLACE(CONVERT(VARCHAR,CAST('01/'+CASE WHEN MONTH(F_FACTURA)<10 THEN '0' ELSE '' END+CAST(MONTH(F_FACTURA) AS VARCHAR(2))+'/'+CAST(YEAR(F_FACTURA) AS VARCHAR(4)) AS DATETIME)+29,102),'.','-'),
   @NOADMISION=FTR.NOREFERENCIA,@GUIA1='T001-00000001',@TGUIA1='09',@GUIA2='T001-00000002',@TGUIA2='99',
   @DNI=CASE WHEN LEN( AFI.DOCIDAFILIADO)=8 THEN  AFI.DOCIDAFILIADO 
		     WHEN LEN(AFI.DOCIDAFILIADO)<8 THEN REPLACE(SPACE(8-LEN(AFI.DOCIDAFILIADO)),SPACE(1),0)+AFI.DOCIDAFILIADO
			 ELSE RIGHT(AFI.DOCIDAFILIADO,8)
	   END,
   @NOMBEPTE=dbo.FNK_LIMPIATEXTO(AFI.NOMBREAFI,'0-9 A-Z().;:,'),
   @NOMBRES=CONCAT(AFI.PNOMBRE,' ',COALESCE(AFI.SNOMBRE,'')),
   @PAPELLIDO=COALESCE(AFI.PAPELLIDO,''),
   @SAPELLIDO=COALESCE(AFI.SAPELLIDO,''),
   @DIRECCION_AFI=LEFT(COALESCE(AFI.DIRECCION,''),40),
   @TELEFONO_AFI=COALESCE(AFI.TELEFONORES,AFI.CELULAR,''),
   @EMAIL_AFI=COALESCE(AFI.EMAIL,''),
   --@PAIS_AFI=COALESCE(AFI.PA,''),
   @CIUDAD_AFI=COALESCE(AFI.CIUDAD,''),
   @DISTRITO_AFI=COALESCE(AFI.CIUDAD,''),
   @VRCOPAGO=FTR.VALORCOPAGO,@AFECTA=CASE WHEN FTR.VIVA>0 THEN 1 ELSE 0 END,
   @TIPOFACT=FTR.TIPOFAC,@PAQUETE=COALESCE(PAQUETE,0),@USUARIOFACT=FTR.USUARIOFACTURA,
   @NCUOTAS=COALESCE(FTR.CUOTAS,1),@PROCEDENCIAFTR=FTR.PROCEDENCIA,
   @TIPODOC_AFI=CONVERT(VARCHAR(1),CONVERT(INT,COALESCE(TGEN.VALOR1,0))),
   @IDPLAN=FTR.IDPLAN,@USUMEDICO='Pruebas Med',@ESPECIALIDAD='Medicina general'
   FROM FTR INNER JOIN FDIAN ON FTR.CNSRESOL=FDIAN.CNSRESOL
            LEFT  JOIN AFI  ON FTR.IDAFILIADO=AFI.IDAFILIADO
			LEFT JOIN TGEN ON AFI.TIPO_DOC =TGEN.CODIGO AND TGEN.TABLA='General' AND TGEN.CAMPO='TIPOIDSUNAT'
   WHERE FTR.N_FACTURA=@N_FACTURA
   AND FDIAN.PROCEDENCIA=CASE WHEN FTR.TIPOFIN='N' THEN 'BOLE' ELSE 'FTR' END


   SELECT @CORRELATIVO= RIGHT(@N_FACTURA,LEN(@N_FACTURA)-(LEN(@PREFACT)+1))
   SELECT @NITEMISOR= NIT,@DVEMISIOR=6,@RAZONSOCIALEMI=dbo.FNK_LIMPIATEXTO(RAZONSOCIAL,'0-9 A-Z().;:,'),@CODPOSTALEMI='150101',@DIRECCIOEMI=DIRECCION,@CIUDADEMI=CIU.NOMBRE,
   @DEPAREMI=DEP.NOMBRE,@DISTRIEMI='',@PAISEMI='PE',@MAILRECEPTOR=COALESCE(TER.EMAIL,'')
   FROM TER LEFT JOIN CIU ON TER.CIUDAD=CIU.CIUDAD
           LEFT JOIN DEP ON CIU.DPTO =DEP.DPTO
   WHERE IDTERCERO=DBO.FNK_VALORVARIABLE('IDTERCEROINSTALADO')


   SELECT @NITRECEP=CASE WHEN FTR.IDTERCERO=FTR.IDAFILIADO AND COALESCE(TER.RUC,'')<> '' AND FTR.TIPOFIN='C' THEN RUC ELSE NIT END ,
          @DVRECEP=CASE WHEN FTR.IDTERCERO=FTR.IDAFILIADO AND COALESCE(TER.RUC,'')<> '' AND FTR.TIPOFIN='C'  THEN 6 ELSE CONVERT(VARCHAR(1),CONVERT(INT,COALESCE(TGEN.VALOR1,0))) END,
          @RAZONSOCIALRECEP=dbo.FNK_LIMPIATEXTO(RAZONSOCIAL,'0-9 A-Z().;:,'),@CODPOSTALRECEP='150101',@DIRECCIORECEP= dbo.FNK_LIMPIATEXTO(DIRECCION,'0-9 A-Z().;:,'),@CIUDADRECEP=CIU.NOMBRE,
   @DEPARRECEP=DEP.NOMBRE,@DISTRIRECEP='',@PAISRECEP='PE',@CODSUNAT='0000'
   FROM FTR INNER JOIN TER ON FTR.IDTERCERO=TER.IDTERCERO
            LEFT JOIN CIU ON TER.CIUDAD=CIU.CIUDAD
            LEFT JOIN DEP ON CIU.DPTO =DEP.DPTO
            LEFT JOIN TGEN ON TER.TIPO_ID =TGEN.CODIGO AND TGEN.TABLA='General' AND TGEN.CAMPO='TIPOIDSUNAT'
   WHERE FTR.N_FACTURA=@N_FACTURA

   IF @DVRECEP='1' AND LEN(@NITRECEP)<>8
   BEGIN
	  SELECT @NITRECEP=CASE WHEN LEN(@NITRECEP)=8 THEN  @NITRECEP
		     WHEN LEN(@NITRECEP)<8 THEN REPLACE(SPACE(8-LEN(@NITRECEP)),SPACE(1),0)+@NITRECEP
			 ELSE RIGHT(@NITRECEP,8) END
   END

   SELECT @LEYENDA='SITEDS:'+CAST(COALESCE(dbo.FNK_LIMPIATEXTO(VENDEDOR,'0-9 A-Z'),'') AS VARCHAR(20)),@SITTEDS=CAST(COALESCE(dbo.FNK_LIMPIATEXTO(VENDEDOR,'0-9 A-Z'),'') AS VARCHAR(20))
   FROM FTR WHERE N_FACTURA=@N_FACTURA

   SELECT @ESPAQ= CASE WHEN COUNT(*)>0 THEN 1 ELSE 0 END FROM FTRD WHERE N_FACTURA=@N_FACTURA AND COALESCE(PAQUETE,0)=2


	SELECT @LEYENDA=@LEYENDA+CASE WHEN COALESCE(PPT.PSEDEAT,0)=1 THEN '  // TIPO CONVENIO:'+ CASE WHEN @ESPAQ= 1 THEN  CAST(SUBSTRING(PPT.RESUMEN,1,50)  AS VARCHAR(50)) ELSE 'PAGO POR SERVICIO' END+' // SEDE ATENCION: '+COALESCE(SEDEAT,'00') ELSE '' END,
         @DIASVENCE=CASE WHEN @TIPODOC='01' THEN CASE WHEN COALESCE(PPT.DIASVTO,0)<=0 THEN 30 ELSE PPT.DIASVTO END ELSE 0 END
         FROM FTR LEFT JOIN HADMAUT ON FTR.VENDEDOR=HADMAUT.AUTORIZACION 
			 LEFT JOIN PPT ON FTR.IDTERCERO=PPT.IDTERCERO AND FTR.IDPLAN=PPT.IDPLAN
	WHERE FTR.N_FACTURA=@N_FACTURA
	AND HADMAUT.NOADMISION=@NOADMISION

   IF COALESCE(@ESPAQ,0)=1 
   BEGIN
      DECLARE @DATOSERPAQ VARCHAR(255)
      DECLARE @IDSERPAQ    VARCHAR(20)
      SELECT @DATOSERPAQ=LTRIM(RTRIM(OBS)),@IDSERPAQ=IDSERVICIOPAQUETE FROM HADM WHERE NOADMISION=@NOADMISION
      IF @DATOSERPAQ IS NULL OR LEN(COALESCE(@DATOSERPAQ,''))=0
      BEGIN
         SELECT @DATOSERPAQ=NULL
      END
   END

   SELECT @VR_IVA=VIVA,@NOMBREI='S',@CODIMP='1000',@IMP='IGV',@CODINTER='VAT'
   FROM FTR 
   WHERE FTR.N_FACTURA=@N_FACTURA

   SELECT  @VR_BRUTO=SUM((COALESCE(VALOR,0)*COALESCE(CANTIDAD,0))),@VR_BRUTO1=SUM((COALESCE(VALOR,0)*COALESCE(CANTIDAD,0))+CASE WHEN COALESCE(PIVA,0)>0 THEN  (COALESCE(VALOR,0)*COALESCE(CANTIDAD,0))*(PIVA/100)ELSE 0 END)
   FROM FTRD 
   WHERE FTRD.N_FACTURA=@N_FACTURA
   AND COALESCE(PAQUETE,0)<>2

   SELECT
   @VR_AFECTO=SUM(CASE WHEN COALESCE(PIVA,0)>0 THEN VLRIMPUESTO ELSE 0 END),
   @VR_INAFECTO=SUM(CASE WHEN COALESCE(PIVA,0)=0 THEN (COALESCE(VALOR,0)*COALESCE(CANTIDAD,0))-(COALESCE(FTRD.VLR_COPAGOS,0)) ELSE 0 END),
	@VR_COPAFECTO=SUM(CASE WHEN COALESCE(PIVA,0)>0 THEN COALESCE(FTRD.VLR_COPAGOS,0) ELSE 0 END ),
	@VR_COPINAFECTO=SUM(CASE WHEN COALESCE(PIVA,0)=0 THEN COALESCE(FTRD.VLR_COPAGOS,0) ELSE 0 END )
   FROM FTRD 
   WHERE FTRD.N_FACTURA=@N_FACTURA
   AND COALESCE(PAQUETE,0)<>2

   IF COALESCE(@VR_AFECTO,0)+COALESCE(@VR_INAFECTO,0)<=0
   BEGIN
      PRINT 'Sin valores Me devuelvo'
      RETURN
   END


   IF COALESCE(@VR_AFECTO,0)>0 AND COALESCE(@VR_INAFECTO,0)>0
   BEGIN
      SELECT @MIXTA=1
      SELECT @PORCOAFE=(@VR_COPAFECTO*100/@VR_AFECTO)/100,@PORCOINA=(@VR_COPINAFECTO*100/@VR_INAFECTO)/100
   END
   ELSE
   BEGIN
      SELECT @MIXTA=0,@PORCOAFE=0,@PORCOINA=0
   END


   SELECT @VR_NETO=VR_TOTAL,@VR_IVA1=COALESCE(VIVA,0),@VR_LETRAS= DBO.FNK_DE_VALORES_A_LETRAS(VR_TOTAL)
   FROM FTR 
   WHERE FTR.N_FACTURA=@N_FACTURA

   IF COALESCE(@VRCOPAGO,0)>0
   BEGIN
      SELECT @PORCO=(@VRCOPAGO*100/@VR_BRUTO)/100
      IF @PAQUETE=1
      BEGIN
         SELECT @VR_AFECTO=@VR_AFECTO-@VRCOPAGO
      END
   END
   ELSE
   BEGIN
      SELECT @PORCO=0.00
   END
   SELECT @MNT_PENDIENTE=''
   IF @TIPODOC='01' --FACTURA
   BEGIN
      IF COALESCE(@VR_IVA,0)>0
      BEGIN
         IF COALESCE(@VR_NETO,0)>=700
         BEGIN
            SELECT @MNT_PENDIENTE=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),ROUND(@VR_NETO-(@VR_NETO*0.12),2)))
            SELECT @VLR_PENDIENTE=ROUND(@VR_NETO-(@VR_NETO*0.12),2)
         END
         ELSE
         BEGIN
            SELECT @MNT_PENDIENTE=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),ROUND(@VR_NETO,2)))
            SELECT @VLR_PENDIENTE=ROUND(@VR_NETO,2)
         END
      END
      IF COALESCE(@NCUOTAS,1)>1 
      BEGIN
         SELECT @VLR_CUOTA=ROUND((@VLR_PENDIENTE/@NCUOTAS),2)
      END
   END
   
   IF NOT EXISTS (SELECT * FROM FTR WHERE FTR.TIPOFIN='N' AND N_FACTURA=@N_FACTURA)
   BEGIN
      INSERT INTO @BOLETA(N_FACTURA,VALOR)
      SELECT HPRED.N_FACTURAH,SUM(COALESCE(HPRED.VALORCOPAGO,0))
      FROM FTRD INNER JOIN HPRED ON FTRD.NOPRESTACION=HPRED.NOPRESTACION AND HPRED.NOITEM=FTRD.NOITEM AND HPRED.N_FACTURA=FTRD.N_FACTURA
      WHERE FTRD.N_FACTURA=@N_FACTURA
      AND COALESCE(HPRED.N_FACTURAH,'')<>'' AND COALESCE(HPRED.VALORCOPAGO,0)>0
      GROUP BY HPRED.N_FACTURAH

      SELECT @OBSERVACION=''
      IF(SELECT COUNT(*) FROM @BOLETA)>0
      BEGIN
         SELECT @NBOLE=COUNT(*), @B=1 FROM @BOLETA

         SELECT @OBSERVACION='Boletas de Venta:'
         WHILE(@B<=@NBOLE)
         BEGIN
            SELECT @OBSERVACION=@OBSERVACION+' '+N_FACTURA+'  Valor: s/'+CONVERT(VARCHAR(20),VALOR)  FROM @BOLETA WHERE ID=@B AND  N_FACTURA<>'B001-ACEPTA'
            SELECT @B=@B+1
         END
      END
      ELSE
      BEGIN
         SELECT @OBSERVACION='Factura sin Boleta '
      END
   END
   IF COALESCE(@TIPODOC,'')='01' 
   BEGIN
      IF @PROCEDENCIAFTR<>'FINANCIERO'
      BEGIN
         SELECT @OBSERVACION=AFI.TIPO_DOC+': '+AFI.DOCIDAFILIADO+' NOMBRE: '+AFI.NOMBREAFI+' '+@OBSERVACION
         FROM  FTR INNER JOIN AFI ON FTR.IDAFILIADO=AFI.IDAFILIADO
         WHERE FTR.N_FACTURA=@N_FACTURA
      END
      ELSE
      BEGIN
         SELECT @OBSERVACION=OBSERVACION FROM  FTR WHERE FTR.N_FACTURA=@N_FACTURA
      END
   END
   
SELECT @VR_LETRAS=@VR_LETRAS+' SOLES'

 SELECT @JSON='{ '
 SELECT @JSON=@JSON+' "EPrefactura": { '
 SELECT @JSON=@JSON+'"PK_PREFAC": "'+@CNSFCT+'",'   
 SELECT @JSON=@JSON+'"NU_PREFAC": "'+@N_FACTURA+'",'   
 SELECT @JSON=@JSON+'"FE_PREFAC": "'+@F_EMISION+'",'   
 SELECT @JSON=@JSON+'"TI_ORIGEN": "1",'   
 SELECT @JSON=@JSON+'"DE_EMP_EMISORA": "ATENCION DOMICILIARIA",'   
 SELECT @JSON=@JSON+'"CO_SEDE_SAP": "1",'   
 SELECT @JSON=@JSON+'"DE_CENTRO": "ATENCION DOMICILIARIA",'   
 SELECT @JSON=@JSON+'"CO_SOCIEDAD_SAP": "1008",'   
 SELECT @JSON=@JSON+'"TI_FINANC": "1",'   
 SELECT @JSON=@JSON+'"TI_INTERL": "1",'   
 SELECT @JSON=@JSON+'"TI_DOCU_SUNAT": "'+@TIPODOC_AFI+'",'   
 SELECT @JSON=@JSON+'"NU_HIST_CLIN": "'+@DNI+'",'   
 SELECT @JSON=@JSON+'"NU_DOCU_IDEN": "'+@DNI+'",'   
 SELECT @JSON=@JSON+'"NO_CLIENT": "'+@NOMBRES+'",'   
 SELECT @JSON=@JSON+'"AP_PATE_CLIE": "'+@PAPELLIDO+'",'   
 SELECT @JSON=@JSON+'"AP_MATE_CLIE": "'+@SAPELLIDO+'",'   
 SELECT @JSON=@JSON+'"DE_DIRE_CLIE": "'+@DIRECCION_AFI+'",'   
 SELECT @JSON=@JSON+'"CO_PAIS_SSAP": "'+@CODPAIS1+'",'   
 SELECT @JSON=@JSON+'"DE_PAIS": "PER�",'   
 SELECT @JSON=@JSON+'"DE_PROV": "'+@CIUDAD_AFI+'",'   
 SELECT @JSON=@JSON+'"DE_DIST": "'+@DISTRITO_AFI+'",'   
 SELECT @JSON=@JSON+'"CO_REGI_SSAP": "41401",'   
 SELECT @JSON=@JSON+'"DE_REGI": "LIMA",'   
 SELECT @JSON=@JSON+'"NU_TELEF": "'+@TELEFONO_AFI+'",'   
 SELECT @JSON=@JSON+'"NU_REME": "",'   
 SELECT @JSON=@JSON+'"CO_POSTAL": "UBIGEO",'   
 SELECT @JSON=@JSON+'"DE_EMAIL": "'+@EMAIL_AFI+'",'   
 SELECT @JSON=@JSON+'"NU_PREF_ORIG": "",'   
 SELECT @JSON=@JSON+'"CO_USUA_LOGI": "'+@USUARIOFACT+'",'   
 SELECT @JSON=@JSON+'"IM_TOTA_BASE": "'+CONVERT(VARCHAR(20),@AFECTA)+'",'   
 SELECT @JSON=@JSON+'"IM_TOTA_IGV": "'+CONVERT(VARCHAR(20),@VR_IVA1)+'",'   
 SELECT @JSON=@JSON+'"IM_TOTAL": "'+@MNT_PENDIENTE+'",'   
 SELECT @JSON=@JSON+'"CO_MONE": "'+@CODPAIS1+'",'   
 SELECT @JSON=@JSON+'"DE_TIPO_DEPO": "",'   
 SELECT @JSON=@JSON+'"CO_USUA_TRAN": "'+@USUARIOFACT+'",'   
 SELECT @JSON=@JSON+'"CO_ORG_VTA_SAP": "CI10",'   
 SELECT @JSON=@JSON+'"CO_CANAL_DIST": "1D",'   
 SELECT @JSON=@JSON+'"CO_GRU_VEN_SAP": "GVL",'   
 SELECT @JSON=@JSON+'"CO_OF_VTA_SAP": "O001",'   
 SELECT @JSON=@JSON+'"TI_PACIENTE": "2",'   
 SELECT @JSON=@JSON+'"CA_REME": "",'   
 SELECT @JSON=@JSON+'"DES_COND_PAG": "",'   
 SELECT @JSON=@JSON+'"CO_CENTRO_XHIS": "1",'   

 PRINT @JSON

   SELECT @JSON=@JSON+' "EPrefacturaDetalle": [ '
   SELECT @JSOND=''
   PRINT 'DETALLES DE LA FACTURA' --FTRD

      DECLARE @N_CUOTA INT 
	   DECLARE XMLFTRD_CURSOR CURSOR FOR
      SELECT N_CUOTA FROM FTRD WHERE N_FACTURA=@N_FACTURA AND COALESCE(FTRD.PAQUETE,0)<>2
      AND COALESCE(VR_TOTAL,0)>0
      ORDER BY N_CUOTA ASC
	   OPEN XMLFTRD_CURSOR    
	   FETCH NEXT FROM XMLFTRD_CURSOR    
	   INTO @N_CUOTA
	   WHILE @@FETCH_STATUS = 0    
	   BEGIN 
         SELECT @ITEM=CONVERT(varchar(3),N_CUOTA*10),@CANTIDAD=CONVERT(varchar(4),CONVERT(INT,CEILING(FTRD.CANTIDAD))),
                @VALOR1=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,4),COALESCE(VALOR,0))),
                @VALOR2=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,4),ROUND((VLR_SERVICI/FTRD.CANTIDAD),0))),
                @VALOR3=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),ROUND(CASE WHEN COALESCE(VIVA,0)>0 THEN VLRIMPUESTO+VIVA ELSE VLR_SERVICI END,2))),
                @VALOR4=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),CASE WHEN COALESCE(FTRD.VLR_COPAGOS,0)>0 THEN CASE WHEN COALESCE(PIVA,0)>0 THEN FTRD.VLR_COPAGOS/(1+(PIVA/100)) ELSE  FTRD.VLR_COPAGOS END ELSE 0 END  )),
                @VALOR5=CONVERT(VARCHAR(20),CONVERT(INT,COALESCE(PIVA,0))),
                @VALOR6=CASE WHEN COALESCE(VIVA,0)>0 THEN  CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),COALESCE(VIVA,0)*FTRD.CANTIDAD,0)) ELSE '0.00' END,
                --@VALOR7=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),ROUND((COALESCE(VALOR,0)*COALESCE(FTRD.CANTIDAD,0))+CASE WHEN COALESCE(VIVA,0)>0 THEN VIVA ELSE 0 END -CASE WHEN COALESCE(FTRD.VLR_COPAGOS,0)>0 THEN FTRD.VLR_COPAGOS ELSE 0 END ,2))),
                @VALOR7=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),CASE WHEN COALESCE(VIVA,0)>0 THEN VLRIMPUESTO ELSE VALOR END)),
				    @ANEXO= dbo.FNK_LIMPIATEXTO(CASE WHEN @PROCEDENCIAFTR='FINANCIERO' THEN FTRD.ANEXO ELSE CASE WHEN COALESCE(SER.DESCRIPCION_CUPS,'')='' THEN SER.DESCSERVICIO ELSE SER.DESCRIPCION_CUPS END END,'0-9 A-Z'), 
                @REFERENCIA=dbo.FNK_LIMPIATEXTO(COALESCE(SER.CODCUPS,FTRD.REFERENCIA),'0-9 A-Z '),
                @PREFIJO=FTRD.PREFIJO,@NPREFIJO=PRE.NOM_PREFIJO,
                @AFECTA=CASE WHEN COALESCE(PIVA,0)>0 AND COALESCE(VIVA,0)>0 THEN 1 ELSE 0 END,
                @VALOR8=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,4),COALESCE(FTRD.VALOR*FTRD.CANTIDAD,0))),
                @VALOR9=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,4),COALESCE(VLR_SERVICI-VLR_COPAGOS,0))),
                @FECHAPRES= REPLACE(CONVERT(VARCHAR,FECHAPREST,102),'.','')
         FROM FTRD LEFT JOIN SER ON FTRD.REFERENCIA=SER.IDSERVICIO
                   LEFT JOIN PRE ON SER.PREFIJO=PRE.PREFIJO
         WHERE N_FACTURA=@N_FACTURA
         AND N_CUOTA=@N_CUOTA

			IF @NROITEM>0 
			BEGIN
				SELECT @JSOND=@JSOND+','
			END
			SELECT @NROITEM =@N_CUOTA
			
         SELECT @JSOND=@JSOND+' { '
			SELECT @JSOND=@JSOND+'"PK_PREFAC": "'+@CNSFCT+'",'   
			SELECT @JSOND=@JSOND+'"NU_PREFAC": "'+@N_FACTURA+'",'   
			SELECT @JSOND=@JSOND+'"ID_ITEM_PREFA": "'+CAST(@ITEM AS VARCHAR(10))+'",'   
			SELECT @JSOND=@JSOND+'"PK_VALE_PREFA": "",'   
			SELECT @JSOND=@JSOND+'"NU_ENCUENTRO": "'+@NOADMISION+'",'   
			SELECT @JSOND=@JSOND+'"TI_ENCUENTRO": "2",'   
			SELECT @JSOND=@JSOND+'"CO_ASEGURA": "'+@DNI+'",'   
			SELECT @JSOND=@JSOND+'"CO_AUTORIZA": "'+@SITTEDS+'",'   
			SELECT @JSOND=@JSOND+'"CO_CARTA_GARA": "",'   
			SELECT @JSOND=@JSOND+'"CO_MECA_SAP": "02",'   
			SELECT @JSOND=@JSOND+'"CO_CEBE": "",'   
			SELECT @JSOND=@JSOND+'"CO_GRUP_PRES": "'+@PREFIJO+'",'   
			SELECT @JSOND=@JSOND+'"DE_GRUP_PRES": "'+@NPREFIJO+'",'   
			SELECT @JSOND=@JSOND+'"CO_PRES_ITEM": "'+@REFERENCIA+'",'   
			SELECT @JSOND=@JSOND+'"DE_PRES_ITEM": "'+@ANEXO+'",'   
			SELECT @JSOND=@JSOND+'"NO_CORT_MEDI": "'+@USUMEDICO+'",'   
			SELECT @JSOND=@JSOND+'"DE_SERV_GAST": "'+@ESPECIALIDAD+'",'   
			SELECT @JSOND=@JSOND+'"CA_ITEM": "'+@CANTIDAD+'",'   
			SELECT @JSOND=@JSOND+'"IM_PREC_BASE": "'+@VALOR1+'",'   
			SELECT @JSOND=@JSOND+'"IM_BASE_ITEM": "'+@VALOR8+'",'   
			SELECT @JSOND=@JSOND+'"IM_COPAGO": "'+@VALOR3+'",'   
			SELECT @JSOND=@JSOND+'"IM_REAL_GASTO": "'+@VALOR9+'",'   
			SELECT @JSOND=@JSOND+'"NU_HIST_CLIN": "'+@DNI+'",'  
			SELECT @JSOND=@JSOND+'"NU_ORIG_PREF": "",'  
			SELECT @JSOND=@JSOND+'"NU_ORIG_PREF": "",'  
			SELECT @JSOND=@JSOND+'"NO_PACIENTE": "'+@NOMBEPTE+'",'   
			SELECT @JSOND=@JSOND+'"NO_TITULAR": "'+@NOMBEPTE+'",'   
			SELECT @JSOND=@JSOND+'"DE_GARANTE": "'+@RAZONSOCIALRECEP+'",'   
			SELECT @JSOND=@JSOND+'"DE_COMPANIA": "SITTEDS",'   
			SELECT @JSOND=@JSOND+'"FE_INIC_VIGE": "SITTEDS",'   
			SELECT @JSOND=@JSOND+'"FE_FINA_VIGE": "SITTEDS",'   
			SELECT @JSOND=@JSOND+'"PC_COPAGO": "SITTEDS",'   
			SELECT @JSOND=@JSOND+'"IM_DEDUCIBLE": "SITTEDS",'   
			SELECT @JSOND=@JSOND+'"FE_INIC_ENCU": "'+@FECHAPRES+'",'   
			SELECT @JSOND=@JSOND+'"FE_FINA_ENCU": "'+@FECHAPRES+'",'   
			SELECT @JSOND=@JSOND+'"PC_IGV": "'+@VALOR5+'",'   
			SELECT @JSOND=@JSOND+'"CO_RUC_EMISOR": "'+@NITEMISOR+'",'   
			SELECT @JSOND=@JSOND+'"DE_PLAN_COPA": "'+@IDPLAN+'",'   
			SELECT @JSOND=@JSOND+'"CO_GARANTE": "36",'   --NO SE TIENE TODAVIA
			SELECT @JSOND=@JSOND+'"CO_SERV_ENCU": "'+@ESPECIALIDAD+'",'     
			SELECT @JSOND=@JSOND+'"CO_PLAN_COPA": "'+@IDPLAN+'",'   
			SELECT @JSOND=@JSOND+'"CO_SERV_GAST": "'+@REFERENCIA+'",'   
			SELECT @JSOND=@JSOND+'"IM_DEDU_GAST": "'+@VALOR3+'",'   
			SELECT @JSOND=@JSOND+'"PC_COASEGU": "0",'   
			SELECT @JSOND=@JSOND+'"CO_ESPE_SSAP": "'+@ESPECIALIDAD+'",'   
			SELECT @JSOND=@JSOND+'"CO_SUB_MECA": "",'   
			SELECT @JSOND=@JSOND+'"CO_SECTOR": "D1",'   
			SELECT @JSOND=@JSOND+'"CO_TIPO_ATEN": "'+@PREFIJO+'",'   
			SELECT @JSOND=@JSOND+'"ID_MEZCLA": "",'   
			SELECT @JSOND=@JSOND+'"TI_VENTA": "1",'   
			SELECT @JSOND=@JSOND+'"NU_CITA_XHIS": "'+@NOADMISION+'",'   
			SELECT @JSOND=@JSOND+'"IM_PAGO": "0",'   
			SELECT @JSOND=@JSOND+'"ID_TRAN_PAGO": "",'   
			SELECT @JSOND=@JSOND+'"CO_TIPO_ITEM": "I",'   
			SELECT @JSOND=@JSOND+'"VA_DET_PADRE": "",'   
         SELECT @JSOND=@JSOND+'   '
         SELECT @JSOND=@JSOND+' } '
         PRINT @JSOND
	   FETCH NEXT FROM XMLFTRD_CURSOR    
	   INTO @N_CUOTA
	   END
	   CLOSE XMLFTRD_CURSOR
	   DEALLOCATE XMLFTRD_CURSOR
   

   SELECT @JSON=LTRIM(RTRIM(@JSON))+LTRIM(RTRIM(@JSOND))


	SELECT @JSON=LTRIM(RTRIM(@JSON)) +' ], } '

   PRINT @JSON

   IF LEN(@JSON)<10
   BEGIN
      PRINT 'NO TENGO DATOS'
      RETURN
   END


  PRINT 'DEFINITIVO'
  PRINT @JSON
  SELECT @sUrl =@URLFACT
  SELECT @BODY=@JSON

   PRINT '@sUrl='+@sUrl
	PRINT '@JSON='
   PRINT SUBSTRING(@BODY,1,8000)
   IF LEN(@BODY)>8000
   BEGIN
	   PRINT SUBSTRING(@BODY,8001,16000)
      IF LEN(@BODY)>16000
      BEGIN
	      PRINT SUBSTRING(@BODY,16001,24000)
         IF LEN(@BODY)>24000
         BEGIN
	         PRINT SUBSTRING(@BODY,24001,32000)
               IF LEN(@BODY)>32000
               BEGIN
	               PRINT SUBSTRING(@BODY,32001,40000)
                  IF LEN(@BODY)>40000
                  BEGIN
	                  PRINT SUBSTRING(@BODY,40001,48000)
                     IF LEN(@BODY)>48000 
                     BEGIN
	                     PRINT SUBSTRING(@BODY,48001,56000)
                        IF LEN(@BODY)>56000
                        BEGIN
	                        PRINT SUBSTRING(@BODY,56001,64000)
                           BEGIN
	                           PRINT SUBSTRING(@BODY,64001,72000)
                              IF LEN(@BODY)>72000
                              BEGIN
	                              PRINT SUBSTRING(@BODY,72001,80000)
                              END
                           END
                        END
                     END
                  END
               END
            END
         END
      END
END

