CREATE OR ALTER PROCEDURE DBO.SPK_GENERA_JSON_PERU_NOTADBCR
@CNFNOT VARCHAR(20),
@N_FACTURA VARCHAR(20)
AS
DECLARE 
 @JSON VARCHAR(MAX)
,@F_EMISION VARCHAR(10)
,@F_EMISIONFACT VARCHAR(10)
,@H_EMISION VARCHAR(8)
,@F_VENCE   VARCHAR(10)
,@TIPODOC   VARCHAR(2)
,@TIPODOCREL VARCHAR(2)
,@CODPAIS1  VARCHAR(3)
,@PERINICIAL  VARCHAR(10)
,@PERFINAL  VARCHAR(10)
,@NOADMISION  VARCHAR(20)
,@GUIA1  VARCHAR(20)
,@TGUIA1 VARCHAR(2)
,@GUIA2  VARCHAR(20)
,@TGUIA2 VARCHAR(2)
,@NITEMISOR VARCHAR(20)
,@DVEMISIOR VARCHAR(1)
,@RAZONSOCIALEMI VARCHAR(125)
,@CODPOSTALEMI VARCHAR(10)
,@DIRECCIOEMI VARCHAR(255)
,@CIUDADEMI   VARCHAR(45)
,@DEPAREMI   VARCHAR(45)
,@DISTRIEMI   VARCHAR(45)
,@PAISEMI   VARCHAR(2)
,@NITRECEP VARCHAR(20)
,@DVRECEP VARCHAR(1)
,@RAZONSOCIALRECEP VARCHAR(125)
,@CODPOSTALRECEP VARCHAR(10)
,@DIRECCIORECEP VARCHAR(255)
,@CIUDADRECEP   VARCHAR(45)
,@DEPARRECEP   VARCHAR(45)
,@DISTRIRECEP  VARCHAR(45)
,@PAISRECEP   VARCHAR(2)
,@CODSUNAT   VARCHAR(4)
,@OBSERVACION VARCHAR(255)
,@TOTAL SMALLINT
,@VR_TOTAL DECIMAL(14,2)
,@VR_TIGV  DECIMAL(14,2)
,@ITEM VARCHAR(4)
,@CANTIDAD VARCHAR(4)
,@VALOR1 VARCHAR(20)
,@VALOR2 VARCHAR(20)
,@VALOR3 VARCHAR(20)
,@VALOR4 VARCHAR(20)
,@VALOR5 VARCHAR(20)
,@VALOR6 VARCHAR(20)
,@ANEXO VARCHAR(255)
,@REFERENCIA VARCHAR(20)
,@VALOR7 VARCHAR(20)
,@VALOR8 VARCHAR(20)
,@VR_LETRAS VARCHAR(2048)
,@OK VARCHAR(10)
,@ERROR VARCHAR(500)
,@RUTAP VARCHAR(500)
,@AFECTA SMALLINT
,@IDCAUSAL VARCHAR(5)
,@CNSDOCUMENTO VARCHAR(50)
,@COMPANIA VARCHAR(2)
,@IDSEDE VARCHAR(5)
,@TIPOFNOT VARCHAR(5)
,@COPAGO DECIMAL(14,2)
,@VALOITEM VARCHAR(20)
DECLARE @RPTA TABLE(ID INT,DATOS VARCHAR(500))
DECLARE @NEWID VARCHAR(100)
DECLARE @RUTA VARCHAR(100)
DECLARE @SQL  VARCHAR(MAX)
DECLARE @TOKEN VARCHAR(50)
DECLARE @PREFACT VARCHAR(5)
DECLARE @CORRELATIVO VARCHAR(8)
DECLARE @CONTADOR SMALLINT
DECLARE @PRENOTA VARCHAR(5)
DECLARE @CORRELATIVON VARCHAR(8)
DECLARE @CODQR VARCHAR(100)
DECLARE @CODHASH VARCHAR(50)
DECLARE @ESTDOC  VARCHAR(10)
DECLARE @URLFACTEP VARCHAR(256)
DECLARE @DESCSUNAT VARCHAR(256)
DECLARE @sUrl VARCHAR(MAX) 
DECLARE @obj INT
DECLARE @valorDeRegreso INT
DECLARE @response VARCHAR(8000)
DECLARE @src VARCHAR(255)
DECLARE @desc VARCHAR(255)
DECLARE @URLFACT VARCHAR(255)
DECLARE @BODY VARCHAR(MAX)
DECLARE @ERRORES VARCHAR(MAX)
DECLARE @AFECTOITEM BIT
DECLARE @VR_AFECTO DECIMAL(14,2)
DECLARE @VR_INAFECTO DECIMAL(14,2)
DECLARE @TIPOITEM VARCHAR(2)
DECLARE @MAILRECEPTOR VARCHAR(256)
DECLARE @COD_PTO_VENTA VARCHAR(100)
BEGIN
      
    IF (SELECT FACTEP FROM FNOT WHERE CNSFNOT=@CNFNOT AND FNOT.N_FACTURA=@N_FACTURA)='OK'
    BEGIN
      PRINT 'Nota ya fue Recibida'
      RETURN
    END
    IF dbo.FNK_VALORVARIABLE('ENVIA_NOTAS_ACEPTA')='SI'
    BEGIN
        SELECT 
            @COMPANIA=COALESCE(FNOT.COMPANIA,'01'),
            @IDSEDE=COALESCE(FTR.IDSEDE,'01'),
            @F_EMISION=REPLACE(CONVERT(VARCHAR,F_NOTA,102),'.','-'),
            @F_VENCE=REPLACE(CONVERT(VARCHAR,F_NOTA+10,102),'.','-'),
            @F_EMISIONFACT=REPLACE(CONVERT(VARCHAR,FTR.F_FACTURA,102),'.','-'),
            @H_EMISION=REPLACE(CONVERT(VARCHAR,F_NOTA,108),'.','-'),
            @TIPODOCREL= CASE WHEN TIPOFIN='N' THEN '03' ELSE '01' END, 
            @TIPODOC=(CASE FNOT.CLASE WHEN 'C' THEN '07' WHEN 'D' THEN '08' ELSE '' END),
            @CODPAIS1='PEN',
            @NOADMISION=IDCONCEPTO, 
            @OBSERVACION=FNOT.OBSERVACION,
            @TOTAL=CASE WHEN FNOT.TIPOCONCEPTO='P' AND VALORCONCEPTO=100 THEN 1 WHEN FNOT.TIPOCONCEPTO='V' AND FNOT.VALORCONCEPTO=FTR.VR_TOTAL THEN 1 ELSE 0 END,
            @AFECTA=CASE WHEN COALESCE(FTR.VIVA,0)>0 THEN 1 ELSE 0 END, 
            @CNSDOCUMENTO=COALESCE(FNOT.CNSDIANFE,''),
            @COPAGO=ISNULL(FTR.VALORCOPAGO,0)
        FROM FNOT INNER JOIN FTR ON FNOT.N_FACTURA=FTR.N_FACTURA
        WHERE CNSFNOT=@CNFNOT AND FNOT.N_FACTURA=@N_FACTURA

        --Diligencio correctamente la observaci�n
        --SET @IDCAUSAL = LEFT(SUBSTRING(@OBSERVACION,0,CHARINDEX(SPACE(1),@OBSERVACION)),5)
        --IF ISNULL(@IDCAUSAL,'')='' 
        --    SET @IDCAUSAL=@OBSERVACION
    
        --SET @OBSERVACION = REPLACE(REPLACE(@OBSERVACION,@IDCAUSAL,''),SPACE(10),'')
        --IF EXISTS (SELECT 1 FROM CAU WHERE IDCAUSAL=@IDCAUSAL)
        --    SELECT @OBSERVACION=DESCCAUSAL+IIF(@OBSERVACION='','',' // '+@OBSERVACION) FROM CAU WHERE IDCAUSAL=@IDCAUSAL
         SELECT @IDCAUSAL=SUBSTRING(@OBSERVACION,1,3) FROM FNOT WHERE CNSFNOT=@CNFNOT
         IF EXISTS(SELECT * FROM CAU WHERE IDCAUSAL=@IDCAUSAL)
         BEGIN
            SELECT @OBSERVACION=SUBSTRING(OBSERVACION,4,255) FROM FNOT WHERE CNSFNOT=@CNFNOT
         END
         ELSE
         BEGIN
            SELECT @OBSERVACION=OBSERVACION FROM FNOT WHERE CNSFNOT=@CNFNOT
         END
         IF LEN(@OBSERVACION)<7
         BEGIN 
            IF @TIPODOC='07'
            BEGIN
               SELECT @OBSERVACION='NOTA CREDITO '+@OBSERVACION
            END
            ELSE
            BEGIN
               SELECT @OBSERVACION='NOTA CREDITO '+@OBSERVACION
            END
         END
         IF EXISTS(SELECT * FROM FNOTD WHERE CNSFNOT=@CNFNOT AND COALESCE(N_FACTURA,'')='')
         BEGIN
            UPDATE FNOTD SET N_FACTURA=@N_FACTURA WHERE CNSFNOT=@CNFNOT
         END
        --Buscar consecutivo de nota
        IF COALESCE(@CNSDOCUMENTO,'')=''
        BEGIN
            --IF COALESCE(@TIPODOC,'')='07' --NOTAS CREDITO
            --BEGIN
            --   SELECT @TIPOFNOT=PREFIJO FROM FDIAN WHERE IDENTIFICADOR=@IDSEDE AND VENCIDA=0 AND PROCEDENCIA=CASE WHEN @TIPODOCREL='03' THEN 'NCB' WHEN @TIPODOCREL='01' THEN 'NCF' ELSE 'XXX' END
            --END
            --ELSE
            --BEGIN
            --   SELECT @TIPOFNOT=PREFIJO FROM FDIAN WHERE IDENTIFICADOR=@IDSEDE AND VENCIDA=0 AND PROCEDENCIA=CASE WHEN @TIPODOCREL='03' THEN 'NDB' WHEN @TIPODOCREL='01' THEN 'NDF' ELSE 'XXX' END
            --END
            --IF COALESCE(@TIPOFNOT,'')=''
            --BEGIN
            --   PRINT 'NO TENGO DOCUMENTO ELECTRONICO ASOCIADO'
            --   RETURN
            --END
             SET @TIPOFNOT=(CASE @TIPODOC WHEN '07' THEN IIF(@TIPODOCREL='03','NCB','NCF') WHEN '08' THEN IIF(@TIPODOCREL='03','NDB','NDF') END)
             PRINT 'VOY A BUSCAR EL NRO JOSE '+@TIPOFNOT
             SET @CNSDOCUMENTO = SPACE(20)
             PRINT '@COMPANIA= '+COALESCE(@COMPANIA,'SIN CIA')+'@IDSEDE '+COALESCE(@IDSEDE,'SIN SEDE')+'@TIPOFNOT ='+COALESCE(@TIPOFNOT,'SINTIPONC')
             EXEC SPK_GENNUMEROFACTURA @COMPANIA, @IDSEDE, NULL, @CNSDOCUMENTO OUTPUT, @TIPOFNOT
             PRINT 'REGRESO DE SPK_GENNUMEROFACTURA '
             UPDATE FNOT SET CNSDIANFE=@CNSDOCUMENTO WHERE CNSFNOT=@CNFNOT AND N_FACTURA=@N_FACTURA
        END
        PRINT 'REGRESO CON EL CONSECUTIVO'
        IF COALESCE(@CNSDOCUMENTO,'')=''
        BEGIN
            PRINT 'NO TENGO DOCUMENTO ELECTRONICO ASOCIADO'
            RETURN
        END
        SELECT  @PRENOTA=LEFT(@CNSDOCUMENTO,4), @CORRELATIVON=RIGHT(@CNSDOCUMENTO,8)
        IF @TOTAL=1
        BEGIN
            SELECT 
                @VR_TOTAL=SUM(FNOTD.VR_TOTAL-COALESCE(FNOTD.VALORIVA,0)),
                @VR_TIGV=SUM(COALESCE(VALORIVA,0)),
                @VR_LETRAS=DBO.FNK_DE_VALORES_A_LETRAS(SUM(FNOTD.VR_TOTAL-COALESCE(FNOTD.VALORIVA,0)))
            FROM FNOTD 
            WHERE CNSFNOT=@CNFNOT
            AND FNOTD.N_FACTURA=@N_FACTURA
        END

        SELECT @VR_LETRAS=@VR_LETRAS+' SOLES'
        PRINT '@VR_LETRAS='+COALESCE(@VR_LETRAS,'NO TENGO LETRAS')
        SELECT @NITEMISOR= NIT,@DVEMISIOR=6,@RAZONSOCIALEMI=RAZONSOCIAL,@CODPOSTALEMI='150101',@DIRECCIOEMI=COALESCE(DIRECCION,''),@CIUDADEMI=COALESCE(CIU.NOMBRE,''),
        @DEPAREMI=DEP.NOMBRE,@DISTRIEMI='',@PAISEMI='PE'
        FROM TER LEFT JOIN CIU ON TER.CIUDAD=CIU.CIUDAD
                LEFT JOIN DEP ON CIU.DPTO =DEP.DPTO
        WHERE IDTERCERO=DBO.FNK_VALORVARIABLE('IDTERCEROINSTALADO')

        SELECT 
            @NITRECEP=NIT,
            @DVRECEP=CONVERT(VARCHAR(1),CONVERT(INT,COALESCE(TGEN.VALOR1,0))),
            @RAZONSOCIALRECEP=dbo.FNK_LIMPIATEXTO(RAZONSOCIAL,'0-9 A-Z().;:,'),
            @CODPOSTALRECEP='150101',@DIRECCIORECEP=dbo.FNK_LIMPIATEXTO(COALESCE(DIRECCION,''),'0-9 A-Z().;:,') ,@CIUDADRECEP=CIU.NOMBRE,
            @DEPARRECEP=DEP.NOMBRE,@DISTRIRECEP='',@PAISRECEP='PE',@CODSUNAT='0000',
            @MAILRECEPTOR=COALESCE(TER.EMAIL,'')
        FROM FTR INNER JOIN TER ON FTR.IDTERCERO=TER.IDTERCERO
                LEFT JOIN CIU ON TER.CIUDAD=CIU.CIUDAD
                LEFT JOIN DEP ON CIU.DPTO =DEP.DPTO
                LEFT JOIN TGEN ON TER.TIPO_ID =TGEN.CODIGO AND TGEN.TABLA='General' AND TGEN.CAMPO='TIPOIDSUNAT'
        WHERE FTR.N_FACTURA=@N_FACTURA

         IF DB_NAME()=DBO.FNK_VALORVARIABLE('BDATA_PRODUCCION')
         BEGIN
            SELECT @URLFACT=DBO.FNK_VALORVARIABLE('URLFACT_ELE_PRODJSON')
            SELECT @TOKEN=dbo.FNK_VALORVARIABLE('TOKEN_FACTU_ELE_PERU')
         END
         ELSE
         BEGIN
            SELECT @URLFACT=DBO.FNK_VALORVARIABLE('URLFACT_ELE_PRUEJSON')
            SELECT @NITEMISOR='20100100100',@TOKEN='gN8zNRBV+/FVxTLwdaZx0w=='
         END

         IF LEN(COALESCE(@TOKEN,''))<20
         BEGIN
            PRINT 'No existe el token de seguridad'
            RETURN
         END
   SELECT
   @VR_AFECTO=SUM(CASE WHEN COALESCE(PIVA,0)>0 THEN COALESCE(VR_TOTAL,0)-COALESCE(VALORIVA,0) ELSE 0 END),
   @VR_INAFECTO=SUM(CASE WHEN COALESCE(PIVA,0)=0 THEN COALESCE(VR_TOTAL,0) ELSE 0 END),
   @VR_TIGV=SUM(COALESCE(VALORIVA,0))
   FROM FNOTD 
   WHERE CNSFNOT=@CNFNOT

   PRINT 'EMPIEZO'
      SELECT @PREFACT=LEFT(@N_FACTURA,4)
      SELECT @CORRELATIVO= RIGHT(@N_FACTURA,LEN(@N_FACTURA)-(LEN(@PREFACT)+1))

      SELECT @JSON='{ '
      SELECT @JSON=@JSON+'"TOKEN":"'+@TOKEN+'",'
      SELECT @JSON=@JSON+'"COD_TIP_NIF_EMIS": "'+@DVEMISIOR+'",'
      SELECT @JSON=@JSON+'"NUM_NIF_EMIS": "'+@NITEMISOR+'",'
      SELECT @JSON=@JSON+'"NOM_RZN_SOC_EMIS": "'+@RAZONSOCIALEMI+'",'
      SELECT @JSON=@JSON+'"NOM_COMER_EMIS": "'+@RAZONSOCIALEMI+'",'
      SELECT @JSON=@JSON+'"COD_UBI_EMIS": "'+@CODPOSTALEMI+'",'
      SELECT @JSON=@JSON+'"TXT_DMCL_FISC_EMIS": "'+@DIRECCIOEMI+'",'
      SELECT @JSON=@JSON+'"COD_TIP_NIF_RECP": "'+@DVRECEP+'",'
      SELECT @JSON=@JSON+'"NUM_NIF_RECP": "'+@NITRECEP+'",'
      SELECT @JSON=@JSON+'"NOM_RZN_SOC_RECP": "'+@RAZONSOCIALRECEP+'",'
      SELECT @JSON=@JSON+'"TXT_DMCL_FISC_RECEP": "'+@DIRECCIORECEP+'",'
      SELECT @JSON=@JSON+'"FEC_EMIS": "'+@F_EMISION+'",'
      SELECT @JSON=@JSON+'"FEC_VENCIMIENTO": "'+@F_VENCE+'",'
      SELECT @JSON=@JSON+'"COD_TIP_CPE": "'+@TIPODOC+'",'
      SELECT @JSON=@JSON+'"NUM_SERIE_CPE": "'+@PRENOTA+'",'
      SELECT @JSON=@JSON+'"NUM_CORRE_CPE": "'+@CORRELATIVON+'",'
      SELECT @JSON=@JSON+'"COD_MND": "PEN",'
      --SELECT @JSON=@JSON+'"MailEnvio": "mifact@outlook.com",'
      SELECT @JSON=@JSON+'"MailEnvio": "'+@MAILRECEPTOR+'",'
      SELECT @JSON=@JSON+'"COD_PRCD_CARGA": "001",'

   IF COALESCE(@VR_AFECTO,0)>0
   BEGIN
      SELECT @JSON=@JSON+'"MNT_TOT_GRAVADO": "'+CONVERT(VARCHAR(20),@VR_AFECTO)+'",' 
      SELECT @JSON=@JSON+'"MNT_TOT_TRIB_IGV": "'+CONVERT(VARCHAR(20),@VR_TIGV)+'",' 
      --SELECT @JSON=@JSON+'"MNT_TOT": "'+CONVERT(VARCHAR(20),@VR_AFECTO+@VR_TIGV)+'",' 
   END
   IF COALESCE(@VR_INAFECTO,0)>0
   BEGIN
		IF COALESCE(@VR_AFECTO,0)>0
		BEGIN
			--SELECT @JSON=@JSON+'"MNT_TOT": "'+CONVERT(VARCHAR(20),@VR_INAFECTO)+'",'
			SELECT @JSON=@JSON+'"MNT_TOT_EXONERADO":"'+CONVERT(VARCHAR(20),@VR_INAFECTO)+'",'
		END
		ELSE
		BEGIN 
			SELECT @JSON=@JSON+'"MNT_TOT_GRAVADO": "0.00",' 
			SELECT @JSON=@JSON+'"MNT_TOT_TRIB_IGV": "0.00",' 
			--SELECT @JSON=@JSON+'"MNT_TOT": "'+CONVERT(VARCHAR(20),@VR_INAFECTO)+'",'
			SELECT @JSON=@JSON+'"MNT_TOT_EXONERADO":"'+CONVERT(VARCHAR(20),@VR_INAFECTO)+'",'
		 END
	END

	  SELECT @JSON=@JSON+'"MNT_TOT": "'+CONVERT(VARCHAR(20),@VR_AFECTO+@VR_TIGV+@VR_INAFECTO)+'",' 
      SELECT @JSON=@JSON+'"COD_PTO_VENTA": "SERVICIOS DE SALUD",'
      SELECT @JSON=@JSON+'"ENVIAR_A_SUNAT": "true",'
      SELECT @JSON=@JSON+'"RETORNA_XML_ENVIO": "false",'
      SELECT @JSON=@JSON+'"RETORNA_XML_CDR": "false",'
      SELECT @JSON=@JSON+'"RETORNA_PDF": "false",'
      SELECT @JSON=@JSON+'"COD_FORM_IMPR":"001",'
      SELECT @JSON=@JSON+'"TXT_VERS_UBL":"2.1",'
      SELECT @JSON=@JSON+'"TXT_VERS_ESTRUCT_UBL":"2.0",'
      SELECT @JSON=@JSON+'"COD_ANEXO_EMIS":"0000",'
      SELECT @JSON=@JSON+'"COD_TIP_OPE_SUNAT": "0101",'
      IF COALESCE(@TIPODOC,'')='07'
      BEGIN
         SELECT @JSON=@JSON+'"COD_TIP_NC": "01",'
      END
      ELSE
      BEGIN 
          SELECT @JSON=@JSON+'"COD_TIP_ND": "01",'
      END
      SELECT @JSON=@JSON+'"TXT_DESC_MTVO": "'+REPLACE(REPLACE(@OBSERVACION,CHAR(13),''),CHAR(10),'')+'",'
      SELECT @JSON=@JSON+'"items": [ '
        SELECT @CONTADOR =0
        DECLARE @N_CUOTA INT 
        DECLARE XMLFNOTD_CURSOR CURSOR FOR
        SELECT ITEM,TIPO  FROM FNOTD WHERE CNSFNOT=@CNFNOT AND N_FACTURA=@N_FACTURA
        AND COALESCE(FNOTD.VR_TOTAL,0)>0
        ORDER BY ITEM ASC
        OPEN XMLFNOTD_CURSOR    
        FETCH NEXT FROM XMLFNOTD_CURSOR    
        INTO @N_CUOTA,@TIPOITEM
        WHILE @@FETCH_STATUS = 0    
        BEGIN 
           SELECT @CONTADOR=@CONTADOR+1
           IF @CONTADOR>1
           BEGIN
              SELECT @JSON=@JSON+' , '
           END
           SELECT @AFECTOITEM=0
           IF @TIPODOC='07'
           BEGIN
              IF @TIPOITEM='S'
              BEGIN
                  SELECT @ITEM=FNOTD.ITEM,
                      @VALOR1=LTRIM(RTRIM(STR(FNOTD.CANTIDAD))),
                      @VALOR2=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),ROUND(((FNOTD.VR_UNITARIO-COALESCE(FNOTD.VALORIVA,0))*FNOTD.CANTIDAD),2))),
                      @VALOR3=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),COALESCE(FNOTD.VALORIVA,0)*FNOTD.CANTIDAD)),
                      @VALOR4=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),FNOTD.VR_UNITARIO-COALESCE(FNOTD.VALORIVA,0))),
                      @VALOR5=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),COALESCE(FNOTD.PIVA,0))),
                      @AFECTOITEM=CASE WHEN COALESCE(FNOTD.PIVA,0)>0 THEN 1 ELSE 0 END,
                      @ANEXO=dbo.FNK_LIMPIATEXTO(FNOTD.DESCRIPCION,'0-9 A-Z().;:,'), 
                      @REFERENCIA=dbo.FNK_LIMPIATEXTO(FNOTD.IDSERVICIO,'0-9 A-Z().;:,'),
                      @VALOR6=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),(FNOTD.VR_UNITARIO))),
                      @VALOR7=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),(FNOTD.VR_UNITARIO-COALESCE(FNOTD.VALORIVA,0))*FNOTD.CANTIDAD,0)),
                      @VALOR8=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),FNOTD.VR_UNITARIO)),
                      @VALOITEM=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),ROUND((FNOTD.VR_UNITARIO*FNOTD.CANTIDAD),2)))
                  FROM FNOTD
                      INNER JOIN FTRD ON FTRD.N_FACTURA=FNOTD.N_FACTURA AND FTRD.N_CUOTA=FNOTD.N_CUOTA
                  WHERE FNOTD.CNSFNOT=@CNFNOT AND FNOTD.N_FACTURA=@N_FACTURA AND FNOTD.ITEM=@N_CUOTA
               END
               ELSE
               BEGIN
                  SELECT @ITEM=FNOTD.ITEM,
                      @VALOR1=LTRIM(RTRIM(STR(FNOTD.CANTIDAD))),
                      @VALOR2=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),ROUND(((FNOTD.VR_UNITARIO-COALESCE(FNOTD.VALORIVA,0))*FNOTD.CANTIDAD),2))),
                      @VALOR3=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),COALESCE(FNOTD.VALORIVA,0)*FNOTD.CANTIDAD)),
                      @VALOR4=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),FNOTD.VR_UNITARIO-COALESCE(FNOTD.VALORIVA,0))),
                      @VALOR5=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),COALESCE(FNOTD.PIVA,0))),
                      @AFECTOITEM=CASE WHEN COALESCE(FNOTD.PIVA,0)>0 THEN 1 ELSE 0 END,
                      @ANEXO=dbo.FNK_LIMPIATEXTO(FNOTD.DESCRIPCION,'0-9 A-Z().;:,'), 
                      @REFERENCIA=dbo.FNK_LIMPIATEXTO(FNOTD.IDSERVICIO,'0-9 A-Z().;:,'),
                      @VALOR6=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),(FNOTD.VR_UNITARIO))),
                      @VALOR7=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),(FNOTD.VR_UNITARIO-COALESCE(FNOTD.VALORIVA,0))*FNOTD.CANTIDAD)),
                      @VALOR8=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),FNOTD.VR_UNITARIO)),
                      @VALOITEM=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),ROUND((FNOTD.VR_UNITARIO*FNOTD.CANTIDAD),2)))
                  FROM FNOTD INNER JOIN CPNT ON FNOTD.IDSERVICIO=CPNT.CODIGO
                  WHERE FNOTD.CNSFNOT=@CNFNOT AND FNOTD.N_FACTURA=@N_FACTURA AND FNOTD.ITEM=@N_CUOTA
               END
            END
            ELSE
            BEGIN
               IF @TIPOITEM='S'
              BEGIN
                     SELECT @ITEM=FNOTD.ITEM,
                         @VALOR1=LTRIM(RTRIM(STR(FNOTD.CANTIDAD))),
                         @VALOR2=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),ROUND(((FNOTD.VR_UNITARIO-COALESCE(FNOTD.VALORIVA,0))*FNOTD.CANTIDAD),2))),
                         @VALOR3=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),COALESCE(FNOTD.VALORIVA,0)*FNOTD.CANTIDAD)),
                         @VALOR4=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),FNOTD.VR_UNITARIO-COALESCE(FNOTD.VALORIVA,0))),
                         @VALOR5=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),COALESCE(FNOTD.PIVA,0))),
                         @AFECTOITEM=CASE WHEN COALESCE(FNOTD.PIVA,0)>0 THEN 1 ELSE 0 END,
                         @ANEXO=dbo.FNK_LIMPIATEXTO(FNOTD.DESCRIPCION,'0-9 A-Z().;:,'), 
                         @REFERENCIA=dbo.FNK_LIMPIATEXTO(FNOTD.IDSERVICIO,'0-9 A-Z().;:,'),
                         @VALOR6=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),(FNOTD.VR_UNITARIO))),
                         @VALOR7=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),(FNOTD.VR_UNITARIO-COALESCE(FNOTD.VALORIVA,0))*FNOTD.CANTIDAD,0)),
                         @VALOR8=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),FNOTD.VR_UNITARIO)),
                         @VALOITEM=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),ROUND((FNOTD.VR_UNITARIO*FNOTD.CANTIDAD),2)))
                     FROM FNOTD INNER JOIN SER ON FNOTD.IDSERVICIO=SER.IDSERVICIO
                     WHERE FNOTD.CNSFNOT=@CNFNOT AND FNOTD.N_FACTURA=@N_FACTURA AND FNOTD.ITEM=@N_CUOTA
                  END
                  ELSE
                  BEGIN
                     SELECT @ITEM=FNOTD.ITEM,
                         @VALOR1=LTRIM(RTRIM(STR(FNOTD.CANTIDAD))),
                         @VALOR2=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),ROUND(((FNOTD.VR_UNITARIO-COALESCE(FNOTD.VALORIVA,0))*FNOTD.CANTIDAD),2))),
                         @VALOR3=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),COALESCE(FNOTD.VALORIVA,0)*FNOTD.CANTIDAD)),
                         @VALOR4=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),FNOTD.VR_UNITARIO)),
                         @VALOR5=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),COALESCE(FNOTD.PIVA,0))),
                         @AFECTOITEM=CASE WHEN COALESCE(FNOTD.PIVA,0)>0 THEN 1 ELSE 0 END,
                         @ANEXO=dbo.FNK_LIMPIATEXTO(FNOTD.DESCRIPCION,'0-9 A-Z().;:,'), 
                         @REFERENCIA=dbo.FNK_LIMPIATEXTO(FNOTD.IDSERVICIO,'0-9 A-Z().;:,'),
                         @VALOR6=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),(FNOTD.VR_UNITARIO+COALESCE(FNOTD.VALORIVA,0)))),
                         @VALOR7=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),(FNOTD.VR_UNITARIO*FNOTD.CANTIDAD))),
                         @VALOR8=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),FNOTD.VR_UNITARIO)),
                         @VALOITEM=CONVERT(VARCHAR(20),CONVERT(DECIMAL(14,2),ROUND(((FNOTD.VR_UNITARIO+COALESCE(FNOTD.VALORIVA,0))*FNOTD.CANTIDAD),2)))
                     FROM FNOTD INNER JOIN CPNT ON FNOTD.IDSERVICIO=CPNT.CODIGO
                     WHERE FNOTD.CNSFNOT=@CNFNOT AND FNOTD.N_FACTURA=@N_FACTURA AND FNOTD.ITEM=@N_CUOTA
                  END
               END
               SELECT @JSON=@JSON+' { '
      
               SELECT @JSON=@JSON+' "COD_ITEM": "'+@REFERENCIA+'",'
               SELECT @JSON=@JSON+' "COD_UNID_ITEM": "NIU",'
               SELECT @JSON=@JSON+' "CANT_UNID_ITEM": "'+@VALOR1+'",'
               SELECT @JSON=@JSON+' "VAL_UNIT_ITEM": "'+@VALOR4+'",' 
               SELECT @JSON=@JSON+' "VAL_VTA_ITEM": "'+@VALOR7+'",'
               SELECT @JSON=@JSON+' "MNT_BRUTO": "'+@VALOR7+'",'
               SELECT @JSON=@JSON+' "PRC_VTA_UNIT_ITEM": "'+@VALOR6+'",'
               SELECT @JSON=@JSON+' "MNT_PV_ITEM": "'+@VALOITEM+'",'
               SELECT @JSON=@JSON+' "COD_TIP_PRC_VTA": "01",'
               IF @AFECTOITEM=1
               BEGIN    
                  SELECT @JSON=@JSON+' "COD_TIP_AFECT_IGV_ITEM":"10",'
                  SELECT @JSON=@JSON+' "COD_TRIB_IGV_ITEM": "1000",'
                  SELECT @JSON=@JSON+' "POR_IGV_ITEM": "'+@VALOR5+'",'
                  SELECT @JSON=@JSON+' "MNT_IGV_ITEM": "'+@VALOR3+'", '
               END
               ELSE
               BEGIN
                  SELECT @JSON=@JSON+' "COD_TIP_AFECT_IGV_ITEM":"20",'
                  SELECT @JSON=@JSON+' "COD_TRIB_IGV_ITEM": "9997",'
                  SELECT @JSON=@JSON+' "POR_IGV_ITEM": "0.00",'
                  SELECT @JSON=@JSON+' "MNT_IGV_ITEM": "0.00",'
               END

               SELECT @JSON=@JSON+' "TXT_DESC_ITEM": "'+@ANEXO+'" '                  
               SELECT @JSON=@JSON+'}'


	        FETCH NEXT FROM XMLFNOTD_CURSOR    
	        INTO @N_CUOTA,@TIPOITEM
        END
        CLOSE XMLFNOTD_CURSOR
        DEALLOCATE XMLFNOTD_CURSOR
      SELECT @JSON=@JSON+' ], '
	   SELECT @JSON=@JSON+' "docs_referenciado": ['
      SELECT @JSON=@JSON+'  { '
      SELECT @JSON=@JSON+'    "COD_TIP_DOC_REF": "'+@TIPODOCREL+'",'
      SELECT @JSON=@JSON+'    "NUM_SERIE_CPE_REF": "'+@PREFACT+'",'
		SELECT @JSON=@JSON+'	  "NUM_CORRE_CPE_REF":"'+@CORRELATIVO+'",'
		SELECT @JSON=@JSON+'	  "FEC_DOC_REF":"'+@F_EMISIONFACT+'"'
      SELECT @JSON=@JSON+'   }'
      SELECT @JSON=@JSON+' ]'
      SELECT @JSON=@JSON+' }'
   
        SELECT @JSON=REPLACE(@JSON,'#','')

         PRINT 'DEFINITIVO...'+CHAR(13)
       --  PRINT @JSON
        IF LEN(@JSON)<=0
        BEGIN
            RAISERROR ('JSON no fue generado Correctamente',16,1)
            RETURN
        END
        --SELECT @URLFACT='http://demo.mifact.net.pe/api/invoiceService.svc/SendInvoice'
        IF LEN(@URLFACT)<30
        BEGIN
           PRINT 'No existe api valida para el envio '
           RETURN
        END
         SELECT @sUrl =@URLFACT
         SELECT @BODY=@JSON

         PRINT '@sUrl='+@sUrl
         PRINT '@JSON='+@BODY
         EXEC sys.sp_OACreate 'MSXML2.ServerXMLHttp', @obj OUT
         EXEC sys.sp_OAMethod @obj, 'Open', NULL, 'POST', @sUrl, false
         Exec sp_OAMethod @obj, 'setRequestHeader', null, 'Content-Type', 'application/json'
         Exec sp_OAMethod @obj, 'send', null, @body
         Exec sp_OAMethod @obj, 'responseText', @Response OUTPUT
         Exec sp_OADestroy @obj

      INSERT INTO FTRAPILOG(N_FACTURA,CNSFNOT, TIPODOC, ESTADOC, ERRORES, DESCSUNAT,METODO, JSONSOLICITUD, JSONRESPUESTA)
      SELECT @N_FACTURA,@CNFNOT,  @TIPODOC, @ESTDOC, @ERRORES, @DESCSUNAT,'ENVIO',@body , @Response

		-- UPDATE FNOT SET SOLICITUDJSON=@JSON,RESPUESTAJSON=@response WHERE N_FACTURA=@N_FACTURA AND CNSFNOT=@CNFNOT
		 IF ISJSON(@response)<>1
		 BEGIN
			PRINT 'Error en la Respuesta NO es json .. ME DEVUELVO'
			UPDATE FNOT SET FACTEP='ERROR' WHERE N_FACTURA=@N_FACTURA AND CNSFNOT=@CNFNOT
			RETURN
		 END
         SELECT @CODQR=CODQR,@CODHASH=CODHASH,@ESTDOC=ESTDOC,@URLFACTEP=URLFACTEP,@DESCSUNAT=DESCSUNAT,@ERRORES=ERRORES
         FROM OPENJSON(@Response)
         WITH(
                CODQR       VARCHAR(100) '$.cadena_para_codigo_qr'
               ,CODHASH    VARCHAR(50) '$.codigo_hash'
               ,ESTDOC     VARCHAR(10) '$.estado_documento'
               ,URLFACTEP  VARCHAR(256) '$.url'
               ,ERRORES    VARCHAR(MAX) '$.errors'
               ,DESCSUNAT  VARCHAR(MAX) '$.sunat_description'
         )

         IF @ESTDOC IN('101','102','103')
         BEGIN
            UPDATE FNOT SET FACTEP='OK',CUDE=LTRIM(RTRIM(@CODQR)) WHERE N_FACTURA=@N_FACTURA AND CNSFNOT=@CNFNOT
         END
         ELSE
         BEGIN
             UPDATE FNOT SET FACTEP='ERROR' WHERE N_FACTURA=@N_FACTURA AND CNSFNOT=@CNFNOT
         END
        
    END
    ELSE
    BEGIN
        PRINT 'No se enviar� a ACEPTA hasta que se configure la variable ENVIA_NOTAS_ACEPTA'
    END
END


