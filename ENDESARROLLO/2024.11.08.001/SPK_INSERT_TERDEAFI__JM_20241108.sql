IF EXISTS(SELECT NAME FROM SYSOBJECTS WHERE NAME = 'SPK_INSERT_TERDEAFI' AND XTYPE='P')
BEGIN
   DROP PROCEDURE SPK_INSERT_TERDEAFI
END

GO
CREATE PROCEDURE DBO.SPK_INSERT_TERDEAFI  
@IDAFILIADO VARCHAR(20),  
@IDCATEGORIA VARCHAR(10),
@PROCE       VARCHAR(10)=NULL,
@NOADMISION  VARCHAR(20)=NULL,
@IDSEDE      VARCHAR(20)='01'
WITH ENCRYPTION
AS  
DECLARE @TIPOTERCONTABLE VARCHAR(10)  
DECLARE @IDPLAN          VARCHAR(6)  
DECLARE @IDTARIFA        VARCHAR(5)  
DECLARE @DOCUMENTO       VARCHAR(20) 
DECLARE @IDTERCERO       VARCHAR(20)
DECLARE @IDTERCEROPART   VARCHAR(20)
DECLARE @IDACTIVIDAD     VARCHAR(20)  
DECLARE @COD_RESP_FISCAL VARCHAR(20)
DECLARE @CREA_TER        BIT=0
BEGIN
   IF COALESCE(@IDAFILIADO,'')=''
   BEGIN
      RETURN
   END
   SELECT @DOCUMENTO =DOCIDAFILIADO FROM AFI WHERE IDAFILIADO=@IDAFILIADO  
   --VALIDO QUE EL DOCIDAFILIADO Y EL NIT SEAN LOS MISMOS -->SI NO SE ACTUALIZA PARA QUE QUEDEN IGUALES
   IF EXISTS(SELECT * FROM TER WHERE IDTERCERO=@IDAFILIADO AND ESTADO='Activo' )
	BEGIN
      PRINT 'INGRESO ACA'
	   IF  EXISTS(SELECT * FROM TER WHERE  IDTERCERO=@IDAFILIADO AND   NIT = @DOCUMENTO )
	   BEGIN
	      PRINT 'IDTERCERO Y NIT IGUALES ACTULIZO LOS CAMPOS DE RUC'
         UPDATE AFI SET RUC=TER.IDTERCERO FROM TER INNER JOIN AFI ON AFI.IDAFILIADO=TER.IDTERCERO 
         WHERE TER.ESTADO='Activo'
         AND AFI.IDAFILIADO=@IDAFILIADO

         SELECT @IDTERCERO=@IDAFILIADO
	   END
      ELSE 
      BEGIN 
         PRINT' IDTERCERO IGUAL DOCUMENTOS DIFERNETES ACTUALIZO TER NIT SELECT TOP 1 * FROM TER '
         UPDATE TER SET NIT=AFI.DOCIDAFILIADO,TIPO_ID=AFI.TIPO_DOC,DV=DBO.FNK_CALCULA_DV(AFI.DOCIDAFILIADO)
         FROM TER INNER JOIN AFI ON AFI.IDAFILIADO=TER.IDTERCERO
         WHERE TER.ESTADO='Activo'
         AND TER.IDTERCERO=@IDAFILIADO

         UPDATE AFI SET RUC=TER.IDTERCERO 
         FROM TER INNER JOIN AFI ON AFI.IDAFILIADO=TER.IDTERCERO 
         WHERE TER.ESTADO='Activo'
         AND TER.IDTERCERO=@IDAFILIADO
         
         SELECT @IDTERCERO=@IDAFILIADO

      END
   END
   ELSE
   BEGIN
      PRINT 'ACA....'
      IF EXISTS( SELECT * FROM TER WHERE TER.IDTERCERO<>@IDAFILIADO AND TER.NIT=@DOCUMENTO )
      BEGIN
         PRINT 'INGRESO EN UN 2'
         IF EXISTS(SELECT * FROM TER WHERE TER.IDTERCERO<>@IDAFILIADO AND TER.NIT=@DOCUMENTO AND COALESCE(ESTADO,'')<>'Activo')
         BEGIN
            UPDATE TER SET ESTADO='Activo' WHERE TER.IDTERCERO<>@IDAFILIADO AND TER.NIT=@DOCUMENTO AND COALESCE(ESTADO,'')<>'Activo'
         END
         SELECT TOP 1 @IDTERCERO=IDTERCERO FROM TER WHERE NIT=@DOCUMENTO AND TER.ESTADO='Activo'

         PRINT COALESCE(@IDTERCERO,'NO TENGO NADA')
         PRINT COALESCE(@DOCUMENTO,'NO TENGO NADA')

         UPDATE TER SET TIPO_ID=AFI.TIPO_DOC, DV=DBO.FNK_CALCULA_DV(AFI.DOCIDAFILIADO)
         FROM TER INNER JOIN AFI ON TER.NIT=AFI.DOCIDAFILIADO
         WHERE AFI.IDAFILIADO=@IDAFILIADO
         AND TER.IDTERCERO=@IDTERCERO

         UPDATE AFI SET RUC=@IDTERCERO WHERE IDAFILIADO=@IDAFILIADO
      END
      ELSE 
      BEGIN
         PRINT 'DEBO CREAR EL TERCERO'
         SELECT @IDTERCERO=NULL,@CREA_TER=1
      END
   END
    IF @CREA_TER=1
    BEGIN
       SET @IDACTIVIDAD    =DBO.FNK_VALORVARIABLE('DEFAULT_PART_AEC')
       SET @COD_RESP_FISCAL=DBO.FNK_VALORVARIABLE('DEFAULT_PART_RF')
        IF @IDTERCERO IS NULL
        BEGIN
            EXEC SPK_GENCONSECUTIVO '01', @IDSEDE, '@TER', @IDTERCERO OUTPUT  
            SELECT @IDTERCERO = @IDSEDE + REPLACE(SPACE(10 - LEN(@IDTERCERO))+LTRIM(RTRIM(@IDTERCERO)),SPACE(1),0)
        END

        PRINT 'Se Inserta un Nuevo Afiliado como Tercero'
        INSERT INTO TER (
            IDTERCERO, RAZONSOCIAL, NIT, DV, TIPO_ID, 
            CIUDAD, DIRECCION, TELEFONOS, NIT_R, ESTADO,  
            ENVIODICAJA, MODOCOPAGO, DIASVTO, ESEXTRANJERO, NATJURIDICA,
            TIPOREGIMEN, EMAIL, IDACTIVIDAD, COD_RESP_FISCAL,
            PNOMBRE, SNOMBRE, PAPELLIDO, SAPELLIDO,RUC
        )  
        SELECT @IDTERCERO, LEFT(COALESCE(PAPELLIDO,'')+' '+ COALESCE(SAPELLIDO,'')+' '+COALESCE(PNOMBRE,'')+' '+COALESCE(SNOMBRE,''),120), DOCIDAFILIADO, DBO.FNK_CALCULA_DV(DOCIDAFILIADO), TIPO_DOC,
            CIUDAD, LEFT(DIRECCION,60), TELEFONORES, IDAFILIADO, 'Activo', 
            0, 'Normal', 0, 0, 'Natural',
            'S', EMAIL, @IDACTIVIDAD, @COD_RESP_FISCAL,
            PNOMBRE, SNOMBRE, PAPELLIDO, SAPELLIDO,RUC
        FROM AFI 
        WHERE IDAFILIADO=@IDAFILIADO

        UPDATE AFI SET RUC=@IDTERCERO WHERE IDAFILIADO=@IDAFILIADO
    END

    PRINT 'Insertando a la Categoria...'
    IF NOT EXISTS(SELECT * FROM TEXCA WHERE IDTERCERO=@IDTERCERO AND IDCATEGORIA=@IDCATEGORIA)
    BEGIN
        INSERT INTO TEXCA (IDTERCERO, IDCATEGORIA, ESTADO, TIPOIPS)  
        SELECT @IDTERCERO, @IDCATEGORIA, 'Activo', NULL  
    END

    IF NOT EXISTS(SELECT * FROM TEXCA WHERE IDTERCERO=@IDTERCERO AND IDCATEGORIA=DBO.FNK_VALORVARIABLE('TERCATCLIENTE'))
    BEGIN
        INSERT INTO TEXCA (IDTERCERO, IDCATEGORIA, ESTADO, TIPOIPS)  
        SELECT @IDTERCERO, DBO.FNK_VALORVARIABLE('TERCATCLIENTE'), 'Activo', NULL  
    END

    PRINT 'Creando un Plan Particular...'
    IF COALESCE(@PROCE,'')<>'' AND COALESCE(@NOADMISION,'')<>''
    BEGIN
        IF @PROCE='HADM'
            SELECT @IDPLAN=IDPLAN FROM HADM WHERE NOADMISION=@NOADMISION
        ELSE IF @PROCE='CIT'
            SELECT @IDPLAN=IDPLAN FROM CIT WHERE CONSECUTIVO=@NOADMISION
        ELSE IF @PROCE='CE'
            SELECT @IDPLAN=IDPLAN FROM AUT WHERE NOAUT=@NOADMISION
        ELSE
            SELECT @IDPLAN=DBO.FNK_VALORVARIABLE('IDPLANPART')
    END
    ELSE
    BEGIN
        SELECT @IDPLAN=DBO.FNK_VALORVARIABLE('IDPLANPART')
    END

    IF NOT EXISTS(SELECT * FROM PPT WHERE IDTERCERO=@IDTERCERO AND IDPLAN=@IDPLAN)
    BEGIN
        SET @IDTERCEROPART   = DBO.FNK_VALORVARIABLE('IDTERCEROPARTICULAR')  
        INSERT INTO PPT (IDTERCERO, IDPLAN, MTOPE, TOPE, DIASVTO, TIPOTERCONTABLE, MCARENCIA, LIQCARENCIA, MMINUTOSCIRDS, FECHAVENCIMIENTO, IDTARIFA, FACTOR, CAPITADO, MAXCITASMESAFI, MAXCITASINCMES, TIPORECOBRO, 
                        COBRACOPAGO, TIPOFACTURACION, BDPROPIA, IDMODELOPC, MEFARMACIA, MEDROGAALTA, TIPOLIQCX, IDMODELOPCA, IDMODELOPCH, NODESCUENTACOPAGO, CEAUTORIZADO, COPAGOIND, CAMBIACONT, IDCONTRATO, 
                        FACTPORAFU, RESUMEN, IMPRIMEEST, ESTADO, CODPRG, ITFC, CNSITFC, MABONO, PABONO, PNUMAUTORIZA_OBL, PFACTURARIND, MEVALOF, COBRAMULTA, IDFORMATOFTR, MFORMATOFACTURAIND, 
                        CEMDOSIAUTOM, REDONDEO, IMPRIMEIDALTERNA, RUBRO, IDTERCEROR, IDPLANR, IDTARIFAR, TIPORIPS, PIDECNT, PGP, CUOTATRIAGE, FORMULACE, IDADMINISTRADORA, PAQUETIZADO, RUBRO_ID)  
        SELECT @IDTERCERO, @IDPLAN,MTOPE, TOPE, DIASVTO, TIPOTERCONTABLE, MCARENCIA, LIQCARENCIA, MMINUTOSCIRDS, FECHAVENCIMIENTO, IDTARIFA, FACTOR, CAPITADO, MAXCITASMESAFI, MAXCITASINCMES, TIPORECOBRO, 
                COBRACOPAGO, TIPOFACTURACION, BDPROPIA, IDMODELOPC, MEFARMACIA, MEDROGAALTA, TIPOLIQCX, IDMODELOPCA, IDMODELOPCH, NODESCUENTACOPAGO, CEAUTORIZADO, COPAGOIND, CAMBIACONT, IDCONTRATO, 
                FACTPORAFU, RESUMEN, IMPRIMEEST, ESTADO, CODPRG, ITFC, CNSITFC, MABONO, PABONO, PNUMAUTORIZA_OBL, PFACTURARIND, MEVALOF, COBRAMULTA, IDFORMATOFTR, MFORMATOFACTURAIND, 
                CEMDOSIAUTOM, REDONDEO, IMPRIMEIDALTERNA, RUBRO, IDTERCEROR, IDPLANR, IDTARIFAR, TIPORIPS, PIDECNT, PGP, CUOTATRIAGE, FORMULACE, IDADMINISTRADORA, PAQUETIZADO, RUBRO_ID
        FROM PPT 
        WHERE IDTERCERO=@IDTERCEROPART
        AND IDPLAN=@IDPLAN
    END
END



