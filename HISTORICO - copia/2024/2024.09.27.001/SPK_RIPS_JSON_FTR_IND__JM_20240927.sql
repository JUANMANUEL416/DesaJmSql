CREATE OR ALTER PROCEDURE DBO.SPK_RIPS_JSON_FTR_IND
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
DECLARE @RECIEN  AS NVARCHAR(MAX)
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
DECLARE @CONSULTAS TABLE (
	codPrestador VARCHAR(20),
	fechaInicioAtencion VARCHAR(16),
	numAutorizacion VARCHAR(30),
	codConsulta VARCHAR(6),
	modalidadGrupoServicioTecSal VARCHAR(2),
	grupoServicios VARCHAR(2),
	codServicio VARCHAR(4),
	finalidadTecnologiaSalud VARCHAR(2),
	causaMotivoAtencion VARCHAR(2),
	codDiagnosticoPrincipal VARCHAR(20),
	codDiagnosticoRelacionado1 VARCHAR(20),
	codDiagnosticoRelacionado2 VARCHAR(20),
	codDiagnosticoRelacionado3 VARCHAR(20),
	tipoDiagnosticoPrincipal VARCHAR(3),
	vrServicio int,--- VARCHAR(20),
	tipoPagoModerador VARCHAR(2),
	valorPagoModerador VARCHAR(10),
	consecutivo  INT IDENTITY(1,1) 
)
DECLARE @codPrestador VARCHAR(20),
	@fechaInicioAtencion VARCHAR(16),
	@numAutorizacion VARCHAR(30),
	@codConsulta VARCHAR(6),
	@modalidadGrupoServicioTecSal VARCHAR(2),
	@grupoServicios VARCHAR(2),
	@codServicio VARCHAR(4),
	@finalidadTecnologiaSalud VARCHAR(2),
	@causaMotivoAtencion VARCHAR(2),
	@codDiagnosticoPrincipal VARCHAR(20),
	@codDiagnosticoRelacionado1 VARCHAR(20),
	@codDiagnosticoRelacionado2 VARCHAR(20),
	@codDiagnosticoRelacionado3 VARCHAR(20),
	@tipoDiagnosticoPrincipal VARCHAR(2),
	@vrServicio DECIMAL(14,2),-- VARCHAR(20),
	@tipoPagoModerador VARCHAR(2),
	@valorPagoModerador VARCHAR(10),
	@consecutivo  VARCHAR(4)  

DECLARE @MEDICAMENTOS TABLE (
	codPrestador VARCHAR(20),
	numAutorizadon VARCHAR(30),
	idMIPRES       VARCHAR(15),
	fechaDispensAdmon VARCHAR(16),
	codDiagnosticoPrincipal VARCHAR(20),
	codDiagnosticoRelacionado VARCHAR(20),
	tipoMedicamento VARCHAR(4),
	codTecnologiaSalud VARCHAR(20),--CODCUM
	nomTecnologiaSalud VARCHAR(30),
	concentracionMedicamento VARCHAR(4),
	unidadMedida int,
	formaFarmaceutica VARCHAR(8),
	unidadMinDispensa VARCHAR(4),
	cantidadMedicamento VARCHAR(20),
	diasTratamiento     VARCHAR(5),
	tipoDocumentoIdentificacion VARCHAR(2),
	numDocumentoIdentificacion VARCHAR(20),
	vrUnitMedicamento VARCHAR(15),
	vrServicio VARCHAR(15),
	tipoPagoModerador VARCHAR(2),
	valorPagoModerador VARCHAR(10),
	numFEVPagoModerador VARCHAR(20),
	consecutivo  INT IDENTITY(1,1) 
)
	DECLARE 
	@numAutorizadon VARCHAR(30),
	@idMIPRES       VARCHAR(15),
	@fechaDispensAdmon VARCHAR(16),
	@codDiagnosticoRelacionado VARCHAR(20),
	@tipoMedicamento VARCHAR(4),
	@codTecnologiaSalud VARCHAR(20),--CODCUM
	@nomTecnologiaSalud VARCHAR(30),
	@concentracionMedicamento VARCHAR(4),
	@unidadMedida int,
	@formaFarmaceutica VARCHAR(8),
	@unidadMinDispensa VARCHAR(4),
	@cantidadMedicamento VARCHAR(20),
	@diasTratamiento     VARCHAR(5),
	@tipoDocumentoIdentificacion VARCHAR(4),
	@numDocumentoIdentificacion VARCHAR(20),
	@vrUnitMedicamento VARCHAR(15),
	@numFEVPagoModerador VARCHAR(20)
	DECLARE @PROCEDIMIENTOS TABLE (
	codPrestador VARCHAR(12),
	fechaInicioAtencion VARCHAR(16),
	idMIPRES VARCHAR(15),
	numAutorizacion VARCHAR(30),
	codProcedimiento VARCHAR(6),
	vialngresoServicioSalud VARCHAR(2),
	modalidadGrupoServicioTecSal VARCHAR(2),
	grupoServicios VARCHAR(2),
	codServicio VARCHAR(4),
	finalidadTecnologiaSalud VARCHAR(2),
	tipoDocumentoIdentificacion VARCHAR(2),
	numDocumentoIdentificacion VARCHAR(20),
	codDiagnosticoPrincipal VARCHAR(20),
	codDiagnosticoRelacionado VARCHAR(20),
	codComplicacion VARCHAR(20),
	vrServicio int, --VARCHAR(20),
	tipoPagoModerador  VARCHAR(2),
	valorPagoModerador  VARCHAR(10),
	numFEVPagoModerador VARCHAR(20),
	consecutivo INT IDENTITY(1,1)
	)
	DECLARE 
	@codProcedimiento VARCHAR(6),
	@vialngresoServicioSalud VARCHAR(2),
	@codComplicacion VARCHAR(20)
	DECLARE @codDiagnosticoPrincipalE VARCHAR(20)
	DECLARE @codDiagnosticoRelacionadoE1 VARCHAR(20)
	DECLARE @codDiagnosticoRelacionadoE2 VARCHAR(20)
	DECLARE @codDiagnosticoRelacionadoE3 VARCHAR(20)
	DECLARE @condicionDestinoUsuarioEgreso VARCHAR(2)
	DECLARE @codDiagnosticoCausaMuerte VARCHAR(20)
	DECLARE @fechaEgreso VARCHAR(16)
	DECLARE @viaIngresoServicioSalud VARCHAR(2)
	DECLARE @OTROSSER TABLE (
		codPrestador VARCHAR(20),
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
		tipoPagoModerador VARCHAR(2),
		valorPagoModerador VARCHAR(20),
		numFEVPagoModerador VARCHAR(20),
		consecutivo  INT IDENTITY(1,1) 
	)
	DECLARE  @fechaSuministroTecnologia VARCHAR(16),
	@tipoOS VARCHAR(2),
	@cantidadOS INT,
	@vrUnitOS INT--VARCHAR(20)

BEGIN

   
	SELECT @PROCEDENCIA=PROCEDENCIA,@NOADMISION=NOREFERENCIA
		 ,@VALORCOPAGO=CASE WHEN COALESCE(CAPITADA,0)=0 THEN COALESCE(VALORCOPAGO,0) ELSE CASE WHEN COALESCE(COPAPROPIO,0)=1 THEN COALESCE(CP_VLR_COPAGOS,0) ELSE COALESCE(VALORCOPAGO,0) END END
		 ,@IDSEDE = IDSEDE
	FROM FTR WHERE N_FACTURA=@N_FACTURA

	IF NOT EXISTS(SELECT * FROM FTR WHERE N_FACTURA=@N_FACTURA AND NOREFERENCIA=@NOADMISION)
	BEGIN
		PRINT 'No encontre la Factura...me devuelvo'
		RETURN
	END

	SELECT @conceptoRecaudo = '05'
	IF @VALORCOPAGO>0
	BEGIN
		SELECT @conceptoRecaudo = '01'
	END

	SELECT @IDTERINSTA=DBO.FNK_VALORVARIABLE('IDTERCEROINSTALADO')
	IF EXISTS(SELECT * FROM FTR INNER JOIN AFI ON FTR.IDAFILIADO=AFI.IDAFILIADO WHERE FTR.N_FACTURA=@N_FACTURA)
	BEGIN
		SELECT @DOCIDAFILIADO=AFI.DOCIDAFILIADO,@TIPODOC=AFI.TIPO_DOC,
		@TIPOUSU= CASE   WHEN AFI.TIPOAFILIADO = 'C' THEN '01'
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
							WHEN AFI.TIPOAFILIADO = 'S/N' THEN '05' ELSE '05' END,
			@FNACIMIENTO=REPLACE(CONVERT(VARCHAR,AFI.FNACIMIENTO,102),'.','-'),
			@SEXO=UPPER(LEFT(AFI.SEXO,1)),@MUNICIPIO=AFI.CIUDAD,@ZONA=CASE WHEN AFI.ZONA='R' THEN '01'ELSE '02' END,
			@INCAPACIDAD='NO',@CNS=1
		FROM FTR INNER JOIN AFI ON FTR.IDAFILIADO=AFI.IDAFILIADO 
		WHERE FTR.N_FACTURA=@N_FACTURA
	END
	ELSE
	BEGIN
		IF @PROCEDENCIA='CI' OR @PROCEDENCIA='ONCO'
		BEGIN
			SELECT @DOCIDAFILIADO=AFI.DOCIDAFILIADO,@TIPODOC=AFI.TIPO_DOC,
			@TIPOUSU= CASE   WHEN AFI.TIPOAFILIADO = 'C' THEN '01'
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
								WHEN AFI.TIPOAFILIADO = 'S/N' THEN '05' ELSE '05' END,
				@FNACIMIENTO=REPLACE(CONVERT(VARCHAR,AFI.FNACIMIENTO,102),'.','-'),
				@SEXO=UPPER(LEFT(AFI.SEXO,1)),@MUNICIPIO=AFI.CIUDAD,@ZONA=CASE WHEN AFI.ZONA='R' THEN '01'ELSE '02' END,
				@INCAPACIDAD='NO',@CNS=1
			FROM CIT INNER JOIN AFI ON CIT.IDAFILIADO=AFI.IDAFILIADO 
			WHERE CIT.CONSECUTIVO=@NOADMISION
		END
		BEGIN
			IF @PROCEDENCIA='AUT'
			BEGIN
			SELECT @DOCIDAFILIADO=AFI.DOCIDAFILIADO,@TIPODOC=AFI.TIPO_DOC,
			@TIPOUSU= CASE   WHEN AFI.TIPOAFILIADO = 'C' THEN '01'
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
									WHEN AFI.TIPOAFILIADO = 'S/N' THEN '05' ELSE '05' END,
				@FNACIMIENTO=REPLACE(CONVERT(VARCHAR,AFI.FNACIMIENTO,102),'.','-'),
				@SEXO=UPPER(LEFT(AFI.SEXO,1)),@MUNICIPIO=AFI.CIUDAD,@ZONA=CASE WHEN AFI.ZONA='R' THEN '01'ELSE '02' END,
				@INCAPACIDAD='NO',@CNS=1
			FROM AUT INNER JOIN AFI ON AUT.IDAFILIADO=AFI.IDAFILIADO 
			WHERE AUT.NOAUT=@NOADMISION
			END
			ELSE
			BEGIN
			SELECT @DOCIDAFILIADO=AFI.DOCIDAFILIADO,@TIPODOC=AFI.TIPO_DOC,
			@TIPOUSU= CASE   WHEN AFI.TIPOAFILIADO = 'C' THEN '01'
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
									WHEN AFI.TIPOAFILIADO = 'S/N' THEN '05' ELSE '05' END,
				@FNACIMIENTO=REPLACE(CONVERT(VARCHAR,AFI.FNACIMIENTO,102),'.','-'),
				@SEXO=UPPER(LEFT(AFI.SEXO,1)),@MUNICIPIO=AFI.CIUDAD,@ZONA=CASE WHEN AFI.ZONA='R' THEN '01'ELSE '02' END,
				@INCAPACIDAD='NO',@CNS=1
			FROM HADM INNER JOIN AFI ON HADM.IDAFILIADO=AFI.IDAFILIADO 
			WHERE HADM.NOADMISION=@NOADMISION
			END
		END
	END

	--SELECT @CONSULTAS= DBO.FNK_RIPS_JSON_CONSULTAS(@NOADMISION,@N_FACTURA,@PROCEDENCIA,@TIPODOC,@DOCIDAFILIADO,@IDTERINSTA)
	--SELECT @MEDICA= DBO.FNK_RIPS_JSON_MEDICAMENTOS(@NOADMISION,@N_FACTURA,@PROCEDENCIA,@TIPODOC,@DOCIDAFILIADO,@IDTERINSTA)
	--SELECT @PROCEDI = DBO.FNK_RIPS_JSON_PROCEDIMIENTOS(@NOADMISION,@N_FACTURA,@PROCEDENCIA,@TIPODOC,@DOCIDAFILIADO,@IDTERINSTA)
	IF @PROCEDENCIA='SALUD'
	BEGIN
		-- SELECT @URGEN = DBO.FNK_RIPS_JSON_URGENCIAS(@NOADMISION,@N_FACTURA,@PROCEDENCIA,@TIPODOC,@DOCIDAFILIADO,@IDTERINSTA)
		-- SELECT @HOSPITA = DBO.FNK_RIPS_JSON_HOSPITALIZACION(@NOADMISION,@N_FACTURA,@PROCEDENCIA,@TIPODOC,@DOCIDAFILIADO,@IDTERINSTA)
		SELECT @RECIEN = DBO.FNK_RIPS_JSON_RECIENNACIDOS(@NOADMISION,@N_FACTURA,@PROCEDENCIA,@TIPODOC,@DOCIDAFILIADO,@IDTERINSTA)
	END
	--SELECT @OTROSER = DBO.FNK_RIPS_JSON_OTROSSERVICIOS(@NOADMISION,@N_FACTURA,@PROCEDENCIA,@TIPODOC,@DOCIDAFILIADO,@IDTERINSTA)

	SELECT @IDPRESTADOR=COALESCE(IDALTERNA2,'No tengo')
	FROM TER 
	WHERE IDTERCERO=@IDTERINSTA

	-- Si la IPS maneja multiples sedes el codigo de habilitación es por sede
	IF EXISTS(SELECT 1 FROM USVGS WHERE IDVARIABLE = 'FACTSEDE' AND DATO='SI')
	BEGIN
		SELECT @IDPRESTADOR = COALESCE(CODHABILITA, IDSGSSS) FROM SED WHERE IDSEDE=@IDSEDE
	END

	SELECT @PLANO='{'
	SET @PLANO += '"numDocumentoIdObligado":"'+LTRIM(RTRIM(COALESCE(@IDTERINSTA,'')))+'" ,'
	SET @PLANO += '"numFactura":"'+@N_FACTURA+'" ,'
	SET @PLANO += '"tipoNota": null,'
	SET @PLANO += '"numNota": null,'
	SET @PLANO += '"usuarios": [ '
	SET @PLANO += '{ '
	SET @PLANO += '  "tipoDocumentoIdentificacion":"'+@TIPODOC+'" ,'
	SET @PLANO += '  "numDocumentoIdentificacion":"'+@DOCIDAFILIADO+'" ,'
	SET @PLANO += '  "tipoUsuario":"'+@TIPOUSU+'" ,'
	SET @PLANO += ' "fechaNacimiento":"'+@FNACIMIENTO+'",'
	SET @PLANO += ' "codSexo": "'+@SEXO+'",'
	SET @PLANO += ' "codPaisOrigen":"170" ,'
	SET @PLANO += ' "codPaisResidencia":"170" ,'
	SET @PLANO += ' "codMunicipioResidencia": "'+@MUNICIPIO+'", '
	SET @PLANO += ' "codZonaTerritorialResidencia": "'+@ZONA+'",'
	SET @PLANO += ' "incapacidad":"'+@INCAPACIDAD+'",'
	SET @PLANO += ' "consecutivo": '+CAST(@CNS AS VARCHAR(5))+','
	SET @PLANO += ' "servicios": { '

	PRINT '@PROCEDENCIA: ' + @PROCEDENCIA
	IF @PROCEDENCIA='CI'
	BEGIN
		-- SELECT DISTINCT FINCONSULTA FROM CIT
		INSERT INTO @CONSULTAS(codPrestador,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
								finalidadTecnologiaSalud,causaMotivoAtencion,vrServicio,valorPagoModerador)
		SELECT @IDPRESTADOR,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,CIT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,CIT.FECHA,108),5),
		numAutorizacion=COALESCE(CIT.NOAUTORIZACION,'null'),codConsulta=SER.CODCUPS,modalidadGrupoServicioTecSal='01',grupoServicios='01',
		codServicio='325',finalidadTecnologiaSalud=LEFT(CASE WHEN CIT.FINCONSULTA IS NULL OR CIT.FINCONSULTA=''  OR CIT.FINCONSULTA='10' THEN '44' ELSE CIT.FINCONSULTA END,2),
		causaMotivoAtencion='38',COALESCE(CIT.VALORTOTAL,0),COALESCE(CIT.VALORCOPAGO,0)
		FROM CIT INNER JOIN SER ON CIT.IDSERVICIO=SER.IDSERVICIO
				INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
		WHERE CONSECUTIVO=@NOADMISION
		AND N_FACTURA=@N_FACTURA
		AND RIPS_CP.ARCHIVO='AC'

		IF EXISTS(SELECT 1 FROM @CONSULTAS)
		BEGIN
			UPDATE @CONSULTAS SET codDiagnosticoPrincipal=HCA.IDDX
         ,codDiagnosticoRelacionado1=HCA.DX1
         ,codDiagnosticoRelacionado2=HCA.DX2
         ,codDiagnosticoRelacionado3=HCA.DX3
			-- https://web.sispro.gov.co/WebPublico/Consultas/ConsultarDetalleReferenciaBasica.aspx?Code=RIPSTipoDiagnosticoPrincipalVersion2
         ,tipoDiagnosticoPrincipal= CASE TIPODX 
							WHEN 'Presuntivo'   THEN '01'
							WHEN 'Impresion dx' THEN '01'
							WHEN 'Definitivo'   THEN '01'
							WHEN 'Conf Nuevo'   THEN '02'
							WHEN 'Conf Repet'   THEN '03'
							ELSE '01'
							END
			FROM CIT LEFT JOIN HCA ON CIT.IDAFILIADO=HCA.IDAFILIADO 
									AND  CONVERT(DATE,CIT.FECHA)=CONVERT(DATE,HCA.FECHA)
									AND HCA.PROCEDENCIA='IPS'
			WHERE CIT.CONSECUTIVO=@NOADMISION
			AND N_FACTURA=@N_FACTURA             
		END
	END
	ELSE
	BEGIN 
		IF @PROCEDENCIA='CE'
		BEGIN
			INSERT INTO @CONSULTAS(codPrestador,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
								finalidadTecnologiaSalud,causaMotivoAtencion,vrServicio,valorPagoModerador)
			SELECT @IDPRESTADOR,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,AUT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,AUT.FECHA,108),5),
			numAutorizacion=AUT.NUMAUTORIZA,codConsulta=SER.CODCUPS,modalidadGrupoServicioTecSal='01',grupoServicios='01',
			codServicio='325',finalidadTecnologiaSalud=LEFT(CASE WHEN AUT.FINALIDAD IS NULL OR AUT.FINALIDAD='' THEN '44' ELSE AUT.FINALIDAD END,2),
			causaMotivoAtencion='38',COALESCE(AUTD.VALOR,0),COALESCE(AUTD.VALORCOPAGO,0)
			FROM AUT INNER JOIN AUTD ON AUT.IDAUT=AUTD.IDAUT
					INNER JOIN SER ON AUTD.IDSERVICIO=SER.IDSERVICIO
					INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
			WHERE AUT.NOAUT=@NOADMISION
			AND AUTD.N_FACTURA=@N_FACTURA
			AND RIPS_CP.ARCHIVO='AC'

			IF EXISTS(SELECT  * FROM @CONSULTAS)
			BEGIN
				UPDATE @CONSULTAS SET codDiagnosticoPrincipal=AUT.DXPPAL
               ,codDiagnosticoRelacionado1=AUT.DXRELACIONADO
               ,codDiagnosticoRelacionado2=AUT.DXRELACIONADO2
               ,tipoDiagnosticoPrincipal='01'
				FROM AUT
				WHERE AUT.NOAUT=@NOADMISION
				AND N_FACTURA=@N_FACTURA  
			END
		END
		ELSE 
		BEGIN
			INSERT INTO @CONSULTAS(codPrestador,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
								finalidadTecnologiaSalud,causaMotivoAtencion,codDiagnosticoPrincipal,codDiagnosticoRelacionado1,codDiagnosticoRelacionado2,
								codDiagnosticoRelacionado3,tipoDiagnosticoPrincipal,vrServicio,valorPagoModerador)
			SELECT COALESCE(@IDPRESTADOR,''),fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5),
			numAutorizacion=HADM.NOAUTORIZACION,codConsulta=SER.CODCUPS,modalidadGrupoServicioTecSal='01',grupoServicios='01',
			codServicio='325',finalidadTecnologiaSalud=LEFT(CASE WHEN HPRE.FINALIDAD IS NULL OR HPRE.FINALIDAD='' OR HPRE.FINALIDAD='10'THEN '44' ELSE HPRE.FINALIDAD END,2),
			causaMotivoAtencion='38',COALESCE(HCA.IDDX,HADM.DXINGRESO,HADM.DXEGRESO),COALESCE(HCA.DX1,HADM.DXSALIDA1),COALESCE(HCA.DX2,HADM.DXSALIDA2),COALESCE(HCA.DX3,HADM.DXSALIDA3),
			CASE HCA.TIPODX 
							WHEN 'Presuntivo'   THEN 1
							WHEN 'Impresion dx' THEN 1
							WHEN 'Definitivo'   THEN 2
							WHEN 'Conf Nuevo'   THEN 2
							WHEN 'Conf Repet'   THEN 3
							ELSE 1
							END,COALESCE(HPRED.VALOR,0),COALESCE(HPRED.VALORCOPAGO,0)
			FROM HADM INNER JOIN  HPRE ON HADM.NOADMISION=HPRE.NOADMISION
					INNER JOIN HPRED ON HPRE.NOPRESTACION=HPRED.NOPRESTACION
					INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO
					LEFT JOIN (SELECT TOP 1 HCA.NOADMISION,HCA.TIPODX,HCA.IDDX,COALESCE(HCA.DX1,'')DX1,COALESCE(HCA.DX2,'')DX2,COALESCE(DX3,'')DX3 
                           FROM HCA WHERE NOADMISION=@NOADMISION AND COALESCE(IDDX,'')<>'' 
                           AND HCA.CLASE='HC'
                           ORDER BY HCA.FECHA DESC 
                           ) HCA ON HADM.NOADMISION=HCA.NOADMISION
					INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
			WHERE HADM.NOADMISION=@NOADMISION
			AND HPRED.N_FACTURA=@N_FACTURA
         AND COALESCE(HPRED.VALOR,0)>0
			AND RIPS_CP.ARCHIVO='AC' 
		END
	END
	
	SELECT @CANT=COUNT(*) FROM @CONSULTAS
	IF @CANT>0 -- AND 1=0
	BEGIN
		
		SET @PLANO += '"consultas":['
		
		SET @NRO=1
		WHILE @NRO<=@CANT
		BEGIN
			SELECT 
			@codPrestador =	codPrestador
			,@fechaInicioAtencion =	fechaInicioAtencion
			,@numAutorizacion =	numAutorizacion
			,@codConsulta =	codConsulta
			,@modalidadGrupoServicioTecSal =	modalidadGrupoServicioTecSal
			,@grupoServicios =	grupoServicios
			,@codServicio =	codServicio
			,@finalidadTecnologiaSalud =	finalidadTecnologiaSalud
			,@causaMotivoAtencion =	causaMotivoAtencion
			,@codDiagnosticoPrincipal =	 CASE WHEN LEN(COALESCE(codDiagnosticoPrincipal,''))<4 THEN 'null' ELSE codDiagnosticoPrincipal END
			,@codDiagnosticoRelacionado1 = CASE WHEN LEN(COALESCE(codDiagnosticoRelacionado1,''))<4 THEN 'null' ELSE codDiagnosticoRelacionado1 END
			,@codDiagnosticoRelacionado2 = CASE WHEN LEN(COALESCE(codDiagnosticoRelacionado2,''))<4 THEN 'null' ELSE codDiagnosticoRelacionado2 END
			,@codDiagnosticoRelacionado3 = CASE WHEN LEN(COALESCE(codDiagnosticoRelacionado3,''))<4 THEN 'null' ELSE codDiagnosticoRelacionado3 END
			,@tipoDiagnosticoPrincipal = CASE WHEN LEN(tipoDiagnosticoPrincipal)<2 THEN '01' ELSE	COALESCE(tipoDiagnosticoPrincipal,'01') END
			,@vrServicio =	vrServicio
			,@tipoPagoModerador =	'01'--tipoPagoModerador
			,@valorPagoModerador =	valorPagoModerador
			,@consecutivo =	CAST(consecutivo AS VARCHAR(4))
			FROM @CONSULTAS
			WHERE consecutivo=@NRO
			SET @PLANO+='{'
			SET @PLANO+='"codPrestador": "'+@codPrestador+'",'
			SET @PLANO+='"fechaInicioAtencion": "'+@fechaInicioAtencion+'",'
			SET @PLANO+='"numAutorizacion": "'+@numAutorizacion+'",'
			SET @PLANO+='"codConsulta": "'+@codConsulta+'",'
			SET @PLANO+='"modalidadGrupoServicioTecSal": "'+@modalidadGrupoServicioTecSal+'",'
			SET @PLANO+='"grupoServicios": "'+@grupoServicios+'",'
			SET @PLANO+='"codServicio": "'+@codServicio+'",'
			SET @PLANO+='"finalidadTecnologiaSalud": "'+@finalidadTecnologiaSalud+'",'
			SET @PLANO+='"causaMotivoAtencion": "'+@causaMotivoAtencion+'",'
         IF COALESCE(@codDiagnosticoPrincipal, '')<>''
			   SET @PLANO+='"codDiagnosticoPrincipal": "'+@codDiagnosticoPrincipal+'",'
         IF COALESCE(@codDiagnosticoRelacionado1, '')<>''
			   SET @PLANO+='"codDiagnosticoRelacionado1": "'+@codDiagnosticoRelacionado1+'",'
         IF COALESCE(@codDiagnosticoRelacionado2, '')<>''
			   SET @PLANO+='"codDiagnosticoRelacionado2": "'+@codDiagnosticoRelacionado2+'",'
         IF COALESCE(@codDiagnosticoRelacionado3, '')<>''
			   SET @PLANO+='"codDiagnosticoRelacionado3": "'+@codDiagnosticoRelacionado3+'",'
			SET @PLANO+='"tipoDiagnosticoPrincipal": "'+@tipoDiagnosticoPrincipal+'",'
			SET @PLANO+='"tipoDocumentoIdentificacion": "'+@TIPODOC+'",'
			SET @PLANO+='"numDocumentoIdentificacion": "'+@DOCIDAFILIADO+'",'
			SET @PLANO+='"vrServicio": '+CAST(@vrServicio AS VARCHAR)+','
			SET @PLANO+='"tipoPagoModerador": "'+@tipoPagoModerador+'",'
			SET @PLANO+='"valorPagoModerador":"'+@valorPagoModerador+'",'
			SET @PLANO+='"numFEVPagoModerador": "'+@N_FACTURA+'",'
			SET @PLANO+='"consecutivo": "'+@consecutivo+'",'
			SET @PLANO+= '"conceptoRecaudo":"'+@conceptoRecaudo+'"'
			SET @PLANO+='},'
			SELECT @NRO+=1
		END
		
		SET @PLANO  += ']'

	END
	IF @PROCEDENCIA='CE'
	BEGIN
		INSERT INTO @MEDICAMENTOS(codPrestador,numAutorizadon,idMIPRES,fechaDispensAdmon,codDiagnosticoPrincipal,codDiagnosticoRelacionado
									,tipoMedicamento,codTecnologiaSalud,nomTecnologiaSalud,concentracionMedicamento,unidadMedida,formaFarmaceutica
									,unidadMinDispensa,cantidadMedicamento,diasTratamiento,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitMedicamento
									,vrServicio,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador)

		SELECT @IDPRESTADOR,numAutorizacion=AUT.NUMAUTORIZA,null,fechaDispensAdmon=REPLACE(CONVERT(VARCHAR,AUT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,AUT.FECHA,108),5),
			AUT.DXPPAL,AUT.DXRELACIONADO,'01',COALESCE(IART.CODCUM,SER.CODCUM),LEFT( dbo.FNK_LIMPIATEXTO(IART.DESCRIPCION,'0-9 A-Z();:.,'),30),'0',
			COALESCE(IUNI.HOMOLOGO_RIPS,247),COALESCE(IFFA.HOMOJSON,'null'),'11',CONVERT(VARCHAR,CONVERT(INT,AUTD.CANTIDAD),10),CAST(AUTD.DIAS AS VARCHAR(3)),@TIPODOC,@DOCIDAFILIADO,AUTD.VALOR,AUTD.VALOR*AUTD.CANTIDAD,
			'01',AUTD.VALORCOPAGO,@N_FACTURA
		FROM AUT INNER JOIN AUTD ON AUT.IDAUT=AUTD.IDAUT
				INNER JOIN SER ON AUTD.IDSERVICIO=SER.IDSERVICIO
				LEFT  JOIN IART ON SER.IDSERVICIO=IART.IDSERVICIO
            LEFT  JOIN IFFA  ON IART.IDFORFARM=IFFA.IDFORFARM
				INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
            LEFT JOIN IUNI ON IUNI.IDUNIDAD=IART.IDUNIDAD
		WHERE AUT.NOAUT=@NOADMISION
		AND AUTD.N_FACTURA=@N_FACTURA
		AND RIPS_CP.ARCHIVO='AM'
	END
	ELSE 
	BEGIN
		INSERT INTO @MEDICAMENTOS(codPrestador,numAutorizadon,idMIPRES,fechaDispensAdmon,codDiagnosticoPrincipal,codDiagnosticoRelacionado
									,tipoMedicamento,codTecnologiaSalud,nomTecnologiaSalud,concentracionMedicamento,unidadMedida,formaFarmaceutica
									,unidadMinDispensa,cantidadMedicamento,diasTratamiento,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitMedicamento
									,vrServicio,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador)

		SELECT @IDPRESTADOR,numAutorizacion=HADM.NOAUTORIZACION,null,fechaDispensAdmon=REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5),
			COALESCE(HCA.IDDX,HADM.DXINGRESO),COALESCE(HCA.DX1,HADM.DXSALIDA1),'01',CASE WHEN COALESCE(SER.MEDICAMENTOS,0)=1 THEN COALESCE(IART.CODCUM,SER.CODCUM) ELSE SER.IDSERVICIO END,LEFT(dbo.FNK_LIMPIATEXTO(IART.DESCRIPCION,'0-9 A-Z();:.,'),30),'0',
			COALESCE(IUNI.HOMOLOGO_RIPS,247),COALESCE(IFFA.HOMOJSON,'null'),'11',CONVERT(VARCHAR,CONVERT(INT,HPRED.CANTIDAD),10),1,@TIPODOC,@DOCIDAFILIADO,CONVERT(VARCHAR,CONVERT(DECIMAL(14,2),HPRED.VALOR),20),
			CONVERT(VARCHAR,CONVERT(DECIMAL(14,2),HPRED.VALOR*HPRED.CANTIDAD),20),'01',CONVERT(VARCHAR,CONVERT(DECIMAL(14,2),HPRED.VALORCOPAGO),20),@N_FACTURA
		FROM HADM INNER JOIN  HPRE ON HADM.NOADMISION=HPRE.NOADMISION
					INNER JOIN HPRED ON HPRE.NOPRESTACION=HPRED.NOPRESTACION
					INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO
					LEFT JOIN IART ON COALESCE(HPRED.IDARTICULO,SER.IDARTICULO)=IART.IDARTICULO
               LEFT JOIN IFFA ON IART.IDFORFARM=IFFA.IDFORFARM
					LEFT JOIN (SELECT TOP 1 HCA.NOADMISION,HCA.TIPODX,HCA.IDDX,COALESCE(HCA.DX1,'')DX1,COALESCE(HCA.DX2,'')DX2,COALESCE(DX3,'')DX3 
                           FROM HCA WHERE NOADMISION=@NOADMISION AND COALESCE(IDDX,'')<>'' 
                           AND HCA.CLASE='HC'
                           ORDER BY HCA.FECHA DESC 
                           ) HCA ON HADM.NOADMISION=HCA.NOADMISION
					INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
               LEFT JOIN IUNI ON IUNI.IDUNIDAD = IART.IDUNIDAD
		WHERE HADM.NOADMISION=@NOADMISION
		AND HPRED.N_FACTURA=@N_FACTURA
      AND COALESCE(HPRED.VALOR,0)>0
		AND RIPS_CP.ARCHIVO='AM' 
	END

	SELECT @CANT=COUNT(*) FROM @MEDICAMENTOS
	IF @CANT>0  -- AND 1=0
	BEGIN
		
		SET @PLANO += ',"medicamentos":['
		
		SET @NRO=1
		WHILE @NRO<=@CANT
		BEGIN
			SELECT @codPrestador=codPrestador
            ,@numAutorizadon=numAutorizadon
            ,@idMIPRES=idMIPRES
            ,@fechaDispensAdmon=fechaDispensAdmon
            ,@codDiagnosticoPrincipal=codDiagnosticoPrincipal
            ,@codDiagnosticoRelacionado=codDiagnosticoRelacionado
            ,@tipoMedicamento=tipoMedicamento
            ,@codTecnologiaSalud=codTecnologiaSalud
            ,@nomTecnologiaSalud=nomTecnologiaSalud
            ,@concentracionMedicamento=concentracionMedicamento
            ,@unidadMedida=unidadMedida
            ,@formaFarmaceutica=formaFarmaceutica
            ,@unidadMinDispensa=unidadMinDispensa
            ,@cantidadMedicamento=cantidadMedicamento
            ,@diasTratamiento=diasTratamiento
            ,@tipoDocumentoIdentificacion=tipoDocumentoIdentificacion
            ,@numDocumentoIdentificacion=numDocumentoIdentificacion
            ,@vrUnitMedicamento=vrUnitMedicamento
            ,@vrServicio=vrServicio
            ,@tipoPagoModerador=tipoPagoModerador
            ,@valorPagoModerador=valorPagoModerador
            ,@numFEVPagoModerador=numFEVPagoModerador
            ,@consecutivo=CAST(consecutivo AS VARCHAR(5))
			FROM @MEDICAMENTOS
			WHERE consecutivo=@NRO

         IF @unidadMedida IS NULL
         BEGIN
            RAISERROR ('La Unidad de Medida de los Medicamentos no puede ser null (IUNI.HOMOLOGO_RIPS)', 16, 1); 
            return
         END

			SET @PLANO+='{'
			SET @PLANO+= '"codPrestador":"'+@codPrestador+'",'
			SET @PLANO+= '"numAutorizadon":"'+COALESCE(@numAutorizadon,'')+'",'
			SET @PLANO+= '"idMIPRES":'+IIF(@idMIPRES IS NULL, 'null',CONCAT('"',@idMIPRES,'"'))+','
			SET @PLANO+= '"fechaDispensAdmon":"'+@fechaDispensAdmon+'",'
         IF COALESCE(@codDiagnosticoPrincipal, '') <> ''
			   SET @PLANO+= '"codDiagnosticoPrincipal":"'+@codDiagnosticoPrincipal+'",'
         IF COALESCE(@codDiagnosticoRelacionado, '') <> ''
			   SET @PLANO+= '"codDiagnosticoRelacionado":"'+@codDiagnosticoRelacionado+'",'
			SET @PLANO+= '"tipoMedicamento":"'+COALESCE(@tipoMedicamento,'')+'",'
			SET @PLANO+= '"codTecnologiaSalud":"'+COALESCE(@codTecnologiaSalud,'')+'",'
			SET @PLANO+= '"nomTecnologiaSalud":"'+COALESCE(@nomTecnologiaSalud,'')+'",'
			SET @PLANO+= '"concentracionMedicamento":"'+COALESCE(@concentracionMedicamento,'')+'",'
			SET @PLANO+= '"unidadMedida":'+COALESCE(CAST(@unidadMedida AS VARCHAR),'null')+','
			SET @PLANO+= '"formaFarmaceutica":"'+COALESCE(@formaFarmaceutica,'')+'",'
			SET @PLANO+= '"unidadMinDispensa":"'+COALESCE(@unidadMinDispensa,'')+'",'
			SET @PLANO+= '"cantidadMedicamento":"'+COALESCE(@cantidadMedicamento,'')+'",'
			SET @PLANO+= '"diasTratamiento":"'+@diasTratamiento+'",'
			SET @PLANO+= '"tipoDocumentoIdentificacion":"'+@tipoDocumentoIdentificacion+'",'
			SET @PLANO+= '"numDocumentoIdentificacion":"'+@numDocumentoIdentificacion+'",'
			SET @PLANO+= '"vrUnitMedicamento":"'+@vrUnitMedicamento+'",'
			SET @PLANO+= '"vrServicio":"'+CONVERT(VARCHAR,@vrServicio)+'",'
			SET @PLANO+= '"tipoPagoModerador":"'+@tipoPagoModerador+'",'
			SET @PLANO+= '"valorPagoModerador":"'+@valorPagoModerador+'",'
			SET @PLANO+= '"numFEVPagoModerador":"'+@numFEVPagoModerador+'",'
			SET @PLANO+= '"consecutivo":"'+@consecutivo+'",'
			SET @PLANO+= '"conceptoRecaudo":"'+@conceptoRecaudo+'"'
			SET @PLANO+='},'
			SELECT @NRO+=1
		END
		
		SET @PLANO  += ']'
	END
	IF @PROCEDENCIA='CI'
	BEGIN
		INSERT INTO @PROCEDIMIENTOS (codPrestador,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,vialngresoServicioSalud
					,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
					,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador
					)
		SELECT @IDPRESTADOR,REPLACE(CONVERT(VARCHAR,CIT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,CIT.FECHA,108),5),null,
				COALESCE(CIT.NOAUTORIZACION,'null'),SER.CODCUPS,'02','01','02','325','16',@TIPODOC,@DOCIDAFILIADO,CIT.IDDX,
				CIT.IDDX,COALESCE(CIT.IDDX,'null'),COALESCE(CIT.VALORTOTAL,0),'01',COALESCE(CIT.VALORCOPAGO,0),@N_FACTURA
		FROM CIT INNER JOIN SER ON CIT.IDSERVICIO=SER.IDSERVICIO
				INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
		WHERE CONSECUTIVO=@NOADMISION
		AND N_FACTURA=@N_FACTURA
		AND RIPS_CP.ARCHIVO='AP'

		IF EXISTS(SELECT  * FROM @PROCEDIMIENTOS)
		BEGIN
			UPDATE @PROCEDIMIENTOS SET codDiagnosticoPrincipal=HCA.IDDX,codDiagnosticoRelacionado=HCA.DX1
			FROM CIT LEFT JOIN HCA ON CIT.IDAFILIADO=HCA.IDAFILIADO 
									AND  CONVERT(DATE,CIT.FECHA)=CONVERT(DATE,HCA.FECHA)
									AND HCA.PROCEDENCIA='IPS'
			WHERE CIT.CONSECUTIVO=@NOADMISION
			AND N_FACTURA=@N_FACTURA 
         AND CIT.IDDX IS NULL
		END
	END
	ELSE
	BEGIN
		IF @PROCEDENCIA='CE'
		BEGIN
			INSERT INTO @PROCEDIMIENTOS (
				codPrestador
				,fechaInicioAtencion
				,idMIPRES
				,numAutorizacion
				,codProcedimiento
				,vialngresoServicioSalud
				,modalidadGrupoServicioTecSal
				,grupoServicios
				,codServicio
				,finalidadTecnologiaSalud
				,tipoDocumentoIdentificacion
				,numDocumentoIdentificacion
				,codDiagnosticoPrincipal
				,codDiagnosticoRelacionado
				,codComplicacion
				,vrServicio
				,tipoPagoModerador
				,valorPagoModerador
				,numFEVPagoModerador
				)
			SELECT @IDPRESTADOR
				,REPLACE(CONVERT(VARCHAR, AUT.FECHA, 102), '.', '-') + ' ' + LEFT(CONVERT(VARCHAR, AUT.FECHA, 108), 5)
				,NULL
				,AUT.NUMAUTORIZA
				,SER.CODCUPS
				,'02'
				,'01'
				,'02'
				,'325'
				,'16'
				,@TIPODOC
				,@DOCIDAFILIADO
				,AUT.DXPPAL
				,AUT.DXRELACIONADO
				,AUT.DXPPAL
				,COALESCE(AUTD.VALOR, 0)
				,'01'
				,COALESCE(AUTD.VALORCOPAGO, 0)
				,@N_FACTURA
			FROM AUT
			INNER JOIN AUTD ON AUT.IDAUT = AUTD.IDAUT
			INNER JOIN SER ON AUTD.IDSERVICIO = SER.IDSERVICIO
			INNER JOIN RIPS_CP ON SER.CODIGORIPS = RIPS_CP.IDCONCEPTORIPS
			WHERE NOAUT = @NOADMISION
				AND AUTD.N_FACTURA = @N_FACTURA
				AND RIPS_CP.ARCHIVO = 'AP'
		END
		ELSE
		BEGIN
			INSERT INTO @PROCEDIMIENTOS (codPrestador,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,vialngresoServicioSalud
						,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
						,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador
						)
			SELECT @IDPRESTADOR,REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5),null,
				HADM.NOAUTORIZACION,SER.CODCUPS,'02','01','02','325','16',@TIPODOC,@DOCIDAFILIADO,COALESCE(HCA.IDDX,HADM.DXINGRESO,HADM.DXEGRESO),
				COALESCE(HCA.DX1,HADM.DXSALIDA1),COALESCE(HADM.COMPLICACION,HCA.IDDX,HADM.DXINGRESO,HADM.DXEGRESO),COALESCE(HPRED.VALOR,0),'01',COALESCE(HPRED.VALORCOPAGO,0),@N_FACTURA
			FROM HADM INNER JOIN HPRE ON HADM.NOADMISION=HPRE.NOADMISION
					INNER JOIN HPRED ON HPRE.NOPRESTACION=HPRED.NOPRESTACION
					LEFT JOIN (SELECT TOP 1 HCA.NOADMISION,HCA.TIPODX,HCA.IDDX,COALESCE(HCA.DX1,'')DX1,COALESCE(HCA.DX2,'')DX2,COALESCE(DX3,'')DX3 
                           FROM HCA WHERE NOADMISION=@NOADMISION AND COALESCE(IDDX,'')<>'' 
                           AND HCA.CLASE='HC'
                           ORDER BY HCA.FECHA DESC 
                           ) HCA ON HADM.NOADMISION=HCA.NOADMISION
					INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO
					INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
			WHERE HADM.NOADMISION=@NOADMISION
			AND HPRED.N_FACTURA=@N_FACTURA
         AND COALESCE(HPRED.VALOR,0)>0
			AND RIPS_CP.ARCHIVO='AP' 
		END
	END

	SELECT @CANT=COUNT(*) FROM @PROCEDIMIENTOS
	IF @CANT>0  ---- AND 1=0
	BEGIN
		
		SET @PLANO += ',"procedimientos":['
		
		SET @NRO=1
		WHILE @NRO<=@CANT
		BEGIN
			SELECT @codPrestador =	codPrestador,
				@fechaInicioAtencion =	fechaInicioAtencion,
				@idMIPRES =	idMIPRES,
				@numAutorizacion =	numAutorizacion,
				@codProcedimiento = codProcedimiento,
				@vialngresoServicioSalud =	vialngresoServicioSalud,
				@modalidadGrupoServicioTecSal =	modalidadGrupoServicioTecSal,
				@grupoServicios =	grupoServicios,
				@codServicio =	codServicio,
				@finalidadTecnologiaSalud =	finalidadTecnologiaSalud,
				@tipoDocumentoIdentificacion =	tipoDocumentoIdentificacion,
				@numDocumentoIdentificacion =	numDocumentoIdentificacion,
				@codDiagnosticoPrincipal =	codDiagnosticoPrincipal,
				@codDiagnosticoRelacionado =	codDiagnosticoRelacionado,
				@codComplicacion =	codComplicacion,
				@vrServicio =	vrServicio,
				@tipoPagoModerador	=tipoPagoModerador,
				@valorPagoModerador = 	valorPagoModerador,
				@numFEVPagoModerador =	numFEVPagoModerador,
				@consecutivo =	CAST(consecutivo AS VARCHAR(4))
			FROM @PROCEDIMIENTOS
			WHERE consecutivo=@NRO
			
			IF @NRO > 1 SET @PLANO+=','

			SET @PLANO+='{'
			SET @PLANO+=' "codPrestador":"'+@codPrestador+'",'
			SET @PLANO+=' "fechaInicioAtencion":"'+@fechaInicioAtencion+'",'
			SET @PLANO+=' "idMIPRES":'+IIF(@idMIPRES IS NULL, 'null',CONCAT('"',@idMIPRES,'"'))+','
			SET @PLANO+=' "numAutorizacion":"'+@numAutorizacion+'",'
			SET @PLANO+=' "codProcedimiento":"'+@codProcedimiento+'",'
			SET @PLANO+=' "viaIngresoServicioSalud":"'+@vialngresoServicioSalud+'",'
			SET @PLANO+=' "modalidadGrupoServicioTecSal":"'+@modalidadGrupoServicioTecSal+'",'
			SET @PLANO+=' "grupoServicios":"'+@grupoServicios+'",'
			SET @PLANO+=' "codServicio":"'+@codServicio+'",'
			SET @PLANO+=' "finalidadTecnologiaSalud":"'+@finalidadTecnologiaSalud+'",'
			SET @PLANO+=' "tipoDocumentoIdentificacion":"'+@tipoDocumentoIdentificacion+'",'
			SET @PLANO+=' "numDocumentoIdentificacion":"'+@numDocumentoIdentificacion+'",'
         IF COALESCE(@codDiagnosticoPrincipal, '')<>''
			   SET @PLANO+=' "codDiagnosticoPrincipal":"'+@codDiagnosticoPrincipal+'",'
         IF COALESCE(@codDiagnosticoRelacionado, '')<>''
			   SET @PLANO+=' "codDiagnosticoRelacionado":"'+@codDiagnosticoRelacionado+'",'
			SET @PLANO+=' "codComplicacion":"'+COALESCE(@codComplicacion,'')+'",'
			SET @PLANO+=' "vrServicio":"'+CAST(@vrServicio AS VARCHAR)+'",'
			SET @PLANO+=' "tipoPagoModerador":"'+@tipoPagoModerador+'",'
			SET @PLANO+=' "valorPagoModerador":"'+@valorPagoModerador+'",'
			SET @PLANO+=' "numFEVPagoModerador":"'+@numFEVPagoModerador+'",'
			SET @PLANO+=' "consecutivo":"'+@consecutivo+'",'
			SET @PLANO+= '"conceptoRecaudo":"'+@conceptoRecaudo+'"'
			SET @PLANO+=' }'
			SELECT @NRO+=1
		END
		
		SET @PLANO  += ']'
	END
	IF EXISTS(SELECT * FROM HADM WHERE NOADMISION=@NOADMISION AND DATEDIFF(HOUR,FECHA,FECHAALTAMED)<=48) AND @PROCEDENCIA='SALUD'
	BEGIN
	
		SET @PLANO += ',"urgencias":['

		SELECT @codPrestador=@IDPRESTADOR, @fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,HADM.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HADM.FECHA,108),5),
		@causaMotivoAtencion=CASE WHEN COALESCE(TGEN.CHECK1,0)=1 THEN DATO1 ELSE CODIGO END 
      ,@codDiagnosticoPrincipal=COALESCE(HCA.IDDX,HADM.DXINGRESO),
		@codDiagnosticoPrincipalE=COALESCE(HADM.DXEGRESO,HCA.DX1),
		@codDiagnosticoRelacionadoE1=COALESCE(HCA.DX1,HADM.DXSALIDA1)
      ,@codDiagnosticoRelacionadoE2=COALESCE(HCA.DX2,HADM.DXSALIDA2),
		@codDiagnosticoRelacionadoE3=COALESCE(HCA.DX3,HADM.DXSALIDA3),@condicionDestinoUsuarioEgreso=CASE WHEN HADM.ESTADOPSALIDA=1 THEN '01' ELSE '02' END,
		@codDiagnosticoCausaMuerte=CASE WHEN HADM.ESTADOPSALIDA=1 THEN null ELSE CAUSABMUERTE END,
		@fechaEgreso=REPLACE(CONVERT(VARCHAR,HADM.FECHAALTAMED,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HADM.FECHAALTAMED,108),5),
		@consecutivo=1
		FROM HADM LEFT JOIN HCA ON HADM.NOADMISION=HCA.NOADMISION
                LEFT JOIN TGEN ON HADM.CAUSAEXTERNA=TGEN.CODIGO AND TGEN.TABLA='General' AND TGEN.CAMPO='CAUSAEXTERNA'
		WHERE HADM.NOADMISION=@NOADMISION
		AND HCA.CLASE='HC'
		AND HCA.PROCEDENCIA='QX'
      AND HCA.CLASEPLANTILLA <> DBO.FNK_VALORVARIABLE('HCPLANTILLAEPI')

      PRINT '@NOADMISION = ' + COALESCE(@NOADMISION, '')


		SET @PLANO+='{'
		SET @PLANO+=' "codPrestador":"'+@codPrestador+'",'
		SET @PLANO+=' "fechaInicioAtencion":"'+@fechaInicioAtencion+'",'
		SET @PLANO+=' "causaMotivoAtencion":"'+@causaMotivoAtencion+'",'
		IF COALESCE(@codDiagnosticoPrincipal, '') <> ''
		   SET @PLANO+=' "codDiagnosticoPrincipal":"'+@codDiagnosticoPrincipal+'",'
		IF COALESCE(@codDiagnosticoPrincipalE, '') <> ''
		   SET @PLANO+=' "codDiagnosticoPrincipalE":"'+@codDiagnosticoPrincipalE+'",'
		IF COALESCE(@codDiagnosticoRelacionadoE1, '') <> ''
		   SET @PLANO+=' "codDiagnosticoRelacionadoE1":"'+@codDiagnosticoRelacionadoE1+'",'
		IF COALESCE(@codDiagnosticoRelacionadoE2, '') <> ''
		   SET @PLANO+=' "codDiagnosticoRelacionadoE2":"'+@codDiagnosticoRelacionadoE2+'",'
		IF COALESCE(@codDiagnosticoRelacionadoE3, '') <> ''
		   SET @PLANO+=' "codDiagnosticoRelacionadoE3":"'+@codDiagnosticoRelacionadoE3+'",'
		SET @PLANO+=' "condicionDestinoUsuarioEgreso":"'+@condicionDestinoUsuarioEgreso+'",'
		SET @PLANO+=' "codDiagnosticoCausaMuerte":"'+COALESCE(@codDiagnosticoCausaMuerte,'null')+'",'
		SET @PLANO+=' "fechaEgreso":"'+@fechaEgreso+'",'
		SET @PLANO+=' "consecutivo":"'+CAST(@consecutivo AS VARCHAR(4))+'",'
		SET @PLANO+= '"conceptoRecaudo":"'+@conceptoRecaudo+'"'
		SET @PLANO+='}'

		SET @PLANO  += ']'

	END
	IF EXISTS(SELECT * FROM HADM WHERE NOADMISION=@NOADMISION AND DATEDIFF(HOUR,FECHA,FECHAALTAMED)>48) AND @PROCEDENCIA='SALUD'
	BEGIN
		SET @PLANO += ',"hospitalizaciones":['

		SELECT @codPrestador=@IDPRESTADOR
			,@viaIngresoServicioSalud='01'
			,@fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,HADM.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HADM.FECHA,108),5)
			,@numAutorizacion=HADM.NOAUTORIZACION
			,@causaMotivoAtencion=HADM.CAUSAEXTERNA
			,@codDiagnosticoPrincipal=COALESCE(HCA.IDDX,HADM.DXINGRESO)
			,@codDiagnosticoPrincipalE=COALESCE(HADM.DXEGRESO,HCA.DX1)
			,@codDiagnosticoRelacionadoE1=COALESCE(HCA.DX1,HADM.DXSALIDA1)
			,@codDiagnosticoRelacionadoE2=COALESCE(HCA.DX2,HADM.DXSALIDA2)
			,@codDiagnosticoRelacionadoE3=COALESCE(HCA.DX3,HADM.DXSALIDA3)
			,@codComplicacion=HADM.COMPLICACION
			,@condicionDestinoUsuarioEgreso=CASE WHEN HADM.ESTADOPSALIDA=1 THEN '01' ELSE '02' END
			,@codDiagnosticoCausaMuerte=CASE WHEN HADM.ESTADOPSALIDA=1 THEN 'null' ELSE CAUSABMUERTE END
			,@fechaEgreso=REPLACE(CONVERT(VARCHAR,HADM.FECHAALTAMED,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HADM.FECHAALTAMED,108),5)
			,@consecutivo=1
		FROM HADM LEFT JOIN HCA ON HADM.NOADMISION=HCA.NOADMISION
		WHERE HADM.NOADMISION=@NOADMISION
		AND HCA.CLASE='HC'
		AND HCA.PROCEDENCIA='QX'
		SET @PLANO+='{ '
		SET @PLANO+=' "codPrestador":"'+@codPrestador+'",'
		SET @PLANO+=' "viaIngresoServicioSalud":"'+LTRIM(RTRIM(@viaIngresoServicioSalud))+'",'
		SET @PLANO+=' "fechaInicioAtencion":"'+@fechaInicioAtencion+'",'
		SET @PLANO+=' "numAutorizacion":"'+@numAutorizacion+'",'
		SET @PLANO+=' "causaMotivoAtencion":"'+@causaMotivoAtencion+'",'
      IF COALESCE(@codDiagnosticoPrincipal, '') <> ''
		   SET @PLANO+=' "codDiagnosticoPrincipal":"'+@codDiagnosticoPrincipal+'",'
      IF COALESCE(@codDiagnosticoPrincipalE, '') <> ''
		   SET @PLANO+=' "codDiagnosticoPrincipalE":"'+@codDiagnosticoPrincipalE+'",'
      IF COALESCE(@codDiagnosticoRelacionadoE1, '') <> ''
		   SET @PLANO+=' "codDiagnosticoRelacionadoE1":"'+@codDiagnosticoRelacionadoE1+'",'
      IF COALESCE(@codDiagnosticoRelacionadoE2, '') <> ''
		   SET @PLANO+=' "codDiagnosticoRelacionadoE2":"'+@codDiagnosticoRelacionadoE2+'",'
      IF COALESCE(@codDiagnosticoRelacionadoE3, '') <> ''
		   SET @PLANO+=' "codDiagnosticoRelacionadoE3":"'+@codDiagnosticoRelacionadoE3+'",'
		SET @PLANO+=' "codComplicacion":"'+COALESCE(@codComplicacion,'')+'",'
		SET @PLANO+=' "condicionDestinoUsuarioEgreso":"'+@condicionDestinoUsuarioEgreso+'",'
		SET @PLANO+=' "codDiagnosticoCausaMuerte":"'+COALESCE(@codDiagnosticoCausaMuerte,'null')+'",'
		SET @PLANO+=' "fechaEgreso":"'+@fechaEgreso+'",'
		SET @PLANO+=' "consecutivo":"'+CAST(@consecutivo AS VARCHAR(4))+'",'
		SET @PLANO+= '"conceptoRecaudo":"'+@conceptoRecaudo+'"'
		SET @PLANO+='}'

		SET @PLANO  += ']'

	END
	IF LEN(@RECIEN)>0
	BEGIN
		SET @PLANO += ',"recienNacidos":['
		--SET @PLANO +=LEFT(LTRIM(RTRIM(@RECIEN)),LEN(LTRIM(RTRIM(@RECIEN)))-1)
		SET @PLANO+='RECIENNACIDOSJSON'
		SET @PLANO  += ']'
	END
	
	PRINT '@PROCEDENCIA = ' + @PROCEDENCIA

	IF @PROCEDENCIA='CI'
	BEGIN
		INSERT INTO @OTROSSER(codPrestador,numAutorizacion,idMIPRES,fechaSuministroTecnologia,tipoOS,codTecnologiaSalud,nomTecnologiaSalud
							,cantidadOS,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitOS,vrServicio,tipoPagoModerador
							,valorPagoModerador,numFEVPagoModerador)
		SELECT @IDPRESTADOR,numAutorizacion=CIT.NOAUTORIZACION,null,
		fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,CIT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,CIT.FECHA,108),5),
		tipoOS='04',codTecnologiaSalud=SER.CODCUPS,nomTecnologiaSalud=LEFT(dbo.FNK_LIMPIATEXTO(SER.DESCSERVICIO,'0-9 A-Z();:.,'),60),
		cantidadOS=COALESCE(CIT.CANTIDADC,1),tipoDocumentoIdentificacion=@TIPODOC,
		numDocumentoIdentificacion=@DOCIDAFILIADO,COALESCE(CIT.VALORTOTAL,0),COALESCE(CIT.VALORTOTAL,0),tipoPagoModerador='01',COALESCE(CIT.VALORCOPAGO,0),
		@N_FACTURA
		FROM CIT INNER JOIN SER ON CIT.IDSERVICIO=SER.IDSERVICIO
				INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
		WHERE CONSECUTIVO=@NOADMISION
		AND N_FACTURA=@N_FACTURA
		AND RIPS_CP.ARCHIVO='AT'

	END
	ELSE
	BEGIN 
		IF @PROCEDENCIA='CE'
		BEGIN
			INSERT INTO @OTROSSER(codPrestador,numAutorizacion,idMIPRES,fechaSuministroTecnologia,tipoOS,codTecnologiaSalud,nomTecnologiaSalud
								,cantidadOS,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitOS,vrServicio,tipoPagoModerador
								,valorPagoModerador,numFEVPagoModerador)
			SELECT @IDPRESTADOR,numAutorizacion=AUT.NUMAUTORIZA,null,
			fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,AUT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,AUT.FECHA,108),5),
			tipoOS='04',codTecnologiaSalud=SER.CODCUPS,nomTecnologiaSalud=LEFT( dbo.FNK_LIMPIATEXTO(SER.DESCSERVICIO,'0-9 A-Z();:.,'),60),
			cantidadOS=COALESCE(AUTD.CANTIDAD,1),tipoDocumentoIdentificacion=@TIPODOC,
			numDocumentoIdentificacion=@DOCIDAFILIADO,
			COALESCE(AUTD.VALOR,0),
			COALESCE(AUTD.VALOR,0)*COALESCE(AUTD.CANTIDAD, 0),
			tipoPagoModerador='01',
			COALESCE(AUT.VALORCOPAGO,0),
			@N_FACTURA
			FROM AUT INNER JOIN AUTD ON AUT.IDAUT=AUTD.IDAUT
					INNER JOIN SER ON AUTD.IDSERVICIO=SER.IDSERVICIO
					INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
			WHERE AUT.NOAUT=@NOADMISION
			AND AUTD.N_FACTURA=@N_FACTURA
			AND RIPS_CP.ARCHIVO='AT'

		END
		ELSE 
		BEGIN

			INSERT INTO @OTROSSER(codPrestador,numAutorizacion,idMIPRES,fechaSuministroTecnologia,tipoOS,codTecnologiaSalud,nomTecnologiaSalud
								,cantidadOS,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitOS,vrServicio,tipoPagoModerador
								,valorPagoModerador,numFEVPagoModerador)
			SELECT @IDPRESTADOR                                                                     
            ,numAutorizacion=HADM.NOAUTORIZACION
            ,null                                                                             
            ,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5)
            ,tipoOS='04'
            ,codTecnologiaSalud=CASE WHEN RIPS_CP.IDCONCEPTORIPS=DBO.FNK_VALORVARIABLE('IDMATERIALESRIPS')THEN SER.IDSERVICIO ELSE SER.CODCUPS END
            ,nomTecnologiaSalud=LEFT( dbo.FNK_LIMPIATEXTO(SER.DESCSERVICIO,'0-9 A-Z();:.,'),60)
            ,cantidadOS=CONVERT(INT,COALESCE(HPRED.CANTIDAD,1))
            ,tipoDocumentoIdentificacion=@TIPODOC
            ,numDocumentoIdentificacion=@DOCIDAFILIADO
            ,CONVERT(DECIMAL(14,2),COALESCE(HPRED.VALOR,0))
            ,CONVERT(DECIMAL(14,2),COALESCE(HPRED.VALOR*HPRED.CANTIDAD,0))
            ,tipoPagoModerador='01'
            ,CONVERT(DECIMAL(14,2),COALESCE(HPRED.VALORCOPAGO,0)) 
            ,@N_FACTURA                                                                       
			FROM HADM INNER JOIN  HPRE ON HADM.NOADMISION=HPRE.NOADMISION
					INNER JOIN HPRED ON HPRE.NOPRESTACION=HPRED.NOPRESTACION
					INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO
					LEFT JOIN HCA ON HPRE.CONSECUTIVOHCA=HCA.CONSECUTIVO
					INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
			WHERE HADM.NOADMISION=@NOADMISION
			AND HPRED.N_FACTURA=@N_FACTURA
			AND RIPS_CP.ARCHIVO='AT'   
         AND COALESCE(HPRED.VALOR,0)>0
        
--QUERY2
		END
	END
	SELECT @CANT=COUNT(*) FROM @OTROSSER
	IF @CANT>0 -- AND 1=0
	BEGIN

		SET @PLANO += ',"otrosServicios":['

		SET @NRO=1
		WHILE @NRO<=@CANT
		BEGIN
			SELECT @codPrestador=codPrestador,
			@numAutorizacion=numAutorizacion,
			@idMIPRES=idMIPRES,
			@fechaSuministroTecnologia=fechaSuministroTecnologia,
			@tipoOS=tipoOS,
			@codTecnologiaSalud=codTecnologiaSalud,
			@nomTecnologiaSalud=nomTecnologiaSalud,
			@cantidadOS=cantidadOS,
			@tipoDocumentoIdentificacion=tipoDocumentoIdentificacion,
			@numDocumentoIdentificacion=numDocumentoIdentificacion,
			@vrUnitOS=vrUnitOS,
			@vrServicio=vrServicio,
			@tipoPagoModerador=tipoPagoModerador,
			@valorPagoModerador=valorPagoModerador,
			@numFEVPagoModerador=numFEVPagoModerador,
			@consecutivo= CAST(consecutivo AS VARCHAR(5))
			FROM @OTROSSER
			WHERE consecutivo=@NRO

			IF @NRO > 1 SET @PLANO+=','

			SET @PLANO+='{ '
			SET @PLANO+= '"codPrestador":"'+@codPrestador+'",'
			SET @PLANO+= '"numAutorizacion":"'+@numAutorizacion+'",'
			SET @PLANO+= '"IdMipres":'+IIF(@idMIPRES IS NULL, 'null',CONCAT('"',@idMIPRES,'"'))+','
			SET @PLANO+= '"fechaSuministroTecnologia":"'+@fechaSuministroTecnologia+'",'
			SET @PLANO+= '"tipoOS":"'+@tipoOS+'",'
			SET @PLANO+= '"codTecnologiaSalud":"'+@codTecnologiaSalud+'",'
			SET @PLANO+= '"nomTecnologiaSalud":"'+@nomTecnologiaSalud+'",'
			SET @PLANO+= '"cantidadOS":"'+CAST(@cantidadOS AS VARCHAR)+'",'
			SET @PLANO+= '"tipoDocumentoIdentificacion":"'+@tipoDocumentoIdentificacion+'",'
			SET @PLANO+= '"numDocumentoIdentificacion":"'+@numDocumentoIdentificacion+'",'
			SET @PLANO+= '"vrUnitOS":"'+CAST(@vrUnitOS AS VARCHAR)+'",'
			SET @PLANO+= '"vrServicio":"'+CAST(@vrServicio AS VARCHAR)+'",'
			SET @PLANO+= '"tipoPagoModerador":"'+@tipoPagoModerador+'",'
			SET @PLANO+= '"valorPagoModerador":"'+@valorPagoModerador+'",'
			SET @PLANO+= '"numFEVPagoModerador":"'+@numFEVPagoModerador+'",'
			SET @PLANO+= '"consecutivo":"'+@consecutivo+'",'
			SET @PLANO+= '"conceptoRecaudo":"'+@conceptoRecaudo+'"'
			SET @PLANO+='}'
			SELECT @NRO+=1
		END
	
		SET @PLANO += ']'

	END
   
	SET @PLANO += '}' --SERVICIOS
	SET @PLANO += '}' --CADA USUARIO
	SET @PLANO += ']'--USUARIOS
	SET @PLANO += '}'--FIN

	SELECT @PLANO=REPLACE(@PLANO,'},]','}]')

   SELECT @PLANO=REPLACE(@PLANO,'"null"','null')

	
	SELECT @PLANO = '{"rips": '+@PLANO+',"xmlFevFile": "@XMLFEVFILE"}'

	DECLARE @CNSFCT VARCHAR(20) = (SELECT CNSFCT FROM FTR WHERE N_FACTURA=@N_FACTURA)
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
END

