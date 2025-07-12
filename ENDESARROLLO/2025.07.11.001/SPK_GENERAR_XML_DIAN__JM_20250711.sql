CREATE OR ALTER PROCEDURE DBO.SPK_GENERAR_XML_DIAN
	@CNSDOC VARCHAR(20), -- Si TIPODOC='FV' entonces el consecutivo es CNSFCT else el consecutivo es CNSFNOT
	@TIPODOC VARCHAR(2)='FV', -- FV: Factura de Venta, NC: Nota de Crédito, ND: Nota de Débito
	@PATH_URL VARCHAR(MAX)=NULL,
	@FACTURACION_POR_SEDE BIT = 0,
	@NOMBRE_XML NVARCHAR(1000) OUTPUT,
	@AMBIENTE INT OUTPUT,
	@TESTSETID VARCHAR(100) OUTPUT
WITH ENCRYPTION
AS
DECLARE @BASE_IVA_SERVICIOS      VARCHAR(20)
SELECT @BASE_IVA_SERVICIOS=DATO FROM USVGS WHERE IDVARIABLE='BASE_IVA_SERVICIOS'
DECLARE @T VARCHAR(10)=CHAR(9)   ,@E VARCHAR(10)=CHAR(13)
DECLARE @XML AS NVARCHAR(MAX)    ,@NIT_ADQUIRIENTE VARCHAR(20)=''
,@CNSFCT VARCHAR(20)             ,@N_FACTURA VARCHAR(20)
,@NOREFERENCIA VARCHAR(20)       ,@VR_FACTURA DECIMAL(14,2)
,@VR_BASEIMPONIBLE DECIMAL(14,2)
,@VR_IVA DECIMAL(14,2)=0
,@FECHA_FACT DATE=GETDATE()
,@FECHA_FACT_VENCE DATE
,@F_NOTA DATETIME
,@HORA_FACT TIME=GETDATE()
,@TIPOVENTA INT
,@CNSRESOL VARCHAR(20)
,@VENCIDA INT=0
,@FTRELECTRONICA INT=0
,@MENSAJE_ERROR VARCHAR(MAX)
,@TIPO_DOCUMENTO VARCHAR(2) 
,@TIPO_OPERACION VARCHAR(2) 
,@CANT_TOTAL_ITEMS INT  
,@NOMBRE_CONTACTO VARCHAR(1000) 
,@TELEFONO_CONTACTO VARCHAR(1000)
,@EMAIL_CONTACTO VARCHAR(1000) 
,@FAX_CONTACTO VARCHAR(1000) 
,@FINIRESOL DATE 
,@FFINRESOL DATE
,@PREFIJO VARCHAR(10)
,@CNSINICIAL VARCHAR(20) 
,@CNSFINAL VARCHAR(20) 
,@CNSACTUAL VARCHAR(20)
,@CLAVE_TECNICA VARCHAR(100)--,@AMBIENTE INT
,@TIPO_PERSONA CHAR(1) 
,@NITFACTU VARCHAR(20)
,@DV_FACTURADOR VARCHAR(1)
,@RSOCIALFACTU VARCHAR(1000) 
,@DIRFACTU VARCHAR(1000) 
,@NOMCIUFACTU VARCHAR(100)
,@CODPOSTALFACTU VARCHAR(20)
,@CIUFACTU VARCHAR(100) 
,@CODDEPTOFACTU VARCHAR(2) 
,@NOMDEPFACTU VARCHAR(100) 
,@CODDEPTOADQUI VARCHAR(2)
,@COD_RESPONSABILIDAD_FISCAL VARCHAR(1000) 
,@IDCONCEPTO VARCHAR(10)
,@schemeName_FACTURADOR VARCHAR(2)
-- ADQUIRIENTE
,@TIPO_PERSONA_ADQUIRIENTE INT
,@DV_ADQUIRIENTE VARCHAR(1)
,@RAZONSOCIAL_ADQUIRIENTE VARCHAR(256)
,@CIUDAD_ADQUIRIENTE VARCHAR(100)
,@CODPOSTALADQUI VARCHAR(20)
,@NOMCIUADQUI VARCHAR(100)
,@DIRADQUI VARCHAR(512)
,@CODRESPFISCALADQ VARCHAR(10)='O-99'
,@TELCONTACTOADQUI VARCHAR(100)
,@FAXCONTACTOADQUI VARCHAR(100)
,@EMAIL_ADQUIRIENTE VARCHAR(200)
,@NOMCONTACTOADQUI VARCHAR(256)
,@schemeName_ADQUIRIENTE VARCHAR(2)
,@IDTERCEROADQUI VARCHAR(20)
,@IDPLAN VARCHAR(6)
-- DATOS DEL SOFTWARE
,@SoftwareID VARCHAR(100)
,@SoftwarePIN VARCHAR(100)
,@SoftwareSecurityCode NVARCHAR(1000)
-- DETALLES DE LA FACTURA
,@CANT_LINEAS INT
,@ROW_ID INT=0
,@N_CUOTA INT
,@ANEXO VARCHAR(1024)
,@CANTIDAD DECIMAL(14,2)
,@VALOR DECIMAL(14,2)
,@VLR_SERVICI DECIMAL(14,2)
,@REFERENCIA VARCHAR(20)
,@IDIMPUESTO VARCHAR(10)
,@IDCLASE VARCHAR(10)
,@PIVA DECIMAL(14,2)
,@VIVA DECIMAL(14,2)
,@FACTURA VARCHAR(20) 
,@NIT_DIAN VARCHAR(20)='800197268' 
,@CUFE VARCHAR(1000) 
,@CUDE VARCHAR(1000)
,@QR_CODE NVARCHAR(MAX) 
,@CANTIARCHENV INT=0
,@PREFIJO_USCXS VARCHAR(20)
,@OBSERVACION_FNOT NVARCHAR(1000)
,@VR_NOTA DECIMAL(14,2)
,@VALORCOPAGO DECIMAL(14,2)
,@VALORMODERADORA DECIMAL(14,2)
,@IDMONEDA VARCHAR(3)
,@IDMONEDA_DESTINO VARCHAR(3)
,@IDSGSSS VARCHAR(20)
,@IDSEDE VARCHAR(5)
,@IDSEDEPPAL VARCHAR(5)
,@IPS BIT
,@COPAGOIPS BIT=0
,@PROCEDENCIA VARCHAR(20)
,@IDAFILIADO VARCHAR(20)
,@TIPOVOLUNTARIO VARCHAR(50)
,@NOAUTORIZACION VARCHAR(50)
,@NOMBRE_USUARIO VARCHAR(40)
,@NROCONTRATO VARCHAR(20)
,@AUTORIZACIONES_MIPRES VARCHAR(20)
,@CAPITADA BIT=0
,@TIPOCAP SMALLINT=0
,@FDESDE_FACT DATE
,@FHASTA_FACT DATE
,@NOPOLIZA VARCHAR(20)
,@MODALIDAD_CNT VARCHAR(2)
,@DESC_MODALIDAD_CNT VARCHAR(100)
,@NOMBREUSUARIO VARCHAR(40)
,@IDTERCERO_OFE VARCHAR(20)
,@CalculationRate DECIMAL(14,2)
,@ENDDATE DATETIME
,@STARTDATE DATETIME
,@TIPOFAC VARCHAR(2)
,@TERIPS VARCHAR(20)
,@NOTAS VARCHAR(2000)
,@VLPQFMAS DECIMAL(14,2)
,@TIPONOTA VARCHAR(2)
,@COD_ANTICIPO VARCHAR(20)
,@NOM_ANTICIPO VARCHAR(100)
,@DESCUENTO DECIMAL(14,2)
,@CODHABILITA VARCHAR(20)
,@DESC_TIPOUSUARIO VARCHAR(100)
,@CobertuPlanBeneficio VARCHAR(200)
,@CODSER VARCHAR(3)
,@COPAPROPIO BIT
DECLARE @PORCENTAJE_DESCUENTO DECIMAL(14, 10) = 0 -- Porcentaje descuento global para aplicar en cada linea con más decimales para mayor precisión
DECLARE @REMANENTE DECIMAL(14, 2) = 0 -- Remanente de descuento que no se aplicó en las líneas para aplicar en la última línea
DECLARE @DESCUENTO_LINEA DECIMAL(14, 2) = 0 -- Descuento que se aplica a la línea
DECLARE @FECHA_TRM DATE
DECLARE @VLR_COPAGOAC DECIMAL(14,2)=0
DECLARE @VLR_MODERAAC DECIMAL(14,2)=0
DECLARE @VLR_COPAGODETA DECIMAL(14,2)=0 
DECLARE @VALORMODERADORADETA DECIMAL(14,2)=0
BEGIN
	BEGIN TRY
	IF @TIPODOC IS NULL SET @TIPODOC='FV'
	BEGIN -- Facturador Electrónico OFE
		IF COALESCE(dbo.FNK_VALORVARIABLE('IDTERCERO_OFE'),'')=''
			RAISERROR ('Variable de sistema IDTERCERO_OFE sin configurar', 16, 1); 
		IF(SELECT COUNT( *) FROM FMAS WHERE N_FACTURA IN (SELECT N_FACTURA FROM FTR WHERE CNSFCT=@CNSDOC ))>=1
		BEGIN 
			SET @TERIPS = CASE WHEN  dbo.FNK_VALORVARIABLE('IDTERCERO_OFE')='900450634' THEN  'CENDI' ELSE '' END 
			SELECT @VLPQFMAS= FMAS.VALORPAQ FROM FMAS WHERE N_FACTURA IN (SELECT N_FACTURA FROM FTR WHERE CNSFCT=@CNSDOC )
		END 
		SELECT @TIPO_PERSONA=CASE WHEN NATJURIDICA='Juridica' THEN '1' ELSE '2' END 
			,@NITFACTU=LTRIM(RTRIM(NIT))
			,@DV_FACTURADOR=DV
			,@RSOCIALFACTU=dbo.FNK_LIMPIATEXTO(RAZONSOCIAL,'0-9 A-Z().;:,')
			,@DIRFACTU=dbo.FNK_LIMPIATEXTO(TER.DIRECCION, '0-9 A-Z().;:,') --='CARRERA 19 No 14-47'
			,@CIUFACTU=TER.CIUDAD
			,@NOMCIUFACTU=CIU.NOMBRE
			,@NOMDEPFACTU=DEP.NOMBRE
			,@CODPOSTALFACTU=CIU.CODPOSTAL
			,@COD_RESPONSABILIDAD_FISCAL=TER.COD_RESP_FISCAL
			,@CODDEPTOFACTU=DEP.COD_DIAN
			,@schemeName_FACTURADOR=(SELECT TOP 1 DATO1 FROM TGEN WHERE TABLA='GENERAL' AND CAMPO='TIPOIDENT' AND CODIGO=TER.TIPO_ID)
			,@IDTERCERO_OFE = TER.IDTERCERO
		FROM TER 
		LEFT JOIN CIU ON CIU.CIUDAD=TER.CIUDAD 
		LEFT JOIN DEP ON CIU.DPTO=DEP.DPTO
		WHERE IDTERCERO=dbo.FNK_VALORVARIABLE('IDTERCERO_OFE')

		IF COALESCE(@NITFACTU,'')='' RAISERROR ('NIT del OFE sin configurar', 16, 1); 
		IF COALESCE(@CODPOSTALFACTU,'')='' RAISERROR ('Codigo postal del facturador electrónico es obligatorio', 16, 1); 
		IF COALESCE(@DV_FACTURADOR,'')='' RAISERROR ('Dígito de verificacion del OFE sin configurar', 16, 1); 
		IF COALESCE(@RSOCIALFACTU,'')='' RAISERROR ('Razón social del OFE sin configurar', 16, 1); 
		IF COALESCE(@DIRFACTU,'')='' RAISERROR ('Dirección fiscal del OFE sin configurar', 16, 1); 
		IF COALESCE(@CIUFACTU,'')='' OR COALESCE(@NOMCIUFACTU,'')='' RAISERROR ('Ciudad de la dirección fiscal del OFE sin configurar', 16, 1); 
		IF COALESCE(@COD_RESPONSABILIDAD_FISCAL,'')='' RAISERROR ('Código de la responsabilidad fiscal del OFE sin configurar', 16, 1); 
		IF COALESCE(@schemeName_FACTURADOR,'')='' RAISERROR ('Tipo de documento de identidad del adquiriente no homologado (TGEN.TABLA= GENERAL, TGEN.CAMPO=TIPOIDENT)', 16, 1); 
	END
	BEGIN -- Software
		SELECT @SoftwareID=COALESCE(DESCRIPCION,'') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='SOFTWARE' AND CODIGO='ID'
		SELECT @SoftwarePIN=COALESCE(DESCRIPCION,'') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='SOFTWARE' AND CODIGO='PIN'
		SELECT @TESTSETID=COALESCE(DESCRIPCION,'') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='SOFTWARE' AND CODIGO='TESTSETID'
		IF COALESCE(@SoftwareID,'')='' RAISERROR ('Identificador del Software es obligatorio. (TGEN => ''FDIAN'', ''SOFTWARE'', ''ID'')', 16, 1); 
		IF COALESCE(@SoftwarePIN,'')='' RAISERROR ('PIN del Software es obligatorio. (TGEN => ''FDIAN'', ''SOFTWARE'', ''PIN'')', 16, 1); 
	END

	IF @TIPODOC='FV'
	BEGIN
		PRINT 'INGRESO A FACTURA'
		SELECT TOP 1 @CNSFCT=CNSFCT, @N_FACTURA=N_FACTURA/*dbo.FNK_LIMPIATEXTO(N_FACTURA,'A-Z0-9_-')*/
			, @VR_FACTURA=CAST(VALORSERVICIOS AS DECIMAL(14,2))
			, @VR_IVA=CAST(COALESCE(VIVA,0) AS DECIMAL(14,2))
			, @NOREFERENCIA=NOREFERENCIA
			, @FECHA_FACT= F_FACTURA 
			, @FECHA_TRM = F_FACTURA 
			, @FECHA_FACT_VENCE=F_VENCE
			, @HORA_FACT=F_FACTURA
			, @TIPOVENTA=CASE WHEN TIPOVENTA='Credito' OR FTR.IDPLAN NOT IN (SELECT DATO FROM USVGS WHERE IDVARIABLE LIKE 'IDPLANPART%') THEN 2 ELSE 1 END
			, @CNSRESOL=CNSRESOL
			, @TIPO_DOCUMENTO=CASE WHEN COALESCE(TIPO_DOCUMENTO, '')='' THEN '01' ELSE TIPO_DOCUMENTO END
			, @TIPO_OPERACION=CASE WHEN COALESCE(TIPO_OPERACION, '')='' THEN '10' ELSE TIPO_OPERACION END
			, @VALORCOPAGO=CASE WHEN COALESCE(CAPITADA,0)=0 THEN COALESCE(VALORCOPAGO,0) ELSE CASE WHEN COALESCE(COPAPROPIO,0)=1 THEN COALESCE(CP_VLR_COPAGOS,0) ELSE COALESCE(VALORCOPAGO,0) END END
          ,@VALORMODERADORA=COALESCE(VALORMODERADORA,0)
          ,@COPAPROPIO =COALESCE(COPAPROPIO,0)
			, @IDMONEDA = 'COP'
			, @IDMONEDA_DESTINO=CASE WHEN COALESCE(MONEDA,'01')='01' THEN 'COP' ELSE MONEDA END
			, @IDSEDE=CASE WHEN COALESCE(FTR.IDSEDE,'') IN('Todas','') THEN dbo.FNK_VALORVARIABLE('IDSEDEPRINCIPAL') ELSE FTR.IDSEDE END --STORRES
			, @IDAFILIADO=IDAFILIADO
			, @PROCEDENCIA=PROCEDENCIA
			, @IDPLAN=IDPLAN
			, @NOMBRE_USUARIO=DBO.FNK_LIMPIATEXTO(USUSU.NOMBRE,'A-Z ')
			, @CAPITADA=COALESCE(FTR.CAPITADA, 0)
         , @TIPOCAP=COALESCE(FTR.TIPOCAP,0)
			, @FDESDE_FACT=FECHACAP_INI
			, @FHASTA_FACT=FECHACAP_FIN
			, @TIPOFAC=FTR.TIPOFAC
			, @NOTAS=OBSERVACION
			, @NOMBREUSUARIO = USUSU.NOMBRE
			, @DESCUENTO = FTR.DESCUENTO
		FROM FTR WITH(NOLOCK)
		LEFT JOIN USUSU ON USUSU.USUARIO=FTR.USUARIOFACTURA
		WHERE CNSFCT=@CNSDOC --FACTE=1

		SELECT @CalculationRate = VALOR 
		FROM MNDV 
		WHERE IDMONEDA=@IDMONEDA_DESTINO
		AND dbo.FNK_FECHA_SIN_HORA(FECHA)=dbo.FNK_FECHA_SIN_HORA(@FECHA_TRM) 

		IF @IDMONEDA_DESTINO <> @IDMONEDA
			SELECT @VR_FACTURA = @VR_FACTURA * @CalculationRate
      EXEC SPQ_VERIFA_COPAGOS_FTRE @N_FACTURA
		IF COALESCE(@FACTURACION_POR_SEDE, 0) = 1
		BEGIN
		   IF NOT EXISTS(SELECT TOP 1 IDTERCERO FROM TER INNER JOIN SED ON SED.NIT=TER.NIT)
				RAISERROR ('No encuentro los datos del facturador de la sede (SELECT TOP 1 IDTERCERO FROM TER INNER JOIN SED ON SED.NIT=TER.NIT)', 16, 1)

			SELECT @TIPO_PERSONA=CASE WHEN NATJURIDICA='Juridica' THEN '1' ELSE '2' END 
				,@NITFACTU=LTRIM(RTRIM(NIT))
				,@DV_FACTURADOR=DV
				,@RSOCIALFACTU=dbo.FNK_LIMPIATEXTO(RAZONSOCIAL,'0-9 A-Z().;:,')
				,@DIRFACTU=dbo.FNK_LIMPIATEXTO(TER.DIRECCION, '0-9 A-Z().;:,') --='CARRERA 19 No 14-47'
				,@CIUFACTU=TER.CIUDAD
				,@NOMCIUFACTU=CIU.NOMBRE
				,@NOMDEPFACTU=DEP.NOMBRE
				,@CODPOSTALFACTU=CIU.CODPOSTAL
				,@COD_RESPONSABILIDAD_FISCAL=TER.COD_RESP_FISCAL
				,@CODDEPTOFACTU=DEP.COD_DIAN
				,@schemeName_FACTURADOR=(SELECT TOP 1 DATO1 FROM TGEN WHERE TABLA='GENERAL' AND CAMPO='TIPOIDENT' AND CODIGO=TER.TIPO_ID)
				,@IDTERCERO_OFE = TER.IDTERCERO
			FROM TER 
			LEFT JOIN CIU ON CIU.CIUDAD=TER.CIUDAD 
			LEFT JOIN DEP ON CIU.DPTO=DEP.DPTO
			WHERE IDTERCERO = (SELECT TOP 1 IDTERCERO FROM TER INNER JOIN SED ON SED.NIT=TER.NIT AND SED.IDSEDE=@IDSEDE)

			IF COALESCE(@NITFACTU,'')='' RAISERROR ('FACTURACION POR SEDE: NIT del OFE sin configurar', 16, 1); 
			IF COALESCE(@CODPOSTALFACTU,'')='' RAISERROR ('FACTURACION POR SEDE: Codigo postal del facturador electrónico es obligatorio', 16, 1); 
			IF COALESCE(@DV_FACTURADOR,'')='' RAISERROR ('FACTURACION POR SEDE: Dígito de verificacion del OFE sin configurar', 16, 1); 
			IF COALESCE(@RSOCIALFACTU,'')='' RAISERROR ('FACTURACION POR SEDE: Razón social del OFE sin configurar', 16, 1); 
			IF COALESCE(@DIRFACTU,'')='' RAISERROR ('FACTURACION POR SEDE: Dirección fiscal del OFE sin configurar', 16, 1); 
			IF COALESCE(@CIUFACTU,'')='' OR COALESCE(@NOMCIUFACTU,'')='' RAISERROR ('FACTURACION POR SEDE: Ciudad de la dirección fiscal del OFE sin configurar', 16, 1); 
			IF COALESCE(@COD_RESPONSABILIDAD_FISCAL,'')='' RAISERROR ('FACTURACION POR SEDE: Código de la responsabilidad fiscal del OFE sin configurar', 16, 1); 
			IF COALESCE(@schemeName_FACTURADOR,'')='' RAISERROR ('FACTURACION POR SEDE: Tipo de documento de identidad del adquiriente no homologado (TGEN.TABLA= GENERAL, TGEN.CAMPO=TIPOIDENT)', 16, 1); 

			SELECT @SoftwareID=COALESCE(DESCRIPCION,'') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='SOFTWARE'+@IDSEDE AND CODIGO='ID' 
			SELECT @SoftwarePIN=COALESCE(DESCRIPCION,'') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='SOFTWARE'+@IDSEDE AND CODIGO='PIN'
			SELECT @TESTSETID=COALESCE(DESCRIPCION,'') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='SOFTWARE'+@IDSEDE AND CODIGO='TESTSETID'
			IF COALESCE(@SoftwareID,'')='' RAISERROR ('Identificador del Software es obligatorio. (TGEN => ''FDIAN(IDSEDE)'', ''SOFTWARE'', ''ID'')', 16, 1); 
			IF COALESCE(@SoftwarePIN,'')='' RAISERROR ('PIN del Software es obligatorio. (TGEN => ''FDIAN(IDSEDE)'', ''SOFTWARE'', ''PIN'')', 16, 1); 
		END

		IF(@PROCEDENCIA IN('CI') AND @TIPOFAC='M' AND COALESCE(@NOREFERENCIA,'')='')
			SELECT @NOREFERENCIA= MAX(CONSECUTIVO) FROM CIT WHERE N_FACTURA=@N_FACTURA

		IF @CNSFCT IS NULL
			RAISERROR ('Sin documento pendiente', 16, 1);  

		IF COALESCE(@CAPITADA, 0)=1
		BEGIN
			IF @FDESDE_FACT IS NULL SET @MENSAJE_ERROR='La factura es capitada y no tiene fecha de inicio de facturación'
			IF @FHASTA_FACT IS NULL SET @MENSAJE_ERROR='La factura es capitada y no tiene fecha final de facturación'
			IF COALESCE(@MENSAJE_ERROR,'')<>'' RAISERROR (@MENSAJE_ERROR, 16, 1)
		END
		ELSE
		BEGIN
			SELECT @FDESDE_FACT=MIN(COALESCE(FECHAPREST,FECHA))
				, @FHASTA_FACT=MAX(COALESCE(FECHAPREST,FECHA)) 
			FROM FTRD WHERE CNSFTR=@CNSDOC 
         IF @PROCEDENCIA='SALUD'
         BEGIN
            SELECT @FHASTA_FACT=CASE WHEN @FHASTA_FACT < COALESCE(FECHAALTAMED,@FHASTA_FACT)  THEN FECHAALTAMED ELSE @FHASTA_FACT END   FROM HADM WHERE NOADMISION=@NOREFERENCIA
         END
		END
			
		SELECT @VR_BASEIMPONIBLE = CASE WHEN @BASE_IVA_SERVICIOS='CONIVA' THEN COALESCE(SUM(VLR_SERVICI-COALESCE(VIVA,0)),0) ELSE COALESCE(SUM(VLR_SERVICI),0) END
		FROM FTRD WITH(NOLOCK) WHERE CNSFTR=@CNSDOC AND COALESCE(VLR_SERVICI,0)>0 AND COALESCE(VALOR,0)>0 AND coalesce(VIVA,0)>0 
		AND COALESCE(FTRD.PAQUETE,0) NOT IN (2, 1)--- STORRES20211202

		SELECT @CANT_TOTAL_ITEMS=COUNT(*) 
		FROM		FTRD WITH(NOLOCK) 
		INNER JOIN	FTR WITH(NOLOCK) ON FTR.N_FACTURA=FTRD.N_FACTURA 
		WHERE CNSFCT=@CNSFCT AND CASE WHEN @TERIPS='CENDI' AND COALESCE(@VLPQFMAS,0)>0 THEN COALESCE(@VLPQFMAS,0) ELSE   COALESCE(VLR_SERVICI,0) END >0 
		AND CASE WHEN @TERIPS='CENDI' AND COALESCE(@VLPQFMAS,0)>0 THEN COALESCE(@VLPQFMAS,0) ELSE COALESCE(VALOR,0) END >0
		AND  COALESCE(FTRD.PAQUETE,0) NOT IN (2, 1)--- STORRES20211202

		BEGIN -- Validaciones de Inconsistencias
			IF COALESCE(@CNSRESOL,'')=''
			BEGIN
				SET @MENSAJE_ERROR='Factura '+@N_FACTURA+' sin resolución'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			IF @CANT_TOTAL_ITEMS<=0 
			BEGIN
				SET @MENSAJE_ERROR='Factura '+@N_FACTURA+' sin items en el detalle'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			IF EXISTS(SELECT * FROM FTRD WITH(NOLOCK) WHERE N_FACTURA=@N_FACTURA AND VLR_SERVICI<0)
			BEGIN
				SET @MENSAJE_ERROR='Factura '+@N_FACTURA+' con detalles en negativo'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
		END

		SELECT @VENCIDA=VENCIDA,@FTRELECTRONICA=FTRELECTRONICA, @FINIRESOL=FECHAINI,@FFINRESOL=FECHAVEN, @PREFIJO=COALESCE(PREFIJO,'')
			,@CNSINICIAL=CNSINICIAL ,@CNSFINAL=CNSFINAL ,@CNSACTUAL=CNSACTUAL+1, @CLAVE_TECNICA=dbo.FNK_LIMPIATEXTO(CLAVETECNICA,'A-Z0-9'), @AMBIENTE=AMBIENTE
		FROM FDIAN WHERE CNSRESOL=@CNSRESOL

		IF ISNULL(@AMBIENTE,0)=1 -- Cuando el ambiente es producción se tomará el prefijo y el consecutivo del numero de la factura
		BEGIN
			SELECT @PREFIJO=LTRIM(RTRIM(COALESCE(PREFIJO,''))) FROM FDIAN WHERE CNSRESOL= @CNSRESOL
			SELECT @CNSACTUAL=REPLACE(@N_FACTURA,@PREFIJO,'')
		END

		SELECT @FACTURA=@CNSACTUAL
		-- Revisar que la resolución no esté vencida
		IF COALESCE(@VENCIDA,0)=1
		BEGIN
			SET @MENSAJE_ERROR='Resolución dian Nro. '+@CNSRESOL+' se encuentra vencida'
			RAISERROR (@MENSAJE_ERROR, 16, 1);  
		END
		-- Validar que la resolución que tiene asignada la factura sea la que corresponde a facturación electrónica
		IF COALESCE(@FTRELECTRONICA,0)=0
		BEGIN
			SET @MENSAJE_ERROR='Resolución dian Nro. '+@CNSRESOL+' no corresponde a facturación electrónica'
			RAISERROR (@MENSAJE_ERROR, 16, 1);  
		END
		-- Validar que la factura tenga un tipo de documento según la resolución DIAN
		IF NOT EXISTS (SELECT * FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='TIPO_DOCUMENTO' AND CODIGO=@TIPO_DOCUMENTO) 
		BEGIN
			SET @MENSAJE_ERROR='Factura '+@N_FACTURA+' no tiene un tipo de documento válido (FTR.TIPO_DOCUMENTO => TGEN: ''FDIAN'', ''TIPO_DOCUMENTO'')'
			RAISERROR (@MENSAJE_ERROR, 16, 1);  
		END
		-- Validar que la factura tenga un tipo de operación según la resolución DIAN
		IF NOT EXISTS (SELECT * FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='TIPO_OPERACION' AND CODIGO=@TIPO_OPERACION)
		BEGIN
			SET @MENSAJE_ERROR='Factura '+@N_FACTURA+' no tiene un tipo de operación válido (FTR.TIPO_OPERACION => TGEN: ''FDIAN'', ''TIPO_OPERACION'')'
			RAISERROR (@MENSAJE_ERROR, 16, 1);  
		END
		IF	@FINIRESOL IS NULL OR @FFINRESOL IS NULL OR COALESCE(@CNSFINAL,'')='' OR COALESCE(@CNSFINAL,'')='' OR COALESCE(@CNSACTUAL,'')=''
			OR COALESCE(@CLAVE_TECNICA,'')=''        OR COALESCE(@AMBIENTE,-1)<0
		BEGIN
			SET @MENSAJE_ERROR='La resolución '+@CNSRESOL+' no se encuentra en su totalidad'
			RAISERROR (@MENSAJE_ERROR, 16, 1);  
		END
			
		SELECT @IDSGSSS=IDSGSSS, @IPS=IPS FROM SED WHERE IDSEDE=@IDSEDE
		IF @IPS IS NULL
			RAISERROR ('No se ha determinado si la sede, a la que pertenece el documento electrónico, corresponde o no a una IPS', 16, 1);  

		IF @IPS=1 SET @COPAGOIPS=1

		IF @PROCEDENCIA IN ('SALUD','CE','CI') AND COALESCE(@IDAFILIADO,'')='' AND COALESCE(@NOREFERENCIA,'') NOT IN ('CEUNIFPE','VARIOS','CEUNIFICADO','MASIVA','UNIWEB') 
		BEGIN
			SET @MENSAJE_ERROR='La factura es de procedencia '+@PROCEDENCIA+' y no tiene el paciente vinculado >> @NOREFERENCIA = '+COALESCE(@NOREFERENCIA,'')
			RAISERROR (@MENSAJE_ERROR, 16, 1);
		END
		
		IF @PROCEDENCIA IN ('SALUD','CE','CI') AND COALESCE(@NOREFERENCIA,'')='' AND COALESCE(@NOREFERENCIA,'') NOT IN ('CEUNIFPE','VARIOS','CEUNIFICADO','MASIVA','UNIWEB')
		BEGIN
			IF @PROCEDENCIA='SALUD' SET @MENSAJE_ERROR='La factura es de procedencia '+@PROCEDENCIA+' y no tiene el número de admisión vinculado al encabezado (HADM.NOADMISION - FTR.NOREFERENCIA) '
			IF @PROCEDENCIA='CE' SET @MENSAJE_ERROR='La factura es de procedencia '+@PROCEDENCIA+' y no tiene el número de la autorización vinculada al encabezado (AUT.NOAUT - FTR.NOREFERENCIA)'
			IF @PROCEDENCIA='CI' SET @MENSAJE_ERROR='La factura es de procedencia '+@PROCEDENCIA+' y no tiene el número de la cita vinculada al encabezado (CIT.CONSECUTIVO - FTR.NOREFERENCIA)'
			RAISERROR (@MENSAJE_ERROR, 16, 1);
		END
		IF @IPS=1 -- Aplica Resolución No. 084 de 2021
		BEGIN
			IF COALESCE(@IDSGSSS,'')='' SELECT TOP 1 @IDSGSSS=IDSGSSS FROM CIA WHERE COMPANIA='01'
			IF COALESCE(@IDSGSSS,'')=''
				RAISERROR ('La sede en la que corresponde el documento electrónico no tiene configurado el código del Sistema General de Seguridad Social en Salud (SGSSS)', 16, 1);  

			IF COALESCE(@IDPLAN,'')=''
				RAISERROR ('La factura no tiene vinculado un plan', 16, 1);  
				
			SELECT @TIPOVOLUNTARIO=TIPOVOLUNTARIO FROM PLN WHERE IDPLAN=@IDPLAN

			IF COALESCE(@TIPOVOLUNTARIO,'')=''
			BEGIN
				SET @MENSAJE_ERROR='El plan '+@IDPLAN+' no tiene configurado un tipo de plan voluntario de salud'
				RAISERROR (@MENSAJE_ERROR, 16, 1);  
			END

			IF @PROCEDENCIA='SALUD' SELECT @NOAUTORIZACION=dbo.FNK_LIMPIATEXTO(NOAUTORIZACION, 'A-Z0-9'), @NOPOLIZA=dbo.FNK_LIMPIATEXTO(HACTRAN.NOPOLIZA, 'A-Z0-9') 
			FROM HADM LEFT JOIN HACTRAN ON HACTRAN.CNSHACTRAN=HADM.CNSHACTRAN WHERE NOADMISION=@NOREFERENCIA -- HADM

			IF @PROCEDENCIA='CE' SELECT @NOAUTORIZACION=dbo.FNK_LIMPIATEXTO(NUMAUTORIZA, 'A-Z0-9'), @NOPOLIZA=dbo.FNK_LIMPIATEXTO(HACTRAN.NOPOLIZA, 'A-Z0-9')
			FROM AUT LEFT JOIN HACTRAN ON HACTRAN.CNSHACTRAN=AUT.CNSHACTRAN  WHERE NOAUT=@NOREFERENCIA -- AUT

			IF @PROCEDENCIA='CI' SELECT @NOAUTORIZACION=dbo.FNK_LIMPIATEXTO(NOAUTORIZACION, 'A-Z0-9'), @NOPOLIZA=dbo.FNK_LIMPIATEXTO(HACTRAN.NOPOLIZA, 'A-Z0-9')
			FROM CIT LEFT JOIN HACTRAN ON HACTRAN.CNSHACTRAN=CIT.CNSHACTRAN WHERE CONSECUTIVO=@NOREFERENCIA -- CIT

			-- Autorizaciones de MIPRES
			SELECT @AUTORIZACIONES_MIPRES=STUFF((SELECT ', '+NUMAUTORIZA FROM (
				SELECT NUMAUTORIZA=COALESCE(DBO.FNK_LIMPIATEXTO(NUMAUTORIZA,'A-Z0-9'),'') FROM HJNOPOS  WHERE NOADMISION=@NOREFERENCIA
			)X WHERE LEN(NUMAUTORIZA)>10
			GROUP BY NUMAUTORIZA 
			FOR XML PATH('')),1,2,'')

			-- Numero de contrato vinculado al plan del tercero asociado a la factura
			SELECT @NROCONTRATO=IIF(COALESCE(CNT.NOPOLIZA,'')<>'',CNT.NOPOLIZA,IIF(COALESCE(CNT.IDALTERNA,'')<>'',CNT.IDALTERNA,COALESCE(PPT.NROCONTRATO,'')))
				,   @MODALIDAD_CNT= CASE WHEN COALESCE(MODALIDAD, '') IN ('01','02','03','04') 
                                     THEN MODALIDAD
                                     ELSE 
					                          CASE COALESCE(CAPITADO, 0) 
						                          WHEN 1  THEN CASE WHEN @TIPOCAP <> 4 THEN IIF(COALESCE(PGP, 0) = 1,'02','03')   ELSE '04' END -- Pago po capitacion // TIPOCAP 4 -> oFTALMO PIÑERES
						                          WHEN 0 THEN
							                          CASE  WHEN COALESCE(PGP, 0) = 1             THEN '02' -- Pago global prospectivo
							                                WHEN COALESCE(PPT.PAQUETIZADO,0) = 1  THEN '01' -- 20250618 -- STORRES -- Contrato paquetizado - SE AGREGA PARA QUE EL SISTEMA TOME LOS VALORES EN CERO DEL PAQUETE.
                                                     ELSE '04' -- Pago por evento¿
							                          END
					                          END
                               END
				,@CODSER = PPT.IMPRIMEIDALTERNA
			FROM FTR INNER JOIN PPT ON PPT.IDTERCERO=FTR.IDTERCERO AND PPT.IDPLAN=FTR.IDPLAN
			          LEFT JOIN CNT ON CNT.IDCONTRATO=PPT.IDCONTRATO 
			WHERE CNSFCT = @CNSFCT

			SELECT @NROCONTRATO = dbo.FNK_LIMPIATEXTO(@NROCONTRATO,'0-9 A-Z().;:,-/_')
				,@MODALIDAD_CNT = dbo.FNK_LIMPIATEXTO(@MODALIDAD_CNT,'0-9 A-Z().;:,-')
				,@CODSER = dbo.FNK_LIMPIATEXTO(@CODSER,'0-9 A-Z().;:,-')

			IF COALESCE(@MODALIDAD_CNT, '') = '' SELECT @MODALIDAD_CNT = '04' 

			SELECT @DESC_MODALIDAD_CNT = DESCRIPCION
			FROM TGEN
			WHERE TABLA='CNT' AND CAMPO='modalidadPago' AND CODIGO = @MODALIDAD_CNT
			
		END
		BEGIN -- Persona de Contacto
			SELECT @NOMBRE_CONTACTO=DBO.FNK_LIMPIATEXTO(DESCRIPCION,'A-Z0-9 .') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='CONTACTO' AND CODIGO='NOMBRE'
			SELECT @TELEFONO_CONTACTO=DBO.FNK_LIMPIATEXTO(DESCRIPCION,'0-9') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='CONTACTO' AND CODIGO='TELEFONO'
			SELECT @EMAIL_CONTACTO=DBO.FNK_LIMPIATEXTO(DESCRIPCION,'a-zA-Z0-9@._') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='CONTACTO' AND CODIGO='EMAIL'
			SELECT @FAX_CONTACTO=DBO.FNK_LIMPIATEXTO(COALESCE(DESCRIPCION,''),'0-9)(') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='CONTACTO' AND CODIGO='FAX'
			IF COALESCE(@NOMBRE_CONTACTO,'')='' RAISERROR ('Nombre de contacto de OFE es obligatorio. (TGEN => ''FDIAN'', ''CONTACTO'', ''NOMBRE'')', 16, 1); 
			IF COALESCE(@TELEFONO_CONTACTO,'')='' RAISERROR ('Teléfono de contacto de OFE es obligatorio. (TGEN => ''FDIAN'', ''CONTACTO'', ''TELEFONO'')', 16, 1); 
			IF COALESCE(@EMAIL_CONTACTO,'')='' RAISERROR ('Email de contacto de OFE es obligatorio. (TGEN => ''FDIAN'', ''CONTACTO'', ''EMAIL'')', 16, 1); 
		END
		BEGIN -- Adquiriente
			SELECT @NIT_ADQUIRIENTE=COALESCE(DBO.FNK_LIMPIATEXTO(TER.NIT,'0-9a-z'),''), @DV_ADQUIRIENTE=COALESCE(DBO.FNK_LIMPIATEXTO(COALESCE(TER.DV,''),'0-9'),''), @RAZONSOCIAL_ADQUIRIENTE=DBO.FNK_LIMPIATEXTO(TER.RAZONSOCIAL,'0-9 A-Z().;:,'), @CIUDAD_ADQUIRIENTE=COALESCE(CIU.HOMOLOGODIAN,TER.CIUDAD), @DIRADQUI=dbo.FNK_LIMPIATEXTO(TER.DIRECCION, '0-9 A-Z().;:,') 
				,@TELCONTACTOADQUI=DBO.FNK_LIMPIATEXTO(COALESCE(TER.TELEFONOS,''),'0-9'), @FAXCONTACTOADQUI=COALESCE(TER.FAX,'')
				,@EMAIL_ADQUIRIENTE=DBO.FNK_LIMPIATEXTO(COALESCE(TER.EMAIL,TER.EMAIL_RL,TER.EMAIL_TH,@EMAIL_CONTACTO,''),'a-zA-Z0-9@._')
				,@CODRESPFISCALADQ='R-99-PN' --COALESCE(TER.COD_RESP_FISCAL,'R-99-PN') --Nota: Para el consumidor final se debe informar el cógido "R-99-PN", Pág 44 del anexo técnico
				,@NOMCIUADQUI=DBO.FNK_LIMPIATEXTO(CIU.NOMBRE,'A-Z0-9 .,-_'), @CODDEPTOADQUI=DEP.COD_DIAN
				,@CODPOSTALADQUI = COALESCE(CIU.CODPOSTAL,CIU.CIUDAD,'')
			FROM FTR INNER JOIN TER ON TER.IDTERCERO=FTR.IDTERCERO 
			LEFT JOIN CIU ON CIU.CIUDAD=TER.CIUDAD
			LEFT JOIN DEP ON DEP.DPTO=CIU.DPTO
			WHERE CNSFCT=@CNSFCT
							   
			IF @EMAIL_ADQUIRIENTE='' SET @EMAIL_ADQUIRIENTE=@EMAIL_CONTACTO
			IF @TELCONTACTOADQUI='' SET @TELCONTACTOADQUI=@TELEFONO_CONTACTO

			-- Eliminar caracteres raros de email del adquiriente
			select @EMAIL_ADQUIRIENTE=dbo.FNK_LIMPIATEXTO(@email_adquiriente,'a-zA-Z0-9@._')
				
			SELECT @TIPO_PERSONA_ADQUIRIENTE=CASE WHEN TIPO_ID='NIT' THEN 1 ELSE 2 END 
				,@NOMCONTACTOADQUI=@RAZONSOCIAL_ADQUIRIENTE
				,@schemeName_ADQUIRIENTE=(SELECT TOP 1 DATO1 FROM TGEN WHERE TABLA='GENERAL' AND CAMPO='TIPOIDENT' AND CODIGO=TER.TIPO_ID)
			FROM TER INNER JOIN FTR ON FTR.IDTERCERO=TER.IDTERCERO
			WHERE FTR.CNSFCT=@CNSFCT


			IF COALESCE(@CODDEPTOADQUI,'')=''
			BEGIN
				SET @MENSAJE_ERROR='El código del departamento de la ciudad de la dirección del adquiriente de la factura '+@N_FACTURA+' es incorrecto'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			IF COALESCE(@NIT_ADQUIRIENTE,'')=''
			BEGIN
				SET @MENSAJE_ERROR='NIT del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			IF COALESCE(@RAZONSOCIAL_ADQUIRIENTE,'')='' 
			BEGIN
				--RAISERROR ('Razón social del adquiriente sin configurar', 16, 1); 
				SET @MENSAJE_ERROR='Razón social del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			IF COALESCE(@CIUDAD_ADQUIRIENTE,'')='' 
			BEGIN
				SET @MENSAJE_ERROR='Ciudad del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			IF COALESCE(@DIRADQUI,'')=''
			BEGIN
				SET @MENSAJE_ERROR='Dirección del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			IF COALESCE(@TELCONTACTOADQUI,'')='' 
			BEGIN
				SET @MENSAJE_ERROR='Teléfono de contacto del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			IF COALESCE(@EMAIL_ADQUIRIENTE,'')='' 
			BEGIN
				SET @MENSAJE_ERROR='Email del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			IF COALESCE(@CODRESPFISCALADQ,'')=''
			BEGIN
				SET @MENSAJE_ERROR='Responsabilidad fiscal del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			IF COALESCE(@CODPOSTALADQUI,'')='' RAISERROR ('Codigo postal de la dirección del adquiriente es obligatorio', 16, 1); 
		END -- Adquiriente
		SELECT @SoftwareSecurityCode=@SoftwareID+@SoftwarePIN+@PREFIJO+@FACTURA -- SoftwareSecurityCode:= SHA-384 (Id Software + Pin + NroDocumento[Con Prefijo])
		IF @AMBIENTE=2 AND COALESCE(@TESTSETID,'')='' RAISERROR ('El identificador de pruebas (TestSetId) es obligatorio en el ambiente de pruebas. (TGEN => ''FDIAN'', ''SOFTWARE'', ''TESTSETID'')', 16, 1); 
		BEGIN -- Calcular el cufe 
			SELECT @CUFE=dbo.FNK_GENERAR_CUFE_CUDE(
				@TIPODOC, -- FV: Factura de Venta, NC: Nota de Crédito, ND: Nota de Débito
				@CNSFCT,
				@NITFACTU,
				@CLAVE_TECNICA,
				@PREFIJO+@CNSACTUAL,
				@AMBIENTE -- 1.- Producción, 2.- Pruebas
			)
		END

		IF COALESCE(@NOTAS,'')='' SET @NOTAS=@CUFE

		SET @QR_CODE=DBO.FNK_QRCODE(@PREFIJO+@FACTURA)
		IF COALESCE(@QR_CODE,'')=''
			SELECT @QR_CODE='NroFactura='+@PREFIJO+@FACTURA+', NitFacturador='+@NITFACTU+', NitAdquiriente='+@NIT_ADQUIRIENTE+', FechaFactura='+REPLACE(CONVERT(VARCHAR,@FECHA_FACT,102),'.','-')+', ValorTotalFactura='+CAST(@VR_FACTURA AS VARCHAR)--+', CUFE='+@CUFE
			
		-- ENCABEZADO
		SET @XML='<?xml version="1.0" encoding="UTF-8" standalone="no"?>'
		SET @XML+=@E+'<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:sts="dian:gov:co:facturaelectronica:Structures-2-1" xmlns:xades="http://uri.etsi.org/01903/v1.3.2#" xmlns:xades141="http://uri.etsi.org/01903/v1.4.1#" xsi:schemaLocation="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2     http://docs.oasis-open.org/ubl/os-UBL-2.1/xsd/maindoc/UBL-Invoice-2.1.xsd" xmlns:salud="minSalud:gov:co:facturaelectronica:Structures-2-1">'
		SET @XML+=@E+@T+'<ext:UBLExtensions>'
		BEGIN -- Datos de la resolucion
			SET @XML+=@E+@T+@T+'<ext:UBLExtension>'
			SET @XML+=@E+@T+@T+@T+'<ext:ExtensionContent>'
			SET @XML+=@E+@T+@T+@T+@T+'<sts:DianExtensions>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<sts:InvoiceControl>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<sts:InvoiceAuthorization>'+@CNSRESOL+'</sts:InvoiceAuthorization>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<sts:AuthorizationPeriod>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+'<cbc:StartDate>'+REPLACE(CONVERT(VARCHAR,@FINIRESOL,102),'.','-')+'</cbc:StartDate>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+'<cbc:EndDate>'+REPLACE(CONVERT(VARCHAR,@FFINRESOL,102),'.','-')+'</cbc:EndDate>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'</sts:AuthorizationPeriod>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<sts:AuthorizedInvoices>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+'<sts:Prefix>'+@PREFIJO+'</sts:Prefix>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+'<sts:From>'+@CNSINICIAL+'</sts:From>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+'<sts:To>'+@CNSFINAL+'</sts:To>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'</sts:AuthorizedInvoices>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'</sts:InvoiceControl>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<sts:InvoiceSource>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:IdentificationCode listAgencyID="6" listAgencyName="United Nations Economic Commission for Europe" listSchemeURI="urn:oasis:names:specification:ubl:codelist:gc:CountryIdentificationCode-2.1">CO</cbc:IdentificationCode>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'</sts:InvoiceSource>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<sts:SoftwareProvider>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<sts:ProviderID schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeID="'+@DV_FACTURADOR+'" schemeName="'+COALESCE(@schemeName_FACTURADOR,'31')+'">'+@NITFACTU+'</sts:ProviderID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<sts:SoftwareID schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)">'+@SoftwareID+'</sts:SoftwareID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'</sts:SoftwareProvider>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<sts:SoftwareSecurityCode schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)">'+@SoftwareSecurityCode+'</sts:SoftwareSecurityCode>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<sts:AuthorizationProvider>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<sts:AuthorizationProviderID schemeID="4" schemeName="31" schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)">'+@NIT_DIAN+'</sts:AuthorizationProviderID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'</sts:AuthorizationProvider>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<sts:QRCode>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+@QR_CODE
			SET @XML+=@E+@T+@T+@T+@T+@T+'</sts:QRCode>'
			SET @XML+=@E+@T+@T+@T+@T+'</sts:DianExtensions>'
			SET @XML+=@E+@T+@T+@T+'</ext:ExtensionContent>'
			SET @XML+=@E+@T+@T+'</ext:UBLExtension>'
		END -- FIN DATOS DE RESOLUCION
		BEGIN -- Firma electronica 
			SET @XML+=@E+@T+@T+'<ext:UBLExtension>'
			SET @XML+=@E+@T+@T+@T+'<ext:ExtensionContent></ext:ExtensionContent>' -- Aquí va la firma electronica
			SET @XML+=@E+@T+@T+'</ext:UBLExtension>'
		END -- Fin de firma electronica
		PRINT '@IPS '+CAST(COALESCE(@IPS,2) AS VARCHAR(4))
		IF @IPS=1 -- Datos para el sector salud
		BEGIN 
			PRINT '-- Datos para el sector salud'
			DECLARE @TIPO_DOC VARCHAR(2), @TIPO_DOC_DENOMINACION VARCHAR(100), @DOCIDAFILIADO VARCHAR(20)
			,@PAPELLIDO VARCHAR(30), @SAPELLIDO VARCHAR(30), @PNOMBRE VARCHAR(30), @SNOMBRE VARCHAR(30)
			,@TIPOUSUARIO VARCHAR(50)

			SELECT @DOCIDAFILIADO=DBO.FNK_LIMPIATEXTO(DOCIDAFILIADO,'0-9A-Z')
				,@PAPELLIDO=DBO.FNK_LIMPIATEXTO(PAPELLIDO,'A-Z ')
				,@SAPELLIDO=DBO.FNK_LIMPIATEXTO(SAPELLIDO,'A-Z ')
				,@PNOMBRE	= DBO.FNK_LIMPIATEXTO(PNOMBRE,'A-Z ')
				,@SNOMBRE	= DBO.FNK_LIMPIATEXTO(SNOMBRE,'A-Z ')
				,@TIPOUSUARIO = COALESCE(TIPOUSUARIO, '05')
			FROM AFI WHERE IDAFILIADO=@IDAFILIADO
		
			-- Tabla de referencia: https://web.sispro.gov.co/WebPublico/Consultas/ConsultarDetalleReferenciaBasica.aspx?Code=RIPSTipoUsuarioVersion2
			SELECT @DESC_TIPOUSUARIO = DESCRIPCION
			FROM TGEN WHERE TABLA='AFI' AND CAMPO='TIPO_USUARIO' AND CODIGO=@TIPOUSUARIO

			SELECT @TIPO_DOC=CODIGO, @TIPO_DOC_DENOMINACION=DESCRIPCION 
			FROM ( SELECT 'CC' CODIGO, 'Cédula de ciudadanía' DESCRIPCION UNION ALL
			SELECT 'CE', 'Cédula de extranjería' UNION ALL
			SELECT 'CD', 'Carné diplomático' UNION ALL
			SELECT 'PA', 'Pasaporte' UNION ALL
			SELECT 'SC', 'Salvoconducto' UNION ALL
			SELECT 'PE', 'Permiso especial de permanencia' UNION ALL
			SELECT 'RC', 'Registro civil de nacimiento' UNION ALL
			SELECT 'TI', 'Tarjeta de identidad' UNION ALL
			SELECT 'CN', 'Certificado de nacido vivo' UNION ALL
			SELECT 'AS', 'Adulto sin identificar' UNION ALL
			SELECT 'MS', 'Menor sin identificar' UNION ALL
			SELECT 'DE', 'Documento extranjero' UNION ALL
			SELECT 'SI', 'Sin identificación') AS #T WHERE CODIGO=dbo.FNK_TIPODOC_POREDAD(@IDAFILIADO)

			IF COALESCE(@TIPO_DOC,'')='' OR COALESCE(@TIPO_DOC_DENOMINACION,'')=''
				SELECT @TIPO_DOC='SI', @TIPO_DOC_DENOMINACION='Sin identificación'
			SELECT @CODHABILITA = CODHABILITA FROM SED WHERE IDSEDE=@IDSEDE

		  IF LTRIM(RTRIM(DBO.FNK_VALORVARIABLE('IDSEDEPRINCIPAL')))<>''
		  BEGIN
			 SELECT @IDSEDEPPAL=LTRIM(RTRIM(DBO.FNK_VALORVARIABLE('IDSEDEPRINCIPAL')))
			 IF EXISTS(SELECT  * FROM SED WHERE IDSEDE=@IDSEDEPPAL AND COALESCE(CODHABILITA,'')<>'')
			 BEGIN
				SELECT @CODHABILITA = CODHABILITA FROM SED WHERE IDSEDE=@IDSEDEPPAL
			 END
		  END

			SET @XML+=@E+@T+@T+'<ext:UBLExtension>'
			SET @XML+=@E+@T+@T+@T+'<ext:ExtensionContent>' 
			SET @XML+=@E+@T+@T+@T+@T+'<CustomTagGeneral>' 

			BEGIN -- Datos correspondiente al usuario (Paciente y Usuario de la factura)
				SET @XML+=@E+@T+@T+@T+@T+@T+'<Name>Responsable</Name>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+'<Value>www.minsalud.gov.co</Value>' 
				--SET @XML+=@E+@T+@T+@T+@T+@T+'<Name>Tipo, Identificador:año del acto administrativo</Name>' 
				--SET @XML+=@E+@T+@T+@T+@T+@T+'<Value>Resolución 0506:2021</Value>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+'<Interoperabilidad>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<Group schemeName="Sector Salud">' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+'<Collection schemeName="Usuario">' 

				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>CODIGO_PRESTADOR</Name>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+LEFT(COALESCE(@CODHABILITA, ''),10)+'</Value>'  --STORRES
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 
				IF  COALESCE(@NOREFERENCIA,'') NOT IN ('CEUNIFPE','VARIOS','CEUNIFICADO','MASIVA','UNIWEB') AND @PROCEDENCIA NOT IN ('FINANCIERO') 
				BEGIN
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>TIPO_DOCUMENTO_IDENTIFICACION</Name>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value schemeName="salud_identificación.gc" schemeID="'+@TIPO_DOC+'">'+
						COALESCE((SELECT TOP 1 DESCRIPCION FROM TGEN WHERE TABLA = 'General' AND CAMPO='TIPOIDENT' AND CODIGO=@TIPO_DOC),'')
						+'</Value>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>'
			
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>NUMERO_DOCUMENTO_IDENTIFICACION</Name>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+@DOCIDAFILIADO+'</Value>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 

					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>PRIMER_APELLIDO</Name>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+coalesce(@PAPELLIDO,'')+'</Value>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 

					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>SEGUNDO_APELLIDO</Name>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+coalesce(@SAPELLIDO,'')+'</Value>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 

					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>PRIMER_NOMBRE</Name>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+coalesce(@PNOMBRE,'')+'</Value>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 

					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>SEGUNDO_NOMBRE</Name>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+coalesce(@SNOMBRE,'')+'</Value>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 

					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>TIPO_USUARIO</Name>' 
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value schemeName="salud_tipo_usuario.gc" schemeID="'+coalesce(@TIPOUSUARIO,'')+'">'+coalesce(@DESC_TIPOUSUARIO,'')+'</Value>'
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 
				END
				PRINT 'DENTRO BUSCANDO MODALIDAD PAGO'
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>MODALIDAD_PAGO</Name>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value schemeName="salud_modalidad_pago.gc" schemeID="'+coalesce(@MODALIDAD_CNT,'')+'">'+COALESCE(@DESC_MODALIDAD_CNT, '')+'</Value>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 

				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>NUMERO_AUTORIZACION</Name>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+COALESCE(@NOAUTORIZACION,'')+'</Value>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 

				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>NUMERO_MIPRES</Name>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+COALESCE(@AUTORIZACIONES_MIPRES,'')+'</Value>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>'

				SELECT @CobertuPlanBeneficio = DESCRIPCION 
				FROM TGEN 
				WHERE TABLA='PLN' 
				AND CAMPO='CobertuPlanBeneficio' 
				AND CODIGO=@TIPOVOLUNTARIO

				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>COBERTURA_PLAN_BENEFICIOS</Name>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value schemeName="salud_cobertura.gc" schemeID="'+COALESCE(@TIPOVOLUNTARIO,'')+'">'+COALESCE(@CobertuPlanBeneficio,'')+'</Value>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>'
			   IF COALESCE(@NOPOLIZA,'')<>''
            BEGIN
               SELECT @NROCONTRATO=''
            END 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>NUMERO_CONTRATO</Name>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+COALESCE(@NROCONTRATO,'')+'</Value>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 

				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>NUMERO_POLIZA</Name>' 
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+COALESCE(@NOPOLIZA,'')+'</Value>'  -- STORRES - 20250618 -- Verificar para el futuro. Actuamnete esta en NOTIFICACION.
				SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 

            DECLARE @VLR_PCOMPA DECIMAL(14,2), @VLR_COP DECIMAL(14,2) ,@VLR_COPAGO DECIMAL(14,2)
            BEGIN -- Solicitud Kevin Rodriguez
			      BEGIN              
				      SELECT @COD_ANTICIPO = MOC.HOMOLOGODIAN
				      FROM FTR 
				      INNER JOIN PPT ON PPT.IDPLAN = FTR.IDPLAN AND PPT.IDTERCERO = FTR.IDTERCERO
				      INNER JOIN MOC ON MOC.IDMODELOPC = IIF(FTR.PROCEDENCIA = 'SALUD', PPT.IDMODELOPCH, PPT.IDMODELOPCA) 
				      WHERE COALESCE(VALORCOPAGO, 0)>0
			         AND FTR.N_FACTURA=@N_FACTURA

				      IF @PROCEDENCIA IN ('SALUD','CE','CI') AND COALESCE(@VALORCOPAGO, 0) > 0 AND COALESCE(@COD_ANTICIPO, '') = ''
				      BEGIN
					      SET @MENSAJE_ERROR='La factura '+@N_FACTURA+' de procedencia '+@PROCEDENCIA+', posee copago (Anticipo) sin configurar (Tabla MOC, Campo: HOMOLOGODIAN)'
					      RAISERROR (@MENSAJE_ERROR, 16, 1); 
				      END

				      SELECT @COD_ANTICIPO = IIF(COALESCE(@COD_ANTICIPO, '')='', '01', @COD_ANTICIPO)

			      END
		         IF COALESCE(@COD_ANTICIPO,'')<>''
		         BEGIN
			         SELECT  @NOM_ANTICIPO=LEFT(COALESCE(TGEN.DESCRIPCION,'COPAGOS'),100) FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='MODELOS_COPAGO' AND CODIGO=@COD_ANTICIPO
		         END
               IF EXISTS(SELECT * FROM PLN WHERE IDPLAN=@IDPLAN AND TIPOSISTEMA='Prepagado') 
               BEGIN
                  SELECT  @VLR_PCOMPA = SUM(VLR_COPAGOS) FROM FTRD INNER JOIN FTR ON FTR.CNSFCT=CNSFTR
                  INNER JOIN SER ON FTRD.REFERENCIA=SER.IDSERVICIO
                  INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
                  WHERE FTR.N_FACTURA=@N_FACTURA 
				      SET @COD_ANTICIPO = '03'
				      SELECT  @NOM_ANTICIPO=LEFT(COALESCE(TGEN.DESCRIPCION,'COPAGOS'),100) FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='MODELOS_COPAGO' AND CODIGO=@COD_ANTICIPO
                  IF COALESCE(@VLR_PCOMPA,0)>0
                  BEGIN
				         SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					      SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>PAGOS_COMPARTIDOS</Name>' 
					      SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+CAST(COALESCE(@VLR_PCOMPA,0)+COALESCE(@VLR_COP,0) AS VARCHAR)+'</Value>' 
					      SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 
                  END
                  SELECT @VLR_COP=0
               END
               ELSE
               BEGIN
			         IF EXISTS(   SELECT 1 FROM FTRD INNER JOIN FTR ON FTR.CNSFCT=CNSFTR
                        INNER JOIN SER ON FTRD.REFERENCIA=SER.IDSERVICIO
                        INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
                     WHERE FTR.N_FACTURA=@N_FACTURA --AND FTR.PROCEDENCIA = 'SALUD' 
                     AND RIPS_CP.ARCHIVO='AC' 
                     AND COALESCE(FTRD.VLR_COPAGOS,0)>0      )
                  BEGIN -- FEV-RIPS Resol. 1036 de 2022 Las consultas en facturas de procedencia asistencial (archivo AC) 
				         PRINT 'ES SALUD, POSEE CONSULTAS, VOY A DIVIDIR LOS COPAGOS'
                     SELECT @VLR_COP = SUM(VLR_COPAGOS) FROM FTRD INNER JOIN FTR ON FTR.CNSFCT=CNSFTR
                        INNER JOIN SER ON FTRD.REFERENCIA=SER.IDSERVICIO
                        INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
                     WHERE FTR.N_FACTURA=@N_FACTURA --AND FTR.PROCEDENCIA = 'SALUD' 
                     AND RIPS_CP.ARCHIVO='AC' 
				         PRINT 'VOY CON COPAGOS EN JOSE MANUEL AC'+STR(@VLR_COP)
                     IF  @VLR_COP >0
                     BEGIN
                        IF EXISTS(SELECT * FROM PLN WHERE IDPLAN=@IDPLAN AND TIPOSISTEMA='Contributivo') 
                        BEGIN
                           SET @VLR_MODERAAC=@VLR_COP
				             --  SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					            --SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>CUOTA_MODERADORA</Name>' 
					            --SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+CAST(COALESCE(@VALORMODERADORA,0) AS VARCHAR)+'</Value>' 
					            --SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 
                        END
                        ELSE
                        BEGIN
                           PRINT ''
				             --  SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					            --SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>COPAGO</Name>' 
					            --SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+CAST(COALESCE(@VLR_COP,0) AS VARCHAR)+'</Value>' 
					            --SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 
                        END
                     END
                     PRINT 'CCREO QUE POR ACA'
                     IF @PROCEDENCIA<>'FINANCIERO'
                     BEGIN
                        PRINT 'DCXDFDFDF'
                        IF EXISTS(SELECT * FROM PLN WHERE IDPLAN=@IDPLAN AND TIPOSISTEMA<>'Prepagado') 
                        BEGIN                          
                           SELECT @VLR_COPAGOAC=SUM(X.VLR_COPA),@VALORMODERADORA=SUM(VLR_MODE)
                           FROM (
                              SELECT VLR_MODE =  CASE WHEN  COALESCE(FTRD.TCOPAGO,'')='02' THEN  FTRD.VLR_COPAGOS WHEN  EXISTS(SELECT *  FROM MOCCD WHERE TIPODEPAGO='Moderadora' AND FTRD.VLR_COPAGOS=MOCCD.VALOR) AND COALESCE(FTRD.TCOPAGO,'') IN('','02') THEN FTRD.VLR_COPAGOS ELSE 0 END , 
                                     VLR_COPA = CASE WHEN  COALESCE(FTRD.TCOPAGO,'')='01'  THEN  FTRD.VLR_COPAGOS  WHEN NOT EXISTS(SELECT *  FROM MOCCD WHERE TIPODEPAGO='Moderadora' AND FTRD.VLR_COPAGOS=MOCCD.VALOR) AND COALESCE(FTRD.TCOPAGO,'') NOT IN('','02')  THEN FTRD.VLR_COPAGOS ELSE 0 END
                              FROM FTRD INNER JOIN FTR ON FTR.CNSFCT=CNSFTR
                                 INNER JOIN SER ON FTRD.REFERENCIA=SER.IDSERVICIO
                                 INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
                              WHERE FTR.N_FACTURA=@N_FACTURA 
                              AND RIPS_CP.ARCHIVO<>'AC'
                           )X
                           IF EXISTS(SELECT * FROM PLN WHERE IDPLAN=@IDPLAN AND TIPOSISTEMA='Subsidiado') OR @PROCEDENCIA='SALUD'
                           BEGIN
                              SELECT @VLR_COPAGO=COALESCE(@VLR_COPAGOAC,0)+COALESCE(@VLR_MODERAAC,0)
                              SELECT @VALORMODERADORA=0,@VLR_MODERAAC=0
                           END
                           IF COALESCE(@VLR_COPAGOAC,0)+COALESCE(@VLR_COP,0)>0
                           BEGIN
				                  SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					               SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>COPAGO</Name>' 
					               SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+CAST(ROUND(COALESCE(@VLR_COPAGOAC,0)+COALESCE(@VLR_COP,0),0) AS VARCHAR)+'</Value>' 
					               SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 
                           END
                           IF COALESCE(@VALORMODERADORA,0)+COALESCE(@VLR_MODERAAC,0)>0
                           BEGIN
				                  SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					               SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>CUOTA_MODERADORA</Name>' 
					               SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+CAST(ROUND(COALESCE(@VALORMODERADORA,0)+COALESCE(@VLR_MODERAAC,0),0) AS VARCHAR)+'</Value>' 
					               SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 
                           END
                        END
                     END
                     ELSE
                     BEGIN
				            IF COALESCE(@CAPITADA,0)=1 AND COALESCE(@TIPOCAP,0)=1 AND COALESCE(@COPAPROPIO,0)=1
                        BEGIN
					            SELECT  @COD_ANTICIPO='04',@NOM_ANTICIPO='ANTICIPO'                          
                        END
                        ELSE
                        BEGIN
                           IF COALESCE(@VALORMODERADORA,0)>0
                           BEGIN
                              SELECT  @COD_ANTICIPO='01',@NOM_ANTICIPO='COPAGO'
                           END
                        END
                        IF COALESCE(@VALORCOPAGO,0)>0
                        BEGIN
				               SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					            SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>COPAGO</Name>' 
					            SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+CAST(ROUND(COALESCE(@VALORCOPAGO,0),0) AS VARCHAR)+'</Value>' 
					            SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 
                        END
                        IF COALESCE(@VALORMODERADORA,0)>0
                        BEGIN
				               SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					            SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>CUOTA_MODERADORA</Name>' 
					            SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+CAST(ROUND(COALESCE(@VALORMODERADORA,0),0) AS VARCHAR)+'</Value>' 
					            SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 
                        END
				         END
			         END
               END
               IF DBO.FNK_VALORVARIABLE('XMLDIAN_DIS_INFOADIC') = 'SI'
               BEGIN
                  IF COALESCE(@VLR_PCOMPA,0)=0
                  BEGIN
				         SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					      SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>PAGOS_COMPARTIDOS</Name>' 
					      SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+CAST(COALESCE(@VLR_PCOMPA,0) AS VARCHAR)+'</Value>' 
					      SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 
                  END
                  IF COALESCE(@VLR_COPAGOAC,0)+COALESCE(@VLR_COP,0)=0
                  BEGIN
				         SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					      SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>COPAGO</Name>' 
					      SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+CAST(COALESCE(@VLR_COP,0) AS VARCHAR)+'</Value>' 
					      SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 
                  END
                  IF COALESCE(@VALORMODERADORA,0)+COALESCE(@VLR_MODERAAC,0)=0
                  BEGIN
				         SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					      SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>CUOTA_MODERADORA</Name>' 
					      SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+CAST(COALESCE(@VALORMODERADORA,0) AS VARCHAR)+'</Value>' 
					      SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 
                  END

                  SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
					   SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>CUOTA_RECUPERACION</Name>' 
					   SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>0.00</Value>' 
					   SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 

               END
				   SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'<AdditionalInformation>' 
				   SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Name>ELABORADO_POR</Name>' 
				   SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+@T+'<Value>'+COALESCE(@NOMBREUSUARIO,'')+'</Value>' 
				   SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+@T+'</AdditionalInformation>' 

				   SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+'</Collection>' 
				   SET @XML+=@E+@T+@T+@T+@T+@T+@T+'</Group>' 
				   SET @XML+=@E+@T+@T+@T+@T+@T+'</Interoperabilidad>'
			   END
--Query2
--Query2
			   SET @XML+=@E+@T+@T+@T+@T+'</CustomTagGeneral>' 
			   SET @XML+=@E+@T+@T+@T+'</ext:ExtensionContent>' 
			   SET @XML+=@E+@T+@T+'</ext:UBLExtension>'
		   END -- Fin de datos Sector Salud
	   END
		IF @IDMONEDA_DESTINO <> @IDMONEDA
		BEGIN
			SET @XML+=@E+@T+@T+'<ext:UBLExtension>'
			SET @XML+=@E+@T+@T+@T+'<ext:ExtensionContent>' 
			SET @XML+=@E+@T+@T+@T+@T+'<CustomTagGeneral>'

			DECLARE @FTR_VR_TOTAL DECIMAL(14,2)
			SELECT @FTR_VR_TOTAL = VR_TOTAL * @CalculationRate
			FROM	FTR 
			WHERE CNSFCT=@CNSFCT 

			SET @XML+=@E+@T+@T+@T+@T+@T+'<TotalesCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<FctConvCop>'+CAST(@FTR_VR_TOTAL AS VARCHAR)+'</FctConvCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<MonedaCop>'+@IDMONEDA_DESTINO+'</MonedaCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<SubTotalCop>'+CAST(@FTR_VR_TOTAL AS VARCHAR)+'</SubTotalCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<DescuentoDetalleCop>0.00</DescuentoDetalleCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<RecargoDetalleCop>0.00</RecargoDetalleCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<TotalBrutoFacturaCop>'+CAST(@FTR_VR_TOTAL AS VARCHAR)+'</TotalBrutoFacturaCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<TotIvaCop>0.00</TotIvaCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<TotIncCop>0.00</TotIncCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<TotBolCop>0.00</TotBolCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<ImpOtroCop>0.00</ImpOtroCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<MntImpCop>0.00</MntImpCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<TotalNetoFacturaCop>'+CAST(@FTR_VR_TOTAL AS VARCHAR)+'</TotalNetoFacturaCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<MntDctoCop>0.00</MntDctoCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<MntRcgoCop>0.00</MntRcgoCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<VlrPagarCop>'+CAST(@FTR_VR_TOTAL AS VARCHAR)+'</VlrPagarCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<ReteFueCop>0.00</ReteFueCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<ReteIvaCop>0.00</ReteIvaCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<ReteIcaCop>0.00</ReteIcaCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<TotAnticiposCop>0.00</TotAnticiposCop>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'</TotalesCop>'
		
			SET @XML+=@E+@T+@T+@T+@T+'</CustomTagGeneral>' 
			SET @XML+=@E+@T+@T+@T+'</ext:ExtensionContent>' 
			SET @XML+=@E+@T+@T+'</ext:UBLExtension>'
		END
		SELECT @XML+=@E+@T+'</ext:UBLExtensions>'
		BEGIN -- Tipo de operación y en que ambiente 
			SET @XML+=@E+@T+'<cbc:UBLVersionID>UBL 2.1</cbc:UBLVersionID>'
			SET @XML+=@E+@T+'<cbc:CustomizationID>'+IIF(@COPAGOIPS=1,'SS-CUFE',@TIPO_OPERACION)+'</cbc:CustomizationID>'
			SET @XML+=@E+@T+'<cbc:ProfileID>DIAN 2.1: Factura Electrónica de Venta</cbc:ProfileID>'
			SET @XML+=@E+@T+'<cbc:ProfileExecutionID>'+CAST(@AMBIENTE AS VARCHAR)+'</cbc:ProfileExecutionID>' -- 1: Producción, 2: Pruebas
		END
		BEGIN -- Otros datos de encabezado de la factura
			SET @XML+=@E+@T+'<cbc:ID>'+@PREFIJO+@FACTURA+'</cbc:ID>'
			SET @XML+=@E+@T+'<cbc:UUID schemeID="'+CAST(@AMBIENTE AS varchar)+'" schemeName="CUFE-SHA384">'+@CUFE+'</cbc:UUID>'
			SET @XML+=@E+@T+'<cbc:IssueDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT,102),'.','-')+'</cbc:IssueDate>'
			SET @XML+=@E+@T+'<cbc:IssueTime>'+CONVERT(VARCHAR,@HORA_FACT,108)+'-05:00</cbc:IssueTime>'
			SET @XML+=@E+@T+'<cbc:DueDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT_VENCE,102),'.','-')+'</cbc:DueDate>'
			SET @XML+=@E+@T+'<cbc:InvoiceTypeCode>'+@TIPO_DOCUMENTO+'</cbc:InvoiceTypeCode>'
			SET @XML+=@E+@T+'<cbc:Note>'+@NOTAS+' - '+@CUFE+'</cbc:Note>'
			SET @XML+=@E+@T+'<cbc:TaxPointDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT_VENCE,102),'.','-')+'</cbc:TaxPointDate>'
			SET @XML+=@E+@T+'<cbc:DocumentCurrencyCode>'+COALESCE(@IDMONEDA,'COP')+'</cbc:DocumentCurrencyCode>'
			SET @XML+=@E+@T+'<cbc:LineCountNumeric>@CANT_TOTAL_ITEMS</cbc:LineCountNumeric>'
			IF @FDESDE_FACT IS NOT NULL AND @FHASTA_FACT IS NOT NULL
			BEGIN
				SET @XML+=@E+@T+'<cac:InvoicePeriod>'
				SET @XML+=@E+@T+@T+'<cbc:StartDate>'+REPLACE(CONVERT(VARCHAR,@FDESDE_FACT,102),'.','-')+'</cbc:StartDate>'
				SET @XML+=@E+@T+@T+'<cbc:StartTime>00:00:00-05:00</cbc:StartTime>'
				SET @XML+=@E+@T+@T+'<cbc:EndDate>'+REPLACE(CONVERT(VARCHAR,@FHASTA_FACT,102),'.','-')+'</cbc:EndDate>'
				SET @XML+=@E+@T+@T+'<cbc:EndTime>23:59:59-05:00</cbc:EndTime>'
				SET @XML+=@E+@T+'</cac:InvoicePeriod>'
			END
		END
		BEGIN -- Datos de la sede donde se origina la factura
			SET @XML+=@E+@T+'<cac:AccountingSupplierParty>'
			SET @XML+=@E+@T+@T+'<cbc:AdditionalAccountID schemeAgencyID="195">'+@TIPO_PERSONA+'</cbc:AdditionalAccountID>' -- 1.- Persona Jurídica, 2.- Persona Natural 
			SET @XML+=@E+@T+@T+'<cac:Party>'
			SET @XML+=@E+@T+@T+@T+'<cac:PartyName>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:Name>'+@RSOCIALFACTU+'</cbc:Name>'
			SET @XML+=@E+@T+@T+@T+'</cac:PartyName>'
			SET @XML+=@E+@T+@T+@T+'<cac:PhysicalLocation>'
			SET @XML+=@E+@T+@T+@T+@T+'<cac:Address>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:ID>'+@CIUFACTU+'</cbc:ID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CityName>'+@NOMCIUFACTU+'</cbc:CityName>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CountrySubentity>'+@NOMCIUFACTU+'</cbc:CountrySubentity>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CountrySubentityCode>'+@CODDEPTOFACTU+'</cbc:CountrySubentityCode>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cac:AddressLine>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:Line>'+@DIRFACTU+'</cbc:Line>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'</cac:AddressLine>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cac:Country>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:IdentificationCode>CO</cbc:IdentificationCode>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:Name languageID="es">Colombia</cbc:Name>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'</cac:Country>'
			SET @XML+=@E+@T+@T+@T+@T+'</cac:Address>'
			SET @XML+=@E+@T+@T+@T+'</cac:PhysicalLocation>'
			-- DATOS DEL FACTURADOR ELECTRONICO
			SET @XML+=@E+@T+@T+@T+'<cac:PartyTaxScheme>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:RegistrationName>'+@RSOCIALFACTU+'</cbc:RegistrationName>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:CompanyID schemeID="'+@DV_FACTURADOR+'" schemeName="'+COALESCE(@schemeName_FACTURADOR,'31')+'" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeAgencyID="195">'+@NITFACTU+'</cbc:CompanyID>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:TaxLevelCode listName="48">'+@COD_RESPONSABILIDAD_FISCAL+'</cbc:TaxLevelCode>'
			SET @XML+=@E+@T+@T+@T+@T+'<cac:RegistrationAddress>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:ID>'+@CIUFACTU+'</cbc:ID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CityName>'+@NOMCIUFACTU+'</cbc:CityName>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CountrySubentity>'+@NOMCIUFACTU+'</cbc:CountrySubentity>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CountrySubentityCode>'+@CODDEPTOFACTU+'</cbc:CountrySubentityCode>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cac:AddressLine>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:Line>'+@DIRFACTU+'</cbc:Line>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'</cac:AddressLine>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cac:Country>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:IdentificationCode>CO</cbc:IdentificationCode>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:Name languageID="es">Colombia</cbc:Name>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'</cac:Country>'
			SET @XML+=@E+@T+@T+@T+@T+'</cac:RegistrationAddress>'
			SET @XML+=@E+@T+@T+@T+@T+'<cac:TaxScheme>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:ID>01</cbc:ID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Name>IVA</cbc:Name>'
			SET @XML+=@E+@T+@T+@T+@T+'</cac:TaxScheme>'
			SET @XML+=@E+@T+@T+@T+'</cac:PartyTaxScheme>'
			SET @XML+=@E+@T+@T+@T+'<cac:PartyLegalEntity>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:RegistrationName>'+@RSOCIALFACTU+'</cbc:RegistrationName>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:CompanyID schemeID="'+@DV_FACTURADOR+'" schemeName="'+COALESCE(@schemeName_FACTURADOR,'31')+'" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeAgencyID="195">'+@NITFACTU+'</cbc:CompanyID>'
			SET @XML+=@E+@T+@T+@T+@T+'<cac:CorporateRegistrationScheme>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:ID>'+@PREFIJO+'</cbc:ID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Name>'+@RSOCIALFACTU+'</cbc:Name>'
			SET @XML+=@E+@T+@T+@T+@T+'</cac:CorporateRegistrationScheme>'
			SET @XML+=@E+@T+@T+@T+'</cac:PartyLegalEntity>'
			SET @XML+=@E+@T+@T+@T+'<cac:Contact>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:Name>'+@NOMBRE_CONTACTO+'</cbc:Name>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:Telephone>'+@TELEFONO_CONTACTO+'</cbc:Telephone>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:Telefax>'+COALESCE(@FAX_CONTACTO,'')+'</cbc:Telefax>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:ElectronicMail>'+@EMAIL_CONTACTO+'</cbc:ElectronicMail>'
			SET @XML+=@E+@T+@T+@T+'</cac:Contact>'
			SET @XML+=@E+@T+@T+'</cac:Party>'
			SET @XML+=@E+@T+'</cac:AccountingSupplierParty>'
		END   
		BEGIN -- Datos del Adquiriente 
			SET @XML+=@E+@T+'<cac:AccountingCustomerParty>'
			SET @XML+=@E+@T+@T+'<cbc:AdditionalAccountID>'+CAST(@TIPO_PERSONA_ADQUIRIENTE AS VARCHAR)+'</cbc:AdditionalAccountID>'
			SET @XML+=@E+@T+@T+'<cac:Party>'
			IF LTRIM(RTRIM(@TIPO_PERSONA_ADQUIRIENTE))='2'
			BEGIN
				SET @XML+=@E+@T+@T+'<cac:PartyIdentification>'
				SET @XML+=@E+@T+@T+@T+'<cbc:ID schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeID="4" schemeName="31">222222222222</cbc:ID>'
				SET @XML+=@E+@T+@T+'</cac:PartyIdentification>'
			END
			SET @XML+=@E+@T+@T+@T+'<cac:PartyName>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:Name>'+@RAZONSOCIAL_ADQUIRIENTE+'</cbc:Name>'
			SET @XML+=@E+@T+@T+@T+'</cac:PartyName>'
			SET @XML+=@E+@T+@T+@T+'<cac:PhysicalLocation>'
			SET @XML+=@E+@T+@T+@T+@T+'<cac:Address>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:ID>'+@CIUDAD_ADQUIRIENTE+'</cbc:ID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CityName>'+@NOMCIUADQUI+'</cbc:CityName>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CountrySubentity>'+@NOMCIUADQUI+'</cbc:CountrySubentity>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CountrySubentityCode>'+@CODDEPTOADQUI+'</cbc:CountrySubentityCode>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cac:AddressLine>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:Line>'+COALESCE(@DIRADQUI,'')+'</cbc:Line>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'</cac:AddressLine>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cac:Country>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:IdentificationCode>CO</cbc:IdentificationCode>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:Name languageID="es">Colombia</cbc:Name>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'</cac:Country>'
			SET @XML+=@E+@T+@T+@T+@T+'</cac:Address>'
			SET @XML+=@E+@T+@T+@T+'</cac:PhysicalLocation>'
			SET @XML+=@E+@T+@T+@T+'<cac:PartyTaxScheme>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:RegistrationName>'+@RAZONSOCIAL_ADQUIRIENTE+'</cbc:RegistrationName>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:CompanyID schemeID="'+@DV_ADQUIRIENTE+'" schemeName="'+COALESCE(@schemeName_ADQUIRIENTE,'31')+'" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeAgencyID="195">'+@NIT_ADQUIRIENTE+'</cbc:CompanyID>'
			set @COD_RESPONSABILIDAD_FISCAL='R-99-PN'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:TaxLevelCode listName="48">'+@COD_RESPONSABILIDAD_FISCAL+'</cbc:TaxLevelCode>'
			SET @XML+=@E+@T+@T+@T+@T+'<cac:RegistrationAddress>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:ID>'+@CIUDAD_ADQUIRIENTE+'</cbc:ID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CityName>'+@NOMCIUADQUI+'</cbc:CityName>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CountrySubentity>'+@NOMCIUADQUI+'</cbc:CountrySubentity>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CountrySubentityCode>'+@CODDEPTOADQUI+'</cbc:CountrySubentityCode>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cac:AddressLine>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:Line>'+@DIRADQUI+'</cbc:Line>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'</cac:AddressLine>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cac:Country>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:IdentificationCode>CO</cbc:IdentificationCode>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:Name languageID="es">Colombia</cbc:Name>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'</cac:Country>'
			SET @XML+=@E+@T+@T+@T+@T+'</cac:RegistrationAddress>'
			SET @XML+=@E+@T+@T+@T+@T+'<cac:TaxScheme>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:ID>01</cbc:ID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Name>IVA</cbc:Name>'
			SET @XML+=@E+@T+@T+@T+@T+'</cac:TaxScheme>'
			SET @XML+=@E+@T+@T+@T+'</cac:PartyTaxScheme>'
			SET @XML+=@E+@T+@T+@T+'<cac:PartyLegalEntity>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:RegistrationName>'+@RAZONSOCIAL_ADQUIRIENTE+'</cbc:RegistrationName>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:CompanyID schemeID="'+@DV_ADQUIRIENTE+'" schemeName="'+COALESCE(@schemeName_ADQUIRIENTE,'31')+'" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeAgencyID="195">'+@NIT_ADQUIRIENTE+'</cbc:CompanyID>'
			SET @XML+=@E+@T+@T+@T+@T+'<cac:CorporateRegistrationScheme>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Name>'+@RAZONSOCIAL_ADQUIRIENTE+'</cbc:Name>' 
			SET @XML+=@E+@T+@T+@T+@T+'</cac:CorporateRegistrationScheme>'
			SET @XML+=@E+@T+@T+@T+'</cac:PartyLegalEntity>'
			SET @XML+=@E+@T+@T+@T+'<cac:Contact>'  -- FALTA VERIFICAR DE DONDE SACAR LOS DATOS DE CONTACTO DEL ADQUIRIENTE
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:Name>'+@NOMCONTACTOADQUI+'</cbc:Name>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:Telephone>'+@TELCONTACTOADQUI+'</cbc:Telephone>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:Telefax>'+@FAXCONTACTOADQUI+'</cbc:Telefax>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:ElectronicMail>'+@EMAIL_ADQUIRIENTE+'</cbc:ElectronicMail>'
			SET @XML+=@E+@T+@T+@T+'</cac:Contact>'
			SET @XML+=@E+@T+@T+'</cac:Party>'
			SET @XML+=@E+@T+'</cac:AccountingCustomerParty>'
		END
		BEGIN -- Metodo de pago
			SET @XML+=@E+@T+'<cac:PaymentMeans>'
			IF @IPS=1 SET @XML+=@E+@T+@T+'<cbc:ID schemeName="salud_modalidades_pago.gc" schemeID="'+COALESCE(@MODALIDAD_CNT,'')+'">'+CAST(@TIPOVENTA AS VARCHAR)+'</cbc:ID>' -- 1.- Contado, 2.- Crédito
			ELSE SET @XML+=@E+@T+@T+'<cbc:ID>'+CAST(@TIPOVENTA AS VARCHAR)+'</cbc:ID>' -- 1.- Contado, 2.- Crédito
			SET @XML+=@E+@T+@T+'<cbc:PaymentMeansCode>47</cbc:PaymentMeansCode>' -- 6.3.4.2. Medios de Pago: cbc:PaymentMeansCode -- Definir como se va a utilizar los medios de pago
			SET @XML+=@E+@T+@T+'<cbc:PaymentDueDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT_VENCE,102),'.','-')+'</cbc:PaymentDueDate>' -- Definir las fechas de vencimiento al momento de crear facturas porque es obligatorio para facturas a crédito
			SET @XML+=@E+@T+@T+'<cbc:PaymentID>'+@CNSFCT+'</cbc:PaymentID>' -- Definir el identificador del pago
			SET @XML+=@E+@T+'</cac:PaymentMeans>'
		END
		BEGIN -- Legalizaciones de depositos
			BEGIN -- Código del anticipo que lo exige la Super Salud ahora en el proceso de RIPS
				SELECT @COD_ANTICIPO = MOC.HOMOLOGODIAN
				FROM FTR 
				INNER JOIN PPT ON PPT.IDPLAN = FTR.IDPLAN AND PPT.IDTERCERO = FTR.IDTERCERO
				INNER JOIN MOC ON MOC.IDMODELOPC = IIF(FTR.PROCEDENCIA = 'SALUD', PPT.IDMODELOPCH, PPT.IDMODELOPCA) 
				WHERE COALESCE(VALORCOPAGO, 0)>0
			 AND FTR.N_FACTURA=@N_FACTURA

				IF @PROCEDENCIA IN ('SALUD','CE','CI') AND COALESCE(@VALORCOPAGO, 0) > 0 AND COALESCE(@COD_ANTICIPO, '') = ''
				BEGIN
					SET @MENSAJE_ERROR='La factura '+@N_FACTURA+' de procedencia '+@PROCEDENCIA+', posee copago (Anticipo) sin configurar (Tabla MOC, Campo: HOMOLOGODIAN)'
					RAISERROR (@MENSAJE_ERROR, 16, 1); 
				END

				SELECT @COD_ANTICIPO = IIF(COALESCE(@COD_ANTICIPO, '')='', '01', @COD_ANTICIPO)

			END
		  IF COALESCE(@COD_ANTICIPO,'')<>''
		  BEGIN
			 SELECT  @NOM_ANTICIPO=LEFT(COALESCE(TGEN.DESCRIPCION,'COPAGOS'),100) FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='MODELOS_COPAGO' AND CODIGO=@COD_ANTICIPO
		  END
         PRINT 'SEPARACION DE COPAGOS'
         SET @VLR_COPAGO=0
         IF EXISTS(SELECT * FROM PLN WHERE IDPLAN=@IDPLAN AND TIPOSISTEMA='Prepagado')
         BEGIN
            SELECT  @VLR_COPAGO = SUM(VLR_COPAGOS) FROM FTRD INNER JOIN FTR ON FTR.CNSFCT=CNSFTR
               INNER JOIN SER ON FTRD.REFERENCIA=SER.IDSERVICIO
               INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
            WHERE FTR.N_FACTURA=@N_FACTURA 

				SET @COD_ANTICIPO = '03'
				SELECT  @NOM_ANTICIPO=LEFT(COALESCE(TGEN.DESCRIPCION,'COPAGOS'),100) FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='MODELOS_COPAGO' AND CODIGO=@COD_ANTICIPO
				SET @XML+=@E+@T+'<cac:PrepaidPayment>' -- PAGOS COMPARTIDOS EN PLANES VOLUNTARIOS DE SALUD
				IF COALESCE(@COD_ANTICIPO, '') <> '' SET @XML+=@E+@T+@T+'<cbc:ID schemeID="' + @COD_ANTICIPO + '">'+@NOM_ANTICIPO+'</cbc:ID>'
				ELSE SET @XML+=@E+@T+@T+'<cbc:ID>PAGOS COMPARTIDOS EN PLANES VOLUNTARIOS DE SALUD</cbc:ID>'
				SET @XML+=@E+@T+@T+'<cbc:PaidAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(COALESCE(@VLR_COPAGO,0) AS VARCHAR)+'</cbc:PaidAmount>'
				SET @XML+=@E+@T+@T+'<cbc:ReceivedDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT,102),'.','-')+'</cbc:ReceivedDate>'
				SET @XML+=@E+@T+@T+'<cbc:PaidDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT,102),'.','-')+'</cbc:PaidDate>'
				SET @XML+=@E+@T+@T+'<cbc:PaidTime>'+CONVERT(VARCHAR,@HORA_FACT,108)+'-05:00</cbc:PaidTime>'
				SET @XML+=@E+@T+@T+'<cbc:InstructionID>Prepago recibido</cbc:InstructionID>'
				SET @XML+=@E+@T+'</cac:PrepaidPayment>'
            SELECT @VALORCOPAGO=@VLR_COPAGO
         END
         ELSE
         BEGIN
            IF @PROCEDENCIA <> 'FINANCIERO'
            BEGIN         
               SELECT @VALORCOPAGO =0,@VLR_MODERAAC=0,@VLR_COPAGOAC=0
			      IF EXISTS(
                  SELECT 1 FROM FTRD INNER JOIN FTR ON FTR.CNSFCT=CNSFTR
                     INNER JOIN SER ON FTRD.REFERENCIA=SER.IDSERVICIO
                     INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
                  WHERE FTR.N_FACTURA=@N_FACTURA 
                  AND RIPS_CP.ARCHIVO='AC' 
                  AND COALESCE(VLR_COPAGOS,0)>0
               )
               BEGIN -- FEV-RIPS Resol. 1036 de 2022 Las consultas en facturas de procedencia asistencial (archivo AC) 
				      PRINT 'ES SALUD, POSEE CONSULTAS, VOY A DIVIDIR LOS COPAGOS'

                  SELECT  @VLR_COPAGO = SUM(VLR_COPAGOS) FROM FTRD INNER JOIN FTR ON FTR.CNSFCT=CNSFTR
                     INNER JOIN SER ON FTRD.REFERENCIA=SER.IDSERVICIO
                     INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
                  WHERE FTR.N_FACTURA=@N_FACTURA 
                  AND RIPS_CP.ARCHIVO='AC' 
                  PRINT @PROCEDENCIA+ 'ACA JOSE DE ACA'
                  IF @VLR_COPAGO IS NULL 
                     SET @VLR_COPAGO =0

                  IF EXISTS(SELECT * FROM PLN WHERE IDPLAN=@IDPLAN AND TIPOSISTEMA='Contributivo') AND @VLR_COPAGO >0
                  BEGIN
                     SELECT @VLR_MODERAAC=@VLR_COPAGO
                     SELECT @VLR_COPAGOAC=0
                  END
                  IF EXISTS(SELECT * FROM PLN WHERE IDPLAN=@IDPLAN AND TIPOSISTEMA NOT IN ('Contributivo','Prepagado')) AND @VLR_COPAGO >0
                  BEGIN
                     SELECT @VLR_MODERAAC = 0
                     SELECT @VLR_COPAGOAC =@VLR_COPAGO
                  END
               END
               PRINT 'RESTO DE LOS ARCHIVOS COPAGO '+CONVERT(VARCHAR(20),@VLR_COPAGOAC) 
               PRINT 'RESTO DE LOS ARCHIVOS MODERADORA '+CONVERT(VARCHAR(20),@VLR_MODERAAC) 

               IF EXISTS(SELECT * FROM PLN WHERE IDPLAN=@IDPLAN AND TIPOSISTEMA<>'Prepagado') 
               BEGIN
                  SELECT @VLR_COPAGODETA=COALESCE(SUM(X.VLR_COPA),0),@VALORMODERADORADETA=COALESCE(SUM(VLR_MODE),0)
                  FROM (
                        SELECT VLR_MODE =  CASE WHEN  COALESCE(FTRD.TCOPAGO,'')='02' THEN  FTRD.VLR_COPAGOS WHEN  EXISTS(SELECT *  FROM MOCCD WHERE TIPODEPAGO='Moderadora' AND FTRD.VLR_COPAGOS=MOCCD.VALOR) AND COALESCE(FTRD.TCOPAGO,'') IN('','02') THEN FTRD.VLR_COPAGOS ELSE 0 END , 
                               VLR_COPA = CASE WHEN  COALESCE(FTRD.TCOPAGO,'')='01'  THEN  FTRD.VLR_COPAGOS  WHEN NOT EXISTS(SELECT *  FROM MOCCD WHERE TIPODEPAGO='Moderadora' AND FTRD.VLR_COPAGOS=MOCCD.VALOR) AND COALESCE(FTRD.TCOPAGO,'') NOT IN('','02')  THEN FTRD.VLR_COPAGOS ELSE 0 END
                     FROM FTRD INNER JOIN FTR ON FTR.CNSFCT=CNSFTR
                        INNER JOIN SER ON FTRD.REFERENCIA=SER.IDSERVICIO
                        INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
                     WHERE FTR.N_FACTURA=@N_FACTURA 
                     AND RIPS_CP.ARCHIVO<>'AC'
                  )X
                  IF @VLR_COPAGODETA IS NULL 
                     SET @VLR_COPAGODETA =0
                  IF @VALORMODERADORADETA IS NULL
                     SET @VALORMODERADORADETA=0

                  SELECT  @VLR_COPAGO=ROUND((@VLR_COPAGOAC+@VLR_COPAGODETA),0)
                  SELECT  @VALORMODERADORA=@VLR_MODERAAC+@VALORMODERADORADETA
				      PRINT 'REVISO TOTALES =@VALORMODERADORA='+CAST(@VALORMODERADORA AS VARCHAR(20))

                  IF EXISTS(SELECT * FROM PLN WHERE IDPLAN=@IDPLAN AND TIPOSISTEMA='Subsidiado')  OR @PROCEDENCIA='SALUD'
                  BEGIN
                     PRINT 'La moderadora solo aplica para las consultas en el salud se vuelve copagos'
                     SELECT @VLR_COPAGO=ROUND((@VLR_COPAGOAC+@VLR_COPAGODETA)+COALESCE(@VALORMODERADORA,0),0)
                     SELECT @VALORMODERADORA=0
                  END
                  IF COALESCE(@VLR_COPAGO,0)>0
                  BEGIN
                     PRINT '@VLR_COPAGO='+CONVERT(VARCHAR(20),@VLR_COPAGO)
				         SET @COD_ANTICIPO = '01'
				         SELECT  @NOM_ANTICIPO=LEFT(COALESCE(TGEN.DESCRIPCION,'COPAGOS'),100) FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='MODELOS_COPAGO' AND CODIGO=@COD_ANTICIPO

				         SET @XML+=@E+@T+'<cac:PrepaidPayment>' -- COPAGO
				         IF COALESCE(@COD_ANTICIPO, '') <> '' SET @XML+=@E+@T+@T+'<cbc:ID schemeID="' + @COD_ANTICIPO + '">'+@NOM_ANTICIPO+'</cbc:ID>'
				         ELSE SET @XML+=@E+@T+@T+'<cbc:ID>COPAGO</cbc:ID>'
				         SET @XML+=@E+@T+@T+'<cbc:PaidAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(COALESCE(@VLR_COPAGO,0) AS VARCHAR)+'</cbc:PaidAmount>'
				         SET @XML+=@E+@T+@T+'<cbc:ReceivedDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT,102),'.','-')+'</cbc:ReceivedDate>'
				         SET @XML+=@E+@T+@T+'<cbc:PaidDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT,102),'.','-')+'</cbc:PaidDate>'
				         SET @XML+=@E+@T+@T+'<cbc:PaidTime>'+CONVERT(VARCHAR,@HORA_FACT,108)+'-05:00</cbc:PaidTime>'
				         SET @XML+=@E+@T+@T+'<cbc:InstructionID>Prepago recibido</cbc:InstructionID>'
				         SET @XML+=@E+@T+'</cac:PrepaidPayment>'
			   
                     SET @VALORCOPAGO =COALESCE(@VALORCOPAGO,0)+COALESCE(@VLR_COPAGO,0)
                  END
                  PRINT 'VOY CON MODERADORA: '+STR(COALESCE(@VALORMODERADORA,0))
                  IF COALESCE(@VALORMODERADORA,0)>0
                  BEGIN
                     PRINT '@VALORMODERADORA='+CONVERT(VARCHAR(20),@VALORMODERADORA)
                     SELECT  @COD_ANTICIPO='02',@NOM_ANTICIPO='CUOTA MODERADORA'
                     SET @XML+=@E+@T+'<cac:PrepaidPayment>' -- Anticipos a la factura / Copagos   
                     SET @XML+=@E+@T+@T+'<cbc:ID schemeID="' + @COD_ANTICIPO + '">'+@NOM_ANTICIPO+'</cbc:ID>'

				         SET @XML+=@E+@T+@T+'<cbc:PaidAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VALORMODERADORA AS VARCHAR)+'</cbc:PaidAmount>'
				         SET @XML+=@E+@T+@T+'<cbc:ReceivedDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT,102),'.','-')+'</cbc:ReceivedDate>'
				         SET @XML+=@E+@T+@T+'<cbc:PaidDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT,102),'.','-')+'</cbc:PaidDate>'
				         SET @XML+=@E+@T+@T+'<cbc:PaidTime>'+CONVERT(VARCHAR,@HORA_FACT,108)+'-05:00</cbc:PaidTime>'
				         SET @XML+=@E+@T+@T+'<cbc:InstructionID>Cuota Moderadoras</cbc:InstructionID>'
                     SET @XML+=@E+@T+'</cac:PrepaidPayment>'
			            SET @VALORCOPAGO =COALESCE(@VALORCOPAGO,0)+COALESCE(@VALORMODERADORA,0)
                  END
               END
            END
            ELSE
			   BEGIN
				   IF COALESCE(@CAPITADA,0)=1 AND COALESCE(@TIPOCAP,0)=1  AND COALESCE(@COPAPROPIO,0)=1
               BEGIN
					   SELECT  @COD_ANTICIPO='04',@NOM_ANTICIPO='ANTICIPOS',@VALORCOPAGO=@VALORCOPAGO+COALESCE(@VALORMODERADORA,0)
                  SET @VALORMODERADORA=0
                  SET @XML+=@E+@T+'<cac:PrepaidPayment>' -- Anticipos a la factura / Copagos
				      IF COALESCE(@COD_ANTICIPO, '') <> '' SET @XML+=@E+@T+@T+'<cbc:ID schemeID="' + @COD_ANTICIPO + '">'+@NOM_ANTICIPO+'</cbc:ID>'
				      ELSE SET @XML+=@E+@T+@T+'<cbc:ID>COPAGO</cbc:ID>'

				      SET @XML+=@E+@T+@T+'<cbc:PaidAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VALORCOPAGO AS VARCHAR)+'</cbc:PaidAmount>'
				      SET @XML+=@E+@T+@T+'<cbc:ReceivedDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT,102),'.','-')+'</cbc:ReceivedDate>'
				      SET @XML+=@E+@T+@T+'<cbc:PaidDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT,102),'.','-')+'</cbc:PaidDate>'
				      SET @XML+=@E+@T+@T+'<cbc:PaidTime>'+CONVERT(VARCHAR,@HORA_FACT,108)+'-05:00</cbc:PaidTime>'
				      SET @XML+=@E+@T+@T+'<cbc:InstructionID>Anticipos Recibidos</cbc:InstructionID>'
                  SET @XML+=@E+@T+'</cac:PrepaidPayment>'
               END
               ELSE
               BEGIN
                  IF COALESCE(@VALORCOPAGO,0)>0
                  BEGIN           
                     SET @XML+=@E+@T+'<cac:PrepaidPayment>' -- Anticipos a la factura / Copagos
				         IF COALESCE(@COD_ANTICIPO, '') <> '' SET @XML+=@E+@T+@T+'<cbc:ID schemeID="' + @COD_ANTICIPO + '">'+@NOM_ANTICIPO+'</cbc:ID>'
				         ELSE SET @XML+=@E+@T+@T+'<cbc:ID>COPAGO</cbc:ID>'

				         SET @XML+=@E+@T+@T+'<cbc:PaidAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VALORCOPAGO AS VARCHAR)+'</cbc:PaidAmount>'
				         SET @XML+=@E+@T+@T+'<cbc:ReceivedDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT,102),'.','-')+'</cbc:ReceivedDate>'
				         SET @XML+=@E+@T+@T+'<cbc:PaidDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT,102),'.','-')+'</cbc:PaidDate>'
				         SET @XML+=@E+@T+@T+'<cbc:PaidTime>'+CONVERT(VARCHAR,@HORA_FACT,108)+'-05:00</cbc:PaidTime>'
				         SET @XML+=@E+@T+@T+'<cbc:InstructionID>Prepago recibido</cbc:InstructionID>'
                     SET @XML+=@E+@T+'</cac:PrepaidPayment>'
                  END
                  IF COALESCE(@VALORMODERADORA,0)>0 
                  BEGIN
                     SELECT  @COD_ANTICIPO='02',@NOM_ANTICIPO='CUOTA MODERADORA'
                     SET @XML+=@E+@T+'<cac:PrepaidPayment>' -- Anticipos a la factura / Copagos   
                     SET @XML+=@E+@T+@T+'<cbc:ID schemeID="' + @COD_ANTICIPO + '">'+@NOM_ANTICIPO+'</cbc:ID>'

				         SET @XML+=@E+@T+@T+'<cbc:PaidAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VALORMODERADORA AS VARCHAR)+'</cbc:PaidAmount>'
				         SET @XML+=@E+@T+@T+'<cbc:ReceivedDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT,102),'.','-')+'</cbc:ReceivedDate>'
				         SET @XML+=@E+@T+@T+'<cbc:PaidDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT,102),'.','-')+'</cbc:PaidDate>'
				         SET @XML+=@E+@T+@T+'<cbc:PaidTime>'+CONVERT(VARCHAR,@HORA_FACT,108)+'-05:00</cbc:PaidTime>'
				         SET @XML+=@E+@T+@T+'<cbc:InstructionID>Cuota Moderadoras</cbc:InstructionID>'
                     SET @XML+=@E+@T+'</cac:PrepaidPayment>'
                     SET  @VALORCOPAGO = @VALORCOPAGO+@VALORMODERADORA
                  END
				   END
			   END
         END
		END
		IF COALESCE(@IDMONEDA,'COP') <> 'COP' and 1=2 -- Información relacionadas con la tasa de cambio de moneda extranjera a peso colombiano 
		BEGIN
			SELECT @CalculationRate=VALOR from mndv where dbo.fnk_fecha_sin_hora(fecha)=dbo.fnk_fecha_sin_hora(@FECHA_FACT)

			IF COALESCE(@CalculationRate,0)<=0
			BEGIN
				SET @MENSAJE_ERROR='La factura '+@N_FACTURA+' es de moneda extranjera ('+@IDMONEDA+') y no existe tasa de cambio a la fecha '+CONVERT(VARCHAR,@FECHA_FACT,103)
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
				
			SET @XML+=@E+@T+'<cac:PaymentExchangeRate>'
			SET @XML+=@E+@T+@T+'<cbc:SourceCurrencyCode>'+COALESCE(@IDMONEDA,'COP')+'</cbc:SourceCurrencyCode>'
			SET @XML+=@E+@T+@T+'<cbc:SourceCurrencyBaseRate>1.00</cbc:SourceCurrencyBaseRate>'
			SET @XML+=@E+@T+@T+'<cbc:TargetCurrencyCode>COP</cbc:TargetCurrencyCode>' -- Debe ir diligenciado en COP, si el cbc:DocumentCurrencyCode es diferente a COP Ver lista de valores posibles en el numeral 6.3.3
			SET @XML+=@E+@T+@T+'<cbc:TargetCurrencyBaseRate>1.00</cbc:TargetCurrencyBaseRate>'
			SET @XML+=@E+@T+@T+'<cbc:CalculationRate>'+CAST(@CalculationRate AS VARCHAR)+'</cbc:CalculationRate>'
			SET @XML+=@E+@T+@T+'<cbc:Date>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT,102),'.','-')+'</cbc:Date>' -- FECHA DE CAMBIO
			SET @XML+=@E+@T+'</cac:PaymentExchangeRate>'
		END	
		IF COALESCE(@VR_IVA,0) > 0
		BEGIN -- Primer impuesto (IVA)
			SET @XML+=@E+@T+'<cac:TaxTotal>'
			SET @XML+=@E+@T+@T+'<cbc:TaxAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VR_IVA AS VARCHAR)+'</cbc:TaxAmount>'
			SET @XML+=@E+@T+@T+'<cbc:RoundingAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">0.00</cbc:RoundingAmount>'
			SET @XML+=@E+@T+@T+'<cac:TaxSubtotal>'
			SET @XML+=@E+@T+@T+@T+'<cbc:TaxableAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(CAST(@VR_BASEIMPONIBLE AS decimal(14,2)) AS VARCHAR)+'</cbc:TaxableAmount>'
			SET @XML+=@E+@T+@T+@T+'<cbc:TaxAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VR_IVA AS VARCHAR)+'</cbc:TaxAmount>'
			SET @XML+=@E+@T+@T+@T+'<cac:TaxCategory>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:Percent>19.00</cbc:Percent>'
			SET @XML+=@E+@T+@T+@T+@T+'<cac:TaxScheme>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:ID>01</cbc:ID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Name>IVA</cbc:Name>'
			SET @XML+=@E+@T+@T+@T+@T+'</cac:TaxScheme>'
			SET @XML+=@E+@T+@T+@T+'</cac:TaxCategory>'
			SET @XML+=@E+@T+@T+'</cac:TaxSubtotal>'
			SET @XML+=@E+@T+'</cac:TaxTotal>'
		END
		IF COALESCE(@DESCUENTO,0)>0 -- Descuento global a la Factura
		BEGIN
			SET @PORCENTAJE_DESCUENTO = COALESCE(@DESCUENTO, 0) / @VR_FACTURA * 100
			SET @XML+=@E+@T+@T+'<cac:AllowanceCharge>'
			SET @XML+=@E+@T+@T+@T+'<cbc:ID>1</cbc:ID>'
			SET @XML+=@E+@T+@T+@T+'<cbc:ChargeIndicator>false</cbc:ChargeIndicator>'
			SET @XML+=@E+@T+@T+@T+'<cbc:AllowanceChargeReasonCode>00</cbc:AllowanceChargeReasonCode>'
			SET @XML+=@E+@T+@T+@T+'<cbc:AllowanceChargeReason>Descuento</cbc:AllowanceChargeReason>'
			SET @XML+=@E+@T+@T+@T+'<cbc:MultiplierFactorNumeric>'+CAST(CAST(@PORCENTAJE_DESCUENTO AS DECIMAL(14,6)) AS VARCHAR)+'</cbc:MultiplierFactorNumeric>'
			SET @XML+=@E+@T+@T+@T+'<cbc:Amount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(COALESCE(@DESCUENTO,0) AS VARCHAR)+'</cbc:Amount>'
			SET @XML+=@E+@T+@T+@T+'<cbc:BaseAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(COALESCE(@VR_FACTURA,0) AS VARCHAR)+'</cbc:BaseAmount>'
			SET @XML+=@E+@T+@T+'</cac:AllowanceCharge>'
		END
		BEGIN -- Total de la Factura
			SET @XML+=@E+@T+'<cac:LegalMonetaryTotal>'
			SET @XML+=@E+@T+@T+'<cbc:LineExtensionAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VR_FACTURA - CASE WHEN @BASE_IVA_SERVICIOS='CONIVA' THEN COALESCE(@VR_IVA,0) ELSE 0 END AS VARCHAR)+'</cbc:LineExtensionAmount>'
			SET @XML+=@E+@T+@T+'<cbc:TaxExclusiveAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VR_BASEIMPONIBLE AS VARCHAR)+'</cbc:TaxExclusiveAmount>'
			SET @XML+=@E+@T+@T+'<cbc:TaxInclusiveAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VR_FACTURA + CASE WHEN @BASE_IVA_SERVICIOS='CONIVA' THEN 0 ELSE COALESCE(@VR_IVA,0) END AS VARCHAR)+'</cbc:TaxInclusiveAmount>'
			SET @XML+=@E+@T+@T+'<cbc:AllowanceTotalAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(COALESCE(@DESCUENTO,0) AS VARCHAR)+'</cbc:AllowanceTotalAmount>'
			SET @XML+=@E+@T+@T+'<cbc:ChargeTotalAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">0.00</cbc:ChargeTotalAmount>'
			SET @XML+=@E+@T+@T+'<cbc:PrepaidAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VALORCOPAGO AS VARCHAR)+'</cbc:PrepaidAmount>' -- Definir si se van a manejar las legalizaciones de depositos (Total anticipos)
			SET @XML+=@E+@T+@T+'<cbc:PayableAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VR_FACTURA - COALESCE(@DESCUENTO, 0) - IIF(@COPAGOIPS=1,ROUND(@VALORCOPAGO,0),0) + IIF(@BASE_IVA_SERVICIOS='CONIVA', 0, COALESCE(@VR_IVA,0)) AS VARCHAR)+'</cbc:PayableAmount>' -- Valor final a pagar, valor factura  + impuestos - descuentos - anticipos
			SET @XML+=@E+@T+'</cac:LegalMonetaryTotal>'
		END
		IF COALESCE(@IDMONEDA_DESTINO, 'COP')<>'COP' AND 1=2
		BEGIN -- Tasa de cambio cuando es una moneda extranjera
			SELECT @CalculationRate=VALOR from mndv where dbo.fnk_fecha_sin_hora(fecha)=dbo.fnk_fecha_sin_hora(@FECHA_TRM) AND IDMONEDA=@IDMONEDA_DESTINO

			IF COALESCE(@CalculationRate,0)<=0
			BEGIN
				SET @MENSAJE_ERROR='La nota '+@CNSDOC+' es de moneda extranjera ('+@IDMONEDA_DESTINO+') y no existe tasa de cambio a la fecha '+CONVERT(VARCHAR,@F_NOTA,103)
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
		
			SET @XML+=@E+@T+'<cac:PaymentExchangeRate>'
			SET @XML+=@E+@T+@T+'<cbc:SourceCurrencyCode>COP</cbc:SourceCurrencyCode>'
			SET @XML+=@E+@T+@T+'<cbc:SourceCurrencyBaseRate>'+CAST(COALESCE(@CalculationRate,0) AS VARCHAR)+'</cbc:SourceCurrencyBaseRate>'
			SET @XML+=@E+@T+@T+'<cbc:TargetCurrencyCode>'+@IDMONEDA_DESTINO+'</cbc:TargetCurrencyCode>'
			SET @XML+=@E+@T+@T+'<cbc:TargetCurrencyBaseRate>1.00</cbc:TargetCurrencyBaseRate>'
			SET @XML+=@E+@T+@T+'<cbc:CalculationRate>'+CAST(COALESCE(@CalculationRate,0) AS VARCHAR)+'</cbc:CalculationRate>'
			SET @XML+=@E+@T+@T+'<cbc:Date>'+REPLACE(CONVERT(VARCHAR,@FECHA_TRM,102),'.','-')+'</cbc:Date>'
			SET @XML+=@E+@T+'</cac:PaymentExchangeRate>'
		END
	
		BEGIN -- Detalles de la Factura
			SELECT	ROW_ID=ROW_NUMBER() OVER(ORDER BY N_CUOTA ASC),N_CUOTA, dbo.FNK_LIMPIATEXTO(ANEXO,'0-9 A-Z') ANEXO, FTRD.CANTIDAD,
				CASE WHEN COALESCE(@TERIPS,'')='CENDI' AND COALESCE(@VLPQFMAS,0)>0 
					THEN @VLPQFMAS ELSE VALOR END VALOR ,  
				CASE WHEN COALESCE(@TERIPS,'')='CENDI' AND COALESCE(@VLPQFMAS,0)>0 
					THEN @VLPQFMAS ELSE VLR_SERVICI END VLR_SERVICI
				,IIF(@PROCEDENCIA IN ('SALUD','CE','CI') AND SER.MEDICAMENTOS=0,
					dbo.FNK_LIMPIATEXTO(COALESCE(CASE @CODSER WHEN '0' THEN SER.IDSERVICIO WHEN '4' THEN SER.IDALTERNA WHEN '1' THEN SER.IDALTERNA WHEN '8' THEN SER.CODCUPS WHEN '9' THEN SER.CODCUPS ELSE SER.IDALTERNA END,REFERENCIA),'0-9 A-Z _-')
					,dbo.FNK_LIMPIATEXTO(REFERENCIA,'0-9 A-Z _-'))REFERENCIA 
				,COALESCE(FTRD.IDIMPUESTO,'') IDIMPUESTO, COALESCE(FTRD.IDCLASE,'') IDCLASE
				,CAST(COALESCE(PIVA,0) AS decimal(14,2)) PIVA 
				,CAST(COALESCE(VIVA,0) AS decimal(14,2)) VIVA
				,DESCUENTO = 0
				,NOPRESTACION
				,NOITEM
				,MED=0
			INTO #FTRD 
			FROM FTRD WITH(NOLOCK) LEFT JOIN SER ON SER.IDSERVICIO=FTRD.REFERENCIA
			WHERE CNSFTR=@CNSFCT AND CASE WHEN @TERIPS='CENDI' AND COALESCE(@VLPQFMAS,0)>0 THEN COALESCE(@VLPQFMAS,0) ELSE   COALESCE(VLR_SERVICI,0) END >0 
					AND CASE WHEN @TERIPS='CENDI' AND COALESCE(@VLPQFMAS,0)>0 THEN COALESCE(@VLPQFMAS,0) ELSE COALESCE(VALOR,0) END >0--- STORRES20211202
					AND COALESCE(FTRD.PAQUETE,0) NOT IN (2, 1) 
		
			SELECT @CANT_LINEAS=@@ROWCOUNT, @ROW_ID=0


			IF @PROCEDENCIA IN ('SALUD','CE','CI') AND dbo.FNK_VALORVARIABLE('XMLDIAN_EXPORTA_CUM')='SI'
			BEGIN
				IF 1=1---COALESCE(@FORMATORIPS,'')='01'-- COD CUMS SOLO
				BEGIN
					PRINT 'FORMATO RIPS CUMS' 
					IF @PROCEDENCIA='SALUD'
					BEGIN
						UPDATE #FTRD SET MED=1, REFERENCIA=CASE WHEN DBO.FNK_VALORVARIABLE('CODCUMS_FIJO') NOT IN('SER.CODCUM','IART.CODCUM','SER.SISPRO') 
                                                     THEN CASE COALESCE(D.CODIGOCUM,'') WHEN '' THEN CASE COALESCE(IART.CODCUM,'') 
                                                           WHEN '' THEN SER.CODCUM ELSE IART.CODCUM END ELSE D.CODIGOCUM END
                                                     ELSE CASE WHEN DBO.FNK_VALORVARIABLE('CODCUMS_FIJO') ='SER.CODCUM' THEN SER.CODCUM
                                                          WHEN DBO.FNK_VALORVARIABLE('CODCUMS_FIJO') ='IART.CODCUM' THEN IART.CODCUM
                                                          ELSE CASE COALESCE(IART.CODCUM,'') 
                                                               WHEN '' THEN SER.CODCUM ELSE IART.CODCUM END 
                                                           END 
                                                      END                                                
						FROM #FTRD A 
							INNER JOIN HPRED D ON D.NOPRESTACION=A.NOPRESTACION AND D.NOITEM=A.NOITEM
							INNER JOIN SER ON SER.IDSERVICIO=D.IDSERVICIO
							LEFT JOIN IART ON D.IDARTICULO=IART.IDARTICULO
						WHERE SER.MEDICAMENTOS=1

						UPDATE #FTRD SET MED=1, REFERENCIA=CASE COALESCE(IART.CODCUM,'') WHEN '' THEN SER.CODCUM ELSE IART.CODCUM END
						FROM #FTRD A INNER JOIN HPRED D ON D.NOPRESTACION=A.NOPRESTACION AND D.NOITEM=A.NOITEM
									INNER JOIN SER ON SER.IDSERVICIO=D.IDSERVICIO
									INNER JOIN IART ON D.IDARTICULO=IART.IDARTICULO
						WHERE SER.MEDICAMENTOS=1 AND (ISNULL(A.REFERENCIA,'')='' OR ISNULL(A.REFERENCIA,'') NOT LIKE '%-%')
					END

					UPDATE #FTRD SET MED=1, REFERENCIA=CASE ISNULL(SER.CODCUM,'') WHEN '' THEN A.REFERENCIA ELSE SER.CODCUM END
					FROM #FTRD A 
					INNER JOIN SER ON A.REFERENCIA=SER.IDSERVICIO
					WHERE SER.MEDICAMENTOS=1 AND (ISNULL(REFERENCIA,'')='' OR ISNULL(REFERENCIA,'') NOT LIKE '%-%')
				
					UPDATE #FTRD SET REFERENCIA=DBO.FNK_LIMPIATEXTO(REFERENCIA,'0-9-') FROM #FTRD A WHERE A.MED=1 AND ISNULL(REFERENCIA,'') LIKE '%-%'

					UPDATE #FTRD SET REFERENCIA=(stuff((select CONCAT('-',IIF(ISNUMERIC(WORD)=1 AND CONVERT(INT, WORD)>0, CONVERT(INT, WORD),WORD)) 
													FROM DBO.FNK_EXPLODE(REFERENCIA,'-') FOR XML PATH('')),1,1,'')
													)
					FROM #FTRD A WHERE A.MED=1 AND ISNULL(REFERENCIA,'') LIKE '%-%'
				END
			   BEGIN --ACTULIZO CODIGOS
					SELECT CNSFTR,N_FACTURA,N_CUOTA
						,IIF(@PROCEDENCIA IN ('SALUD','CE','CI') AND SER.MEDICAMENTOS=0,
							dbo.FNK_LIMPIATEXTO(COALESCE(CASE '4' WHEN '0' THEN SER.IDSERVICIO WHEN '4' THEN SER.IDALTERNA WHEN '1' THEN SER.IDALTERNA WHEN '8' THEN SER.CODCUPS WHEN '9' THEN SER.CODCUPS ELSE SER.IDALTERNA END,REFERENCIA),'0-9 A-Z _-')
							,dbo.FNK_LIMPIATEXTO(REFERENCIA,'0-9 A-Z _-'))REFERENCIA 
						,NOPRESTACION
						,NOITEM
						,MED=0
					INTO #FTRD1
					FROM FTRD WITH(NOLOCK) LEFT JOIN SER ON SER.IDSERVICIO=FTRD.REFERENCIA
					WHERE CNSFTR=@CNSFCT AND COALESCE(FTRD.PAQUETE,0) NOT IN (2, 1) 
		
					PRINT 'FORMATO RIPS CUMS' 
					IF @PROCEDENCIA='SALUD'
					BEGIN
						UPDATE #FTRD1 SET MED=1, REFERENCIA=CASE WHEN DBO.FNK_VALORVARIABLE('CODCUMS_FIJO') NOT IN('SER.CODCUM','IART.CODCUM','SER.SISPRO') 
														THEN CASE COALESCE(D.CODIGOCUM,'') WHEN '' THEN CASE COALESCE(IART.CODCUM,'') 
															WHEN '' THEN SER.CODCUM ELSE IART.CODCUM END ELSE D.CODIGOCUM END
														ELSE CASE WHEN DBO.FNK_VALORVARIABLE('CODCUMS_FIJO') ='SER.CODCUM' THEN SER.CODCUM
															WHEN DBO.FNK_VALORVARIABLE('CODCUMS_FIJO') ='IART.CODCUM' THEN IART.CODCUM
															ELSE CASE COALESCE(IART.CODCUM,'') 
																WHEN '' THEN SER.CODCUM ELSE IART.CODCUM END 
															END 
														END                                                
						FROM #FTRD1 A 
							INNER JOIN HPRED D ON D.NOPRESTACION=A.NOPRESTACION AND D.NOITEM=A.NOITEM
							INNER JOIN SER ON SER.IDSERVICIO=D.IDSERVICIO
							LEFT JOIN IART ON D.IDARTICULO=IART.IDARTICULO
						WHERE SER.MEDICAMENTOS=1

						UPDATE #FTRD1 SET MED=1, REFERENCIA=CASE COALESCE(IART.CODCUM,'') WHEN '' THEN SER.CODCUM ELSE IART.CODCUM END
						FROM #FTRD1 A INNER JOIN HPRED D ON D.NOPRESTACION=A.NOPRESTACION AND D.NOITEM=A.NOITEM
									INNER JOIN SER ON SER.IDSERVICIO=D.IDSERVICIO
									INNER JOIN IART ON D.IDARTICULO=IART.IDARTICULO
						WHERE SER.MEDICAMENTOS=1 AND (ISNULL(A.REFERENCIA,'')='' OR ISNULL(A.REFERENCIA,'') NOT LIKE '%-%')
					END

					UPDATE #FTRD1 SET MED=1, REFERENCIA=CASE ISNULL(SER.CODCUM,'') WHEN '' THEN A.REFERENCIA ELSE SER.CODCUM END
					FROM #FTRD1 A 
					INNER JOIN SER ON A.REFERENCIA=SER.IDSERVICIO
					WHERE SER.MEDICAMENTOS=1 AND (ISNULL(REFERENCIA,'')='' OR ISNULL(REFERENCIA,'') NOT LIKE '%-%')
				
					UPDATE #FTRD1 SET REFERENCIA=DBO.FNK_LIMPIATEXTO(REFERENCIA,'0-9-') FROM #FTRD1 A WHERE A.MED=1 AND ISNULL(REFERENCIA,'') LIKE '%-%'

					UPDATE #FTRD1 SET REFERENCIA=(stuff((select CONCAT('-',IIF(ISNUMERIC(WORD)=1 AND CONVERT(INT, WORD)>0, CONVERT(INT, WORD),WORD)) 
													FROM DBO.FNK_EXPLODE(REFERENCIA,'-') FOR XML PATH('')),1,1,'')
													)
					FROM #FTRD1 A WHERE A.MED=1 AND ISNULL(REFERENCIA,'') LIKE '%-%'
					
					DELETE #FTRD1 WHERE MED=0

					UPDATE FTRD SET CODCUMXML=#FTRD1.REFERENCIA
					FROM FTRD INNER JOIN #FTRD1 ON FTRD.CNSFTR=#FTRD1.CNSFTR AND FTRD.N_CUOTA=#FTRD1.N_CUOTA AND FTRD.N_FACTURA=#FTRD1.N_FACTURA
				END
			END
			IF COALESCE(@DESCUENTO,0)>0
			BEGIN
				SELECT @REMANENTE = @DESCUENTO
				WHILE @ROW_ID < @CANT_LINEAS
				BEGIN
					SET @ROW_ID += 1

					SELECT @DESCUENTO_LINEA = ROUND((VALOR*CANTIDAD* @PORCENTAJE_DESCUENTO)/100, 2) FROM #FTRD WHERE ROW_ID = @ROW_ID
				
					UPDATE #FTRD SET DESCUENTO = @DESCUENTO_LINEA WHERE ROW_ID = @ROW_ID
					SELECT @REMANENTE -= @DESCUENTO_LINEA FROM #FTRD WHERE ROW_ID = @ROW_ID

					IF @ROW_ID = @CANT_LINEAS AND @REMANENTE > 0
					BEGIN
						UPDATE #FTRD SET DESCUENTO = DESCUENTO + @REMANENTE WHERE ROW_ID = @ROW_ID
					END
				END
			END

			SELECT @ROW_ID=0
			WHILE @ROW_ID < @CANT_LINEAS-- AND 1=2
			BEGIN
				SET @ROW_ID+=1
				SELECT @N_CUOTA=ROW_ID-- N_CUOTA -- Se quitó N_CUOTA porque la DIAN solo admite servicios con valores mayores a cero, krystalos guarda valores en cero en ftrd y al excluirlo se saltan los consecutivos y viola la regla del xml FAV02b
					,@ANEXO=#FTRD.ANEXO
					,@CANTIDAD=#FTRD.CANTIDAD
					,@VALOR=#FTRD.VALOR
					,@VLR_SERVICI = #FTRD.VLR_SERVICI * IIF(@IDMONEDA_DESTINO <> @IDMONEDA, @CalculationRate, 1)
					,@REFERENCIA=COALESCE(IIF(SER.CODCUPS IN ('',' '),NULL,SER.CODCUPS),#FTRD.REFERENCIA) -- 20250621 -- STORRES -- SE DEBE ENVIAR LO MISMO QUE LOS RIPS
					,@IDIMPUESTO=#FTRD.IDIMPUESTO
					,@IDCLASE=#FTRD.IDCLASE
					,@PIVA=#FTRD.PIVA
					,@VIVA=#FTRD.VIVA
					,@DESCUENTO_LINEA = #FTRD.DESCUENTO
				FROM #FTRD LEFT JOIN SER ON SER.IDSERVICIO = #FTRD.REFERENCIA
            WHERE ROW_ID=@ROW_ID

				SET @XML+=@E+@T+'<cac:InvoiceLine>'
				SET @XML+=@E+@T+@T+'<cbc:ID>' + CAST(@N_CUOTA AS VARCHAR) + '</cbc:ID>'
				SET @XML+=@E+@T+@T+'<cbc:InvoicedQuantity unitCode="'+IIF(COALESCE(@IDMONEDA,'COP')='COP','EA','NIU')+'">' + '1'/*CAST(@CANTIDAD AS VARCHAR)*/ + '</cbc:InvoicedQuantity>' 
				SET @XML+=@E+@T+@T+'<cbc:LineExtensionAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VLR_SERVICI - CASE WHEN @BASE_IVA_SERVICIOS='CONIVA' THEN @VIVA ELSE 0 END AS VARCHAR)+'</cbc:LineExtensionAmount>'
				SET @XML+=@E+@T+@T+'<cbc:FreeOfChargeIndicator>false</cbc:FreeOfChargeIndicator>'
			
				IF COALESCE(@DESCUENTO,0)>0 -- MANEJAR DESCUENTOS EN LA FACTURA 
				BEGIN
					SET @XML+=@E+@T+@T+'<cac:AllowanceCharge>'
					SET @XML+=@E+@T+@T+@T+'<cbc:ID>' + CAST(@N_CUOTA AS VARCHAR) + '</cbc:ID>'
					SET @XML+=@E+@T+@T+@T+'<cbc:ChargeIndicator>false</cbc:ChargeIndicator>'
					SET @XML+=@E+@T+@T+@T+'<cbc:AllowanceChargeReason>Descuento</cbc:AllowanceChargeReason>'
					SET @XML+=@E+@T+@T+@T+'<cbc:MultiplierFactorNumeric>'+CAST(CAST(@PORCENTAJE_DESCUENTO AS DECIMAL(14,6)) AS VARCHAR)+'</cbc:MultiplierFactorNumeric>'
					SET @XML+=@E+@T+@T+@T+'<cbc:Amount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(COALESCE(@DESCUENTO_LINEA,0) AS VARCHAR)+'</cbc:Amount>'
					--SET @XML+=@E+@T+@T+@T+'<cbc:BaseAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">' + CAST(@VLR_SERVICI AS VARCHAR) + '</cbc:BaseAmount>'
					SET @XML+=@E+@T+@T+@T+'<cbc:BaseAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(CAST(COALESCE(@VALOR,0)*COALESCE(@CANTIDAD,0) AS decimal(14,2)) AS VARCHAR)+'</cbc:BaseAmount>'
					SET @XML+=@E+@T+@T+'</cac:AllowanceCharge>'
				END

				-- Impuestos relacionados al item de la factura, 
				IF COALESCE(@VIVA,0)>0
				BEGIN
					SET @XML+=@E+@T+@T+'<cac:TaxTotal>'
					SET @XML+=@E+@T+@T+@T+'<cbc:TaxAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VIVA AS varchar)+'</cbc:TaxAmount>'
					SET @XML+=@E+@T+@T+@T+'<cac:TaxSubtotal>'
					SET @XML+=@E+@T+@T+@T+@T+'<cbc:TaxableAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CASE WHEN @VIVA>0 THEN CAST(@VLR_SERVICI - CASE WHEN @BASE_IVA_SERVICIOS='CONIVA' THEN @VIVA ELSE 0 END AS varchar) ELSE '0.00' END+'</cbc:TaxableAmount>' -- Monto Imponible 
					SET @XML+=@E+@T+@T+@T+@T+'<cbc:TaxAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VIVA AS varchar)+'</cbc:TaxAmount>' -- Total
					SET @XML+=@E+@T+@T+@T+@T+'<cac:TaxCategory>'
					SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Percent>19.00</cbc:Percent>'
					SET @XML+=@E+@T+@T+@T+@T+@T+'<cac:TaxScheme>'
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:ID>01</cbc:ID>'
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:Name>IVA</cbc:Name>'
					SET @XML+=@E+@T+@T+@T+@T+@T+'</cac:TaxScheme>'
					SET @XML+=@E+@T+@T+@T+@T+'</cac:TaxCategory>'
					SET @XML+=@E+@T+@T+@T+'</cac:TaxSubtotal>'
					SET @XML+=@E+@T+@T+'</cac:TaxTotal>'
				END
				SET @XML+=@E+@T+@T+'<cac:Item>'
				SET @XML+=@E+@T+@T+@T+'<cbc:Description>' + @ANEXO + '</cbc:Description>'
				SET @XML+=@E+@T+@T+@T+'<cac:SellersItemIdentification>'
				SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID>' + @REFERENCIA + '</cbc:ID>'
				SET @XML+=@E+@T+@T+@T+'</cac:SellersItemIdentification>'
				SET @XML+=@E+@T+@T+@T+'<cac:StandardItemIdentification>'
				SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID schemeID="001" schemeName="UNSPSC" schemeAgencyID="10">' + @REFERENCIA + '</cbc:ID>' -- <cbc:ID schemeName="EAN13" schemeAgencyName="195">6543542313534</cbc:ID>
				SET @XML+=@E+@T+@T+@T+'</cac:StandardItemIdentification>'
				SET @XML+=@E+@T+@T+'</cac:Item>'
				SET @XML+=@E+@T+@T+'<cac:Price>'
				SET @XML+=@E+@T+@T+@T+'<cbc:PriceAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">' + CAST(@VLR_SERVICI AS VARCHAR) + '</cbc:PriceAmount>'
				SET @XML+=@E+@T+@T+@T+'<cbc:BaseQuantity unitCode="NIU">' + '1.00'/*CAST(@CANTIDAD AS VARCHAR)*/ + '</cbc:BaseQuantity>'
				SET @XML+=@E+@T+@T+'</cac:Price>'
  				SET @XML+=@E+@T+'</cac:InvoiceLine>'
			END
			DROP TABLE #FTRD
		END
		SELECT @XML=REPLACE(@XML,'@CANT_TOTAL_ITEMS',CAST(@ROW_ID AS VARCHAR))
		SELECT @XML+=@E+'</Invoice>'
	END

	IF COALESCE(@FACTURACION_POR_SEDE, 0)=1 AND @TIPODOC IN ('NC','ND')
	BEGIN
		SELECT @N_FACTURA=N_FACTURA FROM FNOT WHERE CNSFNOT=@CNSDOC
		SELECT @IDSEDE = FTR.IDSEDE
		FROM FTR WHERE N_FACTURA=@N_FACTURA
	
		IF COALESCE(@FACTURACION_POR_SEDE, 0) = 1
		BEGIN
		
			IF NOT EXISTS(SELECT TOP 1 IDTERCERO FROM TER INNER JOIN SED ON SED.NIT=TER.NIT)
			BEGIN
				SET @MENSAJE_ERROR='No encuentro los datos del facturador de la sede (SELECT TOP 1 IDTERCERO FROM TER INNER JOIN SED ON SED.NIT=TER.NIT)'
				RAISERROR (@MENSAJE_ERROR, 16, 1)
			END

			SELECT @TIPO_PERSONA=CASE WHEN NATJURIDICA='Juridica' THEN '1' ELSE '2' END 
				,@NITFACTU=LTRIM(RTRIM(NIT))
				,@DV_FACTURADOR=DV
				,@RSOCIALFACTU=dbo.FNK_LIMPIATEXTO(RAZONSOCIAL,'0-9 A-Z().;:,')
				,@DIRFACTU=dbo.FNK_LIMPIATEXTO(TER.DIRECCION, '0-9 A-Z().;:,') --='CARRERA 19 No 14-47'
				,@CIUFACTU=TER.CIUDAD
				,@NOMCIUFACTU=CIU.NOMBRE
				,@NOMDEPFACTU=DEP.NOMBRE
				,@CODPOSTALFACTU=CIU.CODPOSTAL
				,@COD_RESPONSABILIDAD_FISCAL=TER.COD_RESP_FISCAL
				,@CODDEPTOFACTU=DEP.COD_DIAN
				,@schemeName_FACTURADOR=(SELECT TOP 1 DATO1 FROM TGEN WHERE TABLA='GENERAL' AND CAMPO='TIPOIDENT' AND CODIGO=TER.TIPO_ID)
				,@IDTERCERO_OFE = TER.IDTERCERO
			FROM TER 
			LEFT JOIN CIU ON CIU.CIUDAD=TER.CIUDAD 
			LEFT JOIN DEP ON CIU.DPTO=DEP.DPTO
			WHERE IDTERCERO = (SELECT TOP 1 IDTERCERO FROM TER INNER JOIN SED ON SED.NIT=TER.NIT AND SED.IDSEDE=@IDSEDE)

			IF COALESCE(@NITFACTU,'')='' RAISERROR ('FACTURACION POR SEDE: NIT del OFE sin configurar', 16, 1); 
			IF COALESCE(@CODPOSTALFACTU,'')='' RAISERROR ('FACTURACION POR SEDE: Codigo postal del facturador electrónico es obligatorio', 16, 1); 
			IF COALESCE(@DV_FACTURADOR,'')='' RAISERROR ('FACTURACION POR SEDE: Dígito de verificacion del OFE sin configurar', 16, 1); 
			IF COALESCE(@RSOCIALFACTU,'')='' RAISERROR ('FACTURACION POR SEDE: Razón social del OFE sin configurar', 16, 1); 
			IF COALESCE(@DIRFACTU,'')='' RAISERROR ('FACTURACION POR SEDE: Dirección fiscal del OFE sin configurar', 16, 1); 
			IF COALESCE(@CIUFACTU,'')='' OR COALESCE(@NOMCIUFACTU,'')='' RAISERROR ('FACTURACION POR SEDE: Ciudad de la dirección fiscal del OFE sin configurar', 16, 1); 
			IF COALESCE(@COD_RESPONSABILIDAD_FISCAL,'')='' RAISERROR ('FACTURACION POR SEDE: Código de la responsabilidad fiscal del OFE sin configurar', 16, 1); 
			IF COALESCE(@schemeName_FACTURADOR,'')='' RAISERROR ('FACTURACION POR SEDE: Tipo de documento de identidad del adquiriente no homologado (TGEN.TABLA= GENERAL, TGEN.CAMPO=TIPOIDENT)', 16, 1); 

			SELECT @SoftwareID=COALESCE(DESCRIPCION,'') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='SOFTWARE'+@IDSEDE AND CODIGO='ID' 
			SELECT @SoftwarePIN=COALESCE(DESCRIPCION,'') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='SOFTWARE'+@IDSEDE AND CODIGO='PIN'
			SELECT @TESTSETID=COALESCE(DESCRIPCION,'') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='SOFTWARE'+@IDSEDE AND CODIGO='TESTSETID'
			IF COALESCE(@SoftwareID,'')='' RAISERROR ('Identificador del Software es obligatorio. (TGEN => ''FDIAN(IDSEDE)'', ''SOFTWARE'', ''ID'')', 16, 1); 
			IF COALESCE(@SoftwarePIN,'')='' RAISERROR ('PIN del Software es obligatorio. (TGEN => ''FDIAN(IDSEDE)'', ''SOFTWARE'', ''PIN'')', 16, 1);
		END
	END
	IF @TIPODOC='NC'
	BEGIN
	   DECLARE @PIVANOTA DECIMAL(14,2)=0
	   DECLARE @VIVANOTA DECIMAL(14,2)=0
		BEGIN -- Datos de la Factura
			SELECT @N_FACTURA=N_FACTURA FROM FNOT WHERE CNSFNOT=@CNSDOC
			SELECT @CNSRESOL=CNSRESOLFE, @PREFIJO=COALESCE(PREFIJODIANFE,''), @FACTURA=CNSDIANFE, @CNSFCT=CNSFCT 
				,@TIPO_OPERACION=COALESCE(TIPO_OPERACION, '10'), @FECHA_FACT=F_FACTURA, @VR_FACTURA=CAST(VALORSERVICIOS AS DECIMAL(14,2))
			FROM FTR WHERE N_FACTURA=@N_FACTURA
			SELECT @CUFE=CUFE FROM FTRE WHERE N_FACTURA=@FACTURA AND PREFIJO=@PREFIJO
		END
		BEGIN -- Datos de la Nota
			SELECT @F_NOTA=F_NOTA, @IDCONCEPTO=IDCONCEPTO, @OBSERVACION_FNOT=OBSERVACION, @VR_NOTA=VR_TOTAL FROM FNOT WHERE CNSFNOT=@CNSDOC
			SELECT @IDCONCEPTO=CASE WHEN @TIPODOC='NC' THEN HOMOLOGODIANCR ELSE HOMOLOGODIANDB END FROM CPNT WHERE CODIGO=@IDCONCEPTO
		  SELECT @VIVANOTA= SUM(COALESCE(VALORIVA,0)),@VR_BASEIMPONIBLE=SUM(VR_TOTAL) FROM FNOTD 
		  WHERE  CNSFNOT=@CNSDOC --AND COALESCE(VALORIVA,0)>0
      
		  SELECT @VR_BASEIMPONIBLE=
			SUM(
				CANTIDAD * IIF(@BASE_IVA_SERVICIOS='CONIVA', VR_UNITARIO - VALORIVA, VR_UNITARIO)
			) 

		--SELECT @VR_BASEIMPONIBLE = CASE WHEN @BASE_IVA_SERVICIOS='CONIVA' THEN COALESCE(SUM(VLR_SERVICI-COALESCE(VIVA,0)),0) ELSE COALESCE(SUM(VLR_SERVICI),0) END

		  FROM FNOTD 
		  WHERE  CNSFNOT=@CNSDOC AND COALESCE(VALORIVA,0)>0 --AGREGADO AC "20230616"

		  PRINT @VR_BASEIMPONIBLE
      
		  IF COALESCE(@VIVANOTA,0)>0
		  BEGIN
			 SELECT TOP 1 @PIVANOTA=PIVA FROM FNOTD WHERE CNSFNOT=@CNSDOC AND COALESCE(VALORIVA,0)>0
		  END
			IF COALESCE(@IDCONCEPTO,'')=''
			BEGIN	
				SET @MENSAJE_ERROR='La nota '+@CNSDOC+' no tiene un concepto válido'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			SELECT @CANT_TOTAL_ITEMS=COUNT(*) FROM FNOTD WHERE CNSFNOT=@CNSDOC AND COALESCE(VR_TOTAL,0)>0
		END
		BEGIN -- Adquiriente
			--------------------------------------------------------------------------------------------------------------------------------------------------------------
			SELECT @NIT_ADQUIRIENTE=TER.NIT, @DV_ADQUIRIENTE=COALESCE(TER.DV,''), @RAZONSOCIAL_ADQUIRIENTE=DBO.FNK_LIMPIATEXTO(TER.RAZONSOCIAL,'0-9 A-Z().;:,'), @CIUDAD_ADQUIRIENTE=COALESCE(CIU.HOMOLOGODIAN,TER.CIUDAD), @DIRADQUI=dbo.FNK_LIMPIATEXTO(TER.DIRECCION, '0-9 A-Z().;:,')
				,@TELCONTACTOADQUI=dbo.FNK_LIMPIATEXTO(COALESCE(TER.TELEFONOS,''),'0-9'), @FAXCONTACTOADQUI=COALESCE(TER.FAX,''), @EMAIL_ADQUIRIENTE=COALESCE(TER.EMAIL,TER.EMAIL_RL,TER.EMAIL_TH,@EMAIL_CONTACTO,'')
				,@CODRESPFISCALADQ=COALESCE(TER.COD_RESP_FISCAL,'O-99')
				,@NOMCIUADQUI=CIU.NOMBRE, @CODDEPTOADQUI=DEP.COD_DIAN
				,@CODPOSTALADQUI=COALESCE(CIU.CODPOSTAL,CIU.CIUDAD,'')		
				,@IDTERCEROADQUI=TER.IDTERCERO
			FROM FTR INNER JOIN TER ON TER.IDTERCERO=FTR.IDTERCERO 
			LEFT JOIN CIU ON CIU.CIUDAD=TER.CIUDAD
			LEFT JOIN DEP ON DEP.DPTO=CIU.DPTO
			WHERE CNSFCT=@CNSFCT
			-- Eliminar caracteres raros de email del adquiriente
			select @EMAIL_ADQUIRIENTE=dbo.FNK_LIMPIATEXTO(@email_adquiriente,'a-zA-Z0-9@._')
		 
			SELECT @TIPO_PERSONA_ADQUIRIENTE=CASE WHEN TIPO_ID='NIT' THEN 1 ELSE 2 END 
				,@NOMCONTACTOADQUI=@RAZONSOCIAL_ADQUIRIENTE
				,@schemeName_ADQUIRIENTE=(SELECT TOP 1 DATO1 FROM TGEN WHERE TABLA='GENERAL' AND CAMPO='TIPOIDENT' AND CODIGO=TER.TIPO_ID)
			FROM TER WHERE IDTERCERO=(SELECT IDTERCERO FROM FTR WHERE CNSFCT=@CNSFCT)

			IF COALESCE(@NIT_ADQUIRIENTE,'')=''
			BEGIN
				SET @MENSAJE_ERROR='NIT del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			IF COALESCE(@RAZONSOCIAL_ADQUIRIENTE,'')='' 
			BEGIN
				SET @MENSAJE_ERROR='Razón social del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			IF COALESCE(@CIUDAD_ADQUIRIENTE,'')='' 
			BEGIN
				SET @MENSAJE_ERROR='Ciudad del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			IF COALESCE(@DIRADQUI,'')='' 
			BEGIN
				SET @MENSAJE_ERROR='Dirección del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			IF COALESCE(@TELCONTACTOADQUI,'')='' 
			BEGIN
				SET @MENSAJE_ERROR='Teléfono del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			IF COALESCE(@EMAIL_ADQUIRIENTE,'')='' 
			BEGIN
				SET @MENSAJE_ERROR='Email del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
--QUERY 3
--QUERY 3
			IF COALESCE(@CODRESPFISCALADQ,'')='' RAISERROR ('Responsabilidad fiscal del adquiriente sin configurar', 16, 1); 
		END
		BEGIN -- Persona de Contacto
			SELECT @NOMBRE_CONTACTO=DESCRIPCION FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='CONTACTO' AND CODIGO='NOMBRE'
			SELECT @TELEFONO_CONTACTO=dbo.FNK_LIMPIATEXTO(DESCRIPCION,'0-9') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='CONTACTO' AND CODIGO='TELEFONO'
			SELECT @EMAIL_CONTACTO=DESCRIPCION FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='CONTACTO' AND CODIGO='EMAIL'
			SELECT @FAX_CONTACTO=COALESCE(DESCRIPCION,'') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='CONTACTO' AND CODIGO='FAX'
			IF COALESCE(@NOMBRE_CONTACTO,'')='' RAISERROR ('Nombre de contacto de OFE es obligatorio. (TGEN => ''FDIAN'', ''CONTACTO'', ''NOMBRE'')', 16, 1); 
			IF COALESCE(@TELEFONO_CONTACTO,'')='' RAISERROR ('Teléfono de contacto de OFE es obligatorio. (TGEN => ''FDIAN'', ''CONTACTO'', ''TELEFONO'')', 16, 1); 
			IF COALESCE(@EMAIL_CONTACTO,'')='' RAISERROR ('Email de contacto de OFE es obligatorio. (TGEN => ''FDIAN'', ''CONTACTO'', ''EMAIL'')', 16, 1); 
		END

		BEGIN -- Tipo de Nota de Crédito
			SELECT @TIPONOTA = '20'
			IF EXISTS(SELECT 1 FROM FNOT WHERE CNSFNOT=@CNSDOC AND COALESCE(FNOT.NOTA_SIN_FACTURA, 0)=1 ) SELECT @TIPONOTA = '22'
		END

	   IF  COALESCE(@TIPONOTA,'')<>'22'
	   BEGIN
		   IF NOT EXISTS(SELECT * FROM FTR WHERE N_FACTURA=@N_FACTURA AND COALESCE(CNSDIANFE,'')<>'' AND COALESCE(CNSRESOLFE,'')<>'' AND FACTE=2 )
		   BEGIN
			   SET @MENSAJE_ERROR='Factura ' + @N_FACTURA + ' no validada previamente ante la DIAN'
			   RAISERROR (@MENSAJE_ERROR, 16, 1); 
		   END
		   IF COALESCE(@CNSRESOL,'')='' 
		   BEGIN
			   SET @MENSAJE_ERROR='Factura '+@N_FACTURA+' sin resolución'
			   RAISERROR (@MENSAJE_ERROR, 16, 1); 
		   END
	   END
	   ELSE
	   BEGIN 
		  SELECT @IDCONCEPTO='1'--SE ASIGNA EL CONSECUTO DE DEVOLUCION DE BIENES, CUANDO ES NOTA SIN FACTURA 
		  SELECT TOP 1 @PREFIJO = PREFIJO, @AMBIENTE =COALESCE(AMBIENTE,1) FROM FDIAN WHERE PROCEDENCIA='FTR' AND COALESCE(VENCIDA,0)=0 
		  SELECT @FACTURA = DBO.FNK_LIMPIATEXTO(@N_FACTURA,'0-9') FROM FNOT WHERE CNSFNOT=@CNSDOC
	   END
		IF @CANT_TOTAL_ITEMS<=0
		BEGIN
			SET @MENSAJE_ERROR='Nota '+@CNSDOC+' sin items en el detalle'
			RAISERROR (@MENSAJE_ERROR, 16, 1); 
		END
		IF COALESCE(@TIPONOTA,'')<>'22'
		BEGIN -- Datos de la Resolución DIAN
			SELECT @VENCIDA=VENCIDA,@FTRELECTRONICA=FTRELECTRONICA, @FINIRESOL=FECHAINI,@FFINRESOL=FECHAVEN, @PREFIJO=COALESCE(PREFIJO,'')
				,@CNSINICIAL=CNSINICIAL ,@CNSFINAL=CNSFINAL ,@CNSACTUAL=CNSACTUAL+1, @CLAVE_TECNICA=CLAVETECNICA, @AMBIENTE=AMBIENTE
			FROM FDIAN WHERE CNSRESOL=@CNSRESOL
		END

		SELECT  @CUDE=dbo.FNK_GENERAR_CUFE_CUDE(@TIPODOC,@CNSDOC, @NITFACTU, '', '', @AMBIENTE)
		IF @AMBIENTE=2 AND COALESCE(@TESTSETID,'')='' RAISERROR ('El identificador de pruebas (TestSetId) es obligatorio en el ambiente de pruebas. (TGEN => ''FDIAN'', ''SOFTWARE'', ''TESTSETID'')', 16, 1); 
			
		SELECT @QR_CODE=DBO.FNK_QRCODE(@N_FACTURA)
		IF COALESCE(@QR_CODE,'')=''
			SELECT @QR_CODE='NroNota='+@CNSDOC+', NroFactura='+COALESCE(@PREFIJO,'')+@FACTURA+', NitFacturador='+@NITFACTU+', NitAdquiriente='+@NIT_ADQUIRIENTE+', CUFE=' + COALESCE(@CUFE,'')
		SET @SoftwareSecurityCode=@SoftwareID+@SoftwarePIN+@PREFIJO+@CNSDOC -- SoftwareSecurityCode:= SHA-384 (Id Software + Pin + NroDocumento[Con Prefijo])
		SET @XML='<?xml version="1.0" encoding="UTF-8" standalone="no"?>'
		SET @XML+=@E+'<CreditNote xmlns="urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" xmlns:sts="dian:gov:co:facturaelectronica:Structures-2-1" xmlns:xades="http://uri.etsi.org/01903/v1.3.2#" xmlns:xades141="http://uri.etsi.org/01903/v1.4.1#" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2 http://docs.oasis-open.org/ubl/os-UBL-2.1/xsd/maindoc/UBL-CreditNote-2.1.xsd">'
		SET @XML+=@E+@T+'<ext:UBLExtensions>'
		SET @XML+=@E+@T+@T+'<ext:UBLExtension>'
		SET @XML+=@E+@T+@T+@T+'<ext:ExtensionContent>'
		SET @XML+=@E+@T+@T+@T+@T+'<sts:DianExtensions>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<sts:InvoiceSource>'
		SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:IdentificationCode listAgencyID="6" listAgencyName="United Nations Economic Commission for Europe" listSchemeURI="urn:oasis:names:specification:ubl:codelist:gc:CountryIdentificationCode-2.1">CO</cbc:IdentificationCode>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'</sts:InvoiceSource>'
		BEGIN -- Datos del Software Electronico
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<sts:SoftwareProvider>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+'<sts:ProviderID schemeName="'+COALESCE(@schemeName_FACTURADOR,'31')+'" schemeID="'+@DV_FACTURADOR+'" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeAgencyID="195">'+@NITFACTU+'</sts:ProviderID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+'<sts:SoftwareID schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)">'+@SoftwareID+'</sts:SoftwareID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'</sts:SoftwareProvider>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<sts:SoftwareSecurityCode schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeAgencyID="195">'+@SoftwareSecurityCode+'</sts:SoftwareSecurityCode>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<sts:AuthorizationProvider>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<sts:AuthorizationProviderID schemeID="4" schemeName="31" schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)">'+@NIT_DIAN+'</sts:AuthorizationProviderID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'</sts:AuthorizationProvider>'
		END
		SET @XML+=@E+@T+@T+@T+@T+@T+'<sts:QRCode>'+@QR_CODE+'</sts:QRCode>'
		--	NITFacturador=901034990NumIdentAdquiriente=800000250Cufe=ca0508c0e5fb9da9120cd16757f2e068bb6c60887491976b2e92d49100298f823671e6d860d3ef3113d23ed04b1f6454</sts:QRCode>'
		SET @XML+=@E+@T+@T+@T+@T+'</sts:DianExtensions>'
		SET @XML+=@E+@T+@T+@T+'</ext:ExtensionContent>'
		SET @XML+=@E+@T+@T+'</ext:UBLExtension>'
		SET @XML+=@E+@T+@T+'<ext:UBLExtension>'
		SET @XML+=@E+@T+@T+@T+'<ext:ExtensionContent></ext:ExtensionContent>'
		SET @XML+=@E+@T+@T+'</ext:UBLExtension>'
		SET @XML+=@E+@T+'</ext:UBLExtensions>'

		IF NOT EXISTS (SELECT * FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='TIPO_OPERACION' AND CODIGO=@TIPO_OPERACION)
		BEGIN
			SET @MENSAJE_ERROR='Factura '+@N_FACTURA+' no tiene un tipo de operación válido (FTR.TIPO_OPERACION => TGEN: ''FDIAN'', ''TIPO_OPERACION'')'
			RAISERROR (@MENSAJE_ERROR, 16, 1);  
		END
		BEGIN -- Tipo de operación y en que ambiente 
			SET @XML+=@E+@T+'<cbc:UBLVersionID>UBL 2.1</cbc:UBLVersionID>'
			SET @XML+=@E+@T+'<cbc:CustomizationID>'+@TIPONOTA+'</cbc:CustomizationID>' -- 20 Nota Crédito que referencia una factura electrónica, 22 Nota Crédito sin referencia a facturas*
			SET @XML+=@E+@T+'<cbc:ProfileID>DIAN 2.1: Nota Crédito de Factura Electrónica de Venta</cbc:ProfileID>'
			SET @XML+=@E+@T+'<cbc:ProfileExecutionID>'+CAST(@AMBIENTE AS VARCHAR)+'</cbc:ProfileExecutionID>' -- 1: Producción, 2: Pruebas
		END
		SELECT @XML+=@E+@T+'<cbc:ID>'+@PREFIJO+@CNSDOC+'</cbc:ID>'

		IF COALESCE(@CUDE,'')=''
		BEGIN
			SET @MENSAJE_ERROR='El CUDE del documento '+@PREFIJO+@CNSDOC+' es vacío'
			RAISERROR (@MENSAJE_ERROR, 16, 1);  
		END

		SET @XML+=@E+@T+'<cbc:UUID schemeName="CUDE-SHA384" schemeID="'+CAST(@AMBIENTE AS varchar)+'">'+@CUDE+'</cbc:UUID>'
		SET @XML+=@E+@T+'<cbc:IssueDate>'+REPLACE(CONVERT(VARCHAR,@F_NOTA,102),'.','-')+'</cbc:IssueDate>'
		SET @XML+=@E+@T+'<cbc:IssueTime>'+CONVERT(VARCHAR,@F_NOTA,108)+'-05:00</cbc:IssueTime>'
		SET @XML+=@E+@T+'<cbc:CreditNoteTypeCode>'+CASE WHEN @TIPODOC='NC' THEN '91' ELSE '92' END+'</cbc:CreditNoteTypeCode>'
		SET @XML+=@E+@T+'<cbc:Note>'+@OBSERVACION_FNOT+'</cbc:Note>'
		SET @XML+=@E+@T+'<cbc:DocumentCurrencyCode>'+COALESCE(@IDMONEDA,'COP')+'</cbc:DocumentCurrencyCode>'
		SET @XML+=@E+@T+'<cbc:LineCountNumeric>'+CAST(@CANT_TOTAL_ITEMS AS varchar)+'</cbc:LineCountNumeric>'
	
		SELECT @STARTDATE = CAST(CONCAT(YEAR(@F_NOTA),RIGHT('0'+CAST(MONTH(@F_NOTA) AS VARCHAR),2),'01') AS DATETIME)
		SELECT @ENDDATE = DATEADD(MONTH, ((YEAR(@F_NOTA) - 1900) * 12) + MONTH(@F_NOTA), -1)

		SET @XML+=@E+@T+'<cac:InvoicePeriod>
			<cbc:StartDate>'+REPLACE(CONVERT(VARCHAR,@STARTDATE,102),'.','-')+'</cbc:StartDate>
			<cbc:StartTime>'+CONVERT(VARCHAR,@STARTDATE,108)+'-05:00</cbc:StartTime>
			<cbc:EndDate>'+REPLACE(CONVERT(VARCHAR,@ENDDATE,102),'.','-')+'</cbc:EndDate>
			<cbc:EndTime>'+CONVERT(VARCHAR,@ENDDATE,108)+'-05:00</cbc:EndTime>
		</cac:InvoicePeriod>'

		SET @XML+=@E+@T+'<cac:DiscrepancyResponse>'
		SET @XML+=@E+@T+@T+'<cbc:ReferenceID>'+@PREFIJO+@FACTURA+'</cbc:ReferenceID>'
		SET @XML+=@E+@T+@T+'<cbc:ResponseCode>'+@IDCONCEPTO+'</cbc:ResponseCode>'
		SET @XML+=@E+@T+@T+'<cbc:Description>'+DBO.FNK_LIMPIATEXTO(COALESCE(@OBSERVACION_FNOT,''),'0-9 A-Z():;,.')+'</cbc:Description>'
		SET @XML+=@E+@T+'</cac:DiscrepancyResponse>'
		IF @TIPONOTA NOT IN ('22','32')
		BEGIN
			SET @XML+=@E+@T+'<cac:BillingReference>'
			SET @XML+=@E+@T+@T+'<cac:InvoiceDocumentReference>'
			SET @XML+=@E+@T+@T+@T+'<cbc:ID>'+@PREFIJO+@FACTURA+'</cbc:ID>'
			SET @XML+=@E+@T+@T+@T+'<cbc:UUID schemeName="CUFE-SHA384">'+@CUFE+'</cbc:UUID>'
			SET @XML+=@E+@T+@T+@T+'<cbc:IssueDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT,102),'.','-')+'</cbc:IssueDate>'
			SET @XML+=@E+@T+@T+'</cac:InvoiceDocumentReference>'
			SET @XML+=@E+@T+'</cac:BillingReference>'
		END
		SET @XML+=@E+@T+'<cac:AccountingSupplierParty>'
		SET @XML+=@E+@T+@T+'<cbc:AdditionalAccountID schemeAgencyID="195">'+@TIPO_PERSONA+'</cbc:AdditionalAccountID>' -- 1.- Persona Jurídica, 2.- Persona Natural 
		SET @XML+=@E+@T+@T+'<cac:Party>'
		SET @XML+=@E+@T+@T+@T+'<cbc:IndustryClassificationCode>'+dbo.FNK_AEC_POR_TERCERO(@IDTERCERO_OFE)+'</cbc:IndustryClassificationCode>'
		SET @XML+=@E+@T+@T+@T+'<cac:PartyName>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:Name>'+@RSOCIALFACTU+'</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+'</cac:PartyName>'
		SET @XML+=@E+@T+@T+@T+'<cac:PhysicalLocation>'
		SET @XML+=@E+@T+@T+@T+@T+'<cac:Address>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:ID>'+@CIUFACTU+'</cbc:ID>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CityName>'+@NOMCIUFACTU+'</cbc:CityName>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:PostalZone>'+@CODPOSTALFACTU+'</cbc:PostalZone>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CountrySubentity>'+@NOMDEPFACTU+'</cbc:CountrySubentity>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CountrySubentityCode>'+@CODDEPTOFACTU+'</cbc:CountrySubentityCode>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cac:AddressLine>'
		SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:Line>'+@DIRFACTU+'</cbc:Line>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'</cac:AddressLine>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cac:Country>'
		SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:IdentificationCode>CO</cbc:IdentificationCode>'
		SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:Name languageID="es">COLOMBIA</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'</cac:Country>'
		SET @XML+=@E+@T+@T+@T+@T+'</cac:Address>'
		SET @XML+=@E+@T+@T+@T+'</cac:PhysicalLocation>'
		SET @XML+=@E+@T+@T+@T+'<cac:PartyTaxScheme>'
		SET @XML+=@E+@T+@T+@T+'<cbc:RegistrationName>'+@RSOCIALFACTU+'</cbc:RegistrationName>'
		SET @XML+=@E+@T+@T+@T+'<cbc:CompanyID schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeID="'+@DV_FACTURADOR+'" schemeName="'+COALESCE(@schemeName_FACTURADOR,'31')+'">'+@NITFACTU+'</cbc:CompanyID>'
		SET @XML+=@E+@T+@T+@T+'<cbc:TaxLevelCode listName="No Aplica">'+@COD_RESPONSABILIDAD_FISCAL+'</cbc:TaxLevelCode>'
		SET @XML+=@E+@T+@T+@T+'<cac:RegistrationAddress>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID>'+@CIUFACTU+'</cbc:ID>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CityName>'+@NOMCIUFACTU+'</cbc:CityName>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:PostalZone>'+@CODPOSTALFACTU+'</cbc:PostalZone>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CountrySubentity>'+@NOMDEPFACTU+'</cbc:CountrySubentity>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CountrySubentityCode>'+@CODDEPTOFACTU+'</cbc:CountrySubentityCode>'
		SET @XML+=@E+@T+@T+@T+'<cac:AddressLine>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:Line>'+@DIRFACTU+'</cbc:Line>'
		SET @XML+=@E+@T+@T+@T+'</cac:AddressLine>'
		SET @XML+=@E+@T+@T+@T+'<cac:Country>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:IdentificationCode>CO</cbc:IdentificationCode>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Name languageID="es">COLOMBIA</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+@T+'</cac:Country>'
		SET @XML+=@E+@T+@T+@T+'</cac:RegistrationAddress>'
		SET @XML+=@E+@T+@T+@T+'<cac:TaxScheme>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID>01</cbc:ID>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:Name>IVA</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+'</cac:TaxScheme>'
		SET @XML+=@E+@T+@T+'</cac:PartyTaxScheme>'
		SET @XML+=@E+@T+@T+'<cac:PartyLegalEntity>'
		SET @XML+=@E+@T+@T+@T+'<cbc:RegistrationName>'+@RSOCIALFACTU+'</cbc:RegistrationName>'
		SET @XML+=@E+@T+@T+@T+'<cbc:CompanyID schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeID="'+@DV_FACTURADOR+'" schemeName="'+COALESCE(@schemeName_FACTURADOR,'31')+'">'+@NITFACTU+'</cbc:CompanyID>'
		SET @XML+=@E+@T+@T+@T+'<cac:CorporateRegistrationScheme>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID>'+@PREFIJO+'</cbc:ID>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:Name>'+@RSOCIALFACTU+'</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+'</cac:CorporateRegistrationScheme>'
		SET @XML+=@E+@T+@T+'</cac:PartyLegalEntity>'
		SET @XML+=@E+@T+@T+'<cac:Contact>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Name>'+@RSOCIALFACTU+'</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Telephone>'+@TELEFONO_CONTACTO+'</cbc:Telephone>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Telefax></cbc:Telefax>'
		SET @XML+=@E+@T+@T+@T+'<cbc:ElectronicMail>'+@EMAIL_CONTACTO+'</cbc:ElectronicMail>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Note></cbc:Note>'
		SET @XML+=@E+@T+@T+'</cac:Contact>'
		SET @XML+=@E+@T+'</cac:Party>'
		SET @XML+=@E+'</cac:AccountingSupplierParty>'
		SET @XML+=@E+'<cac:AccountingCustomerParty>'
		SET @XML+=@E+@T+'<cbc:AdditionalAccountID>'+CAST(@TIPO_PERSONA_ADQUIRIENTE AS varchar)+'</cbc:AdditionalAccountID>' -- 1.- Persona Jurídica, 2.- Persona Natural 
		SET @XML+=@E+@T+'<cac:Party>'
		IF LTRIM(RTRIM(@TIPO_PERSONA_ADQUIRIENTE))='2'
		BEGIN
			SET @XML+=@E+@T+@T+'<cac:PartyIdentification>'
			SET @XML+=@E+@T+@T+@T+'<cbc:ID schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeID="4" schemeName="31">222222222222</cbc:ID>'
			SET @XML+=@E+@T+@T+'</cac:PartyIdentification>'
		END
		ELSE
		BEGIN
			SET @XML+=@E+@T+@T+'<cac:PartyIdentification>'
			SET @XML+=@E+@T+@T+@T+'<cbc:ID schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeID="31" schemeName="'+@DV_ADQUIRIENTE+'">'+@NIT_ADQUIRIENTE+'</cbc:ID>'
			SET @XML+=@E+@T+@T+'</cac:PartyIdentification>'
		END
		SET @XML+=@E+@T+@T+'<cac:PartyName>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Name>'+@RAZONSOCIAL_ADQUIRIENTE+'</cbc:Name>'
		SET @XML+=@E+@T+@T+'</cac:PartyName>'
		SET @XML+=@E+@T+@T+'<cac:PhysicalLocation>'
		SET @XML+=@E+@T+@T+@T+'<cac:Address>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID>'+@CIUDAD_ADQUIRIENTE+'</cbc:ID>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CityName>'+@NOMCIUADQUI+'</cbc:CityName>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:PostalZone>'+@CODPOSTALADQUI+'</cbc:PostalZone>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CountrySubentity>'+@NOMCIUADQUI+'</cbc:CountrySubentity>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CountrySubentityCode>'+@CODDEPTOADQUI+'</cbc:CountrySubentityCode>'
		SET @XML+=@E+@T+@T+@T+@T+'<cac:AddressLine>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Line>'+@DIRADQUI+'</cbc:Line>'
		SET @XML+=@E+@T+@T+@T+@T+'</cac:AddressLine>'
		SET @XML+=@E+@T+@T+@T+@T+'<cac:Country>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:IdentificationCode>CO</cbc:IdentificationCode>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Name languageID="es">COLOMBIA</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+@T+'</cac:Country>'
		SET @XML+=@E+@T+@T+@T+'</cac:Address>'
		SET @XML+=@E+@T+@T+'</cac:PhysicalLocation>'
		SET @XML+=@E+@T+@T+'<cac:PartyTaxScheme>'
		SET @XML+=@E+@T+@T+@T+'<cbc:RegistrationName>'+@RAZONSOCIAL_ADQUIRIENTE+'</cbc:RegistrationName>'
		SET @XML+=@E+@T+@T+@T+'<cbc:CompanyID schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeID="'+@DV_ADQUIRIENTE+'" schemeName="'+COALESCE(@schemeName_ADQUIRIENTE,'31')+'">'+@NIT_ADQUIRIENTE+'</cbc:CompanyID>'
		set @CODRESPFISCALADQ='R-99-PN'
		SELECT @CODRESPFISCALADQ=COD_RESP_FISCAL FROM TER WHERE IDTERCERO=@IDTERCEROADQUI
		IF COALESCE(@CODRESPFISCALADQ,'') = '' set @CODRESPFISCALADQ='R-99-PN'
		SET @XML+=@E+@T+@T+@T+'<cbc:TaxLevelCode listName="No Aplica">'+@CODRESPFISCALADQ+'</cbc:TaxLevelCode>'
		SET @XML+=@E+@T+@T+@T+'<cac:RegistrationAddress>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID>'+@CIUDAD_ADQUIRIENTE+'</cbc:ID>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CityName>'+@NOMCIUADQUI+'</cbc:CityName>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:PostalZone>'+@CODPOSTALADQUI+'</cbc:PostalZone>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CountrySubentity>'+@NOMCIUADQUI+'</cbc:CountrySubentity>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CountrySubentityCode>'+@CODDEPTOADQUI+'</cbc:CountrySubentityCode>'
		SET @XML+=@E+@T+@T+@T+@T+'<cac:AddressLine>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Line>'+@DIRADQUI+'</cbc:Line>'
		SET @XML+=@E+@T+@T+@T+@T+'</cac:AddressLine>'
		SET @XML+=@E+@T+@T+@T+@T+'<cac:Country>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:IdentificationCode>CO</cbc:IdentificationCode>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Name languageID="es">COLOMBIA</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+@T+'</cac:Country>'
		SET @XML+=@E+@T+@T+@T+'</cac:RegistrationAddress>'
		SET @XML+=@E+@T+@T+@T+'<cac:TaxScheme>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID>01</cbc:ID>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:Name>IVA</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+'</cac:TaxScheme>'
		SET @XML+=@E+@T+@T+'</cac:PartyTaxScheme>'
		SET @XML+=@E+@T+@T+'<cac:PartyLegalEntity>'
		SET @XML+=@E+@T+@T+@T+'<cbc:RegistrationName>'+@RAZONSOCIAL_ADQUIRIENTE+'</cbc:RegistrationName>'
		SET @XML+=@E+@T+@T+@T+'<cbc:CompanyID schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeID="'+@DV_ADQUIRIENTE+'" schemeName="'+COALESCE(@schemeName_ADQUIRIENTE,'31')+'">'+@NIT_ADQUIRIENTE+'</cbc:CompanyID>'
		SET @XML+=@E+@T+@T+@T+'<cac:CorporateRegistrationScheme>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:Name>'+@RAZONSOCIAL_ADQUIRIENTE+'</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+'</cac:CorporateRegistrationScheme>'
		SET @XML+=@E+@T+@T+'</cac:PartyLegalEntity>'
		SET @XML+=@E+@T+@T+'<cac:Contact>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Name>'+@RAZONSOCIAL_ADQUIRIENTE+'</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Telephone>'+@TELCONTACTOADQUI+'</cbc:Telephone>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Telefax>'+@TELCONTACTOADQUI+'</cbc:Telefax>'
		SET @XML+=@E+@T+@T+@T+'<cbc:ElectronicMail>'+@EMAIL_ADQUIRIENTE+'</cbc:ElectronicMail>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Note></cbc:Note>'
		SET @XML+=@E+@T+@T+'</cac:Contact>'
		SET @XML+=@E+@T+'</cac:Party>'
		SET @XML+=@E+'</cac:AccountingCustomerParty>'

		IF 1=1 -- Pagos y Formas de pago
		BEGIN  
			SET @XML+=@E+'<cac:PaymentMeans>'
			SET @XML+=@E+@T+'<cbc:ID>1</cbc:ID>'
			SET @XML+=@E+@T+'<cbc:PaymentMeansCode>42</cbc:PaymentMeansCode>'
			SET @XML+=@E+@T+'<cbc:PaymentDueDate>'+REPLACE(CONVERT(VARCHAR,@F_NOTA + 30,102),'.','-')+'</cbc:PaymentDueDate>'
			SET @XML+=@E+@T+'<cbc:PaymentID>CONTADO</cbc:PaymentID>'
			SET @XML+=@E+'</cac:PaymentMeans>'


			IF COALESCE(@IDMONEDA_DESTINO,'COP') <> 'COP' AND 1=2 -- Información relacionadas con la tasa de cambio de moneda extranjera a peso colombiano 
			BEGIN
				--SELECT @CalculationRate=VALOR from mndv where dbo.fnk_fecha_sin_hora(fecha)=dbo.fnk_fecha_sin_hora(@F_NOTA)

				IF COALESCE(@CalculationRate,0)<=0
				BEGIN
					SET @MENSAJE_ERROR='La nota '+@CNSDOC+' es de moneda extranjera ('+@IDMONEDA+') y no existe tasa de cambio a la fecha '+CONVERT(VARCHAR,@F_NOTA,103)
					RAISERROR (@MENSAJE_ERROR, 16, 1); 
				END
				
				SET @XML+=@E+@T+'<cac:PaymentExchangeRate>'
				SET @XML+=@E+@T+@T+'<cbc:SourceCurrencyCode>'+COALESCE(@IDMONEDA,'COP')+'</cbc:SourceCurrencyCode>'
				SET @XML+=@E+@T+@T+'<cbc:SourceCurrencyBaseRate>1.00</cbc:SourceCurrencyBaseRate>'
				SET @XML+=@E+@T+@T+'<cbc:TargetCurrencyCode>COP</cbc:TargetCurrencyCode>' -- Debe ir diligenciado en COP, si el cbc:DocumentCurrencyCode es diferente a COP Ver lista de valores posibles en el numeral 6.3.3
				SET @XML+=@E+@T+@T+'<cbc:TargetCurrencyBaseRate>1.00</cbc:TargetCurrencyBaseRate>'
				SET @XML+=@E+@T+@T+'<cbc:CalculationRate>'+CAST(@CalculationRate AS VARCHAR)+'</cbc:CalculationRate>'
				SET @XML+=@E+@T+@T+'<cbc:Date>'+REPLACE(CONVERT(VARCHAR,@F_NOTA,102),'.','-')+'</cbc:Date>' -- FECHA DE CAMBIO
				SET @XML+=@E+@T+'</cac:PaymentExchangeRate>'
			END	
		END
		IF COALESCE(@VIVANOTA,0) > 0
		BEGIN -- Primer impuesto (IVA)
			SET @XML+=@E+@T+'<cac:TaxTotal>'
			SET @XML+=@E+@T+@T+'<cbc:TaxAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VIVANOTA AS VARCHAR)+'</cbc:TaxAmount>'
			SET @XML+=@E+@T+@T+'<cbc:RoundingAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">0.00</cbc:RoundingAmount>'
			SET @XML+=@E+@T+@T+'<cac:TaxSubtotal>'
			SET @XML+=@E+@T+@T+@T+'<cbc:TaxableAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(CAST((@VR_BASEIMPONIBLE) AS decimal(14,2)) AS VARCHAR)+'</cbc:TaxableAmount>'
			SET @XML+=@E+@T+@T+@T+'<cbc:TaxAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VIVANOTA AS VARCHAR)+'</cbc:TaxAmount>'
			SET @XML+=@E+@T+@T+@T+'<cac:TaxCategory>'
			SET @XML+=@E+@T+@T+@T+@T+'<cbc:Percent>19.00</cbc:Percent>'
			SET @XML+=@E+@T+@T+@T+@T+'<cac:TaxScheme>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:ID>01</cbc:ID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Name>IVA</cbc:Name>'
			SET @XML+=@E+@T+@T+@T+@T+'</cac:TaxScheme>'
			SET @XML+=@E+@T+@T+@T+'</cac:TaxCategory>'
			SET @XML+=@E+@T+@T+'</cac:TaxSubtotal>'
			SET @XML+=@E+@T+'</cac:TaxTotal>'
		END
		SET @XML+=@E+'<cac:LegalMonetaryTotal>'
		SET @XML+=@E+@T+'<cbc:LineExtensionAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST((@VR_NOTA-@VIVANOTA) AS varchar)+'</cbc:LineExtensionAmount>'
		SET @XML+=@E+@T+'<cbc:TaxExclusiveAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+ CASE WHEN COALESCE(@VIVANOTA,0)>0 THEN CAST((@VR_BASEIMPONIBLE) AS varchar) ELSE '0.00' END +'</cbc:TaxExclusiveAmount>'
		SET @XML+=@E+@T+'<cbc:TaxInclusiveAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VR_NOTA AS varchar)+'</cbc:TaxInclusiveAmount>'
		SET @XML+=@E+@T+'<cbc:AllowanceTotalAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">0.00</cbc:AllowanceTotalAmount>'
		SET @XML+=@E+@T+'<cbc:ChargeTotalAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">0.00</cbc:ChargeTotalAmount>'
		SET @XML+=@E+@T+'<cbc:PrepaidAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(COALESCE(@VALORCOPAGO,'0.00') AS VARCHAR)+'</cbc:PrepaidAmount>' -- Definir si se van a manejar las legalizaciones de depositos (Total anticipos)
		SET @XML+=@E+@T+'<cbc:PayableAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VR_NOTA AS varchar)+'</cbc:PayableAmount>'
		SET @XML+=@E+'</cac:LegalMonetaryTotal>'
		BEGIN -- Detalles de la Nota
			SELECT ROW_ID=ROW_NUMBER() OVER(ORDER BY ITEM ASC), DBO.FNK_LIMPIATEXTO(COALESCE(DESCRIPCION,''),'0-9 A-Z(),;.:')DESCRIPCION, CANTIDAD, VR_UNITARIO, VR_TOTAL,VALORIVA,PIVA, DBO.FNK_LIMPIATEXTO(IDSERVICIO,'0-9 A-Z(),;.:') IDSERVICIO INTO #FNOTD
			FROM FNOTD WHERE CNSFNOT=@CNSDOC AND COALESCE(VR_TOTAL,0)>0
			SELECT @CANT_LINEAS=@@ROWCOUNT, @ROW_ID=0
			WHILE @ROW_ID < @CANT_LINEAS
			BEGIN
				SET @ROW_ID+=1
				SELECT @N_CUOTA=ROW_ID
				, @ANEXO=DBO.FNK_LIMPIATEXTO(DESCRIPCION,'0-9 A-Z():;,.'), @CANTIDAD=CANTIDAD, @VALOR=VR_UNITARIO, @VLR_SERVICI=VR_TOTAL
			 , @PIVA= PIVA,@VR_IVA=COALESCE(VALORIVA,0)
			 , @REFERENCIA=IDSERVICIO 
				FROM #FNOTD 
            WHERE ROW_ID=@ROW_ID
				SET @XML+=@E+@T+'<cac:CreditNoteLine>'
				SET @XML+=@E+@T+@T+'<cbc:ID>'+CAST(@N_CUOTA AS varchar)+'</cbc:ID>'
			
				SET @XML+=@E+@T+@T+'<cbc:Note>'+@ANEXO+'</cbc:Note>'
				SET @XML+=@E+@T+@T+'<cbc:CreditedQuantity unitCode="EA">'+CAST(@CANTIDAD AS varchar)+'</cbc:CreditedQuantity>'
				SET @XML+=@E+@T+@T+'<cbc:LineExtensionAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST((@VLR_SERVICI-@VR_IVA) AS varchar)+'</cbc:LineExtensionAmount>'
				SET @XML+=@E+@T+@T+'<cbc:FreeOfChargeIndicator>false</cbc:FreeOfChargeIndicator>'
				IF COALESCE(@VR_IVA,0)>0
				BEGIN
					PRINT '@BASE_IVA_SERVICIOS = ' + @BASE_IVA_SERVICIOS
					SET @XML+=@E+@T+@T+'<cac:TaxTotal>'
					SET @XML+=@E+@T+@T+@T+'<cbc:TaxAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VR_IVA AS varchar)+'</cbc:TaxAmount>'
					SET @XML+=@E+@T+@T+@T+'<cac:TaxSubtotal>'
					SET @XML+=@E+@T+@T+@T+@T+'<cbc:TaxableAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CASE WHEN @VR_IVA>0 THEN CAST(@VLR_SERVICI - CASE WHEN @BASE_IVA_SERVICIOS='CONIVA' THEN @VR_IVA ELSE 0 END AS varchar) ELSE '0.00' END+'</cbc:TaxableAmount>' -- Monto Imponible 
					SET @XML+=@E+@T+@T+@T+@T+'<cbc:TaxAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VR_IVA AS varchar)+'</cbc:TaxAmount>' -- Total
					SET @XML+=@E+@T+@T+@T+@T+'<cac:TaxCategory>'
					SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Percent>19.00</cbc:Percent>'
					SET @XML+=@E+@T+@T+@T+@T+@T+'<cac:TaxScheme>'
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:ID>01</cbc:ID>'
					SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:Name>IVA</cbc:Name>'
					SET @XML+=@E+@T+@T+@T+@T+@T+'</cac:TaxScheme>'
					SET @XML+=@E+@T+@T+@T+@T+'</cac:TaxCategory>'
					SET @XML+=@E+@T+@T+@T+'</cac:TaxSubtotal>'
					SET @XML+=@E+@T+@T+'</cac:TaxTotal>'
				END
				SET @XML+=@E+@T+@T+'<cac:Item>'
				SET @XML+=@E+@T+@T+@T+'<cbc:Description>'+@ANEXO+'</cbc:Description>'
				SET @XML+=@E+@T+@T+@T+'<cbc:PackSizeNumeric>1</cbc:PackSizeNumeric>'
				SET @XML+=@E+@T+@T+@T+'<cbc:BrandName></cbc:BrandName>'
				SET @XML+=@E+@T+@T+@T+'<cbc:ModelName></cbc:ModelName>'
				SET @XML+=@E+@T+@T+@T+'<cac:SellersItemIdentification>'
				SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID>'+@REFERENCIA+'</cbc:ID>'
				SET @XML+=@E+@T+@T+@T+@T+'<cbc:ExtendedID></cbc:ExtendedID>'
				SET @XML+=@E+@T+@T+@T+'</cac:SellersItemIdentification>'
				SET @XML+=@E+@T+@T+@T+'<cac:StandardItemIdentification>'
				SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID schemeID="999" schemeName="Estándar de adopción del contribuyente" schemeAgencyID="">'+@REFERENCIA+'</cbc:ID>'
				SET @XML+=@E+@T+@T+@T+'</cac:StandardItemIdentification>'

				SET @XML+=@E+@T+@T+'</cac:Item>'
				SET @XML+=@E+@T+@T+'<cac:Price>'
				SET @XML+=@E+@T+@T+@T+'<cbc:PriceAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VALOR AS varchar)+'</cbc:PriceAmount>'
				SET @XML+=@E+@T+@T+@T+'<cbc:BaseQuantity unitCode="EA">'+CAST(@CANTIDAD AS varchar)+'</cbc:BaseQuantity>'
				SET @XML+=@E+@T+@T+'</cac:Price>'
				SET @XML+=@E+@T+'</cac:CreditNoteLine>'
			END
		END
		SELECT @XML+=@E+'</CreditNote>'
	END
	IF @TIPODOC='ND'
	BEGIN
		BEGIN -- Datos de la Factura
			SELECT @N_FACTURA=N_FACTURA FROM FNOT WHERE CNSFNOT=@CNSDOC
			SELECT @CNSRESOL=CNSRESOLFE, @PREFIJO=COALESCE(PREFIJODIANFE,''), @FACTURA=CNSDIANFE, @CNSFCT=CNSFCT 
				,@TIPO_DOCUMENTO=COALESCE(TIPO_DOCUMENTO, '01')
				,@TIPO_OPERACION=COALESCE(TIPO_OPERACION, '10')
				,@FECHA_FACT=F_FACTURA
				,@VR_FACTURA=CAST(VALORSERVICIOS AS DECIMAL(14,2))
			FROM FTR WHERE N_FACTURA=@N_FACTURA
			SELECT @CUFE=CUFE FROM FTRE WHERE N_FACTURA=@FACTURA AND PREFIJO=@PREFIJO
		END
		BEGIN -- Datos de la Nota
			SELECT @F_NOTA=F_NOTA, @IDCONCEPTO=IDCONCEPTO, @OBSERVACION_FNOT=OBSERVACION, @VR_NOTA=VR_TOTAL FROM FNOT WHERE CNSFNOT=@CNSDOC
			SELECT @IDCONCEPTO=CASE WHEN @TIPODOC='NC' THEN HOMOLOGODIANCR ELSE HOMOLOGODIANDB END FROM CPNT WHERE CODIGO=@IDCONCEPTO
			IF COALESCE(@IDCONCEPTO,'')=''
			BEGIN	
				SET @MENSAJE_ERROR='La nota '+@CNSDOC+' no tiene un concepto válido'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			SELECT @CANT_TOTAL_ITEMS=COUNT(*) FROM FNOTD WHERE CNSFNOT=@CNSDOC AND COALESCE(VR_TOTAL,0)>0
		END
		BEGIN -- Adquiriente
			--------------------------------------------------------------------------------------------------------------------------------------------------------------
			SELECT @NIT_ADQUIRIENTE=TER.NIT, @DV_ADQUIRIENTE=COALESCE(TER.DV,''), @RAZONSOCIAL_ADQUIRIENTE=REPLACE(TER.RAZONSOCIAL,'&','&amp;'), @CIUDAD_ADQUIRIENTE=TER.CIUDAD, @DIRADQUI=dbo.FNK_LIMPIATEXTO(TER.DIRECCION, '0-9 A-Z().;:,')
				,@TELCONTACTOADQUI=dbo.FNK_LIMPIATEXTO(COALESCE(TER.TELEFONOS,''),'0-9'), @FAXCONTACTOADQUI=COALESCE(TER.FAX,''), @EMAIL_ADQUIRIENTE=COALESCE(TER.EMAIL,TER.EMAIL_RL,TER.EMAIL_TH,@EMAIL_CONTACTO,'')
				,@CODRESPFISCALADQ=COALESCE(TER.COD_RESP_FISCAL,'O-99')
				,@CODPOSTALADQUI=COALESCE(CIU.CODPOSTAL,CIU.CIUDAD,'')		
				,@IDTERCEROADQUI=TER.IDTERCERO
			FROM FTR INNER JOIN TER ON TER.IDTERCERO=FTR.IDTERCERO 
				LEFT JOIN CIU ON CIU.CIUDAD=TER.CIUDAD
				LEFT JOIN DEP ON DEP.DPTO=CIU.DPTO
			WHERE CNSFCT=@CNSFCT
				
			-- Eliminar caracteres raros de email del adquiriente
			select @EMAIL_ADQUIRIENTE=dbo.FNK_LIMPIATEXTO(@email_adquiriente,'a-zA-Z0-9@._')

			SELECT @TIPO_PERSONA_ADQUIRIENTE=CASE WHEN TIPO_ID='NIT' THEN 1 ELSE 2 END 
				,@NOMCONTACTOADQUI=@RAZONSOCIAL_ADQUIRIENTE
				,@schemeName_ADQUIRIENTE=(SELECT TOP 1 DATO1 FROM TGEN WHERE TABLA='GENERAL' AND CAMPO='TIPOIDENT' AND CODIGO=TER.TIPO_ID)
			FROM TER WHERE IDTERCERO=(SELECT IDTERCERO FROM FTR WHERE CNSFCT=@CNSFCT)

			SELECT @NOMCIUADQUI=CIU.NOMBRE, @CODDEPTOADQUI=DEP.COD_DIAN FROM CIU INNER JOIN DEP ON DEP.DPTO=CIU.DPTO WHERE CIUDAD=@CIUDAD_ADQUIRIENTE

			IF COALESCE(@NIT_ADQUIRIENTE,'')=''
			BEGIN
				SET @MENSAJE_ERROR='NIT del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			IF COALESCE(@RAZONSOCIAL_ADQUIRIENTE,'')='' 
			BEGIN
				SET @MENSAJE_ERROR='Razón social del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END 
			IF COALESCE(@CIUDAD_ADQUIRIENTE,'')='' RAISERROR ('Ciudad del adquiriente sin configurar', 16, 1); 
			IF COALESCE(@DIRADQUI,'')='' 
			BEGIN
				SET @MENSAJE_ERROR='Dirección del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END 
			IF COALESCE(@TELCONTACTOADQUI,'')='' 
			BEGIN
				SET @MENSAJE_ERROR='Teléfono del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END 
			IF COALESCE(@EMAIL_ADQUIRIENTE,'')='' 
			BEGIN
				SET @MENSAJE_ERROR='Email del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			IF COALESCE(@CODRESPFISCALADQ,'')='' 
			BEGIN
				SET @MENSAJE_ERROR='Responsabilidad fiscal del adquiriente de la factura '+@N_FACTURA+' sin configurar'
				RAISERROR (@MENSAJE_ERROR, 16, 1); 
			END
			--------------------------------------------------------------------------------------------------------------------------------------------------------------
		END
		BEGIN -- Persona de Contacto
			SELECT @NOMBRE_CONTACTO=DESCRIPCION FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='CONTACTO' AND CODIGO='NOMBRE'
			SELECT @TELEFONO_CONTACTO=dbo.FNK_LIMPIATEXTO(DESCRIPCION,'0-9') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='CONTACTO' AND CODIGO='TELEFONO'
			SELECT @EMAIL_CONTACTO=DESCRIPCION FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='CONTACTO' AND CODIGO='EMAIL'
			SELECT @FAX_CONTACTO=COALESCE(DESCRIPCION,'') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='CONTACTO' AND CODIGO='FAX'
			IF COALESCE(@NOMBRE_CONTACTO,'')='' RAISERROR ('Nombre de contacto de OFE es obligatorio. (TGEN => ''FDIAN'', ''CONTACTO'', ''NOMBRE'')', 16, 1); 
			IF COALESCE(@TELEFONO_CONTACTO,'')='' RAISERROR ('Teléfono de contacto de OFE es obligatorio. (TGEN => ''FDIAN'', ''CONTACTO'', ''TELEFONO'')', 16, 1); 
			IF COALESCE(@EMAIL_CONTACTO,'')='' RAISERROR ('Email de contacto de OFE es obligatorio. (TGEN => ''FDIAN'', ''CONTACTO'', ''EMAIL'')', 16, 1); 
		END

		BEGIN -- Tipo de Nota de Débito
			SELECT @TIPONOTA = '30'
			IF EXISTS(SELECT 1 FROM FNOT WHERE CNSFNOT=@CNSDOC AND COALESCE(FNOT.NOTA_SIN_FACTURA, 0)=1) SELECT @TIPONOTA = '32'
		END
	   IF COALESCE(@TIPONOTA,'')<>'32'
	   BEGIN
		   IF NOT EXISTS(SELECT * FROM FTR WHERE N_FACTURA=@N_FACTURA AND COALESCE(CNSDIANFE,'')<>'' AND COALESCE(CNSRESOLFE,'')<>'' AND FACTE=2 )
		   BEGIN
			   SET @MENSAJE_ERROR='Factura ' + @N_FACTURA + ' no validada previamente ante la DIAN'+'@TIPONOTA ='+@TIPONOTA
			   RAISERROR (@MENSAJE_ERROR, 16, 1); 
		   END
		   IF COALESCE(@CNSRESOL,'')='' AND COALESCE(@TIPONOTA,'')<>'32'
		   BEGIN
			   SET @MENSAJE_ERROR='Factura '+@N_FACTURA+' sin resolución'
			   RAISERROR (@MENSAJE_ERROR, 16, 1); 
		   END
	   END
		IF @CANT_TOTAL_ITEMS<=0
		BEGIN
			SET @MENSAJE_ERROR='Nota '+@CNSDOC+' sin items en el detalle'
			RAISERROR (@MENSAJE_ERROR, 16, 1); 
		END
		BEGIN -- Datos de la Resolución DIAN
			SELECT @VENCIDA=VENCIDA,@FTRELECTRONICA=FTRELECTRONICA, @FINIRESOL=FECHAINI,@FFINRESOL=FECHAVEN, @PREFIJO=COALESCE(PREFIJO,'')
				,@CNSINICIAL=CNSINICIAL ,@CNSFINAL=CNSFINAL ,@CNSACTUAL=CNSACTUAL+1, @CLAVE_TECNICA=CLAVETECNICA, @AMBIENTE=AMBIENTE
			FROM FDIAN WHERE CNSRESOL=@CNSRESOL
		END
			
		SELECT  @CUDE=dbo.FNK_GENERAR_CUFE_CUDE(@TIPODOC,@CNSDOC, @NITFACTU, '', '', @AMBIENTE)
		IF @AMBIENTE=2 AND COALESCE(@TESTSETID,'')='' RAISERROR ('El identificador de pruebas (TestSetId) es obligatorio en el ambiente de pruebas. (TGEN => ''FDIAN'', ''SOFTWARE'', ''TESTSETID'')', 16, 1); 
			
		SELECT @QR_CODE=DBO.FNK_QRCODE(@N_FACTURA)
		IF COALESCE(@QR_CODE,'')=''
			SELECT @QR_CODE='NroNota='+@CNSDOC+', NroFactura='+COALESCE(@PREFIJO,'')+@FACTURA+', NitFacturador='+@NITFACTU+', NitAdquiriente='+@NIT_ADQUIRIENTE+', CUFE=' + @CUFE
		SET @SoftwareSecurityCode=@SoftwareID+@SoftwarePIN+@PREFIJO+@CNSDOC -- SoftwareSecurityCode:= SHA-384 (Id Software + Pin + NroDocumento[Con Prefijo])
		SET @XML='<?xml version="1.0" encoding="UTF-8" standalone="no"?>'
		SET @XML+=@E+'<DebitNote xmlns="urn:oasis:names:specification:ubl:schema:xsd:DebitNote-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" xmlns:sts="dian:gov:co:facturaelectronica:Structures-2-1" xmlns:xades="http://uri.etsi.org/01903/v1.3.2#" xmlns:xades141="http://uri.etsi.org/01903/v1.4.1#" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:oasis:names:specification:ubl:schema:xsd:DebitNote-2     &#xD;&#xA;http://docs.oasis-open.org/ubl/os-UBL-2.1/xsd/maindoc/UBL-DebitNote-2.1.xsd">'
		SET @XML+=@E+@T+'<ext:UBLExtensions>'
		SET @XML+=@E+@T+@T+'<ext:UBLExtension>'
		SET @XML+=@E+@T+@T+@T+'<ext:ExtensionContent>'
		SET @XML+=@E+@T+@T+@T+@T+'<sts:DianExtensions>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<sts:InvoiceSource>'
		SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:IdentificationCode listAgencyID="6" listAgencyName="United Nations Economic Commission for Europe" listSchemeURI="urn:oasis:names:specification:ubl:codelist:gc:CountryIdentificationCode-2.1">CO</cbc:IdentificationCode>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'</sts:InvoiceSource>'
		BEGIN -- Datos del Software Electronico
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<sts:SoftwareProvider>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+'<sts:ProviderID schemeName="'+COALESCE(@schemeName_FACTURADOR,'31')+'" schemeID="'+@DV_FACTURADOR+'" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeAgencyID="195">'+@NITFACTU+'</sts:ProviderID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+@T+'<sts:SoftwareID schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)">'+@SoftwareID+'</sts:SoftwareID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'</sts:SoftwareProvider>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<sts:SoftwareSecurityCode schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeAgencyID="195">'+@SoftwareSecurityCode+'</sts:SoftwareSecurityCode>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'<sts:AuthorizationProvider>'
			SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<sts:AuthorizationProviderID schemeID="4" schemeName="31" schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)">'+@NIT_DIAN+'</sts:AuthorizationProviderID>'
			SET @XML+=@E+@T+@T+@T+@T+@T+'</sts:AuthorizationProvider>'
		END
		SELECT @XML+=@E+@T+@T+@T+@T+@T+'<sts:QRCode>'+@QR_CODE+'</sts:QRCode>'
		SET @XML+=@E+@T+@T+@T+@T+'</sts:DianExtensions>'
		SET @XML+=@E+@T+@T+@T+'</ext:ExtensionContent>'
		SET @XML+=@E+@T+@T+'</ext:UBLExtension>'
		SET @XML+=@E+@T+@T+'<ext:UBLExtension>'
		SET @XML+=@E+@T+@T+@T+'<ext:ExtensionContent></ext:ExtensionContent>'
		SET @XML+=@E+@T+@T+'</ext:UBLExtension>'
		SET @XML+=@E+@T+'</ext:UBLExtensions>'
		BEGIN -- Tipo de operación y en que ambiente 
			SET @XML+=@E+@T+'<cbc:UBLVersionID>UBL 2.1</cbc:UBLVersionID>'
			SET @XML+=@E+@T+'<cbc:CustomizationID>'+@TIPONOTA+'</cbc:CustomizationID>'  -- 30 Nota Débito que referencia una factura electrónica, 32 Nota Débito sin referencia a facturas*
			SET @XML+=@E+@T+'<cbc:ProfileID>DIAN 2.1: Nota Débito de Factura Electrónica de Venta</cbc:ProfileID>'
			SET @XML+=@E+@T+'<cbc:ProfileExecutionID>'+CAST(@AMBIENTE AS VARCHAR)+'</cbc:ProfileExecutionID>' -- 1: Producción, 2: Pruebas
		END
		SET @XML+=@E+@T+'<cbc:ID>'+@PREFIJO+@CNSDOC+'</cbc:ID>'
		SET @XML+=@E+@T+'<cbc:UUID schemeName="CUDE-SHA384" schemeID="'+CAST(@AMBIENTE AS varchar)+'">'+@CUDE+'</cbc:UUID>'
		SET @XML+=@E+@T+'<cbc:IssueDate>'+REPLACE(CONVERT(VARCHAR,@F_NOTA,102),'.','-')+'</cbc:IssueDate>'
		SET @XML+=@E+@T+'<cbc:IssueTime>'+CONVERT(VARCHAR,@F_NOTA,108)+'-05:00</cbc:IssueTime>'
		SET @XML+=@E+@T+'<cbc:Note>'+@OBSERVACION_FNOT+'</cbc:Note>'
		SET @XML+=@E+@T+'<cbc:DocumentCurrencyCode>'+COALESCE(@IDMONEDA,'COP')+'</cbc:DocumentCurrencyCode>'
		SET @XML+=@E+@T+'<cbc:LineCountNumeric>'+CAST(@CANT_TOTAL_ITEMS AS varchar)+'</cbc:LineCountNumeric>'
	
		SELECT @STARTDATE = CAST(CONCAT(YEAR(@F_NOTA),RIGHT('0'+CAST(MONTH(@F_NOTA) AS VARCHAR),2),'01') AS DATETIME)
		SELECT @ENDDATE = DATEADD(MONTH, ((YEAR(@F_NOTA) - 1900) * 12) + MONTH(@F_NOTA), -1)

		SET @XML+=@E+@T+'<cac:InvoicePeriod>
			<cbc:StartDate>'+REPLACE(CONVERT(VARCHAR,@STARTDATE,102),'.','-')+'</cbc:StartDate>
			<cbc:StartTime>'+CONVERT(VARCHAR,@STARTDATE,108)+'-05:00</cbc:StartTime>
			<cbc:EndDate>'+REPLACE(CONVERT(VARCHAR,@ENDDATE,102),'.','-')+'</cbc:EndDate>
			<cbc:EndTime>'+CONVERT(VARCHAR,@ENDDATE,108)+'-05:00</cbc:EndTime>
		</cac:InvoicePeriod>'

		SET @XML+=@E+@T+'<cac:DiscrepancyResponse>'
		SET @XML+=@E+@T+@T+'<cbc:ReferenceID>'+@PREFIJO+@FACTURA+'</cbc:ReferenceID>'
		SET @XML+=@E+@T+@T+'<cbc:ResponseCode>'+@IDCONCEPTO+'</cbc:ResponseCode>'
		SET @XML+=@E+@T+@T+'<cbc:Description>'+COALESCE(@OBSERVACION_FNOT,'')+'</cbc:Description>'
		SET @XML+=@E+@T+'</cac:DiscrepancyResponse>'
		IF @TIPONOTA NOT IN ('22','32')
		BEGIN
			SET @XML+=@E+@T+'<cac:BillingReference>'
			SET @XML+=@E+@T+@T+'<cac:InvoiceDocumentReference>'
			SET @XML+=@E+@T+@T+@T+'<cbc:ID>'+@PREFIJO+@FACTURA+'</cbc:ID>'
			SET @XML+=@E+@T+@T+@T+'<cbc:UUID schemeName="CUFE-SHA384">'+@CUFE+'</cbc:UUID>'
			SET @XML+=@E+@T+@T+@T+'<cbc:IssueDate>'+REPLACE(CONVERT(VARCHAR,@FECHA_FACT,102),'.','-')+'</cbc:IssueDate>'
			SET @XML+=@E+@T+@T+'</cac:InvoiceDocumentReference>'
			SET @XML+=@E+@T+'</cac:BillingReference>'
		END
		SET @XML+=@E+@T+'<cac:AccountingSupplierParty>'
		SET @XML+=@E+@T+@T+'<cbc:AdditionalAccountID schemeAgencyID="195">'+@TIPO_PERSONA+'</cbc:AdditionalAccountID>' -- 1.- Persona Jurídica, 2.- Persona Natural 
		SET @XML+=@E+@T+@T+'<cac:Party>'
		SET @XML+=@E+@T+@T+@T+'<cbc:IndustryClassificationCode>'+dbo.FNK_AEC_POR_TERCERO(@IDTERCERO_OFE)+'</cbc:IndustryClassificationCode>'
		SET @XML+=@E+@T+@T+@T+'<cac:PartyName>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:Name>'+@RSOCIALFACTU+'</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+'</cac:PartyName>'
		SET @XML+=@E+@T+@T+@T+'<cac:PhysicalLocation>'
		SET @XML+=@E+@T+@T+@T+@T+'<cac:Address>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:ID>'+@CIUFACTU+'</cbc:ID>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CityName>'+@NOMCIUFACTU+'</cbc:CityName>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:PostalZone>'+@CODPOSTALFACTU+'</cbc:PostalZone>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CountrySubentity>'+@NOMDEPFACTU+'</cbc:CountrySubentity>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:CountrySubentityCode>'+@CODDEPTOFACTU+'</cbc:CountrySubentityCode>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cac:AddressLine>'
		SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:Line>'+@DIRFACTU+'</cbc:Line>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'</cac:AddressLine>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cac:Country>'
		SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:IdentificationCode>CO</cbc:IdentificationCode>'
		SET @XML+=@E+@T+@T+@T+@T+@T+@T+'<cbc:Name languageID="es">COLOMBIA</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'</cac:Country>'
		SET @XML+=@E+@T+@T+@T+@T+'</cac:Address>'
		SET @XML+=@E+@T+@T+@T+'</cac:PhysicalLocation>'
		SET @XML+=@E+@T+@T+@T+'<cac:PartyTaxScheme>'
		SET @XML+=@E+@T+@T+@T+'<cbc:RegistrationName>'+@RSOCIALFACTU+'</cbc:RegistrationName>'
		SET @XML+=@E+@T+@T+@T+'<cbc:CompanyID schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeID="'+@DV_FACTURADOR+'" schemeName="'+COALESCE(@schemeName_FACTURADOR,'31')+'">'+@NITFACTU+'</cbc:CompanyID>'
		SET @XML+=@E+@T+@T+@T+'<cbc:TaxLevelCode listName="No Aplica">'+@COD_RESPONSABILIDAD_FISCAL+'</cbc:TaxLevelCode>'
		SET @XML+=@E+@T+@T+@T+'<cac:RegistrationAddress>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID>'+@CIUFACTU+'</cbc:ID>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CityName>'+@NOMCIUFACTU+'</cbc:CityName>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:PostalZone>'+@CODPOSTALFACTU+'</cbc:PostalZone>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CountrySubentity>'+@NOMDEPFACTU+'</cbc:CountrySubentity>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CountrySubentityCode>'+@CODDEPTOFACTU+'</cbc:CountrySubentityCode>'
		SET @XML+=@E+@T+@T+@T+'<cac:AddressLine>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:Line>'+@DIRFACTU+'</cbc:Line>'
		SET @XML+=@E+@T+@T+@T+'</cac:AddressLine>'
		SET @XML+=@E+@T+@T+@T+'<cac:Country>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:IdentificationCode>CO</cbc:IdentificationCode>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Name languageID="es">COLOMBIA</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+@T+'</cac:Country>'
		SET @XML+=@E+@T+@T+@T+'</cac:RegistrationAddress>'
		SET @XML+=@E+@T+@T+@T+'<cac:TaxScheme>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID>01</cbc:ID>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:Name>IVA</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+'</cac:TaxScheme>'
		SET @XML+=@E+@T+@T+'</cac:PartyTaxScheme>'
		SET @XML+=@E+@T+@T+'<cac:PartyLegalEntity>'
		SET @XML+=@E+@T+@T+@T+'<cbc:RegistrationName>'+@RSOCIALFACTU+'</cbc:RegistrationName>'
		SET @XML+=@E+@T+@T+@T+'<cbc:CompanyID schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeID="'+@DV_FACTURADOR+'" schemeName="'+COALESCE(@schemeName_FACTURADOR,'31')+'">'+@NITFACTU+'</cbc:CompanyID>'
		SET @XML+=@E+@T+@T+@T+'<cac:CorporateRegistrationScheme>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID>'+@PREFIJO+'</cbc:ID>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:Name>'+@RSOCIALFACTU+'</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+'</cac:CorporateRegistrationScheme>'
		SET @XML+=@E+@T+@T+'</cac:PartyLegalEntity>'
		SET @XML+=@E+@T+@T+'<cac:Contact>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Name>'+@RSOCIALFACTU+'</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Telephone>'+@TELEFONO_CONTACTO+'</cbc:Telephone>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Telefax></cbc:Telefax>'
		SET @XML+=@E+@T+@T+@T+'<cbc:ElectronicMail>'+@EMAIL_CONTACTO+'</cbc:ElectronicMail>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Note></cbc:Note>'
		SET @XML+=@E+@T+@T+'</cac:Contact>'
		SET @XML+=@E+@T+'</cac:Party>'
		SET @XML+=@E+'</cac:AccountingSupplierParty>'
		SET @XML+=@E+'<cac:AccountingCustomerParty>'
		SET @XML+=@E+@T+'<cbc:AdditionalAccountID>'+CAST(@TIPO_PERSONA_ADQUIRIENTE AS varchar)+'</cbc:AdditionalAccountID>' -- 1.- Persona Jurídica, 2.- Persona Natural 
		SET @XML+=@E+@T+'<cac:Party>'
		IF LTRIM(RTRIM(@TIPO_PERSONA_ADQUIRIENTE))='2'
		BEGIN
			SET @XML+=@E+@T+@T+'<cac:PartyIdentification>'
			SET @XML+=@E+@T+@T+@T+'<cbc:ID schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeID="4" schemeName="31">222222222222</cbc:ID>'
			SET @XML+=@E+@T+@T+'</cac:PartyIdentification>'
		END
		ELSE
		BEGIN
			SET @XML+=@E+@T+@T+'<cac:PartyIdentification>'
			SET @XML+=@E+@T+@T+@T+'<cbc:ID schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeID="31" schemeName="'+@DV_ADQUIRIENTE+'">'+@NIT_ADQUIRIENTE+'</cbc:ID>'
			SET @XML+=@E+@T+@T+'</cac:PartyIdentification>'
		END
		SET @XML+=@E+@T+@T+'<cac:PartyName>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Name>'+@RAZONSOCIAL_ADQUIRIENTE+'</cbc:Name>'
		SET @XML+=@E+@T+@T+'</cac:PartyName>'
		SET @XML+=@E+@T+@T+'<cac:PhysicalLocation>'
		SET @XML+=@E+@T+@T+@T+'<cac:Address>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID>'+@CIUDAD_ADQUIRIENTE+'</cbc:ID>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CityName>'+@NOMCIUADQUI+'</cbc:CityName>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:PostalZone>'+@CODPOSTALADQUI+'</cbc:PostalZone>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CountrySubentity>'+@NOMCIUADQUI+'</cbc:CountrySubentity>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CountrySubentityCode>'+@CODDEPTOADQUI+'</cbc:CountrySubentityCode>'
		SET @XML+=@E+@T+@T+@T+@T+'<cac:AddressLine>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Line>'+@DIRADQUI+'</cbc:Line>'
		SET @XML+=@E+@T+@T+@T+@T+'</cac:AddressLine>'
		SET @XML+=@E+@T+@T+@T+@T+'<cac:Country>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:IdentificationCode>CO</cbc:IdentificationCode>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Name languageID="es">COLOMBIA</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+@T+'</cac:Country>'
		SET @XML+=@E+@T+@T+@T+'</cac:Address>'
		SET @XML+=@E+@T+@T+'</cac:PhysicalLocation>'
		SET @XML+=@E+@T+@T+'<cac:PartyTaxScheme>'
		SET @XML+=@E+@T+@T+@T+'<cbc:RegistrationName>'+@RAZONSOCIAL_ADQUIRIENTE+'</cbc:RegistrationName>'
		SET @XML+=@E+@T+@T+@T+'<cbc:CompanyID schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeID="'+@DV_ADQUIRIENTE+'" schemeName="'+COALESCE(@schemeName_ADQUIRIENTE,'31')+'">'+@NIT_ADQUIRIENTE+'</cbc:CompanyID>'
		set @CODRESPFISCALADQ='R-99-PN'
		SELECT @CODRESPFISCALADQ=COD_RESP_FISCAL FROM TER WHERE IDTERCERO=@IDTERCEROADQUI
		IF COALESCE(@CODRESPFISCALADQ,'') = '' set @CODRESPFISCALADQ='R-99-PN'
		SET @XML+=@E+@T+@T+@T+'<cbc:TaxLevelCode listName="No Aplica">'+@CODRESPFISCALADQ+'</cbc:TaxLevelCode>'
		SET @XML+=@E+@T+@T+@T+'<cac:RegistrationAddress>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID>'+@CIUDAD_ADQUIRIENTE+'</cbc:ID>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CityName>'+@NOMCIUADQUI+'</cbc:CityName>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:PostalZone>'+@CODPOSTALADQUI+'</cbc:PostalZone>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CountrySubentity>'+@NOMCIUADQUI+'</cbc:CountrySubentity>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:CountrySubentityCode>'+@CODDEPTOADQUI+'</cbc:CountrySubentityCode>'
		SET @XML+=@E+@T+@T+@T+@T+'<cac:AddressLine>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Line>'+@DIRADQUI+'</cbc:Line>'
		SET @XML+=@E+@T+@T+@T+@T+'</cac:AddressLine>'
		SET @XML+=@E+@T+@T+@T+@T+'<cac:Country>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:IdentificationCode>CO</cbc:IdentificationCode>'
		SET @XML+=@E+@T+@T+@T+@T+@T+'<cbc:Name languageID="es">COLOMBIA</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+@T+'</cac:Country>'
		SET @XML+=@E+@T+@T+@T+'</cac:RegistrationAddress>'
		SET @XML+=@E+@T+@T+@T+'<cac:TaxScheme>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID>01</cbc:ID>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:Name>IVA</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+'</cac:TaxScheme>'
		SET @XML+=@E+@T+@T+'</cac:PartyTaxScheme>'
		SET @XML+=@E+@T+@T+'<cac:PartyLegalEntity>'
		SET @XML+=@E+@T+@T+@T+'<cbc:RegistrationName>'+@RAZONSOCIAL_ADQUIRIENTE+'</cbc:RegistrationName>'
		SET @XML+=@E+@T+@T+@T+'<cbc:CompanyID schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)" schemeID="'+@DV_ADQUIRIENTE+'" schemeName="'+COALESCE(@schemeName_ADQUIRIENTE,'31')+'">'+@NIT_ADQUIRIENTE+'</cbc:CompanyID>'
		SET @XML+=@E+@T+@T+@T+'<cac:CorporateRegistrationScheme>'
		SET @XML+=@E+@T+@T+@T+@T+'<cbc:Name>'+@RAZONSOCIAL_ADQUIRIENTE+'</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+'</cac:CorporateRegistrationScheme>'
		SET @XML+=@E+@T+@T+'</cac:PartyLegalEntity>'
		SET @XML+=@E+@T+@T+'<cac:Contact>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Name>'+@RAZONSOCIAL_ADQUIRIENTE+'</cbc:Name>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Telephone>'+@TELCONTACTOADQUI+'</cbc:Telephone>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Telefax>'+@TELCONTACTOADQUI+'</cbc:Telefax>'
		SET @XML+=@E+@T+@T+@T+'<cbc:ElectronicMail>'+@EMAIL_ADQUIRIENTE+'</cbc:ElectronicMail>'
		SET @XML+=@E+@T+@T+@T+'<cbc:Note></cbc:Note>'
		SET @XML+=@E+@T+@T+'</cac:Contact>'
		SET @XML+=@E+@T+'</cac:Party>'
		SET @XML+=@E+'</cac:AccountingCustomerParty>'
		BEGIN  
			SET @XML+=@E+'<cac:PaymentMeans>'
			SET @XML+=@E+@T+'<cbc:ID>1</cbc:ID>'
			SET @XML+=@E+@T+'<cbc:PaymentMeansCode>42</cbc:PaymentMeansCode>'
			SET @XML+=@E+@T+'<cbc:PaymentDueDate>'+REPLACE(CONVERT(VARCHAR,@F_NOTA + 30,102),'.','-')+'</cbc:PaymentDueDate>'
			SET @XML+=@E+@T+'<cbc:PaymentID>CONTADO</cbc:PaymentID>'
			SET @XML+=@E+'</cac:PaymentMeans>'
			IF COALESCE(@IDMONEDA,'COP') <> 'COP' -- Información relacionadas con la tasa de cambio de moneda extranjera a peso colombiano 
			BEGIN
				SELECT @CalculationRate=VALOR from mndv where dbo.fnk_fecha_sin_hora(fecha)=dbo.fnk_fecha_sin_hora(@F_NOTA)
				IF COALESCE(@CalculationRate,0)<=0
				BEGIN
					SET @MENSAJE_ERROR='La nota '+@CNSDOC+' es de moneda extranjera ('+@IDMONEDA+') y no existe tasa de cambio a la fecha '+CONVERT(VARCHAR,@F_NOTA,103)
					RAISERROR (@MENSAJE_ERROR, 16, 1); 
				END
				SET @XML+=@E+@T+'<cac:PaymentExchangeRate>'
				SET @XML+=@E+@T+@T+'<cbc:SourceCurrencyCode>'+COALESCE(@IDMONEDA,'COP')+'</cbc:SourceCurrencyCode>'
				SET @XML+=@E+@T+@T+'<cbc:SourceCurrencyBaseRate>1.00</cbc:SourceCurrencyBaseRate>'
				SET @XML+=@E+@T+@T+'<cbc:TargetCurrencyCode>COP</cbc:TargetCurrencyCode>' -- Debe ir diligenciado en COP, si el cbc:DocumentCurrencyCode es diferente a COP Ver lista de valores posibles en el numeral 6.3.3
				SET @XML+=@E+@T+@T+'<cbc:TargetCurrencyBaseRate>1.00</cbc:TargetCurrencyBaseRate>'
				SET @XML+=@E+@T+@T+'<cbc:CalculationRate>'+CAST(@CalculationRate AS VARCHAR)+'</cbc:CalculationRate>'
				SET @XML+=@E+@T+@T+'<cbc:Date>'+REPLACE(CONVERT(VARCHAR,@F_NOTA,102),'.','-')+'</cbc:Date>' -- FECHA DE CAMBIO
				SET @XML+=@E+@T+'</cac:PaymentExchangeRate>'
			END	
		END
		SET @XML+=@E+@T+'<cac:RequestedMonetaryTotal>'
		SET @XML+=@E+@T+@T+'<cbc:LineExtensionAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VR_NOTA AS varchar)+'</cbc:LineExtensionAmount>'
		SET @XML+=@E+@T+@T+'<cbc:TaxExclusiveAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">0.00</cbc:TaxExclusiveAmount>'
		SET @XML+=@E+@T+@T+'<cbc:TaxInclusiveAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VR_NOTA AS varchar)+'</cbc:TaxInclusiveAmount>'
		SET @XML+=@E+@T+@T+'<cbc:PayableAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VR_NOTA AS varchar)+'</cbc:PayableAmount>'
		SELECT @XML+=@E+@T+'</cac:RequestedMonetaryTotal>'
		BEGIN -- Detalles de la Nota
			SELECT ROW_ID=ROW_NUMBER() OVER(ORDER BY ITEM ASC), DBO.FNK_LIMPIATEXTO(COALESCE(DESCRIPCION,''),'0-9 A-Z(),;.:')DESCRIPCION, CANTIDAD, VR_UNITARIO, VR_TOTAL,VALORIVA,PIVA, IDSERVICIO INTO #FNOTD_ND
			FROM FNOTD WHERE CNSFNOT=@CNSDOC AND COALESCE(VR_TOTAL,0)>0
			SELECT @CANT_LINEAS=@@ROWCOUNT, @ROW_ID=0
			WHILE @ROW_ID < @CANT_LINEAS
			BEGIN
				SET @ROW_ID+=1
				SELECT @N_CUOTA=ROW_ID
				, @ANEXO=DESCRIPCION, @CANTIDAD=CANTIDAD, @VALOR=VR_UNITARIO, @VLR_SERVICI=VR_TOTAL, @REFERENCIA=IDSERVICIO 
				FROM #FNOTD_ND WHERE ROW_ID=@ROW_ID
				SET @XML+=@E+@T+'<cac:DebitNoteLine>'
				SET @XML+=@E+@T+@T+'<cbc:ID>'+CAST(@N_CUOTA AS varchar)+'</cbc:ID>'
				SET @XML+=@E+@T+@T+'<cbc:Note>'+@ANEXO+'</cbc:Note>'
				SET @XML+=@E+@T+@T+'<cbc:DebitedQuantity unitCode="EA">'+CAST(@CANTIDAD AS varchar)+'</cbc:DebitedQuantity>'
				SET @XML+=@E+@T+@T+'<cbc:LineExtensionAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VLR_SERVICI AS varchar)+'</cbc:LineExtensionAmount>'
				SET @XML+=@E+@T+@T+'<cac:Item>'
				SET @XML+=@E+@T+@T+@T+'<cbc:Description>'+@ANEXO+'</cbc:Description>'
				SET @XML+=@E+@T+@T+@T+'<cbc:PackSizeNumeric>1</cbc:PackSizeNumeric>'
				SET @XML+=@E+@T+@T+@T+'<cbc:BrandName></cbc:BrandName>'
				SET @XML+=@E+@T+@T+@T+'<cbc:ModelName></cbc:ModelName>'
				SET @XML+=@E+@T+@T+@T+'<cac:SellersItemIdentification>'
				SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID>'+@REFERENCIA+'</cbc:ID>'
				SET @XML+=@E+@T+@T+@T+@T+'<cbc:ExtendedID></cbc:ExtendedID>'
				SET @XML+=@E+@T+@T+@T+'</cac:SellersItemIdentification>'
				SET @XML+=@E+@T+@T+@T+'<cac:StandardItemIdentification>'
				SET @XML+=@E+@T+@T+@T+@T+'<cbc:ID schemeID="999" schemeName="Estándar de adopción del contribuyente" schemeAgencyID="">'+@REFERENCIA+'</cbc:ID>'
				SET @XML+=@E+@T+@T+@T+'</cac:StandardItemIdentification>'
				SET @XML+=@E+@T+@T+'</cac:Item>'
				SET @XML+=@E+@T+@T+'<cac:Price>'
				SET @XML+=@E+@T+@T+@T+'<cbc:PriceAmount currencyID="'+COALESCE(@IDMONEDA,'COP')+'">'+CAST(@VALOR AS varchar)+'</cbc:PriceAmount>'
				SET @XML+=@E+@T+@T+@T+'<cbc:BaseQuantity unitCode="EA">'+CAST(@CANTIDAD AS varchar)+'</cbc:BaseQuantity>'
				SET @XML+=@E+@T+@T+'</cac:Price>'
				SET @XML+=@E+@T+'</cac:DebitNoteLine>'
			END
		END
		SELECT @XML+=@E+'</'+CASE WHEN @TIPODOC='CR' THEN 'CreditNote' ELSE 'DebitNote' END+'>'
	END

	SET @PREFIJO_USCXS='@FDIAN'+CAST(YEAR(GETDATE()) AS varchar)
	SELECT @CANTIARCHENV=CONSECUTIVO FROM USCXS WHERE COMPANIA='01' AND IDSEDE='01' AND PREFIJO=@PREFIJO_USCXS
	IF COALESCE(@CANTIARCHENV,0) < 1 SET @CANTIARCHENV=0
	SET @CANTIARCHENV+=1
	SET @NOMBRE_XML=LOWER(@TIPODOC)
	SET @NOMBRE_XML+=RIGHT('0000000000'+@NITFACTU,10)
	SET @NOMBRE_XML+=RIGHT('000',10) -- Software Propio
	SET @NOMBRE_XML+=CAST(RIGHT(YEAR(GETDATE()),2) AS VARCHAR)
	SET @NOMBRE_XML+=RIGHT('00000000'+CAST(@CANTIARCHENV AS VARCHAR),8)
	SET @NOMBRE_XML+='.xml'

	IF @PATH_URL IS NULL
		SELECT @XML as [XML]
	ELSE
		EXEC SPK_GUARDAR_ARCHIVO @XML, @PATH_URL, @NOMBRE_XML;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;  
		SELECT  @ErrorMessage=ERROR_MESSAGE(), @ErrorSeverity=ERROR_SEVERITY(), @ErrorState=ERROR_STATE();  
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);  
	END CATCH
END