CREATE OR ALTER PROC DBO.SPK_NOTIFICA_CITA_EMAIL
@ACCION           VARCHAR(20),
@CONSECUTIVO      VARCHAR(20),
@EMAIL			  VARCHAR(MAX) = NULL,
@LINKPAGO		  VARCHAR(MAX) = NULL
WITH ENCRYPTION
AS
DECLARE  @sUrl VARCHAR(MAX)				,@OK VARCHAR(20)
		,@JWT_QRYSTALOS VARCHAR(MAX)	,@EMAIL_TMPL VARCHAR(MAX)
		,@FECHA DATETIME				,@IDSEDE VARCHAR(20)
		,@ATENCION VARCHAR(50)			,@NOMBRE_MED VARCHAR(MAX)
		,@MODALIDADCIT VARCHAR(10)		,@IDMEDICO VARCHAR(20)
		,@FECHA_STRING VARCHAR(MAX)		,@NOMBRE_SED VARCHAR(MAX)
		,@NOMBRE_AFI VARCHAR(MAX)		,@NOMBRE_IPS VARCHAR(MAX)
		,@IDSERVICIO VARCHAR(20)		,@DESCSERVICIO VARCHAR(MAX)
		,@BODY_JSON VARCHAR(MAX)
		,@OBJ INT						,@RESPONSE NVARCHAR(MAX)	
		,@MONTO_ESCRITO VARCHAR(MAX)	,@LINK NVARCHAR(MAX)
      ,@FECHAEXP VARCHAR(MAX)
		
DECLARE @TABLA_TMP AS TABLE (ITEM INT IDENTITY(1,1), RESPONSE NVARCHAR(MAX))
BEGIN
	EXEC SPK_GENERA_TOKEN_WEB @TRANSIENT='JWT_QRY_ENVIOS',	@OK=@OK OUTPUT,  @JWT=@JWT_QRYSTALOS OUTPUT

	IF @OK <> 'OK'
	BEGIN
		PRINT @JWT_QRYSTALOS
		RETURN
	END
	
	IF COALESCE(DBO.FNK_VALORVARIABLE('BDATA_PRODUCCION'), '') = ''
	BEGIN
		PRINT 'Variable de sistema BDATA_PRODUCCION sin valor'
		RETURN
	END

	
	IF COALESCE(DBO.FNK_VALORVARIABLE('URL_API_QRYSTAL_PROD'), '') = ''
	BEGIN
		PRINT 'Variable de sistema URL_API_QRYSTAL_PROD sin valor'
		RETURN
	END

	IF COALESCE(DBO.FNK_VALORVARIABLE('URL_API_QRYSTAL_TEST'), '') = ''
	BEGIN
		PRINT 'Variable de sistema URL_API_QRYSTAL_TEST sin valor'
		RETURN
	END

	IF DB_NAME()=DBO.FNK_VALORVARIABLE('BDATA_PRODUCCION')
		SELECT @sUrl=LTRIM(RTRIM(DBO.FNK_VALORVARIABLE('URL_API_QRYSTAL_PROD')))+'/mailer/enqueue-email'
	ELSE
   BEGIN
		SELECT @sUrl=LTRIM(RTRIM(DBO.FNK_VALORVARIABLE('URL_API_QRYSTAL_TEST')))+'/mailer/enqueue-email'
   END
	IF COALESCE(@SURL, '')=''
	BEGIN
		PRINT '@URL API VACIA'
		RETURN
	END
	IF COALESCE(@JWT_QRYSTALOS, '') = ''
	BEGIN
		PRINT '@JWT_QRYSTALOS VACIA'
		RETURN
	END
	SELECT @FECHA = FECHA ,@IDSEDE=CIT.IDSEDE, @ATENCION= COALESCE(CIT.ATENCION,'')
		,@NOMBRE_MED=UPPER(REPLACE( COALESCE(LTRIM(RTRIM(MED.PNOMBRE)),''), CHAR(9),'') + ' ' + REPLACE( COALESCE(LTRIM(RTRIM(MED.PAPELLIDO)),''), CHAR(9),'') )
		,@MODALIDADCIT = COALESCE(CIT.MODALIDAD,'')
		,@IDMEDICO = CIT.IDMEDICO
		,@FECHA_STRING = CONCAT(
				''
				,FORMAT(CIT.FECHA, 'dddd', 'es-ES')
				,' '
				,DAY(CIT.FECHA)
				,' de '
				,FORMAT(CIT.FECHA, 'MMMM', 'es-ES') 
				,' de '
				,YEAR(CIT.FECHA) 
				,' a las '
				,FORMAT(CIT.FECHA, 'h:mmtt', 'es-ES')
				,' '
				,IIF(DATEPART(HOUR, CIT.FECHA) < 12,'am', 'pm')
			)
			,@NOMBRE_SED = SED.DESCRIPCION
			,@IDSERVICIO = CIT.IDSERVICIO
			,@DESCSERVICIO = dbo.FNK_LIMPIATEXTO(SER.DESCSERVICIO,'0-9 A-Z().;:,')
			,@NOMBRE_AFI = AFI.NOMBREAFI
			,@EMAIL = IIF(COALESCE(@EMAIL, '')='', dbo.FNK_EMAILVALIDO(DBO.FNK_PrimerEmailTercero(AFI.IDAFILIADO)), @EMAIL)
			,@NOMBRE_IPS = TER.RAZONSOCIAL
			,@MONTO_ESCRITO = [dbo].[FNK_GetCurrency](CIT.VALORCOPAGO)  -- ANDRE
			,@LINK = COALESCE(@LINKPAGO, KPAGE.LINKPAGO)
         ,@FECHAEXP =CASE WHEN KPAGE.F_EXPIRA IS NULL THEN 
         CONCAT(
				         ''
				         ,FORMAT(DATEADD(MINUTE,60,CIT.FECHA), 'dddd', 'es-ES')
				         ,' '
				         ,DAY(DATEADD(MINUTE,60,CIT.FECHA))
				         ,' de '
				         ,FORMAT(DATEADD(MINUTE,60,CIT.FECHA), 'MMMM', 'es-ES') 
				         ,' de '
				         ,YEAR(DATEADD(MINUTE,60,CIT.FECHA)) 
				         ,' a las '
				         ,FORMAT(DATEADD(MINUTE,60,CIT.FECHA), 'h:mmtt', 'es-ES')
				         ,' '
				         ,IIF(DATEPART(HOUR, DATEADD(MINUTE,60,CIT.FECHA)) < 12,'am', 'pm')
			         )
         ELSE
         CONCAT(
				''
				,FORMAT(KPAGE.F_EXPIRA, 'dddd', 'es-ES')
				,' '
				,DAY(KPAGE.F_EXPIRA)
				,' de '
				,FORMAT(KPAGE.F_EXPIRA, 'MMMM', 'es-ES') 
				,' de '
				,YEAR(KPAGE.F_EXPIRA) 
				,' a las '
				,FORMAT(KPAGE.F_EXPIRA, 'h:mmtt', 'es-ES')
				,' '
				,IIF(DATEPART(HOUR, KPAGE.F_EXPIRA) < 12,'am', 'pm')
			) END
	FROM   CIT LEFT JOIN MED ON MED.IDMEDICO=CIT.IDMEDICO
	LEFT JOIN SED ON SED.IDSEDE = CIT.IDSEDE
	LEFT JOIN SER ON SER.IDSERVICIO = CIT.IDSERVICIO
	LEFT JOIN AFI ON AFI.IDAFILIADO = CIT.IDAFILIADO
	LEFT JOIN TER ON TER.IDTERCERO = DBO.FNK_VALORVARIABLE('IDTERCEROINSTALADO')
	LEFT JOIN KPAGE ON KPAGE.IDKPAGE = CIT.IDKPAGE AND  KPAGE.CONSECUTIVO = CIT.CONSECUTIVO AND KPAGE.TABLA = 'CIT'
	WHERE CIT.CONSECUTIVO   = @CONSECUTIVO

	IF COALESCE(@EMAIL, '') = ''
	BEGIN
		PRINT 'EMAIL NO EXISTE O MAL INGRESADO EN LA FICHA DEL PACIENTE'
		RETURN
	END

	IF EXISTS(SELECT 1 FROM TGEN WHERE TABLA='GENERAL' AND CAMPO='EXCLUYE_NOTI_CIT_SMS' AND CODIGO=@IDSERVICIO)
	BEGIN
		PRINT 'SERVICIO EXCLUIDO PARA NOTIFICACIONES EN PROCESO DE CITAS'
		RETURN
	END

	IF @ACCION = 'ASIGNA'
		SELECT @EMAIL_TMPL = DBO.FNK_VALORVARIABLE('TMPL_EMAIL_ASIGNA')
	IF @ACCION = 'CANCELA'
		SELECT @EMAIL_TMPL = DBO.FNK_VALORVARIABLE('TMPL_EMAIL_CANCELA')
	IF @ACCION = 'REPROGRAMA'
		SELECT @EMAIL_TMPL = DBO.FNK_VALORVARIABLE('TMPL_EMAIL_REPROGRAM')
	IF @ACCION = 'ENVIA_LINK_PAGO'
		SELECT @EMAIL_TMPL = DBO.FNK_VALORVARIABLE('TMPL_EMAIL_LINKPAGO')
		

	IF COALESCE(@EMAIL_TMPL, '') = ''
	BEGIN
		PRINT 'VARIABLE @EMAIL_TMPL VACIA'
		RETURN
	END
	SELECT @NOMBRE_AFI = DBO.FNK_CAPITALIZAR_TEXTO(@NOMBRE_AFI)
	SELECT @NOMBRE_IPS = DBO.FNK_CAPITALIZAR_TEXTO(@NOMBRE_IPS)
	SELECT @NOMBRE_SED = DBO.FNK_CAPITALIZAR_TEXTO(@NOMBRE_SED)

	IF CHARINDEX('{{NOMBRE_AFI}}', @EMAIL_TMPL)> 0 AND COALESCE(@NOMBRE_AFI, '')<>''
		SELECT @EMAIL_TMPL = REPLACE(@EMAIL_TMPL, '{{NOMBRE_AFI}}', @NOMBRE_AFI)

	IF CHARINDEX('{{NOMBRE_IPS}}', @EMAIL_TMPL) > 0 AND COALESCE(@NOMBRE_IPS, '')<>''
		SELECT @EMAIL_TMPL = REPLACE(@EMAIL_TMPL, '{{NOMBRE_IPS}}', @NOMBRE_IPS)

	IF CHARINDEX('{{NOMBRE_SED}}', @EMAIL_TMPL) > 0 AND COALESCE(@NOMBRE_SED, '')<>''
		SELECT @EMAIL_TMPL = REPLACE(@EMAIL_TMPL, '{{NOMBRE_SED}}', @NOMBRE_SED)

	IF CHARINDEX('{{FECHA_CIT}}', @EMAIL_TMPL) > 0 AND COALESCE(@FECHA_STRING, '')<>''
		SELECT @EMAIL_TMPL = REPLACE(@EMAIL_TMPL, '{{FECHA_CIT}}', @FECHA_STRING)

	IF CHARINDEX('{{NOMBRE_MED}}', @EMAIL_TMPL) > 0 AND COALESCE(@NOMBRE_MED, '')<>''
		SELECT @EMAIL_TMPL = REPLACE(@EMAIL_TMPL, '{{NOMBRE_MED}}', @NOMBRE_MED)

	IF CHARINDEX('{{NOMBRE_SER}}', @EMAIL_TMPL) > 0 AND COALESCE(@DESCSERVICIO, '')<>''
		SELECT @EMAIL_TMPL = REPLACE(@EMAIL_TMPL, '{{NOMBRE_SER}}', @DESCSERVICIO)

	IF @ACCION = 'ENVIA_LINK_PAGO'
	BEGIN
		PRINT '****** LINK ******'
		PRINT @LINK
		
		IF COALESCE(@LINK, '') = ''
		BEGIN
			PRINT 'LINK DE PAGO VACIO O NO EXISTE'
			RETURN
		END

		IF CHARINDEX('{{LINK_PAGO}}', @EMAIL_TMPL) > 0 AND COALESCE(@LINK, '')<>''
			SELECT @EMAIL_TMPL = REPLACE(@EMAIL_TMPL, '{{LINK_PAGO}}', @LINK)
	
		IF CHARINDEX('{{MONTO}}', @EMAIL_TMPL) > 0 AND COALESCE(@MONTO_ESCRITO, '')<>''
			SELECT @EMAIL_TMPL = REPLACE(@EMAIL_TMPL, '{{MONTO}}', @MONTO_ESCRITO)

		IF CHARINDEX('{{F_EXPIRA}}', @EMAIL_TMPL) > 0 AND COALESCE(@MONTO_ESCRITO, '')<>''
			SELECT @EMAIL_TMPL = REPLACE(@EMAIL_TMPL, '{{F_EXPIRA}}', @FECHAEXP)
	END
	
	IF 1=1 -- SOLO PARA PRUEBAS
		SET @EMAIL = 'josemanuel_416@hotmail.com'

	--SELECT @EMAIL_TMPL = REPLACE(@EMAIL_TMPL,'"','\"')
	SELECT @BODY_JSON = '{"MAIL": "{{EMAIL}}", "HTML": "{{HTML}}", "SUBJECT": "{{SUBJECT}}", "CC": [], "ATTACHMENT": []}'
	SELECT @BODY_JSON = REPLACE(@BODY_JSON, '{{EMAIL}}', @EMAIL)
	SELECT @BODY_JSON = REPLACE(@BODY_JSON, '{{HTML}}', @EMAIL_TMPL)
	SELECT @BODY_JSON = REPLACE(@BODY_JSON, '{{SUBJECT}}', CONCAT('Notificaciones ',@NOMBRE_IPS))


	-- SET @BODY_JSON = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@BODY_JSON, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;')

	 PRINT @BODY_JSON
	
	IF COALESCE(@BODY_JSON, '') = ''
	BEGIN
		PRINT 'CUERPO DEL CORREO MALO'
		RETURN
	END

	-- Creaci�n de Objeto HTTP
	EXEC sys.sp_OACreate 'MSXML2.ServerXMLHttp', @obj OUT


	-- Configurar petici�n
	EXEC sys.sp_OAMethod @obj, 'Open', NULL, 'POST', @sUrl, false
	EXEC sys.sp_OAMethod @obj, 'setRequestHeader', NULL, 'Content-Type', 'application/json'
	EXEC sys.sp_OAMethod @obj, 'setRequestHeader', NULL, 'Accept', 'application/json'

	-- Inyectar las credenciales 
	EXEC sys.sp_OAMethod @obj, 'setRequestHeader', NULL, 'Authorization', @JWT_QRYSTALOS

	-- Enviar la petici�n
	EXEC SYS.sp_OAMethod @obj, 'send', null, @BODY_JSON

	-- Obtener la respuestas
	EXEC sys.sp_OAMethod @obj, 'responseText', @response OUTPUT

	-- Si la respuesta es nula, reintentar obtenerla
	IF @response IS NULL
	BEGIN
		INSERT INTO @TABLA_TMP(RESPONSE)
		EXEC sys.sp_OAGetProperty @obj, 'responseText'
		SELECT @response=RESPONSE FROM @TABLA_TMP
	END

	--IF @RESPONSE = '{"success":false,"logout":true,"message":"Token de autenticacion no proporcionado. Debes iniciar sesion."}'
	--BEGIN
	--	DELETE FROM TGEN WHERE TABLA='TRANSIENT' AND CAMPO='TRANSIENT' AND CODIGO='JWT_QRY_ENVIOS'
	--	EXEC DBO.SPK_NOTIFICA_CITA_EMAIL @ACCION, @CONSECUTIVO
	--END

	PRINT '*********** RESPONSE ***********'
	PRINT @response
	PRINT '***********          ***********'
	
	 --Limpiar el objeto HTTP
	EXEC sys.sp_OADestroy @obj
END

