CREATE OR ALTER PROCEDURE  DBO.SPQ_CARTERA_IMPRESION
@JSON  NVARCHAR(MAX)
WITH ENCRYPTION
AS  
DECLARE	 @PARAMETROS  NVARCHAR(MAX)     
         ,@MODELO    VARCHAR(100)         
         ,@METODO    VARCHAR(100)	
         ,@USUARIO      VARCHAR(12)
         ,@CNSFPAG VARCHAR(20)
BEGIN  
	SET DATEFORMAT dmy
   SET LANGUAGE Spanish;
	SELECT *
	INTO #JSON
	FROM OPENJSON (@json)
	WITH (
		MODELO         VARCHAR(100)     '$.MODELO',
		METODO         VARCHAR(100)     '$.METODO',
		USUARIO        VARCHAR(12)      '$.USUARIO',
		PARAMETROS     NVARCHAR(MAX)  AS JSON
	)
	SELECT @MODELO = MODELO , @METODO = METODO , @PARAMETROS = PARAMETROS, @USUARIO = USUARIO
	FROM #JSON
	DECLARE @TBLERRORES TABLE(ERROR VARCHAR(200));

   IF @METODO='FPAG'     
   BEGIN  
      PRINT 'Ingreso a Pagos'
      SELECT @CNSFPAG=CNSFPAG        
      FROM   OPENJSON (@PARAMETROS)
      WITH (           
      CNSFPAG  VARCHAR(20)   '$.CNSFPAG' 
      )
      IF NOT EXISTS(SELECT * FROM FPAG WHERE CNSFPAG=@CNSFPAG)
      BEGIN
         SELECT 'KO'OK,'No se Encontro el Pago. Verifique e intente de nuevo'
      END
      SELECT 'OK'OK,CNSFPAG,FPAG.IDTERCERO,TER.NIT,TER.RAZONSOCIAL,DBO.FNK_FECHA_DDMMAA(FPAG.FECHA) FECHA,
              FPAG.INGRESO,FPAG.BANCO,BCO.DESCRIPCION AS N_BANCO,BMOVD.CTA_BCO,BMOVD.NODOCUMENTO,
              FPAG.CODCAJA,CAJ.DESCRIPCION AS N_CAJA,FPAG.CNSFACJ,FPAG.OBSERVACION,VLRAJUSTEPESO,
              CASE WHEN FPAG.CERRADO=0 THEN 'PAGO NO APLICADO -- NO DEFINITIVO' ELSE '' END TITULO,
              CONCAT(DBO.FNK_FECHA_DDMMAA(FPAG.FECHA),' ',CONVERT(VARCHAR,DBO.FNK_GETDATE(),108))FIMPRESION,
              @USUARIO USUARIO,(SELECT COALESCE(SYS_COMPUTERNAME,HOST_NAME()) FROM USUSU WHERE USUARIO=@USUARIO)EQUIPO
      FROM FPAG INNER JOIN TER ON FPAG.IDTERCERO=TER.IDTERCERO
                LEFT JOIN  BMOVD ON FPAG.BANCO=BMOVD.BANCO AND FPAG.SUCURSAL=BMOVD.SUCURSAL AND FPAG.CTA_BCO=BMOVD.CTA_BCO
                                     AND FPAG.ITEM=BMOVD.ITEM AND FPAG.RENGLON=BMOVD.RENGLON
                LEFT JOIN  FCJ ON FPAG.CODCAJA=FCJ.CODCAJA AND FPAG.CNSFACJ=FCJ.CNSFACJ
                LEFT JOIN  BCO ON BMOVD.BANCO=BCO.BANCO
                LEFT JOIN  CAJ ON FPAG.CODCAJA=CAJ.CODCAJA
      WHERE FPAG.CNSFPAG=@CNSFPAG

      SELECT N_FACTURA,CNSCXC,VLRFACTURA,VLRGLOSA,GLOSAAFECTAIMP,VLRCOPAGO,BASE,VLRIMPUESTO,VLRPAGOSIN,VLRDTOFIN,SINPAGO,VALORPAGO,
             VLREXTRA,OBSERVACION
      FROM FPAGD
      WHERE FPAGD.CNSFPAG=@CNSFPAG
      ORDER BY N_FACTURA

      SELECT FPAGDI.IDIMPUESTO,FPAGDI.IDCLASE,FIMPD.DESCRIPCION,SUM(VLRIMPUESTO) VLRIMPUESTO
      FROM FPAGDI INNER JOIN FIMPD ON FPAGDI.IDIMPUESTO=FIMPD.IDIMPUESTO AND FPAGDI.IDCLASE=FIMPD.IDCLASE
      WHERE CNSFPAG=@CNSFPAG
      GROUP BY FPAGDI.IDIMPUESTO,FPAGDI.IDCLASE,FIMPD.DESCRIPCION
      
   END  
END