CREATE OR ALTER PROCEDURE DBO.SPK_RIPS_JSON_FTR_PGP
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
DECLARE @BANDERA INT
DECLARE @BASE64 NVARCHAR(MAX)
DECLARE @valorPagoModerador INT
DECLARE @PLANTILLA VARCHAR(20)
DECLARE @CAMPO_NRODOCUMENTO   VARCHAR (20) 
DECLARE @CAMPO_TIPODOC        VARCHAR (5) 
DECLARE @CAMPO_DESTINORN      VARCHAR (2) 

DECLARE @HC_POR_ADMISION TABLE ( 
   NOADMISION VARCHAR(20),
   CONSECUTIVOHCA VARCHAR(20),
   CAMPO_NRODOCUMENTO VARCHAR(30),
   CAMPO_TIPODOC VARCHAR(10),
   DESTINORN VARCHAR(2)
)

DECLARE @TODAS_HC TABLE ( 
   NOADMISION  varchar(20),
   CONSECUTIVO varchar(20)
)

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
	consecutivo VARCHAR(20),
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
   xconsecutivo int
)
DECLARE @CONSULTAS2 TABLE (
	codPrestador VARCHAR(20),
	consecutivo VARCHAR(20),
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
   ID int ,
   xconsecutivo int
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
   numFEVPagoModerador VARCHAR(20)
)

DECLARE @MEDICAMENTOS TABLE (
	codPrestador VARCHAR(20),
   numAutorizacion VARCHAR(30),
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
DECLARE @MEDICAMENTOS2 TABLE (
	codPrestador VARCHAR(20),
   numAutorizacion VARCHAR(30),
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
   ID INT,
   xconsecutivo int
)

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
DECLARE @PROCEDIMIENTOS2 TABLE (
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
   ID int ,
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
	codServicio VARCHAR(4),
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
	valorPagoModerador  DECIMAL(14,2),
	numFEVPagoModerador VARCHAR(20),
	restoPagoModerador  VARCHAR(10),
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
   codDiagnosticoPrincipal  VARCHAR(20),
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
	edadGestacional INT,
	numConsultasCPrenatal int,
	codSexoBiologico VARCHAR(2),
	peso int,
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
DECLARE @OTROSSER2 TABLE (
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
   ID int,
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
DECLARE @CPROPIO BIT=0
DECLARE @IDPLAN VARCHAR(6),@ESMODERADORAENFTR VARCHAR(2) ,@ITEM_FDIANR INT
BEGIN
	DECLARE @json NVARCHAR(MAX)
	DECLARE @numNota VARCHAR(MAX) --= 'xx'
   DECLARE @MODO_ASISTENCIAL VARCHAR(10) 
   SELECT @MODO_ASISTENCIAL = DBO.FNK_VALORVARIABLE ('MODO_ASISTENCIAL') 
	SELECT @IDTERINSTA = DBO.FNK_VALORVARIABLE('IDTERCEROINSTALADO')
	PRINT 'SPK_RIPS_JSON_FTR_PGP ='+@N_FACTURA

	SELECT @CNSFCT=CNSFCT,@CPROPIO=COALESCE(COPAPROPIO,0),@IDPLAN=IDPLAN FROM FTR WHERE N_FACTURA=@N_FACTURA

	IF NOT EXISTS(SELECT 1 FROM FTRDC WHERE CNSFTR=@CNSFCT)
	BEGIN
		PRINT 'FACTURA CAPITADA SIN RELACION DE SERVICIOS, ME REGRESO'
		RAISERROR('FACTURA CAPITADA SIN RELACION DE SERVICIOS, POR FAVOR VERIFIQUE.', 16, 1)
		RETURN
	END

	IF EXISTS(SELECT 1 FROM FTRDC WHERE CNSFTR=@CNSFCT AND IDAFILIADO IS NULL)
	BEGIN 
		UPDATE FTRDC SET IDAFILIADO=CIT.IDAFILIADO
		FROM FTRDC INNER JOIN CIT ON FTRDC.NOADMISION=CIT.CONSECUTIVO AND FTRDC.PROCEDENCIA IN('CIT','ONCO')
		WHERE FTRDC.IDAFILIADO IS NULL
		AND FTRDC.CNSFTR=@CNSFCT
      
		UPDATE FTRDC SET IDAFILIADO=AUT.IDAFILIADO
		FROM FTRDC INNER JOIN AUT ON FTRDC.NOADMISION=AUT.IDAUT AND FTRDC.PROCEDENCIA='AUT'
		WHERE FTRDC.IDAFILIADO IS NULL
		AND FTRDC.CNSFTR=@CNSFCT

		UPDATE FTRDC SET IDAFILIADO=HADM.IDAFILIADO
		FROM FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION AND FTRDC.PROCEDENCIA='HADM'
		WHERE FTRDC.IDAFILIADO IS NULL
		AND FTRDC.CNSFTR=@CNSFCT
	END
   
	SELECT @conceptoRecaudo = '05'
	SELECT @IDPRESTADOR=COALESCE(IDALTERNA2,'No tengo'), @numDocumentoIdObligado = NIT 
	FROM TER 
	WHERE IDTERCERO=@IDTERINSTA

   SELECT @ITEM_FDIANR = MAX(ITEM)
   FROM   FDIANR 
   WHERE  CNSDOCUMENTO =  @CNSFCT   AND    TIPO = 'FV' AND    METODO = 'SendBillSync'

   IF EXISTS( SELECT * 
               FROM  FDIANR 
               WHERE ITEM = @ITEM_FDIANR
               AND   COALESCE(XML_AttachedDocument,'') != '' )
   BEGIN  
	    IF EXISTS( SELECT * 
                   FROM  FDIANR 
                   WHERE ITEM = @ITEM_FDIANR
                   AND   COALESCE(XML_AttachedDocument,'') != '' 
                   AND   CHARINDEX('<cbc:ID schemeID="02">CUOTA MODERADORA</cbc:ID>',XML_AttachedDocument) > 0  
                   )
	    BEGIN
		    SELECT @ESMODERADORAENFTR = '02'
	    END
	    ELSE
	    BEGIN
          PRINT 'NO ENCONTRE CM'
		    IF EXISTS( SELECT * 
			      FROM  FDIANR 
			      WHERE ITEM = @ITEM_FDIANR
			      AND   COALESCE(XML_AttachedDocument,'') != '' 
			      AND   CHARINDEX('<cbc:ID schemeID="01">COPAGO</cbc:ID>',XML_AttachedDocument) > 0  
			      )
		    BEGIN
	          SELECT @ESMODERADORAENFTR = '01'
		    END
	    END
    END
    ELSE
    BEGIN
       IF EXISTS(SELECT * 
              FROM  FDIANR 
              WHERE ITEM = @ITEM_FDIANR
              AND   TIPO = 'FV'
              AND   COALESCE(CONVERT(NVARCHAR(MAX),XML_SOLICITUD),'') != '' 
			    )
		 BEGIN
          IF EXISTS(SELECT * 
					  FROM  FDIANR 
					  WHERE ITEM = @ITEM_FDIANR
					  AND   TIPO = 'FV'
					  AND   COALESCE(CONVERT(NVARCHAR(MAX),XML_SOLICITUD),'') != '' 
					  AND   CHARINDEX('<cbc:ID schemeID="02">CUOTA MODERADORA</cbc:ID>',CONVERT(NVARCHAR(MAX),XML_SOLICITUD)) > 0 
					   )
			 BEGIN
			   SELECT @ESMODERADORAENFTR = '02'
			 END  
          ELSE
          BEGIN
             IF EXISTS(SELECT * 
					  FROM  FDIANR 
					  WHERE ITEM = @ITEM_FDIANR
					  AND   TIPO = 'FV'
					  AND   COALESCE(CONVERT(NVARCHAR(MAX),XML_SOLICITUD),'') != '' 
					  AND   CHARINDEX('<cbc:ID schemeID="01">COPAGO</cbc:ID>',CONVERT(NVARCHAR(MAX),XML_SOLICITUD)) > 0 
					   )
             BEGIN
                SELECT @ESMODERADORAENFTR = '01'
             END
          END
       END
    END

    PRINT '@ESMODERADORAENFTR='+COALESCE(@ESMODERADORAENFTR,'Noencontrado')

	PRINT 'BUSCANDO LOS AFILIADOS'
	BEGIN 
		INSERT INTO @USUARIOS(tipoDocumentoIdentificacion,numDocumentoIdentificacion,IDAFILIADO,tipoUsuario,fechaNacimiento,codSexo,codPaisResidencia,codPaisOrigen,
								codMunicipioResidencia,codZonaTerritorialResidencia,incapacidad)
		SELECT DISTINCT  AFI.TIPO_DOC,AFI.DOCIDAFILIADO,AFI.IDAFILIADO,
               CASE WHEN COALESCE(AFI.TIPOUSUARIO,'')='' THEN 
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
									WHEN AFI.TIPOAFILIADO = 'S/N' THEN '05' ELSE '05' END ELSE AFI.TIPOUSUARIO END,
					FNACIMIENTO=REPLACE(CONVERT(VARCHAR,AFI.FNACIMIENTO,102),'.','-'),
					SEXO=UPPER(LEFT(AFI.SEXO,1)),'170','170', MUNICIPIO=AFI.CIUDAD,ZONA=CASE WHEN AFI.ZONA='R' THEN '01'ELSE '02' END,
					INCAPACIDAD='NO'
		FROM FTRDC INNER JOIN AFI ON FTRDC.IDAFILIADO=AFI.IDAFILIADO
		WHERE CNSFTR=@CNSFCT
      --AND COALESCE(FTRDC.VALOR,0)>0
	END
   SELECT @conceptoRecaudo=CASE WHEN TIPOSISTEMA='Contributivo' THEN '02' WHEN TIPOSISTEMA='Subsidiado' THEN '01' ELSE '05' END FROM PLN WHERE IDPLAN=@IDPLAN
	PRINT 'ARMADO TABLA DIAGNOSTICOS '
	BEGIN
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
			,LEFT(HCA.IDDX,4),LEFT(HCA.DX1,4),LEFT(HCA.DX2,4),LEFT(HCA.DX3,4)
		FROM HCA INNER JOIN CIT ON HCA.CONSECUTIVOCIT=CIT.CONSECUTIVO --AND HCA.IDAFILIADO = CIT.IDAFILIADO
		WHERE HCA.CLASE='HC'
			AND HCA.PROCEDENCIA='IPS'
			AND COALESCE(HCA.IDDX,'')<>''
			AND EXISTS(SELECT * FROM FTRDC WHERE  FTRDC.CNSFTR=@CNSFCT AND FTRDC.NOADMISION=CIT.CONSECUTIVO AND FTRDC.PROCEDENCIA IN ('CIT','ONCO'))
		UNION 
		SELECT HCA.IDAFILIADO,HCA.NOADMISION,HCA.CONSECUTIVOCIT,
				CASE HCA.TIPODX 
							WHEN 'Presuntivo'   THEN '01'
							WHEN 'Impresion dx' THEN '01'
							WHEN 'Definitivo'   THEN '01'
							WHEN 'Conf Nuevo'   THEN '02'
							WHEN 'Conf Repet'   THEN '03'
							ELSE '01'
							END,LEFT(HCA.IDDX,4),LEFT(HCA.DX1,4),LEFT(HCA.DX2,4),LEFT(HCA.DX3,4)
		FROM HCA INNER JOIN HADM ON HCA.NOADMISION=HADM.NOADMISION AND HCA.IDAFILIADO = HADM.IDAFILIADO
		WHERE HCA.CLASE='HC'
		AND HCA.PROCEDENCIA='QX'
		AND EXISTS(SELECT * FROM FTRDC WHERE  FTRDC.CNSFTR=@CNSFCT AND FTRDC.NOADMISION=HADM.NOADMISION AND FTRDC.PROCEDENCIA='HADM')
	END

   UPDATE HADM SET DXINGRESO=CASE WHEN LEN(COALESCE(HADM.DXINGRESO,''))<4 THEN DX.IDDX ELSE HADM.DXINGRESO END,
   DXEGRESO=CASE WHEN LEN(COALESCE(HADM.DXEGRESO,''))<4 THEN DX.IDDX ELSE HADM.DXEGRESO END,
   COMPLICACION=CASE WHEN LEN(COALESCE(HADM.COMPLICACION,''))<4 THEN DX.IDDX ELSE HADM.COMPLICACION END,
   DXSALIDA1=CASE WHEN LEN(COALESCE(HADM.DXSALIDA1,''))<4 THEN COALESCE(DX.DX1,DX.IDDX) ELSE HADM.DXSALIDA1 END,
   DXSALIDA2=CASE WHEN LEN(COALESCE(HADM.DXSALIDA2,''))<4 THEN COALESCE(DX.DX2,DX.IDDX) ELSE HADM.DXSALIDA2 END,
   DXSALIDA3=CASE WHEN LEN(COALESCE(HADM.DXSALIDA3,''))<4 THEN COALESCE(DX.DX3,DX.IDDX) ELSE HADM.DXSALIDA3 END
   FROM HADM INNER JOIN @DX DX ON HADM.NOADMISION=DX.NOADMISION AND HADM.IDAFILIADO=DX.IDAFILIADO
   WHERE  EXISTS(SELECT * FROM FTRDC WHERE  FTRDC.CNSFTR=@CNSFCT AND FTRDC.NOADMISION=HADM.NOADMISION AND FTRDC.PROCEDENCIA='HADM')
	
	PRINT 'CONSULTAS'
   BEGIN
      PRINT 'CONSULTAS CIT'
	   BEGIN 
			   INSERT INTO @CONSULTAS(codPrestador,CONSECUTIVO,IDAFILIADO,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
									   finalidadTecnologiaSalud,causaMotivoAtencion,vrServicio,conceptoRecaudo,valorPagoModerador,tipoDocumentoIdentificacion, numDocumentoIdentificacion,
                              codDiagnosticoPrincipal,tipoDiagnosticoPrincipal, numFEVPagoModerador)
			   SELECT @IDPRESTADOR,CIT.CONSECUTIVO,CIT.IDAFILIADO,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,CIT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,CIT.FECHA,108),5),
			   numAutorizacion=LEFT(COALESCE(CIT.NOAUTORIZACION,'null'),30),codConsulta=LEFT(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),modalidadGrupoServicioTecSal='01',
            grupoServicios= CASE WHEN COALESCE(SER.RIPS_GRUPO,'')  = '' THEN '01'  ELSE SER.RIPS_GRUPO  END, 
            codServicio   = CASE WHEN COALESCE(SER.RIPS_CODIGO,'') = '' THEN '325' ELSE SER.RIPS_CODIGO END, 
            finalidadTecnologiaSalud=LEFT(CASE WHEN CIT.FINCONSULTA IS NULL OR CIT.FINCONSULTA=''  OR CIT.FINCONSULTA<='10' THEN
																														 CASE WHEN COALESCE( MPE.FINALIDAD,'')<>'' THEN  MPE.FINALIDAD ELSE '44' END  ELSE CIT.FINCONSULTA END,2), --- SE AGREGA LA FINALIDAD DEL PROGRAMA ESPECIAL STORRES  14/07/2025
			   causaMotivoAtencion='38',CIT.VALORTOTAL
			   ,CASE WHEN COALESCE(FTRDC.VLR_COPAGO,0) <= 0 THEN '05'
				     WHEN COALESCE(@ESMODERADORAENFTR,'') <> '' THEN @ESMODERADORAENFTR
				     WHEN COALESCE(FTRDC.VLR_COPAGO,0)>0 THEN CASE WHEN COALESCE(AFI.TIPOUSUARIO,'')IN('01','02','03') 
			                                                            THEN '02'
																   ELSE CASE WHEN COALESCE(AFI.TIPOUSUARIO,'')='04'
																			      THEN '01'
																		     ELSE @conceptoRecaudo
																	    END
														       END
				     ELSE '05'
			    END
			   --IIF(COALESCE(FTRDC.VLR_COPAGO,0)>0,IIF(COALESCE(AFI.TIPOUSUARIO,'')IN('01','02','03'),'02',IIF(COALESCE(AFI.TIPOUSUARIO,'')='04','01' ,@conceptoRecaudo)),'05')
			   ,COALESCE(FTRDC.VLR_COPAGO,0), MED.TIPO_ID, MED.IDMEDICO,
            HCA.IDDX,CASE HCA.TIPODX 
								   WHEN 'Presuntivo'   THEN '01'
								   WHEN 'Impresion dx' THEN '01'
								   WHEN 'Definitivo'   THEN '01'
								   WHEN 'Conf Nuevo'   THEN '02'
								   WHEN 'Conf Repet'   THEN '03'
								   ELSE '01'
								   END, @N_FACTURA
			   FROM FTRDC INNER JOIN CIT ON FTRDC.NOADMISION=CIT.CONSECUTIVO
				           INNER JOIN SER ON FTRDC.IDSERVICIO=SER.IDSERVICIO
						  
                       INNER JOIN AFI ON CIT.IDAFILIADO=AFI.IDAFILIADO
				           INNER JOIN MED ON CIT.IDMEDICO = MED.IDMEDICO
				           INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
						   LEFT JOIN MPE ON MPE.IDPESPECIAL=CIT.IDPESPECIAL
                       LEFT  JOIN ( SELECT ROW_NUMBER() OVER(PARTITION BY HCA.CONSECUTIVOCIT ORDER BY HCA.FECHA ASC) ITEM,  HCA.CONSECUTIVO, CONSECUTIVOCIT, HCA.IDDX, HCA.TIPODX
                                    FROM HCA 
                                    WHERE COALESCE(CONSECUTIVOCIT,'') <> ''  AND YEAR(HCA.FECHA)>='2025'  AND COALESCe(ANULADA,0)=0 
                                   ) HCA ON CIT.CONSECUTIVO=HCA.CONSECUTIVOCIT AND HCA.ITEM = 1
			   WHERE FTRDC.CNSFTR=@CNSFCT
			   AND FTRDC.PROCEDENCIA IN ('CIT','ONCO')
			   --AND CIT.N_FACTURA=@N_FACTURA
			   AND RIPS_CP.ARCHIVO='AC'
            --AND COALESCE(CIT.VALORTOTAL,0)>0
		   END
	   PRINT 'CONSULTAS AUT'
	   BEGIN
		   INSERT INTO @CONSULTAS(codPrestador,CONSECUTIVO,IDAFILIADO,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
					      finalidadTecnologiaSalud,causaMotivoAtencion,vrServicio,conceptoRecaudo,valorPagoModerador, tipoDocumentoIdentificacion, numDocumentoIdentificacion, 
					      codDiagnosticoPrincipal, codDiagnosticoRelacionado1, codDiagnosticoRelacionado2, tipoDiagnosticoPrincipal,numFEVPagoModerador)
		   SELECT @IDPRESTADOR,AUT.NOAUT,AUT.IDAFILIADO,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,AUT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,AUT.FECHA,108),5),
		          numAutorizacion=LEFT(COALESCE(AUT.NUMAUTORIZA,'null'),30) ,codConsulta=LEFT(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),modalidadGrupoServicioTecSal='01',
                grupoServicios= CASE WHEN COALESCE(SER.RIPS_GRUPO,'')  = '' THEN '01'  ELSE SER.RIPS_GRUPO  END, 
                codServicio   = CASE WHEN COALESCE(SER.RIPS_CODIGO,'') = '' THEN '325' ELSE SER.RIPS_CODIGO END, 
                finalidadTecnologiaSalud=LEFT(CASE WHEN AUT.FINALIDAD IS NULL OR AUT.FINALIDAD='' OR CONVERT(INT,AUT.FINALIDAD)<=10 THEN '44' ELSE  CASE WHEN AUT.FINALIDAD='10' THEN '44' ELSE AUT.FINALIDAD END END,2),
		          causaMotivoAtencion='38'
               ,AUTD.VALOR
		         ,CASE WHEN COALESCE(FTRDC.VLR_COPAGO,0) <= 0 THEN '05'
                     WHEN COALESCE(@ESMODERADORAENFTR,'') <> '' THEN @ESMODERADORAENFTR
                     WHEN COALESCE(FTRDC.VLR_COPAGO,0)>0 THEN '02'
                     ELSE '05'
                END
               --IIF(COALESCE(AUTD.VALORCOPAGO,0)>0,'02','05')
               ,COALESCE(FTRDC.VLR_COPAGO,0), COALESCE(MED.TIPO_ID, @TIPODOC,''), COALESCE(MED.IDMEDICO, @DOCIDAFILIADO,''),
                AUT.DXPPAL, CASE WHEN COALESCE(AUT.DXRELACIONADO,'')='' THEN 'null' END, CASE WHEN COALESCE(AUT.DXRELACIONADO2,'')='' THEN 'null' END,'01',
                @N_FACTURA
		   FROM  FTRDC INNER JOIN AUT ON FTRDC.NOADMISION=AUT.IDAUT 
			            INNER JOIN AUTD ON AUT.IDAUT=AUTD.IDAUT AND FTRDC.NOPRESTACION=AUTD.IDAUT AND FTRDC.NOITEM=AUTD.NO_ITEM
				         INNER JOIN SER ON AUTD.IDSERVICIO=SER.IDSERVICIO
				         INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
			            LEFT  JOIN MED ON IIF(COALESCE(AUT.IDMEDICOSOLICITA,'')='',DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT'),AUT.IDMEDICOSOLICITA)=MED.IDMEDICO
		   WHERE FTRDC.CNSFTR=@CNSFCT
		   AND FTRDC.PROCEDENCIA='AUT'
		   AND AUTD.N_FACTURA=@N_FACTURA
		   --AND AUT.IDAFILIADO=@IDAFILIADO
		   AND RIPS_CP.ARCHIVO='AC'
         AND COALESCE(AUTD.VALOR,0)>0
      END  		
	   PRINT 'CONSULTAS HADM...'
      BEGIN
		   INSERT INTO @CONSULTAS(codPrestador,CONSECUTIVO,IDAFILIADO,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
							   finalidadTecnologiaSalud,causaMotivoAtencion,codDiagnosticoPrincipal,codDiagnosticoRelacionado1,codDiagnosticoRelacionado2,
							   codDiagnosticoRelacionado3,tipoDiagnosticoPrincipal,vrServicio,conceptoRecaudo,valorPagoModerador, 	tipoDocumentoIdentificacion, numDocumentoIdentificacion,
                        numFEVPagoModerador) 
		   SELECT COALESCE(@IDPRESTADOR,''),HADM.NOADMISION,HADM.IDAFILIADO,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5),
		         numAutorizacion= LEFT(COALESCE(HADM.NOAUTORIZACION,'null'),30) ,codConsulta=LEFT(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),modalidadGrupoServicioTecSal='01', 
               grupoServicios= CASE WHEN COALESCE(SER.RIPS_GRUPO,'')  = '' THEN '01'  ELSE SER.RIPS_GRUPO  END, 
               codServicio   = CASE WHEN COALESCE(SER.RIPS_CODIGO,'') = '' THEN '325' ELSE SER.RIPS_CODIGO END, 
               finalidadTecnologiaSalud=LEFT(CASE WHEN HPRE.FINALIDAD IS NULL OR HPRE.FINALIDAD='' OR HPRE.FINALIDAD<='10'THEN '44' ELSE HPRE.FINALIDAD END,2),
		         causaMotivoAtencion='38',COALESCE(HADM.DXINGRESO,HADM.DXEGRESO),COALESCE(HADM.DXSALIDA1,''),COALESCE(HADM.DXSALIDA2,''),COALESCE(HADM.DXSALIDA3,''),
		         '01',HPRED.VALOR,IIF(COALESCE(FTRDC.VLR_COPAGO,0)>0,'01','05'),COALESCE(FTRDC.VLR_COPAGO,0), MED.TIPO_ID, MED.IDMEDICO, @N_FACTURA
		   FROM  FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION  
			   INNER JOIN  HPRE ON HADM.NOADMISION=HPRE.NOADMISION
				   INNER JOIN HPRED ON HPRE.NOPRESTACION=HPRED.NOPRESTACION AND HPRED.NOITEM = FTRDC.NOITEM
				   INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO AND FTRDC.IDSERVICIO = SER.IDSERVICIO
				   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
			   INNER JOIN MED ON MED.IDMEDICO = CASE WHEN COALESCE(HPRE.IDMEDICO,'') = '' THEN COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA) ELSE HPRE.IDMEDICO END
		   WHERE FTRDC.CNSFTR=@CNSFCT
		   AND FTRDC.PROCEDENCIA='HADM'
		   --AND HADM.IDAFILIADO=@IDAFILIADO
		   AND HPRED.N_FACTURA=@N_FACTURA
		   AND COALESCE(HPRED.VALOR,0)>0
		   AND RIPS_CP.ARCHIVO='AC'
		   AND HPRED.CANTIDAD=1
	
		   PRINT 'REVISO CANTIDADES MAYORES A 1 CONSULTAS HADM'

		   INSERT INTO @CONSULTAS1(codPrestador,CONSECUTIVO,IDAFILIADO,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
							   finalidadTecnologiaSalud,causaMotivoAtencion,codDiagnosticoPrincipal,codDiagnosticoRelacionado1,codDiagnosticoRelacionado2,
							   codDiagnosticoRelacionado3,tipoDiagnosticoPrincipal,vrServicio,conceptoRecaudo,valorPagoModerador,Cantidad, tipoDocumentoIdentificacion, numDocumentoIdentificacion,
                        numFEVPagoModerador) 
		   SELECT COALESCE(@IDPRESTADOR,''),HADM.NOADMISION,HADM.IDAFILIADO,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5),
		   numAutorizacion=LEFT(COALESCE(HADM.NOAUTORIZACION,'null'),30),codConsulta=left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),modalidadGrupoServicioTecSal='01',
         grupoServicios= CASE WHEN COALESCE(SER.RIPS_GRUPO,'')  = '' THEN '01'  ELSE SER.RIPS_GRUPO  END, 
         codServicio   = CASE WHEN COALESCE(SER.RIPS_CODIGO,'') = '' THEN '325' ELSE SER.RIPS_CODIGO END, 
         finalidadTecnologiaSalud=LEFT(CASE WHEN HPRE.FINALIDAD IS NULL OR HPRE.FINALIDAD='' OR HPRE.FINALIDAD<='10'THEN '44' ELSE HPRE.FINALIDAD END,2),
		   causaMotivoAtencion='38',COALESCE(HADM.DXINGRESO,HADM.DXEGRESO),COALESCE(HADM.DXSALIDA1,''),COALESCE(HADM.DXSALIDA2,''),COALESCE(HADM.DXSALIDA3,''),
		   '01',HPRED.VALOR,IIF(COALESCE(FTRDC.VLR_COPAGO,0)>0,'01','05'),COALESCE(FTRDC.VLR_COPAGO,0),CONVERT(INT,HPRED.CANTIDAD), MED.TIPO_ID, MED.IDMEDICO, @N_FACTURA
		   FROM  FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION  
			   INNER JOIN  HPRE ON HADM.NOADMISION=HPRE.NOADMISION
				   INNER JOIN HPRED ON HPRE.NOPRESTACION=HPRED.NOPRESTACION AND HPRED.NOITEM = FTRDC.NOITEM
				   INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO  AND FTRDC.IDSERVICIO = SER.IDSERVICIO
				   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
			   INNER JOIN MED ON MED.IDMEDICO = CASE WHEN COALESCE(HPRE.IDMEDICO,'') = '' THEN COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA) ELSE HPRE.IDMEDICO END
		   WHERE FTRDC.CNSFTR=@CNSFCT
		   AND FTRDC.PROCEDENCIA='HADM'
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
				   SELECT @BANDERA=1
				   WHILE @BANDERA<=@CANTORI
				   BEGIN
					   INSERT INTO @CONSULTAS(codPrestador,CONSECUTIVO,IDAFILIADO,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
								   finalidadTecnologiaSalud,causaMotivoAtencion,codDiagnosticoPrincipal,codDiagnosticoRelacionado1,codDiagnosticoRelacionado2,
								   codDiagnosticoRelacionado3,tipoDiagnosticoPrincipal,vrServicio,conceptoRecaudo,valorPagoModerador,tipoDocumentoIdentificacion, numDocumentoIdentificacion) 
					   SELECT codPrestador,CONSECUTIVO,IDAFILIADO,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
								   finalidadTecnologiaSalud,causaMotivoAtencion,codDiagnosticoPrincipal,codDiagnosticoRelacionado1,codDiagnosticoRelacionado2,
								   codDiagnosticoRelacionado3,tipoDiagnosticoPrincipal,vrServicio,conceptoRecaudo,valorPagoModerador, tipoDocumentoIdentificacion, numDocumentoIdentificacion 
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
	   END
   END
	PRINT 'VAMOS POR MEDICAMENTOS'
	BEGIN
      PRINT 'MEDICAMENTOS AUT'
      BEGIN
		   INSERT INTO @MEDICAMENTOS(codPrestador,numAutorizacion,IDAFILIADO,CONSECUTIVO,idMIPRES,fechaDispensAdmon,codDiagnosticoPrincipal,codDiagnosticoRelacionado
									   ,tipoMedicamento,codTecnologiaSalud,nomTecnologiaSalud,concentracionMedicamento,unidadMedida,formaFarmaceutica
									   ,unidadMinDispensa,cantidadMedicamento,diasTratamiento,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitMedicamento
									   ,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador)
		   SELECT @IDPRESTADOR,LEFT(COALESCE(AUT.NUMAUTORIZA,'null'),30) ,AUT.IDAFILIADO,AUT.NOAUT,'null',fechaDispensAdmon=REPLACE(CONVERT(VARCHAR,AUT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,AUT.FECHA,108),5),
			   AUT.DXPPAL,IIF(COALESCE(AUT.DXRELACIONADO,'')='',AUT.DXPPAL,AUT.DXRELACIONADO),'01',COALESCE(SER.CODCUM,IART.CODCUM),LEFT( dbo.FNK_LIMPIATEXTO(IIF(COALESCE(IART.DESCRIPCION,'')='',SER.DESCSERVICIO,IART.DESCRIPCION),'0-9 A-Z();:.,'),30),
            CASE WHEN ISNUMERIC(dbo.FNK_LIMPIATEXTO(LEFT(COALESCE(ICCN.DESCRIPCION,'0'),3),'0-9'))=1 THEN dbo.FNK_LIMPIATEXTO(LEFT(COALESCE(ICCN.DESCRIPCION,'0'),3),'0-9') ELSE 0 END,
			   COALESCE(IUNI.HOMOLOGO_RIPS,247),COALESCE(IFFA.HOMOJSON,'null'),'11',COALESCE(AUTD.CANTIDAD,0),CASE WHEN COALESCE(AUTD.DIAS,0)=0 THEN 1 ELSE AUTD.DIAS END,COALESCE(MED.TIPO_ID,'CC'),COALESCE(MED.IDMEDICO,DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT')),
            AUTD.VALOR,AUTD.VALOR*AUTD.CANTIDAD,IIF(COALESCE(FTRDC.VLR_COPAGO,0)>0,'02','05'),'04',COALESCE(FTRDC.VLR_COPAGO,0),@N_FACTURA
		   FROM FTRDC INNER JOIN AUT ON FTRDC.NOADMISION=AUT.IDAUT  
			   INNER JOIN AUTD ON AUT.IDAUT=AUTD.IDAUT
			   INNER JOIN SER ON AUTD.IDSERVICIO=SER.IDSERVICIO AND FTRDC.IDSERVICIO = SER.IDSERVICIO 
			   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
			   LEFT  JOIN IART ON SER.IDSERVICIO=IART.IDSERVICIO AND IART.PRINCIPAL=1
			   LEFT  JOIN IFFA  ON IART.IDFORFARM=IFFA.IDFORFARM
			   LEFT JOIN IUNI ON IUNI.IDUNIDAD=IART.IDUNIDAD
            LEFT JOIN ICCN ON IART.IDCONCENTRA=ICCN.IDCONCENTRA
            LEFT JOIN MED ON IIF(COALESCE(AUT.IDMEDICOSOLICITA,'')='',DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT'),AUT.IDMEDICOSOLICITA)=MED.IDMEDICO
		   WHERE FTRDC.CNSFTR=@CNSFCT
		   AND FTRDC.PROCEDENCIA='AUT'
		   AND AUTD.N_FACTURA=@N_FACTURA
		   AND RIPS_CP.ARCHIVO='AM'
      END
	   PRINT 'MEDICAMENTOS HADM'
      BEGIN
		   INSERT INTO @MEDICAMENTOS(codPrestador,numAutorizacion,IDAFILIADO,CONSECUTIVO,idMIPRES,fechaDispensAdmon,codDiagnosticoPrincipal,codDiagnosticoRelacionado
									   ,tipoMedicamento,codTecnologiaSalud,nomTecnologiaSalud,concentracionMedicamento,unidadMedida,formaFarmaceutica
									   ,unidadMinDispensa,cantidadMedicamento,diasTratamiento,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitMedicamento
									   ,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador)

		   SELECT @IDPRESTADOR,LEFT(COALESCE(HADM.NOAUTORIZACION,'null'),30) ,HADM.IDAFILIADO,HADM.NOADMISION,'null',fechaDispensAdmon=REPLACE(CONVERT(VARCHAR,FTRDC.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,FTRDC.FECHA,108),5),
			   COALESCE(HADM.DXINGRESO,''),IIF(COALESCE(HADM.DXSALIDA1,'')='',COALESCE(HADM.DXINGRESO,''),HADM.DXSALIDA1),'01',CASE WHEN COALESCE(SER.MEDICAMENTOS,0)=1 THEN IIF(COALESCE(IART.CODCUM,'')='',SER.CODCUM,IART.CODCUM) ELSE SER.IDSERVICIO END,
               LEFT(dbo.FNK_LIMPIATEXTO(IART.DESCRIPCION,'0-9 A-Z();:.,'),30),
               CASE WHEN ISNUMERIC(dbo.FNK_LIMPIATEXTO(LEFT(COALESCE(ICCN.DESCRIPCION,'0'),3),'0-9'))=1 THEN dbo.FNK_LIMPIATEXTO(LEFT(COALESCE(ICCN.DESCRIPCION,'0'),3),'0-9') ELSE 0 END,COALESCE(IUNI.HOMOLOGO_RIPS,247),COALESCE(IFFA.HOMOJSON,'null'),'11',
               COALESCE(HPRED.CANTIDAD,0),1,COALESCE(MED.TIPO_ID,'CC'),COALESCE(MED.IDMEDICO,DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT')),CONVERT(VARCHAR,CONVERT(DECIMAL(14,2),HPRED.VALOR),20),
			   CONVERT(VARCHAR,CONVERT(DECIMAL(14,2),HPRED.VALOR*HPRED.CANTIDAD),20),IIF(COALESCE(FTRDC.VLR_COPAGO,0)>0,'02',@conceptoRecaudo),'04',CONVERT(DECIMAL(14,2),FTRDC.VLR_COPAGO),@N_FACTURA
		   FROM FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION
               INNER JOIN AFI  ON FTRDC.IDAFILIADO=AFI.IDAFILIADO
               INNER JOIN HPRED ON FTRDC.NOPRESTACION=HPRED.NOPRESTACION AND FTRDC.NOITEM=HPRED.NOITEM 
               INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO AND FTRDC.IDSERVICIO = SER.IDSERVICIO
			   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
			   LEFT JOIN IART ON COALESCE(HPRED.IDARTICULO,SER.IDARTICULO)=IART.IDARTICULO
			   LEFT JOIN IFFA ON IART.IDFORFARM=IFFA.IDFORFARM
			   LEFT JOIN IUNI ON IUNI.IDUNIDAD = IART.IDUNIDAD
            LEFT JOIN ICCN ON IART.IDCONCENTRA=ICCN.IDCONCENTRA
            LEFT JOIN MED ON COALESCE(HADM.IDMEDICOING,HADM.IDMEDICOTRA)=MED.IDMEDICO
		   WHERE FTRDC.CNSFTR=@CNSFCT
		   AND FTRDC.PROCEDENCIA='HADM'
		   AND HPRED.N_FACTURA=@N_FACTURA
		   AND COALESCE(HPRED.VALOR,0)>0
		   AND COALESCE(HPRED.NOCOBRABLE,0)=0
		   AND RIPS_CP.ARCHIVO='AM'
      END
	END
	
	PRINT 'PROCEDIMIENTOS'
	BEGIN 
      PRINT 'PROCEDIMIENTOS CIT'
            BEGIN
		         INSERT INTO @PROCEDIMIENTOS (codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
					         ,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
					         ,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador
					         )
		         SELECT @IDPRESTADOR,CIT.IDAFILIADO,CIT.CONSECUTIVO,REPLACE(CONVERT(VARCHAR,CIT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,CIT.FECHA,108),5),'null',
				          LEFT(COALESCE(CIT.NOAUTORIZACION,'null'),30),left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),'02','01',
                      grupoServicios= CASE WHEN COALESCE(SER.RIPS_GRUPO,'')  = '' THEN '01'  ELSE SER.RIPS_GRUPO  END, -- 20250702 -- STORRES SE CAMBIA PARA QUE ENVIE LOS CODIGOS CONFIGURADO
                      codServicio   = CASE WHEN COALESCE(SER.RIPS_CODIGO,'') = '' THEN '325' ELSE SER.RIPS_CODIGO END, -- 20250702 -- STORRES SE CAMBIA PARA QUE ENVIE LOS CODIGOS CONFIGURADO
                      '16',MED.TIPO_ID,MED.IDMEDICO,CIT.IDDX,
				          CASE WHEN COALESCE(CIT.IDDX,'')='' THEN 'null' END,CASE WHEN COALESCE(CIT.IDDX,'')='' THEN 'null' END,CIT.VALORTOTAL
                     ,CASE WHEN COALESCE(FTRDC.VLR_COPAGO,0)<= 0 THEN '05'
                           WHEN COALESCE(@ESMODERADORAENFTR,'') <> '' THEN @ESMODERADORAENFTR 
                           WHEN COALESCE(FTRDC.VLR_COPAGO,0)>0 THEN '02'
                           ELSE '05'
                      END
                     --IIF(COALESCE(FTRDC.VLR_COPAGO,0)>0,'02','05')
                     ,'04'
                     ,COALESCE(FTRDC.VLR_COPAGO,0),@N_FACTURA
		         FROM  FTRDC 
			         INNER JOIN CIT ON FTRDC.NOADMISION=CIT.CONSECUTIVO
			         INNER JOIN SER ON CIT.IDSERVICIO=SER.IDSERVICIO
			         INNER JOIN AFI ON FTRDC.IDAFILIADO=AFI.IDAFILIADO
			         INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
                  LEFT  JOIN MED ON CIT.IDMEDICO=MED.IDMEDICO
		         WHERE FTRDC.CNSFTR=@CNSFCT
		         AND FTRDC.PROCEDENCIA IN('CIT','ONCO')
		         --AND CIT.N_FACTURA=@N_FACTURA
		         AND RIPS_CP.ARCHIVO='AP'
            END   
      PRINT 'PROCEDIMIENTOS AUT'
		   BEGIN --AP
            INSERT INTO @PROCEDIMIENTOS  (codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
					   ,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
					   ,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador)
			   SELECT @IDPRESTADOR,AUT.IDAFILIADO,AUT.NOAUT,REPLACE(CONVERT(VARCHAR, AUT.FECHA, 102), '.', '-') + ' ' + LEFT(CONVERT(VARCHAR, AUT.FECHA, 108), 5),'NULL'
				   ,LEFT(COALESCE(AUT.NUMAUTORIZA,'null'),30),left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),'02','01'
               ,grupoServicios= CASE WHEN COALESCE(SER.RIPS_GRUPO,'')  = '' THEN '01'  ELSE SER.RIPS_GRUPO  END -- 20250702 -- STORRES SE CAMBIA PARA QUE ENVIE LOS CODIGOS CONFIGURADO
               ,codServicio   = CASE WHEN COALESCE(SER.RIPS_CODIGO,'') = '' THEN '325' ELSE SER.RIPS_CODIGO END -- 20250702 -- STORRES SE CAMBIA PARA QUE ENVIE LOS CODIGOS CONFIGURADO
               ,'16',COALESCE(MED.TIPO_ID, 'CC'), COALESCE(MED.IDMEDICO,DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT'))
				   ,AUT.DXPPAL,IIF(COALESCE(AUT.DXRELACIONADO,'')='',AUT.DXPPAL,AUT.DXRELACIONADO),AUT.DXPPAL,AUTD.VALOR
               ,CASE  WHEN COALESCE(FTRDC.VLR_COPAGO,0)<=0 THEN '05'  
                      WHEN COALESCE(@ESMODERADORAENFTR,'') <> '' THEN @ESMODERADORAENFTR 
                      WHEN COALESCE(FTRDC.VLR_COPAGO,0)>0 THEN '02'
                      ELSE '05'
                END
               --IIF(COALESCE(AUT.VALORCOPAGO,0)>0,'02','05')
               ,'04'
				   ,CASE WHEN AUT.IDPLAN IN (DBO.FNK_VALORVARIABLE ('IDPLANPART'),DBO.FNK_VALORVARIABLE ('IDPLANPART2')    ----VGARCIA
										   ,DBO.FNK_VALORVARIABLE ('IDPLANPART3'),DBO.FNK_VALORVARIABLE ('IDPLANPART4')  ----VGARCIA
										   ,DBO.FNK_VALORVARIABLE ('IDPLANPART5'))                                       ----VGARCIA
						   THEN '0.00' 
						   ELSE FTRDC.VLR_COPAGO
						   END
				   ,@N_FACTURA
			   FROM FTRDC 
							INNER JOIN AUTD    ON FTRDC.NOADMISION=AUTD.IDAUT AND FTRDC.NOITEM=AUTD.NO_ITEM
							INNER JOIN AUT    ON AUTD.IDAUT= AUT.IDAUT
					   INNER JOIN AFI ON COALESCE(FTRDC.IDAFILIADO,AUT.IDAFILIADO)=AFI.IDAFILIADO
					   INNER JOIN SER ON AUTD.IDSERVICIO = SER.IDSERVICIO AND FTRDC.IDSERVICIO = SER.IDSERVICIO
					   INNER JOIN RIPS_CP ON SER.CODIGORIPS = RIPS_CP.IDCONCEPTORIPS
					   LEFT  JOIN MED ON MED.IDMEDICO = IIF(COALESCE(AUT.IDMEDICOSOLICITA,'')='',DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT'),AUT.IDMEDICOSOLICITA)				
			   WHERE FTRDC.CNSFTR=@CNSFCT
			   AND FTRDC.PROCEDENCIA='AUT'
			   AND AUTD.N_FACTURA = @N_FACTURA
			   AND RIPS_CP.ARCHIVO = 'AP'
			   AND FTRDC.CANTIDAD = 1



			   INSERT INTO @PROCEDIMIENTOS1 (codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
					   ,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
					   ,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,cantidad,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador)
			   SELECT @IDPRESTADOR,AUT.IDAFILIADO,AUT.NOAUT,REPLACE(CONVERT(VARCHAR, AUT.FECHA, 102), '.', '-') + ' ' + LEFT(CONVERT(VARCHAR, AUT.FECHA, 108), 5),'NULL'
				   ,LEFT(COALESCE(AUT.NUMAUTORIZA,'null'),30),left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),'02','01'
               ,grupoServicios= CASE WHEN COALESCE(SER.RIPS_GRUPO,'')  = '' THEN '01'  ELSE SER.RIPS_GRUPO  END -- 20250702 -- STORRES SE CAMBIA PARA QUE ENVIE LOS CODIGOS CONFIGURADO
               ,codServicio   = CASE WHEN COALESCE(SER.RIPS_CODIGO,'') = '' THEN '325' ELSE SER.RIPS_CODIGO END -- 20250702 -- STORRES SE CAMBIA PARA QUE ENVIE LOS CODIGOS CONFIGURADO
               ,'16',COALESCE(MED.TIPO_ID, 'CC'), COALESCE(MED.IDMEDICO,DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT'))
				   ,AUT.DXPPAL,IIF(COALESCE(AUT.DXRELACIONADO,'')='',AUT.DXPPAL,AUT.DXRELACIONADO),AUT.DXPPAL,AUTD.VALOR
               ,CASE  WHEN COALESCE(FTRDC.VLR_COPAGO,0)<=0 THEN '05'  
                      WHEN COALESCE(@ESMODERADORAENFTR,'') <> '' THEN @ESMODERADORAENFTR 
                      WHEN COALESCE(FTRDC.VLR_COPAGO,0)>0 THEN '02'
                      ELSE '05'
                END
               --IIF(COALESCE(AUT.VALORCOPAGO,0)>0,'02','05')
               ,FTRDC.CANTIDAD,'04'
				   ,CASE WHEN AUT.IDPLAN IN (DBO.FNK_VALORVARIABLE ('IDPLANPART'),DBO.FNK_VALORVARIABLE ('IDPLANPART2')    ----VGARCIA
										   ,DBO.FNK_VALORVARIABLE ('IDPLANPART3'),DBO.FNK_VALORVARIABLE ('IDPLANPART4')  ----VGARCIA
										   ,DBO.FNK_VALORVARIABLE ('IDPLANPART5'))                                       ----VGARCIA
						   THEN '0.00' 
						   ELSE FTRDC.VLR_COPAGO
						   END
				   ,@N_FACTURA
			   FROM FTRDC 
					   INNER JOIN AUT ON FTRDC.NOADMISION=AUT.IDAUT
					   INNER JOIN AUTD ON AUT.IDAUT = AUTD.IDAUT
					   INNER JOIN AFI ON COALESCE(FTRDC.IDAFILIADO,AUT.IDAFILIADO)=AFI.IDAFILIADO
					   INNER JOIN SER ON AUTD.IDSERVICIO = SER.IDSERVICIO AND FTRDC.IDSERVICIO = SER.IDSERVICIO
					   INNER JOIN RIPS_CP ON SER.CODIGORIPS = RIPS_CP.IDCONCEPTORIPS
					   LEFT  JOIN MED ON MED.IDMEDICO = IIF(COALESCE(AUT.IDMEDICOSOLICITA,'')='',DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT'),AUT.IDMEDICOSOLICITA)				
			   WHERE FTRDC.CNSFTR=@CNSFCT
			   AND FTRDC.PROCEDENCIA='AUT'
			   AND AUTD.N_FACTURA = @N_FACTURA
			   AND RIPS_CP.ARCHIVO = 'AP'
			   AND FTRDC.CANTIDAD > 1
			
			   DECLARE @RESIDUO DECIMAL(14,2)
			
			   UPDATE @PROCEDIMIENTOS1 SET restoPagoModerador=TRY_CAST(valorPagoModerador AS decimal(14,2))%cantidad WHERE 1=1
			   UPDATE @PROCEDIMIENTOS1 SET valorPagoModerador=TRY_CAST(valorPagoModerador AS decimal(14,2))-TRY_CAST(restoPagoModerador AS decimal(14,2)) WHERE 1=1
			   SELECT @RESIDUO=SUM(TRY_CAST(restoPagoModerador AS decimal(14,2))) FROM @PROCEDIMIENTOS1 WHERE 1=1
			
			   DECLARE JSPROCE_CURSOR_AUTD CURSOR FOR 
			   SELECT IDPROCE,CANTIDAD FROM @PROCEDIMIENTOS1
			   ORDER BY IDPROCE
			   OPEN JSPROCE_CURSOR_AUTD
			   FETCH NEXT FROM JSPROCE_CURSOR_AUTD INTO @CNSCONSULTA,@CANTORI
			   WHILE @@FETCH_STATUS = 0
			   BEGIN
				   SELECT @valorPagoModerador=CONVERT(INT, CAST((CAST(valorPagoModerador AS decimal(14,2))/@CANTORI) AS DECIMAL (14,2))) FROM @PROCEDIMIENTOS1 WHERE IDPROCE=@CNSCONSULTA
				   SELECT @BANDERA=1
				   WHILE @BANDERA<=@CANTORI
				   BEGIN
					   IF @CNSCONSULTA=1 AND @BANDERA=@CANTORI
					   BEGIN
						   SET @valorPagoModerador = CONVERT(INT, TRY_CAST(@valorPagoModerador AS decimal)+TRY_CAST(@RESIDUO AS decimal(14,2)))
					   END
					   INSERT INTO @PROCEDIMIENTOS (codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
									   ,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
									   ,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador
									   )
					   SELECT codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
									   ,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
									   ,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,tipoPagoModerador,@valorPagoModerador,numFEVPagoModerador
					   FROM @PROCEDIMIENTOS1
					   WHERE IDPROCE=@CNSCONSULTA
					   SELECT @BANDERA = @BANDERA+1
				   END
				   FETCH NEXT FROM JSPROCE_CURSOR_AUTD INTO  @CNSCONSULTA,@CANTORI
			   END
			   CLOSE JSPROCE_CURSOR_AUTD
			   DEALLOCATE JSPROCE_CURSOR_AUTD
         DELETE FROM @PROCEDIMIENTOS1 WHERE 1=1
		   END
      PRINT 'PROCEDIMIENTOS HADM'
         BEGIN
		   INSERT INTO @PROCEDIMIENTOS (codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
					   ,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
					   ,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador
					   )
		   SELECT @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION,REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5),'null',
			   LEFT(COALESCE(HADM.NOAUTORIZACION,'null'),30)  ,left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),COALESCE(REPLACE(TGEN.DATO2,' ',''),HADM.VIAINGRESO,'02'),'01',
            grupoServicios= CASE WHEN COALESCE(SER.RIPS_GRUPO,'')  = '' THEN '01'  ELSE SER.RIPS_GRUPO  END, -- 20250702 -- STORRES SE CAMBIA PARA QUE ENVIE LOS CODIGOS CONFIGURADO
            codServicio   = CASE WHEN COALESCE(SER.RIPS_CODIGO,'') = '' THEN '325' ELSE SER.RIPS_CODIGO END, -- 20250702 -- STORRES SE CAMBIA PARA QUE ENVIE LOS CODIGOS CONFIGURADO
            '16',COALESCE(MED.TIPO_ID,'CC'),COALESCE(MED.IDMEDICO,DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT')),COALESCE(HADM.DXINGRESO,HADM.DXEGRESO), 
			   CASE WHEN LEN(COALESCE(HADM.DXSALIDA1,''))<4 THEN COALESCE(HADM.DXINGRESO,HADM.DXEGRESO) ELSE HADM.DXSALIDA1 END, -- 20250613 storres  Se agrega ELSE ya que no tenia y este campo no puede ir en blanco
			   CASE WHEN COALESCE(HADM.COMPLICACION,HADM.DXINGRESO,HADM.DXEGRESO,'')='' THEN 'null' ELSE COALESCE(HADM.COMPLICACION,HADM.DXINGRESO,HADM.DXEGRESO,'') END, 
            HPRED.VALOR,IIF(COALESCE(FTRDC.VLR_COPAGO,0)>0,'02','05'),'04',COALESCE(FTRDC.VLR_COPAGO,0),@N_FACTURA
		   FROM  FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION
					   INNER JOIN AFI  ON FTRDC.IDAFILIADO=AFI.IDAFILIADO
					   INNER JOIN HPRED ON FTRDC.NOPRESTACION=HPRED.NOPRESTACION AND FTRDC.NOITEM=HPRED.NOITEM
					   INNER JOIN HPRE  ON HADM.NOADMISION=HPRE.NOADMISION AND FTRDC.NOPRESTACION=HPRE.NOPRESTACION
					   INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO AND FTRDC.IDSERVICIO = SER.IDSERVICIO
					   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
					   INNER JOIN TGEN ON HADM.VIAINGRESO = TGEN.CODIGO AND TABLA = 'General' AND CAMPO = 'VIADEINGRESO' 
					   LEFT JOIN MED ON MED.IDMEDICO = CASE WHEN COALESCE(HPRE.IDMEDICO,'') = '' OR  COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA)='' THEN DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT') 
                                                  ELSE CASE WHEN COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA)='' THEN HPRE.IDMEDICO  END END
		   WHERE FTRDC.CNSFTR=@CNSFCT
		   AND FTRDC.PROCEDENCIA='HADM'
		   AND HPRED.N_FACTURA=@N_FACTURA
		   AND COALESCE(HPRED.VALOR,0)>0
		   AND COALESCE(HPRED.NOCOBRABLE,0)=0
		   AND HPRED.CANTIDAD=1
		   AND RIPS_CP.ARCHIVO='AP' 
--QUERY2
--QUERY2	
		   PRINT 'INSERTO CANTIDAS MAYORES A UNO HADM '
		   INSERT INTO @PROCEDIMIENTOS1 (codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
					   ,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
					   ,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,cantidad,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador
					   )
		   SELECT @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION,REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5),'null',
			   LEFT(COALESCE(HADM.NOAUTORIZACION,'null'),30),left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),COALESCE(REPLACE(TGEN.DATO2,' ',''),HADM.VIAINGRESO,'02'),'01',
            grupoServicios= CASE WHEN COALESCE(SER.RIPS_GRUPO,'')  = '' THEN '01'  ELSE SER.RIPS_GRUPO  END, -- 20250702 -- STORRES SE CAMBIA PARA QUE ENVIE LOS CODIGOS CONFIGURADO
            codServicio   = CASE WHEN COALESCE(SER.RIPS_CODIGO,'') = '' THEN '325' ELSE SER.RIPS_CODIGO END, -- 20250702 -- STORRES SE CAMBIA PARA QUE ENVIE LOS CODIGOS CONFIGURADO
            '16',COALESCE(MED.TIPO_ID,'CC'), COALESCE(MED.IDMEDICO,DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT')),
            COALESCE(HADM.DXINGRESO,HADM.DXEGRESO), 
			   CASE WHEN LEN(COALESCE(HADM.DXSALIDA1,''))<4 THEN COALESCE(HADM.DXINGRESO,HADM.DXEGRESO) END,CASE WHEN COALESCE(HADM.COMPLICACION,HADM.DXINGRESO,HADM.DXEGRESO,'')='' THEN 'null' ELSE COALESCE(HADM.COMPLICACION,HADM.DXINGRESO,HADM.DXEGRESO,'') END,
            HPRED.VALOR,IIF(COALESCE(FTRDC.VLR_COPAGO,0)>0,'02','05'),HPRED.CANTIDAD, '04',IIF(COALESCE(HPRED.VALORCOPAGO,0)>0,(HPRED.VALORCOPAGO/HPRED.CANTIDAD),0),@N_FACTURA
		   FROM  FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION
					   INNER JOIN AFI  ON FTRDC.IDAFILIADO=AFI.IDAFILIADO
					   INNER JOIN HPRED ON FTRDC.NOPRESTACION=HPRED.NOPRESTACION AND FTRDC.NOITEM=HPRED.NOITEM
					   INNER JOIN HPRE  ON HADM.NOADMISION=HPRE.NOADMISION AND FTRDC.NOPRESTACION=HPRE.NOPRESTACION
					   INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO AND FTRDC.IDSERVICIO = SER.IDSERVICIO
					   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
					   INNER JOIN TGEN ON HADM.VIAINGRESO = TGEN.CODIGO AND TABLA = 'General' AND CAMPO = 'VIADEINGRESO' 
					   LEFT JOIN MED ON MED.IDMEDICO = CASE WHEN COALESCE(HPRE.IDMEDICO,'') = '' OR  LEN(COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA))<5 THEN DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT') 
                                                  ELSE CASE WHEN COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA)='' THEN HPRE.IDMEDICO  END END
		   WHERE FTRDC.CNSFTR=@CNSFCT
		   AND FTRDC.PROCEDENCIA='HADM'
		   AND HPRED.N_FACTURA=@N_FACTURA
		   AND COALESCE(HPRED.VALOR,0)>0
		   AND COALESCE(HPRED.NOCOBRABLE,0)=0
		   AND HPRED.CANTIDAD > 1
		   AND COALESCE(SER.CIRUGIA,0)=0
		   AND RIPS_CP.ARCHIVO='AP' 

         PRINT 'INSERTO CIRUGIAS'
         IF EXISTS (SELECT 1 FROM FTRDC INNER JOIN HPRED ON FTRDC.NOPRESTACION = HPRED.NOPRESTACION AND FTRDC.NOITEM = HPRED.NOITEM
                     WHERE FTRDC.CNSFTR = @CNSFCT AND FTRDC.PROCEDENCIA = 'HADM'
                        AND HPRED.N_FACTURA = @N_FACTURA AND COALESCE(HPRED.VALOR, 0) > 0 AND COALESCE(HPRED.NOCOBRABLE, 0) = 0
                        AND COALESCE(HPRED.IDCIRUGIA,'') <> ''
            )
         BEGIN
               INSERT INTO @PROCEDIMIENTOS (codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
					   ,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
					   ,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador
					   )
               SELECT @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION,REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5),'null',
			         LEFT(COALESCE(HADM.NOAUTORIZACION,'null'),30)  ,left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),COALESCE(REPLACE(TGEN.DATO2,' ',''),HADM.VIAINGRESO,'02'),'01',
                  grupoServicios= CASE WHEN COALESCE(SER.RIPS_GRUPO,'')  = '' THEN '01'  ELSE SER.RIPS_GRUPO  END, 
                  codServicio   = CASE WHEN COALESCE(SER.RIPS_CODIGO,'') = '' THEN '325' ELSE SER.RIPS_CODIGO END, 
                  '16',COALESCE(MED.TIPO_ID,'CC'),COALESCE(MED.IDMEDICO,DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT')),upper(COALESCE(HADM.DXINGRESO,HADM.DXEGRESO)), 
			         upper(CASE WHEN LEN(COALESCE(HADM.DXSALIDA1,''))<4 THEN COALESCE(HADM.DXINGRESO,HADM.DXEGRESO) ELSE HADM.DXSALIDA1 END), 
			         upper(CASE WHEN COALESCE(HADM.COMPLICACION,HADM.DXINGRESO,HADM.DXEGRESO,'')='' THEN 'null' ELSE COALESCE(HADM.COMPLICACION,HADM.DXINGRESO,HADM.DXEGRESO,'') END), 
                  SUM(FTRDC.VALOR),'05','04',0,@N_FACTURA
		         FROM  FTRDC INNER JOIN HADM    ON FTRDC.NOADMISION=HADM.NOADMISION
					            INNER JOIN AFI     ON FTRDC.IDAFILIADO=AFI.IDAFILIADO
					            INNER JOIN HPRED   ON FTRDC.NOPRESTACION=HPRED.NOPRESTACION AND FTRDC.NOITEM=HPRED.NOITEM
					            INNER JOIN HPRE    ON HADM.NOADMISION=HPRE.NOADMISION AND FTRDC.NOPRESTACION=HPRE.NOPRESTACION
					            INNER JOIN SER     ON HPRED.IDCIRUGIA=SER.IDSERVICIO --AND FTRDC.IDSERVICIO = SER.IDSERVICIO
					            INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS								 
					            INNER JOIN TGEN    ON HADM.VIAINGRESO = TGEN.CODIGO AND TABLA = 'General' AND CAMPO = 'VIADEINGRESO' 
					            LEFT JOIN MED      ON MED.IDMEDICO = CASE WHEN COALESCE(HPRE.IDMEDICO,'') = '' OR  COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA)='' THEN DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT') 
                                                        ELSE CASE WHEN COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA)='' THEN HPRE.IDMEDICO  END END
		         WHERE FTRDC.CNSFTR=@CNSFCT
		         AND FTRDC.PROCEDENCIA='HADM'
		         AND HPRED.N_FACTURA=@N_FACTURA
		         AND COALESCE(HPRED.VALOR,0)>0
				 AND COALESCE(SER.CIRUGIA,0)=1
		         AND COALESCE(HPRED.NOCOBRABLE,0)=0
		         AND RIPS_CP.ARCHIVO='AP' 
              -- and FTRDC.IDAFILIADO = '0200071805'
               GROUP BY HADM.IDAFILIADO,HADM.NOADMISION,REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5),LEFT(COALESCE(HADM.NOAUTORIZACION,'null'),30),
                        left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),COALESCE(REPLACE(TGEN.DATO2,' ',''),HADM.VIAINGRESO,'02'),
                        CASE WHEN COALESCE(SER.RIPS_GRUPO,'')  = '' THEN '01'  ELSE SER.RIPS_GRUPO  END,CASE WHEN COALESCE(SER.RIPS_CODIGO,'') = '' THEN '325' ELSE SER.RIPS_CODIGO END,
                        COALESCE(MED.TIPO_ID,'CC'),COALESCE(MED.IDMEDICO,DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT')),COALESCE(HADM.DXINGRESO,HADM.DXEGRESO),
                        CASE WHEN LEN(COALESCE(HADM.DXSALIDA1,''))<4 THEN COALESCE(HADM.DXINGRESO,HADM.DXEGRESO) ELSE HADM.DXSALIDA1 END,
                        CASE WHEN COALESCE(HADM.COMPLICACION,HADM.DXINGRESO,HADM.DXEGRESO,'')='' THEN 'null' ELSE COALESCE(HADM.COMPLICACION,HADM.DXINGRESO,HADM.DXEGRESO,'') END,
                        IIF(COALESCE(FTRDC.VLR_COPAGO,0)>0,'02','05')
                        ORDER BY IDAFILIADO
         END
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
				   SELECT @BANDERA=1
				   WHILE @BANDERA<=@CANTORI
				   BEGIN
					   INSERT INTO @PROCEDIMIENTOS (codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
									   ,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
									   ,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador
									   )
					   SELECT codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
									   ,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
									   ,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador
					   FROM @PROCEDIMIENTOS1
					   WHERE IDPROCE=@CNSCONSULTA
					   SELECT @BANDERA = @BANDERA+1
				   END
				   FETCH NEXT FROM JSPROCE_CURSOR    
				   INTO  @CNSCONSULTA,@CANTORI
			   END
			   CLOSE JSPROCE_CURSOR
			   DEALLOCATE JSPROCE_CURSOR

		   END
      END
	END
	
   PRINT 'ACTUALIZO FECHA DE INGRESOS Y SALIDAS'
   BEGIN
      UPDATE HADM SET FECHA=DATEADD(HOUR,DATEDIFF(HOUR,HADM.FECHA,FECHAALTAMED),HADM.FECHA)
		FROM FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION  
		WHERE FTRDC.CNSFTR=@CNSFCT 
		AND FTRDC.PROCEDENCIA='HADM'
      AND DATEDIFF(HOUR,HADM.FECHA,FECHAALTAMED)<0

      UPDATE HADM SET FECHA=DATEADD(MINUTE,DATEDIFF(MINUTE,HADM.FECHA,FECHAALTAMED),HADM.FECHA)
		FROM FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION  
		WHERE FTRDC.CNSFTR=@CNSFCT 
		AND FTRDC.PROCEDENCIA='HADM'
      AND DATEDIFF(MINUTE,HADM.FECHA,FECHAALTAMED)<0
   END
   PRINT 'CAPURO FECHA PERIODOS INICIO Y FINAL'
   BEGIN
   	DECLARE @F_FACTURA DATETIME
		DECLARE @F_FINPERIODO DATETIME
      DECLARE @F_INIPERIODO DATETIME
		SELECT @F_FACTURA=F_FACTURA,@F_FINPERIODO=FECHACAP_FIN,@F_INIPERIODO=FECHACAP_INI FROM FTR WHERE N_FACTURA=@N_FACTURA
   END
	PRINT  'URGENCIAS'
	BEGIN
         IF @MODO_ASISTENCIAL = 'Normal'
         BEGIN
		        INSERT INTO @URGENCIAS(codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,causaMotivoAtencion, codDiagnosticoPrincipal,codDiagnosticoPrincipalE,
								        codDiagnosticoRelacionadoE1,codDiagnosticoRelacionadoE2,codDiagnosticoRelacionadoE3,condicionDestinoUsuarioEgreso,
								        codDiagnosticoCausaMuerte,fechaEgreso)
		        SELECT DISTINCT @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION, 
              		  REPLACE(CONVERT(VARCHAR,CASE WHEN HADM.FECHA < @F_INIPERIODO THEN @F_INIPERIODO ELSE HADM.FECHA END,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,CASE WHEN HADM.FECHA < @F_INIPERIODO THEN @F_INIPERIODO ELSE HADM.FECHA END,108),5) ,
		              CASE WHEN COALESCE(TGEN.CHECK1,0)=1 THEN COALESCE(DATO1,'38') ELSE COALESCE(CODIGO,'38') END,COALESCE(HADM.DXINGRESO, HCA.IDDX), COALESCE(HADM.DXEGRESO, HCA.IDDX),COALESCE(HADM.DXSALIDA1,HCA.DX1),
		              COALESCE(DXSALIDA2, HCA.DX2),COALESCE(HADM.DXSALIDA3, HCA.DX3),CASE WHEN HADM.ESTADOPSALIDA=1 THEN '01' ELSE '02' END,
		              CASE WHEN HADM.ESTADOPSALIDA=1 THEN null ELSE CAUSABMUERTE END,
		              REPLACE(CONVERT(VARCHAR, CASE WHEN HADM.FECHAALTAMED IS NULL OR HADM.FECHAALTAMED > @F_FINPERIODO THEN @F_FINPERIODO ELSE HADM.FECHAALTAMED END ,102),'.','-')+' '+LEFT(CONVERT(VARCHAR, CASE WHEN HADM.FECHAALTAMED IS NULL OR HADM.FECHAALTAMED > @F_FINPERIODO THEN DATEADD(MINUTE,-2,DATEADD(DAY,1,@F_FINPERIODO)) ELSE HADM.FECHAALTAMED END,108),5) f_egreso 
		        FROM FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION  
				        LEFT JOIN HCA ON HADM.NOADMISION=HCA.NOADMISION AND COALESCE(HCA.IDDX,'')<>''
				        LEFT JOIN TGEN ON IIF(COALESCE(HADM.CAUSAEXTERNA,'')='','13',HADM.CAUSAEXTERNA) =TGEN.CODIGO AND TGEN.TABLA='General' AND TGEN.CAMPO='CAUSAEXTERNA'
		        WHERE FTRDC.CNSFTR=@CNSFCT 
		        AND FTRDC.PROCEDENCIA='HADM'
              AND EXISTS (SELECT 1 FROM TGEN WHERE TGEN.CODIGO = HADM.TIPOESTANCIA AND TGEN.CAMPO =  'CLASEHOSP'   AND  TGEN.DATO1 = 'U' AND TABLA = 'General')
		        AND DATEDIFF(HOUR,HADM.FECHA,COALESCE(HADM.FECHAALTAMED,DBO.FNK_GETDATE()))<=48
		        AND HCA.CLASE='HC'
		        AND HCA.PROCEDENCIA='QX'
		        AND HCA.CLASEPLANTILLA <> DBO.FNK_VALORVARIABLE('HCPLANTILLAEPI')
         END
	END
	PRINT 'HOSPITALIZACION'
	BEGIN 
		INSERT INTO @HOSPITALIZACION (codPrestador,IDAFILIADO,CONSECUTIVO,viaIngresoServicioSalud,fechaInicioAtencion,numAutorizacion,causaMotivoAtencion,codDiagnosticoPrincipal,
									codDiagnosticoPrincipalE,codDiagnosticoRelacionadoE1,codDiagnosticoRelacionadoE2,codDiagnosticoRelacionadoE3,
									codComplicacion,condicionDestinoUsuarioEgreso,codDiagnosticoCausaMuerte,fechaEgreso)

		SELECT DISTINCT  @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION,COALESCE(REPLACE(TGEN.DATO2,' ',''),HADM.VIAINGRESO,'01'),
		     REPLACE(CONVERT(VARCHAR,CASE WHEN HADM.FECHA < @F_INIPERIODO THEN @F_INIPERIODO ELSE HADM.FECHA END,102),'.','-')+' '+
              LEFT(CONVERT(VARCHAR,CASE WHEN HADM.FECHA < @F_INIPERIODO THEN @F_INIPERIODO ELSE HADM.FECHA END,108),5) 
			,HADM.NOAUTORIZACION
			,COALESCE(REPLACE(TGEN2.DATO1,' ',''),HADM.CAUSAEXTERNA,'38')
			,HADM.DXINGRESO
			,IIF(COALESCE(HADM.DXEGRESO,'')='',HADM.DXINGRESO,HADM.DXEGRESO)
            ,HADM.DXSALIDA1
            ,HADM.DXSALIDA2
            ,HADM.DXSALIDA3
			,COALESCE(HADM.COMPLICACION,HADM.DXINGRESO,HADM.DXEGRESO)
			,CASE WHEN HADM.ESTADOPSALIDA=1 THEN '01' ELSE '02' END
			,CASE WHEN HADM.ESTADOPSALIDA=1 THEN '' ELSE CAUSABMUERTE END
			,REPLACE(CONVERT(VARCHAR, CASE WHEN HADM.FECHAALTAMED IS NULL OR HADM.FECHAALTAMED > @F_FINPERIODO THEN @F_FINPERIODO								    ELSE HADM.FECHAALTAMED END ,102),'.','-')
		   +' '+LEFT(CONVERT(VARCHAR, CASE WHEN HADM.FECHAALTAMED IS NULL OR HADM.FECHAALTAMED > @F_FINPERIODO THEN DATEADD(MINUTE,-2,DATEADD(DAY,1,@F_FINPERIODO)) ELSE HADM.FECHAALTAMED END,108),5) f_egreso 
		FROM FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION
				LEFT JOIN TGEN ON HADM.VIAINGRESO = TGEN.CODIGO AND TABLA = 'General' AND CAMPO = 'VIADEINGRESO' 
				LEFT JOIN TGEN TGEN2 ON HADM.CAUSAEXTERNA = TGEN2.CODIGO AND TGEN2.TABLA = 'General' AND TGEN2.CAMPO = 'CAUSAEXTERNA' 
		WHERE FTRDC.CNSFTR=@CNSFCT 
		AND FTRDC.PROCEDENCIA='HADM'
		AND DATEDIFF(HOUR,HADM.FECHA,COALESCE(HADM.FECHAALTAMED,@F_FACTURA))>=48

	END      
	PRINT 'RECIEN NACIDOS'
	IF   (SELECT COALESCE(COUNT(*),0)
         FROM FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION 
                    INNER JOIN QXRCN ON HADM.NOADMISION=QXRCN.NOADMISION
			WHERE FTRDC.CNSFTR=@CNSFCT AND FTRDC.PROCEDENCIA='HADM'
			) <> 0
	BEGIN

         SELECT TOP 1 @PLANTILLA    = CLASEPLANTILLA  FROM HCAO WHERE PROCESO = 'RNACIDO' AND CAMPODESTINO = 'QXRCN:NRODOCUMENTO' 
         SELECT TOP 1 @CAMPO_NRODOCUMENTO = CAMPO     FROM HCAO WHERE PROCESO = 'RNACIDO' AND CAMPODESTINO = 'QXRCN:NRODOCUMENTO'
         SELECT TOP 1 @CAMPO_TIPODOC      = CAMPO     FROM HCAO WHERE PROCESO = 'RNACIDO' AND CAMPODESTINO = 'QXRCN:TIPODOC'
         SELECT TOP 1 @CAMPO_DESTINORN    = CAMPO     FROM HCAO WHERE PROCESO = 'RNACIDO' AND CAMPODESTINO = 'QXRCN:DESTINORN'
      
         INSERT INTO @TODAS_HC (CONSECUTIVO, NOADMISION)
         SELECT HCA.CONSECUTIVO, HCA.NOADMISION
         FROM HCA
         WHERE NOADMISION IN (SELECT HADM.NOADMISION 
                              FROM FTRDC INNER JOIN HADM ON FTRDC.NOADMISION = HADM.NOADMISION 
                              WHERE FTRDC.PROCEDENCIA = 'HADM' AND FTRDC.CNSFTR = @CNSFCT
                             )
         AND CLASEPLANTILLA = @PLANTILLA

         INSERT INTO @HC_POR_ADMISION (NOADMISION, CONSECUTIVOHCA, CAMPO_NRODOCUMENTO, CAMPO_TIPODOC, DESTINORN)
         SELECT HCP.NOADMISION, HCP.CONSECUTIVO,
                (SELECT TOP 1 COALESCE(ALFANUMERICO, '') FROM HCAD 
                 WHERE CONSECUTIVO = HCP.CONSECUTIVO 
                   AND CLASEPLANTILLA = @PLANTILLA 
                   AND CAMPO = @CAMPO_NRODOCUMENTO
                ) AS NRODOCUMENTO,
                (SELECT TOP 1 COALESCE(ALFANUMERICO, '') FROM HCAD 
                 WHERE CONSECUTIVO = HCP.CONSECUTIVO 
                   AND CLASEPLANTILLA = @PLANTILLA 
                   AND CAMPO = @CAMPO_TIPODOC
                ) AS TIPODOC,
                (SELECT TOP 1 COALESCE(ALFANUMERICO, '') FROM HCAD 
                 WHERE CONSECUTIVO = HCP.CONSECUTIVO 
                   AND CLASEPLANTILLA = @PLANTILLA 
                   AND CAMPO = @CAMPO_DESTINORN
                ) AS DESTINORN
         FROM @TODAS_HC HCP INNER JOIN (SELECT NOADMISION, MAX(CONSECUTIVO) AS MAXCONSEC
                                        FROM @TODAS_HC
                                        GROUP BY NOADMISION
                                       ) M ON HCP.NOADMISION = M.NOADMISION AND HCP.CONSECUTIVO = M.MAXCONSEC

		 INSERT INTO @RECIEN(codPrestador,IDAFILIADO,CONSECUTIVO,tipoDocumentoIdentificacion,numDocumentoIdentificacion,fechaNacimiento,
		 					      edadGestacional,numConsultasCPrenatal,codSexoBiologico,peso, codDiagnosticoPrincipal,condicionDestinoUsuarioEgreso,
		 					      codDiagnosticoCausaMuerte,fechaEgreso
		 					      )
		 SELECT @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION, 
              IIF(COALESCE(HC.CAMPO_TIPODOC,'') = '','CN',HC.CAMPO_TIPODOC),
              IIF(COALESCE(HC.CAMPO_NRODOCUMENTO,'') = '',QXRCN.NRODOCUMENTO,HC.CAMPO_NRODOCUMENTO),
		        REPLACE(CONVERT(VARCHAR,QXRCN.RNFECHANACE,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,QXRCN.RNFECHANACE,108),5),
		        CASE WHEN DBO.FNK_LIMPIATEXTO(QXRCN.CMPERIODOGES,'0-9') < 20 THEN 20
                   WHEN DBO.FNK_LIMPIATEXTO(QXRCN.CMPERIODOGES,'0-9') > 46 THEN 46
                   ELSE DBO.FNK_LIMPIATEXTO(QXRCN.CMPERIODOGES,'0-9') END,
              DBO.FNK_LIMPIATEXTO(QXRCN.CMCONTROLPRE,'0-9'),
              CASE WHEN QXRCN.RNSEXO = 'I ' THEN '03' 
                   WHEN QXRCN.RNSEXO = 'H ' THEN '01' 
                   WHEN QXRCN.RNSEXO = 'M ' THEN '02'
              ELSE '03' END ,
		        CASE WHEN DBO.FNK_LIMPIATEXTO(QXRCN.RNPESO,'0-9') < 500  THEN 500
                   WHEN DBO.FNK_LIMPIATEXTO(QXRCN.RNPESO,'0-9') > 5000 THEN 5000
                   ELSE DBO.FNK_LIMPIATEXTO(QXRCN.RNPESO,'0-9') END,
              QXRCN.RNDX,
              CASE WHEN COALESCE(HC.DESTINORN,'') = '' THEN CASE WHEN QXRCN.ESTADORN = 1 THEN '01' ELSE '02' END
                   ELSE HC.DESTINORN
              END,
		        CASE WHEN COALESCE(QXRCN.CMCAUSAMUERTE,'') = '' THEN 'null'ELSE QXRCN.CMCAUSAMUERTE END,
              REPLACE(CONVERT(VARCHAR, CASE WHEN HADM.FECHAALTAMED IS NULL OR HADM.FECHAALTAMED > @F_FINPERIODO THEN @F_FINPERIODO ELSE HADM.FECHAALTAMED END ,102),'.','-')
		         +' '+LEFT(CONVERT(VARCHAR, CASE WHEN HADM.FECHAALTAMED IS NULL OR HADM.FECHAALTAMED > @F_FINPERIODO THEN DATEADD(MINUTE,-2,DATEADD(DAY,1,@F_FINPERIODO)) ELSE HADM.FECHAALTAMED END,108),5) f_egreso 	
		 FROM FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION AND FTRDC.PROCEDENCIA='HADM'
		 			   INNER JOIN QXRCN ON HADM.NOADMISION=QXRCN.NOADMISION
                  INNER JOIN @HC_POR_ADMISION HC ON FTRDC.NOADMISION = HC.NOADMISION
		 WHERE FTRDC.CNSFTR=@CNSFCT
		 AND FTRDC.PROCEDENCIA='HADM'
       GROUP BY HADM.IDAFILIADO,HADM.NOADMISION,REPLACE(CONVERT(VARCHAR,QXRCN.RNFECHANACE,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,QXRCN.RNFECHANACE,108),5),
		          QXRCN.CMPERIODOGES,QXRCN.CMCONTROLPRE,QXRCN.RNSEXO,QXRCN.RNPESO,QXRCN.RNDX,QXRCN.ESTADORN, QXRCN.CMCAUSAMUERTE, QXRCN.NRODOCUMENTO,
		          REPLACE(CONVERT(VARCHAR,HADM.FECHAALTAMED,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HADM.FECHAALTAMED,108),5), HC.CAMPO_TIPODOC,HC.CAMPO_NRODOCUMENTO,
                REPLACE(CONVERT(VARCHAR, CASE WHEN HADM.FECHAALTAMED IS NULL OR HADM.FECHAALTAMED > @F_FINPERIODO THEN @F_FINPERIODO ELSE HADM.FECHAALTAMED END ,102),'.','-')
		          +' '+LEFT(CONVERT(VARCHAR, CASE WHEN HADM.FECHAALTAMED IS NULL OR HADM.FECHAALTAMED > @F_FINPERIODO THEN DATEADD(MINUTE,-2,DATEADD(DAY,1,@F_FINPERIODO)) ELSE HADM.FECHAALTAMED END,108),5),
                HC.DESTINORN
		 
	END
	PRINT 'OTROS SERVICIOS'
	BEGIN
      PRINT 'OTROS SERVICIOS CIT'
      BEGIN
		INSERT INTO @OTROSSER(codPrestador,IDAFILIADO,CONSECUTIVO,numAutorizacion,idMIPRES,fechaSuministroTecnologia,tipoOS,codTecnologiaSalud,nomTecnologiaSalud
							,cantidadOS,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitOS,vrServicio,conceptoRecaudo,tipoPagoModerador
							,valorPagoModerador,numFEVPagoModerador)
		SELECT @IDPRESTADOR,CIT.IDAFILIADO,CIT.CONSECUTIVO,numAutorizacion=CIT.NOAUTORIZACION,'null',
			fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,CIT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,CIT.FECHA,108),5),
			tipoOS='04',codTecnologiaSalud=left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),20),nomTecnologiaSalud=LEFT(dbo.FNK_LIMPIATEXTO(SER.DESCSERVICIO,'0-9 A-Z();:.,'),60),
			cantidadOS=IIF(COALESCE(CIT.CANTIDADC,1)=0,1,COALESCE(CIT.CANTIDADC,1)),tipoDocumentoIdentificacion=AFI.TIPO_DOC,
			numDocumentoIdentificacion=AFI.DOCIDAFILIADO,COALESCE(CIT.VALORTOTAL,0),COALESCE(CIT.VALORTOTAL,0),IIF(COALESCE(
			CIT.VALORCOPAGO,0)>0,'02',@conceptoRecaudo)
         ,tipoPagoModerador='04'
         ,COALESCE(CIT.VALORCOPAGO,0),
			@N_FACTURA
		FROM FTRDC INNER JOIN CIT ON FTRDC.NOADMISION=CIT.CONSECUTIVO
					INNER JOIN AFI ON FTRDC.IDAFILIADO=AFI.IDAFILIADO
					INNER JOIN SER ON CIT.IDSERVICIO=SER.IDSERVICIO
					INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
		WHERE FTRDC.CNSFTR=@CNSFCT
		AND FTRDC.PROCEDENCIA IN('CIT','ONCO')
		--AND CIT.N_FACTURA=@N_FACTURA
		AND RIPS_CP.ARCHIVO='AT'
      END
      PRINT 'OTROS SERVICIOS AUT'
      BEGIN
		INSERT INTO @OTROSSER(codPrestador,IDAFILIADO,CONSECUTIVO,numAutorizacion,idMIPRES,fechaSuministroTecnologia,tipoOS,codTecnologiaSalud,nomTecnologiaSalud
							,cantidadOS,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitOS,vrServicio,conceptoRecaudo,tipoPagoModerador
							,valorPagoModerador,numFEVPagoModerador)
		SELECT @IDPRESTADOR,AUT.IDAFILIADO,AUT.NOAUT,numAutorizacion=AUT.NUMAUTORIZA,'null',
			fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,AUT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,AUT.FECHA,108),5),
			tipoOS='04',codTecnologiaSalud=left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),20),nomTecnologiaSalud=LEFT( dbo.FNK_LIMPIATEXTO(SER.DESCSERVICIO,'0-9 A-Z();:.,'),60),
			cantidadOS=COALESCE(AUTD.CANTIDAD,1),tipoDocumentoIdentificacion=MED.TIPO_ID,
			numDocumentoIdentificacion=MED.IDMEDICO,
			COALESCE(AUTD.VALOR,0),
			COALESCE(AUTD.VALOR,0)*COALESCE(AUTD.CANTIDAD, 0),
			IIF(COALESCE(AUT.VALORCOPAGO,0)>0,'02',@conceptoRecaudo),
			tipoPagoModerador='04',
		--	COALESCE(FTRDC.VLR_COPAGO,0),
		    COALESCE(AUTD.VALORCOPAGO,0),
			@N_FACTURA
		   FROM FTRDC INNER JOIN AUTD    ON FTRDC.NOADMISION=AUTD.IDAUT AND FTRDC.NOITEM=AUTD.NO_ITEM
					INNER JOIN AUT    ON AUTD.IDAUT= AUT.IDAUT --SE CAMBIA POR IDAUT YA QUE EN FTRDC EN NOADMISION QUEDA REGISTRADO IDAUT STORRES 14/07/2025				
					INNER JOIN SER     ON AUTD.IDSERVICIO=SER.IDSERVICIO AND FTRDC.IDSERVICIO = SER.IDSERVICIO
					INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
					LEFT  JOIN MED		 ON MED.IDMEDICO    = IIF(COALESCE(AUT.IDMEDICOSOLICITA,'')='',DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT'),AUT.IDMEDICOSOLICITA) 
		WHERE FTRDC.CNSFTR=@CNSFCT
		AND FTRDC.PROCEDENCIA='AUT'
		AND AUTD.N_FACTURA=@N_FACTURA
		AND RIPS_CP.ARCHIVO='AT'
      END
      PRINT 'OTROS SERVICIOS HADM'
      BEGIN
		INSERT INTO @OTROSSER(codPrestador,IDAFILIADO,CONSECUTIVO,numAutorizacion,idMIPRES,fechaSuministroTecnologia,tipoOS,codTecnologiaSalud,nomTecnologiaSalud
							,cantidadOS,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitOS,vrServicio,conceptoRecaudo,tipoPagoModerador
							,valorPagoModerador,numFEVPagoModerador)
		SELECT @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION                                                                   
			,numAutorizacion=HADM.NOAUTORIZACION
			,'null'                                                                            
			,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5)
			,tipoOS='04'
			,codTecnologiaSalud=CASE WHEN RIPS_CP.IDCONCEPTORIPS=DBO.FNK_VALORVARIABLE('IDMATERIALESRIPS')THEN SER.IDSERVICIO ELSE left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),20) END
			,nomTecnologiaSalud=LEFT( dbo.FNK_LIMPIATEXTO(SER.DESCSERVICIO,'0-9 A-Z();:.,'),60)
			,cantidadOS=CONVERT(INT,COALESCE(HPRED.CANTIDAD,1))
			,tipoDocumentoIdentificacion=MED.TIPO_ID
			,numDocumentoIdentificacion=MED.IDMEDICO
			,CONVERT(DECIMAL(14,2),COALESCE(HPRED.VALOR,0))
			,CONVERT(DECIMAL(14,2),COALESCE(HPRED.VALOR*HPRED.CANTIDAD,0))
			,IIF(COALESCE(HPRED.VALORCOPAGO,0)>0 AND COALESCE(HPRED.IDCIRUGIA,'')='' ,'02',@conceptoRecaudo)
			,tipoPagoModerador='04'
			,CONVERT(DECIMAL(14,2),COALESCE(HPRED.VALORCOPAGO,0))  --- CONDICIONAMIENTO A QUE SI ES CIRUGIA ESTE COPAGO YA LO ESTA TOMANDO EN EL AP 15-07-2025 STORRES
			,@N_FACTURA                                                                       
			FROM FTRDC INNER JOIN HPRED ON FTRDC.NOPRESTACION=HPRED.NOPRESTACION AND HPRED.NOITEM = FTRDC.NOITEM
					   INNER JOIN  HPRE ON HPRED.NOPRESTACION=HPRE.NOPRESTACION
					   INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION
				INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO --AND FTRDC.IDSERVICIO = SER.IDSERVICIO
				INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
				LEFT JOIN MED ON MED.IDMEDICO= CASE WHEN COALESCE(IIF(HADM.IDMEDICOALTA='',NULL,HADM.IDMEDICOALTA),IIF(HADM.IDMEDICOTRA='',NULL,HADM.IDMEDICOTRA),HADM.IDMEDICOING)='' THEN HPRE.IDMEDICO ELSE COALESCE(IIF(HADM.IDMEDICOALTA='',NULL,HADM.IDMEDICOALTA),IIF(HADM.IDMEDICOTRA='',NULL,HADM.IDMEDICOTRA),HADM.IDMEDICOING) END
			--	LEFT JOIN HCA ON HPRE.CONSECUTIVOHCA=HCA.CONSECUTIVO
			WHERE FTRDC.CNSFTR=@CNSFCT
			AND FTRDC.PROCEDENCIA='HADM'
			AND HPRED.N_FACTURA=@N_FACTURA
			AND RIPS_CP.ARCHIVO='AT'   
			AND COALESCE(HPRED.VALOR,0)>0
			AND COALESCE(HPRED.NOCOBRABLE,0)=0
      END
	END 
	
	PRINT 'ASOCIANDO IDUSUARIO'
	BEGIN
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
	END


   PRINT 'Actualizo modalida de pago'

   --UPDATE @USUARIOS SET @TIPOUSU='03' WHERE 1=1

	PRINT 'ACTUALIZO TABLA DIAGNOSTICOS '
	BEGIN
		UPDATE @DX SET NIDDX=MDX.DESCRIPCION
		FROM @DX DX INNER JOIN MDX ON DX.IDDX=MDX.IDDX

		UPDATE @DX SET NDX1=MDX.DESCRIPCION
		FROM @DX DX INNER JOIN MDX ON DX.DX1=MDX.IDDX

		UPDATE @DX SET NDX2=MDX.DESCRIPCION
		FROM @DX DX INNER JOIN MDX ON DX.DX2=MDX.IDDX

		UPDATE @DX SET NDX3=MDX.DESCRIPCION
		FROM @DX DX INNER JOIN MDX ON DX.DX3=MDX.IDDX

		PRINT 'Diagnosticos consultas'

      DELETE @DX WHERE LEN(COALESCE(IDDX,''))<4

	END
	PRINT 'Actualización de LAS TABLAS con los diagnósticos principales y relacionados en un solo bloque'
	BEGIN
		PRINT 'Diagnosticos Consultas'
		UPDATE AC
		SET 
			AC.codDiagnosticoPrincipal = CASE WHEN COALESCE(AC.codDiagnosticoPrincipal, '') = '' THEN IIF(COALESCE(DX.IDDX,'')='','Z000',DX.IDDX) ELSE AC.codDiagnosticoPrincipal END,
			AC.tipoDiagnosticoPrincipal = IIF(COALESCE(DX.TIPODX,'')='','01',DX.TIPODX),
			AC.codDiagnosticoRelacionado1 = CASE WHEN COALESCE(AC.codDiagnosticoRelacionado1, '') = '' THEN DX.DX1 ELSE AC.codDiagnosticoRelacionado1 END,
			AC.codDiagnosticoRelacionado2 = CASE WHEN COALESCE(AC.codDiagnosticoRelacionado2, '') = '' THEN DX.DX2 ELSE AC.codDiagnosticoRelacionado2 END,
			AC.codDiagnosticoRelacionado3 = CASE WHEN COALESCE(AC.codDiagnosticoRelacionado3, '') = '' THEN DX.DX3 ELSE AC.codDiagnosticoRelacionado3 END
		FROM @CONSULTAS AC
		LEFT JOIN @DX DX ON AC.IDAFILIADO = DX.IDAFILIADO
		WHERE COALESCE(AC.codDiagnosticoPrincipal, '') = '' 
			OR COALESCE(AC.tipoDiagnosticoPrincipal, '') =''
			OR COALESCE(AC.codDiagnosticoRelacionado2, '') = ''
			OR COALESCE(AC.codDiagnosticoRelacionado3, '') = '';
      
      UPDATE @CONSULTAS SET tipoDiagnosticoPrincipal='01' WHERE LEN(COALESCE(tipoDiagnosticoPrincipal,''))<2
		PRINT 'Diagnosticos medicamentos'
		UPDATE AM
		SET 
			AM.codDiagnosticoPrincipal = CASE WHEN COALESCE(AM.codDiagnosticoPrincipal, '') = '' THEN COALESCE(DX.IDDX,'Z000') ELSE AM.codDiagnosticoPrincipal END,
			AM.codDiagnosticoRelacionado = CASE WHEN COALESCE(AM.codDiagnosticoRelacionado, '') = '' THEN DX.DX1 ELSE AM.codDiagnosticoRelacionado END
		FROM @MEDICAMENTOS AM
		INNER JOIN @DX DX ON AM.IDAFILIADO = DX.IDAFILIADO
		WHERE COALESCE(AM.codDiagnosticoPrincipal,'')='' 
      OR COALESCE(AM.codDiagnosticoRelacionado,'')=''
      
      UPDATE @MEDICAMENTOS SET codDiagnosticoPrincipal=UPPER(codDiagnosticoPrincipal),codDiagnosticoRelacionado=UPPER(codDiagnosticoRelacionado)

		PRINT 'Diagnosticos procedimientos'
		UPDATE AP
		SET 
			AP.codDiagnosticoPrincipal = CASE WHEN COALESCE(AP.codDiagnosticoPrincipal, '') = '' OR AP.codDiagnosticoPrincipal IS NULL OR AP.codDiagnosticoPrincipal ='null' THEN IIF(COALESCE(DX.IDDX,'')='','Z000',DX.IDDX) ELSE AP.codDiagnosticoPrincipal END,
			AP.codDiagnosticoRelacionado = CASE WHEN COALESCE(AP.codDiagnosticoRelacionado, '') = '' OR AP.codDiagnosticoRelacionado ='null' THEN IIF(COALESCE(DX.DX1,'')='',DX.IDDX,DX.DX1) ELSE AP.codDiagnosticoRelacionado END,
			AP.codComplicacion = CASE WHEN COALESCE(AP.codComplicacion, '') = '' OR AP.codComplicacion ='null' THEN IIF(COALESCE(DX.DX1,'')='',DX.IDDX,DX.DX1) ELSE AP.codComplicacion END
		FROM @PROCEDIMIENTOS AP
		INNER JOIN @DX DX ON AP.IDAFILIADO = DX.IDAFILIADO
		WHERE COALESCE(AP.codDiagnosticoPrincipal,'')='' 
      OR AP.codDiagnosticoPrincipal IS NULL
      OR AP.codDiagnosticoPrincipal ='null'
      OR COALESCE(AP.codDiagnosticoRelacionado,'')='' 
      OR AP.codDiagnosticoRelacionado ='null' 
      OR COALESCE(AP.codComplicacion,'')=''
      OR COALESCE(AP.codComplicacion,'')='null'

      UPDATE @PROCEDIMIENTOS SET codDiagnosticoPrincipal='Z000' WHERE (codDiagnosticoPrincipal IS NULL OR LEN(COALESCE(codDiagnosticoPrincipal,''))<4)
      UPDATE @PROCEDIMIENTOS SET codDiagnosticoPrincipal=UPPER(codDiagnosticoPrincipal),codDiagnosticoRelacionado=UPPER(codDiagnosticoRelacionado)
      
		PRINT 'URGENCIAS'
		UPDATE AU
		SET 
			AU.codDiagnosticoPrincipal = CASE WHEN COALESCE(AU.codDiagnosticoPrincipal, '') = '' THEN DX.IDDX ELSE AU.codDiagnosticoPrincipal END,
			AU.codDiagnosticoPrincipalE = CASE WHEN COALESCE(AU.codDiagnosticoPrincipalE, '') = '' THEN DX.IDDX ELSE AU.codDiagnosticoPrincipalE END,
			AU.codDiagnosticoRelacionadoE1 = CASE WHEN COALESCE(AU.codDiagnosticoRelacionadoE1, '') = '' THEN 'null' ELSE AU.codDiagnosticoRelacionadoE1 END,
			AU.codDiagnosticoRelacionadoE2 = CASE WHEN COALESCE(AU.codDiagnosticoRelacionadoE2, '') = '' THEN 'null' ELSE AU.codDiagnosticoRelacionadoE2 END,
			AU.codDiagnosticoRelacionadoE3 = CASE WHEN COALESCE(AU.codDiagnosticoRelacionadoE3, '') = '' THEN 'null' ELSE AU.codDiagnosticoRelacionadoE3 END
		FROM @URGENCIAS AU
		INNER JOIN @DX DX ON AU.IDAFILIADO = DX.IDAFILIADO
		WHERE COALESCE(DX.IDDX, '') <> '';
      
      UPDATE @URGENCIAS SET codDiagnosticoPrincipalE=UPPER(codDiagnosticoPrincipalE),codDiagnosticoPrincipal=UPPER(codDiagnosticoPrincipal),codDiagnosticoRelacionadoE1=UPPER(codDiagnosticoRelacionadoE1)

		PRINT 'HOSPITALIZACION'

		UPDATE AH
		SET 
			AH.codDiagnosticoPrincipal = CASE WHEN COALESCE(AH.codDiagnosticoPrincipal, '') = ''  OR  AH.codDiagnosticoPrincipal IS NULL  THEN DX.IDDX ELSE AH.codDiagnosticoPrincipal END,
         AH.codDiagnosticoPrincipalE = CASE WHEN COALESCE(AH.codDiagnosticoPrincipalE, '') = '' OR AH.codDiagnosticoPrincipalE ='null' THEN IIF(COALESCE(DX.DX1,'')='',DX.IDDX,DX.DX1) ELSE AH.codDiagnosticoPrincipalE END,
			AH.codDiagnosticoRelacionadoE1 = CASE WHEN COALESCE(AH.codDiagnosticoRelacionadoE1, '') = '' OR AH.codDiagnosticoRelacionadoE1 IS NULL THEN IIF(COALESCE(DX.DX1,'')='',DX.IDDX,DX.DX1) ELSE AH.codDiagnosticoRelacionadoE1 END,
			AH.codDiagnosticoRelacionadoE2 = CASE WHEN COALESCE(AH.codDiagnosticoRelacionadoE2, '') = '' THEN  IIF(COALESCE(DX.DX2,'')='',DX.IDDX,DX.DX2) ELSE AH.codDiagnosticoRelacionadoE2 END,
			AH.codDiagnosticoRelacionadoE3 = CASE WHEN COALESCE(AH.codDiagnosticoRelacionadoE3, '') = '' THEN  IIF(COALESCE(DX.DX3,'')='',DX.IDDX,DX.DX3) ELSE AH.codDiagnosticoRelacionadoE3 END
		FROM @HOSPITALIZACION AH
		INNER JOIN @DX DX ON AH.IDAFILIADO = DX.IDAFILIADO
		WHERE COALESCE(AH.codDiagnosticoPrincipal, '') = ''
      OR AH.codDiagnosticoPrincipal IS NULL
      OR COALESCE(AH.codDiagnosticoRelacionadoE1, '') = ''
      OR AH.codDiagnosticoRelacionadoE1 IS NULL

      UPDATE @HOSPITALIZACION SET codDiagnosticoPrincipal=UPPER(codDiagnosticoPrincipal),codDiagnosticoRelacionadoE1=UPPER(codDiagnosticoRelacionadoE1)

	END
	   PRINT 'TERMINE DE PREPARAR LOS DATOS'
	   
      DECLARE @IDAFILIADOANT VARCHAR(20)=''
      DECLARE @IDAFILIADO VARCHAR(20)
      DECLARE @CNSX INT 
      DECLARE @ID INT 

      INSERT INTO @CONSULTAS2 (codPrestador,	consecutivo,	IDAFILIADO,	fechaInicioAtencion,	numAutorizacion ,	codConsulta ,
	                              modalidadGrupoServicioTecSal ,	grupoServicios ,	codServicio,	finalidadTecnologiaSalud ,	causaMotivoAtencion ,
	                              codDiagnosticoPrincipal ,	codDiagnosticoRelacionado1,	codDiagnosticoRelacionado2,	codDiagnosticoRelacionado3,	tipoDiagnosticoPrincipal ,
	                              vrServicio ,	tipoPagoModerador ,	tipoDocumentoIdentificacion ,	numDocumentoIdentificacion ,	conceptoRecaudo ,	valorPagoModerador ,	numFEVPagoModerador ,
	                              usuarioId  ,   ID ,   xconsecutivo )
      SELECT codPrestador,	consecutivo,	IDAFILIADO,	fechaInicioAtencion,	numAutorizacion ,	codConsulta ,
	      modalidadGrupoServicioTecSal ,	grupoServicios ,	codServicio,	finalidadTecnologiaSalud ,	causaMotivoAtencion ,
	      codDiagnosticoPrincipal ,	codDiagnosticoRelacionado1,	codDiagnosticoRelacionado2,	codDiagnosticoRelacionado3,	tipoDiagnosticoPrincipal ,
	      vrServicio ,	tipoPagoModerador ,	tipoDocumentoIdentificacion ,	numDocumentoIdentificacion ,	conceptoRecaudo ,	valorPagoModerador ,	numFEVPagoModerador ,
	      usuarioId  ,   ID , 
         ROW_NUMBER() OVER(PARTITION BY IDAFILIADO ORDER BY IDAFILIADO ASC)
     FROM @CONSULTAS
      --PROCEDIMIENTOS

      INSERT INTO @PROCEDIMIENTOS2(	codPrestador,	IDAFILIADO,	CONSECUTIVO,	fechaInicioAtencion,	idMIPRES,	numAutorizacion,	codProcedimiento,
	viaIngresoServicioSalud,	modalidadGrupoServicioTecSal,	grupoServicios,	codServicio,	finalidadTecnologiaSalud ,	tipoDocumentoIdentificacion,
	numDocumentoIdentificacion,	codDiagnosticoPrincipal,	codDiagnosticoRelacionado ,	codComplicacion,	vrServicio, 	conceptoRecaudo ,	tipoPagoModerador,
	valorPagoModerador,	numFEVPagoModerador,	usuarioId,   ID ,   xconsecutivo)
   SELECT codPrestador,	IDAFILIADO,	CONSECUTIVO,	fechaInicioAtencion,	idMIPRES,	numAutorizacion,	codProcedimiento,
	viaIngresoServicioSalud,	modalidadGrupoServicioTecSal,	grupoServicios,	codServicio,	finalidadTecnologiaSalud ,	tipoDocumentoIdentificacion,
	numDocumentoIdentificacion,	codDiagnosticoPrincipal,	codDiagnosticoRelacionado ,	codComplicacion,	vrServicio, 	conceptoRecaudo ,	tipoPagoModerador,
	valorPagoModerador,	numFEVPagoModerador,	usuarioId,   ID ,   ROW_NUMBER() OVER(PARTITION BY IDAFILIADO ORDER BY IDAFILIADO ASC)
   FROM @PROCEDIMIENTOS

    --MEDICAMENTOS

      INSERT INTO @MEDICAMENTOS2(codPrestador ,	numAutorizacion, IDAFILIADO ,	CONSECUTIVO,	idMIPRES ,	fechaDispensAdmon,	codDiagnosticoPrincipal ,	codDiagnosticoRelacionado,
	               tipoMedicamento,	codTecnologiaSalud,	nomTecnologiaSalud,	concentracionMedicamento ,	unidadMedida ,	formaFarmaceutica,	unidadMinDispensa ,
	               cantidadMedicamento,	diasTratamiento,	tipoDocumentoIdentificacion,	numDocumentoIdentificacion,	vrUnitMedicamento,	vrServicio,	conceptoRecaudo,
	               tipoPagoModerador,	valorPagoModerador,	numFEVPagoModerador ,	usuarioId ,   ID  ,   xconsecutivo)
      SELECT codPrestador , numAutorizacion,	IDAFILIADO ,	CONSECUTIVO,	idMIPRES ,	fechaDispensAdmon,	codDiagnosticoPrincipal ,	codDiagnosticoRelacionado,
	         tipoMedicamento,	codTecnologiaSalud,	nomTecnologiaSalud,	concentracionMedicamento ,	unidadMedida ,	formaFarmaceutica,	unidadMinDispensa ,
	         cantidadMedicamento,	diasTratamiento,	tipoDocumentoIdentificacion,	numDocumentoIdentificacion,	vrUnitMedicamento,	vrServicio,	conceptoRecaudo,
	         tipoPagoModerador,	valorPagoModerador,	numFEVPagoModerador ,	usuarioId ,   ID  ,    ROW_NUMBER() OVER(PARTITION BY IDAFILIADO ORDER BY IDAFILIADO ASC)
      FROM @MEDICAMENTOS

    --OTROS SERVICIOS

     INSERT INTO @OTROSSER2(codPrestador,	IDAFILIADO ,	CONSECUTIVO,	numAutorizacion,	idMIPRES,	fechaSuministroTecnologia,	tipoOS,	
               codTecnologiaSalud,nomTecnologiaSalud ,	cantidadOS,	tipoDocumentoIdentificacion,	numDocumentoIdentificacion,
               vrUnitOS, 	vrServicio, 	conceptoRecaudo,	tipoPagoModerador, valorPagoModerador,	numFEVPagoModerador,	usuarioId ,
               ID , xconsecutivo)
      SELECT codPrestador,	IDAFILIADO ,	CONSECUTIVO,	numAutorizacion,	idMIPRES,	fechaSuministroTecnologia,	tipoOS,	
            codTecnologiaSalud,nomTecnologiaSalud ,	cantidadOS,	tipoDocumentoIdentificacion,	numDocumentoIdentificacion,
            vrUnitOS, 	vrServicio, 	conceptoRecaudo,	tipoPagoModerador, valorPagoModerador,	numFEVPagoModerador,	usuarioId ,
            ID , ROW_NUMBER() OVER(PARTITION BY IDAFILIADO ORDER BY IDAFILIADO ASC)
       FROM @OTROSSER

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

     IF EXISTS(SELECT * FROM @PROCEDIMIENTOS2 WHERE tipoDocumentoIdentificacion IS NULL)
     BEGIN
        UPDATE @PROCEDIMIENTOS2 SET tipoDocumentoIdentificacion=AFI.TIPO_DOC,numDocumentoIdentificacion=AFI.DOCIDAFILIADO
        FROM @PROCEDIMIENTOS2 AP INNER JOIN AFI ON AP.IDAFILIADO=AFI.IDAFILIADO
        WHERE AP.tipoDocumentoIdentificacion IS NULL
     END

 
     DECLARE @MODE BIT
     SELECT @MODE=IIF(DBO.FNK_VALORVARIABLE('CUOTMODE_ENFACTFINAN')='SI',1,0)
     
     DECLARE @MODERADORAS AS TABLE (NIVEL INT,VALOR DECIMAL(14,2))

     INSERT INTO @MODERADORAS(NIVEL,VALOR)
     SELECT  ESCALASE,VALOR FROM MOCCD WHERE TIPODEPAGO='Moderadora'

     UPDATE @CONSULTAS2 SET vrServicio=0,valorPagoModerador=CASE WHEN @CPROPIO=1 THEN 0 ELSE valorPagoModerador END
                           ,conceptoRecaudo=CASE WHEN @CPROPIO=1 OR valorPagoModerador =0 THEN '05' 
                                                 ELSE CASE WHEN @MODE=0 THEN @conceptoRecaudo 
                                                           ELSE CASE WHEN  valorPagoModerador IN (SELECT VALOR FROM @MODERADORAS) THEN '02' 
                                                                     ELSE '01' 
                                                                END 
                                                      END  
                                             END
                           WHERE 1=1
     UPDATE @PROCEDIMIENTOS2 SET vrServicio=0 
                               ,valorPagoModerador=CASE WHEN @CPROPIO=1 THEN 0 ELSE valorPagoModerador END
                               ,conceptoRecaudo =CASE WHEN @CPROPIO=1 OR valorPagoModerador =0 THEN '05' 
                                                      ELSE CASE WHEN @MODE=0 THEN @conceptoRecaudo 
                                                                ELSE CASE WHEN  valorPagoModerador IN (SELECT VALOR FROM @MODERADORAS) THEN '02' 
                                                                          ELSE '01' 
                                                                      END 
                                                           END 
                                                  END 
     WHERE 1=1

     UPDATE @MEDICAMENTOS2 SET vrServicio=0,vrUnitMedicamento=0,valorPagoModerador=CASE WHEN @CPROPIO=1 THEN 0 ELSE valorPagoModerador END,
                           conceptoRecaudo=CASE WHEN @CPROPIO=1 OR valorPagoModerador =0 THEN '05' ELSE CASE WHEN @MODE=0
                           THEN @conceptoRecaudo ELSE
                           CASE WHEN  valorPagoModerador IN (SELECT VALOR FROM @MODERADORAS) THEN '02' ELSE '01' END END END WHERE 1=1
     UPDATE @OTROSSER2 SET vrServicio=0,vrUnitOS=0,valorPagoModerador=CASE WHEN @CPROPIO=1 THEN 0 ELSE valorPagoModerador END,
                           conceptoRecaudo=CASE WHEN @CPROPIO=1 OR valorPagoModerador =0 THEN '05' ELSE CASE WHEN @MODE=0
                           THEN @conceptoRecaudo ELSE
                           CASE WHEN  valorPagoModerador IN (SELECT VALOR FROM @MODERADORAS) THEN '02' ELSE '01' END END END  WHERE 1=1


     IF EXISTS(SELECT * FROM @CONSULTAS2 WHERE codDiagnosticoPrincipal IS NULL)
     BEGIN
        UPDATE @CONSULTAS2 SET codDiagnosticoPrincipal='Z000',tipoDiagnosticoPrincipal='01' WHERE codDiagnosticoPrincipal IS NULL
     END

     --return
     --IF @N_FACTURA = 'ASFE99566'
     --BEGIN
     --   SELECT 'AC', SUM(valorPagoModerador) FROM @CONSULTAS      UNION ALL  --group by conceptorecaudo union all
     --   SELECT 'AP', SUM(valorPagoModerador) FROM @PROCEDIMIENTOS UNION ALL --group by conceptorecaudo union all 
     --   SELECT 'AM', SUM(valorPagoModerador) FROM @MEDICAMENTOS   UNION ALL --group by conceptorecaudo union all
     --   SELECT 'AT', SUM(valorPagoModerador) FROM @OTROSSER        --group by conceptorecaudo
     --   --SELECT 'AU', COUNT(*) FROM @URGENCIAS
     --   --SELECT 'AH', COUNT(*) FROM @HOSPITALIZACION
     --   --SELECT 'AH', COUNT(*) FROM @RECIEN

     -- --  SELECT * FROM @PROCEDIMIENTOS where coalesce(valorPagoModerador,0) > 0  AND conceptoRecaudo = '05'

     --RETURN
     --END
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
										upper(c.codDiagnosticoPrincipal) codDiagnosticoPrincipal,
										upper(ISNULL( NULLIF(c.codDiagnosticoRelacionado1,''), 'null')) codDiagnosticoRelacionado1,
										-- c.codDiagnosticoRelacionado2,
										upper(ISNULL( NULLIF(c.codDiagnosticoRelacionado2,''), 'null')) codDiagnosticoRelacionado2,
										-- c.codDiagnosticoRelacionado3,
										upper(ISNULL( NULLIF(c.codDiagnosticoRelacionado3,''), 'null')) codDiagnosticoRelacionado3,
										c.tipoDiagnosticoPrincipal,
										c.tipoDocumentoIdentificacion,
										c.numDocumentoIdentificacion,
										c.vrServicio,
										c.conceptoRecaudo,
										c.valorPagoModerador,
										c.numFEVPagoModerador,
										consecutivo =xconsecutivo                              
									FROM @CONSULTAS2 c
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
										upper(p.codDiagnosticoPrincipal) codDiagnosticoPrincipal,
										upper(p.codDiagnosticoRelacionado) codDiagnosticoRelacionado,
										upper(p.codComplicacion) codComplicacion,
										p.vrServicio,
										p.conceptoRecaudo,
										p.valorPagoModerador,
										p.numFEVPagoModerador,
										consecutivo = xconsecutivo    
									FROM @PROCEDIMIENTOS2 p
									WHERE p.usuarioId = u.usuarioId
									FOR JSON PATH
								),
								urgencias = (
									SELECT 
										ur.codPrestador,
										ur.fechaInicioAtencion,
										ur.causaMotivoAtencion,
                              upper(ur.codDiagnosticoPrincipal) codDiagnosticoPrincipal,
										upper(ur.codDiagnosticoPrincipalE) codDiagnosticoPrincipalE,
										upper(ur.codDiagnosticoRelacionadoE1) codDiagnosticoRelacionadoE1,
										upper(ur.codDiagnosticoRelacionadoE2) codDiagnosticoRelacionadoE2,
										upper(ur.codDiagnosticoRelacionadoE3) codDiagnosticoRelacionadoE3,
										ur.condicionDestinoUsuarioEgreso,
										upper(ur.codDiagnosticoCausaMuerte) codDiagnosticoCausaMuerte,
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
										upper(h.codDiagnosticoPrincipal) codDiagnosticoPrincipal,
                                        --h.codDiagnosticoPrincipalE,
                                        upper(ISNULL( NULLIF(h.codDiagnosticoPrincipalE,''), 'null')) codDiagnosticoPrincipalE,
                                        --h.codDiagnosticoRelacionadoE1,
                                        upper(ISNULL( NULLIF(h.codDiagnosticoRelacionadoE1,''), 'null')) codDiagnosticoRelacionadoE1,
                                        --h.codDiagnosticoRelacionadoE2,
                                        upper(ISNULL( NULLIF(h.codDiagnosticoRelacionadoE2,''), 'null')) codDiagnosticoRelacionadoE2,
                                        --h.codDiagnosticoRelacionadoE3,
                                        upper(ISNULL( NULLIF(h.codDiagnosticoRelacionadoE3,''), 'null')) codDiagnosticoRelacionadoE3,
                                        upper(ISNULL( NULLIF(h.codComplicacion,''), 'null')) codComplicacion,
                                        ISNULL( NULLIF(h.codDiagnosticoCausaMuerte,''), 'null') codDiagnosticoCausaMuerte,
										h.condicionDestinoUsuarioEgreso,
										h.fechaInicioAtencion,
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
                              m.numAutorizacion,
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
										m.numFEVPagoModerador,
										consecutivo = xconsecutivo    
									FROM @MEDICAMENTOS2 m
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
										os.numFEVPagoModerador,
										consecutivo = xconsecutivo    
									FROM @OTROSSER2 os
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

	IF 1=1
	BEGIN
		SELECT @base64 = cast('' as xml).value('xs:base64Binary(sql:column("binaryValue"))', 'varchar(max)')
		from (
			select [binaryValue] = cast(dbo.FNK_AttachedDocument(@CNSFCT,'FV') as varbinary(max))
		) as conv;
		SELECT @PLANO=REPLACE(@PLANO,'@XMLFEVFILE',@base64)
	END

	IF COALESCE(@URL_PATH,'')<>''
	BEGIN
      PRINT 'INICO EXPORTACIION A LA RUTA '+@URL_PATH
		SELECT @N_FACTURA=@N_FACTURA+'.json'
		EXEC SPK_GUARDAR_ARCHIVO @PLANO, @URL_PATH, @N_FACTURA
		SELECT @PLANO= @URL_PATH+IIF(RIGHT(@URL_PATH,1)='\','','\')+@N_FACTURA 
	END
	PRINT 'FINALIZO EN SPK_RIPS_JSON_FTR_PGP'
END

