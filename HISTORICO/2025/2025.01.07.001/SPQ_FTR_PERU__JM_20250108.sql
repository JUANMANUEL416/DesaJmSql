CREATE OR ALTER PROCEDURE DBO.SPQ_FTR_PERU @JSON NVARCHAR(MAX)
	WITH ENCRYPTION
AS
SET DATEFORMAT dmy
DECLARE @TBLERRORES TABLE (ERROR VARCHAR(MAX))
DECLARE  @PARAMETROS NVARCHAR(MAX)			,@MODELO VARCHAR(100)			 ,@METODO VARCHAR(100)
		,@USUARIO VARCHAR(12)				,@COMPANIA VARCHAR(2)			 ,@IDSEDE      VARCHAR(5)		
        ,@SYS_COMPUTERNAME VARCHAR(200)     ,@DATOS    VARCHAR(MAX)
        ,@CONSECUTIVO VARCHAR(20)           ,@DPR VARCHAR(20)                ,@TIPOFAC VARCHAR(10)
        ,@FECHAFACT DATETIME                ,@IDTERCERO VARCHAR(20)          ,@N_FACTURA VARCHAR(20)
        ,@IDAUT VARCHAR(20)                 ,@PREFIJO VARCHAR(6)             ,@IDTERCEROCA VARCHAR(20)
        ,@IDPLAN VARCHAR(2)                 ,@GENERADO SMALLINT              ,@IDSERPAQ   VARCHAR(20)
        ,@VLRTOTALPAQ DECIMAL(14,2)         ,@CANTIPAQ SMALLINT              ,@PROCESO VARCHAR(20)

BEGIN
	SELECT *
	INTO #JSON
	FROM OPENJSON(@json) WITH (
			MODELO VARCHAR(100) '$.MODELO'
			,METODO VARCHAR(100) '$.METODO'
			,USUARIO VARCHAR(12) '$.USUARIO'
			,PARAMETROS NVARCHAR(MAX) AS JSON
	)

	SELECT   @MODELO = MODELO			,@METODO = METODO
			,@PARAMETROS = PARAMETROS	,@USUARIO = USUARIO
	FROM #JSON
   IF @METODO='FACTURAR_CITAUT'     
   BEGIN         
      SELECT @CONSECUTIVO=CONSECUTIVO        
      FROM   OPENJSON (@PARAMETROS)
      WITH (           
      CONSECUTIVO  VARCHAR(20)   '$.CONSECUTIVO'
      )
      SELECT @DPR=DBO.FNK_VALORVARIABLE('IDTERCEROINSTALADO'),@COMPANIA='01',@IDSEDE=COALESCE(UBEQ.IDSEDE,USUSU.IDSEDE)
      FROM USUSU LEFT JOIN UBEQ ON USUSU.SYS_COMPUTERNAME=UBEQ.SYS_COMPUTERNAME
      WHERE USUARIO=@USUARIO
      SELECT @TIPOFAC='Factura',@FECHAFACT=DBO.FNK_GETDATE()
      IF NOT EXISTS(SELECT * FROM CIT WHERE COALESCE(FACTURADA,0)=1 AND COALESCE(N_FACTURA,'')='' AND COALESCE(VALORTOTAL,0)-COALESCE(VALORCOPAGO,0)>0) 
      BEGIN
         BEGIN TRY           
            EXEC SPK_FACTURACE_PERU_CITAUT @CONSECUTIVO,@DPR,@COMPANIA,@IDSEDE, @USUARIO,'','','','','','CI','', 'FALSE', NULL,@FECHAFACT,@TIPOFAC, @IDTERCERO                 
         END TRY
         BEGIN CATCH
                 INSERT INTO @TBLERRORES(ERROR) SELECT ERROR_MESSAGE()
         END CATCH
      END
      ELSE
      BEGIN
         INSERT INTO @TBLERRORES(ERROR)
         SELECT 'Cita ya Facturada o con Valores en Cero(0), Verifique e intente de nuevo'
      END
      IF(SELECT COUNT(*) FROM @TBLERRORES)>0
      BEGIN
         SELECT 'KO' OK, ERROR FROM @TBLERRORES
         RETURN
      END
      SELECT @N_FACTURA=N_FACTURA FROM CIT WHERE CONSECUTIVO=@CONSECUTIVO
      SELECT 'OK' OK,@N_FACTURA N_FACTURA
      RETURN 
   END
   IF @METODO='FACTURAR_CITPAQ'     
   BEGIN  
      SELECT @DATOS=DATOS        
      FROM   OPENJSON (@PARAMETROS)
      WITH (           
      DATOS NVARCHAR(MAX) AS JSON 
      )
      SELECT @CONSECUTIVO=CONSECUTIVO, @IDSERPAQ=IDSERPAQ,@VLRTOTALPAQ=VLRTOTALPAQ,@CANTIPAQ=CANTIPAQ    
      FROM   OPENJSON (@DATOS)
      WITH (           
      CONSECUTIVO  VARCHAR(20)   '$.CONSECUTIVO',
      IDSERPAQ  VARCHAR(20)   '$.IDSERPAQ',
      VLRTOTALPAQ  VARCHAR(20)   '$.VLRTOTALPAQ',
      CANTIPAQ  VARCHAR(20)   '$.CANTIPAQ'
      )
      PRINT '@CONSECUTIVO='+@CONSECUTIVO
      SELECT @DPR=DBO.FNK_VALORVARIABLE('IDTERCEROINSTALADO'),@COMPANIA='01',@IDSEDE=COALESCE(UBEQ.IDSEDE,USUSU.IDSEDE)
      FROM USUSU LEFT JOIN UBEQ ON USUSU.SYS_COMPUTERNAME=UBEQ.SYS_COMPUTERNAME
      WHERE USUARIO=@USUARIO
      SELECT @TIPOFAC='Factura',@FECHAFACT=DBO.FNK_GETDATE()
      IF NOT EXISTS(SELECT * FROM CIT WHERE COALESCE(FACTURADA,0)=1 AND COALESCE(N_FACTURA,'')='') 
      BEGIN
         BEGIN TRY           
            EXEC SPK_FACTURACE_PERU_CITAUT_PAQ @CONSECUTIVO,@DPR,@COMPANIA,@IDSEDE, @USUARIO,@IDSERPAQ,@VLRTOTALPAQ,@CANTIPAQ,@FECHAFACT,@TIPOFAC, @IDTERCERO                 
         END TRY
         BEGIN CATCH
                 INSERT INTO @TBLERRORES(ERROR) SELECT ERROR_MESSAGE()
         END CATCH
      END
      ELSE
      BEGIN
         INSERT INTO @TBLERRORES(ERROR)
         SELECT 'Cita ya Facturada o con Valores en Cero(0), Verifique e intente de nuevo'
      END
      IF(SELECT COUNT(*) FROM @TBLERRORES)>0
      BEGIN
         SELECT 'KO' OK, ERROR FROM @TBLERRORES
         RETURN
      END
      SELECT @N_FACTURA=N_FACTURA FROM CIT WHERE CONSECUTIVO=@CONSECUTIVO
      SELECT 'OK' OK,@N_FACTURA N_FACTURA
      RETURN 
   END
   IF @METODO='NOTIFICA_BOLETAS'     
   OR @METODO='NOTIFICA_BOLETAS_DEBUG'     
   BEGIN 
      SELECT @PROCESO=PROCESO        
      FROM   OPENJSON (@PARAMETROS)
      WITH (           
      PROCESO VARCHAR(20) '$.PROCESO'
      )
     IF DBO.FNK_VALORVARIABLE('BDATA_PRODUCCION')<>DB_NAME()
     BEGIN
         PRINT 'Modo Test No permite el envio de Documentos'
         SELECT 'OK' OK  
         RETURN
     END
     IF  EXISTS(SELECT *
         FROM FTR INNER JOIN FTRE ON FTR.N_FACTURA=FTRE.FTRN_FACTURA
         WHERE FTRE.NOTIFICADO=0
         AND FTR.TIPOFIN='N'
         AND COALESCE(MARCA,0)=1
         AND COALESCE(EQUIMARCA,'')<>''
         AND FTR.FECHA_PP IS NOT NULL
         AND DATEDIFF(MINUTE,FTR.FECHA_PP,DBO.FNK_GETDATE())>10)
      BEGIN
         PRINT 'Si encontre alguna marcada'
         UPDATE FTR SET EQUIMARCA=NULL,MARCA=0,FECHA_PP=NULL
         FROM FTR INNER JOIN FTRE ON FTR.N_FACTURA=FTRE.FTRN_FACTURA
         WHERE FTRE.NOTIFICADO=0
         AND FTR.TIPOFIN='N'
         AND COALESCE(MARCA,0)=1
         AND COALESCE(EQUIMARCA,'')<>''
         AND FTR.FECHA_PP IS NOT NULL
         AND DATEDIFF(MINUTE,FTR.FECHA_PP,DBO.FNK_GETDATE())>10
      END

      PRINT 'VOY AL UPDATE'
      UPDATE FTR SET EQUIMARCA=@USUARIO,MARCA=1,FECHA_PP=DBO.FNK_GETDATE()
      FROM FTR INNER JOIN FTRE ON FTR.N_FACTURA=FTRE.FTRN_FACTURA
                  INNER JOIN TER  ON FTR.IDTERCERO=TER.IDTERCERO
                  LEFT  JOIN AFI  ON FTR.IDAFILIADO=AFI.IDAFILIADO
         WHERE FTRE.NOTIFICADO=0
         AND FTR.TIPOFIN='N'
         AND COALESCE(MARCA,0)=0
         AND COALESCE(EQUIMARCA,'')=''

      SELECT 'OK' OK 
	  
     IF @PROCESO='FRONTEND'
     BEGIN
	     SELECT FTR.N_FACTURA,CONVERT(VARCHAR,F_FACTURA,103)F_FACTURA,FTR.VALORSERVICIOS,VIVA,VR_TOTAL,COALESCE(AFI.EMAIL,TER.EMAIL)CORREO,AFI.DOCIDAFILIADO,AFI.NOMBREAFI
         FROM FTR INNER JOIN FTRE ON FTR.N_FACTURA=FTRE.FTRN_FACTURA
                  INNER JOIN TER  ON FTR.IDTERCERO=TER.IDTERCERO
                  LEFT  JOIN AFI  ON FTR.IDAFILIADO=AFI.IDAFILIADO
         WHERE FTRE.NOTIFICADO=0
         AND FTR.TIPOFIN='N'
         AND COALESCE(MARCA,0)=1
         AND COALESCE(EQUIMARCA,'')=@USUARIO
     END
     ELSE
     BEGIN 
	     SELECT TOP 1 FTR.N_FACTURA,CONVERT(VARCHAR,F_FACTURA,103)F_FACTURA,FTR.VALORSERVICIOS,VIVA,VR_TOTAL,COALESCE(AFI.EMAIL,TER.EMAIL)CORREO,AFI.DOCIDAFILIADO,AFI.NOMBREAFI
         FROM FTR INNER JOIN FTRE ON FTR.N_FACTURA=FTRE.FTRN_FACTURA
                  INNER JOIN TER  ON FTR.IDTERCERO=TER.IDTERCERO
                  LEFT  JOIN AFI  ON FTR.IDAFILIADO=AFI.IDAFILIADO
         WHERE FTRE.NOTIFICADO=0
         AND FTR.TIPOFIN='N'
         AND COALESCE(MARCA,0)=1
         AND COALESCE(EQUIMARCA,'')=@USUARIO
       --AND 1=IIF(@METODO='NOTIFICA_BOLETAS_DEBUG', 1, 2)
     END


      RETURN
   END 
   IF @METODO='MARCA_ENVIO'     
   BEGIN         
      SELECT @N_FACTURA=N_FACTURA        
      FROM   OPENJSON (@PARAMETROS)
      WITH (           
      N_FACTURA  VARCHAR(20)   '$.N_FACTURA' 
      )
      IF EXISTS(SELECT * FROM FTRE WHERE FTRN_FACTURA=@N_FACTURA)
      BEGIN
         UPDATE FTRE SET NOTIFICADO=1,FECHA_NOTIFICADO=DBO.FNK_GETDATE() WHERE FTRN_FACTURA=@N_FACTURA
         UPDATE FTR SET MARCA=0,EQUIMARCA=NULL,FECHA_PP=NULL   WHERE N_FACTURA=@N_FACTURA
      END
      SELECT 'OK'OK
      RETURN
   END  
   IF @METODO='SOPORTES_FTREPE'     
   BEGIN         
      SELECT @N_FACTURA=N_FACTURA        
      FROM   OPENJSON (@PARAMETROS)
      WITH (           
       N_FACTURA  VARCHAR(20)   '$.N_FACTURA'
      )

      DECLARE @PROCEDENCIA VARCHAR(20)
      DECLARE @NOREFERENCIA VARCHAR(20)
      DECLARE @IDAFILIADO VARCHAR(20)
      DECLARE @CONSECUTIVOHCA VARCHAR(20)
      DECLARE @OBSERVACION1 VARCHAR(20)
      DECLARE @RUC VARCHAR(20)
      
      SELECT @PROCEDENCIA=PROCEDENCIA,@NOREFERENCIA=NOREFERENCIA,@IDAFILIADO=IDAFILIADO,@OBSERVACION1=LTRIM(RTRIM(COALESCE(OBSERVACION1,'')))
      FROM FTR WHERE N_FACTURA=@N_FACTURA
      PRINT @PROCEDENCIA

      IF @PROCEDENCIA='CI'
      BEGIN
         PRINT '@NOREFERENCIA='+COALESCE(@NOREFERENCIA,'SI REFERENCIA')+' @IDAFILIADO='+COALESCE(@IDAFILIADO,'SIN AFILIADO')
         IF @OBSERVACION1='CITAUT'
         BEGIN
            SELECT @CONSECUTIVOHCA=CONSECUTIVO FROM HCA WHERE CONSECUTIVOCIT=@NOREFERENCIA AND IDAFILIADO=@IDAFILIADO
         END
         ELSE
         BEGIN
            SELECT @CONSECUTIVOHCA=CONSECUTIVO FROM HCA WHERE CONSECUTIVOCIT=@NOREFERENCIA AND IDAFILIADO=@IDAFILIADO
         END
      END
      IF @PROCEDENCIA='CE'
      BEGIN
         SELECT @CONSECUTIVOHCA=CONSECUTIVOHCA FROM AUT WHERE IDAUT=@NOREFERENCIA
      END

      SELECT @RUC=NIT
      FROM TER WHERE IDTERCERO=DBO.FNK_VALORVARIABLE('IDTERCEROINSTALADO')

      SELECT 'OK'OK
      SELECT @CONSECUTIVOHCA CONSECUTIVO,@IDAFILIADO IDAFILIADO,@RUC RUC 
      RETURN
   
   END  
   IF @METODO='LISTOS_FACTURA'     
   BEGIN        

      SELECT @CONSECUTIVO = CONSECUTIVO    
      FROM   OPENJSON (@PARAMETROS)
      WITH (           
      CONSECUTIVO  VARCHAR(20)   '$.CONSECUTIVO'
      )
      DECLARE LISAUT_CURSOR CURSOR FOR 
      SELECT IDAUT,PREFIJO,IDTERCEROCA,IDPLAN,COALESCE(GENERADO,0)  FROM AUT 
      WHERE CONSECUTIVOCIT=CASE WHEN COALESCE(@CONSECUTIVO,'')<> '' THEN @CONSECUTIVO ELSE CONSECUTIVOCIT END
      AND COALESCE(FACTURADA,0)=0
      AND COALESCE(LISTOFACT,'PEND')='PEND'
      ORDER BY IDAUT
      OPEN LISAUT_CURSOR    
      FETCH NEXT FROM LISAUT_CURSOR    
      INTO @IDAUT,@PREFIJO,@IDTERCEROCA,@IDPLAN,@GENERADO
      WHILE @@FETCH_STATUS = 0    
      BEGIN 
         IF @PREFIJO=DBO.FNK_VALORVARIABLE('PREFIJOMEDICAMENTOS')
         BEGIN
            -- MEDICAMENTOS
            PRINT 'VALIDO SI EL SISTEMA ENTREGA MEDICAMENTOS '
            IF NOT EXISTS(SELECT * FROM PPT WHERE IDTERCERO=@IDTERCEROCA AND IDPLAN=@IDPLAN AND COALESCE(MEFARMACIA,0)=1)
            BEGIN
               PRINT 'CONVENIO NO ENTREGA MEDICAMENTOS'
               UPDATE AUT SET LISTOFACT='NOFACT' WHERE IDAUT=@IDAUT
            END
            ELSE
            BEGIN
               IF NOT EXISTS(SELECT * FROM IZSOL INNER JOIN IMOV ON IZSOL.CNSIZSOL=IMOV.NODOCUMENTO AND IMOV.PROCEDENCIA='CM_SOL'
                              WHERE IZSOL.NOADMISION=@IDAUT AND IZSOL.CLASE='CE'
                              AND IZSOL.ESTADO=1
                              AND IMOV.ESTADO=1)
               BEGIN
                  UPDATE AUT SET LISTOFACT='PEND' WHERE IDAUT=@IDAUT
               END
               ELSE
               BEGIN
                  UPDATE AUT SET LISTOFACT='OK' WHERE IDAUT=@IDAUT
                  UPDATE AUTD SET VALOREXCEDENTE=(VALOR*CANTIDAD)-COALESCE(VALORCOPAGO,0)
                  WHERE IDAUT=@IDAUT
                  AND COALESCE(AUTD.NOCOBRABLE,0)=0
                  AND COALESCE(AUTD.GENERADO,0)=1
                  AND COALESCE(AUTD.FACTURADA,0)=0
               END
            END
         END
         IF @PREFIJO=DBO.FNK_VALORVARIABLE('PREFIJOLABORATORIO') OR @PREFIJO=DBO.FNK_VALORVARIABLE('PREFIJOAPOYODX')
         BEGIN
            PRINT 'AYUDAS DIAGNOSTICAS'
            IF COALESCE(@GENERADO,0)=0
            BEGIN
               FETCH NEXT FROM LISAUT_CURSOR    
               INTO @IDAUT,@PREFIJO,@IDTERCEROCA,@IDPLAN,@GENERADO
               CONTINUE
            END
            IF EXISTS(SELECT * FROM LING INNER JOIN LORD ON LING.NOINGRESO=LORD.NOINGRESO
                                          INNER JOIN AUTD ON LING.NOPRESTACION=AUTD.IDAUT AND AUTD.IDSERVICIO=LORD.IDSERVICIO
                        WHERE COALESCE(AUTD.NOCOBRABLE,0)=0
                        AND LING.NOPRESTACION=@IDAUT
                        AND LORD.ESTADO='I')
            BEGIN
               UPDATE AUT SET LISTOFACT='PEND' WHERE IDAUT=@IDAUT
            END
            ELSE
            BEGIN
               UPDATE AUT SET LISTOFACT='OK' WHERE IDAUT=@IDAUT
               UPDATE AUTD SET VALOREXCEDENTE=(VALOR*CANTIDAD)-COALESCE(VALORCOPAGO,0)
               WHERE IDAUT=@IDAUT
               AND COALESCE(AUTD.NOCOBRABLE,0)=0
               AND COALESCE(AUTD.GENERADO,0)=1
               AND COALESCE(AUTD.FACTURADA,0)=0
            END
         END
         IF @PREFIJO=DBO.FNK_VALORVARIABLE('PREFIJOCONSULTA')
         BEGIN
            UPDATE AUT SET LISTOFACT='NOFACT' WHERE IDAUT=@IDAUT 
         END
         FETCH NEXT FROM LISAUT_CURSOR    
         INTO @IDAUT,@PREFIJO,@IDTERCEROCA,@IDPLAN,@GENERADO
      END
      CLOSE LISAUT_CURSOR
      DEALLOCATE LISAUT_CURSOR

      SELECT 'OK'OK
      RETURN
   END  
   IF @METODO='SOPORTES_HCATD'     
   BEGIN         
      SELECT @CONSECUTIVO=CONSECUTIVO        
      FROM   OPENJSON (@PARAMETROS)
      WITH (           
            CONSECUTIVO  VARCHAR(20)   '$.CONSECUTIVO'
      )
      
         SELECT 'OK'OK, ( SELECT DISTINCT HCATD.CODOM
					,                                HCCOM.DESCRIPCION
					FROM HCA INNER JOIN HCATD ON HCA.CONSECUTIVO=HCATD.CONSECUTIVO
					INNER JOIN HCCOM ON HCCOM.CODOM = HCATD.CODOM
					WHERE HCATD.CONSECUTIVO =@CONSECUTIVO FOR JSON PATH) AS HCATD

      RETURN                 
   END  
   IF @METODO='SOPORTES_APDX_DOCS'     
   BEGIN         
      SELECT @N_FACTURA=N_FACTURA       
      FROM   OPENJSON (@PARAMETROS)
      WITH (           
            N_FACTURA  VARCHAR(20)   '$.N_FACTURA'
      )
      
      SELECT 'OK'OK, DOCS.DocNombre,DocExtension,DOCS.DocFS AS ARCHIVO
      FROM AUTD INNER JOIN LING ON AUTD.IDAUT=LING.NOPRESTACION AND LING.TIPOINGRESO='C'
                INNER JOIN LORD ON LING.NOINGRESO=LORD.NOINGRESO AND AUTD.IDSERVICIO=LORD.IDSERVICIO
                INNER JOIN DOCXTPO ON LORD.NORDEN=DOCXTPO.NODOCUMENTO AND TIPO='LORD'
                INNER JOIN DOCS ON DOCXTPO.DOCUMENTOID=DOCS.DocumentoID
      WHERE   @N_FACTURA IN(AUTD.N_FACTURA,AUTD.NFACTURA)

      RETURN                 
   END 
END


