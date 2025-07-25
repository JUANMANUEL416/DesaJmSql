CREATE OR ALTER PROCEDURE DBO.SPQ_FCOM @JSON  NVARCHAR(MAX)
WITH      ENCRYPTION
AS
DECLARE  @ERRORES AS TABLE(ERROR VARCHAR(MAX))
DECLARE  @PARAMETROS NVARCHAR(MAX), 
		 @METODO VARCHAR(100), 
		 @MODELOACT NVARCHAR(MAX)	,@PROCESO VARCHAR(20)		,@CONSECUTIVO VARCHAR(20)
		 ,@USUARIO VARCHAR(12),@GRUPO VARCHAR(20), @USUNOMBRE VARCHAR(250)	
		 ,@IDSEDE VARCHAR(20),	@SEDE VARCHAR(20)	,@CNSRPDX VARCHAR(20)
		 ,@COMPANIA VARCHAR(20),	@IDARTICULO VARCHAR(20)	,@CANTIDAD INT
		 ,@CNSFCOM VARCHAR(20) ,@CNSFCOM_NUEVO VARCHAR(20),	@datoSOL NVARCHAR(MAX)
		 ,@SYS_COMPUTERNAME VARCHAR(50)	,@IDBODEGA VARCHAR(20)	, @IDBODEGA_DESTINO VARCHAR(20)
		 ,@ORDENCOMPRA SMALLINT	, @CNSFCOMN VARCHAR(20)	, @NVOCONSEC VARCHAR(20)	,@PREFIJO VARCHAR(20)
BEGIN
	SELECT *
	INTO #JSON
	FROM OPENJSON (@json)
	WITH (
		METODO         VARCHAR(100)     '$.METODO',
		USUARIO        VARCHAR(12)      '$.USUARIO',
		PARAMETROS     NVARCHAR(MAX)  AS JSON
	)
	SELECT @METODO = METODO , @PARAMETROS = PARAMETROS, @USUARIO = USUARIO
	FROM #JSON
	SELECT @GRUPO = DBO.FNK_DESCIFRAR(GRUPO), @USUNOMBRE = NOMBRE FROM USUSU WHERE USUARIO = @USUARIO
	SELECT @SYS_COMPUTERNAME = SYS_COMPUTERNAME, @COMPANIA = COMPANIA FROM USUSU WHERE USUARIO = @USUARIO
	SELECT @IDSEDE = IDSEDE, @SEDE = IDSEDE FROM UBEQ WHERE SYS_ComputerName = @SYS_COMPUTERNAME
	PRINT '@USUARIO='+@USUARIO
	/*
	Entendiendo los estados de FCOM
		A=Anulada
		C=Por Confirmar
		P=Procesada
		E=Por Confirmar al Almac�n
		I=Confirmada en Almac�n
	*/
	IF @METODO = 'PROVEEDORES'
	BEGIN
		SELECT 'OK' AS OK
		SELECT TER.IDTERCERO, RAZONSOCIAL, NIT
		FROM TER
		INNER JOIN TEXCA ON TER.IDTERCERO=TEXCA.IDTERCERO
		WHERE TEXCA.IDCATEGORIA = 'PRO'
		RETURN
	END
	IF @METODO = 'CENTROSCOSTOS'
	BEGIN
		SELECT 'OK' AS OK
		SELECT TER.IDTERCERO, RAZONSOCIAL
		FROM TER
		INNER JOIN TEXCA ON TER.IDTERCERO=TEXCA.IDTERCERO
		WHERE TEXCA.IDCATEGORIA = 'PRO'
		RETURN
	END
	IF @METODO = 'USERAUTO'
	BEGIN
		SELECT 'OK' AS OK
		select USUARIO,NOMBRE from USUSU
		RETURN
	END
	IF @METODO = 'CENTROcOSTOS'
	BEGIN
		SELECT 'OK' AS OK
		select CCOSTO,DESCRIPCION from CEN
		RETURN
	END
	IF @METODO = 'GUARDAR'
	BEGIN
		BEGIN TRY
			SELECT @SYS_COMPUTERNAME = SYS_COMPUTERNAME FROM USUSU WHERE USUARIO = @USUARIO
			SELECT @IDSEDE = IDSEDE, @COMPANIA=COMPANIA FROM UBEQ WHERE SYS_ComputerName = @SYS_COMPUTERNAME

            DECLARE @NUEVO_REGISTRO AS BIT = 1

            SELECT @CNSFCOM = JSON_VALUE(@PARAMETROS, '$.CNSFCOM')
            IF @CNSFCOM IS NOT NULL
            BEGIN
                SELECT @NUEVO_REGISTRO = 0
            END

            IF @NUEVO_REGISTRO = 1
            BEGIN
                --EXEC SPK_GENCONSECUTIVO @COMPANIA,@IDSEDE,'@FCOM', @CNSFCOM OUTPUT 
                --SELECT @CNSFCOM = @IDSEDE + RIGHT('00000000' + CONVERT(VARCHAR(8), @CNSFCOM), 8)
				EXEC SPQ_GENSEQUENCE @SEDE=@IDSEDE,@PREFIJO='@FCOM', @LONGITUD=8 ,@NVOCONSEC=@CNSFCOM OUTPUT

            END

			IF @NUEVO_REGISTRO = 1
            BEGIN
                INSERT INTO FCOM(CNSFCOM, COMPANIA, IDTERCERO, N_FACTURA, F_FACTURA, F_VENCE, VENDEDOR, ESTADO, F_CANCELADO, OBSERVACION, VR_ANTESIVA, IVA, VR_TOTAL, CNSFCOT, AJUSTADO, AJUSTEALPESO, ENINVENTARIO, ENCXP, VR_DESCUENTO, USUARIO, FECHA, ORDENCOMPRA, USUARIOORDEN, FECHAORDEN, IDBODEGA, CCOSTO, IDAREA, IDTIPOSER, CODUNG, CODPRG, DCONSUMO, DECONSUMO, TIPOANTICIPO, ESACTIVO, MANTICIPO, CNSPPTO, CNSCDP, CNSRP, AUTOCOMPRA, USUAUTOCOMPRA, VLR_FLETE, USUAUDITA)
                SELECT @CNSFCOM AS CNSFCOM		,@COMPANIA AS COMPANIA
                        ,IDTERCERO				,N_FACTURA
                        ,F_FACTURA				,F_VENCE
                        ,VENDEDOR				,ESTADO = 'C'
                        ,F_CANCELADO = NULL		,OBSERVACION
                        ,VR_ANTESIVA = 0		,IVA = 0
                        ,VR_TOTAL = 0			,CNSFCOT
                        ,AJUSTADO = 0			,AJUSTEALPESO = 0
                        ,ENINVENTARIO = 0		,ENCXP = 0
                        ,VR_DESCUENTO			,USUARIO = @USUARIO
                        ,FECHA
                        ,ORDENCOMPRA = 0		,USUARIOORDEN
                        ,FECHAORDEN				,IDBODEGA
                        ,CCOSTO					,IDAREA
                        ,IDTIPOSER				,CODUNG
                        ,CODPRG					,DCONSUMO = 0
                        ,1						,TIPOANTICIPO
                        ,ESACTIVO = 0			,MANTICIPO
                        ,CNSPPTO = CNSPPTO		,CNSCDP
                        ,CNSRP					,AUTOCOMPRA = 0
                        ,USUAUTOCOMPRA = NULL	,VLR_FLETE = VLR_FLETE
                        ,USUAUDITA = NULL
                FROM OPENJSON(@PARAMETROS) WITH(
                    IDTERCERO VARCHAR(20) '$.IDTERCERO'
                    ,CNSFCOT VARCHAR(20) '$.CNSFCOT'
                    ,N_FACTURA VARCHAR(20) '$.N_FACTURA'
                    ,F_FACTURA DATETIME '$.F_FACTURA'
                    ,F_VENCE DATETIME '$.F_VENCE'
                    ,VENDEDOR VARCHAR(100) '$.VENDEDOR'
                    ,OBSERVACION VARCHAR(100) '$.OBSERVACION'
                    ,FECHAORDEN DATETIME '$.FECHAORDEN'
                    ,FECHA DATETIME '$.FECHA'
                    ,USUARIOORDEN VARCHAR(20) '$.USUARIOORDEN'
                    ,IDBODEGA VARCHAR(20) '$.IDBODEGA'
                    ,CCOSTO VARCHAR(20) '$.CCOSTO'
                    ,TIPOANTICIPO VARCHAR(20) '$.TIPOANTICIPO'
                    ,MANTICIPO SMALLINT '$.MANTICIPO'
                    ,DECONSUMO SMALLINT '$.DECONSUMO'
                    ,IDTIPOSER VARCHAR(20) '$.IDTIPOSER'
                    ,VR_DESCUENTO DECIMAL(14,2) '$.VR_DESCUENTO'
                    ,VLR_FLETE DECIMAL(14,2) '$.VLR_FLETE'
                    ,IDAREA VARCHAR(20) '$.IDAREA'
                    ,CODUNG VARCHAR(20) '$.CODUNG'
                    ,CODPRG VARCHAR(20) '$.CODPRG'
                    ,CNSRP VARCHAR(20) '$.CNSRP'
                    ,CNSPPTO VARCHAR(20) '$.CNSPPTO'
                    ,CNSCDP VARCHAR(20) '$.CNSCDP'
                    
                ) AS #T
            END
            ELSE
            BEGIN
                UPDATE FCOM
                SET IDTERCERO = #T.IDTERCERO
                    ,N_FACTURA = #T.N_FACTURA
                    ,F_FACTURA = #T.F_FACTURA
                    ,F_VENCE = #T.F_VENCE
                    ,VENDEDOR = #T.VENDEDOR
                    ,OBSERVACION = #T.OBSERVACION
                    ,FECHAORDEN = #T.FECHAORDEN
                    ,FECHA = #T.FECHA
                    ,USUARIOORDEN = #T.USUARIOORDEN
                    -- ,IDBODEGA = #T.IDBODEGA
                    ,CCOSTO = #T.CCOSTO
                    ,TIPOANTICIPO = #T.TIPOANTICIPO
                    ,MANTICIPO = #T.MANTICIPO
                    ,DECONSUMO = #T.DECONSUMO
                    ,IDTIPOSER = #T.IDTIPOSER
                    -- ,VR_DESCUENTO = #T.VR_DESCUENTO
                    ,VLR_FLETE = #T.VLR_FLETE
                    ,IDAREA = #T.IDAREA
                    ,CODUNG = #T.CODUNG
                    ,CODPRG = #T.CODPRG
                    ,CNSRP = #T.CNSRP
                    ,CNSPPTO = #T.CNSPPTO
                    ,CNSCDP = #T.CNSCDP
                 FROM FCOM INNER JOIN
					
				 OPENJSON(@PARAMETROS) WITH(
                    IDTERCERO VARCHAR(20) '$.IDTERCERO'
                    ,CNSFCOT VARCHAR(20) '$.CNSFCOT'
                    ,N_FACTURA VARCHAR(20) '$.N_FACTURA'
                    ,F_FACTURA DATETIME '$.F_FACTURA'
                    ,F_VENCE DATETIME '$.F_VENCE'
                    ,VENDEDOR VARCHAR(100) '$.VENDEDOR'
                    ,OBSERVACION VARCHAR(100) '$.OBSERVACION'
                    ,FECHAORDEN DATETIME '$.FECHAORDEN'
                    ,FECHA DATETIME '$.FECHA'
                    ,USUARIOORDEN VARCHAR(20) '$.USUARIOORDEN'
                    ,IDBODEGA VARCHAR(20) '$.IDBODEGA'
                    ,CCOSTO VARCHAR(20) '$.CCOSTO'
                    ,TIPOANTICIPO VARCHAR(20) '$.TIPOANTICIPO'
                    ,MANTICIPO SMALLINT '$.MANTICIPO'
                    ,DECONSUMO SMALLINT '$.DECONSUMO'
                    ,IDTIPOSER VARCHAR(20) '$.IDTIPOSER'
                    ,VR_DESCUENTO DECIMAL(14,2) '$.VR_DESCUENTO'
                    ,VLR_FLETE DECIMAL(14,2) '$.VLR_FLETE'
                    ,IDAREA VARCHAR(20) '$.IDAREA'
                    ,CODUNG VARCHAR(20) '$.CODUNG'
                    ,CODPRG VARCHAR(20) '$.CODPRG'
                    ,CNSRP VARCHAR(20) '$.CNSRP'
                    ,CNSPPTO VARCHAR(20) '$.CNSPPTO'
                    ,CNSCDP VARCHAR(20) '$.CNSCDP'
                    ,CNSFCOM VARCHAR(20) '$.CNSFCOM'
                    
                ) AS #T ON FCOM.CNSFCOM = #T.CNSFCOM 
                WHERE FCOM.CNSFCOM = @CNSFCOM

            END
		END TRY
		BEGIN CATCH
			INSERT INTO @ERRORES(ERROR)
			SELECT ERROR_MESSAGE()
		END CATCH

		IF (SELECT COUNT(1) FROM @ERRORES)>0
		BEGIN
			SELECT 'KO' AS OK
			SELECT ERROR FROM @ERRORES
			RETURN
		END

		SELECT 'OK' AS OK, @CNSFCOM AS CNSFCOM
	END
	IF @METODO = 'CCOSTOS'
	BEGIN
		SELECT 'OK' AS OK
		SELECT CEN.CCOSTO,CEN.DESCRIPCION,AFU.IDAREA, AFU.DESCRIPCION DESCAREA FROM CEN
		INNER JOIN AFU ON AFU.IDAREA=CEN.IDAREA
		WHERE CEN.ESTADO='Activo'
		AND AFU.ESTADO=1
		ORDER BY CEN.DESCRIPCION
		RETURN
	END
	IF @METODO = 'ANULAR'
	BEGIN
		SELECT @CNSFCOM = JSON_VALUE(@PARAMETROS, '$.CNSFCOM')
		UPDATE FCOM SET ESTADO='A' WHERE CNSFCOM=@CNSFCOM
		IF EXISTS (SELECT 1 FROM  FCOM WHERE CNSFCOM = @CNSFCOM AND COALESCE(PROCEDENCIA,'') = 'ILPRE')
		BEGIN
			UPDATE ICTZD SET PROCESADO = 0, CNSFCOM = NULL WHERE CNSFCOM = @CNSFCOM
		END

		SELECT 'OK' AS OK, @CNSFCOM AS CNSFCOM
		RETURN
	END
	IF @METODO = 'IMPRIMIR'
	BEGIN
		SELECT @CNSFCOM = JSON_VALUE(@PARAMETROS, '$.CNSFCOM')

		SELECT 
			FCOM.IDBODEGA, IBOD.DESCRIPCION AS DESCBODEGA
			,TER.NIT, TER.RAZONSOCIAL, TER.DV, TER.DIRECCION, TELEFONOS = DBO.FNK_TelefonosTercero(FCOM.IDTERCERO)
			,FCOM.VENDEDOR
			,FCOM.FECHA
			,FCOM.CCOSTO, CEN.DESCRIPCION DESCCOSTO
			,FCOM.IDAREA, AFU.DESCRIPCION DESCAREA
			,FCOM.F_VENCE
			,FCOM.CNSFCOT
			,FCOM.OBSERVACION
			,FCOM.VLR_FLETE
			,FCOM.VR_DESCUENTO
			,FCOM.IVA
			,FCOM.VR_TOTAL
			,FECHA_IMPRESION = CURRENT_TIMESTAMP
			,ORDENCOMPRA = COALESCE(FCOM.ORDENCOMPRA, 0)
			,FCOM.IDTIPOSER
			,FCOM.N_FACTURA
			,FCOM.F_FACTURA
			,FCOM.ESTADO
         ,BASE=IIF(DBO.FNK_VALORVARIABLE('BDATA_PRODUCCION')=DB_NAME(),'OK','DEMO')
			,FCOMD = (
				SELECT FCOMD.IDARTICULO, DESCRIPCION = COALESCE(IART.DESCRIPCION, FCTSERD.DESCRIPCION)
					,EXISTOTAL = IIF(USVGS.DATO='SI',
						(
						SELECT ISNULL(SUM(EXISLOTE),0)AS TOTAL 
						FROM IEXI 
						WHERE IDBODEGA = FCOM.IDBODEGA 
						AND EXISLOTE > 0 
						AND EXISTS(
							SELECT * FROM VWK_HERMANOS_INVENTARIO AS A 
							WHERE IEXI.IDARTICULO=A.IDARTICULO
							AND HERMANO_MAYOR = FCOMD.IDARTICULO)
						)
					, 0)
					, FCOMD.CANTIDAD
					, IART.IDUNIDAD
					, IART.CODCUM
					, FCOMD.VLR_UNITARIO
					, FCOMD.VR_ANTESIVA
					, FCOMD.IVA
					, FCOMD.VR_TOTAL
					, FCOMD.DETALLE
					, FCOMD.VR_DESCUENTO
					, OPTICA = CAST(COALESCE(ITAR.OPTICA, 0) AS BIT)
					, ODESFERA, OIESFERA, ODCILINDRO, OICILINDRO, ODEJE, OIEJE, ODADICION, OIADICION, ODALT, OIALT, ODAVL, OIAVL, ODTLENTE, OITLENTE, ODDNP, OIDNP
				FROM FCOMD
				LEFT JOIN IART ON IART.IDARTICULO = FCOMD.IDARTICULO AND FCOMD.TIPO='Articulos'
				LEFT JOIN FCTSERD ON FCTSERD.IDSERVICIO=FCOMD.IDARTICULO AND FCOMD.TIPO!='Articulos'
				LEFT JOIN ITAR ON ITAR.IDITAR = IART.IDITAR
				WHERE FCOMD.CNSFCOM = FCOM.CNSFCOM
				FOR JSON PATH
			)

		FROM FCOM 
		INNER JOIN IBOD ON IBOD.IDBODEGA = FCOM.IDBODEGA
		INNER JOIN TER ON TER.IDTERCERO = FCOM.IDTERCERO
		LEFT JOIN USVGS ON USVGS.IDVARIABLE = 'EXIS_ENORDENCOM'
		LEFT JOIN CEN ON CEN.CCOSTO = FCOM.CCOSTO
		LEFT JOIN AFU ON AFU.IDAREA = CEN.IDAREA
		WHERE CNSFCOM = @CNSFCOM



		--SELECT DBO.FNK_TelefonosTercero(IDTERCERO)
		RETURN
	END

	IF @METODO = 'CONFIRMAR_ORDEN'
	BEGIN
		SELECT @CNSFCOM = JSON_VALUE(@PARAMETROS, '$.CNSFCOM')
		SELECT @COMPANIA = COMPANIA FROM FCOM WHERE CNSFCOM = @CNSFCOM
		SELECT @SYS_COMPUTERNAME = SYS_COMPUTERNAME FROM USUSU WHERE USUARIO = @USUARIO
		SELECT @IDSEDE = IDSEDE, @COMPANIA=COMPANIA FROM UBEQ WHERE SYS_ComputerName = @SYS_COMPUTERNAME

		IF NOT EXISTS (SELECT * FROM FCOMD WHERE CNSFCOM = @CNSFCOM)
		BEGIN
			INSERT INTO @ERRORES(ERROR) SELECT 'No cuenta con detalle.' 
		END
		IF (SELECT COUNT(*) FROM @ERRORES)> 0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @ERRORES
			RETURN
		END
		ELSE
		BEGIN
			BEGIN TRY
				UPDATE FCOM 
					SET USUARIOORDEN=@USUARIO,ORDENCOMPRA=CASE WHEN COALESCE(ORDENCOMPRA,0)=0 THEN 1 ELSE ORDENCOMPRA+1 END
					--,FECHAORDEN=DBO.FNK_GETDATE()
					,ESTADO=CASE WHEN ESTADO='C' THEN 'P' ELSE ESTADO END 
				WHERE CNSFCOM=@CNSFCOM

				EXEC SPK_INSERT_ITRA_REQ @CNSFCOM, @USUARIO,@SYS_COMPUTERNAME,@COMPANIA,@IDSEDE
			END TRY
			BEGIN CATCH 
				INSERT INTO @ERRORES(ERROR) SELECT ERROR_MESSAGE() ;  
			END CATCH  
			IF (SELECT COUNT(*) FROM @ERRORES)> 0
			BEGIN
				SELECT 'KO' OK
				SELECT ERROR FROM @ERRORES
				RETURN
			END
			SELECT 'OK' AS OK, @CNSFCOM AS CNSFCOM
		END 
	END
	IF @METODO = 'VALIDA_CANTIDADES'
	BEGIN
		SELECT @CNSFCOM = JSON_VALUE(@PARAMETROS, '$.CNSFCOM')
		
		IF NOT EXISTS (SELECT * FROM FCOMD WHERE CNSFCOM = @CNSFCOM)
		BEGIN
			INSERT INTO @ERRORES(ERROR) SELECT 'No cuenta con detalle.' 
		END
		IF (SELECT COUNT(*) FROM @ERRORES)> 0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @ERRORES
			RETURN
		END
		ELSE
		BEGIN
			BEGIN TRY
				SELECT 'OK' OK, COUNT(*) CANTIDAD

				FROM FCOMD WHERE CNSFCOM = @CNSFCOM
			END TRY
			BEGIN CATCH 
				INSERT INTO @ERRORES(ERROR) SELECT ERROR_MESSAGE() ;  
			END CATCH  
			IF (SELECT COUNT(*) FROM @ERRORES)> 0
			BEGIN
				SELECT 'KO' OK
				SELECT ERROR FROM @ERRORES
				RETURN
			END
			SELECT 'OK' AS OK
		END 

	END
	IF @METODO = 'MARCAR_IMPRESA'
	BEGIN
		SELECT @CNSFCOM = JSON_VALUE(@PARAMETROS, '$.CNSFCOM')
		UPDATE FCOM SET ORDENCOMPRA=ORDENCOMPRA+1  
		WHERE CNSFCOM=@CNSFCOM
		SELECT 'OK' AS OK, @CNSFCOM AS CNSFCOM
	END

	IF @METODO = 'ABRIR'
	BEGIN

		
		BEGIN TRY

			SELECT @CNSFCOM = JSON_VALUE(@PARAMETROS, '$.CNSFCOM')
			SELECT @ORDENCOMPRA = ORDENCOMPRA
			FROM FCOM 
			WHERE CNSFCOM = @CNSFCOM

			IF EXISTS(SELECT 1 FROM FCOM WHERE CNSFCOM = @CNSFCOM AND COALESCE(ORDENCOMPRA, 0)>=1 AND ESTADO='P')
			BEGIN
				IF EXISTS(SELECT 1 FROM ITRA WHERE ITRA.CNSFCOM = @CNSFCOM AND ESTADO<>0)
				BEGIN
					INSERT INTO @ERRORES(ERROR)
					SELECT 'No Puede Abrir la Orden de compra. Ya fue confirmada en bodega'
				END
			END
			ELSE
			BEGIN
				INSERT INTO @ERRORES(ERROR)
				SELECT 'La orden de compra no se encuentra en estado ''CONFIRMADA'' (FCOM.ORDENCOMPRA = '+CAST(@ORDENCOMPRA AS VARCHAR)+'). Contacte por favor al departamento de tecnolog�a si piensa que esto es una irregularidad.'
			END

			IF (SELECT COUNT(*) FROM @ERRORES) <= 0
			BEGIN
				UPDATE FCOM SET ESTADO = 'C', ORDENCOMPRA = 0 WHERE CNSFCOM = @CNSFCOM
				
				DELETE ITRAH 
				FROM   ITRAH INNER JOIN ITRA ON ITRAH.CNSITRA = ITRA.CNSITRA
				WHERE  ITRA.CNSFCOM = @CNSFCOM
				
                DELETE ITRA WHERE  ITRA.CNSFCOM = @CNSFCOM
			END
		END TRY  
		BEGIN CATCH 
			INSERT INTO @ERRORES(ERROR) SELECT ERROR_MESSAGE() ;  
		END CATCH

		IF (SELECT COUNT(*) FROM @ERRORES)> 0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @ERRORES
			RETURN
		END	
		SELECT OK='OK'
		RETURN
	END
	IF @METODO = 'CRUD_SOL'
	BEGIN
		SELECT @PROCESO = PROCESO
		FROM OPENJSON(@PARAMETROS)
		WITH( PROCESO		VARCHAR(20)		 '$.PROCESO')
		
		IF (SELECT COUNT(*) FROM @ERRORES)> 0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @ERRORES
			RETURN
		END
		ELSE
		BEGIN
			BEGIN TRY
				IF @PROCESO = 'NUEVO'
				BEGIN
					--EXEC SPK_GENCONSECUTIVO '01',@IDSEDE,'@RPDX',@CNSRPDX OUTPUT
					--SELECT @CNSRPDX = @IDSEDE + REPLACE(SPACE(8 - LEN(@CNSRPDX))+LTRIM(RTRIM(@CNSRPDX)),SPACE(1),0)
					EXEC SPQ_GENSEQUENCE @SEDE=@IDSEDE,@PREFIJO='@RPDX', @LONGITUD=8 ,@NVOCONSEC=@CNSRPDX OUTPUT
				END
			END TRY
			BEGIN CATCH 
				INSERT INTO @ERRORES(ERROR) SELECT ERROR_MESSAGE() ;  
			END CATCH  
			IF (SELECT COUNT(*) FROM @ERRORES)> 0
			BEGIN
				SELECT 'KO' OK
				SELECT ERROR FROM @ERRORES
				RETURN
			END
			SELECT 'OK'OK, @CNSRPDX CNSFCOM, @PROCESO PROCESO
		END 
	END	
	IF @METODO = 'CERRAR_SOL'
	BEGIN
		SELECT @CNSFCOM = CNSFCOM
		FROM OPENJSON(@PARAMETROS)
		WITH( CNSFCOM		VARCHAR(20)		 '$.CNSFCOM')
			DELETE FROM RPDX WHERE CNS = @CNSFCOM
			SELECT 'OK'OK
	END	
	IF @METODO = 'INSERTA_IART'
	BEGIN
		SELECT @PROCESO = PROCESO, @CNSFCOM = CNSFCOM, @IDARTICULO = IDARTICULO, @CANTIDAD = CANTIDAD
		FROM OPENJSON(@PARAMETROS)
		WITH( PROCESO	VARCHAR(20)	'$.PROCESO'		,CNSFCOM	VARCHAR(20)	'$.CNSFCOM'
			,IDARTICULO	VARCHAR(20)	'$.IDARTICULO'	,CANTIDAD	INT			'$.CANTIDAD')
		
		IF @PROCESO = 'NUEVO'
		BEGIN
			IF EXISTS (SELECT * FROM RPDX WHERE CNS = @CNSFCOM AND RPDX.ID1 = @IDARTICULO )
			BEGIN
				INSERT INTO @ERRORES(ERROR) SELECT 'El insumo ya se encuentra registrado.' 
			END
		END
		IF @PROCESO = 'EDITAR'
		BEGIN
			IF EXISTS (SELECT * FROM FCOMD WHERE CNSFCOM = @CNSFCOM AND FCOMD.IDARTICULO = @IDARTICULO )
			BEGIN
				INSERT INTO @ERRORES(ERROR) SELECT 'El insumo ya se encuentra registrado.' 
			END
		END
		IF (SELECT COUNT(*) FROM @ERRORES)> 0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @ERRORES
			RETURN
		END
		ELSE
		BEGIN
			BEGIN TRY
				IF @PROCESO = 'NUEVO'
				BEGIN
					INSERT INTO RPDX (CNS,  ID1 , CANTIDAD)
					SELECT @CNSFCOM , @IDARTICULO, @CANTIDAD
				END
				IF @PROCESO = 'EDITAR'
				BEGIN
					INSERT INTO FCOMD (CNSFCOM, IDARTICULO, ESTADO, VLR_UNITARIO, CANTIDAD, VR_ANTESIVA, IVA, VR_TOTAL, VR_UNITMASIVA, TIENEIVA, FACTORIVA, VR_DESCUENTO, TIPO, UTILIDAD, TDESCUENTO, TIPODTO, PDTO)
					SELECT @CNSFCOM, @IDARTICULO, 'P',  0, @CANTIDAD, 0, 0,0,0,0,0,0,'Articulos', 0,0,'V',0
				END
			END TRY
			BEGIN CATCH 
				INSERT INTO @ERRORES(ERROR) SELECT ERROR_MESSAGE() ;  
			END CATCH  
			IF (SELECT COUNT(*) FROM @ERRORES)> 0
			BEGIN
				SELECT 'KO' OK
				SELECT ERROR FROM @ERRORES
				RETURN
			END
			SELECT 'OK'OK, @CNSRPDX CNSFCOM, @PROCESO PROCESO
		END 
	END	
	IF @METODO = 'ELIMINA_IART'
	BEGIN
		SELECT @PROCESO = PROCESO, @CNSFCOM = CNSFCOM, @IDARTICULO = IDARTICULO
		FROM OPENJSON(@PARAMETROS)
		WITH( PROCESO	VARCHAR(20)	'$.PROCESO'		,CNSFCOM	VARCHAR(20)	'$.CNSFCOM'
			,IDARTICULO	VARCHAR(20)	'$.IDARTICULO'	)
	
		IF (SELECT COUNT(*) FROM @ERRORES)> 0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @ERRORES
			RETURN
		END
		ELSE
		BEGIN
			BEGIN TRY
				IF @PROCESO = 'NUEVO'
				BEGIN
					DELETE FROM RPDX WHERE CNS = @CNSFCOM AND ID1 = @IDARTICULO
				END
				IF @PROCESO = 'EDITAR'
				BEGIN
					DELETE FROM FCOMD WHERE CNSFCOM = @CNSFCOM AND IDARTICULO = @IDARTICULO
				END
			END TRY
			BEGIN CATCH 
				INSERT INTO @ERRORES(ERROR) SELECT ERROR_MESSAGE() ;  
			END CATCH  
			IF (SELECT COUNT(*) FROM @ERRORES)> 0
			BEGIN
				SELECT 'KO' OK
				SELECT ERROR FROM @ERRORES
				RETURN
			END
			SELECT 'OK'OK, @CNSRPDX CNSFCOM, @PROCESO PROCESO
		END 
	END	
	IF @METODO = 'CANTIDAD_IART'
	BEGIN
		SELECT @CNSFCOM = CNSFCOM, @IDARTICULO = IDARTICULO, @CANTIDAD = CANTIDAD
		FROM OPENJSON(@PARAMETROS)
		WITH( CANTIDAD	INT	'$.CANTIDAD'		,CNSFCOM	VARCHAR(20)	'$.CNSFCOM'
			,IDARTICULO	VARCHAR(20)	'$.IDARTICULO'	)
	
		IF (SELECT COUNT(*) FROM @ERRORES)> 0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @ERRORES
			RETURN
		END
		ELSE
		BEGIN
			BEGIN TRY
				UPDATE FCOMD SET CANTIDAD_REF_ENT = @CANTIDAD WHERE CNSFCOM = @CNSFCOM AND IDARTICULO = @IDARTICULO
			END TRY
			BEGIN CATCH 
				INSERT INTO @ERRORES(ERROR) SELECT ERROR_MESSAGE() ;  
			END CATCH  
			IF (SELECT COUNT(*) FROM @ERRORES)> 0
			BEGIN
				SELECT 'KO' OK
				SELECT ERROR FROM @ERRORES
				RETURN
			END
			SELECT 'OK'OK
		END 
	END	
	IF @METODO = 'GENERA_OC'
	BEGIN
		SELECT @CNSFCOM = CNSFCOM
		FROM OPENJSON(@PARAMETROS)
		WITH(CNSFCOM	VARCHAR(20)	'$.CNSFCOM'	)
	
		IF NOT EXISTS (SELECT * FROM FCOMD WHERE CNSFCOM = @CNSFCOM AND COALESCE(CANTIDAD_REF_ENT,0) > 0)
		BEGIN
			INSERT INTO @ERRORES(ERROR) SELECT 'No se ingreso las cantidades de los Articulos para generar la OC' 
		END
		IF (SELECT COUNT(*) FROM @ERRORES)> 0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @ERRORES
			RETURN
		END
		ELSE
		BEGIN
			BEGIN TRY
				--EXEC SPK_GENCONSECUTIVO @COMPANIA,@IDSEDE,'@FCOM', @CNSFCOM_NUEVO OUTPUT 
				--SELECT @CNSFCOM_NUEVO = @IDSEDE + RIGHT('00000000' + CONVERT(VARCHAR(8), @CNSFCOM_NUEVO), 8)
				EXEC SPQ_GENSEQUENCE @SEDE=@IDSEDE,@PREFIJO='@FCOM', @LONGITUD=8 ,@NVOCONSEC=@CNSFCOM_NUEVO OUTPUT
				
				INSERT INTO FCOM(CNSFCOM, COMPANIA, IDTERCERO, N_FACTURA, F_FACTURA, F_VENCE, VENDEDOR, ESTADO, F_CANCELADO, OBSERVACION, VR_ANTESIVA, IVA, VR_TOTAL, CNSFCOT
				, AJUSTADO, AJUSTEALPESO, ENINVENTARIO, ENCXP, VR_DESCUENTO, USUARIO, FECHA, ORDENCOMPRA, USUARIOORDEN, FECHAORDEN, IDBODEGA, CCOSTO, IDAREA, IDTIPOSER, CODUNG
				, CODPRG, DCONSUMO, DECONSUMO, TIPOANTICIPO, ESACTIVO, MANTICIPO, CNSPPTO, CNSCDP, CNSRP, AUTOCOMPRA, USUAUTOCOMPRA, VLR_FLETE, USUAUDITA)
                SELECT @CNSFCOM_NUEVO AS CNSFCOM		,@COMPANIA AS COMPANIA
                        ,IDTERCERO				,N_FACTURA
                        ,F_FACTURA				,F_VENCE
                        ,VENDEDOR				, 'C'
                        ,F_CANCELADO = NULL		,'OC generada de una Solicitud'
                        ,VR_ANTESIVA = 0		,IVA = 0
                        ,VR_TOTAL = 0			,CNSFCOT
                        ,AJUSTADO = 0			,AJUSTEALPESO = 0
                        ,ENINVENTARIO = 0		,ENCXP = 0
                        ,VR_DESCUENTO			, @USUARIO
                        ,FECHA = DBO.FNK_GETDATE()
                        ,ORDENCOMPRA = 0		,USUARIOORDEN
                        ,FECHAORDEN				,IDBODEGA
                        ,CCOSTO					,IDAREA
                        ,'Compra'				,CODUNG
                        ,CODPRG					,DCONSUMO = 0
                        ,DECONSUMO				,TIPOANTICIPO
                        ,ESACTIVO = 0			,MANTICIPO
                        , CNSPPTO				,CNSCDP
                        ,CNSRP					,AUTOCOMPRA = 0
                        ,USUAUTOCOMPRA = NULL	,VLR_FLETE
                        ,USUAUDITA = NULL
                FROM FCOM WHERE CNSFCOM = @CNSFCOM

				INSERT INTO FCOMD (CNSFCOM, IDARTICULO, ESTADO, VLR_UNITARIO, CANTIDAD, VR_ANTESIVA, IVA, VR_TOTAL, VR_UNITMASIVA, COMPANIA, TIENEIVA, FACTORIVA, NOLOTE, VR_DESCUENTO, TIPO, UTILIDAD, TIPODTO, PDTO, CNSMOV_REF_SOL, IDARTICULO_REF_SOL, CANTIDAD_REF_ENT)
				SELECT @CNSFCOM_NUEVO, IDARTICULO, ESTADO, VLR_UNITARIO, CANTIDAD_REF_ENT, VR_ANTESIVA, IVA, VR_TOTAL, VR_UNITMASIVA, COMPANIA, TIENEIVA, FACTORIVA, NOLOTE, VR_DESCUENTO, TIPO, UTILIDAD, TIPODTO, PDTO, CNSMOV_REF_SOL, IDARTICULO_REF_SOL, CANTIDAD_REF_ENT
				FROM FCOMD WHERE CNSFCOM = @CNSFCOM AND COALESCE(FCOMD.CANTIDAD_REF_ENT,0)  >0

				UPDATE FCOMD SET CNSMOV_REF_SOL = @CNSFCOM_NUEVO, IDARTICULO_REF_SOL = IDARTICULO, ESTADO = 'P'  FROM FCOMD WHERE CNSFCOM = @CNSFCOM AND COALESCE(FCOMD.CANTIDAD_REF_ENT,0)  >0
				UPDATE FCOM SET ESTADO = 'P' WHERE  CNSFCOM = @CNSFCOM

			END TRY
			BEGIN CATCH 
				INSERT INTO @ERRORES(ERROR) SELECT ERROR_MESSAGE() ;  
			END CATCH  
			IF (SELECT COUNT(*) FROM @ERRORES)> 0
			BEGIN
				SELECT 'KO' OK
				SELECT ERROR FROM @ERRORES
				RETURN
			END
			SELECT 'OK'OK
		END 
	END
	IF @METODO = 'GUARDA_FCOM_SOL'
	BEGIN
		SELECT @datoSOL = datoSOL, @IDBODEGA = IDBODEGA
		FROM OPENJSON(@PARAMETROS)
		WITH( datoSOL	NVARCHAR(MAX)	AS JSON		, IDBODEGA		VARCHAR(20) '$.IDBODEGA'	)
	
		SELECT @PROCESO =UPPER( JSON_VALUE(@datoSOL,'$.PROCESO'))

		SELECT * INTO #datoSOL FROM OPENJSON (@datoSOL)
		WITH(
			CNSFCOM		VARCHAR(20) '$.CNSFCOM'		,OBSERVACION	VARCHAR(250)	'$.OBSERVACION'
			,IDTERCERO	VARCHAR(20) '$.IDTERCERO'	,CODUNG			VARCHAR(20)		'$.CODUNG'
			,CCOSTO		VARCHAR(20) '$.CCOSTO'		,IDSEDE			VARCHAR(20)		'$.IDSEDE'
			,IDAREA		VARCHAR(20) '$.IDAREA' )
		
		IF (SELECT COALESCE(COMPRASOL,0) FROM IBOD WHERE IDBODEGA = @IDBODEGA) = 0 AND @PROCESO = 'NUEVO'
		BEGIN
			INSERT INTO @ERRORES(ERROR) SELECT 'Su bodega configurada, no tiene permiso para generar Solicitudes de Compra.' 
		END
		IF (SELECT COALESCE(IDBODEGAPIDE,'') FROM IBOD WHERE IDBODEGA = @IDBODEGA) = 0 AND (SELECT COALESCE(COMPRASOL,0) FROM IBOD WHERE IDBODEGA = @IDBODEGA) <> 0 AND @PROCESO = 'NUEVO'
		BEGIN
			INSERT INTO @ERRORES(ERROR) SELECT 'No tiene configurada la bodega destino.' 
		END
		IF (SELECT COUNT(*) FROM @ERRORES)> 0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @ERRORES
			RETURN
		END
		ELSE
		BEGIN
			BEGIN TRY
				IF @PROCESO = 'NUEVO'
				BEGIN
					--EXEC SPK_GENCONSECUTIVO @COMPANIA,@IDSEDE,'@FCOM', @CNSFCOM OUTPUT 
					--SELECT @CNSFCOM = @IDSEDE + RIGHT('00000000' + CONVERT(VARCHAR(8), @CNSFCOM), 8)
					EXEC SPQ_GENSEQUENCE @SEDE=@IDSEDE,@PREFIJO='@FCOM', @LONGITUD=8 ,@NVOCONSEC=@CNSFCOM OUTPUT

					SELECT @IDBODEGA_DESTINO = (SELECT IDBODEGAPIDE FROM IBOD WHERE IDBODEGA = @IDBODEGA)

					INSERT INTO FCOM (CNSFCOM, COMPANIA, IDTERCERO, ESTADO, OBSERVACION, VR_ANTESIVA, IVA, VR_TOTAL
					, AJUSTADO, AJUSTEALPESO, ENINVENTARIO, ENCXP, VR_DESCUENTO, USUARIO, FECHA, FECHAORDEN, ORDENCOMPRA
					, IDBODEGA, CCOSTO, IDAREA, IDTIPOSER, CODUNG, CODPRG, DECONSUMO, IDBODEGA_ORIGEN )
					SELECT @CNSFCOM, '01', IDTERCERO, 'C', OBSERVACION, 0, 0, 0, 0, 0, 0, 0,0,@USUARIO, DBO.FNK_GETDATE(),DBO.FNK_GETDATE(), 0
					, @IDBODEGA_DESTINO, CCOSTO, IDAREA, 'SolCom', CODUNG, NULL , 0, @IDBODEGA
					FROM #datoSOL

					INSERT INTO FCOMD (CNSFCOM, IDARTICULO, ESTADO, VLR_UNITARIO, CANTIDAD, VR_ANTESIVA, IVA
					, VR_TOTAL, VR_UNITMASIVA, TIENEIVA, FACTORIVA, VR_DESCUENTO, TIPO, UTILIDAD, TDESCUENTO, TIPODTO, PDTO, NOLOTE)
					SELECT @CNSFCOM, RPDX.ID1, 'C',  0, RPDX.CANTIDAD, 0, 0,0,0,0,0,0,'Articulos', 0,0,'V',0, ''
					FROM RPDX, #datoSOL WHERE RPDX.CNS = #datoSOL.CNSFCOM

					DELETE RPDX FROM   RPDX, #datoSOL WHERE RPDX.CNS = #datoSOL.CNSFCOM

				END
				IF @PROCESO = 'EDITAR'
				BEGIN
					UPDATE FCOM SET FCOM.OBSERVACION = #datoSOL.OBSERVACION, FCOM.CCOSTO = #datoSOL.CCOSTO, FCOM.IDAREA = #datoSOL.IDAREA FROM FCOM ,#datoSOL WHERE FCOM.CNSFCOM =  #datoSOL.CNSFCOM
				END
			END TRY
			BEGIN CATCH 
				INSERT INTO @ERRORES(ERROR) SELECT ERROR_MESSAGE() ;  
			END CATCH  
			IF (SELECT COUNT(*) FROM @ERRORES)> 0
			BEGIN
				SELECT 'KO' OK
				SELECT ERROR FROM @ERRORES
				RETURN
			END
			SELECT 'OK'OK
		END 
	END	
	IF @METODO = 'CRUD_IART'
	BEGIN
		SELECT @PROCESO = PROCESO ,@CNSFCOM = CNSFCOM, @IDARTICULO = IDARTICULO, @CANTIDAD = CANTIDAD
		FROM OPENJSON(@PARAMETROS)
		WITH( PROCESO	VARCHAR(20)	'$.PROCESO'			,CNSFCOM	VARCHAR(20)	'$.CNSFCOM'	
			,IDARTICULO	VARCHAR(20)	'$.IDARTICULO'		,CANTIDAD	INT			'$.CANTIDAD' )
		
		IF @PROCESO = 'NUEVO' AND EXISTS (SELECT * FROM FCOMD WHERE CNSFCOM = @CNSFCOM AND IDARTICULO = @IDARTICULO)
		BEGIN
			INSERT INTO @ERRORES(ERROR) SELECT 'El insumo ya se encuentra registrado.' 
		END
		IF @PROCESO = 'EDITAR' AND NOT EXISTS (SELECT * FROM FCOMD WHERE CNSFCOM = @CNSFCOM AND IDARTICULO = @IDARTICULO)
		BEGIN
			INSERT INTO @ERRORES(ERROR) SELECT 'El insumo ya se encuentra registrado.' 
		END
		IF (SELECT COUNT(*) FROM @ERRORES)> 0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @ERRORES
			RETURN
		END
		ELSE
		BEGIN
			BEGIN TRY
				IF @PROCESO = 'EDITAR'
				BEGIN
					UPDATE FCOMD SET CANTIDAD = @CANTIDAD, IDARTICULO = @IDARTICULO WHERE FCOMD.CNSFCOM = @CNSFCOM AND FCOMD.IDARTICULO = @IDARTICULO
				END
				IF @PROCESO = 'NUEVO'
				BEGIN
					INSERT INTO FCOMD (CNSFCOM, IDARTICULO, ESTADO, VLR_UNITARIO, CANTIDAD, VR_ANTESIVA, IVA
					, VR_TOTAL, VR_UNITMASIVA, TIENEIVA, FACTORIVA, VR_DESCUENTO, TIPO, UTILIDAD, TDESCUENTO, TIPODTO, PDTO, NOLOTE)
					SELECT @CNSFCOM, @IDARTICULO, 'C',  0, @CANTIDAD, 0, 0,0,0,0,0,0,'Articulos', 0,0,'V',0, ''
				END
			END TRY
			BEGIN CATCH 
				INSERT INTO @ERRORES(ERROR) SELECT ERROR_MESSAGE() ;  
			END CATCH  
			IF (SELECT COUNT(*) FROM @ERRORES)> 0
			BEGIN
				SELECT 'KO' OK
				SELECT ERROR FROM @ERRORES
				RETURN
			END
			SELECT 'OK'OK
		END 
	END	
	IF @METODO = 'CLONAR'
	BEGIN
		SELECT @CNSFCOM = CNSFCOM
		FROM OPENJSON(@PARAMETROS)
		WITH( CNSFCOM	VARCHAR(20)	'$.CNSFCOM'	 )
	
		IF (SELECT COUNT(*) FROM @ERRORES)> 0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @ERRORES
			RETURN
		END
		ELSE
		BEGIN
			BEGIN TRY
				SELECT @CNSFCOMN = NULL
				EXEC SPQ_GENSEQUENCE @SEDE=@IDSEDE,@PREFIJO='@FCOM', @LONGITUD=8 ,@NVOCONSEC=@CNSFCOMN OUTPUT

				EXEC SPK_CLONA_ORDENCOMPRA @CNSFCOM, @CNSFCOMN, @USUARIO
			END TRY
			BEGIN CATCH 
				INSERT INTO @ERRORES(ERROR) SELECT ERROR_MESSAGE() ;  
			END CATCH  
			IF (SELECT COUNT(*) FROM @ERRORES)> 0
			BEGIN
				SELECT 'KO' OK
				SELECT ERROR FROM @ERRORES
				RETURN
			END
			SELECT 'OK'OK
		END 
	END	
END