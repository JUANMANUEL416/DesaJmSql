IF EXISTS (SELECT name FROM sysobjects   WHERE name = 'SPK_CREACXP_ASIS_UNO' AND type = 'P')
BEGIN
   DROP PROCEDURE SPK_CREACXP_ASIS_UNO
END

GO
CREATE PROCEDURE DBO.SPK_CREACXP_ASIS_UNO
@NOPRESTACION  VARCHAR(16),
@NOITEM        SMALLINT,
@COMPANIA      VARCHAR(2),  
@SEDE          VARCHAR(5)  
WITH ENCRYPTION
AS      
BEGIN  
   DECLARE @NVOCONSEC INT  
   DECLARE @IDTERPROVE VARCHAR(20)  
   DECLARE @IDPROVEEDOR VARCHAR(20)
   DECLARE @VALOR DECIMAL(14,2)  
   DECLARE @IDSERVICIO   VARCHAR(20)    
   DECLARE @DESCSERVICIO VARCHAR(255)   
   DECLARE @IDAREA       VARCHAR(20)    
   DECLARE @IDCIRUGIA    VARCHAR(20)    
   DECLARE @PREFIJO      VARCHAR(6)     
   DECLARE @VALOR1       DECIMAL(14,2)  
   DECLARE @CANTIDAD     INT            
   DECLARE @N_FACTURA    VARCHAR(16)    
   DECLARE @CCOSTO       VARCHAR(20)    
   DECLARE @IDAREAH      VARCHAR(20)    
   DECLARE @IDTERCEROCA  VARCHAR(20)    
   DECLARE @IDPLAN       VARCHAR(6)     
   DECLARE @AUX          INT 
   DECLARE @NOADMISION   VARCHAR(20) 
   DECLARE @USUARIO      VARCHAR(16)         
   -----                                
  PRINT 'CAPTURANDO VARIABLES'
  SELECT @NOADMISION=HPRE.NOADMISION,@USUARIO=HPRE.USUARIO,@IDPROVEEDOR=HPRED.IDPROVEEDOR
  FROM HPRE  INNER JOIN HPRED  ON HPRE.NOPRESTACION=HPRED.NOPRESTACION
  WHERE HPRE.NOPRESTACION=@NOPRESTACION AND NOITEM=@NOITEM
  
  SELECT  @IDTERPROVE = IDTERCERO  FROM TER WHERE (NIT=@IDPROVEEDOR OR IDTERCERO=@IDPROVEEDOR) AND ESTADO='Activo'


  CREATE TABLE #ICXP (IDPROVEEDOR    VARCHAR(20)  COLLATE database_default, 
                       IDSERVICIO     VARCHAR(20) COLLATE database_default,  
                       VALOREXCEDENTE DECIMAL(14,2),                         
                       DESCSEVICIO    VARCHAR(255) COLLATE database_default,  
                       IDAREA         VARCHAR(20) COLLATE database_default, 
                       IDCIRUGIA      VARCHAR(20) COLLATE database_default ,
                       PREFIJO        VARCHAR(6) COLLATE database_default,  
                       VALOR          DECIMAL(14,2),
                       CANTIDAD       INT,
                       NOPRESTACION   VARCHAR(16) COLLATE database_default,  
                       NOITEM         SMALLINT ,
                       N_FACTURA      VARCHAR(16) COLLATE database_default, 
                       CCOSTO         VARCHAR(20) COLLATE database_default,
                       IDAREAH        VARCHAR(20) COLLATE database_default, 
                       ITEM           INT IDENTITY, 
                       IDTERCEROCA    VARCHAR(20) COLLATE database_default, 
                       IDPLAN         VARCHAR(6) COLLATE database_default, 
                       FACTOR         DECIMAL(14,2), 
                       VALORCXP       DECIMAL(14,2),
	                    FECHACARGO     DATETIME )
	                    
	IF (DBO.FNK_VALORVARIABLE('HONORATAR_DIF')='SI')
   BEGIN 
   IF (SELECT COALESCE(IDCIRUGIA,'') FROM HPRED WHERE NOPRESTACION=@NOPRESTACION AND NOITEM=@NOITEM)=''
   BEGIN
      PRINT 'INGRESO POR ACA'
      INSERT INTO #ICXP (IDPROVEEDOR, IDSERVICIO, VALOREXCEDENTE, DESCSEVICIO, IDAREA, IDCIRUGIA,
                            PREFIJO, VALOR, CANTIDAD, NOPRESTACION, NOITEM, N_FACTURA, CCOSTO,
                            IDAREAH, IDTERCEROCA, IDPLAN, FACTOR, VALORCXP, FECHACARGO )
      SELECT IDPROVEEDOR,PXSE.IDSERVICIO,VALOREXCEDENTE,DESCSERVICIO,IDAREA,IDCIRUGIA,SER.PREFIJO,
             CASE DBO.TARF.REDONDEO
              WHEN 'Unidad'   THEN round(DBO.TARDV.VALOR*DBO.PXSE.FACTOR*DBO.TARF.FACTORDINERO,0)
              WHEN 'Decena'   THEN round(DBO.TARDV.VALOR*DBO.PXSE.FACTOR*DBO.TARF.FACTORDINERO,-1)
              WHEN 'Centena'  THEN round(DBO.TARDV.VALOR*DBO.PXSE.FACTOR*DBO.TARF.FACTORDINERO,-2)
              WHEN 'Millar'   THEN round(DBO.TARDV.VALOR*DBO.PXSE.FACTOR*DBO.TARF.FACTORDINERO,-3)
              WHEN 'Dos Dec.' THEN ROUND(DBO.TARDV.VALOR*DBO.PXSE.FACTOR*DBO.TARF.FACTORDINERO,2)
              WHEN 'SIN'      THEN (DBO.TARDV.VALOR*DBO.PXSE.FACTOR*DBO.TARF.FACTORDINERO)
              ELSE round(DBO.TARDV.VALOR*DBO.PXSE.FACTOR*DBO.TARF.FACTORDINERO,0)
              END VALORTOTAL,HPRED.CANTIDAD,NOPRESTACION,HPRED.NOITEM,N_FACTURA,
              HPRED.CCOSTO,IDAREAH,IDADMINISTRADORA,PXSE.IDPLAN,FACTOR,CASE DBO.TARF.REDONDEO
              WHEN 'Unidad'   THEN round(DBO.TARDV.VALOR*DBO.PXSE.FACTOR*DBO.TARF.FACTORDINERO,0)
              WHEN 'Decena'   THEN round(DBO.TARDV.VALOR*DBO.PXSE.FACTOR*DBO.TARF.FACTORDINERO,-1)
              WHEN 'Centena'  THEN round(DBO.TARDV.VALOR*DBO.PXSE.FACTOR*DBO.TARF.FACTORDINERO,-2)
              WHEN 'Millar'   THEN round(DBO.TARDV.VALOR*DBO.PXSE.FACTOR*DBO.TARF.FACTORDINERO,-3)
              WHEN 'Dos Dec.' THEN ROUND(DBO.TARDV.VALOR*DBO.PXSE.FACTOR*DBO.TARF.FACTORDINERO,2)
              WHEN 'SIN'      THEN (DBO.TARDV.VALOR*DBO.PXSE.FACTOR*DBO.TARF.FACTORDINERO)
              ELSE round(DBO.TARDV.VALOR*DBO.PXSE.FACTOR*DBO.TARF.FACTORDINERO,0)
              END VALOR,FECHA
      FROM PXSE INNER JOIN HPRED  ON HPRED.IDSERVICIO=PXSE.IDSERVICIO
                INNER JOIN TARDV ON PXSE.IDTARIFA=TARDV.IDTARIFA AND TARDV.IDSERVICIO=HPRED.CODCUPS
                INNER JOIN TARF  ON TARDV.IDTARIFA=TARF.IDTARIFA
                INNER JOIN SER   ON SER.IDSERVICIO=PXSE.IDSERVICIO
      WHERE  HPRED.NOPRESTACION   = @NOPRESTACION  AND HPRED.NOITEM=@NOITEM AND SER.ESTADO='Activo'
   END
   ELSE
   BEGIN
      PRINT 'INGRESO POR ACA_ELSE'
      INSERT INTO #ICXP (IDPROVEEDOR, IDSERVICIO, VALOREXCEDENTE, DESCSEVICIO, IDAREA, IDCIRUGIA,
                         PREFIJO, VALOR, CANTIDAD, NOPRESTACION, NOITEM, N_FACTURA, CCOSTO,
                         IDAREAH, IDTERCEROCA, IDPLAN, FACTOR, VALORCXP, FECHACARGO )
      SELECT HPRED.IDPROVEEDOR,HPRED.IDSERVICIO,VALOREXCEDENTE,DESCSERVICIO,IDAREA,IDCIRUGIA,SER.PREFIJO,
                (DBO.FNK_SERVICIO_CUPS(HPRED.NOPRESTACION,HPRED.NOITEM)*TARDV.VALOR*PXS.FACTOR)
                  VALORTOTAL,HPRED.CANTIDAD,NOPRESTACION,HPRED.NOITEM,N_FACTURA,
                 HPRED.CCOSTO,IDAREAH,IDADMINISTRADORA,PXS.IDPLAN,FACTOR,
                 (DBO.FNK_SERVICIO_CUPS(HPRED.NOPRESTACION,HPRED.NOITEM)*TARDV.VALOR*PXS.FACTOR) VALOR,FECHA
      FROM HPRED INNER JOIN SER   ON SER.IDSERVICIO=HPRED.IDSERVICIO
                 INNER JOIN PXS   ON PXS.IDTERCERO=@IDTERPROVE AND PXS.IDPLAN=HPRED.IDPLAN
                 INNER JOIN TARDV ON PXS.IDTARIFA=TARDV.IDTARIFA AND TARDV.IDSERVICIO=SER.IDALTERNA
                 INNER JOIN TARF  ON TARDV.IDTARIFA=TARF.IDTARIFA
      WHERE  HPRED.NOPRESTACION   = @NOPRESTACION  AND HPRED.NOITEM=@NOITEM AND SER.ESTADO='Activo'
      GROUP BY IDPROVEEDOR,HPRED.IDSERVICIO,VALOREXCEDENTE,DESCSERVICIO,IDAREA,IDCIRUGIA,SER.PREFIJO,
                (DBO.FNK_SERVICIO_CUPS(HPRED.NOPRESTACION,HPRED.NOITEM)*TARDV.VALOR*PXS.FACTOR)
                  ,HPRED.CANTIDAD,NOPRESTACION,HPRED.NOITEM,N_FACTURA,
                 HPRED.CCOSTO,IDAREAH,IDADMINISTRADORA,PXS.IDPLAN,FACTOR,
                 (DBO.FNK_SERVICIO_CUPS(HPRED.NOPRESTACION,HPRED.NOITEM)*TARDV.VALOR*PXS.FACTOR),FECHA

   END
 END
 ELSE
 BEGIN                    
      INSERT INTO #ICXP (IDPROVEEDOR, IDSERVICIO, VALOREXCEDENTE, DESCSEVICIO, IDAREA, IDCIRUGIA,
                         PREFIJO, VALOR, CANTIDAD, NOPRESTACION, NOITEM, N_FACTURA, CCOSTO,
                         IDAREAH, IDTERCEROCA, IDPLAN, FACTOR, VALORCXP, FECHACARGO )
      SELECT HPRED.IDPROVEEDOR, SER.IDSERVICIO,VW_CXPPROTOT.VLRSERVICIO, SER.DESCSERVICIO,HPRE.IDAREA,HPRED.IDCIRUGIA,
	         SER.PREFIJO,VW_CXPPROTOT.VLRSERVICIO,HPRED.CANTIDAD,HPRED.NOPRESTACION,HPRED.NOITEM,HPRED.N_FACTURA, HPRE.CCOSTO, 
			 HPRE.IDAREAH, HPRED.IDTERCEROCA,HPRED.IDPLAN,VW_CXPPROTOT.FACTOR,(HPRED.CANTIDAD*VW_CXPPROTOT.VLRSERVICIO),HPRE.FECHA 
      FROM   HPRED INNER JOIN HPRE  ON HPRED.NOPRESTACION = HPRE.NOPRESTACION
                   INNER JOIN SER   ON HPRED.IDSERVICIO   = SER.IDSERVICIO
                   INNER JOIN VW_CXPPROTOT ON  HPRED.IDPLAN       = VW_CXPPROTOT.IDPLAN
                                        --AND  HPRE.PREFIJO=VW_CXPPROTOT.PREFIJO
                                          AND @IDTERPROVE   = VW_CXPPROTOT.IDTERCERO
	                                      AND HPRE.IDTERCEROCA    = VW_CXPPROTOT.IDADMINISTRADORA
	                                      AND HPRED.IDSERVICIO    = VW_CXPPROTOT.IDSERVICIO
   
      WHERE  HPRED.NOPRESTACION   = @NOPRESTACION  AND HPRED.NOITEM=@NOITEM
      AND    HPRE.FECHA >= VW_CXPPROTOT.FECHAINIFD
      AND    HPRE.FECHA <= VW_CXPPROTOT.FECHAFINFD
      AND    HPRE.FECHA >= VW_CXPPROTOT.FECHAINI
      AND    HPRE.FECHA <= VW_CXPPROTOT.FECHAFIN
      ORDER BY HPRED.IDPROVEEDOR 
   END
   
   CREATE TABLE #PCXP (IDPROVEEDOR VARCHAR(20),VALOR DECIMAL(14,2))  
   INSERT INTO  #PCXP (IDPROVEEDOR,VALOR)  
   SELECT IDPROVEEDOR, SUM(VALORCXP)  FROM #ICXP  
   GROUP BY IDPROVEEDOR 
   SELECT @VALOR= SUM(VALORCXP)  FROM #ICXP  
   GROUP BY IDPROVEEDOR 
   
   PRINT'INICIAMOS EL INSERT'

   EXEC SPK_GENCONSECUTIVO @COMPANIA,@SEDE,'@FCXP',@NVOCONSEC OUTPUT  
   SELECT @NVOCONSEC = @SEDE + REPLACE(SPACE(8 - LEN(@NVOCONSEC))+LTRIM(RTRIM(@NVOCONSEC)),SPACE(1),0)
   PRINT 'ESTE ES EL CONSECUTIVO DE  FXP...'+' '+CAST(@NVOCONSEC AS VARCHAR(20))

   PRINT 'VALIDO EL TERCERO REVISO ID'


   INSERT INTO FXP(N_PRESUP,IDTERCERO,NOREFERENCIA,F_FACTURAREF,F_VENCE,VR_TOTAL,ESTADO,  
                   F_CANCELADO,EMPLEADO,PROCEDENCIA,OBSERVACION,COMPANIA,INDCOBRADA)  
   SELECT @NVOCONSEC,@IDTERPROVE,@NOADMISION,GETDATE(),NULL,@VALOR,'P',NULL,@USUARIO,  
          'SALUD','',@COMPANIA,0  

		 -- MOD.JQUIROGA 20090615 - Ingresar el N_factura en CXPD
         INSERT INTO FXPD(N_PRESUP,IDTERCERO,ITEM,IDSERVICIO,PREFIJO,VALOR,CANTIDAD,VR_TOTAL,  
                          NOPRESTACION,NOITEM,IDCIRUGIA, N_FACTURA, ESTADO, CCOSTO, IDAREA,
                          IDAREAH, VLRORIGINAL)  
         SELECT @NVOCONSEC,@IDTERPROVE,ITEM,IDSERVICIO,PREFIJO,VALOR,CANTIDAD,  
                VALORCXP,NOPRESTACION,NOITEM,IDCIRUGIA, N_FACTURA, 'P', CCOSTO, IDAREA,
                IDAREAH, VALOR  
         FROM   #ICXP  
         WHERE  IDPROVEEDOR = @IDPROVEEDOR 
    PRINT 'ACTUALIZAMOS HPRED '
   
    UPDATE HPRED SET CXP = 1  WHERE NOPRESTACION=@NOPRESTACION AND NOITEM=@NOITEM
         
END

