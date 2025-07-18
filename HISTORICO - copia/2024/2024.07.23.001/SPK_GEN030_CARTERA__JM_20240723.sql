IF EXISTS(SELECT NAME FROM SYSOBJECTS WHERE NAME='SPK_GEN030_CARTERA' AND XTYPE='P')
BEGIN
   DROP PROCEDURE SPK_GEN030_CARTERA
END
GO
CREATE PROC DBO.SPK_GEN030_CARTERA
@TRIMESTRE    VARCHAR(6)
AS
BEGIN
   --
   IF (SELECT COUNT(*) FROM CIR030 WHERE CIR030.PERIODO   = @TRIMESTRE AND ESTADO='Cerrado')>0
   BEGIN
      PRINT 'PERIODO CERRADO'
      RETURN
   END
   DELETE CIR030 
   WHERE  CIR030.PERIODO   = @TRIMESTRE
   PRINT'--INSERTAMOS LAS INICIALES'
   INSERT INTO CIR030(PERIODO, TR, TI_ERP, NI_ERP, RS_ERP, TI_IPS, NI_IPS, TIPOCOB, PREFACT, N_FACTURA, INDICADOR, VALORFTR, FFACTURA, FRADICADO,N_FACTURAR)
   SELECT DBO.FNK_TRIMESTRE(FCXC.F_RECIBIDO), '2', LEFT(TER.TIPO_ID,2) TIPO_ID, left(TER.NIT,12) NIT,left( TER.RAZONSOCIAL,250) RAZONSOCIAL, 
          (SELECT LEFT(TIPO_ID,2) FROM TER WHERE IDTERCERO=(SELECT DATO FROM USVGS WHERE IDVARIABLE='IDTERCEROINSTALADO' )) ID_IPS,
	       (SELECT DATO FROM USVGS WHERE IDVARIABLE='IDTERCEROINSTALADO' ) NUMERO_ID_IPS, 'F' TIPOCOBRO,
          '',FCXCD.N_FACTURA, 'I', FCXCD.VALORFACTURA, LEFT(CONVERT(VARCHAR(20), FTR.F_FACTURA,120),10), 
          LEFT(CONVERT(VARCHAR(20), FCXC.F_RECIBIDO,120), 10),FCXCD.N_FACTURA
   FROM   FCXCD INNER JOIN FCXC ON FCXCD.CNSCXC = FCXC.CNSCXC
                INNER JOIN TER  ON FCXC.IDTERCERO  = TER.IDTERCERO
                INNER JOIN FTR  ON FCXCD.N_FACTURA = FTR.N_FACTURA
   WHERE  dbo.FNK_TRIMESTRE(FCXC.F_RECIBIDO) = @TRIMESTRE 
   AND    COALESCE (FTR.TIPOTTEC,'') IN (SELECT CODIGO FROM TGEN WHERE TABLA = 'Resoluciones' AND CAMPO = '030_CARTERA_TTEC')


   PRINT'--INSERTAR LAS ACTUALIZACIONES'
   INSERT INTO CIR030(PERIODO, TR, TI_ERP, NI_ERP, RS_ERP, TI_IPS, NI_IPS, TIPOCOB, PREFACT, N_FACTURA, INDICADOR, FFACTURA, FRADICADO,VPAGO,N_FACTURAR)
   SELECT @TRIMESTRE, '2', LEFT(TER.TIPO_ID,2) TIPO_ID,left(TER.NIT,12) NIT,left( TER.RAZONSOCIAL,250)RAZONSOCIAL, 
          (SELECT LEFT(TIPO_ID,2) FROM TER WHERE IDTERCERO=(SELECT DATO FROM USVGS WHERE IDVARIABLE='IDTERCEROINSTALADO' )) ID_IPS,
	       (SELECT DATO FROM USVGS WHERE IDVARIABLE='IDTERCEROINSTALADO' ) NUMERO_ID_IPS, 'F' TIPOCOBRO,
          '',FPAGD.N_FACTURA,'A',LEFT(CONVERT(VARCHAR(20), FTR.F_FACTURA,120), 10),LEFT(CONVERT(VARCHAR(20), FCXC.F_RECIBIDO,120), 10),SUM(FPAGD.VALORPAGO),FPAGD.N_FACTURA
   FROM   FPAGD INNER JOIN FPAG ON FPAGD.CNSFPAG = FPAG.CNSFPAG
                INNER JOIN FTR  ON FPAGD.N_FACTURA = FTR.N_FACTURA
                INNER JOIN TER  ON FTR.IDTERCERO = TER.IDTERCERO
                INNER JOIN FCXCD ON FTR.N_FACTURA = FCXCD.N_FACTURA
                INNER JOIN FCXC  ON FCXCD.CNSCXC  = FCXC.CNSCXC
   WHERE  FPAG.CERRADO = 1
   AND    FPAGD.VALORPAGO > 0
   AND    DBO.FNK_TRIMESTRE(CASE WHEN DBO.FNK_VALORVARIABLE('F_PAGO_CIRUCALAR030')='LEGALIZA' THEN FPAG.FECHA ELSE FPAG.FECHAPAGO END) = @TRIMESTRE
   AND    NOT EXISTS (SELECT * FROM CIR030 WHERE CIR030.N_FACTURAR =FPAGD.N_FACTURA  AND CIR030.PERIODO = @TRIMESTRE)
   AND    COALESCE (FTR.TIPOTTEC,'') IN (SELECT CODIGO FROM TGEN WHERE TABLA = 'Resoluciones' AND CAMPO = '030_CARTERA_TTEC')
   GROUP BY TER.TIPO_ID, TER.NIT, TER.RAZONSOCIAL, FTR.VR_TOTAL, FTR.F_FACTURA, FCXC.F_RECIBIDO,FPAGD.N_FACTURA

   --
   UPDATE CIR030 SET PREFACT=CASE WHEN DBO.FNK_PREFIJOFACT(CIR030.N_FACTURAR)<>'' THEN DBO.FNK_PREFIJOFACT(CIR030.N_FACTURAR) ELSE '' END,
                     N_FACTURA=CASE WHEN DBO.FNK_PREFIJOFACT(CIR030.N_FACTURAR)<>'' 
                                THEN  RIGHT(LTRIM(RTRIM(CIR030.N_FACTURAR)),LEN(LTRIM(RTRIM(CIR030.N_FACTURAR)))-LEN(DBO.FNK_PREFIJOFACT(LTRIM(RTRIM(CIR030.N_FACTURAR)))))
                                ELSE N_FACTURA END
   WHERE  CIR030.PERIODO   = @TRIMESTRE

   UPDATE CIR030 SET CIR030.VALORFTR = FTR.VR_TOTAL
   FROM   CIR030 INNER JOIN FTR ON CIR030.N_FACTURAR = FTR.N_FACTURA
   WHERE  CIR030.PERIODO   = @TRIMESTRE

   --AND    CIR030.INDICADOR = 'A'   
   -- PONER VALOR PAGO 
   UPDATE CIR030 SET CIR030.VPAGO = X.VALORPAGO
   FROM   CIR030 INNER JOIN  (
                              SELECT FCXCD.N_FACTURA,SUM(CASE WHEN FCXCD.SALDONETO <0 THEN (FCXCD.VLRPAGOS+FCXCD.DEDUCCIONES)+ FCXCD.SALDONETO ELSE
                                  CASE WHEN  (FCXCD.VLRPAGOS+FCXCD.DEDUCCIONES)>FCXCD.SALDONETO 
                                       THEN  (FCXCD.VLRPAGOS+FCXCD.DEDUCCIONES)-FCXCD.VLRNOTADB 
                                       ELSE (FCXCD.VLRPAGOS+FCXCD.DEDUCCIONES)-FCXCD.VLRNOTADB END END) VALORPAGO
                              FROM   FCXCD                              
                              GROUP BY FCXCD.N_FACTURA
                            ) X ON CIR030.N_FACTURAR = X.N_FACTURA
   WHERE  CIR030.PERIODO   = @TRIMESTRE
   
   --VALOR DE LAS GLOSAS ACEPTADAS
   UPDATE CIR030 SET VGLOSAACEP  = VR_TOTAL
   FROM CIR030 INNER JOIN (
   SELECT FNOT.N_FACTURA,SUM(FNOT.VR_TOTAL)VR_TOTAL
   FROM   CIR030 INNER JOIN FNOT ON CIR030.N_FACTURAR = FNOT.N_FACTURA
   WHERE  CIR030.PERIODO   = @TRIMESTRE
   AND    FNOT.CERRADA     = 1
   AND    FNOT.CLASE       ='C'
   AND    FNOT.ESTADO      <>'A'
   GROUP BY FNOT.N_FACTURA) X ON CIR030.N_FACTURAR=X.N_FACTURA
 --  AND    FNOT.PROCEDENCIA = 'AUDITORIA' SE QUITA ESTE FILTRO DADO A QUE HAY VALORES ACEPTADOS DE GLOSAS CON PROCEDENCIA CONCILICACION
 --Y ESTAS NO ESTABAN SALIENDO

   --SE COLOCA SALDO A LAS FACTURAS
   UPDATE CIR030 SET CIR030.SALDOFTR =(CASE WHEN FCXCD.VLRGLOSAS>0 THEN (FCXCD.SALDONETO+FCXCD.VLRGLOSAS)ELSE 
                                       CASE WHEN FCXCD.SALDONETO>0 THEN FCXCD.SALDONETO ELSE FCXCD.SALDONETO END  END)--SE AGREGA QUE EL SISTEMA SUME EL SALDO EN AUDITORIA AL SALDONETO DADO QUE AL REPORTAR GENRABA INCONSISTENCIAS. KLEYDER 01.08.2017
   FROM   CIR030 INNER JOIN FCXCD ON CIR030.N_FACTURAR = FCXCD.N_FACTURA
   WHERE  CIR030.PERIODO   = @TRIMESTRE

   --- SE COLOCA SI A LAS FACTURAS CON RESPUESTA GLOSA
   UPDATE CIR030 SET CIR030.GLOSARESP='SI' 
   FROM   CIR030 INNER JOIN (
                              SELECT FGLO.N_FACTURA 
                              FROM FGLO INNER JOIN CIR030 ON FGLO.N_FACTURA=CIR030.N_FACTURA 
                              WHERE CERRADA=1 AND CIR030.PERIODO=@TRIMESTRE
                              ) X ON CIR030.N_FACTURAR=X.N_FACTURA
   WHERE  CIR030.PERIODO=@TRIMESTRE
   -- SI LA FACTURA NO TIENE GLOSA NI RESPUESTA SE DEJA EL CAMPO EN NO
   UPDATE CIR030 SET GLOSARESP='NO'
   WHERE  CIR030.PERIODO=@TRIMESTRE
   AND    COALESCE(CIR030.GLOSARESP,'')=''

   ---SE IDENTIFICAN LAS FACTURAS QUE ESTAN EN COBRO JURIDICO, 
   ---EL CAMPO ETAPA PROCESO SE DEJARA EN CERO PERO ESTE MIENTRAS 
   ---EL PROCESO JURIDO EN EL SISTAMA SEA DE ACUERDO A EL DECRETO O CIRCULAR.
   UPDATE CIR030 SET FTRENCOBROJ='SI' , ETAPAPROCES=0
   FROM   CIR030 INNER JOIN (
                             SELECT FCXCD.N_FACTURA 
                             FROM   CIR030 INNER JOIN FCXCD ON CIR030.N_FACTURA=FCXCD.N_FACTURA
                             WHERE  FCXCD.ENCOBROJUR=1
                             ) Y ON CIR030.N_FACTURAR=Y.N_FACTURA
   WHERE  CIR030.PERIODO=@TRIMESTRE

   --- SI LA FACTURA NO SE ENCUENTRA EN COBRO JURIDICO SE DEJA EN NO
   UPDATE CIR030 SET FTRENCOBROJ='NO', ETAPAPROCES=0
   WHERE  CIR030.PERIODO=@TRIMESTRE
   AND    COALESCE(CIR030.FTRENCOBROJ,'')=''
   --
   UPDATE CIR030 SET CIR030.CONSECUTIVO=X.CONSECUTIVO
   FROM   CIR030 INNER JOIN (
                            SELECT  ROW_NUMBER() OVER(ORDER BY N_FACTURAR) CONSECUTIVO ,N_FACTURAR
                            FROM CIR030 WHERE PERIODO=@TRIMESTRE
                            ) X ON CIR030.N_FACTURAR=X.N_FACTURAR
   WHERE CIR030.PERIODO = @TRIMESTRE

   UPDATE CIR030 SET FDEVOLUCION=LEFT(CONVERT(VARCHAR(20), X.FECHAPAGO,120),10)
   FROM CIR030 INNER JOIN  (
         SELECT FPAGD.N_FACTURA,MIN(FPAG.FECHAPAGO)FECHAPAGO
         FROM CIR030 INNER JOIN FPAGD FPAGD ON CIR030.N_FACTURAR=FPAGD.N_FACTURA
                     INNER JOIN FPAG  ON FPAGD.CNSFPAG=FPAG.CNSFPAG
         WHERE FPAG.INGRESO='GLOSAS'
         AND FPAG.CERRADO=1
         AND CIR030.PERIODO=@TRIMESTRE
         AND CIR030.VGLOSAACEP>0
         GROUP BY FPAGD.N_FACTURA)X ON X.N_FACTURA=CIR030.N_FACTURAR
         WHERE CIR030.VGLOSAACEP>0
         AND CIR030.PERIODO=@TRIMESTRE

   UPDATE CIR030 SET N_FACTURA=LTRIM(RTRIM(N_FACTURA)),RS_ERP=LTRIM(RTRIM(RS_ERP))
   WHERE CIR030.PERIODO= @TRIMESTRE


   UPDATE CIR030 SET CLASE='Periodo',ESTADO='Abierto' WHERE CIR030.PERIODO = @TRIMESTRE
END

