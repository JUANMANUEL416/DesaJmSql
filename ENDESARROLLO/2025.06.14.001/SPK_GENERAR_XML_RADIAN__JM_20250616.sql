CREATE OR ALTER PROCEDURE DBO.SPK_GENERAR_XML_RADIAN
	@ITEM INT,
	@PATH_URL VARCHAR(MAX)=NULL
	--@NOMBRE_XML NVARCHAR(1000) OUTPUT,
	--@AMBIENTE INT OUTPUT,
	--@TESTSETID VARCHAR(100) OUTPUT
WITH ENCRYPTION
AS
DECLARE  @XML				VARCHAR(MAX) = ''		,@SoftwareID			VARCHAR(100)
		,@SoftwarePIN		VARCHAR(100)			,@SoftwareSecurityCode	VARCHAR(400)
		,@MensajeError		VARCHAR(500)			,@DVNITPrestador		VARCHAR(1)
		,@NITPrestador		VARCHAR(30)				,@FECHAEMISION			DATETIME
		,@CNSRADIAN			VARCHAR(20)				,@NODOCUMENTO			VARCHAR(100)
		,@IssueDate			VARCHAR(10)				,@IssueTime				VARCHAR(20)
		,@CUDE				VARCHAR(100)			,@NitDocumento  		VARCHAR(30)	
		,@CodEvento			VARCHAR(10)				,@QRCode				VARCHAR(1000)
		,@UUID				VARCHAR(400)			,@RSOCIALFACTU			VARCHAR(512)
		,@schemeName_FACTURADOR	VARCHAR(50)			,@schemeVersionIDFACTU	VARCHAR(1)
		,@TaxLevelCodeFACTU VARCHAR(20)				,@RAZONSOCIAL_ADQ		VARCHAR(500)
		,@DVADQ				VARCHAR(1)				,@schemeNameADQ			VARCHAR(20)
		,@schemeVersionIDADQ VARCHAR(1)				,@DESCEVENTO			VARCHAR(512)
		,@TIPODOC			VARCHAR(3)				,@USUARIO				VARCHAR(20)
		,@NOMBRES_USUARIO	VARCHAR(250)			,@APELLIDOS_USUARIO		VARCHAR(250)
		,@schemeName_USUARIO VARCHAR(50)			,@DEPARTAMENTO_USUARIO	VARCHAR(100)
		,@CARGO_USUARIO		VARCHAR(50)				,@DOCID_USUARIO			VARCHAR(50)
		,@NOMBRE_XML NVARCHAR(1000)
BEGIN
	BEGIN TRY
		IF COALESCE(dbo.FNK_VALORVARIABLE('IDTERCERO_OFE'),'')=''
		BEGIN
			RAISERROR ('Variable de sistema IDTERCERO_OFE sin configurar', 16, 1); 
		END

		BEGIN -- Software
			SELECT @SoftwareID=COALESCE(DESCRIPCION,'') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='SOFTWARE' AND CODIGO='ID'
			SELECT @SoftwarePIN=COALESCE(DESCRIPCION,'') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='SOFTWARE' AND CODIGO='PIN'
			--SELECT @TestSetID=COALESCE(DESCRIPCION,'') FROM TGEN WHERE TABLA='FDIAN' AND CAMPO='SOFTWARE' AND CODIGO='TESTSETID'
			IF COALESCE(@SoftwareID,'')='' RAISERROR ('Identificador del Software es obligatorio. (TGEN => ''FDIAN'', ''SOFTWARE'', ''ID'')', 16, 1); 
			IF COALESCE(@SoftwarePIN,'')='' RAISERROR ('PIN del Software es obligatorio. (TGEN => ''FDIAN'', ''SOFTWARE'', ''PIN'')', 16, 1); 
			--SELECT @AMBIENTE = 1
		END

		-- Prestador de Servicio
		BEGIN
			SELECT @DVNITPrestador=DV
				--@TIPO_PERSONA=CASE WHEN NATJURIDICA='Juridica' THEN '1' ELSE '2' END 
				,@NITPrestador=LTRIM(RTRIM(NIT))
				,@RSOCIALFACTU=dbo.FNK_LIMPIATEXTO(RAZONSOCIAL,'0-9 A-Z().;:,')
				--,@DIRFACTU=dbo.FNK_LIMPIATEXTO(TER.DIRECCION, '0-9 A-Z().;:,') --='CARRERA 19 No 14-47'
				--,@CIUFACTU=TER.CIUDAD
				--,@NOMCIUFACTU=CIU.NOMBRE
				--,@NOMDEPFACTU=DEP.NOMBRE
				--,@CODPOSTALFACTU=CIU.CODPOSTAL
				--,@COD_RESPONSABILIDAD_FISCAL=TER.COD_RESP_FISCAL
				--,@CODDEPTOFACTU=DEP.COD_DIAN
				,@schemeName_FACTURADOR=(SELECT TOP 1 DATO1 FROM TGEN WHERE TABLA='GENERAL' AND CAMPO='TIPOIDENT' AND CODIGO=TER.TIPO_ID)
				--,@IDTERCERO_OFE = TER.IDTERCERO
				,@schemeVersionIDFACTU = CASE WHEN NATJURIDICA = 'Juridica' THEN 1 ELSE 2 END  -- 1 Persona Jurídica y asimiladas, 2 Persona Natural y asimiladas
				,@TaxLevelCodeFACTU = COD_RESP_FISCAL
			FROM TER 
			LEFT JOIN CIU ON CIU.CIUDAD=TER.CIUDAD 
			LEFT JOIN DEP ON CIU.DPTO=DEP.DPTO
			WHERE IDTERCERO=dbo.FNK_VALORVARIABLE('IDTERCERO_OFE')
		END


		IF COALESCE(@TaxLevelCodeFACTU,'')=''
		BEGIN
			RAISERROR ('El facturador electrónico no tiene definido un código de responsabilidad fiscal', 16, 1); 
		END

		-- Datos del Documento
		BEGIN
			SELECT @CNSRADIAN = CNSRADIAN
				,@CodEvento = CODEVENTO
				,@USUARIO = USUARIO
			FROM FRADIAND
			WHERE ITEM = @ITEM

			SELECT @DESCEVENTO = DESCRIPCION FROM TGEN WHERE TABLA='FRADIAN' AND CAMPO='EVENTOS' AND CODIGO=@CODEVENTO

			
			SELECT @NODOCUMENTO = NODOCUMENTO
				,@FECHAEMISION = FECHAEMISION
				,@NitDocumento =dbo.FNK_LIMPIATEXTO(NIT,'0-9') -- SE REALIZA LA LIMPIEZA DEL NIT
				,@UUID = UUID
				,@RAZONSOCIAL_ADQ = REPLACE(COALESCE(RAZONSOCIAL, FACTURADOR),'&','&amp;')
				,@TIPODOC = TIPODOC
			FROM FRADIAN
			WHERE CNSRADIAN = @CNSRADIAN

			IF ( COALESCE(@UUID,'')='' )
			BEGIN 
				SELECT @MensajeError = 'El CODIGO UUID del NODOCUMENTO: ' + @NODOCUMENTO + ' no corresponde, CNSRADIAN: '+ @CNSRADIAN
            PRINT 'Marco el item como error para que no se detenga el proceso de envio a la Dian'
            UPDATE FRADIAND SET OBSERVACION='Documento sin el xml Adjunto',ERROR=1 WHERE CNSRADIAN=@CNSRADIAN
				RAISERROR (@MensajeError, 16, 1); 
			END

			SELECT @IssueDate = REPLACE(CONVERT(VARCHAR,GETDATE(),102),'.','-')
						,@IssueTime = CONVERT(VARCHAR,GETDATE(),108)+'-05:00'

			
			IF NOT EXISTS(SELECT 1 FROM TER WHERE NIT=LTRIM(RTRIM(@NitDocumento)) AND COALESCE(ESTADO,'')='Activo')
			BEGIN
				SELECT @MensajeError = 'El tercero  '+@RAZONSOCIAL_ADQ+' con nit '+@NitDocumento+' no está configurado en los terceros'
				RAISERROR (@MensajeError, 16, 1); 
			END
			ELSE
			BEGIN
				SELECT TOP 1 
					@DVADQ = DV
					,@schemeNameADQ = (SELECT TOP 1 DATO1 FROM TGEN WHERE TABLA='GENERAL' AND CAMPO='TIPOIDENT' AND CODIGO=TER.TIPO_ID)
					,@schemeVersionIDADQ = CASE WHEN NATJURIDICA = 'Juridica' THEN 1 ELSE 2 END  -- 1 Jurídica, 2 Natural
				FROM TER 
				WHERE NIT=@NitDocumento
			END

		END

		IF NOT EXISTS(SELECT 1 FROM TER WHERE NIT = @NitDocumento AND TER.TIPO_ID IN (SELECT CODIGO FROM TGEN WHERE TABLA='GENERAL' AND CAMPO='TIPOIDENT'))
		BEGIN
			SELECT @MensajeError = 'Tipo de Identificación del Facturador Electrónico con NIT ' + @NitDocumento + ' no se encuentra en la tabla que dispone la DIAN (TGEN.TABLA = GENERAL, TGEN.CAMPO = TIPOIDENT, [TGEN.DATO1])'
			RAISERROR (@MensajeError, 16, 1); 
		END
		
		-- Usuario que realiza la acción
		BEGIN
			SELECT 
				@NOMBRES_USUARIO = NOMBRES
				,@APELLIDOS_USUARIO = APELLIDOS
				,@schemeName_USUARIO=(SELECT TOP 1 DATO1 FROM TGEN WHERE TABLA='GENERAL' AND CAMPO='TIPOIDENT' AND CODIGO=USUSU.TIPOIDENT)
				,@DEPARTAMENTO_USUARIO = DEPARTAMENTO
				,@CARGO_USUARIO = CARGO
				,@DOCID_USUARIO = DOCID
			FROM USUSU
			WHERE USUARIO = @USUARIO

			IF COALESCE(@NOMBRES_USUARIO,'')='' OR 
				COALESCE(@APELLIDOS_USUARIO,'')='' OR 
				COALESCE(@schemeName_USUARIO,'')='' OR 
				COALESCE(@DEPARTAMENTO_USUARIO,'')='' OR 
				COALESCE(@CARGO_USUARIO,'')='' OR 
				COALESCE(@DOCID_USUARIO,'')=''
			BEGIN
				SELECT @MensajeError = 'El usuario ' + COALESCE(@USUARIO,'') + ' no está del todo configurado para emitir eventos RADIAN'
				RAISERROR (@MensajeError, 16, 1); 
			END
		END

		SELECT @SoftwareSecurityCode = @NODOCUMENTO + @IssueDate + @IssueTime + @NITPrestador + @NitDocumento + @CodEvento + '1' + '01' + @SoftwarePIN
		SELECT @SoftwareSecurityCode = @SoftwareID + @SoftwarePIN + @NODOCUMENTO 
		SELECT @SoftwareSecurityCode = @SoftwareID + @SoftwarePIN + CAST(@ITEM AS VARCHAR)


		SELECT @QRCode = 'https://catalogo-vpfe.dian.gov.co/document/searchqr?documentkey=' + @UUID

		SELECT @CUDE = CAST(@ITEM AS VARCHAR)
			+ @IssueDate
			+ @IssueTime
			+ @NITPrestador
			+ @NitDocumento
			+ @CodEvento
			+ @NODOCUMENTO
			+ @TIPODOC
			+ @SoftwarePIN

		-- XML
		BEGIN
			SET @XML='<?xml version="1.0" encoding="UTF-8" standalone="no"?>'
			SET @XML+='<ApplicationResponse xmlns="urn:oasis:names:specification:ubl:schema:xsd:ApplicationResponse-2"
											xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
											xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
											xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
											xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"
											xmlns:sts="dian:gov:co:facturaelectronica:Structures-2-1"
											xmlns:xades="http://uri.etsi.org/01903/v1.3.2#"
											xmlns:xades141="http://uri.etsi.org/01903/v1.4.1#"
											xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
											xsi:schemaLocation="urn:oasis:names:specification:ubl:schema:xsd:ApplicationResponse-2 http://docs.oasis-open.org/ubl/os-UBL-2.1/xsd/maindoc/UBL-ApplicationResponse-2.1.xsd">
				<ext:UBLExtensions>
					<ext:UBLExtension>
						<ext:ExtensionContent>
							<sts:DianExtensions>
								<sts:InvoiceSource>
									<cbc:IdentificationCode listAgencyID="6" listAgencyName="United Nations Economic Commission for Europe" listSchemeURI="urn:oasis:names:specification:ubl:codelist:gc:CountryIdentificationCode-2.1">CO</cbc:IdentificationCode>
								</sts:InvoiceSource>
								<sts:SoftwareProvider>
									<sts:ProviderID schemeID="@DVNITPrestador"
													schemeName="31"
													schemeAgencyID="195"
													schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)">@NITPrestador</sts:ProviderID>
									<sts:SoftwareID schemeAgencyID="195"
													schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)">@SoftwareID</sts:SoftwareID>
								</sts:SoftwareProvider>
								<sts:SoftwareSecurityCode schemeAgencyID="195"
														schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)">@SoftwareSecurityCode</sts:SoftwareSecurityCode>
								<sts:AuthorizationProvider>
									<sts:AuthorizationProviderID 
																schemeAgencyID="195"
																schemeID="4"
																schemeName="31"
																schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)">800197268</sts:AuthorizationProviderID>
								</sts:AuthorizationProvider>
								<sts:QRCode>@QRCode</sts:QRCode>
							</sts:DianExtensions>
						</ext:ExtensionContent>
					</ext:UBLExtension>
					<ext:UBLExtension>
						<ext:ExtensionContent></ext:ExtensionContent>
					</ext:UBLExtension>
				</ext:UBLExtensions>
				<cbc:UBLVersionID>UBL 2.1</cbc:UBLVersionID>
				<cbc:CustomizationID>1</cbc:CustomizationID>
				<cbc:ProfileID>DIAN 2.1: ApplicationResponse de la Factura Electrónica de Venta</cbc:ProfileID>
				<cbc:ProfileExecutionID>@ProfileExecutionID</cbc:ProfileExecutionID>
				<cbc:ID>@ITEM</cbc:ID>
				<cbc:UUID schemeID="@schemeID" schemeName="CUDE-SHA384">@CUDE</cbc:UUID>
				<cbc:IssueDate>@IssueDate</cbc:IssueDate>
				<cbc:IssueTime>@IssueTime</cbc:IssueTime>
				<cbc:Note>@CUDE</cbc:Note>
				<cac:SenderParty>
					<cac:PartyTaxScheme>
						<cbc:RegistrationName>@RSOCIALFACTU</cbc:RegistrationName>
						<cbc:CompanyID schemeAgencyID="195"
									schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)"
									schemeID="@DVNITPrestador"
									schemeName="@schemeName_FACTURADOR"
									schemeVersionID="@schemeVersionIDFACTU">@NITPrestador</cbc:CompanyID>
						<cbc:TaxLevelCode listName="05">@TaxLevelCodeFACTU</cbc:TaxLevelCode>
						<cac:TaxScheme>
							<cbc:ID>01</cbc:ID>
							<cbc:Name>IVA</cbc:Name>
						</cac:TaxScheme>
					</cac:PartyTaxScheme>
				</cac:SenderParty>
				<cac:ReceiverParty>
					<cac:PartyTaxScheme>
						<cbc:RegistrationName>@RAZONSOCIAL_ADQ</cbc:RegistrationName>
						<cbc:CompanyID schemeAgencyID="195"
									schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)"
									schemeID="@DVADQ"
									schemeName="@schemeNameADQ"
									schemeVersionID="@schemeVersionIDADQ">@NitDocumento</cbc:CompanyID>
						<cac:TaxScheme>
							<cbc:ID>01</cbc:ID>
							<cbc:Name>IVA</cbc:Name>
						</cac:TaxScheme>
					</cac:PartyTaxScheme>
				</cac:ReceiverParty>
				<cac:DocumentResponse>
					<cac:Response>
						<cbc:ResponseCode listID="02">@CODEVENTO</cbc:ResponseCode>
						<cbc:Description>@DESCEVENTO</cbc:Description>
					</cac:Response>
					<cac:DocumentReference>
						<cbc:ID>@NODOCUMENTO</cbc:ID>
						<cbc:UUID schemeName="CUFE-SHA384">@UUID</cbc:UUID>
						<cbc:DocumentTypeCode>@TIPODOC</cbc:DocumentTypeCode>
					</cac:DocumentReference>
					<cac:IssuerParty>
						<cac:Person>
							<cbc:ID schemeID="@DV_USUARIO"
									schemeName="@schemeName_USUARIO">@DOCID_USUARIO</cbc:ID>
							<cbc:FirstName>@NOMBRES_USUARIO</cbc:FirstName>
							<cbc:FamilyName>@APELLIDOS_USUARIO</cbc:FamilyName>
							<cbc:JobTitle>@CARGO_USUARIO</cbc:JobTitle>
							<cbc:OrganizationDepartment>@DEPARTAMENTO_USUARIO</cbc:OrganizationDepartment>
						</cac:Person>
					</cac:IssuerParty>
				</cac:DocumentResponse>
			</ApplicationResponse>'
		END -- xml

		-- Sustitución de valores
		BEGIN
			SET @XML=REPLACE(@XML,'@DVNITPrestador', @DVNITPrestador)
			SET @XML=REPLACE(@XML,'@NITPrestador', @NITPrestador)
			SET @XML=REPLACE(@XML,'@SoftwareID', @SoftwareID)
			SET @XML=REPLACE(@XML,'@SoftwareSecurityCode', @SoftwareSecurityCode)
			SET @XML=REPLACE(@XML,'@QRCode', @QRCode)
			SET @XML=REPLACE(@XML,'@NODOCUMENTO', @NODOCUMENTO)
			SET @XML=REPLACE(@XML,'@ProfileExecutionID', '1') -- 1 Producción, 2 Pruebas
			SET @XML=REPLACE(@XML,'@schemeID', '1') -- 1 Producción, 2 Pruebas
			SET @XML=REPLACE(@XML,'@CUDE', @CUDE)
			SET @XML=REPLACE(@XML,'@IssueDate', @IssueDate)
			SET @XML=REPLACE(@XML,'@IssueTime', @IssueTime)
			SET @XML=REPLACE(@XML,'@RSOCIALFACTU', @RSOCIALFACTU)
			SET @XML=REPLACE(@XML,'@schemeName_FACTURADOR', @schemeName_FACTURADOR)
			SET @XML=REPLACE(@XML,'@DVNITPrestador', @DVNITPrestador)
			SET @XML=REPLACE(@XML,'@schemeVersionIDFACTU', @schemeVersionIDFACTU)
			SET @XML=REPLACE(@XML,'@TaxLevelCodeFACTU', @TaxLevelCodeFACTU)
			SET @XML=REPLACE(@XML,'@RAZONSOCIAL_ADQ', @RAZONSOCIAL_ADQ)
			SET @XML=REPLACE(@XML,'@DVADQ', @DVADQ)
			SET @XML=REPLACE(@XML,'@schemeNameADQ', @schemeNameADQ)
			SET @XML=REPLACE(@XML,'@schemeVersionIDADQ', @schemeVersionIDADQ)
			SET @XML=REPLACE(@XML,'@NitDocumento', @NitDocumento)
			SET @XML=REPLACE(@XML,'@CODEVENTO', @CodEvento)
			SET @XML=REPLACE(@XML,'@DESCEVENTO', @DESCEVENTO)
			SET @XML=REPLACE(@XML,'@NODOCUMENTO', @NODOCUMENTO)
			SET @XML=REPLACE(@XML,'@UUID', @UUID)
			SET @XML=REPLACE(@XML,'@TIPODOC', @TIPODOC)
			SET @XML=REPLACE(@XML,'@DOCID_USUARIO', @DOCID_USUARIO)
			SET @XML=REPLACE(@XML,'@NOMBRES_USUARIO', @NOMBRES_USUARIO)
			SET @XML=REPLACE(@XML,'@APELLIDOS_USUARIO', @APELLIDOS_USUARIO)
			SET @XML=REPLACE(@XML,'@DEPARTAMENTO_USUARIO', @DEPARTAMENTO_USUARIO)
			SET @XML=REPLACE(@XML,'@CARGO_USUARIO', @CARGO_USUARIO)
			SET @XML=REPLACE(@XML,'@schemeName_USUARIO', @schemeName_USUARIO)
			SET @XML=REPLACE(@XML,'@DV_USUARIO', DBO.FNK_CALCULA_DV(@DOCID_USUARIO))
			SET @XML=REPLACE(@XML,'@ITEM', CAST(@ITEM AS VARCHAR))
		END
	
	
	SET @NOMBRE_XML = @NODOCUMENTO + '.xml'

	IF @PATH_URL IS NULL
		SELECT @XML as [XML]
	ELSE
		EXEC SPK_GUARDAR_ARCHIVO @XML, @PATH_URL, @NOMBRE_XML;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;  
		SELECT @ErrorMessage=ERROR_MESSAGE(), @ErrorSeverity=ERROR_SEVERITY(), @ErrorState=ERROR_STATE();  
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);  
	END CATCH
END


