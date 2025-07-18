IF EXISTS (SELECT name FROM sysobjects WHERE name = 'SPK_RELIQUIDACXCQX' AND type = 'P')
   DROP PROCEDURE SPK_RELIQUIDACXCQX

GO
CREATE PROCEDURE DBO.SPK_RELIQUIDACXCQX  
@CNSCXC VARCHAR(20)  
WITH ENCRYPTION
AS  
DECLARE @TOTALND      DECIMAL(14,2)  
DECLARE @TOTALNC      DECIMAL(14,2)  
DECLARE @TOTALNC1     DECIMAL(14,2)  
DECLARE @TOTALPAGOS   DECIMAL(14,2)  
DECLARE @DEDUCCIONES  DECIMAL(14,2)  
DECLARE @TOTALCXC     DECIMAL(14,2)
DECLARE @VLRGLOSAS_A  DECIMAL(14,2)
DECLARE @VLRGLOSAS_R  DECIMAL(14,2)
DECLARE @N_FACTURA    VARCHAR(20)
DECLARE @DEDUCCIONES1 DECIMAL(14,2)  
DECLARE @CNSGLOP      VARCHAR(20)
DECLARE @GPAGOS       DECIMAL(14,2)
DECLARE @VLREXTRA     DECIMAL(14,2)
DECLARE @ITEM         INT
DECLARE @CNSGLO       VARCHAR(20)
DECLARE @TIPO         VARCHAR(1)
DECLARE @VRNOTAS      DECIMAL(14,2)
DECLARE @VRNOTASD     DECIMAL(14,2)
DECLARE @VRPAGOS      DECIMAL(14,2)
DECLARE @VRGLOSAS     DECIMAL(14,2)
DECLARE @VRGLOSAS1    DECIMAL(14,2)
DECLARE @VRGLOSAS_R   DECIMAL(14,2)
DECLARE @VRDEDUC      DECIMAL(14,2)
DECLARE @VRNOTAS1     DECIMAL(14,2)
DECLARE @VRNOTAS2     DECIMAL(14,2)
DECLARE @VRNOTAS3     DECIMAL(14,2)
DECLARE @SALDOINICIAL DECIMAL(14,2)
DECLARE @VRCONCI DECIMAL(14,2)
DECLARE @VLRCESIONES  DECIMAL(14,2)   --ARS
DECLARE @VLRCESION  DECIMAL(14,2)   --ARS
BEGIN 

   UPDATE FCXC SET SALDO = 0, DEDUCCIONES = 0, VALORCXCNETO = 0, SALDONETO = 0, VLRPAGOS = 0,
          VLRNOTADB = 0, VLRNOTACR = 0, VLRGLOSAS = 0, VLRGLOSAS_R = 0, VLREXTRA = 0,VALORCXC=0
   WHERE  FCXC.CNSCXC = @CNSCXC

   DECLARE PG_CURSOR CURSOR FOR    
   SELECT N_FACTURA FROM FCXCD WHERE CNSCXC = @CNSCXC     
   OPEN PG_CURSOR    
   FETCH NEXT FROM PG_CURSOR    
   INTO @N_FACTURA
   WHILE @@FETCH_STATUS = 0    
   BEGIN               
      EXEC SPK_RELIQUIDA_FTR @CNSCXC, @N_FACTURA
      FETCH NEXT FROM PG_CURSOR    
      INTO @N_FACTURA
   END
   CLOSE PG_CURSOR
   DEALLOCATE PG_CURSOR
   RETURN
  
END   


