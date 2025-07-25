IF EXISTS(SELECT NAME FROM SYSOBJECTS WHERE NAME= 'SPK_FACTURACE_N_VF' AND XTYPE='P')
BEGIN
   DROP PROCEDURE SPK_FACTURACE_N_VF
END

GO
CREATE PROCEDURE DBO.SPK_FACTURACE_N_VF
@NOAUT        VARCHAR(16),
@NIT          VARCHAR(20),
@COMPANIA     VARCHAR(2),
@IDSEDE       VARCHAR(5),
@USUARIO      VARCHAR(12),
@PRE1         VARCHAR(6),
@PRE2         VARCHAR(6),
@PRE3         VARCHAR(6),
@PRE4         VARCHAR(6),
@PRE5         VARCHAR(6),
@PROC         VARCHAR(2),
@IDTERCEROCA1 VARCHAR(20),
@CETIPOHOSP   VARCHAR(6) = FALSE,  -- PARAM. Que Especifica el tipo de manejo de Planes - Contratos 
@IDPLANPAR    VARCHAR(6) = NULL    -- EL PLAN EN CEHOSP
WITH ENCRYPTION
AS 
DECLARE @IDAUT      VARCHAR(13)
DECLARE @NVOCONSEC  VARCHAR(20)
DECLARE @CNSFTR     VARCHAR(20)
DECLARE @CERRADA    SMALLINT
DECLARE @FACTURADA  SMALLINT
DECLARE @FACTURABLE SMALLINT
DECLARE @TIPOADM    VARCHAR(2)
DECLARE @IDTERCERO  VARCHAR(20)
DECLARE @IDPLAN     VARCHAR(6)
DECLARE @DATO       VARCHAR(80)
DECLARE @DATO1      VARCHAR(80)
DECLARE @IDTERCERO1 VARCHAR(20)  
DECLARE @OK         INT
DECLARE @CA         VARCHAR(15)
DECLARE @IDAFILIADO VARCHAR(20)
DECLARE @DV         SMALLINT
DECLARE @TV         VARCHAR(10)
DECLARE @CCOSTO     VARCHAR(20)
DECLARE @IDAREA     VARCHAR(20)
DECLARE @EC          SMALLINT
DECLARE @IDTERCEROF  VARCHAR(20)
DECLARE @IDTERPART   VARCHAR(20)
DECLARE @DESCUENTO   DECIMAL(14,2)
DECLARE @TIPODTO     VARCHAR(1)
DECLARE @VRTOTAL     DECIMAL(14,2)
DECLARE @VRSERV      DECIMAL(14,2)
DECLARE @VRCOPA      DECIMAL(14,2)
DECLARE @VRPACO      DECIMAL(14,2)
DECLARE @VRDTO       DECIMAL(14,2)
DECLARE @VRABONO     DECIMAL(14,2)
DECLARE @VEZ         INT
DECLARE @DATO3             VARCHAR(20)
DECLARE @TTEC              VARCHAR(10)
DECLARE @TIPOFACTURACION   VARCHAR(1)
DECLARE @NODESCUENTACOPAGO SMALLINT
DECLARE @CUENTACXC         VARCHAR(16)
DECLARE @DATOCCOSTO        VARCHAR(80)
DECLARE @SOAT              SMALLINT
DECLARE @CNSHACTRAN        VARCHAR(20)
DECLARE @IDTERCEROCA       VARCHAR(20)
DECLARE @SYS_COMPUTERNAME  VARCHAR(254)
BEGIN
   SET @SYS_COMPUTERNAME = HOST_NAME()
   -- SACAR DE DONDE SE TOMA EL CCOSTO
   
   SELECT @DATOCCOSTO = DATO FROM USVGS WHERE IDVARIABLE = 'CCOSTOENPRESTACION'
   
   PRINT 'INGRESE' 
      
      SELECT  @IDAUT  = IDAUT, @FACTURABLE = FACTURABLE,
              @IDAFILIADO = IDAFILIADO, @DESCUENTO = DESCUENTO, @TIPODTO = TIPODTO, 
              @CCOSTO=CCOSTO, 
              @CA = AUT.IMPUTABLE_A, @SOAT = SOAT,
              @CNSHACTRAN = CNSHACTRAN
      FROM    AUT 
      WHERE   NOAUT = @NOAUT                
      
      SELECT @DATO3 = LEFT(DATO,20) FROM USVGS WHERE IDVARIABLE = 'IDFDEPFACTURACION'           
         
      DECLARE CUR_FTR CURSOR FOR
      SELECT DISTINCT AUTD.IDTERCEROCA, AUTD.IDPLAN   
      FROM   AUT INNER JOIN AUTD ON AUTD.IDAUT       = AUT.IDAUT 
      WHERE  AUT.NOAUT = @NOAUT 
      AND    (AUT.FACTURADA  = 0 OR AUT.FACTURADA  IS NULL OR AUT.FACTURADA=2) 
      AND    (AUTD.FACTURADA = 0 OR AUTD.FACTURADA IS NULL) 
      
      OPEN CUR_FTR
      FETCH NEXT FROM CUR_FTR
      INTO @IDTERCERO, @IDPLAN
      WHILE @@FETCH_STATUS = 0  
      BEGIN  
         SELECT @IDTERCERO1 = @IDTERCERO
         
         SELECT @TIPOFACTURACION   = TIPOFACTURACION, 
                @NODESCUENTACOPAGO = NODESCUENTACOPAGO
         FROM   PPT
         WHERE  IDTERCERO = @IDTERCERO
         AND    IDPLAN    = @IDPLAN
         
         IF @CA = 'Administadora' 
         BEGIN   
            SELECT @DV = DIASVTO, @TTEC = TIPOTERCONTABLE
            FROM   PPT 
            WHERE  IDTERCERO = @IDTERCERO AND IDPLAN = @IDPLAN
            
            SELECT @CUENTACXC = CUENTA FROM TTEC
            WHERE TIPO = @TTEC   
            IF @DV IS NULL
               SELECT @DV = 30
            IF @DV = 0
               SELECT @DV = 30 
              
            SELECT @TV = 'Credito'
            SELECT @EC = ENVIODICAJA FROM TER WHERE IDTERCERO = @IDTERCERO
            
            IF @EC IS NULL
            BEGIN
               SELECT @EC = 0
            END
            print 'envio directo caja = '+str(@ec)     
            SELECT @IDTERPART = DATO FROM USVGS WHERE IDVARIABLE = 'IDCJTERCEROEXTERNO'
               
            IF @IDTERCERO1 = @IDTERPART OR @IDPLAN = DBO.FNK_VALORVARIABLE('IDPLANPART')
                                        OR @IDPLAN = DBO.FNK_VALORVARIABLE('IDPLANPART2')
                                        OR @IDPLAN = DBO.FNK_VALORVARIABLE('IDPLANPART3')
                                        OR @IDPLAN = DBO.FNK_VALORVARIABLE('IDPLANPART4')
                                        OR @IDPLAN = DBO.FNK_VALORVARIABLE('IDPLANPART5')
            BEGIN   
               SELECT @TV = 'Contado'           
               SELECT @IDTERCEROF = @IDAFILIADO
               SELECT @EC = 1
            END 
            ELSE
            BEGIN
               SELECT @IDTERCEROF = @IDTERCERO1
            END
         END
         IF @CA = 'Afiliado'
         BEGIN
            SELECT @DV = DIASVTO, @TTEC = TIPOTERCONTABLE 
            FROM   PPT WHERE IDTERCERO = @IDTERCERO AND IDPLAN = @IDPLAN
            SELECT @CUENTACXC = CUENTA FROM TTEC
            WHERE TIPO = @TTEC   
            
            IF @DV IS NULL
               SELECT @DV = 30
            IF @DV = 0
               SELECT @DV = 30 
            
            SELECT @EC = ENVIODICAJA FROM TER WHERE IDTERCERO = @IDTERCERO1
            IF @EC IS NULL
               SELECT @EC = 0
            IF @EC = 1
               SELECT @TV = 'Contado'
            ELSE 
               SELECT @TV = 'Credito'
            
            SELECT @IDTERCEROF = @IDTERCERO1
         END         
         IF @IDTERCEROF IS NULL
         BEGIN
            PRINT '@IDTERCEROF IS NULL'
         END
         PRINT 'TERCERO F = '+@IDTERCEROF
         SELECT @DATO = DATO FROM USVGS WHERE IDVARIABLE = 'IDMONEDABASE'
         SELECT @OK   = COUNT(*) FROM TER WHERE IDTERCERO = @IDTERCEROF
                 
         IF  @OK IS NULL
         BEGIN
             SELECT @OK = 0
         END
          
         IF @OK = 0
         BEGIN
            INSERT INTO TER(IDTERCERO, RAZONSOCIAL, NIT, DV, TIPO_ID, DIRECCION,
                        CIUDAD, TELEFONOS, ESTADO, ENVIODICAJA, MODOCOPAGO,
                        DIASVTO, ESEXTRANJERO)
            SELECT @IDTERCEROF, LTRIM(RTRIM(AFI.PAPELLIDO))+' '+LTRIM(RTRIM(AFI.SAPELLIDO))+' '+LTRIM(RTRIM(AFI.PNOMBRE))+' '+LTRIM(RTRIM(AFI.SNOMBRE)), 
                   @IDTERCEROF, 0, '', AFI.DIRECCION, AFI.CIUDAD, AFI.TELEFONORES, 'Activo',
                   1, 'Normal', 0, 0
            FROM AFI WHERE IDAFILIADO = @IDAFILIADO
         END            
         
         CREATE TABLE #FTRD1(CNSFTR VARCHAR(40), N_CUOTA	int IDENTITY, FECHA datetime,
                      DB_CR varchar(2), AREAPRESTACION varchar(20), UBICACION varchar(16),
                      VR_TOTAL float, IMPUTACION varchar(16), CCOSTO varchar (20),
                      PREFIJO varchar(6), ANEXO varchar(1024), REFERENCIA varchar(40), 
                      IDCIRUGIA varchar(20), CANTIDAD smallint, VALOR decimal(14,2),
                      VLR_SERVICI decimal(14,2), VLR_COPAGOS decimal(14,2),
                      VLR_PAGCOMP decimal(14,2), IDPROVEEDOR varchar(20),
                      NOADMISION varchar(16), NOPRESTACION	varchar(16), NOITEM int,	
                      AREAFUNCONT varchar(20), N_FACTURA varchar(16),
                      SUBCCOSTO varchar(4), PCOSTO	decimal(14,2), FECHAPREST datetime,PROCEDENCIA VARCHAR(10),TCOPAGO VARCHAR(10))
         
         INSERT INTO #FTRD1(CNSFTR, FECHA, DB_CR, AREAPRESTACION, UBICACION, VR_TOTAL,
                    IMPUTACION, CCOSTO, PREFIJO, ANEXO, REFERENCIA, IDCIRUGIA, CANTIDAD,
                    VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, IDPROVEEDOR, NOADMISION,
                    NOPRESTACION, NOITEM, AREAFUNCONT, N_FACTURA, SUBCCOSTO, PCOSTO, FECHAPREST,PROCEDENCIA,TCOPAGO)
         SELECT @CNSFTR, GETDATE(), 'DB', AUT.IDAREA, NULL, 
                   (AUTD.CANTIDAD * AUTD.VALOR) - CASE WHEN @NODESCUENTACOPAGO = 1 THEN 0 ELSE ROUND(((AUTD.CANTIDAD * AUTD.VALOR) * AUT.VALORCOPAGO) / AUT.VALORTOTAL,0) END, 
                   NULL, CASE WHEN @DATOCCOSTO = 'SER:CCOSTO' THEN AUTD.CCOSTO ELSE AUT.CCOSTO END, SER.PREFIJO, SER.DESCSERVICIO, AUTD.IDSERVICIO, NULL,
                   AUTD.CANTIDAD, AUTD.VALOR, (AUTD.CANTIDAD * AUTD.VALOR), 
                   CASE WHEN @NODESCUENTACOPAGO = 1 THEN 0 ELSE ROUND(((AUTD.CANTIDAD * AUTD.VALOR) * AUT.VALORCOPAGO) / AUT.VALORTOTAL,0) END, --AUTD.VALORCOPAGO,
                   0, AUT.IDPROVEEDOR, @NOAUT, @NOAUT, AUTD.NO_ITEM, NULL, 
                   @NVOCONSEC, AUT.SUBCCOSTO, AUTD.VALORTOTALCOSTO,AUT.FECHA,'CE',
                   DBO.FNK_TRAE_TIPOCOPAGO(AUT.NOAUT,'CE')
         FROM   AUT INNER JOIN AUTD ON AUTD.IDAUT     = AUT.IDAUT 
                    INNER JOIN SER  ON SER.IDSERVICIO = AUTD.IDSERVICIO
         WHERE  AUT.NOAUT = @NOAUT
         AND    (AUTD.FACTURADA=0 OR AUTD.FACTURADA IS NULL OR AUTD.FACTURADA=2)
         AND    AUTD.IDTERCEROCA = @IDTERCERO 
         AND    AUTD.IDPLAN = @IDPLAN
      
         SELECT @OK = COUNT(*) FROM #FTRD1
       
         IF @OK > 0
         BEGIN
            SET @NVOCONSEC = SPACE(20)
            EXEC SPK_GENNUMEROFACTURA @COMPANIA, @IDSEDE, NULL, @NVOCONSEC OUTPUT   
            PRINT ' N_FACTURA = '+ CASE WHEN @NVOCONSEC IS NULL THEN '' ELSE @NVOCONSEC END
            
            EXEC SPK_GENCONSECUTIVO @COMPANIA, @IDSEDE, '@CNSFTR',  @CNSFTR OUTPUT  
            SELECT @CNSFTR = @IDSEDE + REPLACE(SPACE(8 - LEN(@CNSFTR))+LTRIM(RTRIM(@CNSFTR)),SPACE(1),0)
            
            PRINT 'CNSFCT ='+@CNSFTR+' - N_FACTURA = ' + @NVOCONSEC
            
            INSERT INTO FTR(CNSFCT, COMPANIA, CLASE, IDTERCERO, N_FACTURA, F_FACTURA, F_VENCE,
                        VR_TOTAL, COBRADOR, VENDEDOR, MONEDA, OCOMPRA, ESTADO, F_CANCELADO,
                        IDAFILIADO, EMPLEADO, NOREFERENCIA, PROCEDENCIA, TIPOFAC, OBSERVACION,
                        TIPOVENTA, VALORCOPAGO, DESCUENTO, VALORPCOMP, CREDITO, INDCARTERA,
                        INDCXC, MARCACONT, CONTABILIZADA, NROCOMPROBANTE, MARCA, INDASIGCXC,
                        IMPRESO, VALORSERVICIOS, CLASEANULACION, CNSLOG, USUARIOFACTURA, FECHAFAC,
                        MIVA, PIVA, VR_ABONOS, IDPLAN, FECHAPASOCXC, TIPOFIN, CNSFMAS, IDAREA_ALTA,
                        CCOSTO_ALTA, IDDEP, TIPOTTEC, CUENTACXC, CAPITADA)
            SELECT @CNSFTR, @COMPANIA, 'C', @IDTERCERO, @NVOCONSEC, GETDATE(), GETDATE()+@DV,
                   0, NULL, NULL, LEFT(@DATO,2), NULL, 'P', NULL, @IDAFILIADO, @USUARIO, @NOAUT,
                   @PROC, 'I', '', @TV, 0, 0, 0, 0, 0, 0, 0, 0, NULL, 0, 0, 0, 0, NULL, NULL, @USUARIO,
                   GETDATE(), 0, 0, 0, @IDPLAN, NULL, 'C', NULL, @IDAREA, @CCOSTO, @DATO3, @TTEC,
                   @CUENTACXC, 0   
            
            UPDATE #FTRD1 SET 
            CANTIDAD    = CASE WHEN CANTIDAD    IS NULL THEN 0 ELSE CANTIDAD    END,
            VALOR       = CASE WHEN VALOR       IS NULL THEN 0 ELSE VALOR       END,
            VLR_SERVICI = CASE WHEN VLR_SERVICI IS NULL THEN 0 ELSE VLR_SERVICI END,
            VR_TOTAL    = CASE WHEN VR_TOTAL    IS NULL THEN 0 ELSE VR_TOTAL    END,
            VLR_COPAGOS = CASE WHEN VLR_COPAGOS IS NULL THEN 0 ELSE VLR_COPAGOS END,
            VLR_PAGCOMP = CASE WHEN VLR_PAGCOMP IS NULL THEN 0 ELSE VLR_PAGCOMP END
              
            INSERT INTO FTRD(CNSFTR, N_CUOTA, FECHA, DB_CR, AREAPRESTACION, UBICACION, VR_TOTAL,
                         IMPUTACION, CCOSTO, PREFIJO, ANEXO, REFERENCIA, IDCIRUGIA, CANTIDAD,
                         VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, IDPROVEEDOR, NOADMISION,
                         NOPRESTACION, NOITEM, AREAFUNCONT, N_FACTURA, SUBCCOSTO, PCOSTO, FECHAPREST,PROCEDENCIA,TCOPAGO)
            SELECT @CNSFTR, N_CUOTA, FECHA, DB_CR, AREAPRESTACION, UBICACION, VR_TOTAL,
                   IMPUTACION, CCOSTO, PREFIJO, ANEXO, REFERENCIA, IDCIRUGIA, CANTIDAD,
                   VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, IDPROVEEDOR, NOADMISION,
                   NOPRESTACION, NOITEM, AREAFUNCONT, @NVOCONSEC, SUBCCOSTO, PCOSTO, FECHAPREST,PROCEDENCIA,TCOPAGO            
            FROM   #FTRD1
             
            TRUNCATE TABLE #FTRD1 
               
            SELECT @VRTOTAL = SUM(VR_TOTAL), @VRSERV = SUM(VLR_SERVICI), @VRCOPA = SUM(VLR_COPAGOS),
                   @VRPACO  = SUM(VLR_PAGCOMP)
            FROM FTRD WHERE N_FACTURA = @NVOCONSEC
                  
            IF @VRTOTAL < 0
               SELECT @VRTOTAL = 0
            
            UPDATE FTR SET VALORSERVICIOS = @VRSERV, VALORCOPAGO = @VRCOPA, VALORPCOMP = @VRPACO,
                      VR_TOTAL = @VRTOTAL
            WHERE N_FACTURA = @NVOCONSEC
            
            IF @DESCUENTO IS NULL
               SELECT @DESCUENTO = 0
             
            IF @DESCUENTO > 0
            BEGIN
               IF @TIPODTO = 'P'
                  SELECT @VRDTO = ROUND(@VRTOTAL * (@DESCUENTO/100),0)
               ELSE 
                  SELECT @VRDTO = @DESCUENTO 
            END           
            ELSE
               SELECT @VRDTO = 0
            
            IF @VRABONO IS NULL
               SELECT @VRABONO = 0
            
            UPDATE FTR SET DESCUENTO = @VRDTO, VR_ABONOS = @VRABONO
            WHERE  N_FACTURA = @NVOCONSEC
            
            IF @VRCOPA = 0 AND (   @IDPLAN <> DBO.FNK_VALORVARIABLE('IDPLANPART') 
                                OR @IDPLAN <> DBO.FNK_VALORVARIABLE('IDPLANPART2') 
                                OR @IDPLAN <> DBO.FNK_VALORVARIABLE('IDPLANPART3') 
                                OR @IDPLAN <> DBO.FNK_VALORVARIABLE('IDPLANPART4') 
                                OR @IDPLAN <> DBO.FNK_VALORVARIABLE('IDPLANPART5') 
                               )
            BEGIN
               SELECT @VRCOPA = VALORCOPAGO FROM AUT WHERE NOAUT = @NOAUT
               UPDATE FTR SET VALORCOPAGO = @VRCOPA WHERE N_FACTURA = @NVOCONSEC
            END   
            
            UPDATE FTR SET VR_TOTAL = VALORSERVICIOS - VALORCOPAGO - VALORPCOMP -DESCUENTO - VR_ABONOS
            WHERE  N_FACTURA = @NVOCONSEC      
               
            UPDATE FTR SET VR_TOTAL = 0
            WHERE  VR_TOTAL < 0
            AND    N_FACTURA = @NVOCONSEC      
         
            IF @EC <> 1
            BEGIN
               EXEC SPK_FAC_IMPDEDUC @NIT, @CNSFTR, @NVOCONSEC, @VRSERV
            END
         
            UPDATE AUTD SET N_FACTURA=@NVOCONSEC, FACTURADA=1, CNSFCT=@CNSFTR
            FROM   AUTD INNER JOIN AUT ON AUTD.IDAUT = AUT.IDAUT 
                        LEFT  JOIN SER ON SER.IDSERVICIO = AUTD.IDSERVICIO
            WHERE  AUT.NOAUT        = @NOAUT
            AND    AUTD.IDTERCEROCA = @IDTERCERO
            AND   (AUTD.FACTURADA   = 0 OR AUTD.FACTURADA IS NULL OR AUTD.FACTURADA=2)
            AND    AUTD.IDPLAN      = @IDPLAN
         END    
         FETCH NEXT FROM CUR_FTR
         INTO @IDTERCERO, @IDPLAN
      END
      CLOSE CUR_FTR
      DEALLOCATE CUR_FTR
      
      UPDATE AUT 
      SET AUT.FACTURADA = 1, 
          AUT.CNSFCT    = @CNSFTR, AUT.VFACTURAS = 1,
	       AUT.MARCAFAC  = 0
      WHERE NOAUT = @NOAUT  
   

      DROP TABLE #FTRD1 
      IF (SELECT DBO.FNK_VALORVARIABLE('CONTABFACCE_AUTOM') ) = 'SI'
      BEGIN
         EXEC SPK_CONTAB_FTR @NVOCONSEC, @COMPANIA, @USUARIO, @SYS_COMPUTERNAME, @IDSEDE, ''
      END
END 


