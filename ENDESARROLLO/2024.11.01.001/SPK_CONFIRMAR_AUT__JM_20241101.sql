IF EXISTS (SELECT NAME FROM SYSOBJECTS WHERE NAME = 'SPK_CONFIRMAR_AUT' AND TYPE = 'P')
BEGIN
   DROP PROCEDURE SPK_CONFIRMAR_AUT
END

GO
CREATE PROCEDURE DBO.SPK_CONFIRMAR_AUT
   @IDAUT VARCHAR(20)
WITH ENCRYPTION
AS
/* 
Fecha:		 2018-10-16
Descripci�n: Procedimiento que confirmar�, calcular� valores, copago, apoyo dx y recibo de caja
*/
DECLARE 
@COMPANIA      VARCHAR(2)
,@SEDE		   VARCHAR(5)
,@EQUIPO	   VARCHAR(254)
,@NOAUT        VARCHAR(20)
,@NOADMISION   VARCHAR(20)
,@IDTERCERO    VARCHAR(20)
,@IDPLAN       VARCHAR(20)
,@IDAREA       VARCHAR(20)
,@CCOSTO       VARCHAR(20)
,@IDAFILIADO   VARCHAR(20)
,@IDSERVICIO   VARCHAR(20)
,@USUARIO      VARCHAR(20)
,@IDPROVEEDOR  VARCHAR(20)
,@CNSHACTRAN   VARCHAR(20)
,@COPAGOPROPIO SMALLINT
,@SOAT         SMALLINT
,@ALTOCOSTO    SMALLINT
,@PYP          SMALLINT
,@FECHA        DATETIME
,@VALOR        DECIMAL(14,2)
,@VLRSERVICIO  DECIMAL(17,6)
,@NO_ITEM      INT
,@SQL          VARCHAR(MAX)
,@FIX		   INT
,@FIX_TO	   INT
,@MAXITEM INT
,@VLR_MOVI DECIMAL(14,2)
,@VLR_COPAFIJO DECIMAL(14,2)
,@VLR_COPAGOVAR DECIMAL(14,2)
,@VLR_PRCOPAFIJO DECIMAL(14,2)
,@VLR_PRCOPAGOVAR DECIMAL(14,2)
DECLARE @TABLE TABLE (
	ID			INT IDENTITY(1,1),
	NO_ITEM		INT,
	IDSERVICIO	VARCHAR(20),
	VALOR		DECIMAL(14,2)
)
BEGIN
	PRINT 'EXEC SPK_CONFIRMAR_AUT '+@IDAUT
	SET DATEFORMAT dmy

	SELECT 
		@COMPANIA	= '01',
		@SEDE		= IDSEDE,
		@NOAUT		= NOAUT,
        @IDTERCERO  = IDCONTRATANTE,
        @IDPLAN     = IDPLAN,
		@EQUIPO		= SYS_COMPUTERNAME,
		@IDAFILIADO = IDAFILIADO, 
		@USUARIO	= USUARIO, 
		@IDPROVEEDOR= IDPROVEEDOR, 
		@IDAREA		= IDAREA, 
		@FECHA		= FECHA, 
		@COPAGOPROPIO=COPAGOPROPIO, 
		@SOAT		= SOAT, 
		@CNSHACTRAN = CNSHACTRAN, 
		@ALTOCOSTO	= CASE AUT.ALTOCOSTO  WHEN 'Si' THEN 1 ELSE 0 END, 
		@PYP		= CASE AUT.CLASEORDEN WHEN 'PyP' THEN 1 ELSE 0 END
	FROM AUT WHERE IDAUT=@IDAUT

   PRINT 'Valido Movilidad'


   IF EXISTS(SELECT * FROM PPTCNT INNER JOIN AUT ON PPTCNT.IDTERCERO=AUT.IDTERCEROCA AND PPTCNT.IDPLAN=AUT.IDPLAN AND PPTCNT.PREFIJO=AUT.PREFIJO AND COALESCE(MOVILIDAD,0)=1)
   BEGIN
      IF EXISTS(SELECT * FROM AUT INNER JOIN AFI ON AUT.IDAFILIADO=AFI.IDAFILIADO
                                  INNER JOIN PPTMOVI ON PPTMOVI.IDTERCERO=AUT.IDTERCEROCA AND PPTMOVI.IDPLAN=AUT.IDPLAN 
                                                         AND AFI.CIUDAD=PPTMOVI.CIUDAD AND AFI.CORREGIMIENTO=PPTMOVI.DISTRITO
                WHERE AUT.IDAUT=@IDAUT)
      BEGIN
         IF NOT EXISTS(SELECT * FROM AUTD WHERE IDAUT=@IDAUT AND IDSERVICIO=DBO.FNK_VALORVARIABLE('IDSERMOVILIDAD'))
         BEGIN
            SELECT @VLR_MOVI=PPTMOVI.VALOR,@VLR_COPAGOVAR =PPTMOVI.COPAVAR,@VLR_PRCOPAGOVAR=PRCOPAVAR
            FROM AUT INNER JOIN AFI ON AUT.IDAFILIADO=AFI.IDAFILIADO
                                              INNER JOIN PPTMOVI ON PPTMOVI.IDTERCERO=AUT.IDTERCEROCA AND PPTMOVI.IDPLAN=AUT.IDPLAN 
                                                                     AND AFI.CIUDAD=PPTMOVI.CIUDAD AND AFI.CORREGIMIENTO=PPTMOVI.DISTRITO
            WHERE AUT.IDAUT=@IDAUT


            SELECT @MAXITEM=MAX(NO_ITEM) FROM AUTD WHERE IDAUT=@IDAUT

            INSERT INTO AUTD(IDAUT, NO_ITEM, IDSERVICIO, CANTIDAD, VALOR, VALORCOPAGO, VALORCOPAGOCOSTO, VALOREXCEDENTE, VALORTOTALCOSTO, IDPLAN, IMPRESO, 
                              AUTORIZADO, COMENTARIOS, PCOBERTURA, OBS, NORDEN, CCOSTO,  CODIGOCPCJ, MARCAPAGO, NOAUTORIZEXT, ESDELAB, ENLAB, IDTERCEROCA, 
                              IDCONTRATO, FACTURADA, N_FACTURA, CNSFCT, AQUIENCOBRO, MARCACOPAGOORDEN, VALORPROV, PCOSTO, ITFC, CNSITFC, SYS_COMPUTERNAME,  
                              NOCOBRABLE, MDOSIFICACION, CANTIDIA, DIAS, FRECUENCIA, CODCUPS, POSOLOGIA, SINCRONIZADO, APOYODG_AMBITO, CITAAUTORIZADA, 
                              DOSISAPL, DURACIONTTOF, DURACIONTTOC, CLASEPOSOLOGIA,  MARCA, USUARIOMARCA, NUM_ORDEN, PROCESADA, PRIORIDAD, HOMOLOGO, 
                              IDSERVICIOH, CANTIDADH, VALORHOMO, NO_ITEMH, N_FACTURAORI, DESCUENTO, TIPODTO, CNSFMED, F_INGLAB, F_SALILAB,  IDARTICULO, 
                              IMPORTADO, NFACTURA, N_CONDUCTOR, ID_CONDUCTOR, PLACA_AMB, PROTOCOLO, GENERADO, CONSECUTIVOCIT, COPAGO_FIJO, COPAGO_VARIABLE)
            SELECT IDAUT, NO_ITEM+1, DBO.FNK_VALORVARIABLE('IDSERMOVILIDAD'), 1, @VLR_MOVI, 0, 0, @VLR_MOVI, VALORTOTALCOSTO, IDPLAN, IMPRESO, AUTORIZADO,
                   COMENTARIOS, PCOBERTURA, OBS, NORDEN, CCOSTO,  CODIGOCPCJ, MARCAPAGO, NOAUTORIZEXT, ESDELAB, ENLAB, IDTERCEROCA, IDCONTRATO, FACTURADA, 
                   N_FACTURA, CNSFCT, AQUIENCOBRO, MARCACOPAGOORDEN, VALORPROV, PCOSTO, ITFC, CNSITFC, SYS_COMPUTERNAME,  NOCOBRABLE, MDOSIFICACION, 
                   CANTIDIA, DIAS, FRECUENCIA, CODCUPS, POSOLOGIA, SINCRONIZADO, APOYODG_AMBITO, CITAAUTORIZADA, DOSISAPL, DURACIONTTOF, DURACIONTTOC, 
                   CLASEPOSOLOGIA,  MARCA, USUARIOMARCA, NUM_ORDEN, PROCESADA, PRIORIDAD, HOMOLOGO, IDSERVICIOH, CANTIDADH, VALORHOMO, NO_ITEMH, N_FACTURAORI, 
                   DESCUENTO, TIPODTO, CNSFMED, F_INGLAB, F_SALILAB,  IDARTICULO, IMPORTADO, NFACTURA, N_CONDUCTOR, ID_CONDUCTOR, PLACA_AMB, PROTOCOLO, 
                   GENERADO, CONSECUTIVOCIT, 0, @VLR_COPAGOVAR
            FROM AUTD 
            WHERE IDAUT=@IDAUT
            AND NO_ITEM=@NO_ITEM

            PRINT 'DEFINO COPAGO'

            IF EXISTS(SELECT * FROM AUTD WHERE IDAUT=@IDAUT AND COALESCE(PROTOCOLO,0)=1)
            BEGIN
               UPDATE AUTD SET COPAGO_VARIABLE=@VLR_PRCOPAGOVAR,VALORCOPAGO=CASE WHEN COALESCE(@VLR_PRCOPAGOVAR,0)>0 THEN VALOR*(((100-@VLR_PRCOPAGOVAR)/100)) ELSE 0 END FROM AUTD WHERE IDAUT=@IDAUT AND NO_ITEM=@MAXITEM+1
            END
            ELSE
            BEGIN
               UPDATE AUTD SET COPAGO_VARIABLE=@VLR_COPAGOVAR,VALORCOPAGO=CASE WHEN COALESCE(@VLR_COPAGOVAR,0)>0 THEN VALOR*(((100-@VLR_COPAGOVAR)/100)) ELSE 0 END FROM AUTD WHERE IDAUT=@IDAUT AND NO_ITEM=@MAXITEM+1
            END
            UPDATE AUTD SET VALOREXCEDENTE=VALOR-VALORCOPAGO WHERE IDAUT=@IDAUT AND NO_ITEM=@MAXITEM+1
         END
      END

   END

	INSERT INTO @TABLE (NO_ITEM, IDSERVICIO, VALOR)
	SELECT NO_ITEM, IDSERVICIO, VALOR FROM AUTD WHERE IDAUT=@IDAUT AND IDSERVICIO<>DBO.FNK_VALORVARIABLE('IDSERMOVILIDAD')

	SELECT @FIX=1, @FIX_TO=COUNT(1) FROM @TABLE

	WHILE @FIX<=@FIX_TO
	BEGIN
		SELECT @NO_ITEM=NO_ITEM, @IDSERVICIO=IDSERVICIO, @VALOR=VALOR FROM @TABLE WHERE ID=@FIX
      

		PRINT 'V�lido valores'
      SELECT @VLRSERVICIO=VLRSERVICIO FROM SERTOT
      WHERE IDSERVICIO=@IDSERVICIO AND IDTERCERO=@IDTERCERO AND IDPLAN=@IDPLAN
            AND @FECHA BETWEEN FECHAINI AND FECHAFIN AND @FECHA BETWEEN FECHAINIFD AND FECHAFINFD

		UPDATE AUTD SET VALOR=@VLRSERVICIO
		FROM AUTD WHERE AUTD.IDAUT=@IDAUT AND AUTD.NO_ITEM=@NO_ITEM

      IF DBO.FNK_VALORVARIABLE('IXCOUNTRY')='PERU'
      BEGIN
         PRINT 'ACA IRIA EL COPAGO'
         EXEC SPK_ASIGNACOPAGOS_AUTPE @IDAUT,@NO_ITEM 
      END
      ELSE
      BEGIN
		   EXEC SPK_COPAGO_AUT_CEHOSP @IDAFILIADO,@IDAUT,@NO_ITEM,@IDSERVICIO,@PYP,@ALTOCOSTO,@VALOR,'CE',@EQUIPO,
									   @COMPANIA,@SEDE,@USUARIO,@IDPROVEEDOR,@IDAREA,@FECHA,@COPAGOPROPIO,@SOAT
		   IF @SOAT = 1
			   EXEC SPK_RELIQ_HACTRAN @CNSHACTRAN
      END
         


		-- AQUI INVESTIGAMOS SI ES DE LABORATORIO Y SI TENEMOS INTERFACE                    
		IF (SELECT DATO FROM USVGS WHERE IDVARIABLE='INTERFAZ_LX') = 'ANNARLAB' 
			AND (SELECT COUNT(1) FROM AUTD INNER JOIN SER ON AUTD.IDSERVICIO = SER.IDSERVICIO 
				 WHERE AUTD.IDAUT=@IDAUT AND AUTD.NO_ITEM=@NO_ITEM AND SER.AMBITO='LX') > 0
		BEGIN
			EXEC SPKI_LX_ENVIO_DATOS 'AUTD', @NOAUT, @NO_ITEM
		END
		ELSE
		BEGIN
			-- EZERPA 24.08.2018 ENVIAR SOLICITUD A INTERFAZ RAYOS X, TODAS LAS VALIDACIONES SE HACEN EN SPKI_RX_ENVIO_DATOS
			--IF (SELECT COUNT(1) FROM AUTD INNER JOIN SER ON AUTD.IDSERVICIO = SER.IDSERVICIO WHERE AUTD.IDAUT=@IDAUT AND AUTD.NO_ITEM=@NO_ITEM AND SER.AMBITO='RX') > 0
			IF (SELECT COUNT(1) FROM AUTD INNER JOIN SER ON AUTD.IDSERVICIO = SER.IDSERVICIO 
            WHERE AUTD.IDAUT=@IDAUT AND AUTD.NO_ITEM=@NO_ITEM AND SER.AMBITO IN (SELECT CODIGO FROM TGEN WHERE TABLA='APOYODG_AMBITO' AND CAMPO='ITF_IMG')) > 0
			BEGIN
				EXEC SPKI_RX_ENVIO_DATOS @PROCEDENCIA='AUTD', @NOPRESTACION = @NOAUT, @NOITEM = @NO_ITEM
			END
		END

        SET @FIX += 1
	END


	IF (SELECT DATO FROM USVGS WHERE IDVARIABLE='PREFIJOLABORATORIO')=(SELECT PREFIJO FROM AUT WHERE IDAUT=@IDAUT)
	BEGIN
		UPDATE AUT SET ESDELAB=1, ENLAB=0 WHERE IDAUT=@IDAUT
	END

	IF (SELECT SUM(COALESCE(VALORCOPAGO,0)) FROM AUTD WHERE IDAUT=@IDAUT)>0
	BEGIN
		IF (SELECT COALESCE(VALORCOPAGO,0) FROM AUTD WHERE IDAUT=@IDAUT AND COALESCE(MARCACOPAGOORDEN,0)=1)>0
		BEGIN
		PRINT 'Suma Copago por Orden'
		UPDATE AUT SET VALORCOPAGO=AUTD.VALORCOPAGO, TIPOCOPAGO='M'
		FROM AUT INNER JOIN AUTD ON AUTD.IDAUT=AUT.IDAUT
		WHERE AUT.IDAUT=@IDAUT AND COALESCE(MARCACOPAGOORDEN,0)=1
		END
		ELSE
		BEGIN
		PRINT 'Suma Copago por item'
		UPDATE AUT SET VALORCOPAGO=X.VALOR, TIPOCOPAGO='C'
		FROM (
			SELECT SUM(COALESCE(AUTD.VALORCOPAGO,0)) VALOR
			FROM AUT INNER JOIN AUTD ON AUTD.IDAUT=AUT.IDAUT
			WHERE AUT.IDAUT=@IDAUT
		)X 
		WHERE IDAUT=@IDAUT
		END
	END

	PRINT 'Sumo valores y cantidad de item'
	UPDATE AUT SET NO_ITEMES=X.CANTIDAD, VALORTOTAL=X.VALOR, VALOREXEDENTE=X.VALOR-VALORCOPAGO
	FROM (
		SELECT COUNT(1) CANTIDAD, SUM(ISNULL(AUTD.VALOR,0)*ISNULL(AUTD.CANTIDAD,0)) VALOR 
		FROM AUT INNER JOIN AUTD ON AUTD.IDAUT=AUT.IDAUT
		WHERE AUT.IDAUT=@IDAUT
	)X 
	WHERE IDAUT=@IDAUT

	IF (SELECT DATO FROM USVGS WHERE IDVARIABLE='CETIPOAUTORIZACION') = 'CEHOSP'
		IF (SELECT COALESCE(TIPOCAJA,'') FROM AUT WHERE IDAUT=@IDAUT) <> 'FCJ'
			EXEC SPK_PAGOSCAJA_AUT_CEHOSP @NOAUT, @EQUIPO, @COMPANIA, @SEDE, @USUARIO, 1

END


