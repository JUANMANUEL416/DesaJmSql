IF EXISTS(SELECT NAME FROM SYSOBJECTS WHERE NAME='FNK_LIQUIDAR_NOMI' AND XTYPE='TF')
BEGIN
 DROP FUNCTION FNK_LIQUIDAR_NOMI
END

GO
CREATE FUNCTION DBO.FNK_LIQUIDAR_NOMI(
	@COMPANIA VARCHAR(2), 
	@CODNOMINA VARCHAR(2),
	@ANO VARCHAR(4), 
	@MES VARCHAR(2), 
	@CODPAGO VARCHAR(5),
	@USUARIO VARCHAR(12),
	@SYS_COMPUTERNAME VARCHAR(255),
        @CNSPAGO VARCHAR(20)) 
RETURNS @TABLA
TABLE (COMPANIA         	VARCHAR(2)   COLLATE database_default, -- INGRESOS Y EGRESOS POR PERIODO Y EMPELADO EN NOMINA
       CODNOMINA        	VARCHAR(2)   COLLATE database_default,
       ANO              	VARCHAR(4)   COLLATE database_default, 
       MES              	VARCHAR(2)   COLLATE database_default, 
       CODPAGO          	VARCHAR(5)   COLLATE database_default, 
       NOMBRE_PERIODO   	VARCHAR(60)  COLLATE database_default,
       NUMDOC           	VARCHAR(20)  COLLATE database_default,
       NOMBRE_EMPLEADO  	VARCHAR(60)  COLLATE database_default, 
       IDAREA           	VARCHAR(20)  COLLATE database_default, 
       NOMBRE_AREA      	VARCHAR(45)  COLLATE database_default,
       CCOSTO                   VARCHAR(20)  COLLATE database_default,
       NOMBRE_CCOSTO            VARCHAR(100) COLLATE database_default,
       CODCARGO         	VARCHAR(20)  COLLATE database_default, 
       NOMBRE_CARGO     	VARCHAR(255) COLLATE database_default,
       NIVEL                    VARCHAR(10)  COLLATE database_default,
       GRADO                    VARCHAR(10)  COLLATE database_default,
       DETALLE_CARGO            VARCHAR(255) COLLATE database_default,
       CODCONCEPTO      	VARCHAR(20)  COLLATE database_default,
       NOMBRE_CONCEPTO  	VARCHAR(255) COLLATE database_default, 
       DETALLE                  VARCHAR(10)  COLLATE database_default,
       CANTIDAD                 DECIMAL(15,6),
       BASE_PRESTACIONES	VARCHAR(2)   COLLATE database_default,
       INFO                     VARCHAR(2)   COLLATE database_default,
       TIPO             	VARCHAR(7)   COLLATE database_default,
       VALOR            	DECIMAL(15,6),
       VALOR_APORTES            DECIMAL(15,6),
       TOTAL_NOMINA             DECIMAL(15,6),
       VALOR100P                DECIMAL(15,6),
       BASICO                   DECIMAL(15,6),
       CVALOR100P               VARCHAR(2)   COLLATE database_default,
       USUARIO          	VARCHAR(12)  COLLATE database_default,
       SYS_COMPUTERNAME 	VARCHAR(255) COLLATE database_default,
       CODPRF           	VARCHAR(20)  COLLATE database_default,
       NOMBRE_PRF       	VARCHAR(100) COLLATE database_default,
       IDTERCERO_PRF    	VARCHAR(20)  COLLATE database_default,
       RAZONSOCIAL_PRF  	VARCHAR(120) COLLATE database_default,
       CERRADO          	SMALLINT,
       GENERADO         	SMALLINT,
       SEIMPRIME                VARCHAR(2)   COLLATE database_default,
       IDTRANSPRESTAMO		VARCHAR(6)   COLLATE database_default,
       NUMDOCPRESTAMO           VARCHAR(20)  COLLATE database_default,
       NUMCUOTA         	SMALLINT,
       LINEA                    SMALLINT,
       CODFINANCIACION          VARCHAR(20)  COLLATE database_default,
       CNSLIQRET          VARCHAR(20)  COLLATE database_default,
       IDSEDE          VARCHAR(5)  COLLATE database_default,
       CODUNG          VARCHAR(5)  COLLATE database_default)
AS 
BEGIN
-------------------------------------------------------------------------------------------------
--- INICIO
-------------------------------------------------------------------------------------------------
   DECLARE @FECHAINI DATETIME
   DECLARE @FECHAFIN DATETIME
   SELECT @FECHAINI = FECHAINI, @FECHAFIN = FECHAFIN FROM NPER WHERE CNSPAGO = @CNSPAGO
-------------------------------------------------------------------------------------------------
--- SELECT
-------------------------------------------------------------------------------------------------
   INSERT INTO @TABLA 
   SELECT  @COMPANIA AS COMPANIA,@CODNOMINA AS CODNOMINA, @ANO AS ANO, @MES AS MES, @CODPAGO AS CODPAGO, 
         LEFT(UPPER(NPPAG.DESCRIPCION)+' DE '+ DBO.FNK_NOMBRE_MES( @MES, 1) +' '+@ANO,60) AS NOMBRE_PERIODO,
         NEMPHIS.NUMDOC,LEFT(TER.RAZONSOCIAL,60) AS NOMBRE_EMPLEADO,
         AFU.IDAREA, AFU.DESCRIPCION AS NOMBRE_AREA, CEN.CCOSTO, CEN.DESCRIPCION AS NOMBRE_CCOSTO,
         NCARNG.CODCARGO,NCAR.DESCRIPCION AS NOMBRE_CARGO, NEMPHIS.NIVEL, NEMPHIS.GRADO, NCARNG.DESCRIPCION AS DETALLE_CARGO,
         NCON.CODCONCEPTO, NCON.DESCRIPCION AS NOMBRE_CONCEPTO, DETALLE, NEMPFD.CANTIDAD,	NEMPFD.BASE_PRESTACIONES,
         NCON.INFO, NCON.TIPO, NEMPFD.VALOR, NEMPFD.VALOR_EMPRESA, NEMPFD.VALOR+NEMPFD.VALOR_EMPRESA AS TOTAL_NOMINA, 
         NEMPFD.VALOR100P, NEMPHIS.BASICO, NCON.CVALOR100P,@USUARIO AS USUARIO, @SYS_COMPUTERNAME AS SYS_COMPUTERNAME, 
         NPRF.CODPRF AS CODPRF, NPRF.DESCRIPCION AS NOMBRE_PRF,TER_CXP.IDTERCERO AS IDTERCERO_PRF, 
         TER_CXP.RAZONSOCIAL AS RAZONSOCIAL_PRF, 0, 1, NCON.SEIMPRIME, NEMPFD.IDTRANSPRESTAMO, NEMPFD.NUMDOCPRESTAMO, 
         NEMPFD.NUMCUOTA, NEMPFD.LINEA, NULL,NEMPFD.CNSLIQRET,NPLA.IDSEDE,NPLA.CODUNG
   FROM NPER INNER JOIN NPPAG  ON NPER.CODPPAG  COLLATE database_default = NPPAG.CODPPAG COLLATE database_default
             INNER JOIN NEMPF  ON NEMPF.CNSPAGO COLLATE database_default = NPER.CNSPAGO  COLLATE database_default
             INNER JOIN NEMPFD ON NEMPF.NUMDOC  COLLATE database_default = NEMPFD.NUMDOC COLLATE database_default
                              AND NEMPF.CNSPAGO COLLATE database_default = NEMPFD.CNSPAGO COLLATE database_default
                              AND NEMPF.ITEM    COLLATE database_default = NEMPFD.ITEM    COLLATE database_default
                              AND NEMPFD.LIQUIDAR = 'Si' COLLATE database_default
             INNER JOIN FNK_INFO_NEMPHIS(@FECHAFIN) AS NEMPHIS ON NEMPFD.NUMDOC COLLATE database_default = NEMPHIS.NUMDOC COLLATE database_default
             INNER JOIN NCON   ON NEMPFD.CODCONCEPTO COLLATE database_default = NCON.CODCONCEPTO COLLATE database_default
             INNER JOIN NEMP    ON NEMP.NUMDOC      COLLATE database_default =  NEMPHIS.NUMDOC COLLATE database_default
             INNER JOIN TER    ON TER.IDTERCERO      COLLATE database_default =  NEMP.TERCEROID COLLATE database_default
             INNER JOIN NCARNG ON NEMPHIS.CODCARGO   COLLATE database_default = NCARNG.CODCARGO COLLATE database_default
                              AND NEMPHIS.GRADO      COLLATE database_default = NCARNG.GRADO COLLATE database_default
                              AND NEMPHIS.NIVEL      COLLATE database_default = NCARNG.NIVEL COLLATE database_default
             INNER JOIN AFU    ON NEMPHIS.IDAREA     COLLATE database_default = AFU.IDAREA  COLLATE database_default 
              LEFT JOIN CEN    ON NEMPHIS.CCOSTO     COLLATE database_default = CEN.CCOSTO COLLATE database_default
              LEFT JOIN NPRF   ON NEMPFD.CODPRF      COLLATE database_default = NPRF.CODPRF COLLATE database_default 
              LEFT JOIN TER TER_CXP ON NEMPFD.IDTERCERO COLLATE database_default = TER_CXP.IDTERCERO COLLATE database_default
              LEFT JOIN NCAR   ON NCARNG.CODCARGO COLLATE database_default = NCAR.CODCARGO COLLATE database_default
              LEFT JOIN NPLA   ON NEMPHIS.CODPLANTA=NPLA.CODPLANTA
   WHERE NPER.CNSPAGO = @CNSPAGO
   AND   NEMPHIS.FECHAMOV<=@FECHAFIN
   ORDER BY NEMPHIS.NUMDOC, NEMPFD.LINEA, NEMPHIS.FECHAMOV DESC

 UPDATE @TABLA SET CODFINANCIACION = PRS.CODFINANCIACION
 FROM @TABLA NIEPED INNER JOIN
      PRS ON NIEPED.NUMDOCPRESTAMO COLLATE database_default = PRS.NUMDOCUMENTO COLLATE database_default

 UPDATE @TABLA SET CODFINANCIACION = NEMPDA.CODFINANCIACION
 FROM @TABLA NIEPED INNER JOIN
      NEMPDA ON NIEPED.CODCONCEPTO COLLATE database_default = NEMPDA.CODCONCEPTO COLLATE database_default

 RETURN
END


