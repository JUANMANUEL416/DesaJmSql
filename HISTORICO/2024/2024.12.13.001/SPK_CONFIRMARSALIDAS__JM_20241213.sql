IF EXISTS(SELECT NAME FROM SYSOBJECTS WHERE NAME='SPK_CONFIRMARSALIDAS' AND XTYPE='P')
BEGIN
   DROP PROCEDURE SPK_CONFIRMARSALIDAS
END

GO
CREATE PROCEDURE DBO.SPK_CONFIRMARSALIDAS
@IDBODEGA VARCHAR(20),
@CNSMOV   VARCHAR(20),
@USUARIO  VARCHAR(12),
@COMPANIA VARCHAR(2),
@SEDE     VARCHAR(5)
WITH ENCRYPTION
AS
DECLARE @ENCONTRADO            DECIMAL(9,2)
DECLARE @AFECTACOSTO           SMALLINT
DECLARE @CANTIDAD              DECIMAL(14,2)
DECLARE @CANTIDAD_SALIDA       DECIMAL(14,2)
DECLARE @CONTADOR              SMALLINT
DECLARE @S                     VARCHAR(1)
DECLARE @CNS                   VARCHAR(20)
DECLARE @LONG                  SMALLINT
DECLARE @P                     SMALLINT
DECLARE @CNSITRA               VARCHAR(20)
DECLARE @ESTRANSITO            SMALLINT
DECLARE @ESTRANSFORMABLE       VARCHAR(2)
DECLARE @TRANSFMUCHOS1         VARCHAR(20)
DECLARE @TRANSFMUCHOS1E        VARCHAR(20)
DECLARE @IDTIPOMOV             VARCHAR(2)
DECLARE @IDINVTFEN             VARCHAR(2)
DECLARE @CANTIDAD_IEXI         DECIMAL(14,2)
DECLARE @PROCEDENCIA           VARCHAR(10)
DECLARE @PCOSTO                DECIMAL(16,3)
DECLARE @IDARTICULO_CUR        VARCHAR(20)
DECLARE @CANTIDAD_CUR          DECIMAL(14,2)
DECLARE @CANTPEDIDA_CUR        DECIMAL(14,2)
DECLARE @NOLOTE_CUR            VARCHAR(20)
DECLARE @FECHAVENCE_CUR        DATETIME
DECLARE @NOLOTEPEDIDO_CUR      VARCHAR(20)
DECLARE @NOLOTE_CUR_IEXI       VARCHAR(20)
DECLARE @IDARTICULO_CUR_IEXI   VARCHAR(20)
DECLARE @CANTIDAD_CUR_IEXI     DECIMAL(14,2)
DECLARE @FECHAVENCE_CUR_IEXI   DATETIME
DECLARE @NOLOTEPEDIDO_CUR_IEXI VARCHAR(20)
DECLARE @IDINVTRASLOTESAL      VARCHAR(2)
DECLARE @IDINVTRASLOTEENT      VARCHAR(2)
DECLARE @DIASAVENCER           INT
DECLARE @EXISTENCIA            DECIMAL(14,2)
DECLARE @NROCOMPROBANTE        VARCHAR(20)
DECLARE @SYS_COMPUTERNAME      VARCHAR(128)
DECLARE @ESTADO                INT
DECLARE @SECONTABILIZA         INT
DECLARE @TIPOBODEGA            VARCHAR(20)
DECLARE @IDARTD                VARCHAR(20)
DECLARE @CANTDES               DECIMAL(18,6)
DECLARE @CERRADO               VARCHAR(20)
DECLARE @ANO                   VARCHAR(10)
DECLARE @MES                   VARCHAR(10)
DECLARE @NODOCUMENTO           VARCHAR(20)
DECLARE @EXCEPCION_CON         INT
DECLARE @CNSHDUXS              VARCHAR(20)
DECLARE @CNSHDUXS_N            VARCHAR(20)
DECLARE @CNSHTX_CUR            VARCHAR(20)
DECLARE @CNSHTX2_CUR           VARCHAR(20)
DECLARE @MDOSIF                TINYINT
DECLARE @EQUICC                INT
DECLARE @DOSIS                 DECIMAL(14,6)
DECLARE @DIF                   DECIMAL(14,2)
DECLARE @TOTDOSIS              DECIMAL(14,2)
DECLARE @VOK                   INT
DECLARE @CON                   INT
DECLARE @HOST_MPEDINV          VARCHAR(254)
DECLARE @CNSMOVCOMPRA          VARCHAR(20)
DECLARE @ERROR                 INT
DECLARE @F_VENCEIMOV           DATETIME
DECLARE @CANTIDADSAL           DECIMAL(14,2)
DECLARE @NOPRESTACION          VARCHAR(20)
DECLARE @NOADMISION            VARCHAR(20)
DECLARE @CCOSTOBODV            VARCHAR(20)
DECLARE @IDAREABODV            VARCHAR(20)


BEGIN  
   PRINT'@IDBODEGA ='+ '   '+ @IDBODEGA 
   PRINT'@CNSMOV   = '+ '   '+@CNSMOV


	DECLARE @IDINVDEVPROVEEDOR VARCHAR(20)
	DECLARE @IDINVTRASLACTIVOS VARCHAR(20)
	DECLARE @PEDIDOHPREAIZSOL VARCHAR(20)
	
	SELECT @IDINVDEVPROVEEDOR = DATO FROM USVGS WHERE IDVARIABLE='IDINVDEVPROVEEDOR'
	SELECT @IDINVTRASLACTIVOS = DATO FROM USVGS WHERE IDVARIABLE='IDINVTRASLACTIVOS'
	SELECT @PEDIDOHPREAIZSOL  = DATO FROM USVGS WHERE IDVARIABLE='PEDIDOHPREAIZSOL'

	
   /* SE COMENTARIZA YA NO SE SE NECESITA VALIDACION PREVIA NUEVO PROCESO DE ENTREGA  
   SELECT @CANTIDADSAL = SUM(EXISTOTAL) 
   FROM IDXB INNER JOIN IMOVH ON IDXB.IDARTICULO = IMOVH.IDARTICULO 
   WHERE COALESCE(IMOVH.ESTADO,0)=0 AND IDXB.IDBODEGA =@IDBODEGA AND IMOVH.CNSMOV=@CNSMOV
   PRINT 'CANTIDADSAL='+CONVERT(VARCHAR(20), @CANTIDADSAL)
   IF ( 
       SELECT SUM(IDXB.EXISTOTAL) 
       FROM   IDXB INNER JOIN ( SELECT ISAL.IDARTICULO
                                FROM   ISAL INNER JOIN  IART ON ISAL.IDARTICULO=IART.IDARTICULO
                                            INNER JOIN  IMOVH ON ISAL.CNSMOV=IMOVH.CNSMOV
                                WHERE  ISAL.CNSMOV  = @CNSMOV
                                AND   COALESCE(IMOVH.ESTADO,0)=0 
                               ) ISAL ON IDXB.IDARTICULO=ISAL.IDARTICULO
       WHERE IDXB.IDBODEGA = @IDBODEGA
      )>0
   BEGIN  
   */   
       
   SET @SYS_COMPUTERNAME = HOST_NAME()
        
   SELECT @AFECTACOSTO = 0,-- ES SALIDA NO DEBE AFECTAR EL COSTO
            @ESTRANSITO=ITMO.GENTRANSITO,
            @IDTIPOMOV=ITMO.IDTIPOMOV,
            @PROCEDENCIA = IMOV.PROCEDENCIA, 
            @NROCOMPROBANTE=IMOV.NROCOMPROBANTE, 
            @SECONTABILIZA=IIF(ISNULL(IBOD.NOCONTABILIZA,0)=1,0,ITMO.SECONTABILIZA),
            @NODOCUMENTO = IMOV.NODOCUMENTO ,
			@CCOSTOBODV = IBOD.CCOSTO,
			@TIPOBODEGA=IBOD.TIPOBODEGA
   FROM   IBOD INNER JOIN IMOV ON IBOD.IDBODEGA = IMOV.IDBODEGA 
               INNER JOIN ITMO ON IMOV.IDTIPOMOV = ITMO.IDTIPOMOV
   WHERE  IMOV.CNSMOV=@CNSMOV 
   
   --20211227 SE REGRESA SI ES TRASLADO DE ACTIVOS Y NO TIENE CONFIGURADO EL TIPO DE ACTIVO
    IF @IDINVTRASLACTIVOS = @IDTIPOMOV
	BEGIN
		IF (SELECT COUNT(1) FROM IART INNER JOIN IMOVH ON IMOVH.IDARTICULO=IART.IDARTICULO WHERE IMOVH.CNSMOV=@CNSMOV AND COALESCE(IART.IDTIPOACTIVO,'')='')>0
		BEGIN
			RAISERROR('EXISTEN ARTICULOS SIN TIPO DE ACTIVO, NO SE PUEDE CONTINUAR',16,1)
			RETURN
		END	
	END	
   
   --BEGIN TRAN 
   --BEGIN TRY
	   SELECT @NOPRESTACION=NOPRESTACION,@NOADMISION=NODOCUMENTO FROM IMOV WHERE CNSMOV=@CNSMOV                                        
	   PRINT 'SI HAY POR LO MENOS ALGUNA EXISTENCIA. '+@IDBODEGA+' '+@CNSMOV
	   UPDATE IMOVH 
	   SET ESTADO = 9 
	   FROM IMOVH INNER JOIN IART ON IART.IDARTICULO = IMOVH.IDARTICULO
	   WHERE  IMOVH.CNSMOV     = @CNSMOV 
	   AND    COALESCE(IMOVH.ESTADO,0)     = 0

	   SET @PCOSTO=-99
      
	   IF NOT EXISTS(SELECT IDVARIABLE FROM USVGS WHERE IDVARIABLE='IDINVDIASPARAVENCER')
	   BEGIN
		  INSERT INTO USVGS(IDVARIABLE,DESCRIPCION,TP_VARIABLE,DATO,INDVIGENCIA,OBSERVACION)
		  VALUES('IDINVDIASPARAVENCER','No. D�as AnTes de Vencer para EnTrega.','Numerica',-30,null,'')
	   END 
      
		SELECT @DIASAVENCER = COALESCE(DATO,0) FROM USVGS WHERE IDVARIABLE='IDINVDIASPARAVENCER' 
		IF ISNUMERIC(@DIASAVENCER)=0
		BEGIN
			SELECT @DIASAVENCER=30
		END
   
		SELECT @ERROR=1

		DECLARE CUR_IMOVH CURSOR FOR
			SELECT X.IDARTICULO,X.NOLOTE,X.CANTIDAD,X.NOLOTEPEDIDO,X.FECHAVENCE,IMOVH.CNSHTX
			FROM   IMOVH INNER JOIN ISAL X ON IMOVH.CNSMOV=X.CNSMOV 
											AND IMOVH.IDARTICULO=X.IDARTICULO_IMOVH

			WHERE  IMOVH.CNSMOV = @CNSMOV 
			AND    X.CNSMOV     = @CNSMOV 
			AND    IMOVH.ESTADO = 9
			AND    IMOVH.CANTIDAD > 0
			GROUP BY X.IDARTICULO, X.NOLOTE, X.CANTIDAD, X.NOLOTEPEDIDO, X.FECHAVENCE,IMOVH.CNSHTX      
   
		OPEN CUR_IMOVH
      
		FETCH NEXT FROM CUR_IMOVH
		INTO @IDARTICULO_CUR,@NOLOTE_CUR,@CANTIDAD_CUR,@NOLOTEPEDIDO_CUR,@FECHAVENCE_CUR, @CNSHTX_CUR
		WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT 'ENTRE AL CURSOR'
			SELECT @ERROR=0
			--SELECT @CANTIDAD_SALIDA =  @CANTIDAD_SALIDA + @CANTIDAD_CUR
			--SELECT @CANTIDAD_IEXI = SUM(EXISLOTE) 
			--FROM IEXI 
			--WHERE IDBODEGA    = @IDBODEGA 
			--   AND IDARTICULO  = @IDARTICULO_CUR
           
			SELECT @PCOSTO    = PCOSTO 
			FROM IART 
			WHERE IDARTICULO  = @IDARTICULO_CUR
           
			IF (@PCOSTO<0) OR (@PCOSTO IS NULL)
			BEGIN
				SET @PCOSTO=0
			END
           
			--IF @CANTIDAD_IEXI > 0
			--BEGIN
				PRINT'-------------------------------------'
				PRINT 'IDARTICULO = ' + CONVERT(VARCHAR(20),@IDARTICULO_CUR)
				PRINT 'NOLOTE     = ' + CONVERT(VARCHAR(20),@NOLOTE_CUR)
				PRINT 'IDBODEGA   = ' + CONVERT(VARCHAR(20),@IDBODEGA)
				PRINT CONVERT(VARCHAR(20),'CANTIDAD   = ' + CONVERT(VARCHAR(20),@CANTIDAD_CUR))
				PRINT'-------------------------------------'
				----------------------------------------------------
				--ACTUALIZA FECHA DE ISAL 
				----------------------------------------------------
				PRINT '----------ACTUALIZA LAS FECHAS DE LOS ISAL DE ACUERDO A LA FECHA DE CONFIRMACION DE EL MOVIMIENTO-------'
				UPDATE ISAL
				SET FECHA = (SELECT FECHACONF FROM IMOV WHERE CNSMOV = @CNSMOV)
				WHERE CNSMOV = @CNSMOV                      
				PRINT '--------------------------------------------------------------------------------------------------------'
				----------------------------------------------------
				--ACTUALIZA EXISTENCIA EN IEXI
				----------------------------------------------------
            
				PRINT '--------ACTUALIZA EXISTENCIAS IEXI------------------------'
				PRINT '----- YA LO HACE  EN CLARION ANTES DE CONFIRMAR EL MOVIMIENTO '-- JJIMENEZ 19/02/2016
				--IF @PROCEDENCIA = 'INV
				--BEGIN            
				--   UPDATE IEXI 
				--   SET EXISLOTE = EXISLOTE - @CANTIDAD_CUR
				--   FROM IEXI 
				--   WHERE IDARTICULO = @IDARTICULO_CUR
				--   AND   NOLOTE     = @NOLOTE_CUR
				--   AND   IDBODEGA   = @IDBODEGA
				--END
				PRINT '---------------------------------------------------------'
				---------------------------------------------------
				--ACTUALIZA EXISTENCIAS EN IDXB -- EZERPA 13.12.2018 CODIGO PASADO AL FINAL
				---------------------------------------------------
				--PRINT '--------ACTUALIZA EXISTENCIAS IDXB------------------------'
				--UPDATE IDXB 
				--SET    EXISTOTAL    = EXISTOTAL - @CANTIDAD_CUR 
				--WHERE  IDBODEGA     = @IDBODEGA 
				--AND    IDARTICULO   = @IDARTICULO_CUR
            
				--TRAER PRECIO DE COSTO

			IF (@NOLOTE_CUR IS NULL) OR (LTRIM(RTRIM(@NOLOTE_CUR))='') OR (@PROCEDENCIA<>'INV')
			BEGIN
				PRINT 'NO ES DE INVENTARIO'
				SET @CANTIDAD = @CANTIDAD_CUR
				SET @CANTIDAD_SALIDA = 0
			END
			ELSE
			BEGIN
				PRINT 'ES DE INVENTARIO'
				-- MOD. JQUIROGA 20090418 con AARROYO
				IF @IDTIPOMOV = @IDINVDEVPROVEEDOR
				BEGIN
					SELECT @PCOSTO = PCOSTO 
					FROM IMOVH 
					WHERE CNSMOV=@CNSMOV AND IDARTICULO=@IDARTICULO_CUR AND NOLOTE = @NOLOTE_CUR     
				END      
			END
			PRINT '---------------------------------------------------------'
			------------------------------------------------------
			--ACTUALIZA EXISTENCIAS EN IART
			------------------------------------------------------
			IF 1=2
			BEGIN
				IF @AFECTACOSTO=1 AND @TIPOBODEGA = 'Propia'
				BEGIN
					PRINT 'ACTUALIZA EXISTENCIAS EN IART SE AFECTA COSTOS'   
					UPDATE IART 
					SET   
						PCOSTO = ((ISNULL(IART.PCOSTO,0) * ISNULL(X.EXISTOTAL,0)) - (IART.PCOSTO * @CANTIDAD_CUR))/(ISNULL(X.EXISTOTAL,0)-@CANTIDAD_CUR),
						IART.EXISTOTAL = ISNULL(IART.EXISTOTAL,0)- @CANTIDAD_CUR 
					FROM IART INNER JOIN(
											SELECT IDXB.IDARTICULO, SUM(EXISTOTAL) EXISTOTAL
											FROM   IDXB INNER JOIN IBOD ON IDXB.IDBODEGA = IBOD.IDBODEGA
											WHERE  IBOD.TIPOBODEGA = 'Propia'
											GROUP BY IDXB.IDARTICULO
											) X ON IART.IDARTICULO = X.IDARTICULO
					WHERE IART.IDARTICULO = @IDARTICULO_CUR
				END
				ELSE
				BEGIN
					PRINT 'ACTUALIZA EXISTENCIAS EN IART NO AFECTA COSTOS'   
					UPDATE IART SET IART.EXISTOTAL = ISNULL(IART.EXISTOTAL,0)- @CANTIDAD_CUR
					WHERE  @IDARTICULO_CUR=IART.IDARTICULO
				END            
			END


			-----------------------------------------------------------------------------
			--DEVOLUCIONES A PROVEEDORES              
			-----------------------------------------------------------------------------
			IF @IDTIPOMOV = @IDINVDEVPROVEEDOR
			BEGIN
				PRINT 'ES DEVOLUCION A PROVEEDORES'
				UPDATE IMOVH SET  FECHACONF   = DBO.FNK_FECHA_SIN_MLS(GETDATE()),
									PCOSTOANTES = @PCOSTO,          USUARIOCONF = @USUARIO, EXISTENCIA = @EXISTENCIA
				WHERE  CNSMOV     = @CNSMOV 
				AND    IDARTICULO = @IDARTICULO_CUR 
				AND    NOLOTE     = @NOLOTE_CUR
			END
			ELSE
			BEGIN
				PRINT 'NO ES DEVOLUCION A PROVEEDORES'
				UPDATE IMOVH SET  FECHACONF   = DBO.FNK_FECHA_SIN_MLS(GETDATE()), PCOSTO = @PCOSTO,
									USUARIOCONF = @USUARIO, EXISTENCIA = @EXISTENCIA
				WHERE  CNSMOV     = @CNSMOV 
				AND    IDARTICULO = @IDARTICULO_CUR 
				AND    NOLOTE     = @NOLOTE_CUR
				IF (SELECT TIPO FROM ITMO WHERE IDTIPOMOV=@IDTIPOMOV)='Credito'
				BEGIN            
					UPDATE IMOVH SET  PCOSTOANTES = @PCOSTO
					WHERE  CNSMOV     = @CNSMOV 
					AND    IDARTICULO = @IDARTICULO_CUR 
					AND    NOLOTE     = @NOLOTE_CUR
				END
			END
		--END              
			FETCH NEXT FROM CUR_IMOVH
			INTO @IDARTICULO_CUR,@NOLOTE_CUR,@CANTIDAD_CUR,@NOLOTEPEDIDO_CUR,@FECHAVENCE_CUR, @CNSHTX_CUR
		END
		CLOSE CUR_IMOVH
		DEALLOCATE CUR_IMOVH


		IF @ERROR=1
		BEGIN
			UPDATE IMOVH 
			SET ESTADO = 0
			FROM IMOVH INNER JOIN IART ON IART.IDARTICULO = IMOVH.IDARTICULO
			WHERE  IMOVH.CNSMOV     = @CNSMOV 
			AND    IMOVH.ESTADO     = 9
			PRINT 'ERROR EN EL MOVIMIENTO NO SE PUEDE CONTINUAR'
			RETURN
		END
		ELSE
		BEGIN
			DECLARE CUR_REVI CURSOR FOR
				SELECT IDARTICULO,SUM(CANTIDAD)
				FROM   IMOVH 
				WHERE  IMOVH.CNSMOV = @CNSMOV 
				GROUP BY IDARTICULO
			OPEN CUR_REVI
			FETCH NEXT FROM CUR_REVI
			INTO @IDARTICULO_CUR,@CANTIDAD_CUR--,@NOLOTEPEDIDO_CUR,@FECHAVENCE_CUR, @CNSHTX_CUR
			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF @AFECTACOSTO=1 AND @TIPOBODEGA = 'Propia'
				BEGIN
					PRINT 'ACTUALIZA EXISTENCIAS EN IART SE AFECTA COSTOS'   
					UPDATE IART SET   
						PCOSTO = ((ISNULL(IART.PCOSTO,0) * ISNULL(X.EXISTOTAL,0)) - (@PCOSTO * @CANTIDAD_CUR))/(ISNULL(X.EXISTOTAL,0) - @CANTIDAD_CUR),
						IART.EXISTOTAL = ISNULL(IART.EXISTOTAL,0) - @CANTIDAD_CUR 
					FROM IART INNER JOIN(
											SELECT IDXB.IDARTICULO, SUM(EXISTOTAL) EXISTOTAL
											FROM   IDXB INNER JOIN IBOD ON IDXB.IDBODEGA = IBOD.IDBODEGA
											WHERE  IBOD.TIPOBODEGA = 'Propia'
											GROUP BY IDXB.IDARTICULO
											) X ON IART.IDARTICULO = X.IDARTICULO
					WHERE IART.IDARTICULO = @IDARTICULO_CUR
				END
				ELSE
				BEGIN
					EXEC DBO.SPK_REVISA_EXISTS_INV @IDARTICULO_CUR
				END  
			
				FETCH NEXT FROM CUR_REVI
				INTO @IDARTICULO_CUR,@CANTIDAD_CUR
			END
			CLOSE CUR_REVI
			DEALLOCATE CUR_REVI
		END
	   ----------------------------------------------------------------
	   -- HACIENDO LA NOTA AUTOMATICA
	   ----------------------------------------------------------------      
	   IF @IDTIPOMOV = @IDINVDEVPROVEEDOR
	   BEGIN
		  SELECT @CNSMOVCOMPRA=CNSITRA FROM IMOV WHERE CNSMOV=@CNSMOV
		  EXEC DBO.SPK_GENERANOTADB_DEVOLUCION @CNSMOV,@CNSMOVCOMPRA,@USUARIO,@COMPANIA ,@SEDE,@SYS_COMPUTERNAME 
	   END
	   ----------------------------------------------------------------
	   -- ESTADO CONFIRMADO DE EL MOVIMIENTO
	   ----------------------------------------------------------------
	   PRINT 'ACTUALIZA ESTADO DE EL MOVIMIENTO'
	   UPDATE IMOV SET ESTADO = '1', USUARIOCONF = @USUARIO, FECHACONF = DBO.FNK_FECHA_SIN_MLS(GETDATE()),
	  CCOSTO= CASE WHEN COALESCE(CCOSTO,'') NOT IN (SELECT CCOSTO FROM CEN) AND @TIPOBODEGA='Virtual' THEN @CCOSTOBODV ELSE  CCOSTO END ,
	  IDAREA= CASE WHEN COALESCE(CCOSTO,'') NOT IN (SELECT CCOSTO FROM CEN) AND @TIPOBODEGA='Virtual' THEN @IDAREABODV ELSE  IDAREA END ,

				   SECONTABILIZA = (SELECT SECONTABILIZA FROM ITMO WHERE ITMO.IDTIPOMOV=IMOV.IDTIPOMOV)
	   WHERE  CNSMOV = @CNSMOV
      
      
	   SELECT @ENCONTRADO = COUNT(*) 
	   FROM IMOVH 
	   WHERE CNSMOV=@CNSMOV AND ESTADO=9
      
	   IF @ENCONTRADO>0
	   BEGIN
		  PRINT 'ENCONTRO PENDIENTES'
		  --PENDIENTES
		  SET @CONTADOR=0
		  SET @CNS=''
		  SET @P=1
		  SET @LONG = LEN(LTRIM(RTRIM(@CNSMOV)))
		  WHILE @LONG>=@P
		  BEGIN
			 SET @S = SUBSTRING(@CNSMOV,@P,1)
			 IF @S<>'-'
				SET @CNS=@CNS+@S
			 ELSE
				BREAK
			 SET @P=@P+1
			 CONTINUE
		  END
		  SELECT @ENCONTRADO = COUNT(*) 
		  FROM IMOVH 
		  WHERE CNSMOV=@CNSMOV 
			 AND CANTIDAD<>CANTPEDIDA 
			 AND ESTADO=9
           
		  IF @ENCONTRADO>0
		  BEGIN
            
			 DECLARE @CNSMOVUNO VARCHAR(20)
			 SELECT @CONTADOR  = COUNT(*) FROM IMOV WHERE CNSMOV LIKE @CNS+'%'
			 SELECT @CNSMOVUNO = @CNS+'-'+LTRIM(RTRIM(STR(@CONTADOR)))
            
			 INSERT INTO IMOV (CNSMOV, IDBODEGA, IDTIPOMOV, NODOCUMENTO, TIPODOCU, FECHAMOV, CCOSTO,
							   IDSOLICITA, IDTERCERO, IDFUNCIONARIO, IDRECIBE, FACTORVENTA, ESTADO,
							   IDBODEGAEXTERNA, cnsTran, OBSERVACION, CNSFCOM, SUBIOCOMPRA, 
							   NOPRESTACION, IDAREA, CONTABILIZADA, NROCOMPROBANTE, PROCEDENCIA, 
							   USUARIO, USUARIOCONF, FECHACONF, PARCIAL, IDAREAH, NIVELATENCION,
							   SYS_CompuTerName, TIENECAMBIO, IDITAR, ESTRANSITO, CNSREP, CNSIDEV, CODUNG, CODPRG)
			 SELECT @CNSMOVUNO, IDBODEGA, IDTIPOMOV, NODOCUMENTO, TIPODOCU,  FECHAMOV, CCOSTO, -- JEDM 06.JUL.2006 SE QUITO EN FECHAMOV = DBO.FNK_FECHA_SIN_MLS(GETDATE())
							IDSOLICITA, IDTERCERO, IDFUNCIONARIO, IDRECIBE, FACTORVENTA, '0',
							IDBODEGAEXTERNA, cnsTran, OBSERVACION, CNSFCOM, SUBIOCOMPRA, 
							NOPRESTACION, IDAREA, CONTABILIZADA, NROCOMPROBANTE, PROCEDENCIA, 
							USUARIO, USUARIOCONF, NULL, 1, IDAREAH, NIVELATENCION,
							SYS_CompuTerName, TIENECAMBIO, IDITAR, ESTRANSITO, CNSREP, CNSIDEV, CODUNG, CODPRG
			 FROM IMOV WHERE CNSMOV=@CNSMOV
            
			 /*HTX: AHORA HACEMOS LA CREACION DEL IMOVH DE FALTANTES EN UN CURSOR PARA PODER CONTROLAR LAS UNIDOSIS*/
			 DECLARE IMOVHFALT_CUR CURSOR FOR
            
			 SELECT IDARTICULO, NOLOTE, CNSHTX, CANTPEDIDA, CANTIDAD
			 FROM   IMOVH 
			 WHERE  CNSMOV    = @CNSMOV 
			 AND    CANTIDAD <> CANTPEDIDA 
			 AND    ESTADO    = 9

            
			 INSERT INTO IMOVH(CNSMOV, IDARTICULO, EXISTENCIA, CANTIDAD, CANTPEDIDA, PCOSTO, 
							   NOLOTE, NOLOTEPEDIDO, FECHAVENCE, ESTADO, IDARTICULOTF, CANTIDADTF,
							   PCOSTOANTES, CNSTRAN, ITEM, PVENTA, USUARIO, USUARIOCONF, FECHACONF,
							   PRIEXI, FECHAREPOSI, IDARTICULOORI, CANTIDADORI, TIENECAMBIO, COTIZADO, CNSHTX, IDSERVICIO )
			 SELECT @CNSMOVUNO, IDARTICULO, EXISTENCIA, 0, CANTPEDIDA - CANTIDAD, PCOSTO, 
							NOLOTE, NOLOTEPEDIDO, FECHAVENCE, 0, IDARTICULOTF, CANTIDADTF,
							PCOSTOANTES, CNSTRAN, ITEM, PVENTA, USUARIO, USUARIOCONF, NULL,
							PRIEXI, FECHAREPOSI, IDARTICULOORI, CANTIDADORI, TIENECAMBIO, COTIZADO, CNSHTX, IDSERVICIO 
			 FROM IMOVH WHERE CNSMOV=@CNSMOV 
			 AND CANTIDAD<>CANTPEDIDA 
			 AND ESTADO=9
			 ------------------------------------------------------------------
			 --PENDIENTE MIRAR ESTA ACTUALIZACION POR QUE ME PIDE EL NOLOTE
			 ------------------------------------------------------------------
			 IF @PROCEDENCIA  = 'HTX'
			 BEGIN
               
				UPDATE HTX SET CNSMOV = @CNSMOVUNO 
				FROM   HTX INNER JOIN SER ON HTX.IDSERVICIO=SER.IDSERVICIO
							INNER JOIN IMOVH ON HTX.CNSMOV = IMOVH.CNSMOV
											  AND HTX.CNSHTX=IMOVH.NOLOTE
											  AND SER.IDARTICULO=IMOVH.IDARTICULO                                    
				WHERE  HTX.NOADMISION  = @NODOCUMENTO                 
				AND    HTX.CNSMOV      = @CNSMOV
				AND    IMOVH.ESTADO    = 9
				AND    IMOVH.CANTIDAD <> IMOVH.CANTPEDIDA 
				AND    IMOVH.CANTIDAD  = 0
			 END  
			 IF @PROCEDENCIA='SALUD'
			 BEGIN           
				UPDATE HPRED SET CNSMOV=@CNSMOVUNO
				FROM HPRED INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO
						   INNER JOIN IMOVH ON SER.IDARTICULO=IMOVH.IDARTICULO
				WHERE HPRED.NOPRESTACION=@NOPRESTACION
				AND IMOVH.CNSMOV=@CNSMOVUNO
				AND NOT EXISTS(SELECT * FROM IMOVH X WHERE X.CNSMOV=@CNSMOV AND X.IDARTICULO=IMOVH.IDARTICULO AND CANTIDAD>0)
			 END
			 -----------------------------------------------------------------
			--PENDIENTES CIRUGIA
			IF @PROCEDENCIA='QXPGCX'
			BEGIN
				UPDATE CXPSI SET CNSMOV=@CNSMOVUNO
				FROM   CXPSI INNER JOIN IMOVH  ON CXPSI.CNSMOV     = IMOVH.CNSMOV 
														AND CXPSI.IDSERVICIO = IMOVH.IDARTICULO
				WHERE IMOVH.CNSMOV=@CNSMOV
				AND    IMOVH.ESTADO    = 9
				AND    IMOVH.CANTIDAD <> IMOVH.CANTPEDIDA 
				AND    IMOVH.CANTIDAD  = 0
			END
			 IF @PROCEDENCIA='QXCX'
			 BEGIN
					UPDATE QXPCXI SET CNSMOV=@CNSMOVUNO
					FROM   QXPCXI INNER JOIN IMOVH  ON QXPCXI.CNSMOV   = IMOVH.CNSMOV 
															AND  QXPCXI.ARTICULO = IMOVH.IDARTICULO
					WHERE IMOVH.CNSMOV=@CNSMOV
				AND    IMOVH.ESTADO    = 9
				AND    IMOVH.CANTIDAD <> IMOVH.CANTPEDIDA 
				AND    IMOVH.CANTIDAD  = 0  
				AND    QXPCXI.CNSMOV=  @CNSMOV
				AND    QXPCXI.NOADMISION=@NOADMISION        
			 END
		  END
      
		  SELECT @ESTRANSFORMABLE = DATO FROM USVGS WHERE IDVARIABLE='IDINVTFSA'
		  SELECT @IDINVTFEN       = DATO FROM USVGS WHERE IDVARIABLE='IDINVTFEN'
		  SELECT @TRANSFMUCHOS1   = DATO FROM USVGS WHERE IDVARIABLE = 'IDINVSALTRFMUCHAS1'
		  SELECT @TRANSFMUCHOS1E  = DATO FROM USVGS WHERE IDVARIABLE = 'IDINVENTTRFMUCHAS1'
		  -- TRANSITOS
		  PRINT 'ESTRANSITO = ' + CAST(@ESTRANSITO AS VARCHAR(2))
		  PRINT '@IDTIPOMOV = ' + @IDTIPOMOV
		  PRINT '@ESTRANSFORMABLE = ' + @ESTRANSFORMABLE
		  PRINT'CONSECUTIVO IMOV = '+COALESCE(@CNSMOVUNO, '')
		  PRINT'CONSECUTIVO =  '+@CNSMOV 
         
		  IF @ESTRANSITO=1 AND @IDTIPOMOV<>@ESTRANSFORMABLE
		  BEGIN
			 PRINT 'TRANSITO'
			 SET @CNSITRA=SPACE(20)
			 EXEC SPK_GENCONSECUTIVO @COMPANIA,@SEDE,'@ITRA',@CNSITRA OUTPUT
			 SELECT @CNSITRA = @SEDE + REPLACE(SPACE(8 - LEN(@CNSITRA))+LTRIM(RTRIM(@CNSITRA)),SPACE(1),0)
			 EXEC SPK_INSERTRANSITO @CNSMOV, @CNSITRA
		  END
		  --TRANSFORMACIONES
		  IF @IDTIPOMOV = @ESTRANSFORMABLE
		  BEGIN
			 SET @CNSITRA=SPACE(20)
			 
			 DECLARE @EXISTS BIT = 1
			 WHILE @EXISTS=1
			 BEGIN
				SELECT @EXISTS = 0
				EXEC   SPK_GENCONSECUTIVO @COMPANIA,@SEDE,'@MOV',@CNSITRA OUTPUT
				SELECT @CNSITRA = @SEDE + REPLACE(SPACE(8 - LEN(@CNSITRA))+LTRIM(RTRIM(@CNSITRA)),SPACE(1),0)

				SELECT @EXISTS = 1
				FROM  IMOV WITH(NOLOCK)
				WHERE CNSMOV=@CNSITRA
			 END

			 INSERT INTO IMOV (CNSMOV,IDBODEGA,IDTIPOMOV,NODOCUMENTO,TIPODOCU,FECHAMOV,CCOSTO,IDSOLICITA,
							   IDTERCERO, IDFUNCIONARIO, IDRECIBE, FACTORVENTA, ESTADO, IDBODEGAEXTERNA,                    
							   CNSTRAN,OBSERVACION,CNSFCOM,SUBIOCOMPRA,NOPRESTACION,IDAREA,CONTABILIZADA,                     
							   NROCOMPROBANTE,PROCEDENCIA,USUARIO,USUARIOCONF,FECHACONF,PARCIAL,IDITAR, CODUNG, CODPRG)
			 SELECT @CNSITRA,IDBODEGA=COALESCE(IDBODEGAEXTERNA, IIF(@ESTRANSFORMABLE=@IDTIPOMOV,IDBODEGA,NULL)),@IDINVTFEN,NODOCUMENTO,TIPODOCU,FECHAMOV,CCOSTO,IDSOLICITA, 
					  IDTERCERO, IDFUNCIONARIO,IDRECIBE, FACTORVENTA,'0',IDBODEGAEXTERNA=IIF(@ESTRANSFORMABLE=@IDTIPOMOV,IDBODEGA,NULL),CNSTRAN,OBSERVACION,
					  CNSFCOM,SUBIOCOMPRA,NOPRESTACION,IDAREA,CONTABILIZADA,NROCOMPROBANTE,PROCEDENCIA,
					  USUARIO,USUARIOCONF,FECHACONF,1,IDITAR, CODUNG, CODPRG
			 FROM   IMOV 
			 WHERE  CNSMOV = @CNSMOV
              
			 INSERT INTO IMOVH (CNSMOV,IDARTICULO,EXISTENCIA,CANTIDAD,CANTPEDIDA,PCOSTO,                      
							NOLOTE,NOLOTEPEDIDO,FECHAVENCE,ESTADO,IDARTICULOTF,CANTIDADTF,                      
							PCOSTOANTES,CNSTRAN,ITEM,PVENTA,USUARIO,USUARIOCONF,FECHACONF,PRIEXI)
			 SELECT @CNSITRA,IDARTICULOTF,SUM(EXISTENCIA),SUM(CANTIDADTF),0,SUM((PCOSTO*CANTIDAD)/CANTIDADTF),
				NOLOTE,NOLOTEPEDIDO,MAX(FECHAVENCE),0,'',0,AVG(PCOSTOANTES),
				CNSTRAN,ITEM,AVG(PVENTA),USUARIO,USUARIOCONF,MAX(FECHACONF),PRIEXI
			 FROM   IMOVH 
			 WHERE CNSMOV = @CNSMOV 
			 AND ESTADO = 9 
			 AND CANTIDAD > 0
			 GROUP BY IDARTICULOTF, NOLOTE,NOLOTEPEDIDO, CNSTRAN,ITEM,USUARIO,USUARIOCONF,PRIEXI
                    
		  END
         
		  --TRASLADOS ENTRE LOTES
		  SELECT @IDINVTRASLOTESAL=DATO FROM USVGS WHERE IDVARIABLE='IDINVTRASLOTESAL'
		  SELECT @IDINVTRASLOTEENT=DATO FROM USVGS WHERE IDVARIABLE='IDINVTRASLOTEENT'

		  IF @IDTIPOMOV=@IDINVTRASLOTESAL
		  BEGIN
			 SET @CNSITRA=SPACE(20)
			 EXEC SPK_GENCONSECUTIVO @COMPANIA,@SEDE,'@MOV',@CNSITRA OUTPUT
            
			 SELECT @CNSITRA = @SEDE + REPLACE(SPACE(8 - LEN(@CNSITRA))+LTRIM(RTRIM(@CNSITRA)),SPACE(1),0)
            
			 INSERT INTO IMOV (CNSMOV,         IDBODEGA,      IDTIPOMOV,   NODOCUMENTO,  TIPODOCU,  FECHAMOV,        CCOSTO,  IDSOLICITA,
							   IDTERCERO,      IDFUNCIONARIO, IDRECIBE,    FACTORVENTA,  ESTADO,    IDBODEGAEXTERNA, CNSTRAN,                           
							   OBSERVACION,    CNSFCOM,       SUBIOCOMPRA, NOPRESTACION, IDAREA,    CONTABILIZADA,                     
							   NROCOMPROBANTE, PROCEDENCIA,   USUARIO,     USUARIOCONF,  FECHACONF, PARCIAL,IDITAR,  CODUNG,  CODPRG ) 
			 SELECT @CNSITRA,IDBODEGAEXTERNA,@IDINVTRASLOTEENT,NODOCUMENTO,TIPODOCU,FECHAMOV,CCOSTO,IDSOLICITA, 
					  IDTERCERO, IDFUNCIONARIO,IDRECIBE, FACTORVENTA,'0',IDBODEGAEXTERNA,CNSTRAN,'TRASLADO ENTRE LOTES DE UN ARTICULO.',
					  CNSFCOM,SUBIOCOMPRA,NOPRESTACION,IDAREA,CONTABILIZADA,NROCOMPROBANTE,PROCEDENCIA,
					  USUARIO,USUARIOCONF,FECHACONF,0,IDITAR, CODUNG, CODPRG
			 FROM   IMOV 
			 WHERE  CNSMOV = @CNSMOV
			 PRINT 'INSERTA EL OTRO MOVIMIENTO'
			 INSERT INTO IMOVH (CNSMOV,      IDARTICULO,   EXISTENCIA, CANTIDAD, CANTPEDIDA,   PCOSTO,                      
								  NOLOTE,      NOLOTEPEDIDO, FECHAVENCE, ESTADO,   IDARTICULOTF, CANTIDADTF,                      
								  PCOSTOANTES, CNSTRAN,      ITEM,       PVENTA,   USUARIO,      USUARIOCONF, FECHACONF, PRIEXI)
			 SELECT @CNSITRA, IDARTICULO, EXISTENCIA, CANTIDAD, 0, PCOSTO,
					  NOLOTEPEDIDO, NOLOTE, FECHAVENCE, 0, IDARTICULO, 0,
					  PCOSTOANTES,CNSTRAN,ITEM,PVENTA,USUARIO,USUARIOCONF,FECHACONF,PRIEXI
			 FROM   IMOVH 
			 WHERE  CNSMOV = @CNSMOV 
			 AND ESTADO = 9 
			 AND CANTIDAD > 0
             
			 PRINT 'Actualizando El Lote y y FechaVence del Articulo Trasladado de Lote...'
			 UPDATE IMOVH 
			 SET NOLOTE  = ISAL.NOLOTE,
			 FECHAVENCE  = ISAL.FECHAVENCE
			 FROM   ISAL INNER JOIN IMOVH ON IMOVH.IDARTICULO = ISAL.IDARTICULO  
										   AND ISAL.NOLOTE = IMOVH.NOLOTE
			 WHERE  ISAL.CNSMOV  = @CNSMOV 
			 AND    IMOVH.CNSMOV = @CNSITRA 
		  END
		  ---- TRANSFORMABLE MUCHOS A 1 JEDM:10.NOV.2006 15:25
		  --IF @IDTIPOMOV = @TRANSFMUCHOS1
		  --BEGIN
		  --   PRINT 'MUCHOS A 1'
		  --   SET @CNSITRA = SPACE(20)
		  --   EXEC SPK_GENCONSECUTIVO @COMPANIA,@SEDE,'@MOV',@CNSITRA OUTPUT
		  --   SELECT @CNSITRA = @SEDE + REPLACE(SPACE(8 - LEN(@CNSITRA))+LTRIM(RTRIM(@CNSITRA)),SPACE(1),0)
             
		  --   INSERT INTO IMOV (CNSMOV,         IDBODEGA,      IDTIPOMOV, NODOCUMENTO, TIPODOCU,     FECHAMOV,        CCOSTO,        IDSOLICITA,
		  --                     IDTERCERO,      IDFUNCIONARIO, IDRECIBE,  FACTORVENTA, ESTADO,       IDBODEGAEXTERNA,                    
		  --                     CNSTRAN,        OBSERVACION,   CNSFCOM,   SUBIOCOMPRA, NOPRESTACION, IDAREA,          CONTABILIZADA,                     
		  --                     NROCOMPROBANTE, PROCEDENCIA,   USUARIO,   USUARIOCONF, FECHACONF,    PARCIAL,         IDITAR,        CODUNG, 
		  --                     CODPRG,         F_FACTURA,     F_VENCE)
		  --   SELECT @CNSITRA,IDBODEGA, @TRANSFMUCHOS1E, NODOCUMENTO, TIPODOCU, FECHAMOV, CCOSTO, IDSOLICITA, 
  		   --          IDTERCERO, IDFUNCIONARIO, IDRECIBE, FACTORVENTA,'0',IDBODEGAEXTERNA,CNSTRAN,OBSERVACION,
		  --          CNSFCOM,SUBIOCOMPRA,NOPRESTACION,IDAREA,CONTABILIZADA,NROCOMPROBANTE,PROCEDENCIA,
		  --          USUARIO,USUARIOCONF,FECHACONF,1,IDITAR, CODUNG, CODPRG, DBO.FNK_FECHA_SIN_MLS(GETDATE()),
		  --          DBO.FNK_FECHA_SIN_MLS(GETDATE())
		  --   FROM   IMOV 
		  --   WHERE  CNSMOV = @CNSMOV
                 
		  --   SELECT @IDARTD = IDARTICULODESTINO, @CANTDES = CANTIDADDESTINO
		  --   FROM   IMOV
		  --   WHERE  CNSMOV  = @CNSMOV
            
		  --   INSERT INTO IMOVH (CNSMOV, IDARTICULO, EXISTENCIA, CANTIDAD, CANTPEDIDA, PCOSTO,                      
		  --                      NOLOTE, NOLOTEPEDIDO, FECHAVENCE, ESTADO, IDARTICULOTF, CANTIDADTF,                      
		  --                      PCOSTOANTES, CNSTRAN, ITEM, PVENTA, USUARIO, USUARIOCONF, FECHACONF, PRIEXI)
		  --   SELECT @CNSITRA, @IDARTD, 0, @CANTDES, 0, 0,
		  --          CAST(DAY(GETDATE()) AS VARCHAR(2)) + CAST(MONTH(GETDATE()) AS VARCHAR(2)) + CAST(YEAR(GETDATE()) AS VARCHAR(4)),   
		  --          NULL, NULL, 0, '', 0, 0,
		  --          CNSTRAN,  NULL, 0, USUARIO, NULL, NULL, 0
		  --   FROM   IMOV
		  --   WHERE  CNSMOV = @CNSMOV 
            
		  --END
		  -- Salida de Activos por Traslado 
		  IF @IDINVTRASLACTIVOS = @IDTIPOMOV
		  BEGIN
			 PRINT 'LLamando Procedimiento de Creacion de Activos...'
			 EXEC SPK_INVTRASLADOACTIVOS @CNSMOV, @USUARIO, @COMPANIA, @SEDE
		  END
	   END

	   UPDATE IMOVH 
	   SET ESTADO = 1,
	   ENCXP=0 
	   WHERE CNSMOV=@CNSMOV 
	   AND ESTADO=9
      
      
		/*PARA HOJA DE TRATAMIENTO SE MARCAN LOS ITEMS DE HTX CON LISTOENTREGA  JEDM.31.ENE.2010*/ 
		IF @PROCEDENCIA = 'HTX'
		BEGIN
			PRINT 'ENTRE A PROCESO HTX'

			CREATE TABLE #HDUXS (CNSHDUXS VARCHAR(20) COLLATE DATABASE_DEFAULT)
         
			INSERT INTO #HDUXS (CNSHDUXS)
			SELECT CNSHDUXS FROM HTX 
			WHERE CNSMOV = @CNSMOV  
			AND NOADMISION=@NOADMISION
			AND CNSMOV=@CNSMOV
     
         
			UPDATE HTX SET LISTOENTREGA = 1, ENTREGADO = 1
			FROM   HTX INNER JOIN IMOVH ON HTX.CNSMOV = IMOVH.CNSMOV AND HTX.CNSHTX=IMOVH.NOLOTE
			WHERE  IMOVH.CNSMOV = @CNSMOV 
			AND    HTX.NOADMISION=@NOADMISION
         
			--SELECT * FROM HTX INNER JOIN #HDUXS ON HTX.CNSHDUXS = #HDUXS.CNSHDUXS
         
			UPDATE HTX SET SOLICITADO = 1, LISTOENTREGA = 1, ENTREGADO = 1
			FROM   HTX INNER JOIN #HDUXS ON HTX.CNSHDUXS = #HDUXS.CNSHDUXS
			--WHERE  HTX.CNSHDUXS = @CNSHDUXS

			PRINT 'COLOCANDO EL ARTICULO ENTREGADO ISAL'
			UPDATE HTX SET IDARTICULO=ISAL.IDARTICULO
			FROM HTX INNER JOIN IMOVH ON HTX.CNSMOV=IMOVH.CNSMOV AND HTX.CNSHTX=IMOVH.NOLOTE
					INNER JOIN ISAL  ON IMOVH.CNSMOV=ISAL.CNSMOV AND IMOVH.IDARTICULO=ISAL.IDARTICULO_IMOVH 
			WHERE HTX.CNSMOV=@CNSMOV
			AND   ISAL.CNSMOV=@CNSMOV
         
			DROP TABLE #HDUXS
		END
		IF @PROCEDENCIA = 'HHOM'
		BEGIN
			PRINT 'ENTRE A PROCESO HHOM'
			SELECT @F_VENCEIMOV = F_VENCE FROM IMOV WHERE CNSMOV = @CNSMOV       
			CREATE TABLE #SER (IDSERVICIO VARCHAR(20) COLLATE DATABASE_DEFAULT)
			INSERT INTO #SER (IDSERVICIO)
			SELECT SER.IDSERVICIO 
			FROM   SER INNER JOIN IMOVH ON SER.IDARTICULO = IMOVH.IDARTICULO
			WHERE  IMOVH.CNSMOV = @CNSMOV
			AND    IMOVH.CANTIDAD > 0

			UPDATE HTX SET LISTOENTREGA = 1, ENTREGADO = 1
			WHERE  IDSERVICIO IN (SELECT IDSERVICIO FROM #SER)
			AND    HTX.FECHAREQ <= @F_VENCEIMOV
			AND    HTX.ENTREGADO = 0
			AND    HTX.NOADMISION = @NODOCUMENTO
			PRINT 'SE LLAMA SPK_CARGOS_DESDE_IMOVH'
			EXEC SPK_CARGOS_DESDE_IMOVH @CNSMOV, @USUARIO, @COMPANIA, @SEDE

			DROP TABLE #SER
		END
		IF @PROCEDENCIA = 'SALUD'
		BEGIN
			PRINT 'COLOCANDO EL IDARTICULO ENTREGADO POR FARMACIA....'
			UPDATE HPRED SET IDARTICULO=ISAL.IDARTICULO,NOLOTE=ISAL.NOLOTE
			FROM  HPRED  INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO
						INNER JOIN IMOVH ON IMOVH.IDARTICULO=SER.IDARTICULO
						INNER JOIN ISAL  ON IMOVH.CNSMOV=ISAL.CNSMOV AND IMOVH.IDARTICULO=ISAL.IDARTICULO_IMOVH
			WHERE ISAL.CNSMOV=@CNSMOV
			AND   IMOVH.CNSMOV=@CNSMOV
			AND   HPRED.NOPRESTACION=@NOPRESTACION
		END
		IF @PROCEDENCIA = 'QXCX'
		BEGIN
			PRINT 'COLOCO EL LOTE QUE SE ENTREGO'
			IF EXISTS(SELECT * FROM QXPCXI WHERE CNSMOV=@CNSMOV AND NOADMISION=@NOADMISION)
			BEGIN
				UPDATE QXPCXI SET NOLOTE=ISAL.NOLOTE,IDARTISAL=ISAL.IDARTICULO
				FROM QXPCXI INNER JOIN IMOV ON QXPCXI.CNSMOV=IMOV.CNSMOV AND QXPCXI.NOADMISION=IMOV.NODOCUMENTO
							INNER JOIN IMOVH ON IMOV.CNSMOV=IMOVH.CNSMOV AND QXPCXI.ARTICULO=IMOVH.IDARTICULO
							INNER JOIN ISAL  ON IMOVH.CNSMOV=ISAL.CNSMOV AND IMOVH.IDARTICULO=ISAL.IDARTICULO_IMOVH
				WHERE IMOV.CNSMOV=@CNSMOV
				AND   QXPCXI.CNSMOV=@CNSMOV
				AND   IMOVH.CNSMOV=@CNSMOV
				AND   ISAL.CNSMOV=@CNSMOV
				AND   QXPCXI.NOADMISION=@NOADMISION
			END
		END
		IF @PROCEDENCIA = 'QXPGCX' AND @PEDIDOHPREAIZSOL <>'SI'
		BEGIN
			UPDATE CXPSI SET CANTIDADREAL=IMOVH.CANTIDAD
			FROM   CXPSI INNER JOIN IMOVH ON CXPSI.CNSMOV=IMOVH.CNSMOV AND CXPSI.IDSERVICIO=IMOVH.IDARTICULO
			WHERE  IMOVH.CNSMOV=@CNSMOV AND IMOVH.ESTADO=1
		END
	   --END
	   --ELSE
	   --BEGIN 
	   --   PRINT 'NO HAY NINGUNA EXISTENCIA' 
	   --   RETURN
	   --END 
	   --- ACTUALIZO PCOSTOS ANTES DE ENVIAR CONTABILIDAD

		UPDATE IMOVH SET PCOSTO=ISAL.PCOSTO
		FROM IMOVH INNER JOIN ISAL ON IMOVH.IDARTICULO=ISAL.IDARTICULO_IMOVH AND IMOVH.CNSMOV=ISAL.CNSMOV AND IMOVH.NOLOTE=ISAL.NOLOTE
		WHERE IMOVH.CNSMOV=@CNSMOV
   
		/*JEDM_2011_AGO_04: BUSCAR POSIBLE EXCEPCION CONTABLE*/
		SELECT @EXCEPCION_CON =  COALESCE(COUNT(*),0) 
		FROM   IEXCEP 
		WHERE  CLASE     = 'Contabilizacion' 
		AND    IDBODEGA  = @IDBODEGA 
		AND    IDTIPOMOV = @IDTIPOMOV
   
		---- AFWILLIAMS 24/07/2012
		---- AQUI SE ACTUALIZARA EL KARDEX
		PRINT 'ACTUALIZA KARDEX'
		EXEC SPK_ACTUALIZA_KARDEX @CNSMOV
   
 --   END TRY

	----SI HAY ALGUN ERROR EN EL PROCESO SE ECHA PARA ATRAS TODO EL PROCESO
	--BEGIN CATCH
	--	ROLLBACK TRANSACTION
	--	DECLARE @ERROR_MESSAGE AS VARCHAR(512)=LEFT(ERROR_MESSAGE(),510)
	--	RAISERROR(@ERROR_MESSAGE, 16,1)
	--	RETURN
	--END CATCH
	----DE NO HABER ERROR HACE COMIT Y CONTINUA
	--COMMIT

   PRINT 'Actualizo el tipo de articulo del movimiento'
   
   DECLARE @IDITARM VARCHAR(2)

   SELECT @IDITARM = MIN(IART.IDITAR) 
   FROM ISAL INNER JOIN IART ON ISAL.IDARTICULO=IART.IDARTICULO
   WHERE ISAL.CNSMOV=@CNSMOV 

   UPDATE IMOV SET IDITAR = @IDITARM
   FROM IMOV INNER JOIN ISAL ON IMOV.CNSMOV=ISAL.CNSMOV
             INNER JOIN IART ON ISAL.IDARTICULO=IART.IDARTICULO
   WHERE IMOV.CNSMOV=@CNSMOV

   IF DBO.FNK_VALORVARIABLE('IXCOUNTRY')='PERU'
   BEGIN
      UPDATE ISAL SET PCOSTO=IDXB.PCOSTOM
      FROM ISAL INNER JOIN IMOV ON ISAL.CNSMOV=IMOV.CNSMOV
                INNER JOIN IDXB ON ISAL.IDARTICULO=IDXB.IDARTICULO AND IMOV.IDBODEGA=IDXB.IDBODEGA
      WHERE IMOV.CNSMOV=@CNSMOV

	  IF DBO.FNK_VALORVARIABLE('INTERFAZ_INV')='INTER_SAP'
	  BEGIN
		  EXEC SPK_XML_MOVIN @CNSMOV
	  END 
   END

	---JQUIROGA 20090327 - con AARROYO --OH---
	PRINT'ENVIO AUTOMATICO DEL MOVIMIENTO DE INVENTARIO A CONTABILIDAD' 
	IF  @SECONTABILIZA = 1 -- JEDM_2011_AGO_04 SOLO ENVIAR A CONTABILIDAD LO QUE SE CONTABILIZA
		AND @EXCEPCION_CON = 0 -- JEDM_2011_AGO_04: BUSCAR POSIBLE EXCEPCION CONTABLE
	BEGIN   
		--UPDATE IMOV SET MARCACONT=1 WHERE CNSMOV=@CNSMOV
		SELECT @ANO = YEAR(FECHACONF) FROM IMOV WHERE CNSMOV = @CNSMOV
		SELECT @MES = MONTH(FECHACONF) FROM IMOV WHERE CNSMOV = @CNSMOV
        IF DBO.FNK_VALORVARIABLE('CONTABIMOV_JOB')='SI'
	    BEGIN
		    INSERT INTO IMOVC(CNSMOV, USUARIO, SYS_COMPUTERNAME, COMPANIA, SEDE, NROCOMPROBANTE)
		    SELECT @CNSMOV,@USUARIO,@SYS_COMPUTERNAME,'01',@SEDE,''  
	    END
	    ELSE
	    BEGIN
		    PRINT 'ENVIO A CONTABILIDAD'
		    EXEC SPK_NC_CONTAB_INV @CNSMOV,@USUARIO,@SYS_COMPUTERNAME,@COMPANIA,@SEDE, ''
		    PRINT 'REGRESO DE CONTABILIDAD'
	    END
	END
	IF DBO.FNK_VALORVARIABLE('INTERFAZ_INV')='KCOCUT' AND DBO.FNK_VALORVARIABLE('IDTIPOMOV_INTER_ENT')=IDTIPOMOV
	BEGIN
		EXEC SPK_ENVIA_INTERFAX_INV @CNSMOV
	END 
END

