CREATE OR ALTER PROCEDURE DBO.SPK_RIPS_JSON_FTR_CAPI
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
DECLARE @VALORCOPAGOACU DECIMAL(14,2)
DECLARE @IDSEDE VARCHAR(20)
DECLARE @CODHABILITA VARCHAR(100)
DECLARE @CNSCONSULTA INT
DECLARE @CANTORI INT
DECLARE @BANDERA INT
DECLARE @BASE64 NVARCHAR(MAX)
DECLARE @valorPagoModerador INT
DECLARE @N_FACTURAANT VARCHAR(20)
DECLARE @IDTERCERO VARCHAR(20)
DECLARE @IDPLAN VARCHAR(20)
DECLARE @CPROPIO BIT=0
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
   id int identity(1,1),
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
	usuarioId  INT 
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
	usuarioId  INT 
)

DECLARE @MEDICAMENTOS TABLE (
   id int identity(1,1),
	codPrestador VARCHAR(20),
	IDAFILIADO VARCHAR(20),
	CONSECUTIVO VARCHAR(20),
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
	conceptoRecaudo VARCHAR(20),
	tipoPagoModerador VARCHAR(2),
	valorPagoModerador INT,
	numFEVPagoModerador VARCHAR(20),
	usuarioId  INT
)

DECLARE @PROCEDIMIENTOS TABLE (
   id int identity(1,1),
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
	usuarioId  INT
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
	codDiagnosticoPrincipalE VARCHAR(20),
	codDiagnosticoRelacionadoE1 VARCHAR(20),
	codDiagnosticoRelacionadoE2 VARCHAR(20),
	codDiagnosticoRelacionadoE3 VARCHAR(20),
	condicionDestinoUsuarioEgreso VARCHAR(2),
	codDiagnosticoCausaMuerte VARCHAR(20),
	fechaEgreso VARCHAR(16),
	viaIngresoServicioSalud VARCHAR(2),
	usuarioId  INT
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
	usuarioId  INT
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
	usuarioId  INT
)

DECLARE @OTROSSER TABLE (
   id int identity(1,1),
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
	usuarioId  INT
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
DECLARE @TIPOCAP SMALLINT
BEGIN
	DECLARE @json NVARCHAR(MAX)
	DECLARE @numNota VARCHAR(MAX) --= 'xx'
	SELECT @IDTERINSTA = DBO.FNK_VALORVARIABLE('IDTERCEROINSTALADO')
	PRINT 'SPK_RIPS_JSON_FTR_CAPI ='+@N_FACTURA

	SELECT @CNSFCT=CNSFCT,@TIPOCAP=COALESCE(TIPOCAP,0) ,@IDTERCERO=IDTERCERO , @IDPLAN=IDPLAN,@CPROPIO=COALESCE(COPAPROPIO,0),
   @VALORCOPAGO=CASE WHEN COALESCE(COPAPROPIO,0)=1 THEN COALESCE(CP_VLR_COPAGOS,0) ELSE COALESCE(VALORCOPAGO,0) END
   FROM FTR WHERE N_FACTURA=@N_FACTURA
   IF @TIPOCAP=0
   BEGIN
		PRINT 'No se ha Definido el Tipo de Capita, Verifique e intente de Nuevo'
		RAISERROR('No se ha Definido el Tipo de Capita, Verifique e intente de Nuevo', 16, 1)
		RETURN
   END
   IF @TIPOCAP=4
   BEGIN
		PRINT 'Este tipo de Capita no es permitido, me Regreso'
		RAISERROR('Este tipo de Capita no es permitido, Verifique e intente de Nuevo', 16, 1)
		RETURN
   END
   IF @TIPOCAP<> 0
   BEGIN
	PRINT '@TIPOCAP='+CAST(COALESCE(@TIPOCAP,0) AS VARCHAR(2))
	   IF NOT EXISTS(SELECT 1 FROM FTRDC WHERE CNSFTR=@CNSFCT  ) AND COALESCE(@TIPOCAP,0)<>1
	   BEGIN
		   PRINT 'FACTURA CAPITADA SIN RELACION DE SERVICIOS, ME REGRESO'
		   RAISERROR('FACTURA CAPITADA SIN RELACION DE SERVICIOS, POR FAVOR VERIFIQUE.', 16, 1)
		   RETURN
	   END
      IF @TIPOCAP=2
      BEGIN
         SELECT TOP 1 @N_FACTURAANT=N_FACTURA FROM FTR 
         WHERE IDTERCERO=@IDTERCERO 
         AND IDPLAN=@IDPLAN 
         AND CAPITADA=1  
         AND COALESCE(FACTE,0)=2
		   AND COALESCE(TIPOANULACION,'')<>'NC'
		   AND PROCEDENCIA='FINANCIERO'
         AND N_FACTURA<>@N_FACTURA
         ORDER BY F_FACTURA DESC
      END
	   IF EXISTS(SELECT 1 FROM FTRDC WHERE CNSFTR=@CNSFCT AND IDAFILIADO IS NULL)
	   BEGIN 
		   UPDATE FTRDC SET IDAFILIADO=CIT.IDAFILIADO
		   FROM FTRDC INNER JOIN CIT ON FTRDC.NOADMISION=CIT.CONSECUTIVO AND FTRDC.PROCEDENCIA='CIT'
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
      IF EXISTS(SELECT * FROM PLN WHERE IDPLAN=@IDPLAN AND TIPOSISTEMA='Contributivo')
      BEGIN
         SELECT @conceptoRecaudo = '02'
      END
      ELSE
      BEGIN
         IF EXISTS(SELECT * FROM PLN WHERE IDPLAN=@IDPLAN AND TIPOSISTEMA='Subsidiado')
         BEGIN
            SELECT @conceptoRecaudo = '04'
         END
         ELSE
         BEGIN
            SELECT @conceptoRecaudo = '04'
         END
      END
	   SELECT @IDPRESTADOR=COALESCE(IDALTERNA2,'No tengo'), @numDocumentoIdObligado = NIT 
	   FROM TER 
	   WHERE IDTERCERO=@IDTERINSTA
	   PRINT 'BUSCANDO LOS AFILIADOS'
	   BEGIN 
		   INSERT INTO @USUARIOS(tipoDocumentoIdentificacion,numDocumentoIdentificacion,IDAFILIADO,tipoUsuario,fechaNacimiento,codSexo,codPaisResidencia,codPaisOrigen,
								   codMunicipioResidencia,codZonaTerritorialResidencia,incapacidad)
		   SELECT DISTINCT  AFI.TIPO_DOC,AFI.DOCIDAFILIADO,AFI.IDAFILIADO,
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
									   WHEN AFI.TIPOAFILIADO = 'S/N' THEN '05' ELSE '05' END,
					   FNACIMIENTO=REPLACE(CONVERT(VARCHAR,AFI.FNACIMIENTO,102),'.','-'),
					   SEXO=UPPER(LEFT(AFI.SEXO,1)),'170','170', MUNICIPIO=AFI.CIUDAD,ZONA=CASE WHEN AFI.ZONA='R' THEN '01'ELSE '02' END,
					   INCAPACIDAD='NO'
		   FROM FTRDC INNER JOIN AFI ON FTRDC.IDAFILIADO=AFI.IDAFILIADO
		   WHERE CNSFTR=@CNSFCT
	   END

	   PRINT 'COMIENZO CONSULTAS'
	   BEGIN 
			   INSERT INTO @CONSULTAS(codPrestador,CONSECUTIVO,IDAFILIADO,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
									   finalidadTecnologiaSalud,causaMotivoAtencion,vrServicio,conceptoRecaudo,valorPagoModerador,tipoDocumentoIdentificacion, numDocumentoIdentificacion)
			   SELECT @IDPRESTADOR,CIT.CONSECUTIVO,CIT.IDAFILIADO,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,CIT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,CIT.FECHA,108),5),
			   numAutorizacion=COALESCE(CIT.NOAUTORIZACION,'null'),codConsulta=LEFT(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),modalidadGrupoServicioTecSal='01',grupoServicios='01',
			   codServicio=325,finalidadTecnologiaSalud=LEFT(CASE WHEN CIT.FINCONSULTA IS NULL OR CIT.FINCONSULTA=''  OR CONVERT(INT,COALESCE(CIT.FINCONSULTA,0))<=10 THEN '44' ELSE CIT.FINCONSULTA END,2),
			   causaMotivoAtencion='38',0,IIF(COALESCE(CIT.VALORCOPAGO,0)>0,'02',@conceptoRecaudo),COALESCE(CIT.VALORCOPAGO,0), MED.TIPO_ID, MED.IDMEDICO
			   FROM FTRDC 
				   INNER JOIN CIT ON FTRDC.NOADMISION=CIT.CONSECUTIVO
				   INNER JOIN SER ON CIT.IDSERVICIO=SER.IDSERVICIO
				   INNER JOIN MED ON CIT.IDMEDICO = MED.IDMEDICO
				   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
			   WHERE FTRDC.CNSFTR=@CNSFCT
			   AND FTRDC.PROCEDENCIA='CIT'
			   AND CIT.N_FACTURA=@N_FACTURA
			   AND RIPS_CP.ARCHIVO='AC'

			   IF EXISTS(SELECT 1 FROM @CONSULTAS)
			   BEGIN
				   PRINT 'ACTUALIZO DIAGNOSTICOS CIT'
				   -- https://web.sispro.gov.co/WebPublico/Consultas/ConsultarDetalleReferenciaBasica.aspx?Code=RIPSTipoDiagnosticoPrincipalVersion2
				   UPDATE @CONSULTAS SET codDiagnosticoPrincipal=HCA.IDDX
				   ,codDiagnosticoRelacionado1=HCA.DX1
				   ,codDiagnosticoRelacionado2=HCA.DX2
				   ,codDiagnosticoRelacionado3=HCA.DX3
				   ,tipoDiagnosticoPrincipal= CASE TIPODX 
								   WHEN 'Presuntivo'   THEN '01'
								   WHEN 'Impresion dx' THEN '01'
								   WHEN 'Definitivo'   THEN '01'
								   WHEN 'Conf Nuevo'   THEN '02'
								   WHEN 'Conf Repet'   THEN '03'
								   ELSE '01'
								   END
				   FROM FTRDC
					   INNER JOIN CIT ON FTRDC.NOADMISION=CIT.CONSECUTIVO
					   INNER JOIN HCA ON CIT.IDAFILIADO=HCA.IDAFILIADO  AND CIT.CONSECUTIVO= COALESCE (HCA.NOADMISION,HCA.CONSECUTIVOCIT) AND HCA.PROCEDENCIA='IPS'
				   WHERE FTRDC.CNSFTR=@CNSFCT
				   AND FTRDC.PROCEDENCIA='CIT'
				   AND CIT.N_FACTURA=@N_FACTURA            
			   END
		   END
	   PRINT 'CONSULTAS AUT'
	   BEGIN
		   INSERT INTO @CONSULTAS(codPrestador,CONSECUTIVO,IDAFILIADO,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
							   finalidadTecnologiaSalud,causaMotivoAtencion,vrServicio,conceptoRecaudo,valorPagoModerador, tipoDocumentoIdentificacion, numDocumentoIdentificacion, 
					   codDiagnosticoPrincipal, codDiagnosticoRelacionado1, codDiagnosticoRelacionado2, tipoDiagnosticoPrincipal)
		   SELECT @IDPRESTADOR,AUT.NOAUT,AUT.IDAFILIADO,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,AUT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,AUT.FECHA,108),5),
		   numAutorizacion=AUT.NUMAUTORIZA,codConsulta=LEFT(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),modalidadGrupoServicioTecSal='01',grupoServicios='01',
		   codServicio=325,finalidadTecnologiaSalud=LEFT(CASE WHEN AUT.FINALIDAD IS NULL OR AUT.FINALIDAD='' THEN '44' ELSE  CASE WHEN CONVERT(INT,AUT.FINALIDAD)<=10 THEN '44' ELSE AUT.FINALIDAD END END,2),
		   causaMotivoAtencion='38',0,IIF(COALESCE(AUTD.VALORCOPAGO,0)>0,'02',@conceptoRecaudo),COALESCE(AUTD.VALORCOPAGO,0), COALESCE(MED.TIPO_ID, @TIPODOC,''), COALESCE(MED.IDMEDICO, @DOCIDAFILIADO,''),
           AUT.DXPPAL, CASE WHEN COALESCE(AUT.DXRELACIONADO,'')='' THEN 'null' END, CASE WHEN COALESCE(AUT.DXRELACIONADO2,'')='' THEN 'null' END,'01'
		   FROM  FTRDC INNER JOIN AUT ON FTRDC.NOADMISION=AUT.IDAUT 
			   INNER JOIN AUTD ON AUT.IDAUT=AUTD.IDAUT AND FTRDC.NOPRESTACION=AUTD.IDAUT AND FTRDC.NOITEM=AUTD.NO_ITEM
				   INNER JOIN SER ON AUTD.IDSERVICIO=SER.IDSERVICIO
				   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
			   LEFT JOIN MED ON AUT.IDSOLICITANTE = MED.IDMEDICO 
		   WHERE FTRDC.CNSFTR=@CNSFCT
		   AND FTRDC.PROCEDENCIA='AUT'
		   AND AUTD.N_FACTURA=@N_FACTURA
		   --AND AUT.IDAFILIADO=@IDAFILIADO
		   AND RIPS_CP.ARCHIVO='AC'


		   PRINT 'CONSULTAS HADM...'
		   INSERT INTO @CONSULTAS(codPrestador,CONSECUTIVO,IDAFILIADO,fechaInicioAtencion,numAutorizacion,codConsulta,modalidadGrupoServicioTecSal,grupoServicios,codServicio,
							   finalidadTecnologiaSalud,causaMotivoAtencion,codDiagnosticoPrincipal,codDiagnosticoRelacionado1,codDiagnosticoRelacionado2,
							   codDiagnosticoRelacionado3,tipoDiagnosticoPrincipal,vrServicio,conceptoRecaudo,valorPagoModerador, 	tipoDocumentoIdentificacion, numDocumentoIdentificacion) 
		   SELECT COALESCE(@IDPRESTADOR,''),HADM.NOADMISION,HADM.IDAFILIADO,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5),
		   numAutorizacion=HADM.NOAUTORIZACION,codConsulta=LEFT(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),modalidadGrupoServicioTecSal='01',grupoServicios='01',
		   codServicio=325,finalidadTecnologiaSalud=LEFT(CASE WHEN HPRE.FINALIDAD IS NULL OR HPRE.FINALIDAD='' OR CONVERT(INT,COALESCE(HPRE.FINALIDAD,0))<=10 THEN '44' ELSE HPRE.FINALIDAD END,2),
		   causaMotivoAtencion='38',COALESCE(HADM.DXINGRESO,HADM.DXEGRESO),COALESCE(HADM.DXSALIDA1,''),COALESCE(HADM.DXSALIDA2,''),COALESCE(HADM.DXSALIDA3,''),
		   1,0,IIF(COALESCE(HPRED.VALORCOPAGO,0)>0,'02',@conceptoRecaudo),COALESCE(HPRED.VALORCOPAGO,0), MED.TIPO_ID, MED.IDMEDICO 
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
							   codDiagnosticoRelacionado3,tipoDiagnosticoPrincipal,vrServicio,conceptoRecaudo,valorPagoModerador,Cantidad, tipoDocumentoIdentificacion, numDocumentoIdentificacion) 
		   SELECT COALESCE(@IDPRESTADOR,''),HADM.NOADMISION,HADM.IDAFILIADO,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5),
		   numAutorizacion=HADM.NOAUTORIZACION,codConsulta=left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),modalidadGrupoServicioTecSal='01',grupoServicios='01',
		   codServicio=325,finalidadTecnologiaSalud=LEFT(CASE WHEN HPRE.FINALIDAD IS NULL OR HPRE.FINALIDAD='' OR HPRE.FINALIDAD='10'THEN '44' ELSE HPRE.FINALIDAD END,2),
		   causaMotivoAtencion='38',COALESCE(HADM.DXINGRESO,HADM.DXEGRESO),COALESCE(HADM.DXSALIDA1,''),COALESCE(HADM.DXSALIDA2,''),COALESCE(HADM.DXSALIDA3,''),
		   1,0,IIF(COALESCE(HPRED.VALORCOPAGO,0)>0,'02',@conceptoRecaudo),COALESCE(HPRED.VALORCOPAGO,0),CONVERT(INT,HPRED.CANTIDAD), MED.TIPO_ID, MED.IDMEDICO 
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

	   PRINT 'VAMOS POR MEDICAMENTOS'
	   BEGIN
		   INSERT INTO @MEDICAMENTOS(codPrestador,IDAFILIADO,CONSECUTIVO,numAutorizadon,idMIPRES,fechaDispensAdmon,codDiagnosticoPrincipal,codDiagnosticoRelacionado
									   ,tipoMedicamento,codTecnologiaSalud,nomTecnologiaSalud,concentracionMedicamento,unidadMedida,formaFarmaceutica
									   ,unidadMinDispensa,cantidadMedicamento,diasTratamiento,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitMedicamento
									   ,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador)
		   SELECT @IDPRESTADOR,AUT.IDAFILIADO,AUT.NOAUT,numAutorizacion=AUT.NUMAUTORIZA,null,fechaDispensAdmon=REPLACE(CONVERT(VARCHAR,AUT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,AUT.FECHA,108),5),
			   AUT.DXPPAL,AUT.DXRELACIONADO,'01',COALESCE(IART.CODCUM,SER.CODCUM),LEFT( dbo.FNK_LIMPIATEXTO(IART.DESCRIPCION,'0-9 A-Z();:.,'),30),'0',
			   COALESCE(IUNI.HOMOLOGO_RIPS,247),COALESCE(IFFA.HOMOJSON,'null'),'11',CONVERT(VARCHAR,CONVERT(INT,AUTD.CANTIDAD),10),CAST(AUTD.DIAS AS VARCHAR(3)),@TIPODOC,@DOCIDAFILIADO,AUTD.VALOR,AUTD.VALOR*AUTD.CANTIDAD,
			   IIF(COALESCE(AUTD.VALORCOPAGO,0)>0,'02',@conceptoRecaudo),'04',COALESCE(AUTD.VALORCOPAGO,0),@N_FACTURA
		   FROM FTRDC INNER JOIN AUT ON FTRDC.NOADMISION=AUT.IDAUT  
			   INNER JOIN AUTD ON AUT.IDAUT=AUTD.IDAUT
			   INNER JOIN SER ON AUTD.IDSERVICIO=SER.IDSERVICIO AND FTRDC.IDSERVICIO = SER.IDSERVICIO 
			   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
			   LEFT  JOIN IART ON SER.IDSERVICIO=IART.IDSERVICIO
			   LEFT  JOIN IFFA  ON IART.IDFORFARM=IFFA.IDFORFARM
			   LEFT JOIN IUNI ON IUNI.IDUNIDAD=IART.IDUNIDAD
		   WHERE FTRDC.CNSITFC=@CNSFCT
		   AND FTRDC.PROCEDENCIA='AUT'
		   AND AUTD.N_FACTURA=@N_FACTURA
		   AND RIPS_CP.ARCHIVO='AM'


		   PRINT 'MEDICAMENTOS HADM'

		   INSERT INTO @MEDICAMENTOS(codPrestador,IDAFILIADO,CONSECUTIVO,numAutorizadon,idMIPRES,fechaDispensAdmon,codDiagnosticoPrincipal,codDiagnosticoRelacionado
									   ,tipoMedicamento,codTecnologiaSalud,nomTecnologiaSalud,concentracionMedicamento,unidadMedida,formaFarmaceutica
									   ,unidadMinDispensa,cantidadMedicamento,diasTratamiento,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitMedicamento
									   ,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador)

		   SELECT @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION,numAutorizacion=HADM.NOAUTORIZACION,null,fechaDispensAdmon=REPLACE(CONVERT(VARCHAR,FTRDC.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,FTRDC.FECHA,108),5),
			   COALESCE(HADM.DXINGRESO,''),COALESCE(HADM.DXSALIDA1,''),'01',CASE WHEN COALESCE(SER.MEDICAMENTOS,0)=1 THEN IIF(COALESCE(IART.CODCUM,'')='',SER.CODCUM,IART.CODCUM) ELSE SER.IDSERVICIO END,
               LEFT(dbo.FNK_LIMPIATEXTO(IART.DESCRIPCION,'0-9 A-Z();:.,'),30),'0',COALESCE(IUNI.HOMOLOGO_RIPS,247),COALESCE(IFFA.HOMOJSON,'null'),'11',
               CONVERT(VARCHAR,CONVERT(INT,HPRED.CANTIDAD),10),1,AFI.TIPO_DOC,AFI.DOCIDAFILIADO,CONVERT(VARCHAR,CONVERT(DECIMAL(14,2),HPRED.VALOR),20),
			   CONVERT(VARCHAR,CONVERT(DECIMAL(14,2),HPRED.VALOR*HPRED.CANTIDAD),20),IIF(COALESCE(HPRED.VALORCOPAGO,0)>0,'02',@conceptoRecaudo),'04',CONVERT(DECIMAL(14,2),HPRED.VALORCOPAGO),@N_FACTURA
		   FROM FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION
               INNER JOIN AFI  ON FTRDC.IDAFILIADO=AFI.IDAFILIADO
               INNER JOIN HPRED ON FTRDC.NOPRESTACION=HPRED.NOPRESTACION AND FTRDC.NOITEM=HPRED.NOITEM 
               INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO AND FTRDC.IDSERVICIO = SER.IDSERVICIO
			   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
			   LEFT JOIN IART ON COALESCE(HPRED.IDARTICULO,SER.IDARTICULO)=IART.IDARTICULO
			   LEFT JOIN IFFA ON IART.IDFORFARM=IFFA.IDFORFARM
			   LEFT JOIN IUNI ON IUNI.IDUNIDAD = IART.IDUNIDAD
		   WHERE FTRDC.CNSFTR=@CNSFCT
		   AND FTRDC.PROCEDENCIA='HADM'
		   AND HPRED.N_FACTURA=@N_FACTURA
		   AND COALESCE(HPRED.VALOR,0)>0
		   AND COALESCE(HPRED.NOCOBRABLE,0)=0
		   AND RIPS_CP.ARCHIVO='AM'
	   END

	   PRINT 'PROCEDIMIENTOS'
	   BEGIN 
		   INSERT INTO @PROCEDIMIENTOS (codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
					   ,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
					   ,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador
					   )
		   SELECT @IDPRESTADOR,CIT.IDAFILIADO,CIT.CONSECUTIVO,REPLACE(CONVERT(VARCHAR,CIT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,CIT.FECHA,108),5),null,
				   COALESCE(CIT.NOAUTORIZACION,'null'),left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),'02','01','02',325,'16',MED.TIPO_ID,MED.IDMEDICO,CIT.IDDX,
				   CASE WHEN COALESCE(CIT.IDDX,'')='' THEN 'null' END,CASE WHEN COALESCE(CIT.IDDX,'')='' THEN 'null' END,0,IIF(COALESCE(CIT.VALORCOPAGO,0)>0,'02',@conceptoRecaudo),'04',COALESCE(CIT.VALORCOPAGO,0),@N_FACTURA
		   FROM  FTRDC 
			   INNER JOIN CIT ON FTRDC.NOADMISION=CIT.CONSECUTIVO
			   INNER JOIN SER ON CIT.IDSERVICIO=SER.IDSERVICIO
			   INNER JOIN AFI ON FTRDC.IDAFILIADO=AFI.IDAFILIADO
			   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
            LEFT  JOIN MED ON CIT.IDMEDICO=MED.IDMEDICO
		   WHERE FTRDC.CNSFTR=@CNSFCT
		   AND FTRDC.PROCEDENCIA='CIT'
		   AND CIT.N_FACTURA=@N_FACTURA
		   AND RIPS_CP.ARCHIVO='AP'

		   BEGIN --AP
			   INSERT INTO @PROCEDIMIENTOS1 (codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
					   ,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
					   ,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,cantidad,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador)
			   SELECT @IDPRESTADOR,AUT.IDAFILIADO,AUT.NOAUT,REPLACE(CONVERT(VARCHAR, AUT.FECHA, 102), '.', '-') + ' ' + LEFT(CONVERT(VARCHAR, AUT.FECHA, 108), 5),NULL
				   ,AUT.NUMAUTORIZA,left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),'02','01','02',325,'16',COALESCE(MED.TIPO_ID, 'CC'), COALESCE(MED.IDMEDICO,@DOCIDAFILIADO)
				   ,AUT.DXPPAL,IIF(COALESCE(AUT.DXRELACIONADO,'')='',AUT.DXPPAL,AUT.DXRELACIONADO),AUT.DXPPAL,0,IIF(COALESCE(AUT.VALORCOPAGO,0)>0,'02',@conceptoRecaudo),FTRDC.CANTIDAD,'04'
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
					   INNER JOIN AFI ON FTRDC.IDAFILIADO=AFI.IDAFILIADO
					   INNER JOIN SER ON AUTD.IDSERVICIO = SER.IDSERVICIO AND FTRDC.IDSERVICIO = SER.IDSERVICIO
					   INNER JOIN RIPS_CP ON SER.CODIGORIPS = RIPS_CP.IDCONCEPTORIPS
					   LEFT  JOIN MED ON MED.IDMEDICO = IIF(COALESCE(AUT.IDMEDICOSOLICITA,'')='' OR AUT.IDMEDICOSOLICITA IS NULL,DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT'),AUT.IDMEDICOSOLICITA)				
			   WHERE FTRDC.CNSFTR=@CNSFCT
			   AND FTRDC.PROCEDENCIA='AUT'
			   AND AUTD.N_FACTURA = @N_FACTURA
			   AND RIPS_CP.ARCHIVO = 'AP'
			   AND FTRDC.CANTIDAD > 0
			
			   DECLARE @RESIDUO DECIMAL(14,2)
			
			   UPDATE @PROCEDIMIENTOS1 SET restoPagoModerador=TRY_CAST(valorPagoModerador AS decimal(14,2))%cantidad
			   UPDATE @PROCEDIMIENTOS1 SET valorPagoModerador=TRY_CAST(valorPagoModerador AS decimal(14,2))-TRY_CAST(restoPagoModerador AS decimal(14,2))
			   SELECT @RESIDUO=SUM(TRY_CAST(restoPagoModerador AS decimal(14,2))) FROM @PROCEDIMIENTOS1
			
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
		   END

		   DELETE FROM @PROCEDIMIENTOS1 WHERE 1=1

		   INSERT INTO @PROCEDIMIENTOS (codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,idMIPRES,numAutorizacion,codProcedimiento,viaIngresoServicioSalud
					   ,modalidadGrupoServicioTecSal,grupoServicios,codServicio,finalidadTecnologiaSalud,tipoDocumentoIdentificacion,numDocumentoIdentificacion
					   ,codDiagnosticoPrincipal,codDiagnosticoRelacionado,codComplicacion,vrServicio,conceptoRecaudo,tipoPagoModerador,valorPagoModerador,numFEVPagoModerador
					   )
		   SELECT @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION,REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5),null,
			   HADM.NOAUTORIZACION,left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),COALESCE(REPLACE(TGEN.DATO2,' ',''),HADM.VIAINGRESO,'02'),'01','02',325,'16',MED.TIPO_ID,MED.IDMEDICO,COALESCE(HADM.DXINGRESO,HADM.DXEGRESO), 
			   CASE WHEN COALESCE(HADM.DXSALIDA1,'')='' THEN 'null' END,CASE WHEN COALESCE(HADM.COMPLICACION,HADM.DXINGRESO,HADM.DXEGRESO,'')='' THEN 'null' END,0,IIF(COALESCE(HPRED.VALORCOPAGO,0)>0,'02',@conceptoRecaudo),'04',COALESCE(HPRED.VALORCOPAGO,0),@N_FACTURA
		   FROM  FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION
					   INNER JOIN AFI  ON FTRDC.IDAFILIADO=AFI.IDAFILIADO
					   INNER JOIN HPRED ON FTRDC.NOPRESTACION=HPRED.NOPRESTACION AND FTRDC.NOITEM=HPRED.NOITEM
					   INNER JOIN HPRE  ON HADM.NOADMISION=HPRE.NOADMISION AND FTRDC.NOPRESTACION=HPRE.NOPRESTACION
					   INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO AND FTRDC.IDSERVICIO = SER.IDSERVICIO
					   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
					   INNER JOIN TGEN ON HADM.VIAINGRESO = TGEN.CODIGO AND TABLA = 'General' AND CAMPO = 'VIADEINGRESO' 
					   LEFT JOIN MED ON MED.IDMEDICO = CASE WHEN COALESCE(HPRE.IDMEDICO,'') = '' THEN COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA,DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT')) ELSE HPRE.IDMEDICO END
		   WHERE FTRDC.CNSFTR=@CNSFCT
		   AND FTRDC.PROCEDENCIA='HADM'
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
			   HADM.NOAUTORIZACION,left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),COALESCE(REPLACE(TGEN.DATO2,' ',''),HADM.VIAINGRESO,'02'),'01','02',325,'16',COALESCE(MED.TIPO_ID, @TIPODOC), COALESCE(MED.IDMEDICO,@DOCIDAFILIADO),COALESCE(HADM.DXINGRESO,HADM.DXEGRESO), 
			   CASE WHEN COALESCE(HADM.DXSALIDA1,'')='' THEN 'null' END,CASE WHEN COALESCE(HADM.COMPLICACION,HADM.DXINGRESO,HADM.DXEGRESO,'')='' THEN 'null' END,0,IIF(COALESCE(HPRED.VALORCOPAGO,0)>0,'02',@conceptoRecaudo),HPRED.CANTIDAD, '04',COALESCE(HPRED.VALORCOPAGO,0),@N_FACTURA
		   FROM  FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION
					   INNER JOIN AFI  ON FTRDC.IDAFILIADO=AFI.IDAFILIADO
					   INNER JOIN HPRED ON FTRDC.NOPRESTACION=HPRED.NOPRESTACION AND FTRDC.NOITEM=HPRED.NOITEM
					   INNER JOIN HPRE  ON HADM.NOADMISION=HPRE.NOADMISION AND FTRDC.NOPRESTACION=HPRE.NOPRESTACION
					   INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO AND FTRDC.IDSERVICIO = SER.IDSERVICIO
					   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
					   INNER JOIN TGEN ON HADM.VIAINGRESO = TGEN.CODIGO AND TABLA = 'General' AND CAMPO = 'VIADEINGRESO' 
					   INNER JOIN MED ON MED.IDMEDICO = CASE WHEN COALESCE(HPRE.IDMEDICO,'') = '' THEN COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA,DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT')) ELSE HPRE.IDMEDICO END
		   WHERE FTRDC.CNSFTR=@CNSFCT
		   AND FTRDC.PROCEDENCIA='HADM'
		   AND HPRED.N_FACTURA=@N_FACTURA
		   AND COALESCE(HPRED.VALOR,0)>0
		   AND COALESCE(HPRED.NOCOBRABLE,0)=0
		   AND HPRED.CANTIDAD>1
		   AND RIPS_CP.ARCHIVO='AP' 

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

	   PRINT  'URGENCIAS'
	   BEGIN
		   INSERT INTO @URGENCIAS(codPrestador,IDAFILIADO,CONSECUTIVO,fechaInicioAtencion,causaMotivoAtencion,codDiagnosticoPrincipalE,
								   codDiagnosticoRelacionadoE1,codDiagnosticoRelacionadoE2,codDiagnosticoRelacionadoE3,condicionDestinoUsuarioEgreso,
								   codDiagnosticoCausaMuerte,fechaEgreso)
		   SELECT @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION, REPLACE(CONVERT(VARCHAR,HADM.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HADM.FECHA,108),5),
		   CASE WHEN COALESCE(TGEN.CHECK1,0)=1 THEN DATO1 ELSE CODIGO END,COALESCE(HCA.IDDX,HADM.DXINGRESO),COALESCE(HADM.DXEGRESO,HCA.DX1),
		   COALESCE(HCA.DX1,HADM.DXSALIDA1),COALESCE(HCA.DX2,HADM.DXSALIDA2),CASE WHEN HADM.ESTADOPSALIDA=1 THEN '01' ELSE '02' END,
		   CASE WHEN HADM.ESTADOPSALIDA=1 THEN null ELSE CAUSABMUERTE END,
		   REPLACE(CONVERT(VARCHAR,HADM.FECHAALTAMED,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HADM.FECHAALTAMED,108),5)
		   FROM FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION  
				   LEFT JOIN HCA ON HADM.NOADMISION=HCA.NOADMISION
				   LEFT JOIN TGEN ON HADM.CAUSAEXTERNA=TGEN.CODIGO AND TGEN.TABLA='General' AND TGEN.CAMPO='CAUSAEXTERNA'
		   WHERE FTRDC.CNSFTR=@CNSFCT 
		   AND FTRDC.PROCEDENCIA='HADM'
		   AND HADM.NOADMISION=@NOADMISION
		   AND DATEDIFF(HOUR,HADM.FECHA,HADM.FECHAALTAMED)<=48
		   AND HCA.CLASE='HC'
		   AND HCA.PROCEDENCIA='QX'
		   AND HCA.CLASEPLANTILLA <> DBO.FNK_VALORVARIABLE('HCPLANTILLAEPI')
	   END

	   PRINT 'HOSPITALIZACION'
	   BEGIN 
		   DECLARE @F_FACTURA DATETIME
		   SELECT @F_FACTURA=F_FACTURA FROM FTR WHERE N_FACTURA=@N_FACTURA

		   INSERT INTO @HOSPITALIZACION (codPrestador,IDAFILIADO,CONSECUTIVO,viaIngresoServicioSalud,fechaInicioAtencion,numAutorizacion,causaMotivoAtencion,codDiagnosticoPrincipal,
									   codDiagnosticoPrincipalE,codDiagnosticoRelacionadoE1,codDiagnosticoRelacionadoE2,codDiagnosticoRelacionadoE3,
									   codComplicacion,condicionDestinoUsuarioEgreso,codDiagnosticoCausaMuerte,fechaEgreso)

		   SELECT @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION,COALESCE(REPLACE(TGEN.DATO2,' ',''),HADM.VIAINGRESO,'01'),
		   REPLACE(CONVERT(VARCHAR,HADM.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HADM.FECHA,108),5)
			   ,HADM.NOAUTORIZACION
			   ,COALESCE(REPLACE(TGEN2.DATO1,' ',''),HADM.CAUSAEXTERNA,'38')-- CPALACIO
			   ,COALESCE(HCA.IDDX,HADM.DXINGRESO)
			   ,COALESCE(HADM.DXEGRESO,HCA.DX1)
               ,CASE WHEN COALESCE(HCA.DX1,HADM.DXSALIDA1,'')='' THEN 'null' END
               ,CASE WHEN COALESCE(HCA.DX2,HADM.DXSALIDA2,'')='' THEN 'null' END
               ,CASE WHEN COALESCE(HCA.DX3,HADM.DXSALIDA3,'')='' THEN 'null' END
			   ,COALESCE(HADM.COMPLICACION,HCA.IDDX,HADM.DXINGRESO,HADM.DXEGRESO)
			   ,CASE WHEN HADM.ESTADOPSALIDA=1 THEN '01' ELSE '02' END
			   ,CASE WHEN HADM.ESTADOPSALIDA=1 THEN '' ELSE CAUSABMUERTE END
			   ,REPLACE(CONVERT(VARCHAR,HADM.FECHAALTAMED,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HADM.FECHAALTAMED,108),5)
		   FROM FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION
				   LEFT JOIN HCA ON HADM.NOADMISION=HCA.NOADMISION
				   LEFT JOIN TGEN ON HADM.VIAINGRESO = TGEN.CODIGO AND TABLA = 'General' AND CAMPO = 'VIADEINGRESO' 
				   LEFT JOIN TGEN TGEN2 ON HADM.CAUSAEXTERNA = TGEN2.CODIGO AND TGEN2.TABLA = 'General' AND TGEN2.CAMPO = 'CAUSAEXTERNA' --CPALACIO
		   WHERE FTRDC.CNSFTR=@CNSFCT 
		   AND FTRDC.PROCEDENCIA='HADM'
		   AND DATEDIFF(HOUR,HADM.FECHA,HADM.FECHAALTAMED)<=48
		   AND HCA.CLASE='HC'
		   AND HCA.PROCEDENCIA='QX'
	   END 
      
	   PRINT 'RECIEN NACIDOS'
	   IF EXISTS (SELECT 1 FROM FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION INNER JOIN QXRCN ON HADM.NOADMISION=QXRCN.NOADMISION
			   WHERE FTRDC.CNSFTR=@CNSFCT AND FTRDC.PROCEDENCIA='HADM'
			   )
	   BEGIN
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
		   FROM FTRDC INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION
					   INNER JOIN QXRCN ON HADM.NOADMISION=QXRCN.NOADMISION
		   WHERE FTRDC.CNSFTR=@CNSFCT
		   AND FTRDC.PROCEDENCIA='HADM'
	   END

	   PRINT 'OTROS SERVICIOS'
	   BEGIN
		   INSERT INTO @OTROSSER(codPrestador,IDAFILIADO,CONSECUTIVO,numAutorizacion,idMIPRES,fechaSuministroTecnologia,tipoOS,codTecnologiaSalud,nomTecnologiaSalud
							   ,cantidadOS,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitOS,vrServicio,conceptoRecaudo,tipoPagoModerador
							   ,valorPagoModerador,numFEVPagoModerador)
		   SELECT @IDPRESTADOR,CIT.IDAFILIADO,CIT.CONSECUTIVO,numAutorizacion=CIT.NOAUTORIZACION,null,
			   fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,CIT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,CIT.FECHA,108),5),
			   tipoOS='04',codTecnologiaSalud=left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),nomTecnologiaSalud=LEFT(dbo.FNK_LIMPIATEXTO(SER.DESCSERVICIO,'0-9 A-Z();:.,'),60),
			   cantidadOS=IIF(COALESCE(CIT.CANTIDADC,1)=0,1,COALESCE(CIT.CANTIDADC,1)),tipoDocumentoIdentificacion=AFI.TIPO_DOC,
			   numDocumentoIdentificacion=AFI.DOCIDAFILIADO,COALESCE(CIT.VALORTOTAL,0),COALESCE(CIT.VALORTOTAL,0),IIF(COALESCE(
			   CIT.VALORCOPAGO,0)>0,'02',@conceptoRecaudo),tipoPagoModerador='04',COALESCE(CIT.VALORCOPAGO,0),
			   @N_FACTURA
		   FROM FTRDC INNER JOIN CIT ON FTRDC.NOADMISION=CIT.CONSECUTIVO
					   INNER JOIN AFI ON FTRDC.IDAFILIADO=AFI.IDAFILIADO
					   INNER JOIN SER ON CIT.IDSERVICIO=SER.IDSERVICIO
					   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
		   WHERE FTRDC.CNSFTR=@CNSFCT
		   AND FTRDC.PROCEDENCIA='CIT'
		   AND CIT.N_FACTURA=@N_FACTURA
		   AND RIPS_CP.ARCHIVO='AT'

		   INSERT INTO @OTROSSER(codPrestador,IDAFILIADO,CONSECUTIVO,numAutorizacion,idMIPRES,fechaSuministroTecnologia,tipoOS,codTecnologiaSalud,nomTecnologiaSalud
							   ,cantidadOS,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitOS,vrServicio,conceptoRecaudo,tipoPagoModerador
							   ,valorPagoModerador,numFEVPagoModerador)
		   SELECT @IDPRESTADOR,AUT.IDAFILIADO,AUT.NOAUT,numAutorizacion=AUT.NUMAUTORIZA,null,
			   fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,AUT.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,AUT.FECHA,108),5),
			   tipoOS='04',codTecnologiaSalud=left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6),nomTecnologiaSalud=LEFT( dbo.FNK_LIMPIATEXTO(SER.DESCSERVICIO,'0-9 A-Z();:.,'),60),
			   cantidadOS=COALESCE(AUTD.CANTIDAD,1),tipoDocumentoIdentificacion=MED.TIPO_ID,
			   numDocumentoIdentificacion=MED.IDMEDICO,
			   COALESCE(AUTD.VALOR,0),
			   COALESCE(AUTD.VALOR,0)*COALESCE(AUTD.CANTIDAD, 0),
			   IIF(COALESCE(AUT.VALORCOPAGO,0)>0,'02',@conceptoRecaudo),
			   tipoPagoModerador='04',
			   COALESCE(AUT.VALORCOPAGO,0),
			   @N_FACTURA
		   FROM FTRDC INNER JOIN AUT ON FTRDC.NOADMISION= AUT.NOAUT
					   INNER JOIN AUTD ON AUT.IDAUT=AUTD.IDAUT
					   INNER JOIN SER ON AUTD.IDSERVICIO=SER.IDSERVICIO AND FTRDC.IDSERVICIO = SER.IDSERVICIO
					   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
					   LEFT  JOIN MED		ON MED.IDMEDICO    = IIF(COALESCE(AUT.IDMEDICOSOLICITA,'')='',DBO.FNK_VALORVARIABLE('EPI_MEDICODEFAULT'),AUT.IDMEDICOSOLICITA)
		   WHERE FTRDC.CNSFTR=@CNSFCT
		   AND FTRDC.PROCEDENCIA='AUT'
		   AND AUT.NOAUT=@NOADMISION
		   AND AUTD.N_FACTURA=@N_FACTURA
		   AND RIPS_CP.ARCHIVO='AT'

		   INSERT INTO @OTROSSER(codPrestador,IDAFILIADO,CONSECUTIVO,numAutorizacion,idMIPRES,fechaSuministroTecnologia,tipoOS,codTecnologiaSalud,nomTecnologiaSalud
							   ,cantidadOS,tipoDocumentoIdentificacion,numDocumentoIdentificacion,vrUnitOS,vrServicio,conceptoRecaudo,tipoPagoModerador
							   ,valorPagoModerador,numFEVPagoModerador)
		   SELECT @IDPRESTADOR,HADM.IDAFILIADO,HADM.NOADMISION                                                                   
			   ,numAutorizacion=HADM.NOAUTORIZACION
			   ,null                                                                             
			   ,fechaInicioAtencion=REPLACE(CONVERT(VARCHAR,HPRE.FECHA,102),'.','-')+' '+LEFT(CONVERT(VARCHAR,HPRE.FECHA,108),5)
			   ,tipoOS='04'
			   ,codTecnologiaSalud=CASE WHEN RIPS_CP.IDCONCEPTORIPS=DBO.FNK_VALORVARIABLE('IDMATERIALESRIPS')THEN SER.IDSERVICIO ELSE left(REPLACE(REPLACE(LTRIM(RTRIM(SER.CODCUPS)),CHAR(13),''),CHAR(10),''),6) END
			   ,nomTecnologiaSalud=LEFT( dbo.FNK_LIMPIATEXTO(SER.DESCSERVICIO,'0-9 A-Z();:.,'),60)
			   ,cantidadOS=CONVERT(INT,COALESCE(HPRED.CANTIDAD,1))
			   ,tipoDocumentoIdentificacion=MED.TIPO_ID
			   ,numDocumentoIdentificacion=MED.IDMEDICO
			   ,CONVERT(DECIMAL(14,2),COALESCE(HPRED.VALOR,0))
			   ,CONVERT(DECIMAL(14,2),COALESCE(HPRED.VALOR*HPRED.CANTIDAD,0))
			   ,IIF(COALESCE(HPRED.VALORCOPAGO,0)>0,'02',@conceptoRecaudo)
			   ,tipoPagoModerador='04'
			   ,CONVERT(DECIMAL(14,2),COALESCE(HPRED.VALORCOPAGO,0)) 
			   ,@N_FACTURA                                                                       
		   FROM FTRDC 
			   INNER JOIN HADM ON FTRDC.NOADMISION=HADM.NOADMISION
			   INNER JOIN  HPRE ON HADM.NOADMISION=HPRE.NOADMISION
			   INNER JOIN HPRED ON HPRE.NOPRESTACION=HPRED.NOPRESTACION AND HPRED.NOITEM = FTRDC.NOITEM
			   INNER JOIN SER ON HPRED.IDSERVICIO=SER.IDSERVICIO AND FTRDC.IDSERVICIO = SER.IDSERVICIO
			   INNER JOIN RIPS_CP ON SER.CODIGORIPS=RIPS_CP.IDCONCEPTORIPS
			   INNER JOIN MED ON MED.IDMEDICO= CASE WHEN COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA,HADM.IDMEDICOING)='' THEN HPRE.IDMEDICO ELSE COALESCE(HADM.IDMEDICOALTA,HADM.IDMEDICOTRA,HADM.IDMEDICOING) END
			   LEFT JOIN HCA ON HPRE.CONSECUTIVOHCA=HCA.CONSECUTIVO
		   WHERE FTRDC.CNSFTR=@CNSFCT
		   AND FTRDC.PROCEDENCIA='HADM'
		   AND HPRED.N_FACTURA=@N_FACTURA
		   AND RIPS_CP.ARCHIVO='AT'   
		   AND COALESCE(HPRED.VALOR,0)>0
		   AND COALESCE(HPRED.NOCOBRABLE,0)=0
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
		   FROM HCA INNER JOIN CIT ON HCA.CONSECUTIVOCIT=CIT.CONSECUTIVO AND HCA.IDAFILIADO = CIT.IDAFILIADO
		   WHERE HCA.CLASE='HC'
			   AND HCA.PROCEDENCIA='IPS'
			   AND COALESCE(HCA.IDDX,'')<>''
			   AND EXISTS(SELECT 1 FROM FTRDC WHERE FTRDC.NOADMISION=CIT.CONSECUTIVO AND FTRDC.PROCEDENCIA='CIT')
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
		   AND EXISTS(SELECT 1 FROM FTRDC WHERE FTRDC.NOADMISION=HADM.NOADMISION AND FTRDC.PROCEDENCIA='HADM')
	   END

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
	   END
	   PRINT 'Actualización de LAS TABLAS con los diagnósticos principales y relacionados en un solo bloque'
	   BEGIN
		   PRINT 'Diagnosticos Consultas'
		   UPDATE AC
		   SET 
			   AC.codDiagnosticoPrincipal = CASE WHEN COALESCE(AC.codDiagnosticoPrincipal, '') = '' THEN DX.IDDX ELSE AC.codDiagnosticoPrincipal END,
			   AC.tipoDiagnosticoPrincipal = DX.TIPODX,
			   AC.codDiagnosticoRelacionado1 = CASE WHEN COALESCE(AC.codDiagnosticoRelacionado1, '') = '' THEN DX.DX1 ELSE AC.codDiagnosticoRelacionado1 END,
			   AC.codDiagnosticoRelacionado2 = CASE WHEN COALESCE(AC.codDiagnosticoRelacionado2, '') = '' THEN DX.DX2 ELSE AC.codDiagnosticoRelacionado2 END,
			   AC.codDiagnosticoRelacionado3 = CASE WHEN COALESCE(AC.codDiagnosticoRelacionado3, '') = '' THEN DX.DX3 ELSE AC.codDiagnosticoRelacionado3 END
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
			   AP.codDiagnosticoPrincipal = CASE WHEN COALESCE(AP.codDiagnosticoPrincipal, '') = '' THEN DX.IDDX ELSE AP.codDiagnosticoPrincipal END,
			   AP.codDiagnosticoRelacionado = CASE WHEN COALESCE(AP.codDiagnosticoRelacionado, '') = '' THEN DX.DX1 ELSE AP.codDiagnosticoRelacionado END
		   FROM @PROCEDIMIENTOS AP
		   INNER JOIN @DX DX ON AP.IDAFILIADO = DX.IDAFILIADO
		   WHERE COALESCE(DX.IDDX, '') <> '';

		   PRINT 'URGENCIAS'
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

		   UPDATE AH
		   SET 
			   AH.codDiagnosticoPrincipal = CASE WHEN COALESCE(AH.codDiagnosticoPrincipal, '') = '' THEN DX.IDDX ELSE AH.codDiagnosticoPrincipal END,
			   AH.codDiagnosticoRelacionadoE1 = CASE WHEN COALESCE(AH.codDiagnosticoRelacionadoE1, '') = '' THEN DX.DX1 ELSE AH.codDiagnosticoRelacionadoE1 END,
			   AH.codDiagnosticoRelacionadoE2 = CASE WHEN COALESCE(AH.codDiagnosticoRelacionadoE2, '') = '' THEN DX.DX2 ELSE AH.codDiagnosticoRelacionadoE2 END,
			   AH.codDiagnosticoRelacionadoE3 = CASE WHEN COALESCE(AH.codDiagnosticoRelacionadoE3, '') = '' THEN DX.DX3 ELSE AH.codDiagnosticoRelacionadoE3 END
		   FROM @HOSPITALIZACION AH
		   INNER JOIN @DX DX ON AH.IDAFILIADO = DX.IDAFILIADO
		   WHERE COALESCE(DX.IDDX, '') <> '';
	   END
      SELECT @VALORCOPAGOACU=COALESCE(SUM(valorPagoModerador),0) FROM @CONSULTAS
      SELECT @VALORCOPAGOACU=COALESCE(@VALORCOPAGOACU,0)+COALESCE(SUM(valorPagoModerador),0) FROM @PROCEDIMIENTOS
      SELECT @VALORCOPAGOACU=COALESCE(@VALORCOPAGOACU,0)+COALESCE(SUM(valorPagoModerador),0) FROM @MEDICAMENTOS
      SELECT @VALORCOPAGOACU=COALESCE(@VALORCOPAGOACU,0)+COALESCE(SUM(valorPagoModerador),0) FROM @OTROSSER
      IF ABS(@VALORCOPAGO-@VALORCOPAGOACU)<10
      BEGIN
         DECLARE @CONSE INT
         DECLARE @DIF INT
         SELECT TOP 1 @CONSE=id FROM @CONSULTAS WHERE CONVERT(DECIMAL(14,2),valorPagoModerador)>0
         if COALESCE(@CONSE,0)>0
         BEGIN
            UPDATE @CONSULTAS SET valorPagoModerador=valorPagoModerador+(@VALORCOPAGO-@VALORCOPAGOACU)   WHERE id=@CONSE 
         END
         ELSE
         BEGIN
            SELECT TOP 1 @CONSE=id FROM @PROCEDIMIENTOS WHERE CONVERT(DECIMAL(14,2),valorPagoModerador)>0
            if COALESCE(@CONSE,0)>0
            BEGIN
               UPDATE @PROCEDIMIENTOS SET valorPagoModerador=valorPagoModerador+(@VALORCOPAGO-@VALORCOPAGOACU)   WHERE id=@CONSE 
            END
            ELSE
            BEGIN
               SELECT TOP 1 @CONSE=id FROM @MEDICAMENTOS WHERE CONVERT(DECIMAL(14,2),valorPagoModerador)>0
               if COALESCE(@CONSE,0)>0
               BEGIN
                  UPDATE @MEDICAMENTOS SET valorPagoModerador=valorPagoModerador+(@VALORCOPAGO-@VALORCOPAGOACU)   WHERE id=@CONSE 
               END   
               ELSE
               BEGIN
                  SELECT TOP 1 @CONSE=id FROM @OTROSSER WHERE CONVERT(DECIMAL(14,2),valorPagoModerador)>0
                  if COALESCE(@CONSE,0)>0
                  BEGIN
                     UPDATE @OTROSSER SET valorPagoModerador=valorPagoModerador+(@VALORCOPAGO-@VALORCOPAGOACU)   WHERE id=@CONSE 
                  END  
                END
            END
         END
      END
      IF COALESCE(@CPROPIO,0)=1
      BEGIN
         UPDATE @CONSULTAS SET conceptoRecaudo='05',valorPagoModerador=0 WHERE valorPagoModerador>=0
         UPDATE @PROCEDIMIENTOS SET conceptoRecaudo='05',valorPagoModerador=0 WHERE valorPagoModerador>=0
         UPDATE @MEDICAMENTOS SET conceptoRecaudo='05',valorPagoModerador=0 WHERE valorPagoModerador>=0
         UPDATE @OTROSSER SET conceptoRecaudo='05',valorPagoModerador=0 WHERE valorPagoModerador>=0
      END
	   PRINT 'TERMINE DE PREPARAR LOS DATOS'
   END
--QUERY2	
	IF @TIPOCAP<>1
	BEGIN
		SET @json = (
	   SELECT 
		rips = (
			SELECT 
				numDocumentoIdObligado =  @numDocumentoIdObligado,
				numFactura = CASE WHEN COALESCE(@TIPOCAP,0)=2 THEN @N_FACTURAANT ELSE @N_FACTURA END,
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
										-- c.codDiagnosticoRelacionado1,
										ISNULL( NULLIF(c.codDiagnosticoRelacionado1,''), 'null') codDiagnosticoRelacionado1,
										-- c.codDiagnosticoRelacionado2,
										ISNULL( NULLIF(c.codDiagnosticoRelacionado2,''), 'null') codDiagnosticoRelacionado2,
										-- c.codDiagnosticoRelacionado3,
										ISNULL( NULLIF(c.codDiagnosticoRelacionado3,''), 'null') codDiagnosticoRelacionado3,
										c.tipoDiagnosticoPrincipal,
										c.tipoDocumentoIdentificacion,
										c.numDocumentoIdentificacion,
										c.vrServicio,
										c.conceptoRecaudo,
										c.valorPagoModerador,
										c.numFEVPagoModerador,
										consecutivo = u.usuarioId
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
										p.numFEVPagoModerador,
										consecutivo = u.usuarioId
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
										consecutivo = u.usuarioId
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
                                        --h.codDiagnosticoPrincipalE,
                                        ISNULL( NULLIF(h.codDiagnosticoPrincipalE,''), 'null') codDiagnosticoPrincipalE,
                                        --h.codDiagnosticoRelacionadoE1,
                                        ISNULL( NULLIF(h.codDiagnosticoRelacionadoE1,''), 'null') codDiagnosticoRelacionadoE1,
                                        --h.codDiagnosticoRelacionadoE2,
                                        ISNULL( NULLIF(h.codDiagnosticoRelacionadoE2,''), 'null') codDiagnosticoRelacionadoE2,
                                        --h.codDiagnosticoRelacionadoE3,
                                        ISNULL( NULLIF(h.codDiagnosticoRelacionadoE3,''), 'null') codDiagnosticoRelacionadoE3,
                                        ISNULL( NULLIF(h.codComplicacion,''), 'null') codComplicacion,
                                        ISNULL( NULLIF(h.codDiagnosticoCausaMuerte,''), 'null') codDiagnosticoCausaMuerte,
										h.condicionDestinoUsuarioEgreso,
										h.fechaInicioAtencion,
										h.fechaEgreso,
										consecutivo = u.usuarioId
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
										consecutivo = u.usuarioId
									FROM @RECIEN r
									WHERE r.usuarioId = u.usuarioId
									FOR JSON PATH
								),
								medicamentos = (
									SELECT 
										m.codPrestador,
										m.numAutorizadon,
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
										consecutivo = u.usuarioId
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
										os.numFEVPagoModerador,
										consecutivo = u.usuarioId
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
	END
	IF 1=1
	BEGIN
		SELECT @base64 = cast('' as xml).value('xs:base64Binary(sql:column("binaryValue"))', 'varchar(max)')
		from (
			select [binaryValue] = cast(dbo.FNK_AttachedDocument(@CNSFCT,'FV') as varbinary(max))
		) as conv;
		IF @TIPOCAP<>1
		BEGIN
			SELECT @PLANO=REPLACE(@PLANO,'@XMLFEVFILE',@base64)
		END
		ELSE
		BEGIN
         SET @json ='{ '
			SET @json +=' "xmlFevFile" :"'+@base64+'" '
			SET @json +='	}'
			SELECT @PLANO=@json
		END
	END
	IF COALESCE(@URL_PATH,'')<>''
	BEGIN
		SELECT @N_FACTURA=@N_FACTURA+'.json'
		EXEC SPK_GUARDAR_ARCHIVO @PLANO, @URL_PATH, @N_FACTURA
		SELECT @PLANO= @URL_PATH+IIF(RIGHT(@URL_PATH,1)='\','','\')+@N_FACTURA 
	END
	PRINT 'FINALIZO EN SPK_RIPS_JSON_FTR_CAPI'
END

