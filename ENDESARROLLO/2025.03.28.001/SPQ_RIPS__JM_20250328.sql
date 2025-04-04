CREATE OR ALTER PROCEDURE DBO.SPQ_RIPS
@JSON  NVARCHAR(MAX)
WITH   ENCRYPTION
AS
DECLARE  @PARAMETROS	NVARCHAR(MAX)
		, @METODO		VARCHAR(100)
		, @USUARIO		VARCHAR(20)
		, @TIPODOC		VARCHAR(10)
		, @CNSDOC		VARCHAR(20)
		, @JsonSolicitud NVARCHAR(MAX)
		, @JsonRespuesta NVARCHAR(MAX)
		, @SUCCESS		BIT = 0
		, @CUV			VARCHAR(256)
		, @FRADICACION  DATETIME
DECLARE @TBLERRORES TABLE(ERROR VARCHAR(200));
BEGIN
	SELECT @USUARIO = USUARIO
		,@PARAMETROS = PARAMETROS
		,@METODO = METODO
	FROM OPENJSON (@json)
	WITH (
		MODELO         VARCHAR(100)     '$.MODELO',
		METODO         VARCHAR(100)     '$.METODO',
		USUARIO         VARCHAR(100)     '$.USUARIO',
		PARAMETROS     NVARCHAR(MAX)  AS JSON
	)

	SELECT @TIPODOC = JSON_VALUE(@PARAMETROS, '$.TIPODOC')
		,@CNSDOC = JSON_VALUE(@PARAMETROS, '$.CNSDOC')

	IF @METODO = 'GET_DATOS'
	BEGIN
			
		SELECT OK = 'OK'

		IF @TIPODOC = 'FV'
		BEGIN
			SELECT CUV, FRADICA_RIPS, JSON_RESPUESTA, JSON_ENVIO
         FROM FTRJSON WHERE CNSFCT = @CNSDOC
		END
      SELECT URLBASE=CASE WHEN DBO.FNK_VALORVARIABLE('BDATA_PRODUCCION')<>DB_NAME() 
                     THEN  DBO.FNK_VALORVARIABLE('URL_SERV_RIPS_PRUEBA')
                     ELSE 'OK' END
	END

	IF @METODO = 'SET_DATOS'
	BEGIN
		IF @TIPODOC = 'FV'
		BEGIN
			BEGIN TRY

				SELECT @JsonRespuesta = JSON_RESPUESTA, @JsonSolicitud = JSON_ENVIO
				FROM OPENJSON (@PARAMETROS)
				WITH (
					JSON_RESPUESTA     NVARCHAR(MAX)  AS JSON,	JSON_ENVIO     NVARCHAR(MAX)  AS JSON
				)

			
				SELECT @SUCCESS = JSON_VALUE(@JsonRespuesta,'$.ResultState')

				IF @SUCCESS = 0
				BEGIN
					IF NOT EXISTS (SELECT 1 FROM FTRJSON WHERE CNSFCT = @CNSDOC)
					BEGIN
						INSERT INTO FTRJSON (CNSFCT, JSON_RESPUESTA, FRADICA_RIPS)
						SELECT @CNSDOC, @JSONRESPUESTA, GETDATE()
					END
					ELSE
					BEGIN
						UPDATE FTRJSON 
						SET FRADICA_RIPS = GETDATE()
							,JSON_RESPUESTA = @JSONRESPUESTA
						WHERE CNSFCT = @CNSDOC
					END
				END
				ELSE
				BEGIN
					SELECT @CUV = JSON_VALUE(@JsonRespuesta,'$.CodigoUnicoValidacion')
						--,@FRADICACION = JSON_VALUE(@JsonRespuesta,'$.FechaRadicacion')

					UPDATE FTR 
					SET FRADICA_RIPS = GETDATE()
						,CUV = @CUV
					WHERE CNSFCT = @CNSDOC 

					IF NOT EXISTS (SELECT 1 FROM FTRJSON WHERE CNSFCT = @CNSDOC)
					BEGIN
						INSERT INTO FTRJSON (CNSFCT, JSON_ENVIO,JSON_RESPUESTA, CUV, FRADICA_RIPS)
						SELECT @CNSDOC, @JsonSolicitud , @JSONRESPUESTA, @CUV, GETDATE()
					END
					ELSE
					BEGIN
						UPDATE FTRJSON 
						SET FRADICA_RIPS = GETDATE()
							,JSON_ENVIO = @JsonSolicitud
							,JSON_RESPUESTA = @JSONRESPUESTA
							,CUV = @CUV
						WHERE CNSFCT = @CNSDOC 
					END
				END
			END TRY
			BEGIN CATCH
				INSERT INTO @TBLERRORES(ERROR) SELECT ERROR_MESSAGE()
			END CATCH

			IF(SELECT COUNT(*) FROM @TBLERRORES)>0
			BEGIN
				SELECT 'KO' OK
				SELECT ERROR FROM @TBLERRORES
				RETURN
			END

			SELECT 'OK' OK
			RETURN

		END
	END

	IF @METODO = 'GET_DATOS_XML'
	BEGIN
			
		SELECT OK = 'OK'

		IF @TIPODOC = 'FV'
		BEGIN
			SELECT XML_Base64
			FROM FDIANR
			WHERE CNSDOCUMENTO = @CNSDOC
			AND TIPO='FV'
			AND METODO='SendBillSync'
			AND COALESCE(XML_BASE64, '') <> ''
			ORDER BY ITEM DESC
		END
	END
END




