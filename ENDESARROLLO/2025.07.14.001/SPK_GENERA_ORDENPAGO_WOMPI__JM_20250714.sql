CREATE OR ALTER PROCEDURE DBO.SPK_GENERA_ORDENPAGO_WOMPI 
	 @CONSECUTIVO VARCHAR(20)
	,@TABLA VARCHAR(20)
	,@PROCEDENCIA VARCHAR(20)
	,@IDAFILIADO VARCHAR(20)
	,@VALOR DECIMAL(14, 2)
	,@N_FACTURA VARCHAR(20)
	,@USUARIO VARCHAR(20)
	,@IDKPAGE INT = 0
	,@PROCESO VARCHAR(20)
	WITH ENCRYPTION
AS
DECLARE @sUrl VARCHAR(3096)
DECLARE @TABLA_TMP AS TABLE (ITEM INT IDENTITY(1, 1),RESPONSE VARCHAR(MAX))
DECLARE @WOMPI_PRIVATE_KEY VARCHAR(MAX)
DECLARE @BODY NVARCHAR(MAX)
DECLARE @DESCSERVICIO VARCHAR(255)
DECLARE @BEARER VARCHAR(MAX)
DECLARE @response VARCHAR(MAX)
DECLARE @obj INT
DECLARE @ERROR_MESSAGE VARCHAR(MAX)
DECLARE @DATA AS NVARCHAR(MAX)
DECLARE @paymentOrderId VARCHAR(MAX)
DECLARE @URLPAGO VARCHAR(MAX)
BEGIN
	PRINT '************************** SPK_GENERA_ORDENPAGO_WOMPI **************************'
   IF DB_NAME()=DBO.FNK_VALORVARIABLE('BDATA_PRODUCCION')
   BEGIN
	   SELECT @WOMPI_PRIVATE_KEY = DATO1
	   FROM TGEN
	   WHERE TABLA = 'FPAG'
		   AND CAMPO = 'WOMPI'
		   AND CODIGO = 'WOMPI_PRIVATE_KEY'
   END
   ELSE
   BEGIN
	   SELECT @WOMPI_PRIVATE_KEY = DATO2
	   FROM TGEN
	   WHERE TABLA = 'FPAG'
		   AND CAMPO = 'WOMPI'
		   AND CODIGO = 'WOMPI_PRIVATE_KEY'
   END

	IF TRIM(COALESCE(@WOMPI_PRIVATE_KEY, '')) = ''
	BEGIN
		RAISERROR('Parametros requeridos de pasarela WOMPI sin configurar. TGEN => Tabla: FPAG, Campo: Wompi', 16, 1)
		RETURN
	END

	-- Si contiene la palabra test entonces es https://sandbox.wompi.co/v1/payment_links sino https://production.wompi.co/v1/payment_links
	SELECT @sUrl = IIF(@WOMPI_PRIVATE_KEY LIKE '%test%', 'https://sandbox.wompi.co/v1/payment_links', 'https://production.wompi.co/v1/payment_links')

	IF COALESCE(@IDKPAGE, 0) <= 0
	BEGIN
		INSERT INTO KPAGE (CONSECUTIVO	,TABLA	,PROCEDENCIA
			,FECHAGEN		,MODO		,VALOR	,ESTADO
			,USUCOBRA		,REF_PAGO
			,RESPONSABLEPAGO)
		SELECT @CONSECUTIVO	,@TABLA		,@PROCEDENCIA
			,CONVERT(SMALLDATETIME, GETDATE())
			,IIF(@WOMPI_PRIVATE_KEY LIKE '%test%', 'TEST', 'PRODUCTION')			
			,@VALOR			,'CREATED'	,@USUARIO		
			,@N_FACTURA		,@IDAFILIADO

		SET @IDKPAGE = @@IDENTITY
	END

	IF @TABLA = 'CIT'
	BEGIN
		UPDATE CIT
		SET IDKPAGE = @IDKPAGE
		WHERE CONSECUTIVO = @CONSECUTIVO

		SELECT @DESCSERVICIO = SER.DESCSERVICIO
		FROM CIT INNER JOIN SER ON SER.IDSERVICIO = CIT.IDSERVICIO
		WHERE CIT.CONSECUTIVO = @CONSECUTIVO

		IF @PROCESO = 'VALIDA'
		BEGIN
			RAISERROR('NO IMPLEMENTADO',16,4)
			RETURN
		END

		IF @PROCESO = 'CREAR'
		BEGIN
			SELECT @BODY = (
				SELECT name = 'Pago de Atención Médica'
					,description = @DESCSERVICIO
					,single_use = cast(1 as bit)
					,collect_shipping = cast(0 as bit)
					,currency = 'COP'
					,amount_in_cents = CAST(@VALOR * 100 AS DECIMAL(14,0))
					,sku = CAST(@IDKPAGE AS VARCHAR)
				FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
			)
			SELECT @BEARER = 'Bearer ' + @WOMPI_PRIVATE_KEY

			EXEC sys.sp_OACreate 'MSXML2.ServerXMLHttp', @obj OUT
			EXEC sys.sp_OAMethod @obj, 'Open', NULL, 'POST', @sUrl, false
			EXEC sys.sp_OAMethod @Obj, 'setRequestHeader', NULL, 'Authorization', @BEARER
			EXEC sys.sp_OAMethod @Obj, 'setRequestHeader', NULL, 'Content-Type', 'application/json'
			EXEC sys.sp_OAMethod @Obj, 'setRequestHeader', NULL, 'Accept', 'application/json'
			EXEC SYS.sp_OAMethod @obj, 'send', NULL, @Body
			EXEC sys.sp_OAMethod @obj, 'responseText', @response OUTPUT

			IF @response IS NULL
			BEGIN
				INSERT INTO @TABLA_TMP (RESPONSE)
				EXEC sys.sp_OAGetProperty @obj
					,'responseText'

				SELECT @response = RESPONSE
				FROM @TABLA_TMP
			END

			PRINT @response
			IF EXISTS(
			SELECT 
				[key] AS campo_afectado, 
				[value] AS mensaje_error
			FROM OPENJSON(@response, '$.error.messages') AS errors)
			BEGIN
				SELECT TOP 1 @ERROR_MESSAGE = CONCAT([key], ' ==> ', [value])
				FROM OPENJSON(@response, '$.error.messages') AS errors

				RAISERROR(@ERROR_MESSAGE, 16, 1)
				RETURN
			END
			EXEC sys.sp_OADestroy @obj
			SELECT @DATA = JSON_QUERY(@RESPONSE, '$.data')

			SELECT @urlpago = CONCAT('https://checkout.wompi.co/l/',JSON_VALUE(@DATA, '$.id'))
				,@paymentOrderId = JSON_VALUE(@DATA, '$.id')

			UPDATE KPAGE
			SET ESTADO = 'SEND'
				,RESPUESTA = @response
				,paymentOrderId = @paymentOrderId
				,LINKPAGO = @urlpago
				,ULTIMA_RESP = @response
			WHERE IDKPAGE = @IDKPAGE
		END

		RETURN
	END
END


