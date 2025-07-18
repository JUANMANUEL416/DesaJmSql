CREATE OR ALTER PROCEDURE DBO.SPQ_SER
@JSON  NVARCHAR(MAX)
WITH   ENCRYPTION
AS
DECLARE  @PARAMETROS  NVARCHAR(MAX)		,@CLASEPLANTILLA VARCHAR(20)		,@PROCESO VARCHAR(20)		,@dataSER NVARCHAR(MAX)
		,@GRUPO          VARCHAR(8)     ,@SYS_COMPUTERNAME  VARCHAR(254)     ,@SEDE            VARCHAR(5)		,@IDMEDICO        VARCHAR(12)
		,@METODO      VARCHAR(100)		,@USUARIO  VARCHAR(20)		,@IDAREA            VARCHAR(20)	,@CCOSTO         VARCHAR(20)
		,@IDAFILIADO  VARCHAR(20)		,@SEXO	VARCHAR(20)			,@COMPANIA VARCHAR(2)		,@dataTARD NVARCHAR(MAX)	,@dataTARDV NVARCHAR(MAX)
		,@FNACIMIENTO DATE				,@ITEM INT,@FECHAI    VARCHAR(10),  @FINICIAL DATETIME , @FFINAL DATETIME ,@HORAI     VARCHAR(5)
		,@FECHAF    VARCHAR(10)			,@HORAF     VARCHAR(5), @IDREFERENCIA VARCHAR(20)		,@IDSERVICIOREL_ORI VARCHAR(20)
		,@IDSERVICIOREL		VARCHAR(20) ,@TIPO  VARCHAR(2)  , @QPEDIATRICO  DECIMAL(14,2)  ,@QADULTO  BIT   ,@POR_HORAS	INT
      ,@ENFERMERIA  INT   ,@ENFHORAS	INT
DECLARE @TBLERRORES TABLE(ERROR VARCHAR(500));
DECLARE @LOG_ERR TABLE (ERROR VARCHAR(500));
BEGIN
	SELECT *
	INTO #JSON
	FROM OPENJSON (@json)
	WITH (
		METODO         VARCHAR(100)    '$.METODO',
		USUARIO        VARCHAR(20)     '$.USUARIO',
		PARAMETROS     NVARCHAR(MAX)  AS JSON
	)

	SELECT @METODO = METODO 
		,@PARAMETROS = PARAMETROS
		,@USUARIO	 = USUARIO
	FROM #JSON
		PRINT 'USUARIO:'+@USUARIO
		SELECT @GRUPO = DBO.FNK_DESCIFRAR(GRUPO) FROM USUSU WHERE USUARIO = @USUARIO
		SELECT @SYS_COMPUTERNAME = SYS_COMPUTERNAME ,@IDMEDICO = IDMEDICO FROM USUSU WHERE USUARIO = @USUARIO
		SELECT @SEDE = IDSEDE ,@IDAREA = IDAREA ,@CCOSTO = CCOSTO,@COMPANIA = COMPANIA FROM UBEQ WHERE SYS_ComputerName = @SYS_COMPUTERNAME


	IF @METODO='ONCOLOGICOS'
	BEGIN
		SELECT @IDAFILIADO = IDAFILIADO
		FROM OPENJSON (@PARAMETROS)
		WITH (IDAFILIADO  VARCHAR(20) '$.IDAFILIADO')

		SELECT @FNACIMIENTO = FNACIMIENTO
			,@SEXO = SEXO
		FROM AFI 
		WHERE IDAFILIADO = @IDAFILIADO

		SELECT 'OK' OK ,@IDAFILIADO IDAFILIADO

		SELECT SER.IDSERVICIO
			,SER.DESCSERVICIO
			,SER.SEXO
			,COALESCE(SER.CIRUGIA, 0) CIRUGIA
			,COALESCE(SER.MEZCLA, 0) MEZCLA
			,CASE 
				WHEN COALESCE(EXCLUYEPOSOLOGIA, 0) = 1
					THEN 0
				ELSE COALESCE(SER.MEDICAMENTOS, 0)
				END MEDICAMENTOS
			,COALESCE(SER.IDARTICULO, 'NA') IDARTICULO
			,CAST(CASE 
					WHEN COALESCE(EXCLUYEPOSOLOGIA, 0) = 1
						THEN 0
					ELSE COALESCE(SER.MDOSIF, 0)
					END AS BIT) MDOSIF
			,COALESCE(EQUICC, 0.0) EQUICC
			,COALESCE(SER.MULTIDOSIS, 0) MULTIDOSIS
			,SER.PRESUNI
			,SER.VIA
			,COALESCE(LIBREFORMULACION, 0) LIBREFORMULACION
			,CAST(COALESCE(EXCLUYEPOSOLOGIA, 0) AS BIT) EXCLUYEPOSOLOGIA
			,(SELECT TOP 1 CAST(COALESCE(BIOLOGICO, 0) AS BIT) FROM IART WHERE IDARTICULO = SER.IDARTICULO) BIOLOGICO
			,CAST(COALESCE(T_ESTABILIDAD, 0.0) AS INT) T_ESTABILIDAD
			,0 RAZONNEC
			,CAST(0 AS BIT) LUNES
			,CAST(0 AS BIT) MARTES
			,CAST(0 AS BIT) MIERCOLES
			,CAST(0 AS BIT) JUEVES
			,CAST(0 AS BIT) VIERNES
			,CAST(0 AS BIT) SABADO
			,CAST(0 AS BIT) DOMINGO
			,IART.ALERTA
			,UNIRS = (SELECT ITEM,DXUNIRS FROM IARTDX WHERE IDARTICULO = SER.IDARTICULO FOR JSON AUTO)
			,CICLO = 1
			,TIPODURACION = 'SEMANAS'
			,SER.ONCOLOGIA
		FROM [dbo].[SER]
		LEFT JOIN IART ON IART.IDARTICULO = SER.IDARTICULO
		WHERE COALESCE(SER.ONCOLOGIA, 0) = 1
			AND SER.ESTADO = 'Activo'
			AND SER.SEXO IN (@SEXO, 'Ambos')
			AND (
				REPLACE(COALESCE(TIPORANGOE, ''), 'NA', '') = ''
				OR (
					REPLACE(COALESCE(TIPORANGOE, ''), 'NA', '') = 'I'
					AND DATEDIFF(DAY, @FNACIMIENTO, current_timestamp) / (365.23076923074) BETWEEN COALESCE(SER.EDADINICIAL, 0)
						AND COALESCE(SER.EDADFINAL, 120)
					)
				OR (
					REPLACE(COALESCE(TIPORANGOE, ''), 'NA', '') = 'E'
					AND DATEDIFF(DAY, @FNACIMIENTO, current_timestamp) / (365.23076923074) NOT BETWEEN COALESCE(SER.EDADINICIAL, 0)
						AND COALESCE(SER.EDADFINAL, 120)
					)
				)
		ORDER BY SER.DESCSERVICIO

		RETURN
	END

	IF @METODO='NO_ONCOLOGICOS'
	BEGIN
		SELECT @IDAFILIADO = IDAFILIADO
		FROM OPENJSON (@PARAMETROS)
		WITH (IDAFILIADO  VARCHAR(20) '$.IDAFILIADO')

		SELECT @FNACIMIENTO = FNACIMIENTO
			,@SEXO = SEXO
		FROM AFI 
		WHERE IDAFILIADO = @IDAFILIADO

		SELECT 'OK' OK ,@IDAFILIADO IDAFILIADO

		SELECT SER.IDSERVICIO
			,SER.DESCSERVICIO
			,SER.SEXO
			,COALESCE(SER.CIRUGIA, 0) CIRUGIA
			,COALESCE(SER.MEZCLA, 0) MEZCLA
			,CASE 
				WHEN COALESCE(EXCLUYEPOSOLOGIA, 0) = 1
					THEN 0
				ELSE COALESCE(SER.MEDICAMENTOS, 0)
				END MEDICAMENTOS
			,COALESCE(SER.IDARTICULO, 'NA') IDARTICULO
			,CAST(CASE 
					WHEN COALESCE(EXCLUYEPOSOLOGIA, 0) = 1
						THEN 0
					ELSE COALESCE(SER.MDOSIF, 0)
					END AS BIT) MDOSIF
			,COALESCE(EQUICC, 0.0) EQUICC
			,COALESCE(SER.MULTIDOSIS, 0) MULTIDOSIS
			,SER.PRESUNI
			,SER.VIA
			,COALESCE(LIBREFORMULACION, 0) LIBREFORMULACION
			,CAST(COALESCE(EXCLUYEPOSOLOGIA, 0) AS BIT) EXCLUYEPOSOLOGIA
			,(SELECT TOP 1 CAST(COALESCE(BIOLOGICO, 0) AS BIT) FROM IART WHERE IDARTICULO = SER.IDARTICULO) BIOLOGICO
			,CAST(COALESCE(T_ESTABILIDAD, 0.0) AS INT) T_ESTABILIDAD
			,0 RAZONNEC
			,CAST(0 AS BIT) LUNES
			,CAST(0 AS BIT) MARTES
			,CAST(0 AS BIT) MIERCOLES
			,CAST(0 AS BIT) JUEVES
			,CAST(0 AS BIT) VIERNES
			,CAST(0 AS BIT) SABADO
			,CAST(0 AS BIT) DOMINGO
			,IART.ALERTA
			,UNIRS = (SELECT ITEM,DXUNIRS FROM IARTDX WHERE IDARTICULO = SER.IDARTICULO FOR JSON AUTO)
			,CICLO = 1
			,TIPODURACION = 'SEMANAS'
			,SER.ONCOLOGIA
		FROM [dbo].[SER]
		LEFT JOIN IART ON IART.IDARTICULO = SER.IDARTICULO
		WHERE COALESCE(SER.ONCOLOGIA, 0) = 0
			AND COALESCE(SER.MEDICAMENTOS, 0) = 1
			AND SER.ESTADO = 'Activo'
			AND SER.SEXO IN (@SEXO, 'Ambos')
			AND (
				REPLACE(COALESCE(TIPORANGOE, ''), 'NA', '') = ''
				OR (
					REPLACE(COALESCE(TIPORANGOE, ''), 'NA', '') = 'I'
					AND DATEDIFF(DAY, @FNACIMIENTO, current_timestamp) / (365.23076923074) BETWEEN COALESCE(SER.EDADINICIAL, 0)
						AND COALESCE(SER.EDADFINAL, 120)
					)
				OR (
					REPLACE(COALESCE(TIPORANGOE, ''), 'NA', '') = 'E'
					AND DATEDIFF(DAY, @FNACIMIENTO, current_timestamp) / (365.23076923074) NOT BETWEEN COALESCE(SER.EDADINICIAL, 0)
						AND COALESCE(SER.EDADFINAL, 120)
					)
				)
		ORDER BY SER.DESCSERVICIO

		RETURN
	END

	IF @METODO = 'CRUDSERVICIO' --PRESUNI
	BEGIN
		SELECT @dataSER =  dataSER
		FROM OPENJSON (@PARAMETROS)
		WITH		 (
					dataSER			NVARCHAR(MAX)  AS JSON
					)

		SELECT @PROCESO     = JSON_VALUE(@dataSER ,'$.PROCESO') 
		SELECT    *  INTO #DATOSER
		FROM OPENJSON (@dataSER)
		WITH (
			IDSERVICIO			VARCHAR(200) '$.IDSERVICIO'
			,PREFIJO			VARCHAR(200) '$.PREFIJO'
			,POS				BIT			'$.POS'
			,ANESTESIA			BIT			'$.ANESTESIA'
			,IDALTERNA			VARCHAR(20) '$.IDALTERNA'
			,DESCSERVICIO		VARCHAR(200) '$.DESCSERVICIO'
			,NIVELATENCION		VARCHAR(20) '$.NIVELATENCION'
			,GRUPOQX			VARCHAR(20) '$.GRUPOQX'
			,IDJERARQUIA		VARCHAR(20) '$.IDJERARQUIA'
			,NOM_GENERIC		VARCHAR(200) '$.NOM_GENERIC'
			,COMENTARIOS		VARCHAR(200) '$.COMENTARIOS'
			,CIRUGIA			BIT			'$.CIRUGIA'
			,MSUBSERVICIO		BIT			'$.MSUBSERVICIO'
			,MOBSOBLIGATORIA	BIT			'$.MOBSOBLIGATORIA'
			,MPROVEEDOR			BIT			'$.MPROVEEDOR'
			,ESVACUNA			BIT			'$.ESVACUNA'
			,POSS				BIT			'$.POSS'
			,PYP				BIT			'$.PYP'
			,SEXO				VARCHAR(20) '$.SEXO'
			,ESTADO				VARCHAR(20) '$.ESTADO'
			,IDARTICULO			VARCHAR(20) '$.IDARTICULO'
			,IDGENERICO			VARCHAR(20) '$.IDGENERICO'
			,NIVELFUNCIONARIO	INT '$.NIVELFUNCIONARIO'
			,NIVELSEDE			INT '$.NIVELSEDE'
			,TELECONSULTA		INT '$.TELECONSULTA'
			,SMS				VARCHAR(200) '$.SMS'
			,MEDICAMENTOS		BIT			'$.MEDICAMENTOS'
			,DIASRESTAUTO		INT '$.DIASRESTAUTO'
			,REQAUTORIZACION		BIT			'$.REQAUTORIZACION'
			,TIPOAUTORIZACION		VARCHAR(20) '$.TIPOAUTORIZACION'
			,TIPORANGOE			VARCHAR(20) '$.TIPORANGOE'
			,EDADINICIAL		INT '$.EDADINICIAL'
			,EDADFINAL		INT '$.EDADFINAL'
			,IDPREPARACION		VARCHAR(20) '$.IDPREPARACION'
			,SPD			BIT			'$.SPD'
			,CLASIF1		VARCHAR(20) '$.CLASIF1'
			,CLASIF2		VARCHAR(20) '$.CLASIF2'
			,CODIGORIPS		VARCHAR(5) '$.CODIGORIPS'
			
			,CODFURIPS		VARCHAR(20) '$.CODFURIPS'
			,CCOSTO			VARCHAR(20) '$.CCOSTO'
			,IVA			VARCHAR(20) '$.IVA'
			,IDIMPUESTO		VARCHAR(20) '$.IDIMPUESTO'
			,IDCLASE		VARCHAR(20) '$.IDCLASE'
			,CANTIDAD		INT '$.CANTIDAD'
			,CANTMAXIMA		INT '$.CANTMAXIMA'
			,CANTMAXIMA_CE	INT '$.CANTMAXIMA_CE'
			,CANTMAXIMA_FME	INT '$.CANTMAXIMA_FME'
			,MRECARGONOCTURNO	BIT			'$.MRECARGONOCTURNO'
			,TIPORECARGONOC		VARCHAR(20) '$.TIPORECARGONOC'
			,VLRRECARGONOC    DECIMAL(14,2) '$.VLRRECARGONOC'
			,DIASIGRN			BIT			'$.DIASIGRN'
			,CODCUM				VARCHAR(20) '$.CODCUM'
			,CODSISPRO			VARCHAR(20) '$.CODSISPRO'
			,IDEMEDICA			VARCHAR(20) '$.IDEMEDICA'
			,IDEMEDICAPAD			VARCHAR(20) '$.IDEMEDICAPAD'
			,VLRCOSTO		DECIMAL(14,2) '$.VLRCOSTO'
			,MINUTOSMS		INT '$.MINUTOSMS'
			,GRUPO			VARCHAR(20) '$.GRUPO'
			,ATENCION		VARCHAR(20) '$.ATENCION'
			,MLATERALIDAD			BIT			'$.MLATERALIDAD'
			,PRIORITARIO			BIT			'$.PRIORITARIO'
			,DURACIONCITA			INT '$.DURACIONCITA'
			,ONCOLOGIA				BIT			'$.ONCOLOGIA'
			,AMBITO				VARCHAR(20) '$.AMBITO'
			,IDSECCION    VARCHAR(20) '$.IDSECCION'
			,IDPLANILLA    VARCHAR(20) '$.IDPLANILLA'
			,IDEQUIPO_MUESTRA    VARCHAR(20) '$.IDEQUIPO_MUESTRA'
			,IDMUESTRA    VARCHAR(20) '$.IDMUESTRA'
			,DURACIONMUESTRA    DECIMAL(14,2) '$.DURACIONMUESTRA'
			,ENINTERFAZ    INT '$.ENINTERFAZ'
			,SERIADO				BIT			'$.SERIADO'
			,REPORTA				BIT			'$.REPORTA'
			,CODCUPS    VARCHAR(20) '$.CODCUPS'
			,CUPS_ID    INT '$.CUPS_ID'
			,DESCRIPCION_CUPS    VARCHAR(255) '$.DESCRIPCION_CUPS'
			,MDOSIF					BIT			'$.MDOSIF'
			,EQUICC    DECIMAL(14,2) '$.EQUICC'
			,PRESUNI    VARCHAR(20) '$.PRESUNI'
			,T_ESTABILIDAD    DECIMAL(14,2) '$.T_ESTABILIDAD'
			,MULTIDOSIS				BIT			'$.MULTIDOSIS'
			,LIBREFORMULACION		BIT			'$.LIBREFORMULACION'
			,VIA					 VARCHAR(20) '$.VIA'
			,TERAPIA				BIT			'$.TERAPIA'
			,EXCLUYEPOSOLOGIA		BIT			'$.EXCLUYEPOSOLOGIA'
			,TRANSFORMADO			BIT			'$.TRANSFORMADO'
			,MEZCLA					INT			'$.MEZCLA'
			,CLASEHTX				VARCHAR(20) '$.CLASEHTX'
			,EQUICCINF				DECIMAL(14,2) '$.EQUICCINF'
			,PROCESO				VARCHAR(20) '$.PROCESO'
			,HORARIO				BIT			'$.HORARIO'
			,HDESDE					TIME		'$.HDESDE'
			,HHASTA					TIME		'$.HHASTA'
			,ANTIGENO				BIT			'$.ANTIGENO'
			,VPAI					BIT			'$.VPAI'
			,VEXIST					BIT			'$.VEXIST'
			,MULTI_VAC					BIT			'$.MULTI_VAC'
			,CUANTODOSIS			INT			'$.CUANTODOSIS'
			,CUANTOREFUERZOS		INT			'$.CUANTOREFUERZOS'
			,COLOR					VARCHAR(20)			'$.COLOR'
			,SER_DILUYENTE			VARCHAR(20)			'$.SER_DILUYENTE'
			,CANTIDADMULTI			INT			'$.CANTIDADMULTI'
			,REQ_DILU				BIT			'$.REQ_DILU'
			,OBSAPOYO				VARCHAR(MAX)			'$.OBSAPOYO'
         ,ESAPLIM				BIT			'$.ESAPLIM'
         ,REQBOMBA				BIT			'$.REQBOMBA'
         ,ENFERMERIA				INT			'$.ENFERMERIA'
			,ENFHORAS			INT			'$.ENFHORAS'
         ,TIPOMED  VARCHAR(20)   '$.TIPOMED',
         UPR  VARCHAR(20)   '$.UPR',
         TIPOOTRO  VARCHAR(20)   '$.TIPOOTRO'         
		)
		IF 1 = 2
			BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'XXXXXX'
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
			END

		BEGIN TRY 
			IF UPPER(@PROCESO)='EDITAR' --CODIGORIPS
			BEGIN
				UPDATE SER SET IDSERVICIO=#DATOSER.IDSERVICIO, PREFIJO=#DATOSER.PREFIJO, POS=#DATOSER.POS, ANESTESIA=#DATOSER.ANESTESIA,  IDALTERNA=#DATOSER.IDALTERNA
				, DESCSERVICIO=#DATOSER.DESCSERVICIO, NIVELATENCION=#DATOSER.NIVELATENCION, GRUPOQX=#DATOSER.GRUPOQX, IDJERARQUIA=#DATOSER.IDJERARQUIA,  COMENTARIOS=#DATOSER.COMENTARIOS
				, CIRUGIA=#DATOSER.CIRUGIA, MSUBSERVICIO=#DATOSER.MSUBSERVICIO, MOBSOBLIGATORIA=#DATOSER.MOBSOBLIGATORIA, MPROVEEDOR=#DATOSER.MPROVEEDOR, ESVACUNA=#DATOSER.ESVACUNA, POSS=#DATOSER.POSS, PYP=#DATOSER.PYP, SEXO=#DATOSER.SEXO
				, ESTADO=#DATOSER.ESTADO, IDARTICULO=#DATOSER.IDARTICULO, IDGENERICO=#DATOSER.IDGENERICO, NIVELFUNCIONARIO=#DATOSER.NIVELFUNCIONARIO, NIVELSEDE=#DATOSER.NIVELSEDE, TELECONSULTA=#DATOSER.TELECONSULTA
				, SMS=#DATOSER.SMS, MEDICAMENTOS=#DATOSER.MEDICAMENTOS, DIASRESTAUTO=#DATOSER.DIASRESTAUTO, REQAUTORIZACION=#DATOSER.REQAUTORIZACION, TIPOAUTORIZACION=#DATOSER.TIPOAUTORIZACION,  TIPORANGOE=#DATOSER.TIPORANGOE
				, EDADINICIAL=#DATOSER.EDADINICIAL, EDADFINAL=#DATOSER.EDADFINAL, IDPREPARACION=#DATOSER.IDPREPARACION, SPD=#DATOSER.SPD, CLASIF1=#DATOSER.CLASIF1, CLASIF2=#DATOSER.CLASIF2, CODIGORIPS=#DATOSER.CODIGORIPS
				, CODFURIPS=#DATOSER.CODFURIPS, CCOSTO=#DATOSER.CCOSTO, IVA=#DATOSER.IVA, IDIMPUESTO=#DATOSER.IDIMPUESTO, IDCLASE=#DATOSER.IDCLASE, CANTIDAD=#DATOSER.CANTIDAD, CANTMAXIMA=#DATOSER.CANTMAXIMA, CANTMAXIMA_CE=#DATOSER.CANTMAXIMA_CE
				, CANTMAXIMA_FME=#DATOSER.CANTMAXIMA_FME, MRECARGONOCTURNO=#DATOSER.MRECARGONOCTURNO, TIPORECARGONOC=#DATOSER.TIPORECARGONOC, VLRRECARGONOC=#DATOSER.VLRRECARGONOC, DIASIGRN=#DATOSER.DIASIGRN
				, CODCUM=#DATOSER.CODCUM, CODSISPRO=#DATOSER.CODSISPRO, IDEMEDICA=#DATOSER.IDEMEDICA, VLRCOSTO=#DATOSER.VLRCOSTO, MINUTOSMS=#DATOSER.MINUTOSMS, GRUPO=#DATOSER.GRUPO, ATENCION=#DATOSER.ATENCION, MLATERALIDAD=#DATOSER.MLATERALIDAD
				, PRIORITARIO=#DATOSER.PRIORITARIO, DURACIONCITA=#DATOSER.DURACIONCITA, ONCOLOGIA=#DATOSER.ONCOLOGIA, AMBITO=#DATOSER.AMBITO, IDSECCION=#DATOSER.IDSECCION, IDPLANILLA=#DATOSER.IDPLANILLA
				, IDEQUIPO_MUESTRA=#DATOSER.IDEQUIPO_MUESTRA, IDMUESTRA=#DATOSER.IDMUESTRA, DURACIONMUESTRA=#DATOSER.DURACIONMUESTRA, ENINTERFAZ=#DATOSER.ENINTERFAZ, SERIADO=#DATOSER.SERIADO, REPORTA=#DATOSER.REPORTA
				, CODCUPS=#DATOSER.CODCUPS, CUPS_ID=#DATOSER.CUPS_ID, DESCRIPCION_CUPS=#DATOSER.DESCRIPCION_CUPS, MDOSIF=#DATOSER.MDOSIF, EQUICC=#DATOSER.EQUICC, PRESUNI=#DATOSER.PRESUNI, T_ESTABILIDAD=#DATOSER.T_ESTABILIDAD
				, MULTIDOSIS=#DATOSER.MULTIDOSIS, LIBREFORMULACION=#DATOSER.LIBREFORMULACION, VIA=#DATOSER.VIA, TERAPIA=#DATOSER.TERAPIA, EXCLUYEPOSOLOGIA=#DATOSER.EXCLUYEPOSOLOGIA, TRANSFORMADO=#DATOSER.TRANSFORMADO
				, MEZCLA=#DATOSER.MEZCLA, CLASEHTX=#DATOSER.CLASEHTX, EQUICCINF=#DATOSER.EQUICCINF, IDEMEDICAPAD=#DATOSER.IDEMEDICAPAD
				,HORARIO = COALESCE(#DATOSER.HORARIO,0)
				,HDESDE = #DATOSER.HDESDE
				,HHASTA = #DATOSER.HHASTA
				,ANTIGENO = COALESCE(#DATOSER.ANTIGENO,0)
				,VPAI = COALESCE(#DATOSER.VPAI,0)
				,MULTI_VAC = COALESCE(#DATOSER.MULTI_VAC,0)
				,VEXIST = COALESCE(#DATOSER.VEXIST,0)
				,CUANTODOSIS = #DATOSER.CUANTODOSIS
				,CUANTOREFUERZOS = #DATOSER.CUANTOREFUERZOS
				,COLOR = #DATOSER.COLOR
				,SER_DILUYENTE = #DATOSER.SER_DILUYENTE
				,CANTIDADMULTI = COALESCE(#DATOSER.CANTIDADMULTI,0)
				,REQ_DILU = #DATOSER.REQ_DILU
				,OBSAPOYO = #DATOSER.OBSAPOYO
				,ESAPLIM = COALESCE(#DATOSER.ESAPLIM,0)
				,REQBOMBA = COALESCE(#DATOSER.REQBOMBA,0)
            ,ENFERMERIA  = COALESCE(#DATOSER.ENFERMERIA  ,0)
            ,ENFHORAS    = COALESCE(#DATOSER.ENFHORAS ,0)
            ,TIPOMED= COALESCE(#DATOSER.TIPOMED ,0)
            ,TIPOOTRO= COALESCE(#DATOSER.TIPOOTRO ,0)
            ,UPR= COALESCE(#DATOSER.UPR ,0)
					FROM SER INNER JOIN #DATOSER ON SER.IDSERVICIO = #DATOSER.IDSERVICIO
			END
			IF UPPER(@PROCESO)='INSERTAR'
			BEGIN
				INSERT INTO SER (IDSERVICIO, PREFIJO, POS, ANESTESIA,  IDALTERNA, DESCSERVICIO, NIVELATENCION, GRUPOQX, IDJERARQUIA,  COMENTARIOS, CIRUGIA
				, MSUBSERVICIO, MOBSOBLIGATORIA, MPROVEEDOR, ESVACUNA, POSS, PYP, SEXO, ESTADO, IDARTICULO, IDGENERICO, NIVELFUNCIONARIO, NIVELSEDE, TELECONSULTA, SMS, MEDICAMENTOS
				, DIASRESTAUTO, REQAUTORIZACION, TIPOAUTORIZACION,  TIPORANGOE, EDADINICIAL, EDADFINAL, IDPREPARACION, SPD, CLASIF1, CLASIF2, CODIGORIPS, CODFURIPS, CCOSTO
				, IVA, IDIMPUESTO, IDCLASE, CANTIDAD, CANTMAXIMA, CANTMAXIMA_CE, CANTMAXIMA_FME, MRECARGONOCTURNO, TIPORECARGONOC, VLRRECARGONOC, DIASIGRN, CODCUM, CODSISPRO, IDEMEDICA
				, VLRCOSTO, MINUTOSMS, GRUPO, ATENCION, MLATERALIDAD, PRIORITARIO, DURACIONCITA, ONCOLOGIA, AMBITO, IDSECCION, IDPLANILLA, IDEQUIPO_MUESTRA, IDMUESTRA, DURACIONMUESTRA
				, ENINTERFAZ, SERIADO, REPORTA, CODCUPS, CUPS_ID, DESCRIPCION_CUPS, MDOSIF, EQUICC, PRESUNI, T_ESTABILIDAD, MULTIDOSIS, LIBREFORMULACION, VIA, TERAPIA, EXCLUYEPOSOLOGIA
				, TRANSFORMADO, MEZCLA, CLASEHTX, EQUICCINF, HORARIO, HDESDE, HHASTA,ANTIGENO, VPAI, VEXIST,CUANTODOSIS,CUANTOREFUERZOS,COLOR,MULTI_VAC,REQ_DILU, CANTIDADMULTI, SER_DILUYENTE, OBSAPOYO
            , ESAPLIM, REQBOMBA ,ENFERMERIA ,ENFHORAS, IDEMEDICAPAD,TIPOMED,TIPOOTRO,UPR)
				                      
				SELECT IDSERVICIO, PREFIJO, POS, ANESTESIA,  IDALTERNA, DESCSERVICIO, COALESCE(NIVELATENCION,'NA'), GRUPOQX, IDJERARQUIA,  COMENTARIOS, CIRUGIA
				, MSUBSERVICIO, MOBSOBLIGATORIA, MPROVEEDOR, ESVACUNA, POSS, PYP, COALESCE(SEXO,'Ambos'), COALESCE(ESTADO,'Activo'), IDARTICULO, IDGENERICO, NIVELFUNCIONARIO, NIVELSEDE, TELECONSULTA, SMS, MEDICAMENTOS
				, DIASRESTAUTO, REQAUTORIZACION, TIPOAUTORIZACION, COALESCE( TIPORANGOE,'NA'), EDADINICIAL, EDADFINAL, IDPREPARACION, SPD, CLASIF1, CLASIF2, CODIGORIPS, CODFURIPS, CCOSTO
				, IVA, IDIMPUESTO, IDCLASE, CANTIDAD, CANTMAXIMA, CANTMAXIMA_CE, CANTMAXIMA_FME, MRECARGONOCTURNO, TIPORECARGONOC, VLRRECARGONOC, DIASIGRN, CODCUM, CODSISPRO, IDEMEDICA
				, VLRCOSTO, MINUTOSMS, GRUPO, ATENCION, MLATERALIDAD, PRIORITARIO, DURACIONCITA, ONCOLOGIA, AMBITO, IDSECCION, IDPLANILLA, IDEQUIPO_MUESTRA, IDMUESTRA, DURACIONMUESTRA
				, ENINTERFAZ, SERIADO, REPORTA, CODCUPS, CUPS_ID, DESCRIPCION_CUPS, MDOSIF, EQUICC, PRESUNI, T_ESTABILIDAD, MULTIDOSIS, LIBREFORMULACION, VIA, TERAPIA, EXCLUYEPOSOLOGIA
				, TRANSFORMADO, MEZCLA, CLASEHTX, EQUICCINF, COALESCE(HORARIO,0), HDESDE, HHASTA,COALESCE(ANTIGENO,0), COALESCE(VPAI,0), COALESCE(VEXIST,0),CUANTODOSIS,CUANTOREFUERZOS,COLOR , COALESCE(MULTI_VAC,0)
				, REQ_DILU, CANTIDADMULTI, SER_DILUYENTE,OBSAPOYO,ESAPLIM,REQBOMBA  , COALESCE(ENFERMERIA,0) ,COALESCE(ENFHORAS,0), IDEMEDICAPAD,TIPOMED,TIPOOTRO,UPR
				FROM #DATOSER

            IF DBO.FNK_VALORVARIABLE('INTERFAZ_INV') = 'INTER_SAP'
            BEGIN
               DECLARE @DATOSER_IDSERVICIO VARCHAR(20)
               SELECT @IDREFERENCIA = IART.IDSERVICIO, @DATOSER_IDSERVICIO = #DATOSER.IDSERVICIO FROM #DATOSER
               INNER JOIN IART ON IART.IDARTICULO = #DATOSER.IDSERVICIO

               UPDATE SER SET IDREFERENCIA = @IDREFERENCIA WHERE IDSERVICIO = @DATOSER_IDSERVICIO
            END

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

	IF @METODO = 'GUARDAR_SUBSERVICIO'
	BEGIN
		
		BEGIN TRY
			
			DELETE FROM TGEN WHERE TABLA = 'SUBSERVICIOS' AND CAMPO = JSON_VALUE(@PARAMETROS,'$.IDSERVICIO') AND CODIGO = JSON_VALUE(@PARAMETROS,'$.IDSUBSERVICIO')

			INSERT INTO TGEN(TABLA,CAMPO,CODIGO,DESCRIPCION)
			SELECT 'SUBSERVICIOS', IDSERVICIO, JSON_VALUE(@PARAMETROS,'$.IDSUBSERVICIO'), DESCSERVICIO
			FROM SER 
			WHERE IDSERVICIO=JSON_VALUE(@PARAMETROS,'$.IDSERVICIO')

		END TRY
		BEGIN CATCH
			INSERT INTO @TBLERRORES(ERROR) SELECT ERROR_MESSAGE()          
		END CATCH

		IF(SELECT COUNT(*) FROM @TBLERRORES) >0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END

		SELECT 'OK' AS OK

		RETURN

	END

	IF @METODO = 'ELIMINAR_SUBSERVICIO'
	BEGIN
		
		BEGIN TRY
			
			DELETE FROM TGEN WHERE IDTGEN = JSON_VALUE(@PARAMETROS,'$.IDTGEN')

		END TRY
		BEGIN CATCH
			INSERT INTO @TBLERRORES(ERROR) SELECT ERROR_MESSAGE()          
		END CATCH

		IF(SELECT COUNT(*) FROM @TBLERRORES) >0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END

		SELECT 'OK' AS OK

		RETURN

	END

	IF @METODO = 'CRUD_TARD'
	BEGIN
		SELECT @dataTARD =  dataTARD
		FROM OPENJSON (@PARAMETROS)
		WITH		 (
					dataTARD			NVARCHAR(MAX)  AS JSON
					)
		SELECT @PROCESO     = JSON_VALUE(@dataTARD ,'$.PROCESO') 
		SELECT    *  INTO #DATO_TARD
		FROM OPENJSON (@dataTARD)
		WITH (
			IDSERVICIO				VARCHAR(20)		'$.IDSERVICIO'
			,CIRUGIA				BIT				'$.CIRUGIA'
			,CODIFICACION			VARCHAR(20)		'$.CODIFICACION'
			,IDTARIFA				VARCHAR(5)		'$.IDTARIFA'
			,PROCESO				VARCHAR(20)		'$.PROCESO'
		)
		
		IF UPPER(@PROCESO)='INSERTAR' AND EXISTS (SELECT * FROM TARD WHERE IDTARIFA= (SELECT IDTARIFA FROM #DATO_TARD) AND IDSERVICIO= (SELECT IDSERVICIO FROM #DATO_TARD) )
		BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'Ya existe este tarifario, para este servicio'
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
		RETURN
		END
		IF UPPER(@PROCESO)='BORRAR' AND EXISTS (SELECT * FROM TARDV WHERE IDTARIFA= (SELECT IDTARIFA FROM #DATO_TARD) AND IDSERVICIO= (SELECT IDSERVICIO FROM #DATO_TARD) )
		BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'El tarifario cuenta con Valores de tarifa.'
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
		RETURN
		END

		BEGIN TRY 
			IF UPPER(@PROCESO)='EDITAR'
			BEGIN
				UPDATE TARD SET IDTARIFA=#DATO_TARD.IDTARIFA , IDSERVICIO= #DATO_TARD.IDSERVICIO, CIRUGIA= #DATO_TARD.CIRUGIA, CODIFICACION= #DATO_TARD.CODIFICACION
				FROM TARD INNER JOIN #DATO_TARD ON TARD.IDTARIFA = #DATO_TARD.IDTARIFA AND TARD.IDSERVICIO = #DATO_TARD.IDSERVICIO
			END
			IF UPPER(@PROCESO)='INSERTAR'
			BEGIN
				INSERT INTO TARD (IDTARIFA, IDSERVICIO, CIRUGIA, CODIFICACION)
				SELECT IDTARIFA, IDSERVICIO, CIRUGIA, CODIFICACION
				FROM #DATO_TARD
			END
			IF UPPER(@PROCESO)='BORRAR'
			BEGIN
				DELETE FROM TARD WHERE TARD.IDTARIFA = (SELECT IDTARIFA FROM #DATO_TARD) AND IDSERVICIO= (SELECT IDSERVICIO FROM #DATO_TARD)
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
	IF @METODO = 'CRUD_TARDV'
	BEGIN
		SELECT @dataTARDV =  dataTARDV
		FROM OPENJSON (@PARAMETROS)
		WITH		 (
					dataTARDV			NVARCHAR(MAX)  AS JSON
					)
		SELECT @PROCESO     = JSON_VALUE(@dataTARDV ,'$.PROCESO') 
		SELECT    *  INTO #DATO_TARDV
		FROM OPENJSON (@dataTARDV)
		WITH (
			IDSERVICIO				VARCHAR(20)		'$.IDSERVICIO'
			,IDTARIFA				VARCHAR(5)		'$.IDTARIFA'
			,TIPOVALOR				VARCHAR(50)		'$.TIPOVALOR'
			,FECHA_INICIAL			VARCHAR(10)		'$.FECHA_INICIAL'
			,FECHA_FINAL			VARCHAR(10)		'$.FECHA_FINAL'
			,HORAINI				VARCHAR(5)		'$.HORAINI'
			,HORAFIN				VARCHAR(5)		'$.HORAFIN'
			,CODIFICACION			VARCHAR(20)		'$.CODIFICACION'
			,VALOR					DECIMAL(14,2)	'$.VALOR'
			,VLRPAQUETEREF			DECIMAL(14,2)	'$.VLRPAQUETEREF'
			,NOITEM					INT				'$.NOITEM'
			,PROCESO				VARCHAR(20)		'$.PROCESO'
		)

		--SELECT TOP 100   * FROM #DATO_TARDV
		SELECT @FECHAI=FECHA_INICIAL, @FECHAF= FECHA_FINAL, @HORAI= HORAINI,@HORAF= HORAFIN FROM #DATO_TARDV
		SELECT @FINICIAL = CONVERT(DATETIME,@FECHAI+' '+@HORAI)
		SELECT @FFINAL = CONVERT(DATETIME,@FECHAF+' '+@HORAF)

		
		IF 1 = 2
			BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'xxx'
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
			END
	
		BEGIN TRY 
			IF UPPER(@PROCESO)='EDITAR'
			BEGIN
				UPDATE TARDV SET VALOR = #DATO_TARDV.VALOR, FECHAINI=@FINICIAL, FECHAFIN= @FFINAL,  VLRPAQUETEREF= #DATO_TARDV.VLRPAQUETEREF , CODIFICACION= #DATO_TARDV.CODIFICACION, TIPOVALOR= #DATO_TARDV.TIPOVALOR
				FROM TARDV INNER JOIN #DATO_TARDV ON TARDV.IDTARIFA = #DATO_TARDV.IDTARIFA AND TARDV.IDSERVICIO = #DATO_TARDV.IDSERVICIO AND TARDV.NOITEM = #DATO_TARDV.NOITEM
			END
			IF UPPER(@PROCESO)='INSERTAR'
			BEGIN
				IF (SELECT MAX(NOITEM)+1  FROM TARDV WHERE IDTARIFA = (SELECT IDTARIFA FROM #DATO_TARDV) AND IDSERVICIO = (SELECT IDSERVICIO FROM #DATO_TARDV)) IS NULL
				BEGIN
					SELECT @ITEM = 1
				END
				ELSE
				BEGIN
					SELECT @ITEM = (SELECT MAX(NOITEM)+1  FROM TARDV WHERE IDTARIFA = (SELECT IDTARIFA FROM #DATO_TARDV) AND IDSERVICIO = (SELECT IDSERVICIO FROM #DATO_TARDV))
				END
				INSERT INTO TARDV (IDTARIFA, IDSERVICIO, NOITEM, VALOR, FECHAINI, FECHAFIN,  VLRPAQUETEREF, CODIFICACION, TIPOVALOR)
				SELECT IDTARIFA, IDSERVICIO, @ITEM, VALOR, @FINICIAL, @FFINAL,  VLRPAQUETEREF, CODIFICACION, TIPOVALOR
				FROM #DATO_TARDV
			END
			IF UPPER(@PROCESO)='BORRAR'
			BEGIN
				DELETE FROM TARDV WHERE IDTARIFA = (SELECT IDTARIFA FROM #DATO_TARDV) AND IDSERVICIO = (SELECT IDSERVICIO FROM #DATO_TARDV) AND NOITEM = (SELECT NOITEM FROM #DATO_TARDV)
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

	IF @METODO = 'GENERAR_CPPAF'
	BEGIN
		
		BEGIN TRY

			DECLARE @IDSERVICIO VARCHAR(20) = JSON_VALUE(@PARAMETROS,'$.IDSERVICIO')
			DECLARE @CNSRPDX VARCHAR(20)    = JSON_VALUE(@PARAMETROS,'$.CNSRPDX')
			DECLARE @CNSRPDX2 VARCHAR(20)   = JSON_VALUE(@PARAMETROS,'$.CNSRPDX2')
			--SELECT @IDSERVICIO
			--SELECT @CNSRPDX
			--SELECT @CNSRPDX2
			--RETURN
			EXEC SPK_CFG_SERCPPAF @IDSERVICIO, @CNSRPDX, @CNSRPDX2

		END TRY
		BEGIN CATCH
			INSERT INTO @TBLERRORES(ERROR) SELECT ERROR_MESSAGE()          
		END CATCH

		IF(SELECT COUNT(*) FROM @TBLERRORES) >0
		BEGIN
			SELECT 'KO' OK
			SELECT ERROR FROM @TBLERRORES
			RETURN
		END

		SELECT 'OK' AS OK

		RETURN

	END
	IF @METODO = 'GUARDA_SERR'
	BEGIN
	--QADULTO
		SELECT @IDSERVICIO = IDSERVICIO, @IDSERVICIOREL = IDSERVICIOREL, @TIPO = TIPO, @QPEDIATRICO = QPEDIATRICO, @IDSERVICIOREL_ORI = IDSERVICIOREL_ORI
				, @QADULTO = QADULTO, @POR_HORAS = POR_HORAS, @PROCESO = PROCESO
		FROM OPENJSON(@PARAMETROS)
		WITH(	IDSERVICIO	VARCHAR(20)		'$.IDSERVICIO', IDSERVICIOREL	VARCHAR(20)		'$.IDSERVICIOREL',TIPO	VARCHAR(2)		'$.TIPO'
				,QPEDIATRICO	DECIMAL(14,2)		'$.QPEDIATRICO',QADULTO BIT		'$.QADULTO',POR_HORAS	INT		'$.POR_HORAS'
				,PROCESO	VARCHAR(20)		'$.PROCESO', IDSERVICIOREL_ORI	VARCHAR(20)		'$.IDSERVICIOREL_ORI')
		
		IF COALESCE(@TIPO,'') = '' AND @PROCESO <> 'Eliminar'
		BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'Debe de seleccionar un Tipo de Relacion'
		END
		--IF COALESCE(@QPEDIATRICO,0) = 0 AND @PROCESO <> 'Eliminar'
		--BEGIN
		--	INSERT INTO @TBLERRORES(ERROR) SELECT 'Debe de ingresar un monto mayor a 0'
		--END
		IF @PROCESO = 'Nuevo' AND EXISTS (SELECT 1 FROM SERR WHERE IDSERVICIO = @IDSERVICIO AND IDSERVICIOREL = @IDSERVICIOREL)
		BEGIN
			INSERT INTO @TBLERRORES(ERROR) SELECT 'El Servicio ingresado, ya existe.'
		END
		IF @PROCESO = 'Editar' AND EXISTS (SELECT 1 FROM SERR WHERE IDSERVICIO = @IDSERVICIO AND IDSERVICIOREL = @IDSERVICIOREL AND IDSERVICIOREL <> @IDSERVICIOREL_ORI )
		BEGIN
			INSERT INTO @TBLERRORES (ERROR) SELECT 'El servicio ingresado ya existe'
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
				IF @PROCESO = 'Nuevo'
				BEGIN
					INSERT INTO SERR(IDSERVICIO, IDSERVICIOREL, TIPO, QPEDIATRICO, QADULTO, POR_HORAS)
					SELECT @IDSERVICIO, @IDSERVICIOREL, @TIPO, COALESCE(@QPEDIATRICO,0), @QADULTO, @POR_HORAS
				END
				IF @PROCESO = 'Editar'
				BEGIN
					UPDATE SERR SET IDSERVICIOREL = @IDSERVICIOREL, TIPO = @TIPO, QPEDIATRICO = COALESCE(@QPEDIATRICO,0), QADULTO = @QADULTO, POR_HORAS = @POR_HORAS
					WHERE IDSERVICIOREL = @IDSERVICIOREL_ORI AND IDSERVICIO = @IDSERVICIO
				END
				IF @PROCESO = 'Eliminar'
				BEGIN
					DELETE FROM SERR WHERE IDSERVICIO = @IDSERVICIO AND IDSERVICIOREL = @IDSERVICIOREL
				END
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












