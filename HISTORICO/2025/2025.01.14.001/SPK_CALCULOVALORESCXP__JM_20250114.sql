IF EXISTS(SELECT NAME FROM SYSOBJECTS WHERE NAME='SPK_CALCULOVALORESCXP' AND XTYPE='P')
BEGIN
   DROP PROCEDURE SPK_CALCULOVALORESCXP
END

GO
CREATE PROCEDURE DBO.SPK_CALCULOVALORESCXP
@CNSFCXP         VARCHAR(20)
WITH ENCRYPTION
AS
DECLARE @VLR_ANTICIPOS DECIMAL(14,2)
DECLARE @VLR_ORIGEN    DECIMAL(14,2)
DECLARE @VLR_ANTES     DECIMAL(14,2)
DECLARE @CNSFCOM       VARCHAR(20)
DECLARE @PROCEDENCIA   VARCHAR(10)
DECLARE @PROCENOTA   VARCHAR(10)

DECLARE @REDONDEO      SMALLINT
DECLARE @VLRNOTASDB    DECIMAL(14,2)
DECLARE @VLRNOTASCR    DECIMAL(14,2)
BEGIN
   IF (SELECT PROCEDENCIA FROM FCXP WHERE CNSFCXP=@CNSFCXP)='A'
   BEGIN
      PRINT 'CXP ANULADA'
      RETURN
   END
   IF(SELECT PROCEDENCIA FROM FCXP WHERE CNSFCXP=@CNSFCXP)<>'ANTICIPOS' 
   BEGIN

      SELECT  
	  @VLRNOTASDB=SUM(CASE WHEN TIPO='DB' THEN CASE WHEN PROCEDENCIA= 'INV' THEN  CASE WHEN DBO.FNK_VALORVARIABLE( 'MIMPUESTONOTADBCR' )='SI' THEN VALOR ELSE VLR_NETO END
													 ELSE  CASE WHEN PROCEDENCIA='AUDT' AND VLR_NETO=0 THEN VALOR
															ELSE IIF(VALOR>VLR_NETO,VALOR +COALESCE(VALORIVA,0)-VLR_IMPUESTOS , VLR_NETO)
															END  
													  END 
						ELSE 0 END),
	  @VLRNOTASCR=SUM(CASE WHEN TIPO='CR' THEN  CASE WHEN PROCEDENCIA='AUDT' AND VLR_NETO=0  THEN VALOR ELSE VLR_NETO END ELSE 0 END) 
      FROM FCXPDBCR WHERE CNSFCXP=@CNSFCXP AND ESTADO IN('P','N') AND COALESCE(CONTABILIZADA,0)<>0



      UPDATE FCXP SET VLR_NOTASDEBITO=COALESCE(@VLRNOTASDB,0), VLR_NOTASCREDITO=COALESCE(@VLRNOTASCR,0) WHERE CNSFCXP=@CNSFCXP

      SELECT @VLR_ANTES=SALDO,@PROCEDENCIA=PROCEDENCIA, @CNSFCOM = CNSFCOM FROM FCXP WHERE CNSFCXP=@CNSFCXP
      PRINT 'VALOR ANTES DE RELIQUIDAR............'+STR(@VLR_ANTES)
      PRINT 'INGRESO RELIQUIDA'
      IF @PROCEDENCIA='Compras' AND DBO.FNK_VALORVARIABLE('REDONDEO_COMPRAS_CXP')='SI'
      BEGIN
         SELECT @REDONDEO=1
      END
      ELSE
      BEGIN
         SELECT @REDONDEO=0
      END
	   UPDATE FCXP SET  VALOR     = COALESCE(V.VALOR,0), 
					   VLR_DESCUENTO = COALESCE(V.VLR_DESCUENTO,0), 
					   VLR_IVA       = COALESCE(V.VLR_IVA,0), 
					   VLR_NETO      = COALESCE(V.VLR_NETO,0) + COALESCE(FCXP.VLR_FLETE,0), 
					   VLR_GLOSAS    = COALESCE(V.VLR_GLOSAS,0),  
					   VLR_IMPUESTOS = COALESCE(I.IMPUESTOS,0),
					   VLR_ABONOS    = COALESCE(A.ABONOS,0)+COALESCE(Y.ANTICIPOS, 0),
					   SALDO         = CASE WHEN @REDONDEO=1 THEN ROUND( COALESCE(V.SALDO,0) - COALESCE(I.IMPUESTOS,0) + COALESCE(FCXP.VLR_FLETE,0) - COALESCE(Y.ANTICIPOS, 0) -
									       COALESCE(A.ABONOS,0) - COALESCE(VLR_NOTASDEBITO,0) + COALESCE(VLR_NOTASCREDITO,0) -COALESCE(V.VLRCOPAGO,0),0)
										   ELSE COALESCE(V.SALDO,0) - COALESCE(I.IMPUESTOS,0) + COALESCE(FCXP.VLR_FLETE,0) - COALESCE(Y.ANTICIPOS, 0) -
									       COALESCE(A.ABONOS,0) - COALESCE(VLR_NOTASDEBITO,0) + COALESCE(VLR_NOTASCREDITO,0) -COALESCE(V.VLRCOPAGO,0)END , 
                  VLR_TDOLAR  =   COALESCE(VLR_DOLARES,0)
	   FROM   FCXP LEFT JOIN (SELECT  CNSFCXP,
									  VALOR         = CASE WHEN @REDONDEO=0 THEN COALESCE(SUM(VALOR*CANTIDAD),0) ELSE  ROUND(COALESCE(SUM(VALOR*CANTIDAD),0),0)END-COALESCE(SUM(VLRCOPAGO),0), 
									  VLR_DESCUENTO = COALESCE(SUM(VLR_DESCUENTO),0), 
                             VLRCOPAGO    = COALESCE(SUM(VLRCOPAGO),0),
									  VLR_IVA       = COALESCE(SUM(VLR_IVA),0), 
									  VLR_NETO      = CASE WHEN @REDONDEO=0 THEN COALESCE(SUM(VLR_NETO),0) ELSE ROUND(COALESCE(SUM(VLR_NETO),0),0) END-COALESCE(SUM(VLRCOPAGO),0), 
									  VLR_GLOSAS    = COALESCE(SUM(VLR_GLOSAS),0), 
									  SALDO         =CASE WHEN @REDONDEO=0 THEN COALESCE(SUM(VLR_NETO),0) ELSE ROUND(COALESCE(SUM(VLR_NETO),0),0) END -COALESCE(SUM(VLRCOPAGO),0),
                             VLR_DOLARES   =COALESCE(SUM(COALESCE(VLR_DOLARES,0)*CANTIDAD),0)
							  FROM    FCXPD 
							  GROUP BY FCXPD.CNSFCXP) AS V ON FCXP.CNSFCXP = V.CNSFCXP 
				   LEFT JOIN (SELECT CNSFCXP, ABONOS = COALESCE(SUM(ABONO),0) 
							  FROM   FCXPP 
							  WHERE  ESTADO <> 'A' 
							  GROUP BY CNSFCXP) AS A ON FCXP.CNSFCXP = A.CNSFCXP 
				   LEFT JOIN (SELECT CNSFCXP, IMPUESTOS = COALESCE(SUM(VALOR),0) 
							  FROM   FCXPI 
							  WHERE COALESCE(IMPUESTO_ASUM,0) = 0 -- Impuestos no Asumidos
							  GROUP BY CNSFCXP) AS I ON FCXP.CNSFCXP = I.CNSFCXP
               LEFT JOIN (SELECT CNSFCXP,ANTICIPOS =SUM(VALOR_LEG) FROM ANT WHERE CNSFCXP=@CNSFCXP AND ESTADO='L' GROUP BY CNSFCXP ) AS Y
                                              ON FCXP.CNSFCXP = Y.CNSFCXP
	   WHERE  FCXP.CNSFCXP = @CNSFCXP  
	          
	   IF (SELECT COALESCE(SUM(VALOR*CANTIDAD),0) FROM FCXPD WHERE CNSFCXP=@CNSFCXP  AND COALESCE(ESTADO,'')<>'A')>0
	   BEGIN
		  UPDATE FCXP 
		  SET ESTADO = CASE WHEN COALESCE(SALDO,0) = 0 AND COALESCE(VLR_ABONOS,0)>0 THEN 'P' 
							ELSE CASE WHEN COALESCE(SALDO,0)>0 AND COALESCE(VLR_ABONOS,0)> 0  AND COALESCE(CONTABILIZADA,0)<>0 THEN 'C'
                          WHEN COALESCE(SALDO,0)>0 AND COALESCE(VLR_ABONOS,0)=0  AND COALESCE(CONTABILIZADA,0)<>0 THEN 'N'
                          WHEN COALESCE(SALDO,0)>0 AND COALESCE(CONTABILIZADA,0)=0 THEN 'N'
									  ELSE ESTADO 
								 END 
					   END 
		  WHERE CNSFCXP = @CNSFCXP
	   END
      SELECT @VLR_ANTES=SALDO FROM FCXP WHERE CNSFCXP=@CNSFCXP
      PRINT 'VALOR DESPUES DE RELIQUIDAR............'+STR(@VLR_ANTES)
   END
   ELSE
   BEGIN 
      PRINT 'EMPIEZO RELIQUIDACION ANTICIPOS .....'
      SELECT @VLR_ANTICIPOS=VALORCXP,@VLR_ORIGEN=VALOR_LEG FROM  ANT 
      WHERE CNSFCXP=@CNSFCXP
      AND ESTADO='L'
      PRINT 'VALOR DE ANTICIPOS == '+LTRIM(RTRIM(STR(@VLR_ANTICIPOS)))
      IF @VLR_ANTICIPOS>0 OR @VLR_ORIGEN>0
      BEGIN 
		   UPDATE FCXP SET VALOR     = @VLR_ORIGEN, 
						   VLR_DESCUENTO = COALESCE(V.VLR_DESCUENTO,0), 
						   VLR_IVA       = COALESCE(V.VLR_IVA,0), 
						   VLR_NETO      = @VLR_ORIGEN, 
						   VLR_GLOSAS    = COALESCE(V.VLR_GLOSAS,0),  
						   VLR_IMPUESTOS = COALESCE(I.IMPUESTOS,0),
						   VLR_ABONOS    = COALESCE(A.ABONOS,0)+@VLR_ANTICIPOS,
						   SALDO         = @VLR_ORIGEN -@VLR_ANTICIPOS- COALESCE(I.IMPUESTOS,0) + COALESCE(FCXP.VLR_FLETE,0) - 
										   COALESCE(A.ABONOS,0) - COALESCE(VLR_NOTASDEBITO,0) + COALESCE(VLR_NOTASCREDITO,0) 
		   FROM   FCXP LEFT JOIN (SELECT  CNSFCXP,
										  VALOR         = COALESCE(SUM(VALOR*CANTIDAD),0), 
										  VLR_DESCUENTO = COALESCE(SUM(VLR_DESCUENTO),0), 
										  VLR_IVA       = COALESCE(SUM(VLR_IVA),0), 
										  VLR_NETO      = COALESCE(SUM(VLR_NETO),0), 
										  VLR_GLOSAS    = COALESCE(SUM(VLR_GLOSAS),0), 
										  SALDO         = COALESCE(SUM(VLR_NETO),0) 
								  FROM    FCXPD 
								  GROUP BY FCXPD.CNSFCXP) AS V ON FCXP.CNSFCXP = V.CNSFCXP 
					   LEFT JOIN (SELECT CNSFCXP, ABONOS = COALESCE(SUM(ABONO),0) 
								  FROM   FCXPP 
								  WHERE  ESTADO <> 'A' 
								  GROUP BY CNSFCXP) AS A ON FCXP.CNSFCXP = A.CNSFCXP 
					   LEFT JOIN (SELECT CNSFCXP, IMPUESTOS = COALESCE(SUM(VALOR),0) 
								  FROM   FCXPI 
								  WHERE COALESCE(IMPUESTO_ASUM,0) = 0 -- Impuestos no Asumidos
								  GROUP BY CNSFCXP) AS I ON FCXP.CNSFCXP = I.CNSFCXP 
		   WHERE  FCXP.CNSFCXP = @CNSFCXP  
		          
		   IF (SELECT COALESCE(SUM(VALOR*CANTIDAD),0) FROM FCXPD WHERE CNSFCXP=@CNSFCXP  AND COALESCE(ESTADO,'')<>'A')>0
		   BEGIN
		     UPDATE FCXP 
		     SET ESTADO = CASE WHEN COALESCE(SALDO,0) = 0 AND COALESCE(VLR_ABONOS,0)>0 THEN 'P' 
							   ELSE CASE WHEN COALESCE(SALDO,0)>0 AND COALESCE(VLR_ABONOS,0)>0  AND COALESCE(CONTABILIZADA,0)<>0 THEN 'C' 
                             WHEN COALESCE(SALDO,0)>0 AND COALESCE(CONTABILIZADA,0)=0 THEN 'N'
									     ELSE ESTADO 
								    END 
					      END 
		     WHERE CNSFCXP = @CNSFCXP
		  END

	   END
   END
END


