CREATE OR ALTER PROCEDURE DBO.SPK_RIPS_JSON_FTR_MAS
@N_FACTURA  VARCHAR(20),
@URL_PATH VARCHAR(MAX)=NULL,
@PLANO NVARCHAR(MAX) OUTPUT
AS 
DECLARE @NOADMISION VARCHAR(20)
DECLARE @PROCEDENCIA VARCHAR(20)
DECLARE @MEDICA AS NVARCHAR(MAX)
DECLARE @PROCEDI AS NVARCHAR(MAX)
DECLARE @URGEN AS NVARCHAR(MAX)
DECLARE @HOSPITA AS NVARCHAR(MAX)
DECLARE @OTROSER AS NVARCHAR(MAX)
DECLARE @IDTERINSTA VARCHAR(20)
DECLARE @TIPODOC VARCHAR(2)
DECLARE @DOCIDAFILIADO VARCHAR(20)
DECLARE @TIPOUSU VARCHAR(2)
DECLARE @FNACIMIENTO VARCHAR(10)
DECLARE @SEXO VARCHAR(1) --M --F
DECLARE @MUNICIPIO VARCHAR(5)
DECLARE @ZONA VARCHAR(20) --01 RURAL -- 02 URBANO
DECLARE @INCAPACIDAD VARCHAR(2) --SI--NO
DECLARE @CNS INT =1 --factura individual
DECLARE @IDPRESTADOR VARCHAR(20)
DECLARE @NRO INT
DECLARE @CANT INT
DECLARE @conceptoRecaudo VARCHAR(20)
DECLARE @VALORCOPAGO DECIMAL(14,2)
DECLARE @IDSEDE VARCHAR(20)
DECLARE @CODHABILITA VARCHAR(100)
DECLARE @CNSCONSULTA INT
DECLARE @CANTORI INT
DECLARE @BANDERA INT    ,@IDMEDICODEFAULT VARCHAR(12) ,@TIPO_ID_MEDICODEFAULT VARCHAR(5)
DECLARE @USUARIOS TABLE (
	usuarioId INT IDENTITY(1,1) PRIMARY KEY,
	tipoDocumentoIdentificacion VARCHAR(20),
	numDocumentoIdentificacion VARCHAR(20),
	IDAFILIADO VARCHAR(20),
	tipoUsuario VARCHAR(2),
	fechaNacimiento VARCHAR(10),
	codSexo VARCHAR(1),
	codPaisResidencia VARCHAR(5),
    codPaisOrigen VARCHAR(5),
    codMunicipioResidencia VARCHAR(5),
    codZonaTerritorialResidencia VARCHAR(2),
    incapacidad VARCHAR(20)
)
DECLARE @CONSULTAS TABLE (
	codPrestador VARCHAR(20),
	CONSECUTIVO VARCHAR(20),
	IDAFILIADO VARCHAR(20),
	fechaInicioAtencion VARCHAR(16),
	numAutorizacion VARCHAR(30),
	codConsulta VARCHAR(10),
	modalidadGrupoServicioTecSal VARCHAR(2),
	grupoServicios VARCHAR(2),
	codServicio INT,
	finalidadTecnologiaSalud VARCHAR(2),
	causaMotivoAtencion VARCHAR(2),
	codDiagnosticoPrincipal VARCHAR(20),
	codDiagnosticoRelacionado1 VARCHAR(20),
	codDiagnosticoRelacionado2 VARCHAR(20),
	codDiagnosticoRelacionado3 VARCHAR(20),
	tipoDiagnosticoPrincipal VARCHAR(3),
	vrServicio int,
	tipoPagoModerador VARCHAR(2),
    tipoDocumentoIdentificacion VARCHAR(2),
	numDocumentoIdentificacion VARCHAR(20),
	conceptoRecaudo VARCHAR(20),
	valorPagoModerador INT,
	numFEVPagoModerador VARCHAR(20),
	usuarioId  INT, 
   ID int identity(1,1),
   xconsecutivo int,
   PROCEDENCIA VARCHAR(20)
)
DECLARE @CONSULTAS1 TABLE (
	IDCONSULTA INT IDENTITY PRIMARY KEY,
	codPrestador VARCHAR(20),
	CONSECUTIVO VARCHAR(20),
	IDAFILIADO VARCHAR(20),
	fechaInicioAtencion VARCHAR(16),
	numAutorizacion VARCHAR(30),
	codConsulta VARCHAR(10),
	modalidadGrupoServicioTecSal VARCHAR(2),
	grupoServicios VARCHAR(2),
	codServicio INT,
	finalidadTecnologiaSalud VARCHAR(2),
	causaMotivoAtencion VARCHAR(2),
	codDiagnosticoPrincipal VARCHAR(20),
	codDiagnosticoRelacionado1 VARCHAR(20),
	codDiagnosticoRelacionado2 VARCHAR(20),
	codDiagnosticoRelacionado3 VARCHAR(20),
	tipoDiagnosticoPrincipal VARCHAR(3),
	tipoDocumentoIdentificacion VARCHAR(2), 
	numDocumentoIdentificacion VARCHAR(20), 
	vrServicio int,--- VARCHAR(20),
	Cantidad int,
	conceptoRecaudo VARCHAR(20),
	tipoPagoModerador VARCHAR(2),
	valorPagoModerador INT,
	usuarioId  INT, 
   PROCEDENCIA VARCHAR(20)
)
--DECLARE @codPrestador VARCHAR(20),
--	@fechaInicioAtencion VARCHAR(16),
--	@numAutorizacion VARCHAR(30),
--	@codConsulta VARCHAR(6),
--	@modalidadGrupoServicioTecSal VARCHAR(2),
--	@grupoServicios VARCHAR(2),
--	@codServicio VARCHAR(4),
--	@finalidadTecnologiaSalud VARCHAR(2),
--	@causaMotivoAtencion VARCHAR(2),
--	@codDiagnosticoPrincipal VARCHAR(20),
--	@codDiagnosticoRelacionado1 VARCHAR(20),
--	@codDiagnosticoRelacionado2 VARCHAR(20),
--	@codDiagnosticoRelacionado3 VARCHAR(20),
--	@tipoDiagnosticoPrincipal VARCHAR(2),
--	@vrServicio DECIMAL(14,2),-- VARCHAR(20),
--	@tipoPagoModerador VARCHAR(2),
--	@valorPagoModerador VARCHAR(10),
--	@usuarioId  VARCHAR(4)  

DECLARE @MEDICAMENTOS TABLE (
	codPrestador VARCHAR(20),
   IDAFILIADO VARCHAR(20),
   CONSECUTIVO VARCHAR(20),
	idMIPRES       VARCHAR(15),
	fechaDispensAdmon VARCHAR(16),
	codDiagnosticoPrincipal VARCHAR(20),
	codDiagnosticoRelacionado VARCHAR(20),
	tipoMedicamento VARCHAR(4),
	codTecnologiaSalud VARCHAR(20),--CODCUM
	nomTecnologiaSalud VARCHAR(30),
	concentracionMedicamento INT,
	unidadMedida int,
	formaFarmaceutica VARCHAR(8),
	unidadMinDispensa INT,
	cantidadMedicamento INT,
	diasTratamiento     SMALLINT,
	tipoDocumentoIdentificacion VARCHAR(2),
	numDocumentoIdentificacion VARCHAR(20),
	vrUnitMedicamento DECIMAL(14,2),
	vrServicio DECIMAL(14,2),
	conceptoRecaudo VARCHAR(20),
	tipoPagoModerador VARCHAR(2),
	valorPagoModerador INT,
	numFEVPagoModerador VARCHAR(20),
	usuarioId  INT, 
   ID int identity(1,1),
   xconsecutivo int
)
	--DECLARE 
	--@numAutorizadon VARCHAR(30),
	--@idMIPRES       VARCHAR(15),
	--@fechaDispensAdmon VARCHAR(16),
	--@codDiagnosticoRelacionado VARCHAR(20),
	--@tipoMedicamento VARCHAR(4),
	--@codTecnologiaSalud VARCHAR(20),--CODCUM
	--@nomTecnologiaSalud VARCHAR(30),
	--@concentracionMedicamento VARCHAR(4),
	--@unidadMedida int,
	--@formaFarmaceutica VARCHAR(8),
	--@unidadMinDispensa VARCHAR(4),
	--@cantidadMedicamento VARCHAR(20),
	--@diasTratamiento     VARCHAR(5),
	--@tipoDocumentoIdentificacion VARCHAR(4),
	--@numDocumentoIdentificacion VARCHAR(20),
	--@vrUnitMedicamento VARCHAR(15),
	--@numFEVPagoModerador VARCHAR(20)

DECLARE @PROCEDIMIENTOS TABLE (
	codPrestador VARCHAR(12),
   IDAFILIADO VARCHAR(20),
   CONSECUTIVO VARCHAR(20),
	fechaInicioAtencion VARCHAR(16),
	idMIPRES VARCHAR(15),
	numAutorizacion VARCHAR(30),
	codProcedimiento VARCHAR(6),
	viaIngresoServicioSalud VARCHAR(2),
	modalidadGrupoServicioTecSal VARCHAR(2),
	grupoServicios VARCHAR(2),
	codServicio INT,
	finalidadTecnologiaSalud VARCHAR(2),
	tipoDocumentoIdentificacion VARCHAR(2),
	numDocumentoIdentificacion VARCHAR(20),
	codDiagnosticoPrincipal VARCHAR(20),
	codDiagnosticoRelacionado VARCHAR(20),
	codComplicacion VARCHAR(20),
	vrServicio int, --VARCHAR(20),
	conceptoRecaudo VARCHAR(20),
	tipoPagoModerador  VARCHAR(2),
	valorPagoModerador  INT,
	numFEVPagoModerador VARCHAR(20),
	usuarioId  INT, 
   ID int identity(1,1),
   xconsecutivo int
)
DECLARE @PROCEDIMIENTOS1 TABLE (
   IDPROCE INT IDENTITY PRIMARY KEY,
	codPrestador VARCHAR(12),
   IDAFILIADO VARCHAR(20),
   CONSECUTIVO VARCHAR(20),
	fechaInicioAtencion VARCHAR(16),
	idMIPRES VARCHAR(15),
	numAutorizacion VARCHAR(30),
	codProcedimiento VARCHAR(6),
	viaIngresoServicioSalud VARCHAR(2),
	modalidadGrupoServicioTecSal VARCHAR(2),
	grupoServicios VARCHAR(2),
	codServicio INT,
	finalidadTecnologiaSalud VARCHAR(2),
	tipoDocumentoIdentificacion VARCHAR(2),
	numDocumentoIdentificacion VARCHAR(20),
	codDiagnosticoPrincipal VARCHAR(20),
	codDiagnosticoRelacionado VARCHAR(20),
	codComplicacion VARCHAR(20),
	vrServicio int, --VARCHAR(20),
	cantidad int,
	conceptoRecaudo VARCHAR(20),
	tipoPagoModerador  VARCHAR(2),
	valorPagoModerador  INT,
	numFEVPagoModerador VARCHAR(20),
	usuarioId  INT

)
DECLARE @codProcedimiento VARCHAR(6),
	@vialngresoServicioSalud VARCHAR(2),
	@codComplicacion VARCHAR(20)

DECLARE @URGENCIAS TABLE (
	codPrestador VARCHAR(12),
   IDAFILIADO VARCHAR(20),
   CONSECUTIVO VARCHAR(20),
	fechaInicioAtencion VARCHAR(16),
	causaMotivoAtencion VARCHAR(2),
	codDiagnosticoPrincipalE VARCHAR(20),
	codDiagnosticoRelacionadoE1 VARCHAR(20),
	codDiagnosticoRelacionadoE2 VARCHAR(20),
	codDiagnosticoRelacionadoE3 VARCHAR(20),
	condicionDestinoUsuarioEgreso VARCHAR(2),
	codDiagnosticoCausaMuerte VARCHAR(20),
	fechaEgreso VARCHAR(16),
	viaIngresoServicioSalud VARCHAR(2),
	usuarioId  INT,
   ID int identity(1,1),
   xconsecutivo int
)
DECLARE @HOSPITALIZACION TABLE (
	codPrestador VARCHAR(12),
   IDAFILIADO VARCHAR(20),
   CONSECUTIVO VARCHAR(20),
	viaIngresoServicioSalud VARCHAR(2),
   fechaInicioAtencion VARCHAR(16),
	numAutorizacion VARCHAR(30),
	causaMotivoAtencion VARCHAR(2),
	codDiagnosticoPrincipal VARCHAR(20),
	codDiagnosticoPrincipalE VARCHAR(20),
	codDiagnosticoRelacionadoE1 VARCHAR(20),
	codDiagnosticoRelacionadoE2 VARCHAR(20),
	codDiagnosticoRelacionadoE3 VARCHAR(20),
	codComplicacion VARCHAR(20),
	condicionDestinoUsuarioEgreso VARCHAR(2),
	codDiagnosticoCausaMuerte VARCHAR(20),
	fechaEgreso VARCHAR(16),
	usuarioId  INT,
   ID int identity(1,1),
   xconsecutivo int
)
DECLARE @RECIEN TABLE (
	codPrestador VARCHAR(12),
   IDAFILIADO VARCHAR(20),
   CONSECUTIVO VARCHAR(20),
	tipoDocumentoIdentificacion VARCHAR(2) DEFAULT 'CN',
	numDocumentoIdentificacion VARCHAR(20),
	fechaNacimiento VARCHAR(16),
	edadGestacional VARCHAR(2),
	numConsultasCPrenatal VARCHAR(2),
	codSexoBiologico VARCHAR(2),
	peso VARCHAR(4),
	codDiagnosticoPrincipal VARCHAR(20),
	condicionDestinoUsuarioEgreso VARCHAR(2),
	codDiagnosticoCausaMuerte VARCHAR(20),
	fechaEgreso VARCHAR(16),
	usuarioId  INT,
   ID int identity(1,1),
   xconsecutivo int
)

DECLARE @OTROSSER TABLE (
	codPrestador VARCHAR(20),
   IDAFILIADO VARCHAR(20),
   CONSECUTIVO VARCHAR(20),
	numAutorizacion VARCHAR(30),
	idMIPRES VARCHAR(15),
	fechaSuministroTecnologia VARCHAR(16),
	tipoOS VARCHAR(2),
	codTecnologiaSalud VARCHAR(20),
	nomTecnologiaSalud VARCHAR(60),
	cantidadOS INT, --VARCHAR(5),
	tipoDocumentoIdentificacion VARCHAR(2),
	numDocumentoIdentificacion VARCHAR(20),
	vrUnitOS INT, -- VARCHAR(20),
	vrServicio int, -- VARCHAR(20),
	conceptoRecaudo VARCHAR(20),
	tipoPagoModerador VARCHAR(2),
	valorPagoModerador INT,
	numFEVPagoModerador VARCHAR(20),
	usuarioId  INT, 
   ID int identity(1,1),
   xconsecutivo int
)
DECLARE @DX TABLE (
	IDAFILIADO VARCHAR(20),
	NOADMISION VARCHAR(20),
	CONSECUTIVOCIT VARCHAR(20),
	TIPODX VARCHAR(20),
	IDDX VARCHAR(4),
	NIDDX VARCHAR(255),
	DX1 VARCHAR(4),
	NDX1 VARCHAR(255),
	DX2 VARCHAR(4),
	NDX2 VARCHAR(255),
	DX3 VARCHAR(4),
	NDX3 VARCHAR(255)
)
DECLARE  @fechaSuministroTecnologia VARCHAR(16)
	,@tipoOS VARCHAR(2)
	,@cantidadOS INT
	,@vrUnitOS INT--VARCHAR(20)
	,@primerGrupo BIT = 1
DECLARE @numDocumentoIdObligado VARCHAR(20) 
DECLARE @CNSFCT VARCHAR(20)
DECLARE @PAQUETE BIT ,@CONCEPTORECAUDOMCE VARCHAR(20) ,@CONCEPTORECAUDOMCI VARCHAR(20) ,@ESMODERADORAENFTR VARCHAR(2)
BEGIN
	DECLARE @json NVARCHAR(MAX)
	--DECLARE @numNota VARCHAR(MAX) --= 'xx'
   SELECT @IDTERINSTA = DBO.FNK_VALORVARIABLE('IDTERCEROINSTALADO')
   PRINT 'SPK_RIPS_JSON_FTR_MAS ='+@N_FACTURA

   SELECT @CNSFCT=CNSFCT,@PAQUETE=COALESCE(FTR.PAQUETE,0),@PROCEDENCIA=FTR.PROCEDENCIA
   FROM FTR WHERE N_FACTURA=@N_FACTURA AND TIPOFAC = 'M'

   IF NOT EXISTS(SELECT * FROM FTRD WHERE CNSFTR=@CNSFCT)
   BEGIN
      PRINT 'FACTURA MASIVA SIN RELACION DE SERVICIOS, ME REGRESO'
	  RAISERROR('FACTURA MASIVA SIN RELACION DE SERVICIOS, POR FAVOR VERIFIQUE.', 16, 1)
      RETURN
   END

   SELECT @IDMEDICODEFAULT = DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT')
   SELECT @TIPO_ID_MEDICODEFAULT = TIPO_ID FROM MED WHERE IDMEDICO = @IDMEDICODEFAULT

	SELECT @conceptoRecaudo = '05'
	SELECT @IDPRESTADOR=COALESCE(IDALTERNA2,'No tengo'), @numDocumentoIdObligado = NIT
	FROM TER 
	WHERE IDTERCERO=@IDTERINSTA

	IF EXISTS( SELECT top 1 * 
              FROM  FDIANR 
              WHERE CNSDOCUMENTO = @CNSFCT 
              AND   TIPO = 'FV'
              AND   COALESCE(XML_AttachedDocument,'') != '' 
              ORDER BY ITEM DESC )
	BEGIN
		IF EXISTS( SELECT top 1 * 
				  FROM  FDIANR 
				  WHERE CNSDOCUMENTO = @CNSFCT 
				  AND   TIPO = 'FV'
				  AND   COALESCE(XML_AttachedDocument,'') != '' 
				  AND   CHARINDEX('<cbc:ID schemeID="02">CUOTA MODERADORA</cbc:ID>',XML_AttachedDocument) > 0  
				  ORDER BY ITEM DESC )
		BEGIN
		   SELECT @ESMODERADORAENFTR = '02'
		END
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT top 1 * 
              FROM  FDIANR 
              WHERE CNSDOCUMENTO = @CNSFCT 
              AND   TIPO = 'FV'
              AND   COALESCE(CONVERT(NVARCHAR(MAX),XML_SOLICITUD),'') != '' 
			   ORDER BY ITEM DESC)
		BEGIN
			IF EXISTS(SELECT top 1 * 
					  FROM  FDIANR 
					  WHERE CNSDOCUMENTO = @CNSFCT 
					  AND   TIPO = 'FV'
					  AND   COALESCE(CONVERT(NVARCHAR(MAX),XML_SOLICITUD),'') != '' 
					  AND   CHARINDEX('<cbc:ID schemeID="02">CUOTA MODERADORA</cbc:ID>',CONVERT(NVARCHAR(MAX),XML_SOLICITUD)) > 0 
					  ORDER BY ITEM DESC )
			BEGIN
			   SELECT @ESMODERADORAENFTR = '02'
			END
		END
	END

   PRINT 'BUSCANDO LOS AFILIADOS'
   IF COALESCE(@PAQUETE,0)=1 AND @PROCEDENCIA='CI'
   BEGIN
      UPDATE FTRD SET PROCEDENCIA='CI'
      FROM FTR INNER JOIN FTRD ON FTR.N_FACTURA=FTRD.N_FACTURA
      WHERE FTRD.PROCEDENCIA IS NULL
      AND FTR.PROCEDENCIA='CI'
      AND FTRD.NOITEM=99
      AND FTR.N_FACTURA=@N_FACTURA
   END
   ----jedm 2025.05.13 Se toma esta variable para saber si se envia todo a copago O AL CONCEPTO ALLI INDICADO
   SELECT @CONCEPTORECAUDOMCE = DATO1 FROM TGEN WHERE TABLA = 'RIPS_JSON' AND CAMPO = 'conceptoRecaudo' AND CODIGO = 'MCE' 
   SELECT @CONCEPTORECAUDOMCI = DATO1 FROM TGEN WHERE TABLA = 'RIPS_JSON' AND CAMPO = 'conceptoRecaudo' AND CODIGO = 'MCI' 
   
   IF EXISTS(SELECT 1 FROM FTRD WHERE CNSFTR=@CNSFCT AND PROCEDENCIA='CI')
   BEGIN
		PRINT 'AFIS DE CI'
		INSERT INTO @USUARIOS(tipoDocumentoIdentificacion,numDocumentoIdentificacion,IDAFILIADO,tipoUsuario,fechaNacimiento,codSexo,codPaisResidencia,codPaisOrigen,
                         codMunicipioResidencia,codZonaTerritorialResidencia,incapacidad)
	   SELECT DISTINCT  AFI.TIPO_DOC,AFI.DOCIDAFILIADO,AFI.IDAFILIADO,
		  CASE WHEN COALESCE(AFI.TIPOUSUARIO,'')<>'' THEN AFI.TIPOUSUARIO ELSE 
                  CASE   WHEN AFI.TIPOAFILIADO = 'C' THEN '01'
							WHEN AFI.TIPOAFILIADO = 'B' THEN '02'
							WHEN AFI.TIPOAFILIADO = 'J' THEN '01'
							WHEN AFI.TIPOAFILIADO = 'A' THEN '03'
							WHEN AFI.TIPOAFILIADO = 'S' THEN '07'
							WHEN AFI.TIPOAFILIADO = 'Sb' THEN '04'
							WHEN AFI.TIPOAFILIADO = 'SR' THEN '05'
							WHEN AFI.TIPOAFILIADO = 'TA' THEN '06'
							WHEN AFI.TIPOAFILIADO = 'RE' THEN '07'
							WHEN AFI.TIPOAFILIADO = 'SN' THEN '05'
							WHEN AFI.TIPOAFILIADO = 'S/' THEN '05'
							WHEN AFI.TIPOAFILIADO = 'S/N' THEN '05' ELSE '05' END END,
				FNACIMIENTO=REPLACE(CONVERT(VARCHAR,AFI.FNACIMIENTO,102),'.','-'),
				SEXO=UPPER(LEFT(AFI.SEXO,1)),'170','170', MUNICIPIO=AFI.CIUDAD,ZONA=CASE WHEN AFI.ZONA='R' THEN '01'ELSE '02' END,
				INCAPACIDAD='NO'
	   FROM FTRD 
		INNER JOIN CIT ON FTRD.NOADMISION=CIT.CONSECUTIVO
	   INNER JOIN AFI ON CIT.IDAFILIADO=AFI.IDAFILIADO
	   WHERE CNSFTR=@CNSFCT AND FTRD.PROCEDENCIA='CI'
      AND COALESCE(FTRD.VLR_SERVICI,0)>0
	END

	IF EXISTS(SELECT 1 FROM FTRD WHERE CNSFTR=@CNSFCT AND PROCEDENCIA='CE')
	BEGIN
		PRINT 'AFIS DE CE'
		INSERT INTO @USUARIOS(tipoDocumentoIdentificacion,numDocumentoIdentificacion,IDAFILIADO,tipoUsuario,fechaNacimiento,codSexo,codPaisResidencia,codPaisOrigen,
                         codMunicipioResidencia,codZonaTerritorialResidencia,incapacidad)
	   SELECT DISTINCT  AFI.TIPO_DOC,AFI.DOCIDAFILIADO,AFI.IDAFILIADO,
		  CASE WHEN COALESCE(AFI.TIPOUSUARIO,'')<>'' THEN AFI.TIPOUSUARIO ELSE 
                  CASE   WHEN AFI.TIPOAFILIADO = 'C' THEN '01'
							WHEN AFI.TIPOAFILIADO = 'B' THEN '02'
							WHEN AFI.TIPOAFILIADO = 'J' THEN '01'
							WHEN AFI.TIPOAFILIADO = 'A' THEN '03'
							WHEN AFI.TIPOAFILIADO = 'S' THEN '07'
							WHEN AFI.TIPOAFILIADO = 'Sb' THEN '04'
							WHEN AFI.TIPOAFILIADO = 'SR' THEN '05'
							WHEN AFI.TIPOAFILIADO = 'TA' THEN '06'
							WHEN AFI.TIPOAFILIADO = 'RE' THEN '07'
							WHEN AFI.TIPOAFILIADO = 'SN' THEN '05'
							WHEN AFI.TIPOAFILIADO = 'S/' THEN '05'
							WHEN AFI.TIPOAFILIADO = 'S/N' THEN '05' ELSE '05' END END,
				FNACIMIENTO=REPLACE(CONVERT(VARCHAR,AFI.FNACIMIENTO,102),'.','-'),
				SEXO=UPPER(LEFT(AFI.SEXO,1)),'170','170', MUNICIPIO=AFI.CIUDAD,ZONA=CASE WHEN AFI.ZONA='R' THEN '01'ELSE '02' END,
				INCAPACIDAD='NO'
	   FROM FTRD 
		INNER JOIN AUT ON FTRD.NOADMISION=AUT.NOAUT
	   INNER JOIN AFI ON AUT.IDAFILIADO=AFI.IDAFILIADO
	   WHERE CNSFTR=@CNSFCT AND FTRD.PROCEDENCIA='CE'
	   AND NOT EXISTS(SELECT * FROM @USUARIOS US WHERE US.IDAFILIADO=AUT.IDAFILIADO)
      AND COALESCE(FTRD.VALOR,0)>0
	END

	IF EXISTS(SELECT 1 FROM FTRD WHERE CNSFTR=@CNSFCT AND PROCEDENCIA='SALUD')
	BEGIN
		PRINT 'AFIS SALUD'
		INSERT INTO @USUARIOS(tipoDocumentoIdentificacion,numDocumentoIdentificacion,IDAFILIADO,tipoUsuario,fechaNacimiento,codSexo,codPaisResidencia,codPaisOrigen,
                         codMunicipioResidencia,codZonaTerritorialResidencia,incapacidad)
	   SELECT DISTINCT  AFI.TIPO_DOC,AFI.DOCIDAFILIADO,AFI.IDAFILIADO,
  		  CASE WHEN COALESCE(AFI.TIPOUSUARIO,'')<>'' THEN AFI.TIPOUSUARIO ELSE 
                  CASE   WHEN AFI.TIPOAFILIADO = 'C' THEN '01'
							WHEN AFI.TIPOAFILIADO = 'B' THEN '02'
							WHEN AFI.TIPOAFILIADO = 'J' THEN '01'
							WHEN AFI.TIPOAFILIADO = 'A' THEN '03'
							WHEN AFI.TIPOAFILIADO = 'S' THEN '07'
							WHEN AFI.TIPOAFILIADO = 'Sb' THEN '04'
							WHEN AFI.TIPOAFILIADO = 'SR' THEN '05'
							WHEN AFI.TIPOAFILIADO = 'TA' THEN '06'
							WHEN AFI.TIPOAFILIADO = 'RE' THEN '07'
							WHEN AFI.TIPOAFILIADO = 'SN' THEN '05'
							WHEN AFI.TIPOAFILIADO = 'S/' THEN '05'
							WHEN AFI.TIPOAFILIADO = 'S/N' THEN '05' ELSE '05' END END,
				FNACIMIENTO=REPLACE(CONVERT(VARCHAR,AFI.FNACIMIENTO,102),'.','-'),
				SEXO=UPPER(LEFT(AFI.SEXO,1)),'170','170', MUNICIPIO=AFI.CIUDAD,ZONA=CASE WHEN AFI.ZONA='R' THEN '01'ELSE '02' END,
				INCAPACIDAD='NO'
	   FROM FTRD 
		INNER JOIN HADM ON FTRD.NOADMISION=HADM.NOADMISION
	   INNER JOIN AFI ON HADM.IDAFILIADO=AFI.IDAFILIADO
	   WHERE CNSFTR=@CNSFCT AND FTRD.PROCEDENCIA='SALUD'
	   AND NOT EXISTS(SELECT * FROM @USUARIOS US WHERE US.IDAFILIADO=HADM.IDAFILIADO)
	END

   PRINT 'COMIENZO CONSULTAS'
   PRINT 'CONSULTAS CIT'
		   INSERT INTO @CONSULTAS(codPrestador,CONSECUTIVO,IDAFILIADO,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
								        finalidadTecnologiaSalud,causaMotivoAtencion,vrServicio,conceptoRecaudo,valorPagoModerador,tipoDocumentoIdentificacion, numDocumentoIdentificacion
                               ,PROCEDENCIA,numFEVPagoModerador)
		   SELECT @IDPRESTADOR,CIT.CONSECUTIVO,CIT.IDAFILIADO,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,CIT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,CIT.FECHA,108),5),
		          numAutorizacion=COALESCE((SUBSTRING (CIT.NOAUTORIZACION,0,30)),'null'), --- YCARRILLO
			       codConsulta=REPLACE(REPLACE(LTRIM(RTRIM(LEFT(SER.CODCUPS,6))),CHAR(13),''),CHAR(10),''),modalidadGrupoServicioTecSal='01',grupoServicios='01',
		          codServicio=325,finalidadTecnologiaSalud=LEFT(CASE WHEN CIT.FINCONSULTA IS NULL OR CIT.FINCONSULTA=''  OR CIT.FINCONSULTA='10' 
				                                                     THEN '44' 
																	 ELSE CIT.FINCONSULTA 
															     END,2),
		          causaMotivoAtencion='38',COALESCE(FTRD.VLR_SERVICI,0),
				  CASE WHEN COALESCE(CIT.VALORCOPAGO,0)>0 
					   THEN  CASE  WHEN COALESCE(FTRD.TCOPAGO,'')<> '' THEN FTRD.TCOPAGO 
                           WHEN COALESCE(@ESMODERADORAENFTR,'') <> '' THEN @ESMODERADORAENFTR
								  WHEN COALESCE(@CONCEPTORECAUDOMCI,'') <> '' THEN @CONCEPTORECAUDOMCI --jedm 2025.05.13 Se toma esta variable para saber si se envia todo a copago
								  WHEN COALESCE(AFI.TIPOUSUARIO,'') IN('01','02','03')  
								  THEN '02' 
								  ELSE IIF(AFI.TIPOUSUARIO IN ('05','11'),'03','01') 
						     END 
					   ELSE @conceptoRecaudo 
				  END,
				  COALESCE((SELECT TOP 1 FTRD.VLR_COPAGOS FROM FTRD WHERE N_FACTURA = @N_FACTURA AND NOADMISION = CIT.CONSECUTIVO),CIT.VALORCOPAGO,0)
				  , MED.TIPO_ID, MED.IDTERCERO ,'CIT',CIT.NFACTURA
		   FROM   FTRD INNER JOIN CIT ON FTRD.NOADMISION=CIT.CONSECUTIVO
					      INNER JOIN AFI ON CIT.IDAFILIADO=AFI.IDAFILIADO
					      INNER JOIN SER ON CIT.IDSERVICIO=SER.IDSERVICIO
				         INNER JOIN MED ON CIT.IDMEDICO = MED.IDMEDICO 
				         INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
		   WHERE  FTRD.CNSFTR=@CNSFCT
		   AND    FTRD.PROCEDENCIA='CI'
		   AND    CIT.N_FACTURA=@N_FACTURA
		   AND    RIPS_CP.ARCHIVO='AC'
         AND    COALESCE(PAQUETE,0)=CASE WHEN @PAQUETE=1 THEN 0 ELSE COALESCE(PAQUETE,0) END
         AND    COALESCE(FTRD.VLR_SERVICI,0)>0

     
			PRINT 'CONSULTAS AUT'

			INSERT INTO @CONSULTAS(codPrestador,CONSECUTIVO,IDAFILIADO,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
								        finalidadTecnologiaSalud,causaMotivoAtencion,vrServicio,conceptoRecaudo,valorPagoModerador,tipoDocumentoIdentificacion, numDocumentoIdentificacion
                               ,PROCEDENCIA,numFEVPagoModerador)
			SELECT @IDPRESTADOR,AUT.NOAUT,AUT.IDAFILIADO,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,AUT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,AUT.FECHA,108),5),
			       numAutorizacion=AUT.NUMAUTORIZA,codConsulta=REPLACE(REPLACE(LTRIM(RTRIM(LEFT(SER.CODCUPS,6))),CHAR(13),''),CHAR(10),''),modalidadGrupoServicioTecSal='01',grupoServicios='01',
			       codServicio=325,finalidadTecnologiaSalud=LEFT(CASE WHEN AUT.FINALIDAD IS NULL OR AUT.FINALIDAD='' 
                                                                       THEN '44' 
                                                                   ELSE  CASE WHEN AUT.FINALIDAD='10' THEN '44' 
                                                                             WHEN TRIM(AUT.FINALIDAD) = '1' THEN '15'
                                                                             WHEN TRIM(AUT.FINALIDAD) = '2' THEN '16'
                                                                             WHEN TRIM(AUT.FINALIDAD) = '3' THEN '14'
                                                                             WHEN TRIM(AUT.FINALIDAD) = '4' THEN '12'
                                                                             WHEN TRIM(AUT.FINALIDAD) = '5' THEN '13'               --CMT AUT    --SELECT * FROM TGEN WHERE TABLA = 'GENERAL' AND CAMPO = 'FINALIDAD' 
                                                                             ELSE '44'
                                                                        END 
                                                               END,2),
			      causaMotivoAtencion='38',
			      (SELECT TOP 1 FTRD.VLR_SERVICI 
                FROM   FTRD 
                WHERE  N_FACTURA = @N_FACTURA 
                AND    FTRD.NOPRESTACION = AUT.IDAUT 
                AND    FTRD.NOITEM = AUTD.NO_ITEM) -- KR 2025.05.16 se agrega cambio para el calculo del valor del servicio el caul venia en null 
			      ,CASE WHEN COALESCE(AUTD.VALORCOPAGO,0)>0 OR COALESCE(AUT.VALORCOPAGO,0)> 0   
			           THEN  CASE WHEN COALESCE(FTRD.TCOPAGO,'')<> '' THEN FTRD.TCOPAGO
                               WHEN COALESCE(@ESMODERADORAENFTR,'') <> '' THEN @ESMODERADORAENFTR
                               WHEN COALESCE(AUT.COPAGOPROPIO,0)=1 THEN '05' -- YCARRILLO 20250519
							          WHEN COALESCE(@CONCEPTORECAUDOMCI,'') <> '' THEN @CONCEPTORECAUDOMCI --jedm 2025.05.13 Se toma esta variable para saber si se envia todo a copago
							          WHEN COALESCE(AFI.TIPOUSUARIO,'') IN('01','02','03')  THEN '02' 
							      ELSE IIF(AFI.TIPOUSUARIO IN('11','05'),'03','01') 
					         END 
				       ELSE @conceptoRecaudo 
			      END,
			      CONVERT(DECIMAL(14,2),IIF(COALESCE(AUT.COPAGOPROPIO,0)=1,COALESCE(AUT.VALORCOPAGO,0)/COALESCE(AUT.NO_ITEMES,ROW_NUMBER() OVER (ORDER BY AUTD.NO_ITEM)) ,COALESCE(AUTD.VALORCOPAGO,0))), -- KR 2025.05.16 se agrega cambio para que se tenga en cuenta copago propio en aut para calcular el copago
               COALESCE(MED.TIPO_ID, @TIPODOC,''), COALESCE(MED.IDMEDICO, @DOCIDAFILIADO,''),'AUT',AUTD.NFACTURA
			FROM  FTRD INNER JOIN AUT ON FTRD.NOADMISION=AUT.NOAUT 
					     INNER JOIN AFI ON AUT.IDAFILIADO=AFI.IDAFILIADO
					     INNER JOIN AUTD ON AUT.IDAUT=AUTD.IDAUT AND FTRD.NOPRESTACION=AUTD.IDAUT AND FTRD.NOITEM=AUTD.NO_ITEM
					     INNER JOIN SER ON AUTD.IDSERVICIO=SER.IDSERVICIO AND FTRD.REFERENCIA = SER.IDSERVICIO
					     INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
                    LEFT  JOIN MED ON MED.IDMEDICO = IIF(COALESCE(AUT.IDMEDICOSOLICITA,'')='',DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT'),AUT.IDMEDICOSOLICITA)
                    LEFT JOIN TGEN ON TGEN.TABLA='GENERAL' AND CAMPO='FINALIDADCONSULTA' AND CODIGO=AUT.FINALIDAD
			WHERE FTRD.CNSFTR=@CNSFCT
			AND FTRD.PROCEDENCIA='CE'
			AND AUTD.N_FACTURA=@N_FACTURA
          --AND AUT.IDAFILIADO=@IDAFILIADO
			AND RIPS_CP.ARCHIVO='AC'
         AND COALESCE(AUTD.VALOR,0)>0

			IF EXISTS(SELECT 1 FROM @CONSULTAS)
			BEGIN
				UPDATE @CONSULTAS SET 
				codDiagnosticoPrincipal= CASE WHEN COALESCE(LEFT(TRIM(CIT.IDDX),4),LEFT(TRIM(HCA.IDDX),4),'') != '' 
                                               THEN COALESCE(LEFT(TRIM(CIT.IDDX),4),LEFT(TRIM(HCA.IDDX),4),'')
                                          ELSE
                                              (SELECT TOP 1 IDDX FROM HCA WHERE HCA.IDAFILIADO = CIT.IDAFILIADO AND HCA.PROCEDENCIA = 'IPS' AND CLASE = 'HC' ORDER BY FECHA DESC)
              
                                     END
				,codDiagnosticoRelacionado1=IIF(LEN(COALESCE(HCA.DX1,''))<>4 ,	 'null', HCA.DX1 )
				,codDiagnosticoRelacionado2=IIF(LEN(COALESCE(HCA.DX2,''))<>4 ,	 'null', HCA.DX2 ),
				tipoDiagnosticoPrincipal='01'
				FROM  CIT INNER JOIN @CONSULTAS X ON CIT.CONSECUTIVO=X.CONSECUTIVO
						    LEFT JOIN HCA ON CIT.CONSECUTIVO=COALESCE(HCA.NOADMISION,HCA.CONSECUTIVOCIT)
            WHERE X.PROCEDENCIA = 'CIT'
				
				UPDATE @CONSULTAS SET codDiagnosticoPrincipal=AUT.DXPPAL
               ,codDiagnosticoRelacionado1=IIF(LEN(COALESCE(AUT.DXRELACIONADO,''))<>4 ,	 'null', AUT.DXRELACIONADO )
               ,codDiagnosticoRelacionado2=IIF(LEN(COALESCE(AUT.DXRELACIONADO2,''))<>4 ,	 'null', AUT.DXRELACIONADO2 )
               ,tipoDiagnosticoPrincipal='01'
				FROM AUT INNER JOIN @CONSULTAS X ON AUT.NOAUT=X.CONSECUTIVO
            WHERE X.PROCEDENCIA = 'AUT'
			END

			--SELECT * FROM @CONSULTAS

         PRINT 'CONSULTAS HADM...'
			INSERT INTO @CONSULTAS(codPrestador,CONSECUTIVO,IDAFILIADO,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
								finalidadTecnologiaSalud,causaMotivoAtencion,codDiagnosticoPrincipal,codDiagnosticoRelacionado1,codDiagnosticoRelacionado2,
								codDiagnosticoRelacionado3,tipoDiagnosticoPrincipal,vrServicio,conceptoRecaudo,valorPagoModerador, 	tipoDocumentoIdentificacion, numDocumentoIdentificacion
                       ,PROCEDENCIA) 
			SELECT COALESCE(@IDPRESTADOR,''),HADM.NOADMISION,HADM.IDAFILIADO,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5),
			       numAutorizacion=HADM.NOAUTORIZACION,codConsulta=REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),modalidadGrupoServicioTecSal='01',grupoServicios='01',
			       codServicio=325,finalidadTecnologiaSalud=LEFT(CASE WHEN HPRE.FINALIDAD IS NULL OR HPRE.FINALIDAD='' OR HPRE.FINALIDAD='10'THEN '44' ELSE HPRE.FINALIDAD END,2),
			       causaMotivoAtencion='38',COALESCE(HADM.DXINGRESO,HADM.DXEGRESO),COALESCE(HADM.DXSALIDA1,''),COALESCE(HADM.DXSALIDA2,''),COALESCE(HADM.DXSALIDA3,''),
			       1,COALESCE(HPRED.VALOR,0),IIF(COALESCE(HPRED.VALORCOPAGO,0)>0,'01',@conceptoRecaudo),COALESCE(HPRED.VALORCOPAGO,0), MED.TIPO_ID, MED.IDTERCERO 
                ,'SALUD'
			FROM  FTRD INNER JOIN HADM ON FTRD.NOADMISION=HADM.NOADMISION  
                    INNER JOIN  HPRE ON HADM.NOADMISION=HPRE.NOADMISION
					     INNER JOIN HPRED ON HPRE.NOPRESTACION=HPRED.NOPRESTACION AND HPRED.NOITEM = FTRD.NOITEM
					     INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO AND FTRD.REFERENCIA = SER.IDSERVICIO
					     INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
                    INNER JOIN MED ON MED.IDMEDICO = CASE WHEN COALESCE(HPRE.IDMEDICO,'') = '' THEN COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA) ELSE HPRE.IDMEDICO END  
			WHERE FTRD.CNSFTR=@CNSFCT
			AND FTRD.PROCEDENCIA='SALUD'
          --AND HADM.IDAFILIADO=@IDAFILIADO
			AND HPRED.N_FACTURA=@N_FACTURA
			AND COALESCE(HPRED.VALOR,0)>0
			AND RIPS_CP.ARCHIVO='AC'
			AND HPRED.CANTIDAD=1

         PRINT 'REVISO CANTIDADES MAYORES A 1 CONSULTAS HADM'

			INSERT INTO @CONSULTAS1(codPrestador,CONSECUTIVO,IDAFILIADO,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
								finalidadTecnologiaSalud,causaMotivoAtencion,codDiagnosticoPrincipal,codDiagnosticoRelacionado1,codDiagnosticoRelacionado2,
								codDiagnosticoRelacionado3,tipoDiagnosticoPrincipal,vrServicio,conceptoRecaudo,valorPagoModerador,Cantidad, tipoDocumentoIdentificacion, numDocumentoIdentificacion
                        ,PROCEDENCIA) 
			SELECT COALESCE(@IDPRESTADOR,''),HADM.NOADMISION,HADM.IDAFILIADO,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5),
			       numAutorizacion=HADM.NOAUTORIZACION,codConsulta=REPLACE(REPLACE(LTRIM(RTRIM(LEFT(SER.CODCUPS,6))),CHAR(13),''),CHAR(10),''),modalidadGrupoServicioTecSal='01',grupoServicios='01',
			       codServicio=325,finalidadTecnologiaSalud=LEFT(CASE WHEN HPRE.FINALIDAD IS NULL OR HPRE.FINALIDAD='' OR HPRE.FINALIDAD='10'THEN '44' ELSE HPRE.FINALIDAD END,2),
			       causaMotivoAtencion='38',COALESCE(HADM.DXINGRESO,HADM.DXEGRESO),COALESCE(HADM.DXSALIDA1,''),COALESCE(HADM.DXSALIDA2,''),COALESCE(HADM.DXSALIDA3,''),
		          1,COALESCE(HPRED.VALOR,0),IIF(COALESCE(HPRED.VALORCOPAGO,0)>0,'01',@conceptoRecaudo),COALESCE(HPRED.VALORCOPAGO,0),CONVERT(INT,HPRED.CANTIDAD), MED.TIPO_ID, MED.IDTERCERO
               ,'SALUD'
			FROM  FTRD INNER JOIN HADM ON FTRD.NOADMISION=HADM.NOADMISION  
               INNER JOIN  HPRE ON HADM.NOADMISION=HPRE.NOADMISION
					INNER JOIN HPRED ON HPRE.NOPRESTACION=HPRED.NOPRESTACION AND HPRED.NOITEM = FTRD.NOITEM
					INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO AND FTRD.REFERENCIA = SER.IDSERVICIO
					INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
               INNER JOIN MED ON MED.IDMEDICO = CASE WHEN COALESCE(HPRE.IDMEDICO,'') = '' THEN COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA) ELSE HPRE.IDMEDICO END
			WHERE FTRD.CNSFTR=@CNSFCT
			AND FTRD.PROCEDENCIA='SALUD'
          --AND HADM.IDAFILIADO=@IDAFILIADO
			AND HPRED.N_FACTURA=@N_FACTURA
			AND COALESCE(HPRED.VALOR,0)>0
			AND RIPS_CP.ARCHIVO='AC'
			AND HPRED.CANTIDAD > 1

         IF EXISTS(SELECT 1 FROM @CONSULTAS1)
         BEGIN
            PRINT 'INGRESO A MAYOR QUE 1'

            DECLARE JSCONSUL_CURSOR CURSOR FOR 
            SELECT IDCONSULTA,CANTIDAD FROM @CONSULTAS1
            ORDER BY IDCONSULTA
            OPEN JSCONSUL_CURSOR    
            FETCH NEXT FROM JSCONSUL_CURSOR    
            INTO @CNSCONSULTA,@CANTORI
				WHILE @@FETCH_STATUS = 0    
				BEGIN 
				   PRINT 'INGRESO AL CURSOR CANTIDAD CONSULTAS='+STR(@CANTORI)
				   SELECT @BANDERA=1
				   WHILE @BANDERA<=@CANTORI
				   BEGIN
					  PRINT 'DENTRO DEL WHILE'+STR(@BANDERA)
					  INSERT INTO @CONSULTAS(codPrestador,CONSECUTIVO,IDAFILIADO,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
									finalidadTecnologiaSalud,causaMotivoAtencion,codDiagnosticoPrincipal,codDiagnosticoRelacionado1,codDiagnosticoRelacionado2,
									codDiagnosticoRelacionado3,tipoDiagnosticoPrincipal,vrServicio,conceptoRecaudo,valorPagoModerador,tipoDocumentoIdentificacion, numDocumentoIdentificacion
                          ,PROCEDENCIA )
					  SELECT codPrestador,CONSECUTIVO,IDAFILIADO,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
								finalidadTecnologiaSalud,causaMotivoAtencion,codDiagnosticoPrincipal,codDiagnosticoRelacionado1,codDiagnosticoRelacionado2,
								codDiagnosticoRelacionado3,tipoDiagnosticoPrincipal,vrServicio,conceptoRecaudo,valorPagoModerador, tipoDocumentoIdentificacion, numDocumentoIdentificacion 
                       ,PROCEDENCIA
					  FROM @CONSULTAS1
					  WHERE IDCONSULTA=@CNSCONSULTA

					  SELECT @BANDERA = @BANDERA+1
				   END

				   FETCH NEXT FROM JSCONSUL_CURSOR    
				   INTO  @CNSCONSULTA,@CANTORI
				END
            CLOSE JSCONSUL_CURSOR
            DEALLOCATE JSCONSUL_CURSOR
         END	

      PRINT 'VAMOS POR MEDICAMENTOS'
      BEGIN
		   INSERT INTO @MEDICAMENTOS(codPrestador,IDAFILIADO,CONSECUTIVO,idMIPRES,fechaDispensAdmon,codDiagnosticoPrincipal,codDiagnosticoRelacionado
									   ,tipoMedicamento,codTecnologiaSalud,nomTecnologiaSalud,concentracionMedicamento,unidadMedida,formaFarmaceutica
									   ,unidadMinDispensa,cantidadMedicamento,diasTratamiento,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitMedicamento
									   ,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador)

		   SELECT @IDPRESTADOR,AUT.IDAFILIADO,AUT.NOAUT,null,fechaDispensAdmon=REPLACE(CONVERT(VARCHAR,AUT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,AUT.FECHA,108),5),
			   AUT.DXPPAL,IIF(COALESCE(AUT.DXRELACIONADO,'')='',AUT.DXPPAL,AUT.DXRELACIONADO),'01',CASE WHEN COALESCE(SER.MEDICAMENTOS,0)=1 THEN IIF(COALESCE(IART.CODCUM,'')='',SER.CODCUM,IART.CODCUM) ELSE SER.IDSERVICIO END,
            LEFT( dbo.FNK_LIMPIATEXTO(IART.DESCRIPCION,'0-9 A-Z();:.,'),30),
            CASE WHEN ISNUMERIC(dbo.FNK_LIMPIATEXTO(LEFT(COALESCE(ICCN.DESCRIPCION,'0'),3),'0-9'))=1 THEN dbo.FNK_LIMPIATEXTO(LEFT(COALESCE(ICCN.DESCRIPCION,'0'),3),'0-9') ELSE 0 END,
			   COALESCE(IUNI.HOMOLOGO_RIPS,247),COALESCE(IFFA.HOMOJSON,'null'),'11',CONVERT(VARCHAR,CONVERT(INT,AUTD.CANTIDAD),10),IIF(COALESCE(AUTD.DIAS,0)=0,1,AUTD.DIAS)
           ,COALESCE(MED.TIPO_ID,@TIPO_ID_MEDICODEFAULT,''),COALESCE(MED.IDMEDICO,@IDMEDICODEFAULT,'')
           ,AUTD.VALOR,AUTD.VALOR*AUTD.CANTIDAD,
			   CASE WHEN COALESCE(AUTD.VALORCOPAGO,0)>0 OR COALESCE(AUT.VALORCOPAGO,0)> 0   
			     THEN  CASE  WHEN COALESCE(FTRD.TCOPAGO,'')<> '' THEN FTRD.TCOPAGO 
                          WHEN COALESCE(@ESMODERADORAENFTR,'') <> '' AND COALESCE(AUTD.VALORCOPAGO,0)>0 THEN @ESMODERADORAENFTR  --20250620
                          WHEN COALESCE(AUT.COPAGOPROPIO,0)=1 AND COALESCE(AUT.VALORCOPAGO,0) = 0  THEN '05' -- YCARRILLO 20250519
						        WHEN COALESCE(AUT.COPAGOPROPIO,0)=0 AND COALESCE(AUT.VALORCOPAGO,0)> 0  AND COALESCE(AUTD.VALORCOPAGO,0)= 0 THEN '05'    --20250620
				              WHEN COALESCE(AUT.COPAGOPROPIO,0)=1 AND COALESCE(AUT.VALORCOPAGO,0)> 0  AND COALESCE(AUTD.VALORCOPAGO,0)= 0 THEN '02'    --20250620
                          WHEN COALESCE(@CONCEPTORECAUDOMCE,'') <> '' THEN @CONCEPTORECAUDOMCE --jedm 2025.05.13 Se toma esta variable para saber si se envia todo a copago
                          WHEN COALESCE(AFI.TIPOUSUARIO,'') IN('01','02','03')  THEN '02' 
							ELSE IIF(AFI.TIPOUSUARIO IN('11','05'),'03','01') 
					   END 
				 ELSE @conceptoRecaudo 
			END, 
			   '04',CASE WHEN AUT.VALORCOPAGO = 0 THEN 0 ELSE AUTD.VALORCOPAGO END,AUTD.NFACTURA 
		   FROM FTRD INNER JOIN AUT     ON FTRD.NOADMISION	   =	AUT.NOAUT   --STORRES -- 20250521 -- SE QUITA LA UNICON DE FTRD.NOPRESTACION=AUT.IDAUT
				       INNER JOIN AFI     ON AUT.IDAFILIADO	   =	AFI.IDAFILIADO
                   INNER JOIN AUTD    ON AUT.IDAUT		      =	AUTD.IDAUT --STORRES -- 20250521 -- SE QUITA LA UNICON DE FTRD.NOPRESTACION=AUT.IDAUT
				       INNER JOIN SER     ON AUTD.IDSERVICIO	   =	SER.IDSERVICIO AND FTRD.REFERENCIA = SER.IDSERVICIO
                   INNER JOIN RIPS_CP ON SER.CODIGORIPS	   =	RIPS_CP.IDCONCEPTORIPS
				       LEFT  JOIN IART    ON SER.IDSERVICIO	   =	IART.IDSERVICIO AND COALESCE(IART.PRINCIPAL,0)=1 -- --STORRES -- 20250521 -- SE CAMBIA INNER JOIN POR LEFT JOIN 
                   LEFT  JOIN IFFA    ON IART.IDFORFARM	   =	IFFA.IDFORFARM
                   LEFT  JOIN IUNI    ON IUNI.IDUNIDAD	   =	IART.IDUNIDAD
                   LEFT  JOIN ICCN    ON IART.IDCONCENTRA   =	ICCN.IDCONCENTRA
                   LEFT  JOIN MED     ON AUT.IDSOLICITANTE  =	MED.IDMEDICO
		   WHERE FTRD.CNSFTR=@CNSFCT
          AND FTRD.PROCEDENCIA='CE'
		   AND RIPS_CP.ARCHIVO='AM'
         --AND AUT.IDAFILIADO=@IDAFILIADO
		   AND AUTD.N_FACTURA=@N_FACTURA
         AND COALESCE(AUTD.VALOR,0)>0

		   --CASE WHEN COALESCE(AUTD.VALORCOPAGO,0)>0 OR COALESCE(AUT.VALORCOAPGO,0)> 0   THEN  CASE WHEN COALESCE(AFI.TIPOUSUARIO,'') IN('01','02','03')  THEN '02' ELSE '01' END ELSE @conceptoRecaudo END
         PRINT 'MEDICAMENTOS HADM'

		   INSERT INTO @MEDICAMENTOS(codPrestador,IDAFILIADO,CONSECUTIVO,idMIPRES,fechaDispensAdmon,codDiagnosticoPrincipal,codDiagnosticoRelacionado
									   ,tipoMedicamento,codTecnologiaSalud,nomTecnologiaSalud,concentracionMedicamento,unidadMedida,formaFarmaceutica
									   ,unidadMinDispensa,cantidadMedicamento,diasTratamiento,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitMedicamento
									   ,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador)

		   SELECT @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION,null,fechaDispensAdmon=REPLACE(CONVERT(VARCHAR,FTRD.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,FTRD.FECHA,108),5),
			   COALESCE(HADM.DXINGRESO,'null'),COALESCE(HADM.DXSALIDA1,''),'01',CASE WHEN COALESCE(SER.MEDICAMENTOS,0)=1 THEN IIF(COALESCE(IART.CODCUM,'')='',SER.CODCUM,IART.CODCUM) ELSE SER.IDSERVICIO END,
            LEFT(dbo.FNK_LIMPIATEXTO(IART.DESCRIPCION,'0-9 A-Z();:.,'),30),'0',COALESCE(IUNI.HOMOLOGO_RIPS,247),COALESCE(IFFA.HOMOJSON,'null'),'11',
            CONVERT(VARCHAR,CONVERT(INT,HPRED.CANTIDAD),10),1,AFI.TIPO_DOC,AFI.DOCIDAFILIADO,CONVERT(VARCHAR,CONVERT(DECIMAL(14,2),HPRED.VALOR),20),
			   CONVERT(VARCHAR,CONVERT(DECIMAL(14,2),HPRED.VALOR*HPRED.CANTIDAD),20),IIF(COALESCE(HPRED.VALORCOPAGO,0)>0,'01',@conceptoRecaudo),'04',CONVERT(DECIMAL(14,2),HPRED.VALORCOPAGO),@N_FACTURA
		   FROM FTRD INNER JOIN HADM ON FTRD.NOADMISION=HADM.NOADMISION
                    INNER JOIN AFI  ON HADM.IDAFILIADO=AFI.IDAFILIADO
                    INNER JOIN HPRED ON FTRD.NOPRESTACION=HPRED.NOPRESTACION AND FTRD.NOITEM=HPRED.NOITEM 
                    INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO AND FTRD.REFERENCIA = SER.IDSERVICIO
			   LEFT JOIN IART ON COALESCE(HPRED.IDARTICULO,SER.IDARTICULO)=IART.IDARTICULO
			   LEFT JOIN IFFA ON IART.IDFORFARM=IFFA.IDFORFARM
			   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
			   LEFT JOIN IUNI ON IUNI.IDUNIDAD = IART.IDUNIDAD
		   WHERE FTRD.CNSFTR=@CNSFCT
		   AND FTRD.PROCEDENCIA='SALUD'
		   AND HPRED.N_FACTURA=@N_FACTURA
		   AND COALESCE(HPRED.VALOR,0)>0
		   AND COALESCE(HPRED.NOCOBRABLE,0)=0
		   AND RIPS_CP.ARCHIVO='AM' 

     END

     PRINT 'PROCEDIMIENTOS'


		INSERT INTO @PROCEDIMIENTOS (codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
					,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
					,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador
					)
		SELECT @IDPRESTADOR,CIT.IDAFILIADO,CIT.CONSECUTIVO,REPLACE(CONVERT(VARCHAR,CIT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,CIT.FECHA,108),5),null,
				COALESCE(CIT.NOAUTORIZACION,'null'),LEFT(SER.CODCUPS,6),'02','01','02',325,'16',MED.TIPO_ID,MED.IDTERCERO
            ,COALESCE(HCA.IDDX,CIT.IDDX), 
				COALESCE(CIT.IDDX,'null'),COALESCE(HCA.IDDX,CIT.IDDX,'null')
            ,CASE WHEN COALESCE(FTRD.VLR_SERVICI,0) >0 THEN COALESCE(FTRD.VLR_SERVICI,0)
                  ELSE COALESCE(CIT.VALORTOTAL,0)*COALESCE(CIT.CANTIDADC,1)
             END
				,CASE WHEN COALESCE(CIT.VALORCOPAGO,0)>0 
				      THEN  CASE  WHEN COALESCE(FTRD.TCOPAGO,'')<> '' THEN FTRD.TCOPAGO 
                              WHEN COALESCE(@ESMODERADORAENFTR,'') <> '' THEN @ESMODERADORAENFTR
							         WHEN COALESCE(AFI.TIPOUSUARIO,'') IN('01','02','03') THEN '02' 
						         ELSE IIF(AFI.TIPOUSUARIO IN ('05','11'),'03','01') 
							END 
					   ELSE @conceptoRecaudo 
				 END,
				'04',COALESCE(CIT.VALORCOPAGO,0),CIT.NFACTURA
		FROM  FTRD INNER JOIN CIT ON FTRD.NOADMISION=CIT.CONSECUTIVO
				   INNER JOIN SER ON CIT.IDSERVICIO=SER.IDSERVICIO
				   INNER JOIN AFI ON CIT.IDAFILIADO=AFI.IDAFILIADO
				   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
                   INNER JOIN MED ON CIT.IDMEDICO=MED.IDMEDICO
				   LEFT JOIN HCA ON HCA.CONSECUTIVO=CIT.CONSECUTIVOHCA AND HCA.IDAFILIADO=CIT.IDAFILIADO
		WHERE FTRD.CNSFTR=@CNSFCT
		AND FTRD.PROCEDENCIA='CI'
		 AND CIT.N_FACTURA=@N_FACTURA
		AND RIPS_CP.ARCHIVO='AP'
      AND COALESCE(CIT.VALORTOTAL,0)>0


		INSERT INTO @PROCEDIMIENTOS (codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud,modalidadGrupoServicioTecSal,grupoServicios
                                    ,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion,codDiagnosticoPrincipal,codDiagnosticoRelacionado
                                    ,codComplicacion,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador	)
		SELECT @IDPRESTADOR,AUT.IDAFILIADO,AUT.NOAUT,REPLACE(CONVERT(VARCHAR, AUT.FECHA, 102), '.', '-') + ' ' + LEFT(CONVERT(VARCHAR, AUT.FECHA, 108), 5),NULL
				,AUT.NUMAUTORIZA,LEFT(SER.CODCUPS,6),'02','01','02',325,'16',COALESCE(MED.TIPO_ID, @TIPODOC)
				, COALESCE(MED.IDMEDICO,@DOCIDAFILIADO),AUT.DXPPAL,AUT.DXRELACIONADO,AUT.DXPPAL,COALESCE(AUTD.VALOR, 0),
				 CASE  WHEN COALESCE(FTRD.TCOPAGO,'')<> '' THEN FTRD.TCOPAGO 
                  WHEN COALESCE(@ESMODERADORAENFTR,'') <> '' AND COALESCE(AUTD.VALORCOPAGO,0)>0THEN @ESMODERADORAENFTR --20250620
                  WHEN COALESCE(AUT.COPAGOPROPIO,0)=1 AND COALESCE(AUT.VALORCOPAGO,0)= 0 THEN '05' -- KR 2025-05-26 se agrega cambio para que si se marca copago propio para quitar el copago mande 05 en tipo recaudo.
				     WHEN COALESCE(AUT.COPAGOPROPIO,0)=0 AND COALESCE(AUT.VALORCOPAGO,0)> 0  AND COALESCE(AUTD.VALORCOPAGO,0)= 0 THEN '05'    --20250620
				      WHEN COALESCE(AUT.COPAGOPROPIO,0)=1 AND COALESCE(AUT.VALORCOPAGO,0)> 0  AND COALESCE(AUTD.VALORCOPAGO,0)= 0 THEN '02'    --20250620
                      WHEN COALESCE(AUTD.VALORCOPAGO,0)>0 OR COALESCE(AUT.VALORCOPAGO,0)> 0   
				      THEN  CASE  WHEN COALESCE(FTRD.TCOPAGO,'')<> '' THEN FTRD.TCOPAGO 
                              WHEN COALESCE(@CONCEPTORECAUDOMCE,'') <> '' AND COALESCE(AUTD.VALORCOPAGO,0)>0 THEN @CONCEPTORECAUDOMCE --jedm 2025.05.13 Se toma esta variable para saber si se envia todo a copago
					              WHEN COALESCE(AFI.TIPOUSUARIO,'') IN ('01','02','03')  THEN '01' 
							      ELSE '02' 
							  END 
					  ELSE @conceptoRecaudo 
				 END,-- YCARRILLO
				 '04'
            ,CASE WHEN AUT.IDPLAN IN (DBO.FNK_VALORVARIABLE ('IDPLANPART'),DBO.FNK_VALORVARIABLE ('IDPLANPART2')
										,DBO.FNK_VALORVARIABLE ('IDPLANPART3'),DBO.FNK_VALORVARIABLE ('IDPLANPART4')
										,DBO.FNK_VALORVARIABLE ('IDPLANPART5'))
					   THEN 0 
				  ELSE CONVERT(DECIMAL(14,2), 
				               IIF(COALESCE(AUT.COPAGOPROPIO,0)=1, COALESCE(AUT.VALORCOPAGO,0)/COALESCE(AUT.NO_ITEMES,ROW_NUMBER() OVER (ORDER BY AUTD.NO_ITEM)), COALESCE(AUTD.VALORCOPAGO,0)))
				 
				 
			 END
            ,AUTD.NFACTURA			
		FROM FTRD INNER JOIN  AUT ON FTRD.NOADMISION=AUT.NOAUT
                  INNER JOIN  AFI ON AUT.IDAFILIADO=AFI.IDAFILIADO
                  INNER JOIN AUTD ON AUT.IDAUT = AUTD.IDAUT
			         INNER JOIN SER ON AUTD.IDSERVICIO = SER.IDSERVICIO AND FTRD.REFERENCIA = SER.IDSERVICIO
			         INNER JOIN RIPS_CP ON SER.CODIGORIPS = RIPS_CP.IDCONCEPTORIPS
                  LEFT  JOIN MED ON MED.IDMEDICO = IIF(COALESCE(AUT.IDMEDICOSOLICITA,'')='',DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT'),AUT.IDMEDICOSOLICITA)	
		WHERE FTRD.CNSFTR=@CNSFCT
		AND FTRD.PROCEDENCIA='CE'
		AND AUTD.N_FACTURA = @N_FACTURA
		AND RIPS_CP.ARCHIVO = 'AP'
		AND AUTD.CANTIDAD = 1
      AND COALESCE(AUTD.VALOR,0)>0

      PRINT 'PROCEDIMIENTOS 1'
		INSERT INTO @PROCEDIMIENTOS1 (codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
					,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
					,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,cantidad,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador
					)
		SELECT @IDPRESTADOR,AUT.IDAFILIADO,AUT.NOAUT,REPLACE(CONVERT(VARCHAR, AUT.FECHA, 102), '.', '-') + ' ' + LEFT(CONVERT(VARCHAR, AUT.FECHA, 108), 5),NULL
				,AUT.NUMAUTORIZA,LEFT(SER.CODCUPS,6),'02','01','02',325,'16',COALESCE(MED.TIPO_ID, @TIPODOC), COALESCE(MED.IDMEDICO,@DOCIDAFILIADO),AUT.DXPPAL,AUT.DXRELACIONADO,'null',COALESCE(AUTD.VALOR, 0),
				CASE WHEN COALESCE(FTRD.TCOPAGO,'')<> '' THEN FTRD.TCOPAGO 
                  WHEN COALESCE(@ESMODERADORAENFTR,'') <> '' THEN @ESMODERADORAENFTR
                  WHEN COALESCE(AUT.COPAGOPROPIO,0)=1 AND COALESCE(AUT.VALORCOPAGO,0)= 0 THEN '05' -- KR 2025-05-26 se agrega cambio para que si se marca copago propio para quitar el copago mande 05 en tipo recaudo.
				      WHEN COALESCE(AUTD.VALORCOPAGO,0)>0 OR COALESCE(AUT.VALORCOPAGO,0)> 0   
				      THEN  CASE WHEN COALESCE(@CONCEPTORECAUDOMCE,'') <> '' THEN @CONCEPTORECAUDOMCE --jedm 2025.05.13 Se toma esta variable para saber si se envia todo a copago
					              WHEN COALESCE(AFI.TIPOUSUARIO,'') IN ('01','02','03')  
					              THEN '01' 
							        ELSE '02' 
							  END 
					  ELSE @conceptoRecaudo 
				 END,
				AUTD.CANTIDAD,'04'
            ,CASE WHEN AUT.IDPLAN IN (DBO.FNK_VALORVARIABLE ('IDPLANPART'),DBO.FNK_VALORVARIABLE ('IDPLANPART2')
										,DBO.FNK_VALORVARIABLE ('IDPLANPART3'),DBO.FNK_VALORVARIABLE ('IDPLANPART4')
										,DBO.FNK_VALORVARIABLE ('IDPLANPART5'))
					   THEN 0 
				  ELSE CONVERT(DECIMAL(14,2), 
				               IIF(COALESCE(AUT.COPAGOPROPIO,0)=1, COALESCE(AUT.VALORCOPAGO,0)/COALESCE(AUT.NO_ITEMES,ROW_NUMBER() OVER (ORDER BY AUTD.NO_ITEM)), COALESCE(AUTD.VALORCOPAGO,0)))
				 
				 END
			
			, AUTD.NFACTURA			
      FROM FTRD INNER JOIN  AUT ON FTRD.NOADMISION=AUT.NOAUT
                  INNER JOIN  AFI ON AUT.IDAFILIADO=AFI.IDAFILIADO
                  INNER JOIN AUTD ON AUT.IDAUT = AUTD.IDAUT
			         INNER JOIN SER ON AUTD.IDSERVICIO = SER.IDSERVICIO  AND FTRD.REFERENCIA = SER.IDSERVICIO
			         INNER JOIN RIPS_CP ON SER.CODIGORIPS = RIPS_CP.IDCONCEPTORIPS
                  LEFT  JOIN MED ON MED.IDMEDICO = IIF(COALESCE(AUT.IDMEDICOSOLICITA,'')='',DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT'),AUT.IDMEDICOSOLICITA)	
		WHERE FTRD.CNSFTR=@CNSFCT
		AND FTRD.PROCEDENCIA='CE'
		AND AUTD.N_FACTURA = @N_FACTURA
		AND RIPS_CP.ARCHIVO = 'AP'
		AND AUTD.CANTIDAD > 1
      AND COALESCE(AUTD.VALOR,0)>0

		PRINT 'PROCEDIMIENTO SALUD'
			INSERT INTO @PROCEDIMIENTOS (codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
						,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
						,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador
						)
			SELECT @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION,REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5),null,
				HADM.NOAUTORIZACION,LEFT(SER.CODCUPS,6),COALESCE(REPLACE(TGEN.DATO2,' ',''),HADM.VIAINGRESO,'02'),'01','02',325,'16',MED.TIPO_ID,MED.IDMEDICO,COALESCE(HADM.DXINGRESO,HADM.DXEGRESO), 
				COALESCE(HADM.DXSALIDA1,''),COALESCE(HADM.COMPLICACION,HADM.DXINGRESO,HADM.DXEGRESO),COALESCE(HPRED.VALOR,0),IIF(COALESCE(HPRED.VALORCOPAGO,0)>0,'01',@conceptoRecaudo),'04',COALESCE(HPRED.VALORCOPAGO,0),@N_FACTURA
			FROM  FTRD INNER JOIN HADM ON FTRD.NOADMISION=HADM.NOADMISION
                     INNER JOIN AFI  ON HADM.IDAFILIADO=AFI.IDAFILIADO
					      INNER JOIN HPRED ON FTRD.NOPRESTACION=HPRED.NOPRESTACION AND FTRD.NOITEM=HPRED.NOITEM
                     INNER JOIN HPRE  ON HADM.NOADMISION=HPRE.NOADMISION AND FTRD.NOPRESTACION=HPRE.NOPRESTACION
					      INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO AND FTRD.REFERENCIA = SER.IDSERVICIO
					      INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
                     INNER JOIN TGEN ON HADM.VIAINGRESO = TGEN.CODIGO AND TABLA = 'General' AND CAMPO = 'VIADEINGRESO' 
                     INNER JOIN MED ON MED.IDMEDICO = CASE WHEN COALESCE(HPRE.IDMEDICO,'') = '' THEN COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA) ELSE HPRE.IDMEDICO END 
			WHERE FTRD.CNSFTR=@CNSFCT
			AND FTRD.PROCEDENCIA='SALUD'
			AND HPRED.N_FACTURA=@N_FACTURA
			AND COALESCE(HPRED.VALOR,0)>0
			AND COALESCE(HPRED.NOCOBRABLE,0)=0
			AND HPRED.CANTIDAD=1
			AND RIPS_CP.ARCHIVO='AP' 

         PRINT 'INSERTO CANTIDAS MAYORES A UNO HADM '

			INSERT INTO @PROCEDIMIENTOS1 (codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
						,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
						,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,cantidad,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador
						)
			SELECT @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION,REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5),null,
				HADM.NOAUTORIZACION,LEFT(SER.CODCUPS,6),COALESCE(REPLACE(TGEN.DATO2,' ',''),HADM.VIAINGRESO,'02'),'01','02',325,'16',MED.TIPO_ID,MED.IDMEDICO,COALESCE(HADM.DXINGRESO,HADM.DXEGRESO), 
				COALESCE(HADM.DXSALIDA1,''),COALESCE(HADM.COMPLICACION,HADM.DXINGRESO,HADM.DXEGRESO),COALESCE(HPRED.VALOR,0),IIF(COALESCE(HPRED.VALORCOPAGO,0)>0,'01',@conceptoRecaudo),HPRED.CANTIDAD, '04',COALESCE(HPRED.VALORCOPAGO,0),@N_FACTURA
			FROM  FTRD INNER JOIN HADM ON FTRD.NOADMISION=HADM.NOADMISION
                     INNER JOIN AFI  ON HADM.IDAFILIADO=AFI.IDAFILIADO
					      INNER JOIN HPRED ON FTRD.NOPRESTACION=HPRED.NOPRESTACION AND FTRD.NOITEM=HPRED.NOITEM
                     INNER JOIN HPRE  ON HADM.NOADMISION=HPRE.NOADMISION AND FTRD.NOPRESTACION=HPRE.NOPRESTACION
					      INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO AND FTRD.REFERENCIA = SER.IDSERVICIO
					      INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
                     INNER JOIN TGEN ON HADM.VIAINGRESO = TGEN.CODIGO AND TABLA = 'General' AND CAMPO = 'VIADEINGRESO' 
                     INNER JOIN MED ON MED.IDMEDICO = CASE WHEN COALESCE(HPRE.IDMEDICO,'') = '' THEN COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA) ELSE HPRE.IDMEDICO END
			WHERE FTRD.CNSFTR=@CNSFCT
			AND FTRD.PROCEDENCIA='SALUD'
			AND HPRED.N_FACTURA=@N_FACTURA
			AND COALESCE(HPRED.VALOR,0)>0
			AND COALESCE(HPRED.NOCOBRABLE,0)=0
			AND HPRED.CANTIDAD>1
			AND RIPS_CP.ARCHIVO='AP' 
--QUERY2
--QUERY2
         IF EXISTS(SELECT 1 FROM @PROCEDIMIENTOS1)
         BEGIN

            DECLARE JSPROCE_CURSOR CURSOR FOR 
            SELECT IDPROCE,CANTIDAD FROM @PROCEDIMIENTOS1
            ORDER BY IDPROCE
            OPEN JSPROCE_CURSOR    
            FETCH NEXT FROM JSPROCE_CURSOR    
            INTO @CNSCONSULTA,@CANTORI
            WHILE @@FETCH_STATUS = 0    
            BEGIN 
               PRINT 'INGRESO AL CURSOR CANTIDAD PROCEDIMIENTOS='+STR(@CANTORI)
               SELECT @BANDERA=1
               WHILE @BANDERA<=@CANTORI
               BEGIN
                  PRINT 'DENTRO DEL WHILE'+STR(@BANDERA)
			         INSERT INTO @PROCEDIMIENTOS (codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
						         ,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
						         ,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador
						         )
                  SELECT codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
						         ,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
						         ,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,tipoPagoModerador
								 ,CONVERT(INT,valorPagoModerador/@CANTORI) --JEDM 2025.05.13  se divide el copago entre la cantidad para que no se duplique o triplique, etc
								 ,numFEVPagoModerador
                  FROM @PROCEDIMIENTOS1
                  WHERE IDPROCE=@CNSCONSULTA
               --   print '@CNSCONSULTA >>>>> ' + @CNSCONSULTA

                  SELECT @BANDERA = @BANDERA+1
               END

               FETCH NEXT FROM JSPROCE_CURSOR    
               INTO  @CNSCONSULTA,@CANTORI
            END
            CLOSE JSPROCE_CURSOR
            DEALLOCATE JSPROCE_CURSOR
         END

		
        PRINT  'URGENCIAS'
        
      INSERT INTO @URGENCIAS(codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,causaMotivoAtencion,codDiagnosticoPrincipalE,
                              codDiagnosticoRelacionadoE1,codDiagnosticoRelacionadoE2,codDiagnosticoRelacionadoE3,condicionDestinoUsuarioEgreso,
                              codDiagnosticoCausaMuerte,fechaEgreso)
		SELECT @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION, REPLACE(CONVERT(VARCHAR,HADM.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HADM.FECHA,108),5),
		CASE WHEN COALESCE(TGEN.CHECK1,0)=1 THEN DATO1 ELSE CODIGO END,COALESCE(HCA.IDDX,HADM.DXINGRESO),COALESCE(HADM.DXEGRESO,HCA.DX1),
		COALESCE(HCA.DX1,HADM.DXSALIDA1),COALESCE(HCA.DX2,HADM.DXSALIDA2),CASE WHEN HADM.ESTADOPSALIDA=1 THEN '01' ELSE '02' END,
		CASE WHEN HADM.ESTADOPSALIDA=1 THEN null ELSE CAUSABMUERTE END,
		REPLACE(CONVERT(VARCHAR,HADM.FECHAALTAMED,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HADM.FECHAALTAMED,108),5)
		FROM FTRD INNER JOIN HADM ON FTRD.NOADMISION=HADM.NOADMISION  
                LEFT JOIN HCA ON HADM.NOADMISION=HCA.NOADMISION
                LEFT JOIN TGEN ON HADM.CAUSAEXTERNA=TGEN.CODIGO AND TGEN.TABLA='General' AND TGEN.CAMPO='CAUSAEXTERNA'
		WHERE FTRD.CNSFTR=@CNSFCT 
		AND FTRD.PROCEDENCIA='SALUD'
		AND HADM.NOADMISION=@NOADMISION
		AND DATEDIFF(HOUR,HADM.FECHA,HADM.FECHAALTAMED)<=48
		AND HCA.CLASE='HC'
		AND HCA.PROCEDENCIA='QX'
		AND HCA.CLASEPLANTILLA <> DBO.FNK_VALORVARIABLE('HCPLANTILLAEPI')

      PRINT 'HOSPITALIZACION'
      
      DECLARE @F_FACTURA DATETIME
      SELECT @F_FACTURA=F_FACTURA FROM FTR WHERE N_FACTURA=@N_FACTURA

      INSERT INTO @HOSPITALIZACION (codPrestador,IDAFILIADO,CONSECUTIVO,viaIngresoServicioSalud,fechaInicioAtencion,numAutorizacion,causaMotivoAtencion,codDiagnosticoPrincipal,
                                    codDiagnosticoPrincipalE,codDiagnosticoRelacionadoE1,codDiagnosticoRelacionadoE2,codDiagnosticoRelacionadoE3,
                                    codComplicacion,condicionDestinoUsuarioEgreso,codDiagnosticoCausaMuerte,fechaEgreso)
		--SELECT @fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,MIN(COALESCE(FECHAPREST,FECHA)),102),'.','-')+' '+LEFT(CONVERT(VARCHAR,MIN(COALESCE(FECHAPREST,FECHA)),108),5) FROM FTRD WHERE N_FACTURA=@N_FACTURA 


		SELECT @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION,COALESCE(REPLACE(TGEN.DATO2,' ',''),HADM.VIAINGRESO,'01'),
         -- REPLACE(CONVERT(VARCHAR,MIN(FTRD.FECHA),102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HADM.FECHA,108),5)
         REPLACE(CONVERT(VARCHAR,HADM.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HADM.FECHA,108),5)
			,HADM.NOAUTORIZACION
			,COALESCE(REPLACE(TGEN2.DATO1,' ',''),HADM.CAUSAEXTERNA,'38')-- CPALACIO
			,COALESCE(HCA.IDDX,HADM.DXINGRESO)
			,COALESCE(HADM.DXEGRESO,HCA.DX1)
			,COALESCE(HCA.DX1,HADM.DXSALIDA1)
			,COALESCE(HCA.DX2,HADM.DXSALIDA2)
			,COALESCE(HCA.DX3,HADM.DXSALIDA3)
			,COALESCE(HADM.COMPLICACION,HCA.IDDX,HADM.DXINGRESO,HADM.DXEGRESO)
			,CASE WHEN HADM.ESTADOPSALIDA=1 THEN '01' ELSE '02' END
			,CASE WHEN HADM.ESTADOPSALIDA=1 THEN '' ELSE CAUSABMUERTE END
			,REPLACE(CONVERT(VARCHAR,HADM.FECHAALTAMED,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HADM.FECHAALTAMED,108),5)
		FROM FTRD INNER JOIN HADM ON FTRD.NOADMISION=HADM.NOADMISION
                 LEFT JOIN HCA ON HADM.NOADMISION=HCA.NOADMISION
                 LEFT JOIN TGEN ON HADM.VIAINGRESO = TGEN.CODIGO AND TABLA = 'General' AND CAMPO = 'VIADEINGRESO' 
			        LEFT JOIN TGEN TGEN2 ON HADM.CAUSAEXTERNA = TGEN2.CODIGO AND TGEN2.TABLA = 'General' AND TGEN2.CAMPO = 'CAUSAEXTERNA' --CPALACIO
		WHERE FTRD.CNSFTR=@CNSFCT 
		AND FTRD.PROCEDENCIA='SALUD'
		AND DATEDIFF(HOUR,HADM.FECHA,HADM.FECHAALTAMED)<=48
		AND HCA.CLASE='HC'
		AND HCA.PROCEDENCIA='QX'
      PRINT 'RECIEN NACIDOS'     
      INSERT INTO @RECIEN(codPrestador,IDAFILIADO,CONSECUTIVO,tipoDocumentoIdentificacion,numDocumentoIdentificacion,fechaNacimiento,
                          edadGestacional,numConsultasCPrenatal,codSexoBiologico,peso, codDiagnosticoPrincipal,condicionDestinoUsuarioEgreso,
                          codDiagnosticoCausaMuerte,fechaEgreso
                           )

      SELECT @IDPRESTADOR,'CN',HADM.IDAFILIADO,HADM.NOADMISION,HADM.IDAFILIADO,
      REPLACE(CONVERT(VARCHAR,QXRCN.RNFECHANACE,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,QXRCN.RNFECHANACE,108),5),
      QXRCN.CMPERIODOGES,QXRCN.CMCONTROLPRE,QXRCN.RNSEXO,
      QXRCN.RNPESO,QXRCN.RNDX,QXRCN.ESTADORN,
      QXRCN.CMCAUSAMUERTE,
      REPLACE(CONVERT(VARCHAR,HADM.FECHAALTAMED,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HADM.FECHAALTAMED,108),5)
      FROM FTRD INNER JOIN HADM ON FTRD.NOADMISION=HADM.NOADMISION
                  INNER JOIN QXRCN ON HADM.NOADMISION=QXRCN.NOADMISION
      WHERE FTRD.CNSFTR=@CNSFCT
      AND FTRD.PROCEDENCIA='SALUD'


      PRINT 'OTROS SERVICIOS'

		INSERT INTO @OTROSSER(codPrestador,IDAFILIADO,CONSECUTIVO,numAutorizacion,idMIPRES,fechaSuministroTecnologia,tipoOS,codTecnologiaSalud,nomTecnologiaSalud
							,cantidadOS,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitOS,vrServicio,conceptoRecaudo,tipoPagoModerador
							,valorPagoModerador,numFEVPagoModerador)
		SELECT @IDPRESTADOR,CIT.IDAFILIADO,CIT.CONSECUTIVO,numAutorizacion=CIT.NOAUTORIZACION,null,
		fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,CIT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,CIT.FECHA,108),5),
		tipoOS='04',codTecnologiaSalud=SER.CODCUPS,nomTecnologiaSalud=LEFT(dbo.FNK_LIMPIATEXTO(SER.DESCSERVICIO,'0-9 A-Z();:.,'),60),
		cantidadOS=COALESCE(CIT.CANTIDADC,1),tipoDocumentoIdentificacion=MED.TIPO_ID, --- YCARRILLO
		numDocumentoIdentificacion=MED.IDTERCERO,COALESCE(CIT.VALORTOTAL,0),COALESCE(CIT.VALORTOTAL,0),
		 CASE WHEN COALESCE(CIT.VALORCOPAGO,0)>0 THEN  CASE  WHEN COALESCE(FTRD.TCOPAGO,'')<> '' THEN FTRD.TCOPAGO 
                                                           WHEN COALESCE(AFI.TIPOUSUARIO,'') IN('01','02','03')  THEN '02' 
                                                           ELSE '01' END 
                                    ELSE @conceptoRecaudo END,
		tipoPagoModerador='04',COALESCE(CIT.VALORCOPAGO,0),
		@N_FACTURA
		FROM FTRD INNER JOIN CIT ON FTRD.NOADMISION=CIT.CONSECUTIVO
                 INNER JOIN AFI ON CIT.IDAFILIADO=AFI.IDAFILIADO
                 INNER JOIN SER ON CIT.IDSERVICIO=SER.IDSERVICIO 
				 INNER JOIN MED ON CIT.IDMEDICO=MED.IDMEDICO  --- YCARRILLO
				 INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
		WHERE FTRD.CNSFTR=@CNSFCT
		AND FTRD.PROCEDENCIA='CI'
		AND CIT.N_FACTURA=@N_FACTURA
		AND RIPS_CP.ARCHIVO='AT'
      AND COALESCE(CIT.VALORTOTAL,0)>0

		INSERT INTO @OTROSSER(codPrestador,IDAFILIADO,CONSECUTIVO,numAutorizacion,idMIPRES,fechaSuministroTecnologia,tipoOS,codTecnologiaSalud,nomTecnologiaSalud
							,cantidadOS,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitOS,vrServicio,conceptoRecaudo,tipoPagoModerador
							,valorPagoModerador,numFEVPagoModerador)
		SELECT @IDPRESTADOR,AUT.IDAFILIADO,AUT.NOAUT,numAutorizacion=AUT.NUMAUTORIZA,null,
		fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,AUT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,AUT.FECHA,108),5),
		tipoOS='04',codTecnologiaSalud=SER.IDSERVICIO,nomTecnologiaSalud=LEFT( dbo.FNK_LIMPIATEXTO(SER.DESCSERVICIO,'0-9 A-Z();:.,'),60),
		cantidadOS=COALESCE(AUTD.CANTIDAD,1),tipoDocumentoIdentificacion=MED.TIPO_ID,
		numDocumentoIdentificacion=MED.IDMEDICO,
		COALESCE(AUTD.VALOR,0),
		COALESCE(AUTD.VALOR,0)*COALESCE(AUTD.CANTIDAD, 0),
		CASE WHEN COALESCE(AUTD.VALORCOPAGO,0)>0 OR COALESCE(AUT.VALORCOPAGO,0)> 0   
      THEN  CASE  WHEN COALESCE(FTRD.TCOPAGO,'')<> '' THEN FTRD.TCOPAGO 
                  WHEN COALESCE(AFI.TIPOUSUARIO,'') IN('01','02','03')  THEN '02' ELSE '01' END
      ELSE @conceptoRecaudo END,
		tipoPagoModerador='04',
		COALESCE(AUT.VALORCOPAGO,0),
		@N_FACTURA
		FROM FTRD INNER JOIN AUT ON FTRD.NOADMISION= AUT.NOAUT
				    INNER JOIN AFI ON AUT.IDAFILIADO=AFI.IDAFILIADO
                INNER JOIN AUTD ON AUT.IDAUT=AUTD.IDAUT
				    INNER JOIN SER ON AUTD.IDSERVICIO=SER.IDSERVICIO AND FTRD.REFERENCIA = SER.IDSERVICIO
				    LEFT  JOIN MED		ON MED.IDMEDICO    = IIF(COALESCE(AUT.IDMEDICOSOLICITA,'')='',DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT'),AUT.IDMEDICOSOLICITA)
				    INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
		WHERE FTRD.CNSFTR=@CNSFCT
		AND FTRD.PROCEDENCIA='CE'
		--AND AUT.NOAUT=@NOADMISION
		AND AUTD.N_FACTURA=@N_FACTURA
		AND RIPS_CP.ARCHIVO='AT'
      AND COALESCE(AUTD.VALOR,0)>0

			INSERT INTO @OTROSSER(codPrestador,IDAFILIADO,CONSECUTIVO,numAutorizacion,idMIPRES,fechaSuministroTecnologia,tipoOS,codTecnologiaSalud,nomTecnologiaSalud
								,cantidadOS,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitOS,vrServicio,conceptoRecaudo,tipoPagoModerador
								,valorPagoModerador,numFEVPagoModerador)
			SELECT @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION                                                                   
            ,numAutorizacion=HADM.NOAUTORIZACION
            ,null                                                                             
            ,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5)
            ,tipoOS='04'
            ,codTecnologiaSalud=CASE WHEN RIPS_CP.IDCONCEPTORIPS=DBO.FNK_VALORVARIABLE('IDMATERIALESRIPS')THEN SER.IDSERVICIO ELSE SER.CODCUPS END
            ,nomTecnologiaSalud=LEFT( dbo.FNK_LIMPIATEXTO(SER.DESCSERVICIO,'0-9 A-Z();:.,'),60)
            ,cantidadOS=CONVERT(INT,COALESCE(HPRED.CANTIDAD,1))
            ,tipoDocumentoIdentificacion=MED.TIPO_ID
            ,numDocumentoIdentificacion=MED.IDMEDICO
            ,CONVERT(DECIMAL(14,2),COALESCE(HPRED.VALOR,0))
            ,CONVERT(DECIMAL(14,2),COALESCE(HPRED.VALOR*HPRED.CANTIDAD,0))
			   ,IIF(COALESCE(HPRED.VALORCOPAGO,0)>0,'01',@conceptoRecaudo)
            ,tipoPagoModerador='04'
            ,CONVERT(DECIMAL(14,2),COALESCE(HPRED.VALORCOPAGO,0)) 
            ,@N_FACTURA                                                                       
			FROM FTRD INNER JOIN HADM ON FTRD.NOADMISION=HADM.NOADMISION
                    INNER JOIN  HPRE ON HADM.NOADMISION=HPRE.NOADMISION
					     INNER JOIN HPRED ON HPRE.NOPRESTACION=HPRED.NOPRESTACION AND HPRED.NOITEM = FTRD.NOITEM
					     INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO AND FTRD.REFERENCIA = SER.IDSERVICIO
					     LEFT JOIN HCA ON HPRE.CONSECUTIVOHCA=HCA.CONSECUTIVO
					     INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
					     INNER JOIN MED ON MED.IDMEDICO= CASE WHEN COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA,HADM.IDMEDICOING)='' THEN HPRE.IDMEDICO ELSE COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA,HADM.IDMEDICOING) END
			WHERE FTRD.CNSFTR=@CNSFCT
			AND FTRD.PROCEDENCIA='SALUD'
			AND HPRED.N_FACTURA=@N_FACTURA
			AND RIPS_CP.ARCHIVO='AT'   
			AND COALESCE(HPRED.VALOR,0)>0
			AND COALESCE(HPRED.NOCOBRABLE,0)=0
      
        PRINT 'ASOCIANDO IDUSUARIO'

        UPDATE @CONSULTAS SET usuarioId=US.usuarioId
        FROM @CONSULTAS AC INNER JOIN @USUARIOS US ON AC.IDAFILIADO=US.IDAFILIADO

        UPDATE @MEDICAMENTOS SET usuarioId=US.usuarioId
        FROM @MEDICAMENTOS AM INNER JOIN @USUARIOS US ON AM.IDAFILIADO=US.IDAFILIADO

        UPDATE @PROCEDIMIENTOS SET usuarioId=US.usuarioId
        FROM @PROCEDIMIENTOS AP INNER JOIN @USUARIOS US ON AP.IDAFILIADO=US.IDAFILIADO

        UPDATE @OTROSSER SET usuarioId=US.usuarioId
        FROM @OTROSSER OT INNER JOIN @USUARIOS US ON OT.IDAFILIADO=US.IDAFILIADO

        UPDATE @URGENCIAS SET usuarioId=US.usuarioId
        FROM @URGENCIAS AU INNER JOIN @USUARIOS US ON AU.IDAFILIADO=US.IDAFILIADO

        UPDATE @HOSPITALIZACION SET usuarioId=US.usuarioId
        FROM @HOSPITALIZACION AH INNER JOIN @USUARIOS US ON AH.IDAFILIADO=US.IDAFILIADO

        UPDATE @RECIEN SET usuarioId=US.usuarioId
        FROM @RECIEN AN INNER JOIN @USUARIOS US ON AN.IDAFILIADO=US.IDAFILIADO

        PRINT 'ARMADO TABLA DIAGNOSTICOS '



        INSERT INTO @DX (IDAFILIADO,NOADMISION,CONSECUTIVOCIT,TIPODX,IDDX,DX1,DX2,DX3)
        SELECT HCA.IDAFILIADO,HCA.NOADMISION,HCA.CONSECUTIVOCIT,
        CASE HCA.TIPODX 
							WHEN 'Presuntivo'   THEN '01'
							WHEN 'Impresion dx' THEN '01'
							WHEN 'Definitivo'   THEN '01'
							WHEN 'Conf Nuevo'   THEN '02'
							WHEN 'Conf Repet'   THEN '03'
							ELSE '01'
							END
        ,LEFT(TRIM(HCA.IDDX),4),LEFT(TRIM(HCA.DX1),4),LEFT(TRIM(HCA.DX2),4)
		,CASE WHEN COALESCE(LEFT(TRIM(HCA.DX3),4),'') = '' THEN NULL ELSE COALESCE(LEFT(TRIM(HCA.DX3),4),'') END
        FROM HCA INNER JOIN CIT ON HCA.CONSECUTIVOCIT=CIT.CONSECUTIVO
        WHERE 
			HCA.PROCEDENCIA='IPS'
        AND COALESCE(HCA.IDDX,'')<>''
        AND EXISTS(SELECT * FROM FTRD WHERE FTRD.NOADMISION=CIT.CONSECUTIVO AND FTRD.PROCEDENCIA='CI' AND FTRD.N_FACTURA = @N_FACTURA )
        UNION 
        SELECT HCA.IDAFILIADO,HCA.NOADMISION,HCA.CONSECUTIVOCIT,
               CASE HCA.TIPODX 
							WHEN 'Presuntivo'   THEN '01'
							WHEN 'Impresion dx' THEN '01'
							WHEN 'Definitivo'   THEN '01'
							WHEN 'Conf Nuevo'   THEN '02'
							WHEN 'Conf Repet'   THEN '03'
							ELSE '01'
			   END
			  ,LEFT(TRIM(HCA.IDDX),4),LEFT(TRIM(HCA.DX1),4),LEFT(TRIM(HCA.DX2),4)
			  ,CASE WHEN COALESCE(LEFT(TRIM(HCA.DX3),4),'') = '' THEN NULL ELSE COALESCE(LEFT(TRIM(HCA.DX3),4),'') END
        FROM  HCA INNER JOIN HADM ON HCA.NOADMISION=HADM.NOADMISION
        WHERE HCA.CLASE='HC'
        AND HCA.PROCEDENCIA='QX'
        AND EXISTS(SELECT * FROM FTRD WHERE FTRD.NOADMISION=HADM.NOADMISION AND FTRD.PROCEDENCIA='SALUD'  AND FTRD.N_FACTURA = @N_FACTURA)

        UPDATE @DX SET NIDDX=MDX.DESCRIPCION
        FROM @DX DX INNER JOIN MDX ON DX.IDDX=MDX.IDDX

        UPDATE @DX SET NDX1=MDX.DESCRIPCION
        FROM @DX DX INNER JOIN MDX ON DX.DX1=MDX.IDDX

        UPDATE @DX SET NDX2=MDX.DESCRIPCION
        FROM @DX DX INNER JOIN MDX ON DX.DX2=MDX.IDDX

        UPDATE @DX SET NDX3=MDX.DESCRIPCION
        FROM @DX DX INNER JOIN MDX ON DX.DX3=MDX.IDDX

		PRINT 'Diagnosticos consultas'

        
		-- Actualización de @CONSULTAS con los diagnósticos principales y relacionados en un solo bloque

		UPDATE AC
		SET 
			AC.codDiagnosticoPrincipal = CASE WHEN COALESCE(AC.codDiagnosticoPrincipal, '') = '' THEN DX.IDDX ELSE AC.codDiagnosticoPrincipal END,
			AC.tipoDiagnosticoPrincipal = DX.TIPODX,
			AC.codDiagnosticoRelacionado1 = CASE WHEN COALESCE(AC.codDiagnosticoRelacionado1, '') = '' THEN DX.DX2 ELSE AC.codDiagnosticoRelacionado2 END,
			AC.codDiagnosticoRelacionado2 = CASE WHEN COALESCE(AC.codDiagnosticoRelacionado2, '') = '' THEN DX.DX2 ELSE AC.codDiagnosticoRelacionado2 END,
			AC.codDiagnosticoRelacionado3 = CASE WHEN COALESCE(AC.codDiagnosticoRelacionado3, '') = '' THEN LEFT(TRIM(DX.DX3),4) ELSE AC.codDiagnosticoRelacionado3 END
		FROM @CONSULTAS AC
		INNER JOIN @DX DX ON AC.IDAFILIADO = DX.IDAFILIADO
		WHERE COALESCE(DX.IDDX, '') <> '' 
		  OR COALESCE(DX.DX1, '') <> ''
		  OR COALESCE(DX.DX2, '') <> ''
		  OR COALESCE(DX.DX3, '') <> '';

        PRINT 'Diagnosticos medicamentos'
		UPDATE AM
		SET 
			AM.codDiagnosticoPrincipal = CASE WHEN COALESCE(AM.codDiagnosticoPrincipal, '') = '' THEN DX.IDDX ELSE AM.codDiagnosticoPrincipal END,
			AM.codDiagnosticoRelacionado = CASE WHEN COALESCE(AM.codDiagnosticoRelacionado, '') = '' THEN DX.DX1 ELSE AM.codDiagnosticoRelacionado END
		FROM @MEDICAMENTOS AM
		INNER JOIN @DX DX ON AM.IDAFILIADO = DX.IDAFILIADO
		WHERE COALESCE(DX.IDDX, '') <> '';

        PRINT 'Diagnosticos procedimientos'
		UPDATE AP
		SET 
			AP.codDiagnosticoPrincipal = CASE WHEN COALESCE(AP.codDiagnosticoPrincipal, '') = '' THEN COALESCE(DX.IDDX,'null') ELSE CASE WHEN COALESCE(AP.codDiagnosticoPrincipal,'')='' THEN 'null' ELSE AP.codDiagnosticoPrincipal END END,
			AP.codDiagnosticoRelacionado = CASE WHEN COALESCE(AP.codDiagnosticoRelacionado, '') = '' THEN COALESCE(DX.DX1,'null') ELSE CASE WHEN COALESCE(AP.codDiagnosticoRelacionado,'')='' THEN 'null' ELSE AP.codDiagnosticoRelacionado END  END
		FROM @PROCEDIMIENTOS AP
		INNER JOIN @DX DX ON AP.IDAFILIADO = DX.IDAFILIADO
		--WHERE (COALESCE(DX.IDDX, '') <> '' OR COALESCE(DX.DX1,'')<>'') ;

	   UPDATE @PROCEDIMIENTOS SET codDiagnosticoRelacionado='null' WHERE LEN(COALESCE(codDiagnosticoRelacionado,''))<4

        PRINT 'URGENCIAS'

        --UPDATE @URGENCIAS SET 
        --codDiagnosticoPrincipalE=CASE WHEN COALESCE(AU.codDiagnosticoPrincipalE,'')='' THEN  DX.IDDX ELSE AU.codDiagnosticoPrincipalE END
        --FROM @URGENCIAS AU INNER JOIN @DX DX ON AU.IDAFILIADO=DX.IDAFILIADO
        --WHERE COALESCE(DX.IDDX,'')<>''

        --UPDATE @URGENCIAS SET 
        --codDiagnosticoRelacionadoE1=CASE WHEN COALESCE(AU.codDiagnosticoRelacionadoE1,'')='' THEN  DX.DX1 ELSE AU.codDiagnosticoRelacionadoE1 END
        --FROM @URGENCIAS AU INNER JOIN @DX DX ON AU.IDAFILIADO=DX.IDAFILIADO
        --WHERE COALESCE(DX.DX1,'')<>''

        --UPDATE @URGENCIAS SET 
        --codDiagnosticoRelacionadoE2=CASE WHEN COALESCE(AU.codDiagnosticoRelacionadoE2,'')='' THEN  DX.DX2 ELSE AU.codDiagnosticoRelacionadoE2 END
        --FROM @URGENCIAS AU INNER JOIN @DX DX ON AU.IDAFILIADO=DX.IDAFILIADO
        --WHERE COALESCE(DX.DX2,'')<>''

        --UPDATE @URGENCIAS SET 
        --codDiagnosticoRelacionadoE3=CASE WHEN COALESCE(AU.codDiagnosticoRelacionadoE3,'')='' THEN  DX.DX3 ELSE AU.codDiagnosticoRelacionadoE3 END
        --FROM @URGENCIAS AU INNER JOIN @DX DX ON AU.IDAFILIADO=DX.IDAFILIADO
        --WHERE COALESCE(DX.DX3,'')<>''

		UPDATE AU
		SET 
			AU.codDiagnosticoPrincipalE = CASE WHEN COALESCE(AU.codDiagnosticoPrincipalE, '') = '' THEN DX.IDDX ELSE AU.codDiagnosticoPrincipalE END,
			AU.codDiagnosticoRelacionadoE1 = CASE WHEN COALESCE(AU.codDiagnosticoRelacionadoE1, '') = '' THEN DX.DX1 ELSE AU.codDiagnosticoRelacionadoE1 END,
			AU.codDiagnosticoRelacionadoE2 = CASE WHEN COALESCE(AU.codDiagnosticoRelacionadoE2, '') = '' THEN DX.DX2 ELSE AU.codDiagnosticoRelacionadoE2 END,
			AU.codDiagnosticoRelacionadoE3 = CASE WHEN COALESCE(AU.codDiagnosticoRelacionadoE3, '') = '' THEN DX.DX3 ELSE AU.codDiagnosticoRelacionadoE3 END
		FROM @URGENCIAS AU
		INNER JOIN @DX DX ON AU.IDAFILIADO = DX.IDAFILIADO
		WHERE COALESCE(DX.IDDX, '') <> '';

        PRINT 'HOSPITALIZACION'

        --UPDATE @HOSPITALIZACION SET 
        --codDiagnosticoPrincipal=CASE WHEN COALESCE(AH.codDiagnosticoPrincipal,'')='' THEN  DX.IDDX ELSE AH.codDiagnosticoPrincipal END
        --FROM @HOSPITALIZACION AH INNER JOIN @DX DX ON AH.IDAFILIADO=DX.IDAFILIADO
        --WHERE COALESCE(DX.IDDX,'')<>''

        --UPDATE @HOSPITALIZACION SET 
        --codDiagnosticoRelacionadoE1=CASE WHEN COALESCE(AH.codDiagnosticoRelacionadoE1,'')='' THEN  DX.DX1 ELSE AH.codDiagnosticoRelacionadoE1 END
        --FROM @HOSPITALIZACION AH INNER JOIN @DX DX ON AH.IDAFILIADO=DX.IDAFILIADO
        --WHERE COALESCE(DX.DX1,'')<>''

        --UPDATE @HOSPITALIZACION SET 
        --codDiagnosticoRelacionadoE2=CASE WHEN COALESCE(AH.codDiagnosticoRelacionadoE2,'')='' THEN  DX.DX2 ELSE AH.codDiagnosticoRelacionadoE2 END
        --FROM @HOSPITALIZACION AH INNER JOIN @DX DX ON AH.IDAFILIADO=DX.IDAFILIADO
        --WHERE COALESCE(DX.DX2,'')<>''

        --UPDATE @HOSPITALIZACION SET 
        --codDiagnosticoRelacionadoE2=CASE WHEN COALESCE(AH.codDiagnosticoRelacionadoE2,'')='' THEN  DX.DX3 ELSE AH.codDiagnosticoRelacionadoE2 END
        --FROM @HOSPITALIZACION AH INNER JOIN @DX DX ON AH.IDAFILIADO=DX.IDAFILIADO
        --WHERE COALESCE(DX.DX3,'')<>''

		UPDATE AH
		SET 
			AH.codDiagnosticoPrincipal = CASE WHEN COALESCE(AH.codDiagnosticoPrincipal, '') = '' THEN DX.IDDX ELSE AH.codDiagnosticoPrincipal END,
			AH.codDiagnosticoRelacionadoE1 = CASE WHEN COALESCE(AH.codDiagnosticoRelacionadoE1, '') = '' THEN DX.DX1 ELSE AH.codDiagnosticoRelacionadoE1 END,
			AH.codDiagnosticoRelacionadoE2 = CASE WHEN COALESCE(AH.codDiagnosticoRelacionadoE2, '') = '' THEN DX.DX2 ELSE AH.codDiagnosticoRelacionadoE2 END,
			AH.codDiagnosticoRelacionadoE3 = CASE WHEN COALESCE(AH.codDiagnosticoRelacionadoE3, '') = '' THEN DX.DX3 ELSE AH.codDiagnosticoRelacionadoE3 END
		FROM @HOSPITALIZACION AH
		INNER JOIN @DX DX ON AH.IDAFILIADO = DX.IDAFILIADO
		WHERE COALESCE(DX.IDDX, '') <> '';

		PRINT 'TERMINE DE PREPARAR LOS DATOS'
	   PRINT 'TERMINE DE PREPARAR LOS DATOS'
      DECLARE @IDAFILIADOANT VARCHAR(20)=''
      DECLARE @IDAFILIADO VARCHAR(20)
      DECLARE @CNSX INT 
      DECLARE @ID INT 
      --UPDATE @CONSULTAS SET conceptoRecaudo='05'
      DECLARE PG_CURSOR CURSOR FOR 
      SELECT ID,IDAFILIADO FROM @CONSULTAS
      ORDER BY IDAFILIADO ASC
      OPEN PG_CURSOR    
      FETCH NEXT FROM PG_CURSOR    
      INTO @ID, @IDAFILIADO
      WHILE @@FETCH_STATUS = 0    
      BEGIN 
         IF @IDAFILIADOANT<>@IDAFILIADO
         BEGIN
            SELECT @CNSX=1,@IDAFILIADOANT=@IDAFILIADO
         END
         ELSE
         BEGIN
            SELECT @CNSX = @CNSX+1
         END
         UPDATE @CONSULTAS SET xconsecutivo=@CNSX WHERE ID=@ID
         FETCH NEXT FROM PG_CURSOR    
         INTO @ID, @IDAFILIADO
      END
      CLOSE PG_CURSOR
      DEALLOCATE PG_CURSOR
      --PROCEDIMIENTOS
      SELECT @ID=0,@IDAFILIADOANT=''
      DECLARE PG_CURSOR CURSOR FOR 
      SELECT ID,IDAFILIADO FROM @PROCEDIMIENTOS
      ORDER BY IDAFILIADO ASC
      OPEN PG_CURSOR    
      FETCH NEXT FROM PG_CURSOR    
      INTO @ID, @IDAFILIADO
      WHILE @@FETCH_STATUS = 0    
      BEGIN 
         IF @IDAFILIADOANT<>@IDAFILIADO
         BEGIN
            SELECT @CNSX=1,@IDAFILIADOANT=@IDAFILIADO
         END
         ELSE
         BEGIN
            SELECT @CNSX = @CNSX+1
         END
         UPDATE @PROCEDIMIENTOS SET xconsecutivo=@CNSX WHERE ID=@ID
         FETCH NEXT FROM PG_CURSOR    
         INTO @ID, @IDAFILIADO
      END
      CLOSE PG_CURSOR
      DEALLOCATE PG_CURSOR

    --MEDICAMENTOS
      SELECT @ID=0,@IDAFILIADOANT=''
      DECLARE PG_CURSOR CURSOR FOR 
      SELECT ID,IDAFILIADO FROM @MEDICAMENTOS
      ORDER BY IDAFILIADO ASC
      OPEN PG_CURSOR    
      FETCH NEXT FROM PG_CURSOR    
      INTO @ID, @IDAFILIADO
      WHILE @@FETCH_STATUS = 0    
      BEGIN 
         IF @IDAFILIADOANT<>@IDAFILIADO
         BEGIN
            SELECT @CNSX=1,@IDAFILIADOANT=@IDAFILIADO
         END
         ELSE
         BEGIN
            SELECT @CNSX = @CNSX+1
         END
         UPDATE @MEDICAMENTOS SET xconsecutivo=@CNSX WHERE ID=@ID
         FETCH NEXT FROM PG_CURSOR    
         INTO @ID, @IDAFILIADO
      END
      CLOSE PG_CURSOR
      DEALLOCATE PG_CURSOR

    --OTROS SERVICIOS
      SELECT @ID=0,@IDAFILIADOANT=''
      DECLARE PG_CURSOR CURSOR FOR 
      SELECT ID,IDAFILIADO FROM @OTROSSER
      ORDER BY IDAFILIADO ASC
      OPEN PG_CURSOR    
      FETCH NEXT FROM PG_CURSOR    
      INTO @ID, @IDAFILIADO
      WHILE @@FETCH_STATUS = 0    
      BEGIN 
         IF @IDAFILIADOANT<>@IDAFILIADO
         BEGIN
            SELECT @CNSX=1,@IDAFILIADOANT=@IDAFILIADO
         END
         ELSE
         BEGIN
            SELECT @CNSX = @CNSX+1
         END
         UPDATE @OTROSSER SET xconsecutivo=@CNSX WHERE ID=@ID
         FETCH NEXT FROM PG_CURSOR    
         INTO @ID, @IDAFILIADO
      END
      CLOSE PG_CURSOR
      DEALLOCATE PG_CURSOR

    --OTROS HOSPITALIZACION
      SELECT @ID=0,@IDAFILIADOANT=''
      DECLARE PG_CURSOR CURSOR FOR 
      SELECT ID,IDAFILIADO FROM @HOSPITALIZACION
      ORDER BY IDAFILIADO ASC
      OPEN PG_CURSOR    
      FETCH NEXT FROM PG_CURSOR    
      INTO @ID, @IDAFILIADO
      WHILE @@FETCH_STATUS = 0    
      BEGIN 
         IF @IDAFILIADOANT<>@IDAFILIADO
         BEGIN
            SELECT @CNSX=1,@IDAFILIADOANT=@IDAFILIADO
         END
         ELSE
         BEGIN
            SELECT @CNSX = @CNSX+1
         END
         UPDATE @HOSPITALIZACION SET xconsecutivo=@CNSX WHERE ID=@ID
         FETCH NEXT FROM PG_CURSOR    
         INTO @ID, @IDAFILIADO
      END
      CLOSE PG_CURSOR
      DEALLOCATE PG_CURSOR

    --OTROS URGENCIAS
      SELECT @ID=0,@IDAFILIADOANT=''
      DECLARE PG_CURSOR CURSOR FOR 
      SELECT ID,IDAFILIADO FROM @URGENCIAS
      ORDER BY IDAFILIADO ASC
      OPEN PG_CURSOR    
      FETCH NEXT FROM PG_CURSOR    
      INTO @ID, @IDAFILIADO
      WHILE @@FETCH_STATUS = 0    
      BEGIN 
         IF @IDAFILIADOANT<>@IDAFILIADO
         BEGIN
            SELECT @CNSX=1,@IDAFILIADOANT=@IDAFILIADO
         END
         ELSE
         BEGIN
            SELECT @CNSX = @CNSX+1
         END
         UPDATE @URGENCIAS SET xconsecutivo=@CNSX WHERE ID=@ID
         FETCH NEXT FROM PG_CURSOR    
         INTO @ID, @IDAFILIADO
      END
      CLOSE PG_CURSOR
      DEALLOCATE PG_CURSOR

    --OTROS RECIEN NACIDOS
      SELECT @ID=0,@IDAFILIADOANT=''
      DECLARE PG_CURSOR CURSOR FOR 
      SELECT ID,IDAFILIADO FROM @RECIEN
      ORDER BY IDAFILIADO ASC
      OPEN PG_CURSOR    
      FETCH NEXT FROM PG_CURSOR    
      INTO @ID, @IDAFILIADO
      WHILE @@FETCH_STATUS = 0    
      BEGIN 
         IF @IDAFILIADOANT<>@IDAFILIADO
         BEGIN
            SELECT @CNSX=1,@IDAFILIADOANT=@IDAFILIADO
         END
         ELSE
         BEGIN
            SELECT @CNSX = @CNSX+1
         END
         UPDATE @RECIEN SET xconsecutivo=@CNSX WHERE ID=@ID
         FETCH NEXT FROM PG_CURSOR    
         INTO @ID, @IDAFILIADO
      END
      CLOSE PG_CURSOR
      DEALLOCATE PG_CURSOR
     IF EXISTS(SELECT * FROM @PROCEDIMIENTOS WHERE tipoDocumentoIdentificacion IS NULL)
     BEGIN
        UPDATE @PROCEDIMIENTOS SET tipoDocumentoIdentificacion=AFI.TIPO_DOC,numDocumentoIdentificacion=AFI.DOCIDAFILIADO
        FROM @PROCEDIMIENTOS AP INNER JOIN AFI ON AP.IDAFILIADO=AFI.IDAFILIADO
        WHERE AP.tipoDocumentoIdentificacion IS NULL
     END

	SET @json = (
	SELECT 
		rips = (
			SELECT 
				numDocumentoIdObligado = @numDocumentoIdObligado,
				numFactura = @N_FACTURA,
				tipoNota ='null',
				numNota = 'null',
				usuarios = (
					SELECT 
						tipoDocumentoIdentificacion = u.tipoDocumentoIdentificacion,
						numDocumentoIdentificacion = u.numDocumentoIdentificacion,
						tipoUsuario = u.tipoUsuario,
						fechaNacimiento = u.fechaNacimiento,
						codSexo = u.codSexo,
						codPaisResidencia = u.codPaisResidencia,
						codPaisOrigen = u.codPaisOrigen,
						codMunicipioResidencia = u.codMunicipioResidencia,
						codZonaTerritorialResidencia = u.codZonaTerritorialResidencia,
						incapacidad = u.incapacidad,
						consecutivo = u.usuarioId,
						servicios = (
							SELECT 
								consultas = (
									SELECT 
										c.codPrestador,
										c.fechaInicioAtencion,
										c.numAutorizacion,
										c.codConsulta,
										c.modalidadGrupoServicioTecSal,
										c.grupoServicios,
										c.codServicio,
										c.finalidadTecnologiaSalud,
										c.causaMotivoAtencion,
										c.codDiagnosticoPrincipal,
										c.codDiagnosticoRelacionado1,
										c.codDiagnosticoRelacionado2,
										c.codDiagnosticoRelacionado3,
										c.tipoDiagnosticoPrincipal,
										c.tipoDocumentoIdentificacion,
										c.numDocumentoIdentificacion,
										c.vrServicio,
										c.conceptoRecaudo,
										c.valorPagoModerador,
										IIF(c.numFEVPagoModerador IS NULL,'null',c.numFEVPagoModerador)numFEVPagoModerador,
										consecutivo = xconsecutivo
									FROM @CONSULTAS c
									WHERE c.usuarioId = u.usuarioId
									FOR JSON PATH
								),
								procedimientos = (
									SELECT 
										p.codPrestador,
										p.fechaInicioAtencion,
										p.idMIPRES,
										p.numAutorizacion,
										p.codProcedimiento,
										p.viaIngresoServicioSalud,
										p.modalidadGrupoServicioTecSal,
										p.grupoServicios,
										p.codServicio,
										p.finalidadTecnologiaSalud,
										p.tipoDocumentoIdentificacion,
										p.numDocumentoIdentificacion,
										p.codDiagnosticoPrincipal,
										p.codDiagnosticoRelacionado,
										p.codComplicacion,
										p.vrServicio,
										p.conceptoRecaudo,
										p.valorPagoModerador,
										IIF(p.numFEVPagoModerador IS NULL,'null',p.numFEVPagoModerador)numFEVPagoModerador,
										consecutivo = xconsecutivo
									FROM @PROCEDIMIENTOS p
									WHERE p.usuarioId = u.usuarioId
									FOR JSON PATH
								),
								urgencias = (
									SELECT 
										ur.codPrestador,
										ur.fechaInicioAtencion,
										ur.causaMotivoAtencion,
										ur.codDiagnosticoPrincipalE,
										ur.codDiagnosticoRelacionadoE1,
										ur.codDiagnosticoRelacionadoE2,
										ur.codDiagnosticoRelacionadoE3,
										ur.condicionDestinoUsuarioEgreso,
										ur.codDiagnosticoCausaMuerte,
										ur.fechaEgreso,
										consecutivo = xconsecutivo
									FROM @URGENCIAS ur
									WHERE ur.usuarioId = u.usuarioId
									FOR JSON PATH
								),
								hospitalizacion = (
									SELECT 
										h.codPrestador,
										h.viaIngresoServicioSalud,
										h.numAutorizacion,
										h.causaMotivoAtencion,
										h.codDiagnosticoPrincipal,
										h.codDiagnosticoPrincipalE,
										h.codDiagnosticoRelacionadoE1,
										h.codDiagnosticoRelacionadoE2,
										h.codDiagnosticoRelacionadoE3,
										h.codComplicacion,
										h.condicionDestinoUsuarioEgreso,
										h.codDiagnosticoCausaMuerte,
										h.fechaEgreso,
										consecutivo = xconsecutivo
									FROM @HOSPITALIZACION h
									WHERE h.usuarioId = u.usuarioId
									FOR JSON PATH
								),
								recienNacidos = (
									SELECT 
										r.codPrestador,
										r.tipoDocumentoIdentificacion,
										r.numDocumentoIdentificacion,
										r.fechaNacimiento,
										r.edadGestacional,
										r.numConsultasCPrenatal,
										r.codSexoBiologico,
										r.peso,
										r.codDiagnosticoPrincipal,
										r.condicionDestinoUsuarioEgreso,
										r.codDiagnosticoCausaMuerte,
										r.fechaEgreso,
										consecutivo = xconsecutivo
									FROM @RECIEN r
									WHERE r.usuarioId = u.usuarioId
									FOR JSON PATH
								),
								medicamentos = (
									SELECT 
										m.codPrestador,
										m.idMIPRES,
										m.fechaDispensAdmon,
										m.codDiagnosticoPrincipal,
										m.codDiagnosticoRelacionado,
										m.tipoMedicamento,
										m.codTecnologiaSalud,
										m.nomTecnologiaSalud,
										m.concentracionMedicamento,
										m.unidadMedida,
										m.formaFarmaceutica,
										m.unidadMinDispensa,
										m.cantidadMedicamento,
										m.diasTratamiento,
										m.tipoDocumentoIdentificacion,
										m.numDocumentoIdentificacion,
										m.vrUnitMedicamento,
										m.vrServicio,
										m.conceptoRecaudo,
										m.valorPagoModerador,
										IIF(m.numFEVPagoModerador IS NULL,'null',m.numFEVPagoModerador)numFEVPagoModerador,
										consecutivo = xconsecutivo
									FROM @MEDICAMENTOS m
									WHERE m.usuarioId = u.usuarioId
									FOR JSON PATH
								),
								otrosServicios = (
									SELECT 
										os.codPrestador,
										os.numAutorizacion,
										os.idMIPRES,
										os.fechaSuministroTecnologia,
										os.tipoOS,
										os.codTecnologiaSalud,
										os.nomTecnologiaSalud,
										os.cantidadOS,
										os.tipoDocumentoIdentificacion,
										os.numDocumentoIdentificacion,
										os.vrUnitOS,
										os.vrServicio,
										os.conceptoRecaudo,
										os.valorPagoModerador,
										IIF(os.numFEVPagoModerador IS NULL,'null',os.numFEVPagoModerador)numFEVPagoModerador,
										consecutivo = xconsecutivo
									FROM @OTROSSER os
									WHERE os.usuarioId = u.usuarioId                        
									FOR JSON PATH
								)
							FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
						)
					FROM @USUARIOS u
					ORDER BY usuarioId ASC
					FOR JSON PATH
				)
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
		),
      xmlFevFile = '@XMLFEVFILE'
	FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	)

	SELECT @JSON = REPLACE(@JSON,'\"','"')
	SELECT @JSON = REPLACE(@JSON,'\\"','"')
	SELECT @JSON = REPLACE(@JSON,'"{','{')
	SELECT @JSON = REPLACE(@JSON,'}"','}')
	SELECT @JSON = REPLACE(@JSON,'"null"','null')
	SELECT @PLANO= @json

	--SELECT @PLANO = '{"rips": '+@PLANO+',"xmlFevFile": "@XMLFEVFILE"}'

	--DECLARE @CNSFCT VARCHAR(20) = (SELECT CNSFCT FROM FTR WHERE N_FACTURA=@N_FACTURA)
	DECLARE @BASE64 NVARCHAR(MAX)

	IF 1=1
	BEGIN
		select @base64 = cast('' as xml).value('xs:base64Binary(sql:column("binaryValue"))', 'varchar(max)')
		from (
		  select [binaryValue] = cast(dbo.FNK_AttachedDocument(@CNSFCT,'FV') as varbinary(max))
		) as conv;
		SELECT @PLANO=REPLACE(@PLANO,'@XMLFEVFILE',@base64)
	END
	ELSE
	BEGIN
		SELECT @BASE64 = XML_Base64
		FROM FDIANR
		WHERE CNSDOCUMENTO = @CNSFCT
		AND TIPO='FV'
		AND METODO='SendBillSync'
		AND COALESCE(XML_BASE64, '') <> ''
		ORDER BY ITEM DESC
		SELECT @PLANO=REPLACE(@PLANO,'@XMLFEVFILE',@base64)
	END

	IF COALESCE(@URL_PATH,'')<>''
	BEGIN
		SELECT @N_FACTURA=@N_FACTURA+'.json'
		EXEC SPK_GUARDAR_ARCHIVO @PLANO, @URL_PATH, @N_FACTURA
		SELECT @PLANO= @URL_PATH+IIF(RIGHT(@URL_PATH,1)='\','','\')+@N_FACTURA 
	END

   PRINT 'FINALIZO EN SPK_RIPS_JSON_FTR_MAS'
END