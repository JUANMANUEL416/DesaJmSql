CREATE OR ALTER PROCEDURE DBO.SPQ_APAG_COL @JSON NVARCHAR(MAX)
	WITH ENCRYPTION
AS
SET DATEFORMAT dmy
SET LANGUAGE spanish; 
DECLARE @TBLERRORES TABLE (ERROR VARCHAR(MAX))
DECLARE  @PARAMETROS NVARCHAR(MAX)			,@MODELO VARCHAR(100)			   ,@METODO VARCHAR(100)
		,@USUARIO VARCHAR(12)				   ,@COMPANIA VARCHAR(2)		      ,@IDSEDE      VARCHAR(5)		
      ,@SYS_COMPUTERNAME VARCHAR(200)     ,@DATOS    VARCHAR(MAX)
      ,@PROCESO VARCHAR(20)               ,@FECHA DATE                     ,@VALOR_NUM DECIMAL(14,2)   
      ,@IDTERCERO VARCHAR(20)             ,@NIT DECIMAL(14,2)              ,@RAZONSOCIAL VARCHAR(27)   
      ,@F_VENCE DATETIME               ,@AUTORIZADOR VARCHAR(20)      ,@NOMBREAUT VARCHAR(29)
     ,@NOADMISION VARCHAR(20)             ,@OBSERVACION VARCHAR(200)        ,@IDPAGARE  VARCHAR(20)
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
   IF @METODO='CRUB_APAG'     
   BEGIN         
      SELECT @DATOS=DATOS        
      FROM   OPENJSON (@PARAMETROS)
      WITH (           
         DATOS NVARCHAR(MAX) AS JSON 
            )           
      
         SELECT  @PROCESO=PROCESO,@IDPAGARE=COALESCE(IDPAGARE,''), @FECHA=FECHA, @VALOR_NUM=VALOR_NUM,@IDTERCERO=IDTERCERO, @F_VENCE=F_VENCE, 
         @AUTORIZADOR=AUTORIZADOR, @NOADMISION=NOADMISION,  @OBSERVACION=OBSERVACION  
         FROM   OPENJSON (@DATOS)
         WITH( 
               PROCESO VARCHAR(20)          '$.PROCESO',
               FECHA DATE                    '$.FECHA',
               IDPAGARE VARCHAR(20)           '$.IDPAGARE',
               VALOR_NUM DECIMAL(14,2)        '$.VALOR_NUM',
               IDTERCERO VARCHAR(20)          '$.IDTERCERO',
               F_VENCE DATE                   '$.F_VENCE',
               AUTORIZADOR VARCHAR(20)      '$.AUTORIZADOR',
               NOADMISION VARCHAR(20)          '$.NOADMISION',
               OBSERVACION VARCHAR(200)          '$.OBSERVACION'         
          )    
         IF @PROCESO='Nuevo'
         BEGIN
         SELECT @IDSEDE= COALESCE(UBEQ.IDSEDE,USUSU.IDSEDE),@COMPANIA=UBEQ.COMPANIA,
         @SYS_COMPUTERNAME=COALESCE(USUSU.SYS_COMPUTERNAME,HOST_NAME())
         FROM USUSU LEFT JOIN UBEQ ON USUSU.SYS_ComputerName=UBEQ.SYS_ComputerName
         WHERE USUARIO=@USUARIO

         BEGIN TRY
            PRINT 'AQUI LLAMO A GENCONSECUTIVO @IDSEDE='+COALESCE(@IDSEDE,'SIN SEDE')+'--'+COALESCE(@COMPANIA,'CIA') 
            SELECT @IDPAGARE=''
		      EXEC SPK_GENCONSECUTIVO @COMPANIA,@IDSEDE, '@APAG', @IDPAGARE OUTPUT  
            PRINT '@CNSCXC='+COALESCE(@IDPAGARE,'')   
		      SELECT @IDPAGARE = @IDSEDE + REPLACE(SPACE(8 - LEN(@IDPAGARE))+LTRIM(RTRIM(@IDPAGARE)),SPACE(1),0)
		      PRINT '@CNSCXC='+COALESCE(@IDPAGARE,'')                    
         END TRY
         BEGIN CATCH
            INSERT INTO @TBLERRORES(ERROR) SELECT ERROR_MESSAGE()
            SELECT ERROR AS ERROR FROM  @TBLERRORES 
            RETURN
         END CATCH
            
         BEGIN TRY 
               PRINT 'VOY A INSERTAR '
               INSERT INTO APAG (IDPAGARE ,IDTERCERO ,FECHA ,VALOR_NUM ,FECHAVENCE ,FORMA_PAGO ,CONFIRMACION ,DESCRIPCION ,NOADMISION ,USUARIO ,
               SYS_COMPUTERNAME ,AUTORIZDOR ,ESTADO ,CODCAJA ,CNSFACJ )   
               SELECT @IDPAGARE,@IDTERCERO,DBO.FNK_GETDATE(),@VALOR_NUM,@F_VENCE,NULL,NULL,@OBSERVACION,@NOADMISION,@USUARIO,
               @SYS_COMPUTERNAME,@AUTORIZADOR,'Nuevo',NULL,NULL                                  
         END TRY
         BEGIN CATCH
               INSERT INTO @TBLERRORES(ERROR) SELECT ERROR_MESSAGE()
               SELECT ERROR AS ERROR FROM  @TBLERRORES 
               RETURN
         END CATCH

         SELECT 'OK'OK 
         RETURN

      END
      IF @PROCESO='Editar'
      BEGIN
         IF EXISTS(SELECT * FROM APAG WHERE IDPAGARE=@IDPAGARE AND NOADMISION=@NOADMISION AND ESTADO='Nuevo')
         BEGIN
            UPDATE APAG SET AUTORIZDOR=@AUTORIZADOR,FECHAVENCE=@F_VENCE,IDTERCERO=@IDTERCERO,VALOR_NUM=@VALOR_NUM,DESCRIPCION=@OBSERVACION
            WHERE IDPAGARE=@IDPAGARE
            AND NOADMISION=@NOADMISION
            SELECT 'OK' OK
            RETURN 
         END
         ELSE
         BEGIN
            SELECT 'KO'KO,'No se Encontro pagaré Para Actualizar, Verifique e Intente de nuevo'ERROR
            RETURN
         END
      END
   END   
   IF @METODO='IMPRIME_APAG'     
   BEGIN         
      SELECT @IDPAGARE=IDPAGARE        
      FROM   OPENJSON (@PARAMETROS)
      WITH (           
         IDPAGARE VARCHAR(20) '$.IDPAGARE' 
            )           
       IF EXISTS(SELECT  * FROM APAG WHERE IDPAGARE=@IDPAGARE)     
       BEGIN
          SELECT 'OK'OK
          SELECT  TER1.RAZONSOCIAL AS NCLINICA,TER1.DV,CIU.NOMBRE, IDPAGARE,APAG.IDTERCERO,TER.TIPO_ID,TER.NIT,TER.RAZONSOCIAL,CONVERT(VARCHAR,APAG.FECHA,103)FECHA,VALOR_NUM,
                  CONVERT(VARCHAR,APAG.FECHAVENCE,103)F_VENCE,CONVERT(VARCHAR,GETDATE(),103)+' '+CONVERT(VARCHAR,GETDATE(),108)F_IMPRESION,
                  LTRIM(RTRIM(TRIM(DBO.FNK_DE_VALORES_A_LETRAS(APAG.VALOR_NUM))))+' PESOS M/CTE. ' LETRAS,
                  FECHAF='En constancia de los anterior, se suscribe este documento El dia '+CAST(DAY(APAG.FECHA) AS VARCHAR(2))+' del mes de '+UPPER(DATENAME(MONTH,APAG.FECHA))+' del año '+CAST(YEAR(APAG.FECHA) AS VARCHAR(4)),
                  OBSERVACION='Observaciones: '+APAG.DESCRIPCION,
                  AUTORIZADO='Autorizado por: '+APAG.AUTORIZDOR+'  '+USUSU.NOMBRE,
                  CUERPO=REPLACE(REPLACE(REPLACE('Declaro PRIMERO que me obligo a pagar solidariamente e incondicionalmente a la orden de '+TER1.RAZONSOCIAL+' 
                                 de la Salud, entidad sin animo de lucro, identificada con NIT '+TER1.NIT+'-'+TER1.DV+' o a quien represente sus derechos 
                                 la suma de '+LTRIM(RTRIM(TRIM(DBO.FNK_DE_VALORES_A_LETRAS(APAG.VALOR_NUM))))+' PESOS M/CTE.($  '+CAST(VALOR_NUM AS VARCHAR(20))+') 
                                 mas los intereses durante el plazo. SEGUNDA  En caso de mora y mientras ella subsista, pagaremos intereses  moratorios a la tasa del 
                                 máxima legal autorizada según  las normas comerciales. TERCERA:  De igual manera por medio del presente documento autorizamos de 
                                 manera especial, expresa e irrevocable al acreedor, para que contrate  la gestión de cobranza que se haga necesaria en el evento de 
                                 mora en el cumplimiento de  mi obligación y por lo mismo, me obligo a pagar todos los gastos y costos que se genere ya sea de la 
                                 cobranza judicial o extrajudicial, incluyendo los honorarios de abogados. CUARTA: Clausula aclaratoria: El acreedor podrá declarar 
                                 vencido el plazo y exigir inmediatamente el pago de  la totalidad de la obligación cuando el deudor  entre en mora o incumpla 
                                 cualquiera de las obligaciones derivadas de este documento.',CHAR(13),''),CHAR(10),''),SPACE(34),'')
          FROM APAG INNER JOIN TER ON APAG.IDTERCERO=TER.IDTERCERO
                    INNER JOIN USUSU ON APAG.AUTORIZDOR=USUSU.USUARIO,
                    TER TER1 INNER JOIN CIU ON TER1.CIUDAD=CIU.CIUDAD
          WHERE IDPAGARE=@IDPAGARE
          AND  TER1.IDTERCERO=DBO.FNK_VALORVARIABLE('IDTERCEROINSTALADO')
          RETURN 
       END
       ELSE
       BEGIN
         SELECT 'KO'KO,'No se Encontro pagaré Para Imprimir, Verifique e Intente de nuevo'ERROR
         RETURN
       END
   END  
   IF @METODO='CIERRA_APAG'     
   BEGIN         
      SELECT @IDPAGARE=IDPAGARE        
      FROM   OPENJSON (@PARAMETROS)
      WITH (           
         IDPAGARE VARCHAR(20) '$.IDPAGARE' 
            ) 
       PRINT '@IDPAGARE='+COALESCE(@IDPAGARE,'NO TRAIGO NADA')
       IF EXISTS(SELECT  * FROM APAG WHERE IDPAGARE=@IDPAGARE AND ESTADO='Nuevo')     
       BEGIN
          PRINT 'INGRESO AL UPDATE'
          UPDATE APAG SET ESTADO='Impreso'  WHERE IDPAGARE=@IDPAGARE AND ESTADO='Nuevo'
          SELECT 'OK'OK
          RETURN 
       END
       ELSE
       BEGIN
          PRINT 'NO ENCONTRE'
          SELECT 'OK'OK
          RETURN 
       END
   END   
END


