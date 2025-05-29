CREATE OR ALTER PROCEDURE DBO.SPQ_AUT_COL
	@JSON  NVARCHAR(MAX)
WITH
ENCRYPTION
AS   
DECLARE @PARAMETROS         NVARCHAR(MAX) ,@MODELO           VARCHAR(100)    ,@METODO         VARCHAR(100)  ,@USUARIO          VARCHAR(12)
	    ,@GRUPO              VARCHAR(8)    ,@SYS_COMPUTERNAME VARCHAR(254)    ,@SEDE           VARCHAR(5)    ,@A                INT
       ,@IDAFILIADO         VARCHAR(20)   ,@PROCEDENCIA      VARCHAR(10)     ,@PROCESO        VARCHAR(20)   ,@AUT              NVARCHAR(MAX)
       ,@AUTD               NVARCHAR(MAX) ,@CNS              VARCHAR(20)     ,@CNSIDAUT       VARCHAR(20)   ,@VIGENCIA         SMALLINT
       ,@IDPLAN_AFI         VARCHAR(6)    ,@IDTERCERO_AFI    VARCHAR(20)     ,@IDAUT          VARCHAR(20)   ,@CONT             INT
       ,@IDAREA             VARCHAR(10)   ,@CONSECUTIVO      VARCHAR(20)     ,@CODCAJA        VARCHAR(20)   ,@CNSFACJ          VARCHAR(20)     
       ,@CNSHACTRAN         VARCHAR(20)	,@SIRAS			    VARCHAR(20)     ,@ITEM				 INT			   ,@VALORTOTAL	    DECIMAL (14,2)
	    ,@MEENTREGA			 VARCHAR(20)   ,@IDPLAN           VARCHAR(6)		  ,@NOAUT			 VARCHAR(20)	,@IDTERINSTALADO   VARCHAR(20)
       ,@COMPANIA			    VARCHAR(2)    ,@IDSEDEF          VARCHAR(6)		  ,@F_FACTURA		 DATETIME	   ,@IDSEDE           VARCHAR(6)
       ,@VALORCOPAGO		    DECIMAL(14,2) ,@N_FACTURA        VARCHAR(20)	  ,@VLR_PRESTACION DECIMAL(14,2)	,@VLR_ABONADO      DECIMAL(14,2)
	    ,@VLR_FALTANTE		 DECIMAL(14,2) ,@VLR_NV_ABONO     DECIMAL(14,2)	  ,@NRO            INT           ,@NVOCONSEC        VARCHAR(20)
       ,@RAZONANULA         VARCHAR(MAX)	,@PYP              INT		        ,@AC             INT	         ,@VALOR            DECIMAL(14,2)	
       ,@IDSERVICIO         VARCHAR(50)   ,@TOTAL            DECIMAL(14,2)   ,@NOADMISION     VARCHAR(16)  
       ,@PEDIDOHPREAIZSOL   VARCHAR(20)   ,@ESTADO_AUX       VARCHAR(1) = 0  ,@CNSMOV         VARCHAR(20)   ,@IDPROVEEDOR      VARCHAR(50)
       ,@GENEROCAJA         SMALLINT      ,@TIPOCAJA         VARCHAR(4)      ,@NORECIBOCAJA   VARCHAR(20)   ,@FECHA            DATE
       ,@ESTADO_FCJ         VARCHAR(1)    ,@CERRADA          SMALLINT        ,@SOAT           SMALLINT      ,@COPAGOPROPIO     DECIMAL(14,2)
       ,@CONSECUTIVOHCA     VARCHAR(13)	,@IDBODEGA		    VARCHAR(20)     ,@NO_ITEM	       INT           ,@VALIDATURNO      SMALLINT
       ,@ABIERTA_CAJ        SMALLINT      ,@CNSACJ_CAJ       VARCHAR(20)     ,@IDPLAN_TFCJ    VARCHAR(6)	   ,@PROCEDENCIA_TFCJ VARCHAR(10)
       ,@NOADMISION_TFCJ    VARCHAR(16)   ,@CNSFACJ_TFCJ     VARCHAR(20)     ,@CODCAJA_FCJ    VARCHAR(20)	,@FECHAFCJ         DATETIME 
       ,@FECHAAUT           DATETIME      ,@TIPODTO          VARCHAR(1)      ,@DESCUENTO      DECIMAL(14,2) ,@IDTERCEROCA      VARCHAR(20)
       ,@ENVIODICAJA        SMALLINT      ,@IXCOUNTRY        VARCHAR(20)     ,@TIPOFAC        VARCHAR(20)   ,@RUC              VARCHAR(20)
BEGIN		
   --VARIABLES PARA AUT
   DECLARE @IDCONTRATANTE_AUT VARCHAR(20), @IDPROVEEDOR_AUT VARCHAR(20) ,@IDPLAN_AUT VARCHAR(6) ,@PREFIJO_AUT VARCHAR(6) ,@VALORCOPAGO_AUT  DECIMAL(14,2)
          ,@GENEROCAJA_AUT    SMALLINT
          ,@EXCOBROPC SMALLINT, @LIQUIDARPC SMALLINT, @COBRARPC SMALLINT
   --VARIABLES PARA CURSOR AUTD
   DECLARE @IDAUT_CUR VARCHAR(13) ,@NO_ITEM_CUR SMALLINT ,@PYP_CUR SMALLINT = 0,@ALTOCOSTO_CUR SMALLINT = 0
         ,@VALORAUTD_CUR DECIMAL(14,2) ,@IDSERVICIO_CUR VARCHAR(20) ,@VEZ INT = 1
   DECLARE @VRTOTCOPAGO DECIMAL(14,2)

	SET LANGUAGE Spanish; 
	SET DATEFORMAT dmy
	SELECT @A = ISJSON(@JSON)
	IF @A = 0 
	BEGIN
		RAISERROR('Json: Formato Erroneo',16,1)
		RETURN
	END
	--PRINT 'INGRESE A SPQ_FME_COL'
	SELECT *
	INTO #JSON
	FROM OPENJSON (@json)
	WITH (
		MODELO         VARCHAR(100)     '$.MODELO',
		METODO         VARCHAR(100)     '$.METODO',
		USUARIO        VARCHAR(12)      '$.USUARIO',
		PARAMETROS     NVARCHAR(MAX)     AS JSON
	)
   SELECT @IXCOUNTRY=DBO.FNK_VALORVARIABLE('IXCOUNTRY')
	SELECT @MODELO = MODELO , @METODO = METODO , @PARAMETROS = PARAMETROS , @USUARIO = USUARIO
	FROM #JSON
	--DEFINICION DE TABLA DE ERRORES
	DECLARE @TBLERRORES TABLE(ERROR VARCHAR(200));
	-- TOMA DEL GRUPO, SYS_COMPUTERNAME, SEDE   DE ACUERDO AL USUARIO
	PRINT 'USUARIO:'+@USUARIO
	SELECT @GRUPO = DBO.FNK_DESCIFRAR(GRUPO) FROM USUSU WHERE USUARIO = @USUARIO
	SELECT @SYS_COMPUTERNAME = SYS_COMPUTERNAME FROM USUSU WHERE USUARIO = @USUARIO
	SELECT @SEDE = IDSEDE FROM UBEQ WHERE SYS_ComputerName = @SYS_COMPUTERNAME
	SELECT @IDSEDE = IDSEDE, @COMPANIA=COMPANIA, @IDBODEGA = COALESCE(IDBODEGA, IDBODEGA2, IDBODEGANOCHE, IDBODEGACONSUMO) 
	FROM UBEQ WHERE SYS_ComputerName = @SYS_COMPUTERNAME
	IF COALESCE(@SEDE,'') = '' SELECT @SEDE = '01'
	PRINT 'SEDE='+@SEDE
   PRINT '@SYS_COMPUTERNAME='+@SYS_COMPUTERNAME
   SELECT @IDAFILIADO  = JSON_VALUE(@PARAMETROS ,'$.IDAFILIADO')
   SELECT @IDPLAN_AFI  = IDPLAN ,@IDTERCERO_AFI = IDADMINISTRADORA FROM AFI WHERE IDAFILIADO = @IDAFILIADO


   IF @METODO = 'CRUDAUT'
   BEGIN
      PRINT 'CRUDAUT'
      SELECT @AUT  = AUT, @AUTD = AUTD
      FROM OPENJSON (@PARAMETROS)
      WITH(
         AUT   NVARCHAR(MAX)     AS JSON,
         AUTD  NVARCHAR(MAX)     AS JSON
      )
      --FECHAAUTORIZA
      --SELECT * FROM OPENJSON (@AUT)
      --ID_CPPAF
      SELECT @PROCESO     = JSON_VALUE(@AUT ,'$.PROCESO') 
	  SELECT @MEENTREGA =   JSON_VALUE(@AUT ,'$.MENTREGA') 
	 
	  --MENTREGA--IDPLAN--NUMAUTORIZA--FECHAVENCE--VALOR
      SELECT   * INTO #AUTD
      FROM  OPENJSON (@AUTD)
	   WITH (
          PROCESO             VARCHAR(20)   '$.PROCESO'           
         ,IDAUT               VARCHAR(13)   '$.IDAUT'             
         ,NO_ITEM             INT           '$.NO_ITEM'          
         ,IDSERVICIO          VARCHAR(20)   '$.IDSERVICIO'        
         ,DESCSERVICIO        VARCHAR(255)  '$.DESCSERVICIO'      
         ,CODCUPS             VARCHAR(20)   '$.CODCUPS'           
         ,CANTIDAD            DECIMAL(18,2) '$.CANTIDAD'          
         ,VALOR				  DECIMAL(18,2) '$.VALOR'          
         ,MDOSIFICACION       BIT           '$.MDOSIFICACION'     
         ,CLASEPOSOLOGIA      VARCHAR(20)   '$.CLASEPOSOLOGIA'    
         ,CANTIDIA            INT           '$.CANTIDIA'          
         ,FRECUENCIA          SMALLINT      '$.FRECUENCIA'        
         ,DIAS                SMALLINT      '$.DIAS'              
         ,PRIORIDAD           BIT           '$.PRIORIDAD'         
         ,COMENTARIOS         VARCHAR(2048) '$.COMENTARIOS'       
         ,AQUIENCOBRO         VARCHAR(2)    '$.AQUIENCOBRO'       
         ,NOAUTORIZEXT        VARCHAR(20)   '$.NOAUTORIZEXT'      
         ,IDTERCEROCA         VARCHAR(20)   '$.IDTERCEROCA'       
         ,IDPLAN              VARCHAR(6)    '$.IDPLAN'            
         ,APOYODG_AMBITO      VARCHAR(2)    '$.APOYODG_AMBITO'    
         ,CCOSTO              VARCHAR(20)   '$.CCOSTO'            
         ,IDARTICULO          VARCHAR(20)   '$.IDARTICULO'        
         ,IDARTICULOSER       VARCHAR(20)   '$.IDARTICULOSER'     
         ,CNSFMED             VARCHAR(20)   '$.CNSFMED'           
         ,CITAAUTORIZADA      BIT           '$.CITAAUTORIZADA'    
         ,POSOLOGIA           VARCHAR(255)  '$.POSOLOGIA'         
         ,IDTERCEROCADESC     VARCHAR(255)  '$.IDTERCEROCADESC'   
         ,REQAUTORIZACION     BIT           '$.REQAUTORIZACION'   
         ,CANTMINIMA          SMALLINT      '$.CANTMINIMA'        
         ,CANTMAXIMA          DECIMAL(14,2) '$.CANTMAXIMA'        
         ,IDADMINISTRADORA    VARCHAR(20)   '$.IDADMINISTRADORA' 
         ,TIPOAFILIADO			VARCHAR(20)   '$.TIPOAFILIADO' 
         ,IDPROVEEDOR			VARCHAR(20)   '$.IDPROVEEDOR' 
         ,PREFIJO				VARCHAR(20)   '$.PREFIJO' 
	   ) 

      SELECT * INTO #AUTD_NUEVO
      FROM OPENJSON (@AUTD)
      WITH (
         PROCESO             VARCHAR(20)   '$.PROCESO'  ,
         AQUIENCOBRO         VARCHAR(1)  '$.AQUIENCOBRO'  ,
         IDAUT               VARCHAR(13)   '$.IDAUT'             
         ,NO_ITEM             INT           '$.NO_ITEM'          
         ,IDSERVICIO          VARCHAR(20)   '$.IDSERVICIO'  
         ,DESCSERVICIO        VARCHAR(255)  '$.DESCSERVICIO'      
         ,CODCUPS             VARCHAR(20)   '$.CODCUPS'           
         ,CANTIDAD            DECIMAL(18,2) '$.CANTIDAD'  
         ,VALOR				  DECIMAL(18,2) '$.VALOR'          
         ,MDOSIFICACION       BIT           '$.MDOSIFICACION'     
         ,CLASEPOSOLOGIA      VARCHAR(20)   '$.CLASEPOSOLOGIA'    
         ,CANTIDIA            INT           '$.CANTIDIA'          
         ,FRECUENCIA          SMALLINT      '$.FRECUENCIA'        
         ,DIAS                SMALLINT      '$.DIAS'              
         ,PRIORIDAD           BIT           '$.PRIORIDAD'         
         ,COMENTARIOS         VARCHAR(2048) '$.COMENTARIOS'       
         ,NOAUTORIZEXT        VARCHAR(20)   '$.NOAUTORIZEXT'      
         ,IDTERCEROCA         VARCHAR(20)   '$.IDTERCEROCA'       
         ,IDPLAN              VARCHAR(6)    '$.IDPLAN'            
         ,APOYODG_AMBITO      VARCHAR(2)    '$.APOYODG_AMBITO'    
         ,CCOSTO              NVARCHAR(MAX)   AS JSON         
         ,IDARTICULO          VARCHAR(20)   '$.IDARTICULO'        
         ,IDARTICULOSER       VARCHAR(20)   '$.IDARTICULOSER'     
         ,CNSFMED             VARCHAR(20)   '$.CNSFMED'           
         ,CITAAUTORIZADA      BIT           '$.CITAAUTORIZADA'    
         ,POSOLOGIA           VARCHAR(255)  '$.POSOLOGIA'         
         ,IDTERCEROCADESC     VARCHAR(255)  '$.IDTERCEROCADESC'   
         ,REQAUTORIZACION     BIT           '$.REQAUTORIZACION'   
         ,CANTMINIMA          SMALLINT      '$.CANTMINIMA'        
         ,CANTMAXIMA          DECIMAL(14,2) '$.CANTMAXIMA'        
         ,IDADMINISTRADORA    VARCHAR(20)   '$.IDADMINISTRADORA' 
      )
	  UPDATE #AUTD_NUEVO SET IDPLAN = JSON_VALUE(@AUT ,'$.IDPLAN.value'), IDTERCEROCA = JSON_VALUE(@AUT ,'$.IDCONTRATANTE.value') WHERE  1 = 1 
	  --SELECT TOP 100 IDPLAN, IDTERCEROCA,  * FROM #AUTD_NUEVO
      
		IF UPPER(@PROCESO) = 'EDITAR'  AND DBO.FNK_VALORVARIABLE('SOLOUN_CODAUTORIZA')='SI' AND COALESCE(JSON_VALUE(@AUT ,'$.NUMAUTORIZA'), '')<>''
		BEGIN
			SELECT  @NRO=COUNT(*) FROM AUT WHERE COALESCE(AUT.NUMAUTORIZA,'')= COALESCE(JSON_VALUE(@AUT ,'$.NUMAUTORIZA'), '')  AND  AUT.IDAUT <> JSON_VALUE(@AUT ,'$.IDAUT')
			IF @NRO>0
			BEGIN
				INSERT INTO @TBLERRORES(ERROR)
				SELECT 'Ya existe un servicio ambulatorio con este mismo número de Autorización.. Autorización No Valida...'+COALESCE(JSON_VALUE(@AUT ,'$.NUMAUTORIZA'), '')
			END
		END
		IF UPPER(@PROCESO) = 'INSERTAR'  AND DBO.FNK_VALORVARIABLE('SOLOUN_CODAUTORIZA')='SI' AND COALESCE(JSON_VALUE(@AUT ,'$.NUMAUTORIZA'), '')<>''
		BEGIN
			SELECT  @NRO=COUNT(*) FROM AUT WHERE COALESCE(AUT.NUMAUTORIZA,'')= COALESCE(JSON_VALUE(@AUT ,'$.NUMAUTORIZA'), '')
			IF @NRO>0
			BEGIN
				INSERT INTO @TBLERRORES(ERROR)
				SELECT 'Ya existe un servicio ambulatorio con este mismo número de Autorización.. Autorización No Valida...'+COALESCE(JSON_VALUE(@AUT ,'$.NUMAUTORIZA'), '')
			END
		END
       IF UPPER(@PROCESO) = 'EDITAR' AND  (SELECT FACTURADA FROM AUT WHERE  AUT.IDAUT = JSON_VALUE(@AUT ,'$.IDAUT'))  = 1
       BEGIN
           INSERT INTO @TBLERRORES(ERROR) SELECT 'El registro ya se encuentra Facturado.'
           SELECT 'KO' OK
           SELECT ERROR FROM @TBLERRORES
           RETURN
       END
       IF UPPER(@PROCESO) = 'EDITAR' AND  (SELECT ESTADO FROM AUT WHERE  AUT.IDAUT = JSON_VALUE(@AUT ,'$.IDAUT'))  = 'Procesado'
       BEGIN
           INSERT INTO @TBLERRORES(ERROR) SELECT 'El registro ya se encuentra en Estado 1.'
           SELECT 'KO' OK
           SELECT ERROR FROM @TBLERRORES
           RETURN
       END
       IF UPPER(@PROCESO) = 'EDITAR' AND  (SELECT ENLAB FROM AUT WHERE  AUT.IDAUT = JSON_VALUE(@AUT ,'$.IDAUT'))  = 1
       BEGIN
           INSERT INTO @TBLERRORES(ERROR) SELECT 'El registro ya se encuentra en Laboratorio.'
           SELECT 'KO' OK
           SELECT ERROR FROM @TBLERRORES
           RETURN
       END
	    IF EXISTS (SELECT PNUMAUTORIZA_OBL FROM PPT WHERE IDTERCERO = JSON_VALUE(@AUT ,'$.IDCONTRATANTE.value') AND IDPLAN = JSON_VALUE(@AUT ,'$.IDPLAN.value') AND COALESCE( PPT.PNUMAUTORIZA_OBL,1) = 1)  
		           AND COALESCE(JSON_VALUE(@AUT ,'$.NUMAUTORIZA'), '') = '' AND COALESCE(JSON_VALUE(@AUT ,'$.AUTORIZADOPOR'), '') = '' AND COALESCE(JSON_VALUE(@AUT ,'$.FECHAAUTORIZA'), '') = ''
	    BEGIN
		    INSERT INTO @TBLERRORES(ERROR) SELECT 'Segun el Plan la Autorizacion es obligatoria.'
		    SELECT 'KO' OK
		    SELECT ERROR FROM @TBLERRORES
		    RETURN
	    END
       BEGIN TRY
         IF UPPER(@PROCESO) = 'INSERTAR'
         BEGIN
            PRINT 'INSERTAR'
            --EXEC SPK_GENCONSECUTIVO '01', @SEDE, '@AUTF', @CNS OUTPUT
            --SELECT @CNS = @SEDE++ REPLACE(SPACE(8 - LEN(@CNS))+LTRIM(RTRIM(@CNS)),SPACE(1),0)
			EXEC SPQ_GENSEQUENCE @SEDE=@SEDE,@PREFIJO='@AUTF', @LONGITUD=8, @NVOCONSEC=@CNS OUTPUT
            PRINT 'CONSECUTIVO: '+@CNS

            --EXEC SPK_GENCONSECUTIVO '01', @SEDE, '@AUT', @CNSIDAUT OUTPUT
            --SELECT @CNSIDAUT = @SEDE++ REPLACE(SPACE(8 - LEN(@CNSIDAUT))+LTRIM(RTRIM(@CNSIDAUT)),SPACE(1),0)
			EXEC SPQ_GENSEQUENCE @SEDE=@SEDE,@PREFIJO='@AUT', @LONGITUD=8, @NVOCONSEC=@CNSIDAUT OUTPUT
            PRINT '@CNSIDAUT: '+@CNSIDAUT
       
            --SELECT @VIGENCIA = COALESCE(VIGENCIA,30) FROM PRE WHERE PREFIJO = JSON_VALUE(@AUT ,'$.PREFIJO.value')
            SELECT @VIGENCIA = 30
		
            BEGIN TRY --TIPOAFILIADO--IDTERCEROCA--MARCAENV--ESDEINV--PREFIJO--IDAREA
				IF COALESCE((SELECT JSON_VALUE(@AUT ,'$.CCOSTO.IDAREA')),'') = ''
					SELECT @IDAREA = (SELECT TOP 1 IDAREA FROM CEN WHERE CCOSTO = JSON_VALUE(@AUT ,'$.CCOSTO.value'))
				ELSE
					SELECT @IDAREA = (SELECT JSON_VALUE(@AUT ,'$.CCOSTO.IDAREA'))

               INSERT INTO AUT (IDAUT               ,NOAUT         ,FECHA            ,FECHAVENCE       ,FECHASOL         ,IDAFILIADO       ,NUMCARNET       ,IDPLAN ,
                                PREFIJO             ,IDSEDE        ,IDSEDEORIGEN     ,TIPOAUTORIZACION ,ALTOCOSTO        ,ATENCION         ,URGENCIA        ,IMPUTABLE_A ,
                                IDSOLICITANTE       ,IDPROVEEDOR   ,ESTADO           ,CONSANULADO      ,IDOPERADORANULA  ,FECHAANULA       ,CAUSALANULA     ,NO_ITEMES ,
                                VALORTOTAL          ,VALORCOPAGO   ,VALORBENEFICIO   ,VALOREXEDENTE    ,VALORTOTALCOSTO  ,VALORCOPAGOCOSTO ,IMPRESO         ,CXPGEN ,
                                CXCGEN              ,AUTORIZADOPOR ,NUMAUTORIZA      ,FECHAAUTORIZA    ,AUTORIZADO       ,IDPESPECIAL      ,IDESTADOE       ,USUARIO ,
                                RECOBRARA           ,FUENTE        ,IDCAUSAEXT       ,AMBITO           ,FINALIDAD        ,PERSONAL_AT      ,DXPPAL          ,DXRELACIONADO ,
                                COMPLICACION        ,FORMAQX       ,TIPOURGENCIA     ,SPD              ,NORECIBOCAJA     ,CLASEORDEN       ,GENEROCAJA      ,IDCONTRATANTE ,
                                TIPOCOPAGO          ,PEDIDOINV     ,ENVIO            ,OBS              ,ESCONTINUACION   ,NOAUTORIGEN      ,SEMANASCOT      ,LIQUIDAPC ,
                                OBSDX               ,COMITE        ,CERTIFICACION    ,IDCLASEAUT       ,CLASECONT        ,ESDEINV          ,NOGENERACIONOPS ,FECHAGEN ,
                                CNSAFIAA            ,PROCEDENCIA   ,IDAREAH          ,IDAREA           ,CCOSTO           ,SUBCCOSTO        ,NIVELATENCION   ,FACTURADA ,
                                N_FACTURA           ,CNSFCT        ,VFACTURAS        ,FACTURABLE       ,DESCUENTO        ,TIPODTO          ,MARCAFAC        ,IDIPS ,
                                CLASECONTRATO       ,ENPAQUETE     ,IDCIRUGIA        ,SOAT             ,NOADMISION       ,IDCONTRATO       ,RUBRO           ,CLASERUBRO ,
                                PERIODICIDAD        ,CNSFACT       ,CONTINUACION     ,VLRUTOTRA        ,TIPOCONT         ,DXRELACIONADO2   ,FECHACOMITE     ,IDALTERNA ,
                                MARCAENV            ,COPAGOPROPIO  ,CNSHACTRAN       ,ESDELAB          ,ENLAB            ,COBRARA          ,IDTERCEROCA     ,CONSECUTIVOHCA ,
                                RAZONANULACION      ,PIDECCOSTO    ,FECHAREALIZACION ,CODCAJA          ,TIPOCAJA         ,IDGRUPOSER       ,PEXTERNA        ,AQUIENCOBRO ,
                                CODUNG              ,CODPRG        ,ITFC             ,CNSITFC          ,SYS_COMPUTERNAME ,CNSLABCOR        ,TIPOUSUARIO     ,NOADMISIONCE ,
                                INDLABCORE          ,CERRADA       ,CONTABILIZADA    ,NROCOMPROBANTE   ,MARCACONT        ,SINCRONIZADO     ,IDPLAN_AFI      ,IDTERCERO_AFI ,
                                USUARIONOFACTURABLE ,FECHA_NOFAC   ,RIESGO           ,IDSUCURSAL       ,CIUDAD           ,FUNCIONARIO_AUT  ,IDIPSSOLICITA   ,IDMEDICOSOLICITA ,
                                DIRECCION           ,ORIGEN        ,VLRDEPOSITOS     ,NOTIFICADO       ,ENTREGADO        ,FENTREGA         ,UENTREGA       ,TIPOAFILIADO ,
                                MENTREGA            ,NRO_ENTREGA   ,CANT_ENTREGAS    ,RUBRO_ID         ,IDFIRMAPTE       ,IDFIRMARESP ) 
               SELECT @CNSIDAUT ,@CNS 
			            ,COALESCE( REPLACE(JSON_VALUE(@AUT ,'$.FECHA'),'-','') , DBO.FNK_GETDATE()) 
			            ,COALESCE( REPLACE(JSON_VALUE(@AUT ,'$.FECHAVENCE'),'-','') , DBO.FNK_GETDATE() + @VIGENCIA) 
			            , DBO.FNK_GETDATE()
			            , @IDAFILIADO , '' , JSON_VALUE(@AUT ,'$.IDPLAN.value')
                     ,JSON_VALUE(@AUT ,'$.PREFIJO.value')     ,JSON_VALUE(@AUT ,'$.IDSEDE.value')   ,JSON_VALUE(@AUT ,'$.IDSEDE.value') ,JSON_VALUE(@AUT ,'$.TIPOAUTORIZACION.value') 
                     ,JSON_VALUE(@AUT ,'$.ALTOCOSTO.value')   ,JSON_VALUE(@AUT ,'$.ATENCION.value') ,CASE JSON_VALUE(@AUT ,'$.URGENCIA.value') WHEN 'false' THEN 0 ELSE 1 END
                     ,JSON_VALUE(@AUT ,'$.IMPUTABLE_A.value') 
					      ,COALESCE(JSON_VALUE(@AUT ,'$.IDSOLICITANTE') , CASE WHEN EXISTS (SELECT * FROM USUSU WHERE USUARIO = @USUARIO AND COALESCE( USUSU.IDMEDICO,'')  <> '' ) THEN (SELECT IDMEDICO FROM USUSU WHERE USUARIO = @USUARIO) ELSE (SELECT USUARIO FROM USUSU WHERE USUARIO = @USUARIO) END )
                     --,CASE JSON_VALUE(@AUT ,'$.IDPROVEEDOR')  WHEN '' THEN NULL ELSE JSON_VALUE(@AUT ,'$.IDPROVEEDOR') END
					      ,CASE WHEN COALESCE(JSON_VALUE(@AUT ,'$.IDPROVEEDOR'),'' )= '' THEN (SELECT IDPROVEEDORDEF FROM PRE WHERE PREFIJO = JSON_VALUE(@AUT ,'$.PREFIJO.value')) END
					      /*,JSON_VALUE(@AUT ,'$.ESTADO')*/
					      ,'Pendiente'
                     ,CONSANULADO  = NULL ,IDOPERADORANULA = NULL ,FECHAANULA = NULL, CAUSALANULA = NULL , NO_ITEMES = 0 
                     ,VALORTOTAL   = 0 ,VALORCOPAGO = JSON_VALUE(@AUT ,'$.VALORCOPAGO') ,VALORBENEFICIO = 0 ,VALOREXEDENTE = 0 ,VALORTOTALCOSTO = 0 ,VALORCOPAGOCOSTO = 0 ,IMPRESO = 0 ,CXPGEN = 0
                     ,CXCGEN       = 0 ,AUTORIZADOPOR = JSON_VALUE(@AUT ,'$.AUTORIZADOPOR') ,NUMAUTORIZA = JSON_VALUE(@AUT ,'$.NUMAUTORIZA') ,FECHAAUTORIZA = COALESCE( REPLACE(JSON_VALUE(@AUT ,'$.FECHAAUTORIZA'),'-','') , NULL) ,AUTORIZADO = 0 
                     ,IDPESPECIAL  = JSON_VALUE(@AUT ,'$.IDPESPECIAL.value'),IDESTADOE = NULL ,USUARIO = @USUARIO 
                     ,RECOBRARA    = NULL                                   ,FUENTE    = NULL ,IDCAUSAEXT = JSON_VALUE(@AUT ,'$.IDCAUSAEXT.value') ,AMBITO = JSON_VALUE(@AUT ,'$.AMBITO.value') 
                     ,FINALIDAD    = JSON_VALUE(@AUT ,'$.FINALIDAD.value')
                     ,PERSONAL_AT  = JSON_VALUE(@AUT ,'$.PERSONAL_AT.value'),DXPPAL    = JSON_VALUE(@AUT ,'$.DXPPAL.value'),DXRELACIONADO = JSON_VALUE(@AUT ,'$.DXRELACIONADO.value') 
                     ,COMPLICACION = JSON_VALUE(@AUT ,'$.COMPLICACION.value')
                     ,FORMAQX      = NULL ,'NA' ,0 ,NULL, JSON_VALUE(@AUT ,'$.CLASEORDEN.value'), JSON_VALUE(@AUT ,'$.GENEROCAJA') ,JSON_VALUE(@AUT ,'$.IDCONTRATANTE.value') 
                     ,JSON_VALUE(@AUT ,'$.TIPOCOPAGO.value') ,JSON_VALUE(@AUT ,'$.PEDIDOINV.value') ,NULL ,NULL , 0 ,NULL ,NULL , LIQUIDAPC = 0
                     ,OBSDX = NULL ,NULL ,NULL , 'CE' ,JSON_VALUE(@AUT ,'$.CLASECONT.value'), JSON_VALUE(@AUT ,'$.ESDEINV.value'),  NULL , DBO.FNK_FECHA_SIN_MLS(GETDATE()), CNSAFIAA= NULL
                     ,NULL , NULL , @IDAREA, JSON_VALUE(@AUT ,'$.CCOSTO.value') ,NULL ,JSON_VALUE(@AUT ,'$.NIVELATENCION.value')
                     ,FACTURADA        = 0                                         ,N_FACTURA      = NULL
                     ,CNSFCT= NULL                                                 ,0 
                     ,1                                                            ,JSON_VALUE(@AUT ,'$.DESCUENTO') 
                     ,NULL                                                         ,0 
                     ,NULL                                                         ,CLASECONTRATO  = JSON_VALUE(@AUT ,'$.CLASECONTRATO.value') 
                     ,ENPAQUETE        = CASE JSON_VALUE(@AUT ,'$.ENPAQUETE') WHEN 'false' THEN 0 ELSE 1 END    
                     ,IDCIRUGIA        = NULL                                      ,SOAT           = CASE JSON_VALUE(@AUT ,'$.SOAT') WHEN 'false' THEN 0 ELSE 1 END         
                     ,NOADMISION       = NULL                                      ,IDCONTRATO     = NULL      
                     ,RUBRO            = NULL                                      ,CLASERUBRO     = NULL 
                     ,PERIODICIDAD     = 0                                         ,CNSFACT        = NULL     
                     ,CONTINUACION     = 0                                         ,VLRUTOTRA      = 0              ,TIPOCONT            = NULL       
                     ,DXRELACIONADO2   = NULL                                      ,FECHACOMITE    = NULL           ,IDALTERNA           = NULL ,MARCAENV       = 0           
                     ,COPAGOPROPIO     = CASE JSON_VALUE(@AUT ,'$.COPAGOPROPIO') WHEN 'false' THEN 0 ELSE 1 END 
                     ,CNSHACTRAN       = CASE JSON_VALUE(@AUT ,'$.CNSHACTRAN')  WHEN '' THEN NULL ELSE JSON_VALUE(@AUT ,'$.CNSHACTRAN') END        
                     ,ESDELAB          = 0                                         ,ENLAB          = 0              ,COBRARA             = JSON_VALUE(@AUT ,'$.COBRARA')        
                     ,JSON_VALUE(@AUT ,'$.IDCONTRATANTE.value')         ,CONSECUTIVOHCA = NULL           ,RAZONANULACION      = NULL ,PIDECCOSTO     = 0   
                     ,FECHAREALIZACION = NULL                                      ,CODCAJA        = NULL         
                     ,TIPOCAJA         = JSON_VALUE(@AUT ,'$.TIPOCAJA')            ,IDGRUPOSER     = NULL           ,PEXTERNA            = NULL ,AQUIENCOBRO    = JSON_VALUE(@AUT ,'$.AQUIENCOBRO')
                     ,CODUNG           = NULL                                      ,CODPRG         = NULL           ,ITFC                = 0    ,CNSITFC        = NULL        
                     ,SYS_COMPUTERNAME = @SYS_COMPUTERNAME                         ,CNSLABCOR      = NULL           ,TIPOUSUARIO         = 'I'  ,NOADMISIONCE   = NULL
                     ,INDLABCORE       = 0                                         ,CERRADA        = 0              ,CONTABILIZADA       = 0    ,NROCOMPROBANTE = NULL  
                     ,MARCACONT        = 0                                         ,SINCRONIZADO   = 0     
                     ,IDPLAN_AFI       = @IDPLAN_AFI                               ,IDTERCERO_AFI  = @IDTERCERO_AFI ,USUARIONOFACTURABLE = NULL ,FECHA_NOFAC    = NULL 
                     ,RIESGO           = JSON_VALUE(@AUT ,'$.RIESGO')              ,IDSUCURSAL     = NULL           ,CIUDAD              = NULL           
                     ,FUNCIONARIO_AUT  = NULL                                      ,IDIPSSOLICITA  = JSON_VALUE(@AUT ,'$.IDIPSSOLICITA')            ,IDMEDICOSOLICITA    = NULL
                     ,DIRECCION        = NULL                                      ,ORIGEN         = NULL           ,VLRDEPOSITOS        = 0    ,NOTIFICADO     = 0      
                     ,ENTREGADO        = 0                                         ,FENTREGA       = NULL           ,UENTREGA            = NULL      
                     ,TIPOAFILIADO     = JSON_VALUE(@AUT ,'$.TIPOAFILIADO.value')  ,MENTREGA       = JSON_VALUE(@AUT ,'$.MENTREGA.value')           ,NRO_ENTREGA         = NULL ,CANT_ENTREGAS  = 0    
                     ,RUBRO_ID         = NULL                                      ,IDFIRMAPTE     = NULL           ,IDFIRMARESP         = NULL
          
		         IF     (SELECT COALESCE(AUT.FECHA,'') FROM AUT WHERE IDAUT = @CNSIDAUT ) = '' 
                   OR (SELECT CONVERT(DATE, AUT.FECHAVENCE) FROM AUT WHERE IDAUT = @CNSIDAUT) = '19000101'
			         UPDATE AUT SET FECHAVENCE = DBO.FNK_GETDATE() + @VIGENCIA WHERE IDAUT = @CNSIDAUT 
               
               IF     (SELECT COALESCE(FECHAAUTORIZA,'') FROM AUT WHERE IDAUT = @CNSIDAUT)='' 
                   OR (SELECT COALESCE(FECHAAUTORIZA,'') FROM AUT WHERE IDAUT = @CNSIDAUT)='1900-01-01 00:00:00.000'
                  UPDATE AUT SET FECHAAUTORIZA =  NULL WHERE IDAUT = @CNSIDAUT

               DECLARE @PREF VARCHAR(6)
               SELECT @PREF = JSON_VALUE(@AUT ,'$.PREFIJO.value')
               PRINT 'PREFIJO = '+@PREF
			      IF EXISTS (SELECT * FROM PRE WHERE PREFIJO = JSON_VALUE(@AUT ,'$.PREFIJO.value')  AND COALESCE(MINVENTARIOS,0)=1 )
               BEGIN
                   print 'ingrese a colocarlo de inventario'
				       UPDATE AUT SET ESDEINV = 1 WHERE  IDAUT = @CNSIDAUT
			      END
			      -- PARA EL ACCIDENTE DE TRANSITO					
			      SELECT  @SIRAS = COALESCE(SIRAS,'') ,  @CNSHACTRAN =COALESCE(CNSHACTRAN,'')  
			      FROM OPENJSON(@PARAMETROS) --PARA GUARDAR EL SIRAS EN HACTRAND
			      WITH( 
			   	    SIRAS			VARCHAR(20) '$.SIRAS'
			   	   ,CNSHACTRAN		VARCHAR(20) '$.CNSHACTRAN'
			      )
               
			      IF ( COALESCE(@CNSHACTRAN ,'' ) <>'' )
			      BEGIN
			   	     IF ( SELECT COUNT(*) FROM HACTRAND WHERE  CNSHACTRAN	=@CNSHACTRAN AND PROCEDENCIA='CE'	AND NOREFERENCIA = @CONSECUTIVO ) >0  
			   	     BEGIN
			   	  	   PRINT 'ACTUALIZO EL CONSUMO DEL ACCIDENTE DE TRANSITO'
			   	  	   UPDATE HACTRAND SET VLRGASTADO = 0 , SIRAS = @SIRAS  WHERE  CNSHACTRAN	=@CNSHACTRAN AND PROCEDENCIA='CE'	AND NOREFERENCIA = @CONSECUTIVO
			   	     END
			   	     ELSE
			   	     BEGIN
			   	  	   PRINT 'AGREGO UN NUEVO DETALLE DE HACTRAND CON EL NUEVO CONSUMO'
                  
			   	  	   SELECT @ITEM = COUNT(ITEM)+1 FROM HACTRAND WHERE  CNSHACTRAN	=@CNSHACTRAN 
			   	  	   INSERT INTO HACTRAND ( CNSHACTRAN, ITEM, PROCEDENCIA,  NOREFERENCIA , N_FCT_ASEG, VLRGASTADO, SIRAS	)
			   	  		   VALUES  ( @CNSHACTRAN ,  @ITEM , 'CE' , @CNS , NULL , 0  , @SIRAS   )
			   	     END
			      END
		
            END TRY
            BEGIN CATCH 
               INSERT INTO @TBLERRORES(ERROR) SELECT ERROR_MESSAGE()
            END CATCH

            IF (SELECT COUNT(*) FROM @TBLERRORES)> 0
		      BEGIN
               DELETE AUT WHERE IDAUT = @CNSIDAUT
			      SELECT 'KO' OK
			      SELECT ERROR FROM @TBLERRORES
		         RETURN
		      END 
            PRINT 'PASE AUT'
            BEGIN TRY--IDAREA -- JSON_VALUE(@AUT ,'$.IDCONTRATANTE.value') --IDTERCEROCA  NOAUT --NO_ITEM
               PRINT 'ENTRE AL TRY DE AUTD'
               INSERT INTO AUTD (IDAUT           ,NO_ITEM          ,IDSERVICIO     ,CANTIDAD       ,VALOR            ,VALORCOPAGO  ,VALORCOPAGOCOSTO ,VALOREXCEDENTE ,
                                 VALORTOTALCOSTO ,IDPLAN           ,IMPRESO        ,AUTORIZADO     ,COMENTARIOS      ,PCOBERTURA   ,OBS              ,NORDEN ,
                                 CCOSTO          ,CODIGOCPCJ       ,MARCAPAGO      ,NOAUTORIZEXT   ,ESDELAB          ,ENLAB        ,IDTERCEROCA      ,IDCONTRATO ,
                                 FACTURADA       ,N_FACTURA        ,CNSFCT         ,AQUIENCOBRO    ,MARCACOPAGOORDEN ,VALORPROV    ,PCOSTO           ,ITFC ,
                                 CNSITFC         ,SYS_COMPUTERNAME ,NOCOBRABLE     ,MDOSIFICACION  ,CANTIDIA         ,DIAS         ,FRECUENCIA       ,CODCUPS ,
                                 POSOLOGIA       ,SINCRONIZADO     ,APOYODG_AMBITO ,CITAAUTORIZADA ,DOSISAPL         ,DURACIONTTOF ,DURACIONTTOC     ,CLASEPOSOLOGIA ,
                                 MARCA           ,USUARIOMARCA     ,NUM_ORDEN      ,PROCESADA      ,PRIORIDAD        ,HOMOLOGO     ,IDSERVICIOH      ,CANTIDADH ,
                                 VALORHOMO       ,NO_ITEMH         ,N_FACTURAORI   ,DESCUENTO      ,TIPODTO          ,CNSFMED      ,F_INGLAB         ,F_SALILAB ,
                                 IDARTICULO      ,IMPORTADO ) 
               SELECT @CNSIDAUT 
                     , ROW_NUMBER()  OVER (ORDER BY NO_ITEM)       
                     , IDSERVICIO ,CANTIDAD
                     ,COALESCE((SELECT TOP 1 VLRSERVICIO FROM SERTOT WHERE SERTOT.IDSERVICIO = #AUTD_NUEVO.IDSERVICIO AND SERTOT.IDTERCERO = JSON_VALUE(@AUT ,'$.IDTERCEROCA') 
                        AND SERTOT.IDPLAN = JSON_VALUE(@AUT ,'$.IDPLAN.value') AND CONVERT(DATE, GETDATE()) BETWEEN FECHAINI AND FECHAFIN AND CONVERT(DATE, GETDATE()) BETWEEN FECHAINIFD AND FECHAFINFD  ),0)
                     --,0
                        , 0, 0, 0,  0
                     , JSON_VALUE(@AUT ,'$.IDPLAN.value')
                     , 0 ,1
                     , COMENTARIOS     
                     , 100 ,NULL, NULL
                     , JSON_VALUE(@AUT ,'$.CCOSTO.value')
                     , NULL ,0 
                     , NOAUTORIZEXT
                     , 0,0
                     , JSON_VALUE(@AUT ,'$.IDCONTRATANTE.value')
                     , NULL
                     , 0, NULL ,NULL 
                     , AQUIENCOBRO
                     , 0 ,0 ,0 ,0 ,NULL ,@SYS_COMPUTERNAME, 0
                     , MDOSIFICACION
                     , CANTIDIA
                     , DIAS     
                     , FRECUENCIA
                     , CODCUPS 
                     , POSOLOGIA       
                     , 0
                     , APOYODG_AMBITO  
                     , CITAAUTORIZADA  
                     , DOSISAPL = NULL,DURACIONTTOF = NULL,DURACIONTTOC = NULL
                     , CLASEPOSOLOGIA  
                     , 0 ,NULL ,NULL ,0 , PRIORIDAD ,NULL ,NULL ,NULL
                     , NULL, NULL ,NULL ,NULL ,NULL ,NULL , NULL ,NULL
                     , IDARTICULO      
                     , 0
                     --PRIORIDAD       
                     --IDARTICULOSER   
                     --CNSFMED         
                     --IDTERCEROCADESC 
                     --REQAUTORIZACION 
                     --CANTMINIMA      
                     --CANTMAXIMA      
                     --IDADMINISTRADORA
               FROM   #AUTD_NUEVO
               PRINT 'INSERTE AUTD ==============='
               SELECT @FECHAAUT = FECHA FROM AUT WHERE IDAUT = @CNSIDAUT

     --CLOSE AUTD_C
				--DEALLOCATE AUTD_C
				
               DECLARE AUTD_C CURSOR FOR 
               SELECT IDAUT ,NO_ITEM 
               FROM   AUTD 
               WHERE  IDAUT = @CNSIDAUT
               OPEN AUTD_C
               FETCH NEXT FROM AUTD_C INTO @IDAUT_CUR ,@NO_ITEM_CUR
               WHILE @@FETCH_STATUS = 0
               BEGIN
                  PRINT 'INGRESE AL CURSOR' +STR(@VEZ)

                  SELECT @IDSERVICIO_CUR = IDSERVICIO ,@VALORAUTD_CUR = VALOR FROM AUTD WHERE IDAUT = @CNSIDAUT AND NO_ITEM = @NO_ITEM_CUR
                  PRINT '@IDSERVICIO_CUR ='+@IDSERVICIO_CUR
                  SELECT @PYP_CUR       = CASE WHEN CLASEORDEN = 'PyP' THEN 1 ELSE 0 END 
                        ,@ALTOCOSTO_CUR = CASE WHEN ALTOCOSTO  = 'Si'  THEN 1 ELSE 0 END   
                  FROM   AUT WHERE IDAUT = @CNSIDAUT  

                  EXEC SPK_COPAGO_AUT_CEHOSP @IDAFILIADO, @CNSIDAUT ,@NO_ITEM_CUR ,@IDSERVICIO_CUR ,@PYP_CUR ,@ALTOCOSTO_CUR ,@VALORAUTD_CUR
                                             ,'CE' ,@SYS_COMPUTERNAME ,'01' ,@IDSEDE , @USUARIO, NULL, @IDAREA ,@FECHAAUT, 0, 0
                  SELECT @VEZ += 1
                  FETCH NEXT FROM AUTD_C INTO @IDAUT_CUR ,@NO_ITEM_CUR
               END
                CLOSE AUTD_C
                DEALLOCATE AUTD_C


                --CALCULO DE TOTALES DE AUT
                UPDATE AUT SET VALORTOTAL = (SELECT SUM(VALOR) FROM AUTD WHERE IDAUT = @CNSIDAUT) 
                        ,NO_ITEMES = (select COUNT( IDSERVICIO) from autd where IDAUT = @CNSIDAUT ) 
                WHERE AUT.IDAUT = @CNSIDAUT
                --DECLARE @VRTOTCOPAGO DECIMAL(14,2)


                IF (SELECT COALESCE(COPAGOPROPIO,0) FROM AUT WHERE IDAUT = @CNSIDAUT) = 0
                BEGIN
                    IF (SELECT SUM(VALORCOPAGO) FROM AUTD WHERE AUTD.IDAUT = @CNSIDAUT)>0
                    BEGIN
                       IF (SELECT VALORCOPAGO FROM AUTD WHERE AUTD.IDAUT =  @CNSIDAUT AND MARCACOPAGOORDEN = 1  ) >0
                       BEGIN
                          SELECT @VRTOTCOPAGO = VALORCOPAGO FROM AUTD WHERE AUTD.IDAUT =  @CNSIDAUT AND MARCACOPAGOORDEN = 1
                          UPDATE AUT SET VALORCOPAGO = @VRTOTCOPAGO , TIPOCOPAGO = 'M' WHERE IDAUT = @CNSIDAUT
                       END
                       ELSE
                       BEGIN
                          SELECT @VRTOTCOPAGO = SUM(VALORCOPAGO) FROM AUTD WHERE AUTD.IDAUT = @CNSIDAUT
                          UPDATE AUT SET VALORCOPAGO = @VRTOTCOPAGO , TIPOCOPAGO = 'C' WHERE IDAUT = @CNSIDAUT
                       END
                    END
                    ELSE
                    BEGIN
                       UPDATE AUT SET VALORCOPAGO = 0 , TIPOCOPAGO = 'N' WHERE IDAUT = @CNSIDAUT 
                    END
                END



                SELECT @IDCONTRATANTE_AUT = IDCONTRATANTE ,@IDPROVEEDOR_AUT = IDPROVEEDOR ,@IDPLAN_AUT = IDPLAN ,@PREFIJO_AUT = PREFIJO ,@VALORCOPAGO_AUT = VALORCOPAGO
                      ,@GENEROCAJA_AUT    = GENEROCAJA  
                FROM   AUT WHERE IDAUT = @CNSIDAUT

                SELECT @EXCOBROPC=EXCOBROPC, @LIQUIDARPC=LIQUIDARPC, @COBRARPC = COBRARPC FROM VW_PXS  --CMT VW_PXS
                WHERE  IDADMINISTRADORA = @IDCONTRATANTE_AUT
                AND    IDTERCERO        = @IDPROVEEDOR_AUT AND IDPLAN = @IDPLAN_AUT
                AND    PREFIJO          = @PREFIJO_AUT 


                if DBO.FNK_valorvariable('CETIPOAUTORIZACION') = 'CEHOSP'
                BEGIN
                   IF (SELECT TIPOCAJA FROM AUT WHERE IDAUT = @CNSIDAUT) <>'FCJ'
                   BEGIN
                       PRINT 'VOY PARA SPK_PAGOSCAJA_AUT_CEHOSP '
                      EXEC SPK_PAGOSCAJA_AUT_CEHOSP @CNS,@SYS_COMPUTERNAME, '01',@IDSEDE, @USUARIO, 1  --CMT AUT
                   END
                END
                ELSE
                BEGIN
                   IF (SELECT COALESCE(TER.ENVIODICAJA,0) FROM AUT INNER JOIN TER ON AUT.IDTERCEROCA = TER.IDTERCERO WHERE AUT.IDAUT = @CNSIDAUT) = 1
                   BEGIN
                      PRINT 'VOY A SPK_PAGOSCAJA_AUT (1)'
                      EXEC SPK_PAGOSCAJA_AUT @CNS,@SYS_COMPUTERNAME,'01',@IDSEDE, @USUARIO, 1
                   END
                   ELSE
                   BEGIN
                      IF @VALORCOPAGO_AUT > 0 AND @COBRARPC = 1
                      BEGIN
                         If @GENEROCAJA_AUT <> 1 
                         BEGIN
                              PRINT 'VOY A SPK_PAGOSCAJA_AUT (0)'
                            EXEC SPK_PAGOSCAJA_AUT @CNS,@SYS_COMPUTERNAME,'01',@IDSEDE,@USUARIO,0
                         END
                      END
                   END
                END


			      IF DBO.FNK_VALORVARIABLE('INTERFAZ_LX') = 'ANNARLAB'  AND (SELECT COUNT(*) FROM AUTD INNER JOIN SER ON AUTD.IDSERVICIO = SER.IDSERVICIO WHERE AUTD.IDAUT = @CNSIDAUT AND    SER.AMBITO = 'LX' )>0
			      BEGIN
					   PRINT 'ENTRA A SPKI_LX_ENVIO_DATOS'
					   EXEC SPKI_LX_ENVIO_DATOS 'AUTD', @CNS, 0
			      END

            END TRY
            BEGIN CATCH
               INSERT INTO @TBLERRORES(ERROR) SELECT ERROR_MESSAGE()
            END CATCH
            IF (SELECT COUNT(*) FROM @TBLERRORES)> 0
		      BEGIN
               DELETE AUTD WHERE IDAUT = @CNSIDAUT
               DELETE AUT  WHERE IDAUT = @CNSIDAUT
			      SELECT 'KO' OK
			      SELECT ERROR FROM @TBLERRORES
		         RETURN
		      END 
            SELECT 'OK' OK ,@CNS CNS
            RETURN
         END
         IF UPPER(@PROCESO) = 'EDITAR'
         BEGIN
			PRINT '@PROCESO = EDITAR'
		      --FECHA, FECHAVENCE,
            SELECT @CNSIDAUT = JSON_VALUE(@AUT ,'$.IDAUT') 
            SELECT @CNS = NOAUT FROM AUT WHERE IDAUT = @CNSIDAUT --IDTERCEROCA
            SELECT @IDAREA = (SELECT TOP 1 IDAREA FROM CEN WHERE CCOSTO = JSON_VALUE(@AUT ,'$.CCOSTO.value'))
            UPDATE AUT SET PREFIJO        = JSON_VALUE(@AUT ,'$.PREFIJO.value')           , IDSEDE = JSON_VALUE(@AUT ,'$.IDSEDE.value')                  , CCOSTO = JSON_VALUE(@AUT ,'$.CCOSTO.value') 
                        , CLASECONTRATO   = JSON_VALUE(@AUT ,'$.CLASECONTRATO.value')     , TIPOAFILIADO = JSON_VALUE(@AUT ,'$.TIPOAFILIADO.value')      , URGENCIA = CASE JSON_VALUE(@AUT ,'$.URGENCIA') WHEN 'true' THEN 1 ELSE 0 END 
                        , ENPAQUETE       = CASE JSON_VALUE(@AUT ,'$.ENPAQUETE') WHEN 'true' THEN 1 ELSE 0 END                                           , DXPPAL = JSON_VALUE(@AUT ,'$.DXPPAL.value')
                        , COMPLICACION    = JSON_VALUE(@AUT ,'$.COMPLICACION.value')      , IDPROVEEDOR = JSON_VALUE(@AUT ,'$.IDPROVEEDOR')              , SOAT = CASE JSON_VALUE(@AUT ,'$.SOAT') WHEN 'true' THEN 1 ELSE 0 END
                        , IDCONTRATANTE   = JSON_VALUE(@AUT ,'$.IDCONTRATANTE.value')           , IDPLAN = JSON_VALUE(@AUT ,'$.IDPLAN.value')                        , DXRELACIONADO = JSON_VALUE(@AUT ,'$.DXRELACIONADO.value')
                        , NIVELATENCION   = JSON_VALUE(@AUT ,'$.NIVELATENCION.value')
                        , IDAREA          = @IDAREA          , NUMAUTORIZA = JSON_VALUE(@AUT ,'$.NUMAUTORIZA')               , FECHAAUTORIZA = COALESCE( REPLACE(JSON_VALUE(@AUT ,'$.FECHAAUTORIZA'),'-','') , NULL)
                        , MENTREGA        = JSON_VALUE(@AUT ,'$.MENTREGA')                , COPAGOPROPIO = CASE JSON_VALUE(@AUT ,'$.COPAGOPROPIO') WHEN 'true' THEN 1 ELSE 0 END                        , VALORCOPAGO = JSON_VALUE(@AUT ,'$.VALORCOPAGO')
                        , TIPOCOPAGO      = JSON_VALUE(@AUT ,'$.TIPOCOPAGO.value')           , CNSHACTRAN =  COALESCE( JSON_VALUE(@AUT ,'$.CNSHACTRAN'), NULL)      
					   , IDSOLICITANTE = COALESCE(JSON_VALUE(@AUT ,'$.IDSOLICITANTE') , CASE WHEN EXISTS (SELECT * FROM USUSU WHERE USUARIO = @USUARIO AND COALESCE( USUSU.IDMEDICO,'')  <> '' ) THEN (SELECT IDMEDICO FROM USUSU WHERE USUARIO = @USUARIO) ELSE (SELECT USUARIO FROM USUSU WHERE USUARIO = @USUARIO) END )
					   , FECHAVENCE = REPLACE(JSON_VALUE(@AUT ,'$.FECHAVENCE'),'-',''), FECHA = REPLACE(JSON_VALUE(@AUT ,'$.FECHA'),'-','') --STORRES
            WHERE  AUT.IDAUT = JSON_VALUE(@AUT ,'$.IDAUT') 
               IF (SELECT FECHAAUTORIZA FROM AUT WHERE  AUT.IDAUT = JSON_VALUE(@AUT ,'$.IDAUT') ) = '1900-01-01 00:00:00.000'
                  UPDATE AUT SET FECHAAUTORIZA =  NULL WHERE AUT.IDAUT = JSON_VALUE(@AUT ,'$.IDAUT') 

			   SELECT @VIGENCIA = 30
			   IF (SELECT COALESCE(AUT.FECHA,'') FROM AUT WHERE IDAUT = JSON_VALUE(@AUT ,'$.IDAUT')  ) = '' OR (SELECT CONVERT(DATE, AUT.FECHAVENCE) FROM AUT WHERE IDAUT = JSON_VALUE(@AUT ,'$.IDAUT') ) = '19000101'
				   UPDATE AUT SET FECHAVENCE = FECHA + @VIGENCIA WHERE IDAUT = JSON_VALUE(@AUT ,'$.IDAUT')  	

            -- PARA EL ACCIDENTE DE TRANSITO					
				
			   SELECT @CONSECUTIVO = NOAUT FROM AUT WHERE  AUT.IDAUT = JSON_VALUE(@AUT ,'$.IDAUT')
			   SELECT @VALORTOTAL = SUM(COALESCE(CANTIDAD,0) * COALESCE( VALOR,0)) FROM AUTD WHERE  AUTD.IDAUT = JSON_VALUE(@AUT ,'$.IDAUT')
			   --SELECT @VALORTOTAL
			  -- SELECT TOP 100   * FROM AUTD WHERE  AUTD.IDAUT = JSON_VALUE(@AUT ,'$.IDAUT')
			   IF ( COALESCE(@CNSHACTRAN ,'' ) <>'' )
			   BEGIN
				   IF ( SELECT COUNT(*) FROM HACTRAND WHERE  CNSHACTRAN	=@CNSHACTRAN AND PROCEDENCIA='CE'	AND NOREFERENCIA = @CONSECUTIVO ) >0  -- YA EXISTE EL MISMO CNSHACTRAN PARA ESA CITA SOLO ACTUALIZO EL SIRAS
				   BEGIN
						   PRINT 'SOLO CAMBIO EL SIRAS '
						   UPDATE HACTRAND SET  SIRAS = @SIRAS  WHERE  CNSHACTRAN	=@CNSHACTRAN AND PROCEDENCIA='CE'	AND NOREFERENCIA = @CONSECUTIVO
					   END
				   ELSE
				   BEGIN
				   -- YA HAY UN CNSHACTRAN PARA LA CITA PERO NO ES EL MISMO POR LO QUE LO ESTAMOS CAMBIANDO
					   IF ( SELECT COUNT(*) FROM HACTRAND WHERE  PROCEDENCIA='CE'	AND NOREFERENCIA = @CONSECUTIVO ) >0  
					   BEGIN
						   PRINT 'CAMBIO EL CNSHACTRAN Y EL SIRAS'
						   UPDATE HACTRAND SET  SIRAS = @SIRAS , CNSHACTRAN	= @CNSHACTRAN   WHERE   PROCEDENCIA='CE'	AND NOREFERENCIA = @CONSECUTIVO
					   END
					   ELSE
					   BEGIN
						   PRINT 'AGREGO UN NUEVO DETALLE DE HACTRAND CON EL NUEVO CONSUMO'

						   SELECT @ITEM = COUNT(ITEM)+1 FROM HACTRAND WHERE  CNSHACTRAN	=@CNSHACTRAN 
						   INSERT INTO HACTRAND ( CNSHACTRAN, ITEM, PROCEDENCIA,  NOREFERENCIA , N_FCT_ASEG, VLRGASTADO, SIRAS	)
							   VALUES  ( @CNSHACTRAN ,  @ITEM , 'CE' , @CONSECUTIVO , NULL , @VALORTOTAL  , @SIRAS   )
					   END
				   END
			   END
			   ELSE
			   BEGIN
				   PRINT 'LE QUITO QUE ES CITA SOAT'
				   UPDATE CIT SET CNSHACTRAN = NULL WHERE  CONSECUTIVO = @CONSECUTIVO
				   DELETE HACTRAND WHERE  CNSHACTRAN = @CNSHACTRAN AND PROCEDENCIA = 'CE' AND  NOREFERENCIA = @CONSECUTIVO 

			   END

            DELETE FROM AUTD WHERE NOT EXISTS (SELECT * FROM #AUTD WHERE AUTD.IDSERVICIO = #AUTD.IDSERVICIO AND AUTD.IDAUT = #AUTD.IDAUT) AND AUTD.IDAUT = JSON_VALUE(@AUT ,'$.IDAUT')

            IF EXISTS ( SELECT *FROM  #AUTD WHERE #AUTD.PROCESO = 'Insertar') --VALOR
            BEGIN
				PRINT 'INSERTA ====== =>'
               SELECT ROW_NUMBER() OVER(ORDER BY IDSERVICIO DESC) AS FILA_CITA,  AQUIENCOBRO
                  ,PROCESO,  IDAUT, NO_ITEM, IDSERVICIO, DESCSERVICIO, CODCUPS, CANTIDAD, MDOSIFICACION, CLASEPOSOLOGIA, CANTIDIA, FRECUENCIA, DIAS
                  , PRIORIDAD, COMENTARIOS, NOAUTORIZEXT, IDTERCEROCA, IDPLAN, APOYODG_AMBITO, (SELECT VALOR FROM OPENJSON(CCOSTO) WITH (VALOR VARCHAR(20) '$.value')) CCOSTO
                  , IDARTICULO, IDARTICULOSER, CNSFMED, CITAAUTORIZADA, POSOLOGIA, IDTERCEROCADESC, REQAUTORIZACION, CANTMINIMA, CANTMAXIMA, IDADMINISTRADORA , VALOR
                  INTO #AUTD_NEW
               FROM #AUTD_NUEVO WHERE #AUTD_NUEVO.PROCESO = 'Insertar'
				PRINT 'INSERTA /////////////////////'

			  --SELECT IDPLAN, IDTERCEROCA,   * FROM #AUTD_NEW --VALOR
               DECLARE @ITEM_AUTD INT
               DECLARE @LIMITE_AU INT
                  SELECT @ITEM_AUTD=1,@LIMITE_AU=0
                  SELECT @LIMITE_AU=COUNT(*) FROM  #AUTD_NEW

               WHILE @ITEM_AUTD<=@LIMITE_AU
               BEGIN
					IF (SELECT COUNT(*) FROM AUTD WHERE IDAUT = JSON_VALUE(@AUT ,'$.IDAUT')) = 0 
					BEGIN
					PRINT 'GO 11'
						SET @CONT = 1
					END
					ELSE 
					BEGIN
					PRINT 'GO 22'
						SELECT @CONT = (SELECT TOP 1 NO_ITEM FROM AUTD WHERE IDAUT = JSON_VALUE(@AUT ,'$.IDAUT') ORDER BY  AUTD.NO_ITEM   DESC ) + 1 
					END
					PRINT 'GO'
                  INSERT INTO AUTD (IDAUT           ,NO_ITEM          ,IDSERVICIO     ,CANTIDAD       ,VALOR            ,VALORCOPAGO  ,VALORCOPAGOCOSTO ,VALOREXCEDENTE ,
                                    VALORTOTALCOSTO ,IDPLAN           ,IMPRESO        ,AUTORIZADO     ,COMENTARIOS      ,PCOBERTURA   ,OBS              ,NORDEN ,
                                    CCOSTO          ,CODIGOCPCJ       ,MARCAPAGO      ,NOAUTORIZEXT   ,ESDELAB          ,ENLAB        ,IDTERCEROCA      ,IDCONTRATO ,
                                    FACTURADA       ,N_FACTURA        ,CNSFCT         ,AQUIENCOBRO    ,MARCACOPAGOORDEN ,VALORPROV    ,PCOSTO           ,ITFC ,
                                    CNSITFC         ,SYS_COMPUTERNAME ,NOCOBRABLE     ,MDOSIFICACION  ,CANTIDIA         ,DIAS         ,FRECUENCIA       ,CODCUPS ,
                                    POSOLOGIA       ,SINCRONIZADO     ,APOYODG_AMBITO ,CITAAUTORIZADA ,DOSISAPL         ,DURACIONTTOF ,DURACIONTTOC     ,CLASEPOSOLOGIA ,
                                    MARCA           ,USUARIOMARCA     ,NUM_ORDEN      ,PROCESADA      ,PRIORIDAD        ,HOMOLOGO     ,IDSERVICIOH      ,CANTIDADH ,
                                    VALORHOMO       ,NO_ITEMH         ,N_FACTURAORI   ,DESCUENTO      ,TIPODTO          ,CNSFMED      ,F_INGLAB         ,F_SALILAB ,
                                    IDARTICULO      ,IMPORTADO ) 
                  SELECT JSON_VALUE(@AUT ,'$.IDAUT') 
                        , @CONT   
                        , IDSERVICIO ,CANTIDAD
                        , COALESCE(#AUTD_NEW.VALOR,0), 0, 0, 0,  0
                        , IDPLAN , 0 ,1 , COMENTARIOS      , 100 ,NULL, NULL , CCOSTO
                         , NULL ,0  , NOAUTORIZEXT , 0,0 , IDTERCEROCA , NULL
                         , 0, NULL ,NULL  , AQUIENCOBRO     , 0 ,0 ,0 ,0 ,NULL ,@SYS_COMPUTERNAME, 0 , MDOSIFICACION
                         , CANTIDIA , DIAS   , FRECUENCIA , CODCUPS  , POSOLOGIA      
                         , 0 , APOYODG_AMBITO   , CITAAUTORIZADA   , DOSISAPL = NULL,DURACIONTTOF = NULL,DURACIONTTOC = NULL
                         , CLASEPOSOLOGIA   , 0 ,NULL ,NULL ,0 , PRIORIDAD ,NULL ,NULL ,NULL , NULL, NULL ,NULL ,NULL ,NULL ,NULL , NULL ,NULL
                         , IDARTICULO       , 0
                  FROM   #AUTD_NEW WHERE #AUTD_NEW.FILA_CITA = @ITEM_AUTD
                  SELECT @ITEM_AUTD = @ITEM_AUTD+1 

               END
			   PRINT 'SALE DE INSERTAR'
            END
			IF EXISTS ( SELECT *FROM  #AUTD WHERE #AUTD.PROCESO = 'Editar')
            BEGIN
				PRINT 'EDITAR ===>'
               SELECT ROW_NUMBER() OVER(ORDER BY IDSERVICIO DESC) AS FILA_CITA,  AQUIENCOBRO
                     ,PROCESO,  IDAUT, NO_ITEM, IDSERVICIO, DESCSERVICIO, CODCUPS, CANTIDAD, MDOSIFICACION, CLASEPOSOLOGIA, CANTIDIA, FRECUENCIA, DIAS
                     ,PRIORIDAD, COMENTARIOS, NOAUTORIZEXT, IDTERCEROCA, IDPLAN, APOYODG_AMBITO, (SELECT VALOR FROM OPENJSON(CCOSTO) WITH (VALOR VARCHAR(20) '$.value')) CCOSTO
                     ,IDARTICULO, IDARTICULOSER, CNSFMED, CITAAUTORIZADA, POSOLOGIA, IDTERCEROCADESC, REQAUTORIZACION, CANTMINIMA, CANTMAXIMA, IDADMINISTRADORA
               INTO #AUTD_EDITAR
               FROM #AUTD_NUEVO WHERE #AUTD_NUEVO.PROCESO = 'Editar'

               DECLARE @ITEM_AUTD_EDITAR INT
               DECLARE @LIMITE_AU_EDITAR INT
               SELECT  @ITEM_AUTD_EDITAR =1,@LIMITE_AU_EDITAR=0
               SELECT  @LIMITE_AU_EDITAR = COUNT(*) FROM  #AUTD_EDITAR

               WHILE @ITEM_AUTD_EDITAR<=@LIMITE_AU_EDITAR
               BEGIN
                  UPDATE AUTD SET
				            AUTD.CANTIDAD = #AUTD_EDITAR.CANTIDAD
				           ,AUTD.MDOSIFICACION = #AUTD_EDITAR.MDOSIFICACION
				           ,AUTD.CANTIDIA = #AUTD_EDITAR.CANTIDIA
				           ,AUTD.DIAS = #AUTD_EDITAR.DIAS
				           ,AUTD.FRECUENCIA = #AUTD_EDITAR.FRECUENCIA
				           ,AUTD.POSOLOGIA = #AUTD_EDITAR.POSOLOGIA
				           ,AUTD.PRIORIDAD = #AUTD_EDITAR.PRIORIDAD
				           ,AUTD.COMENTARIOS = #AUTD_EDITAR.COMENTARIOS
				           ,AUTD.CCOSTO = #AUTD_EDITAR.CCOSTO
				           ,AUTD.CITAAUTORIZADA = #AUTD_EDITAR.CITAAUTORIZADA
				           ,AUTD.AQUIENCOBRO = #AUTD_EDITAR.AQUIENCOBRO
				           ,AUTD.NOAUTORIZEXT = #AUTD_EDITAR.NOAUTORIZEXT
				           ,AUTD.CLASEPOSOLOGIA = #AUTD_EDITAR.CLASEPOSOLOGIA
				           FROM #AUTD_EDITAR WHERE   AUTD.IDSERVICIO = #AUTD_EDITAR.IDSERVICIO AND AUTD.IDAUT = #AUTD_EDITAR.IDAUT
                           SELECT @ITEM_AUTD_EDITAR = @ITEM_AUTD_EDITAR+1 
               END
            END

            ------ BEGIN EDITAR DATOS PAGOS DESDE AQUI 
            SELECT @FECHAAUT = FECHA FROM AUT WHERE IDAUT = @CNSIDAUT
			--SELECT TOP 100 VALORCOPAGO, VALOR,   * FROM AUTD WHERE IDAUT = @CNSIDAUT
				--CLOSE AUTD_C
				--DEALLOCATE AUTD_C
            
            DECLARE AUTD_C_2 CURSOR FOR 
            SELECT IDAUT ,NO_ITEM 
            FROM   AUTD 
            WHERE  IDAUT = @CNSIDAUT
            OPEN AUTD_C_2
            FETCH NEXT FROM AUTD_C_2 INTO @IDAUT_CUR ,@NO_ITEM_CUR
            WHILE @@FETCH_STATUS = 0
            BEGIN
               PRINT 'INGRESE AL CURSOR ==' +STR(@VEZ)

               SELECT @IDSERVICIO_CUR = IDSERVICIO ,@VALORAUTD_CUR = VALOR FROM AUTD WHERE IDAUT = @CNSIDAUT AND NO_ITEM = @NO_ITEM_CUR
               PRINT '@IDSERVICIO_CUR ='+@IDSERVICIO_CUR
               SELECT @PYP_CUR       = CASE WHEN CLASEORDEN = 'PyP' THEN 1 ELSE 0 END 
                     ,@ALTOCOSTO_CUR = CASE WHEN ALTOCOSTO  = 'Si'  THEN 1 ELSE 0 END   
               FROM   AUT WHERE IDAUT = @CNSIDAUT  
			   --SELECT @IDSERVICIO_CUR
			   PRINT '@IDAFILIADO' + str(@IDAFILIADO)
			   PRINT '@@CNSIDAUT' + str(@CNSIDAUT)
			   PRINT '@@NO_ITEM_CUR' + str(@NO_ITEM_CUR)
			   PRINT '@@IDSERVICIO_CUR ' + @IDSERVICIO_CUR
			   PRINT '@@PYP_CUR' + str(@PYP_CUR)
			   PRINT '@@ALTOCOSTO_CUR' + str(@ALTOCOSTO_CUR)
			   PRINT '@@VALORAUTD_CUR' + str(@VALORAUTD_CUR)
			   PRINT '@@IDAREA' + str(@IDAREA)
               EXEC SPK_COPAGO_AUT_CEHOSP @IDAFILIADO, @CNSIDAUT ,@NO_ITEM_CUR ,@IDSERVICIO_CUR ,@PYP_CUR ,@ALTOCOSTO_CUR ,@VALORAUTD_CUR
                                          ,'CE' ,@SYS_COMPUTERNAME ,'01' ,@IDSEDE , @USUARIO, NULL, @IDAREA ,@FECHAAUT, 0, 0
               SELECT @VEZ += 1
               FETCH NEXT FROM AUTD_C_2 INTO @IDAUT_CUR ,@NO_ITEM_CUR
            END
            CLOSE AUTD_C_2
            DEALLOCATE AUTD_C_2

			--SELECT TOP 100 VALORCOPAGO, VALOR,   * FROM AUTD WHERE IDAUT = @CNSIDAUT

            --CALCULO DE TOTALES DE AUT
            UPDATE AUT SET VALORTOTAL = (SELECT SUM(VALOR) FROM AUTD WHERE IDAUT = @CNSIDAUT) 
                  ,NO_ITEMES = (select COUNT( IDSERVICIO) from autd where IDAUT = @CNSIDAUT ) 
            WHERE AUT.IDAUT = @CNSIDAUT
            --DECLARE @VRTOTCOPAGO DECIMAL(14,2)


            IF (SELECT COALESCE(COPAGOPROPIO,0) FROM AUT WHERE IDAUT = @CNSIDAUT) = 0
            BEGIN
               IF (SELECT SUM(VALORCOPAGO) FROM AUTD WHERE AUTD.IDAUT = @CNSIDAUT)>0
               BEGIN
                  IF (SELECT VALORCOPAGO FROM AUTD WHERE AUTD.IDAUT =  @CNSIDAUT AND MARCACOPAGOORDEN = 1  ) >0
                  BEGIN
                     SELECT @VRTOTCOPAGO = VALORCOPAGO FROM AUTD WHERE AUTD.IDAUT =  @CNSIDAUT AND MARCACOPAGOORDEN = 1
                     UPDATE AUT SET VALORCOPAGO = @VRTOTCOPAGO , TIPOCOPAGO = 'M' WHERE IDAUT = @CNSIDAUT
                  END
                  ELSE
                  BEGIN
                     SELECT @VRTOTCOPAGO = SUM(VALORCOPAGO) FROM AUTD WHERE AUTD.IDAUT = @CNSIDAUT
                     UPDATE AUT SET VALORCOPAGO = @VRTOTCOPAGO , TIPOCOPAGO = 'C' WHERE IDAUT = @CNSIDAUT
                  END
               END
               ELSE
               BEGIN
                  UPDATE AUT SET VALORCOPAGO = 0 , TIPOCOPAGO = 'N' WHERE IDAUT = @CNSIDAUT 
               END
            END



            SELECT @IDCONTRATANTE_AUT = IDCONTRATANTE ,@IDPROVEEDOR_AUT = IDPROVEEDOR ,@IDPLAN_AUT = IDPLAN ,@PREFIJO_AUT = PREFIJO ,@VALORCOPAGO_AUT = VALORCOPAGO
                  ,@GENEROCAJA_AUT    = GENEROCAJA  
            FROM   AUT WHERE IDAUT = @CNSIDAUT

            SELECT @EXCOBROPC=EXCOBROPC, @LIQUIDARPC=LIQUIDARPC, @COBRARPC = COBRARPC FROM VW_PXS  --CMT VW_PXS
            WHERE  IDADMINISTRADORA = @IDCONTRATANTE_AUT
            AND    IDTERCERO        = @IDPROVEEDOR_AUT AND IDPLAN = @IDPLAN_AUT
            AND    PREFIJO          = @PREFIJO_AUT 


            if DBO.FNK_valorvariable('CETIPOAUTORIZACION') = 'CEHOSP'
            BEGIN
               IF (SELECT TIPOCAJA FROM AUT WHERE IDAUT = @CNSIDAUT) <>'FCJ'
               BEGIN
                  PRINT 'VOY PARA SPK_PAGOSCAJA_AUT_CEHOSP '
                  EXEC SPK_PAGOSCAJA_AUT_CEHOSP @CNS,@SYS_COMPUTERNAME, '01',@IDSEDE, @USUARIO, 1  --CMT AUT
               END
            END
            ELSE
            BEGIN
               IF (SELECT COALESCE(TER.ENVIODICAJA,0) FROM AUT INNER JOIN TER ON AUT.IDTERCEROCA = TER.IDTERCERO WHERE AUT.IDAUT = @CNSIDAUT) = 1
               BEGIN
                  PRINT 'VOY A SPK_PAGOSCAJA_AUT (1)'
                  EXEC SPK_PAGOSCAJA_AUT @CNS,@SYS_COMPUTERNAME,'01',@IDSEDE, @USUARIO, 1
               END
               ELSE
               BEGIN
                  IF @VALORCOPAGO_AUT > 0 AND @COBRARPC = 1
                  BEGIN
                     If @GENEROCAJA_AUT <> 1 
                     BEGIN
                        PRINT 'VOY A SPK_PAGOSCAJA_AUT (0)'
                        EXEC SPK_PAGOSCAJA_AUT @CNS,@SYS_COMPUTERNAME,'01',@IDSEDE,@USUARIO,0
                     END
                  END
               END
            END

            ------ BEGIN EDITAR DATOS PAGOS HASTA AQUI

            SELECT 'OK' OK

            RETURN
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
--query2
   IF @METODO = 'VER_REPORTE_AUT'
   BEGIN
	   SELECT @IDAUT = IDAUT
      FROM OPENJSON(@PARAMETROS)WITH(        IDAUT      VARCHAR(20)            '$.IDAUT' )

      IF (SELECT COUNT(*) FROM @TBLERRORES)> 0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END
      ELSE
      BEGIN
         BEGIN TRY --FECHA, FECHAVENCE
            SELECT  'OK'OK,  AUT.PEDIDOINV ,AUT.IDAUT ,AUT.NOAUT ,AUT.FECHA , AUT.PREFIJO, PRE.NOM_PREFIJO
               ,AUT.VALORTOTAL ,AUT.DESCUENTO ,AUT.VALORCOPAGO ,(AUT.VALORTOTAL - AUT.DESCUENTO) VR_TOTAL ,AUT.N_FACTURA,AUT.IDCONTRATANTE ,TER.RAZONSOCIAL
               ,AUT.IDPLAN  ,PLN.DESCPLAN ,AUT.ESTADO ,AUT.GENEROCAJA,AUT.CERRADA ,AUT.FACTURADA  ,AUT.CLASEORDEN ,AUT.ALTOCOSTO 
			   ,AUT.IDPROVEEDOR, PRO.RAZONSOCIAL [PRO_DESC], CIUPRO.NOMBRE [CIUPRO_DESC], PRO.TELEFONOS [PRO_TELEFONO], PRO.DIRECCION [PRO_DIRECCION]
               ,AUT.COPAGOPROPIO ,AUT.SOAT ,AUT.TIPOCAJA ,AUT.CODCAJA ,AUT.NORECIBOCAJA,AUT.CONTABILIZADA ,AUT.CNSHACTRAN ,AUT.ESDEINV ,AUT.IMPRESO ,AUT.USUARIO,AUT.TIPOCOPAGO
               ,AUT.IDSEDE     ,SED.DESCRIPCION NOMBRESEDE,AUT.FECHAVENCE,AUT.ENPAQUETE,AUT.TIPOAUTORIZACION,AUT.ATENCION,AUT.NOADMISION,AUT.IMPUTABLE_A
               ,AUT.IDPESPECIAL,AUT.URGENCIA,AUT.NIVELATENCION,AUT.RIESGO,PRO.RAZONSOCIAL NOMBREPROVEEDOR,AUT.NUMAUTORIZA,AUT.AUTORIZADOPOR,AUT.FECHAAUTORIZA,AUT.MENTREGA,AUT.IDIPSSOLICITA,AUT.IDMEDICOSOLICITA,AUT.IDCLASEAUT
               ,AFI.IDAFILIADO, AFI.TIPO_DOC, AFI.DOCIDAFILIADO, AFI.NOMBREAFI, AFI.IDADMINISTRADORA, TERAFI.RAZONSOCIAL AFI_RAZONSOCIAL, AFI.EDAD, AFI.SEXO, AFI.EMAIL, AFI.DIRECCION
               ,OCU.OCUPACION, OCU.DESCRIPCION OCU_DESC, AUT.AUTORIZADO, AFISED.IDSEDE AFI_IDSEDE , AFISED.DESCRIPCION AFI_SED_DESC, TGEN.CODIGO GRUPO_CODIGO , TGEN.DESCRIPCION GRUPO_DESC, AFI.GRUPO_SANG
               ,ESCOLA.CODIGO ESCOLA_CODIGO, ESCOLA.DESCRIPCION ESCOLA_DESC, AFI.TELEFONORES, AFI.FECHAAFILIACION, USUSU.NOMBRE USUARIO_NOM,MED.NOMBRE NOMBREMEDICO,AUT.IDSOLICITANTE, MES.DESCRIPCION ESPECI_DESC, MED.NO_REGISTRO
               ,AUT.IDAREA, AFU.DESCRIPCION [AFU_DESC] ,AUT.CLASECONTRATO, CASE WHEN AUT.CLASECONTRATO = 'E' THEN 'Evento' WHEN AUT.CLASECONTRATO = 'C' THEN 'Capitado'  END CLASECONTRATO_DESC
               ,AUT.IDCAUSAEXT, CAU_EXT.DESCRIPCION [CAU_DESC]              
               ,AUT.CLASECONT , CASE WHEN AUT.CLASECONT = 'ENGE' THEN 'Enfermedad General' WHEN AUT.CLASECONT = 'ATEP' THEN 'ATEP' WHEN AUT.CLASECONT = 'SOAT' THEN 'SOAT' WHEN AUT.CLASECONT = 'MATE' THEN 'Maternidad' ELSE AUT.CLASECONT END [CLASECONT_DESC]
               ,AUT.FINALIDAD, FINA.DESCRIPCION [FINA_DESC] ,AUT.AMBITO, AMBI.DESCRIPCION [AMBI_DESC], AUT.PERSONAL_AT, PER_AT.DESCRIPCION [PER_AT_DESC], AUT.CCOSTO, CEN.DESCRIPCION [CEN_DESC]
               ,AUT.TIPOAFILIADO , CASE WHEN AUT.TIPOAFILIADO = 'C' THEN 'Cotizante' WHEN AUT.TIPOAFILIADO = 'B' THEN 'Beneficiario' WHEN AUT.TIPOAFILIADO = 'J' THEN 'Jubilado' WHEN AUT.TIPOAFILIADO = 'A' THEN 'Adicional' WHEN AUT.TIPOAFILIADO = 'S' THEN 'Sustitución Pensional' WHEN AUT.TIPOAFILIADO = 'Sb' THEN 'Subsidiado' END [TIPOAFILIADO_DESC]
               ,AUT.DXPPAL, MDX_DXPPAL.DESCRIPCION [DXPPAL_DESC], AUT.DXRELACIONADO, MDX_DXRELACIONADO.DESCRIPCION [DXRELACIONADO_DESC], AUT.COMPLICACION, MDX_COMPLICACION.DESCRIPCION [COMPLICACION_DESC]
			   ,CONCAT   (floor(cast(datediff(day, FNACIMIENTO, getdate()) as float)/365),' años ', floor((cast(datediff(day, FNACIMIENTO, getdate()) as float)/365-(floor(cast(datediff(day, FNACIMIENTO, getdate()) as float)/365)))*12), ' meses '
			   ,floor((((cast(datediff(day, AFI.FNACIMIENTO, getdate()) as float)/365-(floor(cast(datediff(day, AFI.FNACIMIENTO, getdate()) as float)/365)))*12)-floor((cast(datediff(day, AFI.FNACIMIENTO, getdate()) as float)/365-(floor(cast(datediff(day, AFI.FNACIMIENTO, getdate()) as float)/365)))*12))*(365/12)), ' días' ) AS EDAD_LARGO
			   , DATEPART(HOUR, AUT.FECHA) HORA
			   , Format(AUT.FECHA,'dd/MM/yyyy hh:mm tt') AS FECHA_HORARIO, IDFIRMAPTE, IDFIRMARESP
            FROM AUT
               INNER JOIN PRE ON AUT.PREFIJO = PRE.PREFIJO
               LEFT JOIN MED ON AUT.IDSOLICITANTE = MED.IDMEDICO
               LEFT JOIN MES ON MED.IDEMEDICA = MES.IDEMEDICA
               LEFT JOIN TER ON AUT.IDCONTRATANTE = TER.IDTERCERO
               LEFT JOIN PLN ON AUT.IDPLAN        = PLN.IDPLAN
               LEFT JOIN SED ON AUT.IDSEDE        = SED.IDSEDE
               LEFT JOIN TER PRO ON AUT.IDPROVEEDOR   = PRO.IDTERCERO
			   LEFT JOIN CIU CIUPRO ON PRO.CIUDAD = CIUPRO.CIUDAD
               LEFT JOIN AFI ON AUT.IDAFILIADO    = AFI.IDAFILIADO
               LEFT JOIN TER TERAFI ON AFI.IDADMINISTRADORA = TERAFI.IDTERCERO
               LEFT JOIN OCU ON AFI.IDOCUPACION = OCU.OCUPACION
               LEFT JOIN SED AFISED ON AFI.IDSEDE = AFISED.IDSEDE
               LEFT JOIN TGEN ON AFI.GRUPOPOB = TGEN.CODIGO AND TGEN.TABLA = 'General' AND TGEN.CAMPO = 'GRUPOPOB'
               LEFT JOIN TGEN ESCOLA ON AFI.IDESCOLARIDAD = ESCOLA.CODIGO AND ESCOLA.TABLA = 'AFI' AND ESCOLA.CAMPO = 'ESCOLARIDAD'
               LEFT JOIN USUSU ON AUT.USUARIO = USUSU.USUARIO
               LEFT JOIN CEN ON AUT.CCOSTO = CEN.CCOSTO
               LEFT JOIN TGEN CAU_EXT ON AUT.IDCAUSAEXT = CAU_EXT.CODIGO AND CAU_EXT.TABLA = 'General' AND CAU_EXT.CAMPO = 'CAUSAEXTERNA'
               LEFT JOIN TGEN AMBI ON AUT.AMBITO = AMBI.CODIGO AND AMBI.CAMPO = 'AMBITO' AND AMBI.TABLA = 'General'
               LEFT JOIN TGEN FINA ON AUT.FINALIDAD = FINA.CODIGO AND FINA.CAMPO = 'FINALIDAD' AND FINA.TABLA = 'General'
               LEFT JOIN TGEN PER_AT ON AUT.PERSONAL_AT = PER_AT.CODIGO AND PER_AT.CAMPO = 'PERSONAL_AT' AND PER_AT.TABLA = 'General'
               LEFT JOIN AFU ON AUT.IDAREA = AFU.IDAREA
               LEFT JOIN MDX MDX_DXPPAL ON AUT.DXPPAL = MDX_DXPPAL.IDDX
               LEFT JOIN MDX MDX_DXRELACIONADO ON AUT.DXRELACIONADO = MDX_DXRELACIONADO.IDDX
               LEFT JOIN MDX MDX_COMPLICACION ON AUT.COMPLICACION = MDX_COMPLICACION.IDDX
               
          WHERE AUT.IDAUT = @IDAUT

               --DETALLE
               SELECT AUTD.ID, AUTD.IDAUT, AUTD.NO_ITEM, AUTD.IDSERVICIO ,AUTD.CANTIDAD ,AUTD.VALOR ,AUTD.VALORCOPAGO ,AUTD.VALORCOPAGOCOSTO ,AUTD.VALOREXCEDENTE
                  ,AUTD.VALORTOTALCOSTO,AUTD.IDPLAN,AUTD.AUTORIZADO,CASE WHEN AUTD.AUTORIZADO = 1 THEN 'Autorizado' ELSE 'No Autorizado' END AUTORIZADO_DESC ,AUTD.COMENTARIOS ,AUTD.NORDEN ,AUTD.CCOSTO ,AUTD.FACTURADA ,AUTD.N_FACTURA ,AUTD.AQUIENCOBRO
                  ,AUTD.CODCUPS ,AUTD.CLASEPOSOLOGIA ,AUTD.CANTIDIA ,AUTD.FRECUENCIA ,AUTD.DIAS ,AUTD.PRIORIDAD ,AUTD.IDTERCEROCA ,AUTD.APOYODG_AMBITO
                  ,SER.DESCSERVICIO, COALESCE(LTRIM(RTRIM(SER.COMENTARIOS)),'') [SER_COMENTARIOS], CONCAT(AUTD.IDSERVICIO,': ',SER.DESCSERVICIO) [IDSERVICIO_NOMBRE]
               FROM   AUTD LEFT JOIN SER ON AUTD.IDSERVICIO = SER.IDSERVICIO
               WHERE  AUTD.IDAUT = @IDAUT
         
         END TRY  
	      BEGIN CATCH 
		      INSERT INTO @TBLERRORES(ERROR) SELECT ERROR_MESSAGE() ;  
	      END CATCH
	      IF (SELECT COUNT(*) FROM @TBLERRORES)> 0
	      BEGIN
		      SELECT 'KO' OK
		      SELECT ERROR FROM @TBLERRORES
		      RETURN
	      END	
	      SELECT 'OK'OK
       END
   END 
	IF @METODO = 'DATO_IMPRIMIR_RECIBO_ASEGURADO'
	BEGIN
	   SELECT @CONSECUTIVO =  CONSECUTIVO ,@CNSFACJ = CNSFACJ , @CODCAJA = CODCAJA, @PROCEDENCIA = PROCEDENCIA
	   FROM OPENJSON (@PARAMETROS)
	   WITH (
            CNSFACJ			VARCHAR(20)    '$.CNSFACJ',
            CODCAJA			VARCHAR(4)     '$.CODCAJA',
            PROCEDENCIA		VARCHAR(50)    '$.PROCEDENCIA',
            CONSECUTIVO		VARCHAR(20)    '$.CONSECUTIVO'
           )
      --SELECT @CODCAJA = CODCAJA, @CNSFACJ = CNSFACJ FROM FCJ WHERE  NOADMISION = @CONSECUTIVO
		SELECT 'OK'OK,@PROCEDENCIA PROCEDENCIA ,FCJ.NOADMISION CONSECUTIVO, AFI.TIPO_DOC, AFI.DOCIDAFILIADO,COALESCE( AFI.NOMBREAFI, CJR.DESCRIPCION)NOMBREAFI , AFI.DIRECCION, AFI.SEXO, FCJ.IDPLAN, PLN.DESCPLAN, FCJ.IDTERCERO, TER.RAZONSOCIAL
							, CASE WHEN DBO.FNK_VALORVARIABLE('IDTERCEROPARTICULAR') = FCJ.IDTERCERO THEN 1 ELSE 0 END ESPART
				            , AFI.CELULAR, AFI.TELEFONORES,AFI.EDAD, COALESCE( AFI.IDALTERNA,'')IDALTERNA , CIUAFI.NOMBRE [CIU_NOMBRE], AFI.EMAIL, AFI.IDTIPOAFILIACION,AFI.ESTADO_CIVIL
				            , NIVELSOCIOEC, AFI.TIPOAFILIADO
							, CASE   WHEN AFI.TIPOAFILIADO = 'C' THEN 'Cotizante'
                                 WHEN AFI.TIPOAFILIADO = 'B' THEN 'Beneficiario'
                                 WHEN AFI.TIPOAFILIADO = 'J' THEN 'Jubilado'
                                 WHEN AFI.TIPOAFILIADO = 'A' THEN 'Adicional'
                                 WHEN AFI.TIPOAFILIADO = 'S' THEN 'Sustitución Pensional'
                                 WHEN AFI.TIPOAFILIADO = 'Sb' THEN 'Subsidiado'
                                 WHEN AFI.TIPOAFILIADO = 'SR' THEN 'Sin régimen'
                                 WHEN AFI.TIPOAFILIADO = 'TA' THEN 'Tomador/Amparado'
                                 WHEN AFI.TIPOAFILIADO = 'RE' THEN 'Régimen Especiales o de Excepción'
                                 WHEN AFI.TIPOAFILIADO = 'SN' THEN 'S/N'
                                 WHEN AFI.TIPOAFILIADO = 'S/' THEN 'S/N'
                                 WHEN AFI.TIPOAFILIADO = 'S/N' THEN 'S/N' ELSE '' END [TIPOAFI_NOMBRE]
         ,CONVERT (DATE ,FCJ.FECHA) FECHA, CONVERT(varchar,FCJ.FECHA,104) FECHAFORMATO, CONVERT (DATETIME ,FCJ.FECHA) FECHACOMPLETA, DATEPART(HOUR, FCJ.FECHA) HORA
         , Format(FCJ.FECHA,'dd/MM/yyyy hh:mm tt') AS FECHA_HORARIO,   CONVERT(varchar,FCJ.FECHA,104) FECHACITA
         ,COALESCE(FCJ.OBSERVACION,'Sin Observacion') OBSERVACION, SED.IDSEDE, SED.DESCRIPCION [SED_NOMBRE], SED.DIRECCION [SED_DIRECCION]
         , SED.TELEFONOS [SED_TELEFONOS],  SED.DESCRIPCION [SED_CIUDAD], SED.NIT [SED_NIT], SED.DV [SED_DV]
         ,FCJ.N_RECIBO , FCJ.CNSFACJ, FCJ.CODCAJA, FCJ.CLASE_FAC, FCJ.NOADMISION, FCJ.VALORTOTAL,FCJ.ESTADO, FCJ.CERRADA
         ,FCJ.N_FACTURA, COALESCE(FCJ.USUARIO, CJR.CODCAJERO) USUARIO,COALESCE( USUSU.NOMBRE, CJR.DESCRIPCION) [USUSU_NOMBRE], USUSU.CODCAJERO [COD_CAJERO]
         FROM FCJ 
            LEFT JOIN USUSU ON FCJ.USUARIO = USUSU.USUARIO
			LEFT JOIN CJR ON FCJ.USUARIO = CJR.CODCAJERO
            LEFT JOIN AFI ON FCJ.IDAFILIADO = AFI.IDAFILIADO
            LEFT JOIN SED ON @IDSEDE = SED.IDSEDE
            LEFT JOIN TER ON FCJ.IDTERCERO = TER.IDTERCERO
            LEFT JOIN PLN ON FCJ.IDTERCERO = PLN.IDPLAN
            LEFT JOIN CIU CIUAFI ON AFI.CIUDAD = CIUAFI.CIUDAD
          WHERE FCJ.CNSFACJ = @CNSFACJ
          AND   FCJ.CODCAJA =@CODCAJA

         SELECT FCJ.NOADMISION, FCJD.CONCEPTO,  CPCJ.DESCRIPCION CONCEPTO_DESC,  FCJD.VALORUNITARIO, FCJD.CANTIDAD, FCJD.VALORTOTAL, FCJD.DCTO, FCJD.VLRDESCUENTO 
         FROM   FCJ INNER JOIN FCJD ON FCJ.CNSFACJ = FCJD.CNSFACJ 
                                   AND FCJ.CODCAJA = FCJD.CODCAJA  
                    INNER JOIN CPCJ ON FCJD.CONCEPTO = CPCJ.CODIGO
         WHERE  FCJ.CNSFACJ = @CNSFACJ
         AND    FCJ.CODCAJA = @CODCAJA

         
         SELECT PCJ.CODCAJA, PCJ.CNSPCJ, PCJ.CNSFACJ, PCJ.TIPOPAGO, FPA.DESCRIPCION, PCJ.VALOR, PCJ.FECHA, PCJ.CNSACJ,PCJ.BANCO,BCO.DESCRIPCION [BANCO_DESC], PCJ.NUMEROAUTORIZA, PCJ.NUMERODOCUMENTO
         FROM  PCJ 
            INNER JOIN FPA ON PCJ.TIPOPAGO=  FPA.FORMAPAGO 
            LEFT JOIN BCO ON PCJ.BANCO = BCO.BANCO
         WHERE  CODCAJA = @CODCAJA AND CNSFACJ = @CNSFACJ

          SELECT SUM(PCJ.VALOR) VALOR_FPA FROM PCJ  
          WHERE  CODCAJA = @CODCAJA AND CNSFACJ = @CNSFACJ

         --SELECT FCJD.CODCAJA, FCJD.CNSFACJ, FCJD.ITEM, FCJD.CONCEPTO, CPCJ.DESCRIPCION, FCJD.VALORUNITARIO, FCJD.CANTIDAD, FCJD.VALORTOTAL, FCJD.DCTO, FCJD.VLRDESCUENTO FROM FCJD 
         --   INNER JOIN CPCJ ON FCJD.CONCEPTO = CPCJ.CODIGO
         --WHERE FCJD.CODCAJA = @CODCAJA AND FCJD.CNSFACJ = @CNSFACJ

          SELECT TER.RAZONSOCIAL, FCJPCXC.CNSFACJ, FCJPCXC.CODCAJA, FCJPCXC.CNSCXC, FCJPCXC.N_FACTURA, FCJPCXC.ITEM_FCXCDV, FCJPCXC.IDTERCERO, FCJPCXC.VALOR, FCJPCXC.ESTADO, FCJPCXC.CNSFPAG
          , FCJPCXC.TIPOCXC, FCJPCXC.VLR_IMPUESTOS FROM  FCJPCXC
         LEFT JOIN TER ON FCJPCXC.IDTERCERO = TER.IDTERCERO
         WHERE  FCJPCXC.CODCAJA = @CODCAJA AND FCJPCXC.CNSFACJ = @CNSFACJ

         SELECT  FCJPCXC.CNSFACJ, FCJPCXC.CODCAJA,COALESCE( SUM(FCJPCXC.VALOR),0) VALOR, COALESCE(SUM( FCJPCXC.VLR_IMPUESTOS),0) IMPUESTO FROM  FCJPCXC
         WHERE FCJPCXC.CODCAJA = @CODCAJA AND FCJPCXC.CNSFACJ = @CNSFACJ
         GROUP BY FCJPCXC.CNSFACJ, FCJPCXC.CODCAJA
	END
	IF @METODO = 'FACTURA_AUT'     
	BEGIN   
      SELECT @IDAUT=IDAUT,@TIPOFAC=TIPOFACT      
      FROM   OPENJSON (@PARAMETROS)
      WITH (           
         IDAUT VARCHAR(20) '$.IDAUT',
         TIPOFACT VARCHAR(20) '$.TIPOFACT',
         RUC     VARCHAR(20) '$.RUC'
            )           
      IF NOT EXISTS(SELECT * FROM AUT WHERE IDAUT=@IDAUT)
      BEGIN
         SELECT 'KO' OK, 'No existe la Autorizacion' ERROR 
         RETURN
      END
      IF NOT EXISTS(SELECT * FROM AUTD WHERE IDAUT=@IDAUT)
      BEGIN
         SELECT 'KO' OK, 'Autorización sin detalles ' ERROR 
         RETURN
      END
      IF EXISTS(SELECT * FROM AUT WHERE IDAUT=@IDAUT AND COALESCE(FACTURADA,0)=1)
      BEGIN
         SELECT 'KO' OK, 'Autorización ya Facturada, no se puede Continuar ' ERROR 
         RETURN
      END
      IF EXISTS(SELECT * FROM AUT WHERE IDAUT=@IDAUT AND ESTADO='Anulada')
      BEGIN 
         SELECT 'KO' OK, 'Autorización Anulada, no se puede Continuar ' ERROR 
         RETURN         
      END
      IF EXISTS(SELECT * FROM AUT INNER JOIN PPT ON AUT.IDCONTRATANTE=PPT.IDTERCERO AND AUT.IDPLAN=PPT.IDPLAN 
                AND (COALESCE(PFACTURARIND,0)=0 OR COALESCE(TIPOTERCONTABLE,'NO')='NO')
                AND AUT.IDAUT=@IDAUT)
      BEGIN
         SELECT 'KO'KO,'Esta autorización pertenece a un plan que se factura masivamente ó Inconsistencia Contable, No Existe Tipo Ter Contable... Revisar Contrato 'ERROR
         RETURN
      END
      SELECT @IDPLAN = IDPLAN,@NOAUT=NOAUT,@IDSEDE=IDSEDE,@VALORCOPAGO=COALESCE(VALORCOPAGO,0) FROM AUT WHERE IDAUT=@IDAUT
      IF @IDPLAN NOT IN(SELECT DATO FROM USVGS WHERE IDVARIABLE LIKE 'IDPLANPART%')
      BEGIN
         IF DBO.FNK_VALORVARIABLE('VALRECA_COPA_FACTU')='SI' AND @VALORCOPAGO>0
         BEGIN
            PRINT 'Es particular, reviso la Caja'
            IF NOT EXISTS(SELECT * FROM FCJ WHERE NOADMISION=@NOAUT AND PROCEDENCIA='CE' AND CERRADA=1 AND ESTADO='P')
            BEGIN
               SELECT 'KO'KO,'El valor del copago no ha sido recuadado en caja... Se debe recaudar primero'ERROR
               RETURN
            END
         END
      END
      IF DBO.FNK_VALORVARIABLE('ASI_VAL_CCAF_CARGOS')='SI'
      BEGIN
         IF NOT EXISTS(SELECT *  FROM AUTD INNER JOIN SER ON AUTD.IDSERVICIO=SER.IDSERVICIO 
                                     INNER JOIN AUT ON AUTD.IDAUT=AUT.IDAUT
            WHERE AUTD.IDAUT=@IDAUT
            AND  EXISTS (SELECT * FROM KMCOM WHERE IDTIPOCONT='VENTAS'
            AND KMCOM.PREFIJO=SER.PREFIJO 
            AND KMCOM.IDAREA=AUT.IDAREA 
            AND KMCOM.CCOSTO=AUT.CCOSTO ) 
            )
         BEGIN
            SELECT 'KO'KO,'No existe configuracion contable para centro de costo y área funcional.'ERROR
            RETURN
         END
      END
      IF NOT EXISTS(SELECT * FROM PRI WHERE FECHA_INI<=GETDATE() AND FECHA_FIN+1>GETDATE() AND CERRADO=0 AND CERRADO_FAC=0 AND CERRADO_CARTERA=0)
      BEGIN
         BEGIN
            SELECT 'KO'KO,'El periodo contable no existe o se encuentra cerrado'ERROR
            RETURN
         END
      END
      IF DBO.FNK_VALORVARIABLE('PRESUP_CXC_ACTIVADO')='SI'
      BEGIN
         IF (SELECT CASE WHEN COALESCE(RUBRO,'')='' OR COALESCE(RUBROANT,'')='' 
                    THEN 0 ELSE 1 END FROM PLN WHERE IDPLAN=@IDPLAN)=0
         BEGIN
            SELECT 'KO'KO,'Este plan No tiene Asociados los Rubros Presupuestales No se puede Continuar'ERROR
            RETURN
         END
      END
      SELECT @IDTERINSTALADO=DBO.FNK_VALORVARIABLE('IDTERCEROINSTALADO')
      SELECT @COMPANIA=COALESCE(UBEQ.COMPANIA,USUSU.COMPANIA),@IDSEDEF=COALESCE(UBEQ.IDSEDE,USUSU.IDSEDE)
      FROM USUSU LEFT JOIN UBEQ ON USUSU.SYS_ComputerName=UBEQ.SYS_ComputerName
      WHERE USUARIO=@USUARIO
      IF DBO.FNK_VALORVARIABLE('FACTSEDE')='SI'
      BEGIN
         IF @IDSEDE<>@IDSEDEF
         BEGIN
            SELECT @IDSEDEF=@IDSEDE
         END
      END
      ELSE
      BEGIN
         SELECT @IDSEDEF=DBO.FNK_VALORVARIABLE('IDSEDEPRINCIPAL')
      END
      BEGIN TRY    
         IF @IXCOUNTRY='PERU'
         BEGIN
            PRINT 'VOY A GENERAR BOLETA '
            PRINT 'TIPOFAC ='+@TIPOFAC
            EXEC SPK_FACTURACE_PERU_COPA @NOAUT,@IDTERINSTALADO,@COMPANIA, @IDSEDEF, @USUARIO,'','','','','','CE','', 'FALSE', NULL,@F_FACTURA,@TIPOFAC,@RUC    
         END
         ELSE
         BEGIN
             EXEC SPK_FACTURACE_N @NOAUT,@IDTERINSTALADO,@COMPANIA, @IDSEDEF, @USUARIO,'','','','','','CE','', 'FALSE', NULL,@F_FACTURA       
          END
      END TRY
      BEGIN CATCH
            INSERT INTO @TBLERRORES(ERROR) SELECT ERROR_MESSAGE()
      END CATCH
      IF(SELECT COUNT(*) FROM @TBLERRORES)>0
      BEGIN
         SELECT 'KO' OK, ERROR FROM @TBLERRORES
         RETURN
      END
      IF @IDPLAN IN(SELECT DATO FROM USVGS WHERE IDVARIABLE LIKE 'IDPLANPART%') AND DBO.FNK_VALORVARIABLE('GENERA_PAGO_PART_FAC')='SI'
      BEGIN
         EXEC SPK_PAGOSCAJA_AUT  @NOAUT,@SYS_COMPUTERNAME, @COMPANIA,@IDSEDEF , @USUARIO ,1
      END
      IF @IXCOUNTRY='PERU'
      BEGIN
         SELECT TOP 1 @N_FACTURA=NFACTURA FROM AUTD WHERE IDAUT=@IDAUT
      END
      ELSE
      BEGIN
         SELECT @N_FACTURA=N_FACTURA FROM AUT WHERE IDAUT=@IDAUT
      END
      SELECT 'OK' OK,@N_FACTURA N_FACTURA
      RETURN 
   END
	IF @METODO = 'VALIDA_CUOTA'
	BEGIN
		SELECT @IDAUT = IDAUT
		FROM OPENJSON(@PARAMETROS)WITH( IDAUT      VARCHAR(20)            '$.IDAUT' )
	
		BEGIN TRY 
			SELECT 'OK' AS OK, COUNT(*) VALIDA FROM QXDING WHERE NOINGRESO = @IDAUT AND PROCEDENCIA='CE'

			IF EXISTS ( SELECT TOP 1 FTR.VR_TOTAL VLR_PRESTACION,AUT.VLRDEPOSITOS VLR_ABONADO
				         FROM   AUT INNER JOIN AUTD ON AUT.IDAUT=AUTD.IDAUT 
						              INNER JOIN FTR  ON AUTD.N_FACTURA=FTR.N_FACTURA 
				         WHERE AUT.IDAUT=@IDAUT
				         AND AUTD.IDPLAN=DBO.FNK_VALORVARIABLE('IDPLANPART')
				         GROUP BY FTR.VR_TOTAL,AUT.VLRDEPOSITOS
				       )
				SELECT TOP 1 FTR.VR_TOTAL VLR_PRESTACION,AUT.VLRDEPOSITOS VLR_ABONADO
				FROM   AUT INNER JOIN AUTD ON AUT.IDAUT=AUTD.IDAUT 
						INNER JOIN FTR ON AUTD.N_FACTURA=FTR.N_FACTURA 
				WHERE AUT.IDAUT=@IDAUT
				AND AUTD.IDPLAN=DBO.FNK_VALORVARIABLE('IDPLANPART')
				GROUP BY FTR.VR_TOTAL,AUT.VLRDEPOSITOS
		   ELSE
				SELECT  0 VLR_PRESTACION, 0 VLR_ABONADO
		END TRY
		BEGIN CATCH
			INSERT INTO @TBLERRORES(ERROR)
			SELECT ERROR_MESSAGE()
		END CATCH

		IF EXISTS(SELECT 1 FROM @TBLERRORES)
		BEGIN
			SELECT 'KO' AS OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END
		SELECT 'OK' AS OK
		RETURN
	END
	IF @METODO = 'ABONAR_CUOTA'
	BEGIN
		SELECT @IDAUT = IDAUT, @VLR_PRESTACION = VLR_PRESTACION, @VLR_ABONADO = VLR_ABONADO
		      ,@VLR_FALTANTE = VLR_FALTANTE , @VLR_NV_ABONO = VLR_NV_ABONO
		FROM OPENJSON(@PARAMETROS)WITH( IDAUT				VARCHAR(20)				'$.IDAUT' 
										      ,VLR_PRESTACION	DECIMAL(14,2)			'$.VLR_PRESTACION'
										      ,VLR_ABONADO		DECIMAL(14,2)			'$.VLR_ABONADO'
										      ,VLR_FALTANTE		DECIMAL(14,2)			'$.VLR_FALTANTE'
										      ,VLR_NV_ABONO		DECIMAL(14,2)			'$.VLR_NV_ABONO'
										)
		IF @VLR_NV_ABONO <= 0
		BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'El Valor Ingresado no es Valido'
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END
		IF @VLR_FALTANTE < @VLR_NV_ABONO
		BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'El Valor Ingresado Es Mayor al valor Pendiente de Pago'
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END
		BEGIN TRY 
			SELECT @NOAUT = NOAUT FROM AUT WHERE  IDAUT = @IDAUT
			IF (@VLR_NV_ABONO <= 0)
			BEGIN
				EXEC SPK_PAGOSCAJA_AUT_RELACIONADOS @NOAUT, @SYS_COMPUTERNAME, @COMPANIA, @SEDE, @USUARIO, @VLR_NV_ABONO
			END
			ELSE
			BEGIN
				EXEC SPK_ABONOFACTURA_AUT_CAJAPART @NOAUT, @SYS_COMPUTERNAME, @COMPANIA, @SEDE, @USUARIO, @VLR_NV_ABONO
			END
		END TRY
		BEGIN CATCH
			INSERT INTO @TBLERRORES(ERROR)
			SELECT ERROR_MESSAGE()
		END CATCH

		IF EXISTS(SELECT 1 FROM @TBLERRORES)
		BEGIN
			SELECT 'KO' AS OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END
		SELECT 'OK' AS OK
		RETURN
	END
	IF @METODO = 'ANULAR_AUT'
	BEGIN
		SELECT @IDAUT = IDAUT ,@RAZONANULA = RAZONANULA ,@PROCESO = PROCESO
		FROM OPENJSON(@PARAMETROS)
      WITH(  IDAUT				VARCHAR(20)			 '$.IDAUT' 
            ,RAZONANULA			VARCHAR(MAX)         '$.RAZONANULA'
            ,PROCESO			VARCHAR(100)         '$.PROCESO')

		SELECT @NOAUT = NOAUT, @SOAT = SOAT ,@CNSHACTRAN = CNSHACTRAN ,@CONSECUTIVOHCA = COALESCE(CONSECUTIVOHCA,'') ,@NORECIBOCAJA = NORECIBOCAJA
		FROM   AUT WHERE IDAUT = @IDAUT

		IF EXISTS (SELECT * FROM LING 
					INNER JOIN LORD ON LING.NOINGRESO = LORD.NOINGRESO
					WHERE COALESCE(LORD.RESULTADO,'') = 'R' AND LING.NOPRESTACION = @IDAUT AND LING.TIPOINGRESO = 'C'
					) AND @PROCESO = 'VALIDA'
		BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'El registro no se puede anular, por que tiene registros que ya tienen resultados.'
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END
		IF EXISTS (SELECT * FROM AUT WHERE AUT.IDAUT = @IDAUT AND ESTADO = 'Anulada')
		BEGIN
			IF @PROCESO <> 'VALIDA'
			BEGIN
				INSERT INTO @TBLERRORES(ERROR) SELECT 'Orden ya está anulada'
				SELECT 'KO' OK
				SELECT ERROR FROM @TBLERRORES
				RETURN
			END
		END
      
		IF (SELECT COUNT(1) FROM AUTD WHERE IDAUT = @IDAUT AND FACTURADA=1 ) > 0
		BEGIN
			IF @PROCESO <> 'VALIDA'
			BEGIN
				INSERT INTO @TBLERRORES(ERROR) SELECT 'No se puede Anular una autorización con servicios facturados'
				SELECT 'KO' OK
				SELECT ERROR FROM @TBLERRORES
				RETURN
			END
		END
             
      SELECT @PEDIDOHPREAIZSOL = COALESCE(DBO.FNK_VALORVARIABLE('PEDIDOHPREAIZSOL'),'')

      IF @PEDIDOHPREAIZSOL <> 'SI'
      BEGIN --CMT IMOV
         IF (SELECT ESTADO FROM IMOV WHERE NODOCUMENTO = @NOAUT AND PROCEDENCIA = 'CE') = 1
            SELECT @ESTADO_AUX = 1
         ELSE
         BEGIN
            SELECT @CNSMOV = CNSMOV FROM IMOV WHERE NODOCUMENTO = @NOAUT AND PROCEDENCIA = 'CE'
            IF (SELECT COUNT(*) FROM IMOVH WHERE ESTADO = 1 AND CNSMOV = @CNSMOV) > 0
               SELECT @ESTADO_AUX = 2
         END
      END
      ELSE
      BEGIN
         IF (SELECT COUNT(1) 
             FROM   IZSOL INNER JOIN IMOV ON IMOV.NODOCUMENTO = IZSOL.CNSIZSOL 
                                           AND IMOV.PROCEDENCIA = 'CM_SOL'
             WHERE  IMOV.ESTADO <> 2 
             AND    IZSOL.CLASE      = 'CE' 
             AND    IZSOL.NOADMISION = @IDAUT
            ) > 0
         BEGIN
            SELECT @ESTADO_AUX = 2
         END
      END
      IF @TIPOCAJA = 'FCJ'
      BEGIN
         SELECT @CERRADA = CERRADA, @ESTADO_FCJ = ESTADO FROM FCJ WHERE CNSFACJ = @NORECIBOCAJA
         AND CODCAJA = @CODCAJA
         IF @ESTADO_FCJ <> 'A' AND @CERRADA = 1
            SELECT @ESTADO_AUX = 3
      END


		IF @ESTADO_AUX = 1
		BEGIN
			IF @PROCESO <> 'VALIDA'
			BEGIN
				INSERT INTO @TBLERRORES(ERROR) SELECT 'Orden no puede ser anulada por que ya fue entregada en farmacia'
				SELECT 'KO' OK
				SELECT ERROR FROM @TBLERRORES
				RETURN
			END
		END
		IF @ESTADO_AUX = 2
		BEGIN
			IF @PROCESO <> 'VALIDA'
			BEGIN
				INSERT INTO @TBLERRORES(ERROR) SELECT 'Orden no puede ser anulada por que fue parcialmente entregada en farmacia'
				SELECT 'KO' OK
				SELECT ERROR FROM @TBLERRORES
				RETURN
			END
		END
		IF @ESTADO_AUX =  3
		BEGIN
			IF @PROCESO <> 'VALIDA'
			BEGIN
				INSERT INTO @TBLERRORES(ERROR) SELECT 'Orden no puede ser anulada por que ya fue traida en caja'
				SELECT 'KO' OK
				SELECT ERROR FROM @TBLERRORES
				RETURN
			END
		END
		--IF (SELECT COUNT(1) FROM AUTD WHERE IDAUT = @IDAUT AND COALESCE(ENLAB,0) = 1) > 0
		--BEGIN
		--	IF @PROCESO <> 'VALIDA'
		--	BEGIN
		--		INSERT INTO @TBLERRORES(ERROR) SELECT 'Orden traida en apoyo diagnostico no se puede anular'
		--		SELECT 'KO' OK
		--		SELECT ERROR FROM @TBLERRORES
		--		RETURN
		--	END
		--END  
		IF @PROCESO = 'VALIDA'
		BEGIN
			IF (SELECT COUNT(*) FROM @TBLERRORES) > 0
			BEGIN
				SELECT 'KO' OK 
				SELECT * FROM @TBLERRORES
				RETURN
			END
			ELSE
			BEGIN
				SELECT 'OK' OK
            RETURN
			END
		END

      SELECT @GENEROCAJA = GENEROCAJA ,@TIPOCAJA = TIPOCAJA FROM AUT WHERE IDAUT = @IDAUT
      IF @GENEROCAJA = 1
      BEGIN
         IF @TIPOCAJA = 'TFCJ'
         BEGIN
            DELETE TFCJDD FROM TFCJDD INNER JOIN TFCJ ON TFCJDD.CNSFACJ=TFCJ.CNSFACJ 
            WHERE  TFCJ.NOADMISION = @NOAUT
            AND    PROCEDENCIA     = 'CE'
            DELETE TFCJD FROM TFCJD INNER JOIN TFCJ ON TFCJD.CNSFACJ=TFCJ.CNSFACJ 
            WHERE  TFCJ.NOADMISION = @NOAUT
            AND    PROCEDENCIA     = 'CE'
            DELETE TFCJ WHERE NOADMISION=@NOAUT AND PROCEDENCIA='CE'
         END
         ELSE IF @TIPOCAJA = 'FCJ'
         BEGIN
            SELECT @CERRADA = CERRADA, @ESTADO_FCJ = ESTADO FROM FCJ WHERE CNSFACJ = @NORECIBOCAJA
            AND CODCAJA = @CODCAJA
            IF @ESTADO_FCJ <> 'A' AND @CERRADA = 1
               SELECT @ESTADO_AUX = 3
         END
      END
      IF @ESTADO_AUX =  3
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'Orden no puede ser anulada por que ya fue traida en caja'
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
      END
   --   IF (SELECT COUNT(1) FROM AUTD WHERE IDAUT = @IDAUT AND COALESCE(ENLAB,0) = 1) > 0
   --   BEGIN
   --      INSERT INTO @TBLERRORES(ERROR) SELECT 'Orden traida en apoyo diagnostico no se puede anular'
			--SELECT 'KO' OK
			--SELECT ERROR FROM @TBLERRORES
			--RETURN
   --   END   

	  DELETE FROM LORDDREFS WHERE LORDDREFS.NORDEN  IN (SELECT NORDEN FROM AUTD WHERE  AUTD.IDAUT = @IDAUT AND COALESCE(NORDEN,'')<> '')
	  DELETE FROM LORDD WHERE  LORDD.NORDEN IN (SELECT NORDEN FROM AUTD WHERE  AUTD.IDAUT = @IDAUT AND COALESCE(NORDEN,'')<> '')
	  DELETE FROM LORD WHERE  LORD.NORDEN IN (SELECT NORDEN FROM AUTD WHERE  AUTD.IDAUT = @IDAUT AND COALESCE(NORDEN,'')<> '')
	  DELETE FROM LING WHERE LING.NOPRESTACION  = @NOAUT AND LING.TIPOINGRESO = 'C'
	  UPDATE AUTD SET NORDEN = NULL, ENLAB = 0, USUARIOMARCA = NULL WHERE AUTD.IDAUT = @IDAUT 


		--EXEC SPK_GENCONSECUTIVO @COMPANIA,@SEDE,'@XAUT',@NVOCONSEC OUTPUT  
		--SELECT @NVOCONSEC = @SEDE + REPLACE(SPACE(8 - LEN(@NVOCONSEC))+LTRIM(RTRIM(@NVOCONSEC)),SPACE(1),0)
		EXEC SPQ_GENSEQUENCE @SEDE=@SEDE,@PREFIJO='@XAUT', @LONGITUD=8,@NVOCONSEC=@NVOCONSEC OUTPUT

      UPDATE AUT SET IDOPERADORANULA = @USUARIO
                    ,CONSANULADO     = @NVOCONSEC
                    ,FECHAANULA      = GETDATE()
                    ,RAZONANULACION  = @RAZONANULA
                    ,MARCAFAC        = 0
                    ,CNSFACT         = ''
                    ,ESTADO          = 'Anulada'
      WHERE AUT.IDAUT = @IDAUT
		
      IF @PEDIDOHPREAIZSOL <>'SI'
      BEGIN
         DELETE IMOVH WHERE CNSMOV = @CNSMOV
         DELETE IMOV  WHERE CNSMOV = @CNSMOV
      END
      ELSE
      BEGIN
         UPDATE IZSOL SET ESTADO=2 WHERE NOADMISION = @IDAUT AND CLASE='CE'
      END

      IF @SOAT = 1
      BEGIN
         EXEC SPK_MOV_ACTRAN 'BORRAR', 'CE', @NOAUT
         EXEC SPK_RELIQ_HACTRAN @CNSHACTRAN
      END

      UPDATE RSA SET RSA.FECHALIMITE = RSA.FECHALIM
      FROM   (SELECT AUT.IDAFILIADO, AUT.IDPLAN ,AUTD.IDSERVICIO FROM AUTD INNER JOIN AUT ON AUTD.IDAUT = AUT.IDAUT WHERE AUT.IDAUT = @IDAUT) X
      WHERE  RSA.FECHALIMITE >= GETDATE()
      AND    RSA.IDAFILIADO  = X.IDAFILIADO
      AND    RSA.IDPLAN      = X.IDPLAN
      AND    RSA.IDSERVICIO  = X.IDSERVICIO
		
      IF @CONSECUTIVOHCA <> ''
      BEGIN
         UPDATE HCATD SET APLICADA=0
         FROM   HCATD INNER JOIN AUT  ON AUT.CONSECUTIVOHCA=HCATD.CONSECUTIVO
                      INNER JOIN AUTD ON AUTD.IDAUT=AUT.IDAUT
         WHERE AUT.IDAUT         = @IDAUT 
         AND   HCATD.IDSERVICIO = AUTD.IDSERVICIO
      END

		SELECT 'OK' AS OK
		RETURN
	END
	IF @METODO = 'SEPARAR_SER_OPTICA'
	BEGIN
		SELECT @IDAUT = IDAUT
		FROM OPENJSON(@PARAMETROS)WITH( IDAUT				VARCHAR(20)				'$.IDAUT' 
										)
		IF EXISTS (SELECT * FROM AUTD WHERE AUTD.IDAUT = @IDAUT AND AUTD.HOMOLOGO = 1)
		BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'El servicio ya se encuentra separado'
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END  
		BEGIN TRY 
			EXEC SPK_SEPARA_SER_REL_AUT @IDAUT
		END TRY
		BEGIN CATCH
			INSERT INTO @TBLERRORES(ERROR)
			SELECT ERROR_MESSAGE()
		END CATCH

		IF EXISTS(SELECT 1 FROM @TBLERRORES)
		BEGIN
			SELECT 'KO' AS OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END
		SELECT 'OK' AS OK
		RETURN
	END
	IF @METODO = 'UNIR_SER_OPTICA'
	BEGIN
		SELECT @IDAUT = IDAUT
		FROM OPENJSON(@PARAMETROS)WITH( IDAUT				VARCHAR(20)				'$.IDAUT' 
										)
		--IF NOT EXISTS (SELECT * FROM AUTD WHERE AUTD.IDAUT = @IDAUT AND (AUTD.HOMOLOGO <> 1 OR AUTD.CITAAUTORIZADA = 1))
		--BEGIN
		--	INSERT INTO @TBLERRORES(ERROR) SELECT 'El servicio se encuentra en HOMOLOGO <> 1 o CITAAUTORIZADA = 1'
		--	SELECT 'KO' OK
		--	SELECT ERROR FROM @TBLERRORES
		--	RETURN
		--END 
		IF NOT EXISTS (SELECT * FROM AUTD WHERE AUTD.IDAUT = @IDAUT AND AUTD.HOMOLOGO = 1)
		BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'El servicio no se encunetra separado'
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END 
		IF EXISTS (SELECT * FROM AUTD WHERE AUTD.IDAUT = @IDAUT AND AUTD.FACTURADA = 1)
		BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'Item Ya Facturado... No Se Puede Continua'
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END 
		BEGIN TRY 
			DELETE FROM AUTD WHERE IDAUT = @IDAUT AND HOMOLOGO=0
			UPDATE AUTD SET VALOR=VALORHOMO,IDSERVICIO=IDSERVICIOH,HOMOLOGO=0,VALOREXCEDENTE=(VALORHOMO*CANTIDAD) WHERE IDAUT= @IDAUT
			DELETE FROM AUTD WHERE COALESCE(AUTD.IDSERVICIO,'')='' AND AUTD.IDAUT = @IDAUT
		END TRY
		BEGIN CATCH
			INSERT INTO @TBLERRORES(ERROR)
			SELECT ERROR_MESSAGE()
		END CATCH

		IF EXISTS(SELECT 1 FROM @TBLERRORES)
		BEGIN
			SELECT 'KO' AS OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END
		SELECT 'OK' AS OK
		RETURN
	END
	IF @METODO = 'PEDIR_INVENTARIO_OPTICA'
	BEGIN
		SELECT @IDAUT = IDAUT
		FROM OPENJSON(@PARAMETROS)WITH( IDAUT				VARCHAR(20)				'$.IDAUT' 
										)
      IF (SELECT DBO.FNK_VALORVARIABLE ('PEDIRFARMACIACE')) = 'NO'
		BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'Variable PEDIRFARMACIACE esta en NO: No permite pedir a inventarios.'
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END 
		IF EXISTS (SELECT * FROM AUT WHERE  AUT.IDAUT = @IDAUT AND COALESCE(AUT.ESDEINV,0) = 0)
		BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'El registro no tiene los datos validos, para este proceso.'
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END
      IF EXISTS (SELECT * FROM AUT WHERE  AUT.IDAUT = @IDAUT AND COALESCE(AUT.ESDEINV,0) = 1 AND COALESCE(AUT.PEDIDOINV,0) = 1)
		BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'Pedido procesado anteriormente'
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END
		BEGIN TRY 
			IF EXISTS(SELECT * FROM AUT WHERE  AUT.IDAUT = @IDAUT AND COALESCE(AUT.ESDEINV,0) = 1 AND COALESCE(AUT.PEDIDOINV,0) = 0)
			BEGIN
				SELECT @IDSEDE = IDSEDE FROM AUT WHERE IDAUT = @IDAUT
            SELECT @IDBODEGA = COALESCE(IDBODEGACM, IDBODEGALOG, IDBODEGA24H, IDBODHEMO)  FROM SED WHERE IDSEDE = @IDSEDE
				EXEC SPK_PEDIDOINVCE @IDAUT, @IDBODEGA, @COMPANIA, @IDSEDE, @USUARIO, @SYS_COMPUTERNAME
			END
		END TRY
		BEGIN CATCH
			INSERT INTO @TBLERRORES(ERROR)
			SELECT ERROR_MESSAGE()
		END CATCH

		IF EXISTS(SELECT 1 FROM @TBLERRORES)
		BEGIN
			SELECT 'KO' AS OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END
		SELECT 'OK' AS OK
		RETURN
	END
	IF @METODO = 'FIRMAR_PRESTACION_SERVICIO'
	BEGIN
		DECLARE @IDFIRMA UNIQUEIDENTIFIER
			,@TIPOFIRMA VARCHAR(50)
		BEGIN TRY 

			SELECT @CONSECUTIVO = JSON_VALUE(@PARAMETROS, '$.CONSECUTIVO')
				,@IDFIRMA = JSON_VALUE(@PARAMETROS, '$.FIRMA')
				,@TIPOFIRMA = JSON_VALUE(@PARAMETROS, '$.TIPO')
		
			IF @TIPOFIRMA = 'PRESTACION_PACIENTE'
			BEGIN
				DELETE FROM DOCS WHERE DOCUMENTOID = (SELECT IDFIRMAPTE FROM AUT WHERE IDAUT=@CONSECUTIVO)

				UPDATE AUT SET IDFIRMAPTE=@IDFIRMA
				WHERE IDAUT=@CONSECUTIVO
			END
			ELSE
			BEGIN
				DELETE FROM DOCS WHERE DOCUMENTOID = (SELECT IDFIRMARESP FROM AUT WHERE IDAUT=@CONSECUTIVO)
				
				UPDATE AUT SET IDFIRMARESP=@IDFIRMA
				WHERE IDAUT=@CONSECUTIVO
			END

		END TRY
		BEGIN CATCH
			INSERT INTO @TBLERRORES(ERROR)
			SELECT ERROR_MESSAGE()
		END CATCH

		IF EXISTS(SELECT 1 FROM @TBLERRORES)
		BEGIN
			SELECT 'KO' AS OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END

		SELECT 'OK' AS OK, @CONSECUTIVO AS CONSECUTIVO

		RETURN
	END
	IF @METODO = 'NO_COBRABLE'
	BEGIN
		SELECT @IDAUT = IDAUT, @NO_ITEM = NO_ITEM
		FROM OPENJSON(@PARAMETROS)WITH( IDAUT				VARCHAR(20)				'$.IDAUT' 
										,NO_ITEM			INT						'$.NO_ITEM' 
										)

		IF	EXISTS (SELECT  * FROM AUTD WHERE AUTD.IDAUT = @IDAUT AND AUTD.NO_ITEM = @NO_ITEM AND COALESCE(AUTD.NOCOBRABLE,0) = 0)
			AND (SELECT COALESCE(OBS,'') FROM AUTD WHERE AUTD.IDAUT = @IDAUT AND AUTD.NO_ITEM = @NO_ITEM) = '' 
			AND (DBO.FNK_VALORVARIABLE('OBLIGA_OBSNOCOB_AUTD')) = 'SI'
		BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'Debe diligenciar el campo de observación ya que es obligatorio.'
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END
		
		BEGIN TRY 
			IF EXISTS (SELECT  * FROM AUTD WHERE AUTD.IDAUT = @IDAUT AND AUTD.NO_ITEM = @NO_ITEM AND COALESCE(AUTD.NOCOBRABLE,0) = 0)
			BEGIN
				UPDATE AUTD SET NOCOBRABLE = 1, VALOR = 0, VALORCOPAGO = 0, VALOREXCEDENTE = 0, VALORCOPAGOCOSTO = 0 WHERE AUTD.IDAUT = @IDAUT AND AUTD.NO_ITEM = @NO_ITEM 
				SELECT 'OK' AS OK
				RETURN 
			END

			IF EXISTS (SELECT  * FROM AUTD WHERE AUTD.IDAUT = @IDAUT AND AUTD.NO_ITEM = @NO_ITEM AND COALESCE(AUTD.NOCOBRABLE,0) = 1)
			BEGIN
				UPDATE AUTD SET NOCOBRABLE = 0 WHERE AUTD.IDAUT = @IDAUT AND AUTD.NO_ITEM = @NO_ITEM 
				SELECT @PYP = (SELECT CASE COALESCE(AUT.CLASEORDEN,'') WHEN 'PyP' THEN 1 ELSE 0 END FROM AUT WHERE IDAUT = @IDAUT)
				SELECT @AC = (SELECT CASE COALESCE(AUT.ALTOCOSTO,'') WHEN 'Si' THEN 1 ELSE 0 END FROM AUT WHERE IDAUT = @IDAUT)
				SELECT @NOAUT = NOAUT, @IDAFILIADO = IDAFILIADO, @IDPROVEEDOR = IDPROVEEDOR, @IDAREA = IDAREA
				, @FECHA = CONVERT(DATE,FECHA), @COPAGOPROPIO= COPAGOPROPIO,@SOAT = SOAT, @CNSHACTRAN = CNSHACTRAN
				FROM AUT WHERE IDAUT = @IDAUT

				SELECT @IDSERVICIO = IDSERVICIO, @VALOR = VALOR FROM AUTD WHERE  AUTD.IDAUT = @IDAUT AND AUTD.NO_ITEM = @NO_ITEM 

				EXEC SPK_COPAGO_AUT_CEHOSP @IDAFILIADO, @IDAUT, @NO_ITEM, @IDSERVICIO,@PYP,  @AC, @VALOR, 'CE', @SYS_COMPUTERNAME, @COMPANIA, @IDSEDE, @USUARIO
						,@IDPROVEEDOR, @IDAREA, @FECHA, @COPAGOPROPIO, @SOAT

				IF @SOAT = 1
					EXEC SPK_RELIQ_HACTRAN @CNSHACTRAN

				EXEC SPK_TOTALESAUT_CJN @IDAUT
			END

		END TRY
		BEGIN CATCH
			INSERT INTO @TBLERRORES(ERROR)
			SELECT ERROR_MESSAGE()
		END CATCH

		IF EXISTS(SELECT 1 FROM @TBLERRORES)
		BEGIN
			SELECT 'KO' AS OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END
		SELECT 'OK' AS OK
		RETURN
	END
--QUERY3
   IF @METODO = 'VERDATOS_AUT'
   BEGIN
      SELECT @IDAUT = IDAUT
      FROM OPENJSON(@PARAMETROS) WITH(        IDAUT      VARCHAR(20)            '$.IDAUT' )

      IF (SELECT COUNT(*) FROM AUT WHERE IDAUT=@IDAUT)=0
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'No existe la Autorización'
         SELECT 'KO' OK
         SELECT ERROR FROM @TBLERRORES
         RETURN
      END
      SELECT 'OK' OK
      SELECT GENEROCAJA ,TIPOCAJA ,COALESCE(VALORCOPAGO,0) VALORCOPAGO FROM AUT WHERE IDAUT = @IDAUT
      RETURN
   END
   IF @METODO = 'RECAUDAR_COPAGO'
   BEGIN
      SELECT @IDAUT = IDAUT
      FROM OPENJSON(@PARAMETROS)WITH(        IDAUT      VARCHAR(20)            '$.IDAUT' )
      PRINT '@SYS_COMPUTERNAME='+@SYS_COMPUTERNAME
      IF (SELECT COUNT(*) FROM AUT WHERE IDAUT=@IDAUT)=0
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'No existe la Autorización'
         SELECT 'KO' OK
         SELECT ERROR FROM @TBLERRORES
         RETURN
      END
      SELECT @GENEROCAJA = GENEROCAJA ,@TIPOCAJA = TIPOCAJA ,@VALORCOPAGO = COALESCE(VALORCOPAGO,0) ,@NORECIBOCAJA = NORECIBOCAJA ,@NOAUT = NOAUT
      FROM   AUT WHERE IDAUT = @IDAUT
      IF @GENEROCAJA <> 1
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'La autorización no genero caja'
      END
      IF @VALORCOPAGO <= 0
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'El valor del copago es 0'        
      END
      IF (SELECT COUNT(*) FROM @TBLERRORES)>0
      BEGIN
         SELECT 'KO' OK
         SELECT ERROR FROM @TBLERRORES
         RETURN
      END

      IF @GENEROCAJA = 1 AND @TIPOCAJA = 'TFCJ'
      BEGIN
         SELECT @VALIDATURNO = DBO.FNK_VALIDA_TURNO_CAJA(@USUARIO,@SYS_ComputerName)
         IF @VALIDATURNO = 0
            INSERT INTO @TBLERRORES(ERROR) SELECT 'El Usuario '+@USUARIO+' No Esta Habilidado Como Cajero'
         ELSE IF @VALIDATURNO = 1
            INSERT INTO @TBLERRORES(ERROR) SELECT 'La Caja Buscada No Existe o Esta Inactiva'  
         ELSE IF @VALIDATURNO = 2
            INSERT INTO @TBLERRORES(ERROR) SELECT 'La Caja Esta Cerrada No se Puede Continuar'
         ELSE IF @VALIDATURNO = 3
            INSERT INTO @TBLERRORES(ERROR) SELECT 'Caja Abierta por Otro Cajero, Revise sus Credenciales' 
         ELSE IF @VALIDATURNO = 4
            INSERT INTO @TBLERRORES(ERROR) SELECT 'No Existe Turno para Esta Caja y Este Cajero, Revise sus Credenciales'
         ELSE IF @VALIDATURNO = 5
            INSERT INTO @TBLERRORES(ERROR) SELECT 'Equipo No Esta Habilidado para Ser Caja, Revise sus Credenciales'
         ELSE IF @VALIDATURNO = 6
               INSERT INTO @TBLERRORES(ERROR) SELECT 'Caja y Cajero Fuera de Turno, Revise sus Credenciales'

         IF (SELECT CAJA FROM UBEQ WHERE SYS_COMPUTERNAME=@SYS_COMPUTERNAME) <> 0
         BEGIN
               SELECT @CODCAJA = CAJA FROM UBEQ WHERE SYS_COMPUTERNAME=@SYS_COMPUTERNAME
               IF (SELECT CASE WHEN  EXISTS(SELECT * FROM CAJ WHERE CODCAJA=@CODCAJA) THEN 'OK' ELSE 'ER' END) = 'ER'
               BEGIN
                  INSERT INTO @TBLERRORES(ERROR) SELECT 'El equipo no está configurado como caja... No se puede continuar'  
               END
         END
         ELSE
         BEGIN
               INSERT INTO @TBLERRORES(ERROR) SELECT 'El equipo no está configurado como caja... No se puede continuar'  
         END


         SELECT @CODCAJA = CAJA FROM UBEQ WHERE SYS_COMPUTERNAME=@SYS_COMPUTERNAME
         SELECT @ABIERTA_CAJ = ABIERTA, @CNSACJ_CAJ = CNSACJ FROM CAJ WHERE CODCAJA=@CODCAJA
         IF (SELECT @ABIERTA_CAJ FROM CAJ WHERE CODCAJA=@CODCAJA) = 0
         BEGIN
               INSERT INTO @TBLERRORES(ERROR) SELECT 'La caja está cerrada... No se puede continuar'  
         END
         SELECT @IDPLAN_TFCJ = IDPLAN ,@PROCEDENCIA_TFCJ = PROCEDENCIA ,@NOADMISION_TFCJ = NOADMISION ,@CNSFACJ_TFCJ = CNSFACJ
         FROM   TFCJ 
         WHERE  CNSFACJ = @NORECIBOCAJA

         IF @IDPLAN_TFCJ IN (SELECT DATO FROM USVGS WHERE IDVARIABLE LIKE 'IDPLANPART%') AND @PROCEDENCIA_TFCJ = 'CE'
         BEGIN
            IF (SELECT COUNT(*) FROM FTR WHERE NOREFERENCIA = @NOADMISION_TFCJ AND PROCEDENCIA = 'CE' AND ESTADO = 'P' ) <= 0
               BEGIN
                  INSERT INTO @TBLERRORES(ERROR) SELECT 'La orden no ha sido facturada... Es particular, debe facturar primero'
               END
         END
         IF (SELECT COUNT(*) FROM @TBLERRORES)>0
         BEGIN
               SELECT 'KO' OK
               SELECT ERROR FROM @TBLERRORES
               RETURN
         END
         --LLAMO TRAER RECIBO A CAJA
         IF @@TRANCOUNT > 0
         BEGIN
            SAVE TRANSACTION antesTraerRecibo;  -- Punto de salvado único para sp_interno
         END
         ELSE
         BEGIN
            BEGIN TRANSACTION
         END
         BEGIN TRY
            EXEC SPK_TRAERECIB_CAJA @CNSFACJ_TFCJ ,@CNSACJ_CAJ ,@SYS_COMPUTERNAME ,'01',@IDSEDE ,@USUARIO , 'COBRO'
            IF @@TRANCOUNT = 1
            BEGIN
               COMMIT TRANSACTION;
            END
         END TRY
         BEGIN CATCH
            IF @@TRANCOUNT > 0
            BEGIN
               IF @@TRANCOUNT = 1
               BEGIN
                  ROLLBACK TRANSACTION;
               END
               ELSE
               BEGIN
                  ROLLBACK TRANSACTION antesTraerRecibo;  -- Usar el nombre único
               END
            END
            DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
            DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
            DECLARE @ErrorState    INT = ERROR_STATE();
            INSERT INTO @TBLERRORES(ERROR) SELECT 'Error al traer el recibo a caja... No se puede continuar (SPK_TRAERECIB_CAJA)'
            SELECT 'KO' OK

            RAISERROR(@ErrorMessage, 16, @ErrorState); -- Lanzar un nuevo error con el mensaje original
            RETURN
         END CATCH
         --
         SELECT @CNSFACJ = CNSFACJ ,@CODCAJA_FCJ = CODCAJA FROM FCJ WHERE PROCEDENCIA='CE' AND NOADMISION=@NOAUT AND CODCAJA=@CODCAJA

         SELECT  @VALORTOTAL = FCJ.VALORTOTAL-SUM(COALESCE(PCJ.VALOR,0)) 
         FROM    FCJ LEFT JOIN PCJ ON FCJ.CODCAJA=PCJ.CODCAJA 
                                    AND FCJ.CNSFACJ=PCJ.CNSFACJ 
         WHERE   FCJ.CODCAJA = @CODCAJA_FCJ 
         AND     FCJ.CNSFACJ=@CNSFACJ 
         GROUP BY FCJ.VALORTOTAL
         SELECT @CERRADA = CERRADA FROM FCJ WHERE FCJ.CODCAJA = @CODCAJA_FCJ  AND  FCJ.CNSFACJ=@CNSFACJ 
         SELECT 'OK' OK ,@VALORTOTAL VALORFALTANTE ,@VALORCOPAGO VALORCOPAGO, @CODCAJA_FCJ CODCAJA ,@CNSFACJ CNSFACJ ,@CNSACJ_CAJ CNSACJ
               ,GENEROCAJA ,TIPOCAJA ,@CERRADA CERRADA ,1 RECAUDAR
         FROM AUT 
         WHERE IDAUT = @IDAUT
         
            
      END
      ELSE IF @GENEROCAJA = 1 AND @TIPOCAJA = 'FCJ'
      BEGIN
         SELECT @CODCAJA = AUT.CODCAJA ,@CNSFACJ = NORECIBOCAJA, @VALORCOPAGO = VALORCOPAGO FROM AUT WHERE IDAUT = @IDAUT
         SELECT @CERRADA = CERRADA ,@CNSACJ_CAJ = CNSACJ FROM FCJ WHERE FCJ.CODCAJA = @CODCAJA  AND  FCJ.CNSFACJ=@CNSFACJ 
         SELECT  @VALORTOTAL = FCJ.VALORTOTAL-SUM(COALESCE(PCJ.VALOR,0)) 
         FROM    FCJ LEFT JOIN PCJ ON FCJ.CODCAJA=PCJ.CODCAJA 
                                    AND FCJ.CNSFACJ=PCJ.CNSFACJ 
         WHERE   FCJ.CODCAJA = @CODCAJA
         AND     FCJ.CNSFACJ = @CNSFACJ 
         GROUP BY FCJ.VALORTOTAL

         SELECT 'OK' OK ,@VALORTOTAL VALORFALTANTE ,AUT.VALORCOPAGO  ,AUT.CODCAJA ,AUT.NORECIBOCAJA CNSFACJ, @CNSACJ_CAJ CNSACJ ,AUT.GENEROCAJA ,AUT.TIPOCAJA
               ,@CERRADA CERRADA ,0 RECAUDAR 
         FROM   AUT
         WHERE  AUT.IDAUT = @IDAUT

      END
   END
   IF @METODO = 'CONFIRMAR_RECIBO'
   BEGIN
      SELECT @CNSFACJ = CNSFACJ, @CODCAJA = CODCAJA ,@CNSACJ_CAJ = CNSACJ ,@IDAUT = IDAUT
      FROM OPENJSON(@PARAMETROS)WITH(
	      CNSFACJ     VARCHAR(20)    '$.CNSFACJ' ,
	      CODCAJA     VARCHAR(20)    '$.CODCAJA' ,
         CNSACJ      VARCHAR(20)    '$.CNSACJ'  ,
         IDAUT       VARCHAR(20)    '$.IDAUT'
      )
      SELECT @FECHAFCJ = FECHA ,@TOTAL = VALORTOTAL ,@NOADMISION = NOADMISION 
      FROM   FCJ 
      WHERE  CODCAJA = @CODCAJA AND CNSFACJ = @CNSFACJ

      PRINT '@IDAUT='+@IDAUT
      --SELECT @TOTAL = VALORTOTAL, @N_FACTURA = N_FACTURA, @IDAFILIADO = IDAFILIADO, @PROCEDENCIA = PROCEDENCIA,
      --       @IDTERCERO = IDTERCERO, @ESTADO= ESTADO, @FECHAFCJ = FECHA, @NOADMISION = NOADMISION 
      --FROM FCJ 
      --WHERE  FCJ.CODCAJA = @CODCAJA 
      --AND FCJ.CNSFACJ = @CNSFACJ


      IF (SELECT COALESCE(SUM (VALOR),0) FROM PCJ WHERE PCJ.CODCAJA = @CODCAJA AND PCJ.CNSFACJ = @CNSFACJ ) = 0
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'El recibo no tiene detalles de pago.'
      END
      IF  (SELECT COALESCE(SUM (VALOR),0) FROM PCJ WHERE PCJ.CODCAJA = @CODCAJA AND PCJ.CNSFACJ = @CNSFACJ ) > 0
      BEGIN
         IF (SELECT COALESCE(SUM (VALOR),0) FROM PCJ WHERE PCJ.CODCAJA = @CODCAJA AND PCJ.CNSFACJ = @CNSFACJ ) <>  @TOTAL
         BEGIN
            INSERT INTO @TBLERRORES(ERROR) SELECT 'El valor del detalle de pago, es diferente al valor del Recibo'
         END
      END
      IF @FECHAFCJ IS NULL
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'La fecha del recibo no Valida'
      END
      IF @FECHAFCJ > GETDATE()
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'La fecha del recibo es mayor a la fecha actual'
      END
      IF NOT EXISTS(SELECT * FROM PRI WHERE FECHA_INI<=@FECHAFCJ AND FECHA_FIN+1>@FECHAFCJ AND COALESCE(CERRADO,0)=0)
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'El periodo contable esta cerrado '+COALESCE(CONVERT(VARCHAR,@FECHAFCJ,103),'NO TENGO FECHA')
      END
      IF (SELECT CERRADA FROM FCJ WHERE FCJ.CODCAJA = @CODCAJA AND FCJ.CNSFACJ = @CNSFACJ ) = 1
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'El recibo ya se encuentra confirmado'
      END
      IF (SELECT ESTADO FROM FCJ WHERE FCJ.CODCAJA = @CODCAJA AND FCJ.CNSFACJ = @CNSFACJ ) = 'D'
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'No se puede Confirmar un Recibo Desecho.'
      END
      IF (SELECT ESTADO FROM FCJ WHERE FCJ.CODCAJA = @CODCAJA AND FCJ.CNSFACJ = @CNSFACJ ) = 'A'
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'No se puede Confirmar un Recibo Anulado.'
      END
      IF @TOTAL<=0
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'No se puede Confirmar un Recibo Con Valor Cero (0).'
      END
      IF (SELECT COUNT(1) FROM MCP WHERE PROCEDENCIA='CAJA' AND   REFERENCIA2 = @CODCAJA AND REFERENCIA1 = @CNSFACJ   AND COALESCE(ANULADO,0)=0) <> 0
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'El recibo ya se encuentra contabilizado'
      END
      IF (SELECT ESTADO  FROM AUT WHERE  NOAUT  = @NOADMISION AND  @PROCEDENCIA = 'CE' ) = 'Anulada'
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'La Autorización fue anulada, no se puede confirmar.'
      END
      IF (SELECT COUNT(1) FROM  ACJ WHERE  CODCAJA = @CODCAJA AND ABIERTA = 1 ) = 0
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'La caja no se encuentra abierta.'
      END
      IF (SELECT COUNT(*) FROM @TBLERRORES)>0
      BEGIN
            SELECT 'KO' OK
            SELECT ERROR FROM @TBLERRORES
            RETURN
      END
      EXEC SPK_CIERRERECIBO_CAJA @CODCAJA,@CNSFACJ,'01',@IDSEDE,@USUARIO,@SYS_ComputerName
      EXEC SPK_ACTUALIZA_SALDO_BANCO @CNSFACJ ,@CODCAJA
      EXEC SPK_NC_CONTAB_CAJA_ING @CNSFACJ, @CODCAJA, @USUARIO, @SYS_COMPUTERNAME, @COMPANIA, @IDSEDE,''

      --SELECT 'OK' OK

      SELECT  @VALORTOTAL = FCJ.VALORTOTAL-SUM(COALESCE(PCJ.VALOR,0)) 
      FROM    FCJ LEFT JOIN PCJ ON FCJ.CODCAJA=PCJ.CODCAJA 
                               AND FCJ.CNSFACJ=PCJ.CNSFACJ 
      WHERE   FCJ.CODCAJA = @CODCAJA 
      AND     FCJ.CNSFACJ = @CNSFACJ 
      GROUP BY FCJ.VALORTOTAL
      
      SELECT @CERRADA = CERRADA FROM FCJ WHERE FCJ.CODCAJA = @CODCAJA  AND  FCJ.CNSFACJ = @CNSFACJ
      SELECT 'OK' OK ,@VALORTOTAL VALORFALTANTE , COALESCE(VALORCOPAGO,0) VALORCOPAGO, @CODCAJA CODCAJA ,@CNSFACJ CNSFACJ ,@CNSACJ_CAJ CNSACJ
             ,GENEROCAJA ,TIPOCAJA ,@CERRADA CERRADA
      FROM   AUT 
      WHERE  IDAUT = @IDAUT

      RETURN
   END
   IF @METODO = 'IMPRIMIR_RECIBO'
   BEGIN
      SELECT @IDAUT = IDAUT
      FROM OPENJSON(@PARAMETROS)WITH(        IDAUT      VARCHAR(20)            '$.IDAUT' )
      PRINT '@SYS_COMPUTERNAME='+@SYS_COMPUTERNAME
      IF (SELECT COUNT(*) FROM AUT WHERE IDAUT=@IDAUT)=0
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'No existe la Autorización'
      END
      SELECT @CODCAJA = CODCAJA ,@CNSFACJ = NORECIBOCAJA FROM AUT WHERE  IDAUT = @IDAUT
      IF (SELECT COALESCE(CERRADA,0) FROM FCJ WHERE CODCAJA = @CODCAJA AND CNSFACJ = @CNSFACJ) <> 1
         INSERT INTO @TBLERRORES(ERROR) SELECT 'Recibo NO esta Confirmado'

      IF (SELECT COUNT(*) FROM @TBLERRORES) > 0
      BEGIN
         SELECT 'KO' OK
         SELECT ERROR FROM @TBLERRORES
         RETURN
      END

      --CMT AUT
		SELECT  'OK'OK, AUT.FACTURABLE, AUT.FACTURADA,  AUT.IDAUT ,AFI.TIPO_DOC, AFI.DOCIDAFILIADO, AFI.NOMBREAFI, AFI.DIRECCION, AFI.SEXO, AUT.NUMAUTORIZA
            ,AUT.IDPLAN ,AUT.IDTERCEROCA ,AFI.CELULAR, AFI.TELEFONORES,AFI.EDAD, COALESCE( AFI.IDALTERNA,'') IDALTERNA , CIUAFI.NOMBRE [CIU_NOMBRE]
            ,AFI.EMAIL, AFI.IDTIPOAFILIACION,AFI.ESTADO_CIVIL ,CIUMED.NOMBRE [CIU_NOMBRE_MED], NIVELSOCIOEC, AUT.NUMCARNET, AFI.TIPOAFILIADO
            ,CASE   WHEN AFI.TIPOAFILIADO = 'C' THEN 'Cotizante'
                     WHEN AFI.TIPOAFILIADO = 'B' THEN 'Beneficiario'
                     WHEN AFI.TIPOAFILIADO = 'J' THEN 'Jubilado'
                     WHEN AFI.TIPOAFILIADO = 'A' THEN 'Adicional'
                     WHEN AFI.TIPOAFILIADO = 'S' THEN 'Sustitución Pensional'
                     WHEN AFI.TIPOAFILIADO = 'Sb' THEN 'Subsidiado'
                     WHEN AFI.TIPOAFILIADO = 'SR' THEN 'Sin régimen'
                     WHEN AFI.TIPOAFILIADO = 'TA' THEN 'Tomador/Amparado'
                     WHEN AFI.TIPOAFILIADO = 'RE' THEN 'Régimen Especiales o de Excepción'
                     WHEN AFI.TIPOAFILIADO = 'SN' THEN 'S/N'
                     WHEN AFI.TIPOAFILIADO = 'S/' THEN 'S/N'
                     WHEN AFI.TIPOAFILIADO = 'S/N' THEN 'S/N' 
                     ELSE '' 
               END [TIPOAFI_NOMBRE]
            ,CONVERT (DATE ,AUT.FECHA) FECHA ,CONVERT(varchar,AUT.FECHA,104) FECHAFORMATO, CONVERT (DATETIME ,AUT.FECHA) FECHACOMPLETA
            ,DATEPART(HOUR, AUT.FECHA) HORA  ,Format(AUT.FECHA,'dd/MM/yyyy hh:mm tt') AS FECHA_HORARIO,   CONVERT(varchar,AUT.FECHA,104) FECHAAUT
            ,AUT.OBS, AUT.IDSEDE, SED.DESCRIPCION [SED_NOMBRE], SED.DIRECCION [SED_DIRECCION]
            ,SED.TELEFONOS [SED_TELEFONOS],  CIUSED.NOMBRE [SED_CIUDAD], SED.NIT [SED_NIT], SED.DV [SED_DV]
            ,FCJ.N_RECIBO , FCJ.CNSFACJ, FCJ.CODCAJA, FCJ.CLASE_FAC, FCJ.NOADMISION, FCJ.VALORTOTAL,FCJ.ESTADO, FCJ.CERRADA, FCJ.OBSERVACION
            ,AUT.N_FACTURA, FCJ.USUARIO USUARIO, USUSU.NOMBRE [USUSU_NOMBRE]
            ,(SELECT CODCAJERO FROM USUSU WHERE USUARIO =  (SELECT USUARIO FROM FCJ WHERE CNSFACJ= @CNSFACJ AND FCJ.CODCAJA = @CODCAJA) ) [COD_CAJERO]
      FROM  AUT  INNER JOIN FCJ        ON AUT.NORECIBOCAJA   = FCJ.CNSFACJ AND FCJ.CODCAJA = @CODCAJA
                 INNER JOIN AFI        ON AUT.IDAFILIADO     = AFI.IDAFILIADO
                  LEFT JOIN HCA        ON AUT.CONSECUTIVOHCA = HCA.CONSECUTIVO
                  LEFT JOIN MED        ON HCA.IDMEDICO       = MED.IDMEDICO
                  LEFT JOIN MES        ON MED.IDEMEDICA      = MES.IDEMEDICA
                 INNER JOIN SED        ON SED.IDSEDE         = AUT.IDSEDE
                 INNER JOIN USUSU      ON FCJ.USUARIO        = USUSU.USUARIO
                  LEFT JOIN CIU CIUSED ON SED.CIUDAD         = CIUSED.CIUDAD
                  LEFT JOIN CIU CIUAFI ON AFI.CIUDAD         = CIUAFI.CIUDAD
                  LEFT JOIN CIU CIUMED ON MED.CIUDAD         = CIUMED.CIUDAD
      WHERE  AUT.IDAUT = @IDAUT

      SELECT FCJ.NOADMISION, FCJD.CONCEPTO,  CPCJ.DESCRIPCION CONCEPTO_DESC,  FCJD.VALORUNITARIO, FCJD.CANTIDAD, FCJD.VALORTOTAL, FCJD.DCTO
            ,FCJD.VLRDESCUENTO 
      FROM   FCJ INNER JOIN FCJD ON FCJ.CNSFACJ   = FCJD.CNSFACJ 
                                AND FCJ.CODCAJA = FCJD.CODCAJA  
                 INNER JOIN CPCJ ON FCJD.CONCEPTO = CPCJ.CODIGO
      WHERE  FCJ.CNSFACJ = @CNSFACJ
      AND    FCJ.CODCAJA = @CODCAJA

      SELECT PCJ.CODCAJA, PCJ.CNSPCJ, PCJ.CNSFACJ, PCJ.TIPOPAGO, FPA.DESCRIPCION, PCJ.VALOR, PCJ.FECHA, PCJ.CNSACJ,PCJ.BANCO,BCO.DESCRIPCION [BANCO_DESC]
            ,PCJ.NUMEROAUTORIZA, PCJ.NUMERODOCUMENTO
      FROM   PCJ INNER JOIN FPA ON PCJ.TIPOPAGO=  FPA.FORMAPAGO 
                  LEFT JOIN BCO ON PCJ.BANCO = BCO.BANCO
      WHERE  CODCAJA = @CODCAJA 
      AND    CNSFACJ = @CNSFACJ

      SELECT SUM(PCJ.VALOR) VALOR_FPA 
      FROM   PCJ  
      WHERE  CODCAJA = @CODCAJA 
      AND    CNSFACJ = @CNSFACJ

      SELECT TER.RAZONSOCIAL, FCJPCXC.CNSFACJ, FCJPCXC.CODCAJA, FCJPCXC.CNSCXC, FCJPCXC.N_FACTURA, FCJPCXC.ITEM_FCXCDV, FCJPCXC.IDTERCERO, FCJPCXC.VALOR
            ,FCJPCXC.ESTADO, FCJPCXC.CNSFPAG ,FCJPCXC.TIPOCXC, FCJPCXC.VLR_IMPUESTOS 
      FROM   FCJPCXC  LEFT JOIN TER ON FCJPCXC.IDTERCERO = TER.IDTERCERO
      WHERE  FCJPCXC.CODCAJA = @CODCAJA 
      AND    FCJPCXC.CNSFACJ = @CNSFACJ

      SELECT  FCJPCXC.CNSFACJ, FCJPCXC.CODCAJA,COALESCE( SUM(FCJPCXC.VALOR),0) VALOR, COALESCE(SUM( FCJPCXC.VLR_IMPUESTOS),0) IMPUESTO FROM  FCJPCXC
      WHERE   FCJPCXC.CODCAJA = @CODCAJA 
      AND     FCJPCXC.CNSFACJ = @CNSFACJ
      GROUP BY FCJPCXC.CNSFACJ, FCJPCXC.CODCAJA
      
      RETURN
   END
   IF @METODO = 'DEVOLVER_RECIBO'
	BEGIN
		SELECT @IDAUT = IDAUT
		FROM OPENJSON(@PARAMETROS)WITH(
		   IDAUT        VARCHAR(20)    '$.IDAUT' 
		)

		IF (SELECT COUNT(*) FROM FCJ WHERE  CODCAJA = @CODCAJA AND CNSFACJ = @CNSFACJ AND CERRADA = 1 ) > 0
		BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'El recibo se encuentra recaudado.'
		END

		IF (SELECT COUNT(*) FROM @TBLERRORES)> 0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END
		
      SELECT @CNSFACJ = NORECIBOCAJA ,@CODCAJA = CODCAJA FROM AUT WHERE @IDAUT = IDAUT
		BEGIN TRY

			EXEC SPK_DEVUELVERECIB_CAJA @CODCAJA,@CNSFACJ,'01',@IDSEDE

		END TRY
		BEGIN CATCH
			INSERT INTO @TBLERRORES(ERROR) SELECT ERROR_MESSAGE();
		END CATCH
		IF(SELECT COUNT(*) FROM @TBLERRORES)>0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END
		          
      SELECT 'OK' OK, GENEROCAJA ,TIPOCAJA ,COALESCE(VALORCOPAGO,0) VALORCOPAGO FROM AUT WHERE IDAUT = @IDAUT

   END
   IF @METODO = 'DESCUENTOS'
   BEGIN
      PRINT 'DESCUENTOS'
      SELECT @AUT  = AUT
      FROM OPENJSON (@PARAMETROS)
      WITH(
         AUT   NVARCHAR(MAX)     AS JSON
      )
      SELECT @IDAUT   = JSON_VALUE(@AUT , '$.IDAUT')
      SELECT @TIPODTO = JSON_VALUE(@AUT, '$.TIPODTO.value') , @DESCUENTO = JSON_VALUE(@AUT, '$.DESCUENTO')
      IF @TIPODTO NOT IN ('P','V')
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'Debe seleccionar un tipo de descuento'
         SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
      END
      IF @TIPODTO = 'P' AND @DESCUENTO <= 0 AND @DESCUENTO > 100
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'Ingrese el Procentaje Correcto de Descuento'
         SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
      END
      IF @TIPODTO = 'V' AND @DESCUENTO <= 0
      BEGIN
         INSERT INTO @TBLERRORES(ERROR) SELECT 'Ingrese el Valor Correcto de Descuento'
         SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
      END
      SELECT @NORECIBOCAJA = NORECIBOCAJA , @NOAUT = NOAUT ,@IDTERCEROCA = IDTERCEROCA ,@VALORCOPAGO = VALORCOPAGO
            ,@IDCONTRATANTE_AUT = AUT.IDCONTRATANTE ,@IDPROVEEDOR_AUT = IDPROVEEDOR ,@IDPLAN_AUT = IDPLAN
            ,@PREFIJO_AUT = AUT.PREFIJO ,@GENEROCAJA_AUT = AUT.GENEROCAJA
      FROM   AUT WHERE IDAUT = @IDAUT

      SELECT @COBRARPC = COBRARPC --EXCOBROPC, LIQUIDARPC, 
      FROM   VW_PXS 
      WHERE  IDADMINISTRADORA = @IDCONTRATANTE_AUT
      AND    IDTERCERO        = @IDPROVEEDOR_AUT 
      AND    IDPLAN           = @IDPLAN_AUT
      AND    PREFIJO          = @PREFIJO_AUT

      SELECT @ENVIODICAJA = ENVIODICAJA FROM TER WHERE IDTERCERO = @IDTERCEROCA --CMT TER,ENVIODICAJA
      --PROCESO DE DESCUENTO
      DELETE TFCJDD WHERE CNSFACJ=@NORECIBOCAJA
      DELETE TFCJD  WHERE CNSFACJ=@NORECIBOCAJA
      DELETE TFCJ   WHERE CNSFACJ=@NORECIBOCAJA

      
      

      IF DBO.FNK_VALORVARIABLE('CETIPOAUTORIZACION') = 'CEHOSP'
      BEGIN
         UPDATE AUT SET GENEROCAJA = 0 ,TIPODTO = @TIPODTO ,DESCUENTO = @DESCUENTO WHERE IDAUT = @IDAUT
         EXEC SPK_PAGOSCAJA_AUT_CEHOSP @NOAUT ,@SYS_COMPUTERNAME, '01', @IDSEDE ,@USUARIO ,1
      END
      ELSE
      BEGIN
         IF @ENVIODICAJA = 1
         BEGIN
            UPDATE AUT SET GENEROCAJA = 0 ,TIPODTO = @TIPODTO ,DESCUENTO = @DESCUENTO WHERE IDAUT = @IDAUT
            EXEC SPK_PAGOSCAJA_AUT @NOAUT,@SYS_COMPUTERNAME, '01',@IDSEDE,@USUARIO, 1
         END
         ELSE
         BEGIN
            IF @VALORCOPAGO > 0 AND @COBRARPC = 1
            BEGIN
               IF @GENEROCAJA_AUT <> 1 
               BEGIN
                  UPDATE AUT SET GENEROCAJA = 0 ,TIPODTO = @TIPODTO ,DESCUENTO = @DESCUENTO WHERE IDAUT = @IDAUT
                  EXEC SPK_PAGOSCAJA_AUT @NOAUT,@SYS_COMPUTERNAME,'01',@IDSEDE, @USUARIO,0
               END
            END
         END
      END
      SELECT 'OK' OK
      RETURN
   END
   IF @METODO = 'QUITAR_DESCUENTOS'
   BEGIN
      PRINT 'QUITAR_DESCUENTOS'
      SELECT @AUT  = AUT
      FROM OPENJSON (@PARAMETROS)
      WITH(
         AUT   NVARCHAR(MAX)     AS JSON
      )
      SELECT @IDAUT   = JSON_VALUE(@AUT , '$.IDAUT')
      SELECT @TIPODTO = JSON_VALUE(@AUT, '$.TIPODTO.value') , @DESCUENTO = JSON_VALUE(@AUT, '$.DESCUENTO')

      SELECT @NORECIBOCAJA = NORECIBOCAJA , @NOAUT = NOAUT ,@IDTERCEROCA = IDTERCEROCA ,@VALORCOPAGO = VALORCOPAGO
            ,@IDCONTRATANTE_AUT = AUT.IDCONTRATANTE ,@IDPROVEEDOR_AUT = IDPROVEEDOR ,@IDPLAN_AUT = IDPLAN
            ,@PREFIJO_AUT = AUT.PREFIJO ,@GENEROCAJA_AUT = AUT.GENEROCAJA
      FROM   AUT WHERE IDAUT = @IDAUT

      SELECT @COBRARPC = COBRARPC --EXCOBROPC, LIQUIDARPC, 
      FROM   VW_PXS 
      WHERE  IDADMINISTRADORA = @IDCONTRATANTE_AUT
      AND    IDTERCERO        = @IDPROVEEDOR_AUT 
      AND    IDPLAN           = @IDPLAN_AUT
      AND    PREFIJO          = @PREFIJO_AUT

      SELECT @ENVIODICAJA = ENVIODICAJA FROM TER WHERE IDTERCERO = @IDTERCEROCA --CMT TER,ENVIODICAJA

      UPDATE AUT SET DESCUENTO=0 ,TIPODTO='' WHERE IDAUT = @IDAUT

      IF DBO.FNK_VALORVARIABLE('CETIPOAUTORIZACION') = 'CEHOSP'
      BEGIN
         EXEC SPK_PAGOSCAJA_AUT_CEHOSP @NOAUT,@SYS_COMPUTERNAME ,'01',@IDSEDE,@USUARIO, 1
      END
      ELSE
      BEGIN
         IF @ENVIODICAJA = 1
         BEGIN
            EXEC SPK_PAGOSCAJA_AUT @NOAUT,@SYS_COMPUTERNAME,'01',@IDSEDE,@USUARIO, 1
         END
         ELSE
         BEGIN
            IF @VALORCOPAGO > 0 AND @COBRARPC = 1
            BEGIN
               IF @GENEROCAJA_AUT <> 1 
               BEGIN
                  EXEC SPK_PAGOSCAJA_AUT @NOAUT,@SYS_COMPUTERNAME,'01',@IDSEDE,@USUARIO, 0
               END
            END
         END
      END
      SELECT 'OK' OK

      RETURN
   END
	IF @METODO = 'RELIQUIDAR'
	BEGIN
		SELECT @IDAUT = IDAUT
		FROM OPENJSON (@PARAMETROS)
		WITH		 (	IDAUT				VARCHAR(20)			'$.IDAUT'	)
		
		
		IF  (SELECT COALESCE(FACTURADA,0) FROM AUT WHERE IDAUT = @IDAUT) = 1
		BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'El registro se encuentra Facturado'
		END
		IF (SELECT COUNT(*) FROM @TBLERRORES)> 0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END
		ELSE
		BEGIN
			BEGIN TRY
				EXEC SPK_COPAGO_AUT_CEHOSP_RELIQ @IDAUT,'CE', @SYS_COMPUTERNAME, @COMPANIA, @IDSEDE, @USUARIO
			END TRY  
			BEGIN CATCH 
				INSERT INTO @TBLERRORES(ERROR) SELECT ERROR_MESSAGE() ;  
			END CATCH  
			IF (SELECT COUNT(*) FROM @TBLERRORES)> 0
			BEGIN
				SELECT 'KO' OK
				SELECT ERROR FROM @TBLERRORES
				RETURN
			END
			SELECT 'OK'OK
		END 
	END
END

