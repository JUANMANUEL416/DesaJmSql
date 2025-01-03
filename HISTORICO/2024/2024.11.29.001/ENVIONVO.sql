DECLARE @JWT_QRYSTALOS VARCHAR(MAX)
DECLARE @TABLA_TMP AS TABLE (ITEM INT IDENTITY(1,1), RESPONSE VARCHAR(MAX))
DECLARE @sUrl VARCHAR(3096) = 'https://api-test.qrystalos.com/api/ususu/ingresar'
DECLARE @obj INT
DECLARE @response VARCHAR(max)
DECLARE @Body VARCHAR(max) = '{"COMPANIA": "PI", "USUARIO": "TEST", "CLAVE": "123456"}'

EXEC  dbo.SPK_GET_TRANSIENT
	@TRANSIENT =  'JWT_QRYSTALOS',
	@DATO = @JWT_QRYSTALOS OUT


IF COALESCE(@JWT_QRYSTALOS,'')=''
BEGIN
	
   EXEC sys.sp_OACreate 'MSXML2.ServerXMLHttp', @obj OUT

	EXEC sys.sp_OAMethod @obj, 'Open', NULL, 'POST', @sUrl, false
	--EXEC sys.sp_OAMethod @Obj, 'setRequestHeader', null, 'x-maytapi-key', @MAYTAPI_TOKEN_APIKEY
	EXEC sys.sp_OAMethod @Obj, 'setRequestHeader', null, 'Content-Type', 'application/json'
	EXEC SYS.sp_OAMethod @obj, 'send', null, @Body
	EXEC sys.sp_OAMethod @obj, 'responseText', @response OUTPUT

	IF @response IS NULL
	BEGIN
		INSERT INTO @TABLA_TMP(RESPONSE)
		EXEC sys.sp_OAGetProperty @obj, 'responseText'
		SELECT @response=RESPONSE FROM @TABLA_TMP
	END

	EXEC sys.sp_OADestroy @obj
   
   IF ISJSON(@RESPONSE)=1
   BEGIN
      SELECT @JWT_QRYSTALOS = JSON_VALUE(@response,'$.jwt')
   END

   IF COALESCE(@JWT_QRYSTALOS,'') <> ''
      EXEC dbo.SPK_SET_TRANSIENT @TRANSIENT = 'JWT_QRYSTALOS', @VALUE = @JWT_QRYSTALOS, @EXPIRATION = 360 -- 6 HORAS
END

IF COALESCE(@JWT_QRYSTALOS,'') = ''
   RETURN

SELECT @JWT_QRYSTALOS = 'Bearer ' + @JWT_QRYSTALOS

BEGIN
   SELECT @sUrl = 'https://api-test.qrystalos.com/api/rhapsody'
   SELECT @Body ='{
    "EPrefactura": {
        "PK_PREFAC": "8355903",
        "NU_PREFAC": "B001-00000027",
        "FE_PREFAC": "2024-11-23",
        "DE_EMP_EMISORA": "ATENCION DOMICILIARIA",
        "CO_SEDE_SAP": "1",
        "DE_CENTRO": "ATENCION DOMICILIARIA",
        "CO_SOCIEDAD_SAP": "CI10",
        "TI_FINANC": "1",
        "TI_INTERL": "1",
        "TI_ORIGEN": "1",
        "TI_DOCU_SUNAT": "4",
        "NU_DOCU_IDEN": "03450754",
        "NU_HIST_CLIN": "03450754",
        "NO_CLIENT": "ALBERTO JOSE",
        "AP_PATE_CLIE": "DOMINGUEZ",
        "AP_MATE_CLIE": "PRIETO",
        "DE_DIRE_CLIE": "AV COSTANERA 1572",
        "DE_EMAIL": "solanoomar82@gmail.com",
        "CO_PAIS_SSAP": "PE",
        "DE_PAIS": "PERÚ",
        "DE_PROV": "41401",
        "DE_DIST": "41401",
        "CO_REGI_SSAP": "41401",
        "DE_REGI": "LIMA",
        "NU_TELEF": "917365635",
        "NU_REME": "",
        "CO_POSTAL": "UBIGEO",
        "NU_PREF_ORIG": "",
        "CO_USUA_LOGI": "TEST",
        "IM_TOTA_BASE": "1",
        "IM_TOTA_IGV": "7.63",
        "IM_TOTAL": "",
        "CO_MONE": "PE",
        "DE_TIPO_DEPO": "",
        "CO_USUA_TRAN": "TEST",
        "CO_ORG_VTA_SAP": "CI10",
        "CO_CANAL_DIST": "1D",
        "CO_GRU_VEN_SAP": "GVL",
        "CO_OF_VTA_SAP": "O001",
        "TI_PACIENTE": "2",
        "CA_REME": "",
        "DES_COND_PAG": "",
        "CO_CENTRO_XHIS": "1008",
        "EPrefacturaDetalle": [
            {
                "PK_PREFAC": "151",
                "NU_PREFAC": "B001-00000027",
                "ID_ITEM_PREFA": "10",
                "PK_VALE_PREFA": "",
                "NU_ENCUENTRO": "010039944231",
                "TI_ENCUENTRO": "2",
                "CO_ASEGURA": "03450754",
                "CO_AUTORIZA": "",
                "CO_CARTA_GARA": "",
                "CO_MECA_SAP": "02",
                "CO_CEBE": "",
                "CO_GRUP_PRES": "HNOQ",
                "DE_GRUP_PRES": "HHMM NO QUIRURGICOS",
                "CO_PRES_ITEM": "ADMI003001",
                "DE_PRES_ITEM": "SERVICIO DE ATENCIÓN MÉDICA A DOMICILIO PACIENTE REGULAR",
                "NO_CORT_MEDI": "Pruebas Med",
                "DE_SERV_GAST": "Medicina g",
                "CA_ITEM": "1",
                "IM_PREC_BASE": "42.3700",
                "IM_BASE_ITEM": "42.3700",
                "IM_COPAGO": "50.00",
                "IM_REAL_GASTO": "50.0000",
                "NU_HIST_CLIN": "03450754",
                "NU_ORIG_PREF": "",
                "NO_PACIENTE": "DOMINGUEZ PRIETO ALBERTO JOSE",
                "NO_TITULAR": "DOMINGUEZ PRIETO ALBERTO JOSE",
                "DE_GARANTE": "DOMINGUEZ PRIETO ALBERTO JOSE",
                "DE_COMPANIA": "SITTEDS",
                "FE_INIC_VIGE": "SITTEDS",
                "FE_FINA_VIGE": "SITTEDS",
                "PC_COPAGO": "SITTEDS",
                "IM_DEDUCIBLE": "SITTEDS",
                "FE_INIC_ENCU": "20241123",
                "FE_FINA_ENCU": "20241123",
                "PC_IGV": "18",
                "CO_RUC_EMISOR": "20100054184",
                "DE_PLAN_COPA": "PAQ001",
                "CO_GARANTE": "36",
                "CO_SERV_ENCU": "Medicina g",
                "CO_PLAN_COPA": "PAQ001",
                "CO_SERV_GAST": "ADMI003001",
                "IM_DEDU_GAST": "50.00",
                "PC_COASEGU": "0",
                "CO_ESPE_SSAP": "Medicina g",
                "CO_SUB_MECA": "",
                "CO_SECTOR": "D1",
                "CO_TIPO_ATEN": "HNOQ",
                "ID_MEZCLA": "",
                "ID_TRAN_PAGO": "",
                "NU_CITA_XHIS": "010039944231",
                "TI_VENTA": "1",
                "IM_PAGO": "0",
                "CO_TIPO_ITEM": "I",
                "VA_DET_PADRE": ""
            }
        ]
    }
}'
   EXEC sys.sp_OACreate 'MSXML2.ServerXMLHttp', @obj OUT
   EXEC sys.sp_OAMethod @obj, 'Open', NULL, 'POST', @sUrl, false
	EXEC sys.sp_OAMethod @Obj, 'setRequestHeader', null, 'Authorization', @JWT_QRYSTALOS
   /****/
	EXEC sys.sp_OAMethod @Obj, 'setRequestHeader', null, 'EndPoint', '/FacturacionPaciente/PreFacturaPacienteEM'
   /****/
	EXEC sys.sp_OAMethod @Obj, 'setRequestHeader', null, 'Content-Type', 'application/json'
	EXEC SYS.sp_OAMethod @obj, 'send', null, @Body
	EXEC sys.sp_OAMethod @obj, 'responseText', @response OUTPUT

	IF @response IS NULL
	BEGIN
		INSERT INTO @TABLA_TMP(RESPONSE)
		EXEC sys.sp_OAGetProperty @obj, 'responseText'
		SELECT @response=RESPONSE FROM @TABLA_TMP
	END

	EXEC sys.sp_OADestroy @obj
   
   SELECT @response
END
