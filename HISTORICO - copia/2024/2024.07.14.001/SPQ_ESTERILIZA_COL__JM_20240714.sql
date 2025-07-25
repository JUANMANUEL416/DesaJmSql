CREATE OR ALTER PROCEDURE DBO.SPQ_ESTERILIZA_COL @JSON NVARCHAR(MAX)
	WITH ENCRYPTION
AS
SET DATEFORMAT dmy
DECLARE @TBLERRORES TABLE (ERROR VARCHAR(MAX))
DECLARE  @PARAMETROS NVARCHAR(MAX)			,@MODELO VARCHAR(100)			   ,@METODO VARCHAR(100)
		,@USUARIO VARCHAR(12)				   ,@COMPANIA VARCHAR(2)		      ,@IDSEDE      VARCHAR(5)		
      ,@SYS_COMPUTERNAME VARCHAR(200)     ,@DATOS    VARCHAR(MAX)
      ,@PROCESO VARCHAR(20)               ,@CODPAQUETE VARCHAR(20)        ,@DESCRIPCION VARCHAR(100)
      ,@IDARTICULO VARCHAR(20)            ,@CANT INT                      ,@NOITEM INT
      ,@ESTADO VARCHAR(10)                ,@EQUIPO VARCHAR(20)            ,@ESTEQUIPO BIT
      ,@CNSREP VARCHAR(20)                ,@USUENTREGA VARCHAR(20)        ,@SECTOR VARCHAR(20)
      ,@CLASE VARCHAR(20)
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
   IF @METODO='CRUD_KCEPAQ'     
   BEGIN         
      SELECT @DATOS=DATOS        
      FROM   OPENJSON (@PARAMETROS)
      WITH (           
         DATOS NVARCHAR(MAX) AS JSON 
            )           
         SELECT @PROCESO=PROCESO,@CODPAQUETE=CODPAQUETE,@DESCRIPCION=DESCRIPCION       
         FROM   OPENJSON (@DATOS)
         WITH   (    
         PROCESO VARCHAR(20)      '$.PROCESO',
         CODPAQUETE VARCHAR(20)   '$.CODPAQUETE',
         DESCRIPCION VARCHAR(100) '$.DESCRIPCION'
         )  
      IF @PROCESO='Nuevo'
      BEGIN
         IF NOT EXISTS(SELECT * FROM KCEPAQ WHERE CODPAQUETE=@CODPAQUETE)
         BEGIN
            INSERT INTO KCEPAQ(CODPAQUETE,DESCRIPCION)
            SELECT @CODPAQUETE,@DESCRIPCION
         END
         ELSE
         BEGIN
            INSERT INTO @TBLERRORES(ERROR)
            SELECT 'Paquete ya existe'
         END
         IF(SELECT COUNT(*) FROM @TBLERRORES)>0
         BEGIN
            SELECT 'KO' OK, ERROR FROM @TBLERRORES
            RETURN
         END
         SELECT 'OK' OK
         RETURN 
      END
      IF @PROCESO='Edita'
      BEGIN
         IF EXISTS(SELECT * FROM KCEPAQ WHERE CODPAQUETE=@CODPAQUETE)
         BEGIN
            UPDATE KCEPAQ SET DESCRIPCION=@DESCRIPCION WHERE CODPAQUETE=@CODPAQUETE
         END
         ELSE
         BEGIN
            INSERT INTO @TBLERRORES(ERROR)
            SELECT 'Paquete ya existe'      
         END
         IF(SELECT COUNT(*) FROM @TBLERRORES)>0
         BEGIN
            SELECT 'KO' OK, ERROR FROM @TBLERRORES
            RETURN
         END
         SELECT 'OK' OK
         RETURN 
      END 
      IF @PROCESO='Borrar'
      BEGIN
         IF NOT EXISTS(SELECT * FROM KCEPAQD WHERE CODPAQUETE=@CODPAQUETE)
         BEGIN
            DELETE KCEPAQ WHERE CODPAQUETE=@CODPAQUETE
         END
         ELSE
         BEGIN
            INSERT INTO @TBLERRORES(ERROR)
            SELECT 'Paquete con Detalles No se puede Continuar'             
         END
         IF(SELECT COUNT(*) FROM @TBLERRORES)>0
         BEGIN
            SELECT 'KO' OK, ERROR FROM @TBLERRORES
            RETURN
         END
         SELECT 'OK' OK
         RETURN 
      END
   END
   IF @METODO='CRUD_KCEPAQD'     
   BEGIN         
      SELECT @DATOS=DATOS        
      FROM   OPENJSON (@PARAMETROS)
      WITH (           
         DATOS NVARCHAR(MAX) AS JSON 
            )           
         SELECT @PROCESO=PROCESO,@CODPAQUETE=CODPAQUETE,@NOITEM=ITEM,@IDARTICULO=IDARTICULO,@CANT=CANT,
         @ESTADO=CASE WHEN ESTADO='true' THEN 'Activo' ELSE 'Inactivo' END
         FROM   OPENJSON (@DATOS)
         WITH   (    
         PROCESO VARCHAR(20)      '$.PROCESO',
         CODPAQUETE VARCHAR(20)   '$.CODPAQUETE',
         ITEM INT                 '$.ITEM',
         IDARTICULO VARCHAR(100) '$.IDARTICULO',
         CANT       INT           '$.CANT',
         ESTADO VARCHAR(20)       '$.ESTADO'
         )  
      IF @PROCESO='Nuevo'
      BEGIN
         IF EXISTS(SELECT * FROM KCEPAQ WHERE CODPAQUETE=@CODPAQUETE)
         BEGIN
            SELECT @NOITEM=MAX(ITEM) FROM KCEPAQD WHERE CODPAQUETE=@CODPAQUETE
            INSERT INTO KCEPAQD(CODPAQUETE,ITEM,IDARTICULO,CANT,ESTADO)
            SELECT @CODPAQUETE,COALESCE(@NOITEM,0)+1,@IDARTICULO,@CANT,'Activo'
         END
         ELSE
         BEGIN
            INSERT INTO @TBLERRORES(ERROR)
            SELECT 'Paquete no Encontrado'
         END
         IF(SELECT COUNT(*) FROM @TBLERRORES)>0
         BEGIN
            SELECT 'KO' OK, ERROR FROM @TBLERRORES
            RETURN
         END
         SELECT 'OK' OK
         RETURN 
      END
      IF @PROCESO='Editar'
      BEGIN
         IF EXISTS(SELECT * FROM KCEPAQD WHERE CODPAQUETE=@CODPAQUETE AND ITEM=@NOITEM)
         BEGIN
            UPDATE KCEPAQD SET IDARTICULO=@IDARTICULO,CANT=@CANT,ESTADO=@ESTADO WHERE CODPAQUETE=@CODPAQUETE AND ITEM=@NOITEM
         END
         ELSE
         BEGIN
            INSERT INTO @TBLERRORES(ERROR)
            SELECT 'item no Encontrado '      
         END
         IF(SELECT COUNT(*) FROM @TBLERRORES)>0
         BEGIN
            SELECT 'KO' OK, ERROR FROM @TBLERRORES
            RETURN
         END
         SELECT 'OK' OK
         RETURN 
      END 
      IF @PROCESO='Borrar'
      BEGIN
         IF EXISTS(SELECT * FROM  KCEPAQD WHERE CODPAQUETE=@CODPAQUETE AND ITEM=@NOITEM)
         BEGIN
            DELETE  KCEPAQD WHERE CODPAQUETE=@CODPAQUETE AND ITEM=@NOITEM
         END
         ELSE
         BEGIN
            INSERT INTO @TBLERRORES(ERROR)
            SELECT ' Item no Encontado no se puede continuar'             
         END
         IF(SELECT COUNT(*) FROM @TBLERRORES)>0
         BEGIN
            SELECT 'KO' OK, ERROR FROM @TBLERRORES
            RETURN
         END
         SELECT 'OK' OK
         RETURN 
      END
   END
   IF @METODO='CRUD_TGEQUIP'     
   BEGIN         
      SELECT @DATOS=DATOS        
      FROM   OPENJSON (@PARAMETROS)
      WITH (           
         DATOS NVARCHAR(MAX) AS JSON 
            )  
         SELECT @PROCESO=PROCESO,@EQUIPO=EQUIPO,@DESCRIPCION=DESCRIPCION,@ESTEQUIPO=CASE WHEN ESTADO='True' THEN 1 ELSE 0 END
         FROM   OPENJSON (@DATOS)
         WITH   (    
         PROCESO VARCHAR(20)      '$.PROCESO',
         EQUIPO VARCHAR(20)   '$.EQUIPO',
         DESCRIPCION VARCHAR(100) '$.DESCRIPCION',
         ESTADO VARCHAR(20)       '$.ESTADO'
         )  
      IF @PROCESO='Nuevo'
      BEGIN
         IF NOT EXISTS(SELECT * FROM TGEN WHERE TABLA='ESTERILIZACION' AND CAMPO='EQUIPO' AND CODIGO=@EQUIPO)
         BEGIN
            INSERT INTO TGEN(TABLA,CAMPO,CODIGO,DESCRIPCION,CHECK1)
            SELECT TABLA='ESTERILIZACION' , CAMPO='EQUIPO', @EQUIPO,@DESCRIPCION,1
         END
         ELSE
         BEGIN
            INSERT INTO @TBLERRORES(ERROR)
            SELECT 'Equipo  ya existe'
         END
         IF(SELECT COUNT(*) FROM @TBLERRORES)>0
         BEGIN
            SELECT 'KO' OK, ERROR FROM @TBLERRORES
            RETURN
         END
         SELECT 'OK' OK
         RETURN 
      END
      IF @PROCESO='Editar'
      BEGIN
         IF EXISTS(SELECT * FROM TGEN WHERE TABLA='ESTERILIZACION' AND CAMPO='EQUIPO' AND CODIGO=@EQUIPO)
         BEGIN
            UPDATE TGEN SET DESCRIPCION=@DESCRIPCION,CHECK1=@ESTEQUIPO WHERE TABLA='ESTERILIZACION' AND CAMPO='EQUIPO' AND CODIGO=@EQUIPO
         END
         ELSE
         BEGIN
            INSERT INTO @TBLERRORES(ERROR)
            SELECT 'Equipo No Encontrado, Verfique e intente de nuevo'      
         END
         IF(SELECT COUNT(*) FROM @TBLERRORES)>0
         BEGIN
            SELECT 'KO' OK, ERROR FROM @TBLERRORES
            RETURN
         END
         SELECT 'OK' OK
         RETURN 
      END 
      IF @PROCESO='Borrar'
      BEGIN
         IF  EXISTS(SELECT * FROM TGEN WHERE TABLA='ESTERILIZACION' AND CAMPO='EQUIPO' AND CODIGO=@EQUIPO)
             AND NOT EXISTS(SELECT * FROM KCECAR WHERE EQUIPO=@EQUIPO)
         BEGIN
            DELETE TGEN WHERE TABLA='ESTERILIZACION' AND CAMPO='EQUIPO' AND CODIGO=@EQUIPO
         END
         ELSE
         BEGIN
            INSERT INTO @TBLERRORES(ERROR)
            SELECT 'Equipo Con Registros, No se puede Continuar'             
         END
         IF(SELECT COUNT(*) FROM @TBLERRORES)>0
         BEGIN
            SELECT 'KO' OK, ERROR FROM @TBLERRORES
            RETURN
         END
         SELECT 'OK' OK
         RETURN 
      END
   END
   IF @METODO='CRUD_KCEREP'     
   BEGIN         
      SELECT @PROCESO=PROCESO,@CNSREP=CNSREP,@USUENTREGA=USUENTREGA,@SECTOR=SECTOR,@CODPAQUETE=CODPAQUETE,@CLASE=CLASE      
      FROM   OPENJSON (@PARAMETROS)
      WITH (           
           PROCESO VARCHAR(20) '$.PROCESO',
           CNSREP  VARCHAR(20) '$.CNSREP',
           USUENTREGA VARCHAR(20) '$.USUENTREGA',
           SECTOR VARCHAR(20) '$.SECTOR',
           CODPAQUETE VARCHAR(20) '$.CODPAQUETE',
           CLASE VARCHAR(20) '$.CLASE'
            )           
      
      IF @PROCESO='Nuevo'
      BEGIN
         BEGIN TRY
            SELECT @IDSEDE= COALESCE(UBEQ.IDSEDE,USUSU.IDSEDE),@COMPANIA=UBEQ.COMPANIA 
            FROM USUSU LEFT JOIN UBEQ ON USUSU.SYS_ComputerName=UBEQ.SYS_ComputerName
            WHERE USUARIO=@USUARIO

            PRINT 'AQUI LLAMO A GENCONSECUTIVO @IDSEDE='+COALESCE(@IDSEDE,'SIN SEDE')+' COMPANIA'+COALESCE(@COMPANIA,'CIA') 
            SELECT @CNSREP=''
		      EXEC SPK_GENCONSECUTIVO @COMPANIA,@IDSEDE, '@KCEREP', @CNSREP OUTPUT  
            PRINT '@CNSREP='+COALESCE(@CNSREP,'')   
		      SELECT @CNSREP = @IDSEDE + REPLACE(SPACE(8 - LEN(@CNSREP))+LTRIM(RTRIM(@CNSREP)),SPACE(1),0)
		      PRINT '@CNSREP='+COALESCE(@CNSREP,'')                    
         END TRY
         BEGIN CATCH
            INSERT INTO @TBLERRORES(ERROR) SELECT ERROR_MESSAGE()
            SELECT 'KO'KO, ERROR AS ERROR FROM  @TBLERRORES 
            RETURN
         END CATCH

         BEGIN TRY           
             INSERT INTO KCEREP(CNSREP, FECHA, USUENTRE, SECTOR, CODPAQUETE, USUAREP, CLASE,ESTADO)  
             SELECT @CNSREP,DBO.FNK_GETDATE(), @USUENTREGA, @SECTOR, @CODPAQUETE, @USUARIO, @CLASE,'Recibido'
         END TRY
         BEGIN CATCH
               INSERT INTO @TBLERRORES(ERROR) SELECT ERROR_MESSAGE()
         END CATCH
         IF(SELECT COUNT(*) FROM @TBLERRORES)>0
         BEGIN
            SELECT 'KO' OK, ERROR FROM @TBLERRORES
            RETURN
         END
         SELECT 'OK' OK
         RETURN 
      END
      IF @PROCESO='Editar'
      BEGIN
         --IF EXISTS(SELECT  * FROM )

      END
   END      
END