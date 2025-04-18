IF EXISTS(SELECT NAME FROM SYSOBJECTS WHERE NAME='NC_SPK_MOVXTERCERO' AND TYPE = 'P') 
BEGIN
   DROP PROCEDURE NC_SPK_MOVXTERCERO
END

GO
CREATE PROCEDURE DBO.NC_SPK_MOVXTERCERO
@FECHAINI        DATETIME, 
@FECHAFIN        DATETIME, 
@IDTERCEROINI    VARCHAR(20), 
@IDTERCEROFIN    VARCHAR(20), 
@CUENTAINI       VARCHAR(16), 
@CUENTAFIN       VARCHAR(16),
@CCOSTOINI       VARCHAR(20),
@CCOSTOFIN       VARCHAR(20),
@WHERE           VARCHAR(3000),
@CONSECUTIVORPDX VARCHAR(20),
@COMPANIA        VARCHAR(2) = '01',
@SEDE            VARCHAR(5) = '01',
@NVOCONSEC       VARCHAR(20)
WITH ENCRYPTION
AS
DECLARE 
   --@NVOCONSEC     VARCHAR(20),
   @ANOINI        SMALLINT,
   @ANOFIN        SMALLINT,
   @MESINI        SMALLINT,
   @MESFIN        SMALLINT,
   @ITEM_CUR      INT,
   @CUENTA_ANT    VARCHAR(20),
   @CUENTA_CUR    VARCHAR(20),
   @CCOSTO_ANT    VARCHAR(20),
   @CCOSTO_CUR    VARCHAR(20),
   @IDTERCERO_ANT VARCHAR(20),
   @IDTERCERO_CUR VARCHAR(20),
   @N_FACTURA_ANT VARCHAR(20),
   @N_FACTURA_CUR VARCHAR(20),
   @CODUNG_CUR    VARCHAR(5), 
   @CODPRG_CUR    VARCHAR(20),
   @SI_CUR        DECIMAL(14,2),
   @DB_CUR        DECIMAL(14,2),
   @CR_CUR        DECIMAL(14,2),
   @SF_CUR        DECIMAL(14,2),
   @SF            DECIMAL(14,2),
   @SF_ANT        DECIMAL(14,2),
   @QUERYFINAL    VARCHAR(3000),
   @NTZ           VARCHAR(2)
DECLARE @PERIODOINICIAL    VARCHAR(6)
DECLARE @PERIODOFINAL      VARCHAR(6)
DECLARE @ULTPERIODOCER     VARCHAR(6)

BEGIN
   --EXEC SPK_GENCONSECUTIVO @COMPANIA,@SEDE,'@TPROCONT', @NVOCONSEC OUTPUT  
   --SELECT @NVOCONSEC = @SEDE + REPLACE(SPACE(8 - LEN(@NVOCONSEC))+LTRIM(RTRIM(@NVOCONSEC)),SPACE(1),0) 
   SELECT @ANOINI = YEAR(@FECHAINI), @MESINI = MONTH(@FECHAINI), @ANOFIN = YEAR(@FECHAFIN), @MESFIN = MONTH(@FECHAFIN)
   SELECT @ULTPERIODOCER = COALESCE(MAX(CAST(ANO AS VARCHAR(20))+ CASE WHEN MES < 10 THEN '0' + CAST(MES AS VARCHAR(1)) ELSE CAST(MES AS VARCHAR(2)) END ),'')
   FROM   PRI
   WHERE  CERRADO = 1
   SELECT @PERIODOINICIAL = CAST(@ANOINI AS VARCHAR(20))+ CASE WHEN @MESINI < 10 THEN '0' + CAST(@MESINI AS VARCHAR(1)) ELSE CAST(@MESINI AS VARCHAR(2)) END 
   SELECT @PERIODOFINAL = CAST(@ANOFIN AS VARCHAR(20))+ CASE WHEN @MESFIN < 10 THEN '0' + CAST(@MESFIN AS VARCHAR(1)) ELSE CAST(@MESFIN AS VARCHAR(2)) END 

   --PRINT 'VOY A BALANCE AU CON TPROCONT=' + @NVOCONSEC
   --EXEC SPK_BALANCE 'AU', @NVOCONSEC, @ANOINI, @MESINI, @ANOFIN, @MESFIN, @CUENTAINI, @CUENTAFIN, 1, 10, @CCOSTOINI, @CCOSTOFIN, @COMPANIA, @SEDE, @IDTERCEROINI, 0            
   
   CREATE TABLE #TABLA_FNK_MOVXTERCERO
      (TIPO          SMALLINT UNIQUE (TIPO, ITEM), 
       CUENTA         VARCHAR(16)   COLLATE database_default,
       NOMCUENTA      VARCHAR(200)   COLLATE database_default,
       CCOSTO         VARCHAR (20)  COLLATE database_default,
       NOMCCOSTO      VARCHAR (100) COLLATE database_default,
       IDTERCERO      VARCHAR(20)   COLLATE database_default, 
       RAZONSOCIAL    VARCHAR(120)  COLLATE database_default,
       N_FACTURA      VARCHAR (20)  COLLATE database_default,
       FECHAMOV       DATETIME UNIQUE (CUENTA, CCOSTO, IDTERCERO, N_FACTURA, FECHAMOV, ITEM),
       DETALLE        VARCHAR(512) COLLATE database_default,  
       COMPROBANTE    VARCHAR(20) COLLATE database_default,  
       NOREFERENCIA   VARCHAR(20) COLLATE database_default,  
       NROCOMPROBANTE VARCHAR(20) COLLATE database_default,  
       FECHAINI       DATETIME,
       FECHAFIN       DATETIME,
       SI             DECIMAL(14,2),
       DB             DECIMAL(14,2),
       CR             DECIMAL(14,2),
       SF             DECIMAL(14,2),
       ITEM           INT IDENTITY NOT NULL PRIMARY KEY CLUSTERED (ITEM),
       CODUNG         VARCHAR(5)  COLLATE database_default,
       CODPRG         VARCHAR(20) COLLATE database_default,
       NOCHEQUE		 VARCHAR(20) COLLATE database_default, --- CAMPO ADICIONADO (JREYES 20090421)
	    ESTADO         VARCHAR(1)  COLLATE database_default)  --- CAMPO ADICIONADO (JREYES 20090421) 
     
   IF @IDTERCEROFIN = ''    
      SET @IDTERCEROFIN = DBO.FNK_MICOLLATE()
   IF @CUENTAFIN = ''    
      SET @CUENTAFIN    = DBO.FNK_MICOLLATE()
   IF @CCOSTOFIN = ''    
      SET @CCOSTOFIN    = DBO.FNK_MICOLLATE()
                    
    PRINT '-- Saldo Inicial del CUENTA'
   IF EXISTS(SELECT * FROM TBALANCETERFAC WHERE CNSPRO=@NVOCONSEC AND TIPO='Detalle')
   BEGIN
   INSERT INTO #TABLA_FNK_MOVXTERCERO (TIPO, IDTERCERO, CUENTA, CCOSTO, N_FACTURA, FECHAINI, FECHAFIN, FECHAMOV, SI, DB, CR, SF, CODUNG, CODPRG)
   SELECT 1, '', CUENTA, '', '', @FECHAINI, @FECHAFIN, NULL, SUM(SI), 0, 0, 0, NULL, NULL 
   FROM TBALANCETERFAC 
   WHERE CNSPRO=@NVOCONSEC AND TIPO='Detalle' AND CUENTA>=@CUENTAINI AND CUENTA<=@CUENTAFIN
   GROUP BY CUENTA
   END
   IF EXISTS(SELECT * FROM TBALANCETERFAC WHERE CNSPRO=@NVOCONSEC AND TIPO='Tercero')
   BEGIN
      PRINT 'INGRESO LOS TERCEROS'
      INSERT INTO #TABLA_FNK_MOVXTERCERO (TIPO, IDTERCERO, CUENTA, CCOSTO, N_FACTURA, FECHAINI, FECHAFIN, FECHAMOV, SI, DB, CR, SF, CODUNG, CODPRG)
      SELECT 1, IDTERCERO, CUENTA, '', '', @FECHAINI, @FECHAFIN, NULL,SUM(SI),0,0,0, NULL, NULL 
      FROM TBALANCETERFAC 
      WHERE CNSPRO=@NVOCONSEC AND TIPO='Tercero' AND CUENTA>=@CUENTAINI AND CUENTA<=@CUENTAFIN
      GROUP BY IDTERCERO, CUENTA
   END 


   --PRINT '-- Saldo Inicial del Mes'
   --INSERT INTO #TABLA_FNK_MOVXTERCERO (TIPO, IDTERCERO, CUENTA, CCOSTO, N_FACTURA, FECHAINI, FECHAFIN, FECHAMOV, SI, DB, CR, SF, CODUNG, CODPRG)
   --SELECT 1, X.IDTERCERO, X.CUENTA, X.CCOSTO, X.N_FACTURA, @FECHAINI, @FECHAFIN, @FECHAINI, SUM(SI), 0, 0, SUM(SF),'', ''
   --FROM   TBALANCETERFAC X
   --WHERE  COALESCE(X.TIPO,'') = ''
   ----WHERE  X.CCOSTO    >= @CCOSTOINI    AND X.CCOSTO    <= @CCOSTOFIN 
   ----AND    X.CUENTA    >= @CUENTAINI    AND X.CUENTA    <= @CUENTAFIN 
   ----AND    X.IDTERCERO >= @IDTERCEROINI AND X.IDTERCERO <= @IDTERCEROFIN 
   --AND    X.CNSPRO     = @NVOCONSEC
   --GROUP BY X.IDTERCERO, X.CUENTA, X.CCOSTO, X.N_FACTURA

   PRINT '--MOVIMIENTOS--'
   INSERT INTO #TABLA_FNK_MOVXTERCERO (TIPO, IDTERCERO, CUENTA, CCOSTO, N_FACTURA, DETALLE, COMPROBANTE, NOREFERENCIA, NROCOMPROBANTE, 
                                       FECHAMOV, FECHAINI, FECHAFIN, SI, DB, CR, SF, CODUNG, CODPRG, NOCHEQUE)
   SELECT 2, IDTERCERO=COALESCE(MCH.IDTERCERO,''), CUENTA=MCH.CUENTA, 
          CCOSTO = CASE COALESCE(@CCOSTOINI,'') WHEN '' THEN '' 
                                                ELSE CASE WHEN X.CLASE  IN ('CXC', 'CXP' ) THEN '' ELSE COALESCE(MCH.CCOSTO,'') END
                   END,
          N_FACTURA = ISNULL(MCH.N_FACTURA,''), 
          DETALLE = LEFT(LTRIM(RTRIM(MCH.DETALLE)),511), MCP.COMPROBANTE, MCP.NOREFERENCIA, MCP.NROCOMPROBANTE, MCP.FECHACONTABLE, @FECHAINI, @FECHAFIN, SI = 0, 
          DB = CASE WHEN MCH.TIPO = 'DB' THEN MCH.VALOR ELSE 0 END, 
          CR = CASE WHEN MCH.TIPO = 'CR' THEN MCH.VALOR ELSE 0 END,     
          SF = 0,
          ISNULL(MCH.CODUNG,''), ISNULL(MCH.CODPRG,''), MCP.NOCHEQUE
   FROM   MCP INNER JOIN MCH ON MCP.COMPANIA       = MCH.COMPANIA 
                            AND MCP.NROCOMPROBANTE = MCH.NROCOMPROBANTE
              INNER JOIN CUE X ON MCH.CUENTA = X.CUENTA
   WHERE  MCP.COMPANIA=@COMPANIA 
   AND    ANOMES >= @PERIODOINICIAL
   AND    ANOMES <= @PERIODOFINAL
   AND    MCP.ESTADO        = 2 
   AND    ISNULL(MCP.ANULADO,0) = 0 
   AND    MCH.CUENTA >= @CUENTAINI 
   AND    MCH.CUENTA <= @CUENTAFIN 
   AND    ISNULL(MCH.IDTERCERO,'') >= @IDTERCEROINI 
   AND    ISNULL(MCH.IDTERCERO,'') <= @IDTERCEROFIN 
   AND    ISNULL(MCH.CCOSTO,'')    >= @CCOSTOINI 
   AND    ISNULL(MCH.CCOSTO,'')    <= @CCOSTOFIN


   PRINT'--DEBO COLOCAR SALDOS INICIALES EN CERO DE CUENTAS QUE SOLO HASTA AHORA TENGAN MOV--'
   INSERT INTO #TABLA_FNK_MOVXTERCERO (TIPO, IDTERCERO, CUENTA, CCOSTO, N_FACTURA, DETALLE, COMPROBANTE, NOREFERENCIA, NROCOMPROBANTE, 
                                       FECHAMOV, FECHAINI, FECHAFIN, SI, DB, CR, SF, CODUNG, CODPRG)
   SELECT 1, Y.IDTERCERO, Y.CUENTA, Y.CCOSTO, Y.N_FACTURA, Y.DETALLE, Y.COMPROBANTE, 
             Y.NOREFERENCIA, Y.NROCOMPROBANTE, Y.FECHAMOV, @FECHAINI, @FECHAFIN, SI = 0, DB = ISNULL(Y.DB,0), CR = ISNULL(Y.CR,0), 
             SF = COALESCE(Y.CR,0), Y.CODUNG, Y.CODPRG
   FROM   (SELECT MCP.COMPANIA, 
                  IDTERCERO = ISNULL(TER.IDTERCERO,''), 
                  CUENTA    = MCH.CUENTA, 
                  CCOSTO    = CASE COALESCE(@CCOSTOINI,'') WHEN '' THEN '' 
                                                           ELSE CASE WHEN X.CLASE  IN ('CXC', 'CXP' ) THEN '' 
                                                                     ELSE COALESCE(MCH.CCOSTO,'') 
                                                                 END
                  END,
                  N_FACTURA=ISNULL(MCH.N_FACTURA,''), DETALLE = MCH.DETALLE, MCP.COMPROBANTE, MCP.NOREFERENCIA, 
                  MCP.NROCOMPROBANTE, FECHAMOV = MCP.FECHACONTABLE, DB = SUM(CASE WHEN MCH.TIPO = 'DB' THEN MCH.VALOR ELSE 0 END),
                  CR = SUM(CASE WHEN MCH.TIPO = 'CR' THEN MCH.VALOR ELSE 0 END),
                  CODUNG = ISNULL(MCH.CODUNG,''), CODPRG = ISNULL(MCH.CODPRG,'')		
           FROM   MCP  INNER JOIN MCH  ON MCP.COMPANIA = MCH.COMPANIA 
                                      AND MCP.NROCOMPROBANTE = MCH.NROCOMPROBANTE 
                       INNER JOIN CUE X ON MCH.CUENTA = X.CUENTA
                       LEFT JOIN  TER  ON TER.IDTERCERO = MCH.IDTERCERO 
                       LEFT JOIN  CEN  ON CEN.CCOSTO    = MCH.CCOSTO 
                                      AND CEN.COMPANIA  = MCP.COMPANIA
           WHERE MCP.COMPANIA = @COMPANIA 
           AND   ANOMES >= @PERIODOINICIAL
           AND   ANOMES <= @PERIODOFINAL
           AND   ISNULL(MCH.IDTERCERO,'') >= @IDTERCEROINI AND ISNULL(MCH.IDTERCERO,'') <= @IDTERCEROFIN 
           AND   MCH.CUENTA >= @CUENTAINI AND MCH.CUENTA <= @CUENTAFIN 
           AND   ISNULL(MCH.CCOSTO,'') >= @CCOSTOINI AND ISNULL(MCH.CCOSTO,'') <= @CCOSTOFIN 
           AND   MCP.ESTADO=2 
           AND   ISNULL(MCP.ANULADO,0) = 0
           GROUP BY MCP.COMPANIA, ISNULL(TER.IDTERCERO,''), MCH.CUENTA, 
                    CASE COALESCE(@CCOSTOINI,'') WHEN '' THEN '' 
                                                ELSE CASE WHEN X.CLASE  IN ('CXC', 'CXP' ) THEN '' ELSE COALESCE(MCH.CCOSTO,'') END
                    END, 
                    ISNULL(MCH.N_FACTURA,''), MCP.FECHACONTABLE, MCH.DETALLE, MCP.COMPROBANTE, 
                    MCP.NOREFERENCIA, MCP.NROCOMPROBANTE, ISNULL(MCH.CODUNG,''), 
                    ISNULL(MCH.CODPRG,'')
          ) Y LEFT JOIN #TABLA_FNK_MOVXTERCERO X ON COALESCE(X.IDTERCERO,'') = COALESCE(Y.IDTERCERO,'') 
                                                AND COALESCE(X.CUENTA,'')    = COALESCE(Y.CUENTA,'')
                                                AND COALESCE(X.CCOSTO,'')    = COALESCE(Y.CCOSTO,'')
                                                AND COALESCE(X.N_FACTURA,'') = COALESCE(Y.N_FACTURA,'')
                                                AND COALESCE(X.CODUNG,'') = COALESCE(Y.CODUNG, '')
                                                AND COALESCE(X.CODPRG,'') = COALESCE(Y.CODPRG, '')
                                                AND X.TIPO = 2
    WHERE X.CUENTA IS NULL
    ORDER BY Y.CUENTA, Y.CCOSTO, Y.IDTERCERO, Y.N_FACTURA, Y.FECHAMOV 

-- IF CAST('01/'+STR(LTRIM(@MESINI))+'/'+STR(LTRIM(@ANOINI)) AS DATETIME) < @FECHAINI
-- BEGIN
--    -- Saldo Inicial desde el dia exacto
--    PRINT 'ANTES DEL UPDATE(*1)'
--    UPDATE #TABLA_FNK_MOVXTERCERO SET  SI = ISNULL(X.SI,0) + ISNULL(Y.DB,0) - ISNULL(Y.CR,0)
--	   FROM #TABLA_FNK_MOVXTERCERO X INNER JOIN (SELECT IDTERCERO = ISNULL(TER.IDTERCERO,''), CUENTA=MCH.CUENTA, CCOSTO=ISNULL(CEN.CCOSTO,''),
--                                                     N_FACTURA = ISNULL(MCH.N_FACTURA,''), CODUNG = ISNULL(MCH.CODUNG,''), CODPRG = ISNULL(MCH.CODPRG,''),
--                                                     DB = SUM(CASE WHEN MCH.TIPO = 'DB' THEN MCH.VALOR ELSE 0 END),
--                                                     CR = SUM(CASE WHEN MCH.TIPO = 'CR' THEN MCH.VALOR ELSE 0 END)
--                                              FROM   MCP  INNER JOIN MCH  ON MCP.COMPANIA=MCH.COMPANIA 
--                                                                         AND MCP.NROCOMPROBANTE = MCH.NROCOMPROBANTE 
--                                                           LEFT JOIN  TER ON TER.IDTERCERO = MCH.IDTERCERO 
--                                                           LEFT JOIN  CEN ON CEN.COMPANIA  = MCP.COMPANIA 
--                                                                         AND CEN.CCOSTO    = MCH.CCOSTO
--                                              WHERE  MCP.COMPANIA=@COMPANIA 
--                                              AND    MCP.FECHACONTABLE >= CAST('01/'+STR(LTRIM(@MESINI))+'/'+STR(LTRIM(@ANOINI)) AS DATETIME) 
--                                              AND    MCP.FECHACONTABLE < @FECHAINI 
--                                              AND    ISNULL(MCH.IDTERCERO,'') >= @IDTERCEROINI 
--                                              AND    ISNULL(MCH.IDTERCERO,'') <= @IDTERCEROFIN 
--                                              AND    MCH.CUENTA >= @CUENTAINI 
--                                              AND    MCH.CUENTA <= @CUENTAFIN 
--                                              AND    ISNULL(MCH.CCOSTO,'') >= @CCOSTOINI 
--                                              AND    ISNULL(MCH.CCOSTO,'') <= @CCOSTOFIN 
--                                              AND    MCP.ESTADO = 2 
--                                              AND    ISNULL(MCP.ANULADO,0) = 0 
--                                              GROUP BY ISNULL(TER.IDTERCERO,''), MCH.CUENTA, ISNULL(CEN.CCOSTO,''), ISNULL(MCH.N_FACTURA,''), 
--                                                       ISNULL(MCH.CODUNG,''), ISNULL(MCH.CODPRG,'')
--                                             ) Y ON X.IDTERCERO = Y.IDTERCERO 
--                                                AND X.CUENTA    = Y.CUENTA 
--                                                AND X.CCOSTO    = Y.CCOSTO 
--                                                AND X.N_FACTURA = Y.N_FACTURA 
--                                                AND X.CODUNG    = Y.CODUNG 
--                                                AND X.CODPRG    = Y.CODPRG       
--    PRINT 'ANTES DEL UPDATE(*2)'   
--    INSERT INTO #TABLA_FNK_MOVXTERCERO (TIPO, IDTERCERO, CUENTA, CCOSTO, N_FACTURA, DETALLE, COMPROBANTE, 
--                                        NOREFERENCIA, NROCOMPROBANTE, FECHAMOV, FECHAINI, FECHAFIN, SI, DB, CR, CODUNG, CODPRG)
--    SELECT 1, Y.IDTERCERO, Y.CUENTA, Y.CCOSTO, Y.N_FACTURA, Y.DETALLE, Y.COMPROBANTE, 
--           Y.NOREFERENCIA, Y.NROCOMPROBANTE, Y.FECHAMOV, @FECHAINI, @FECHAFIN, SI = 0, DB = ISNULL(Y.DB,0), CR = ISNULL(Y.CR,0), 
--           Y.CODUNG, Y.CODPRG
--    FROM   (SELECT MCP.COMPANIA, IDTERCERO=ISNULL(TER.IDTERCERO,''), CUENTA=MCH.CUENTA, CCOSTO=ISNULL(CEN.CCOSTO,''),
--                   N_FACTURA=ISNULL(MCH.N_FACTURA,''), DETALLE = MCH.DETALLE, MCP.COMPROBANTE, MCP.NOREFERENCIA, 
--                   MCP.NROCOMPROBANTE, FECHAMOV = MCP.FECHACONTABLE, DB = SUM(CASE WHEN MCH.TIPO = 'DB' THEN MCH.VALOR ELSE 0 END),
--                   CR = SUM(CASE WHEN MCH.TIPO = 'CR' THEN MCH.VALOR ELSE 0 END),
--                   CODUNG = ISNULL(MCH.CODUNG,''), CODPRG = ISNULL(MCH.CODPRG,'')		
--            FROM   MCP  INNER JOIN MCH  ON MCP.COMPANIA = MCH.COMPANIA 
--                                       AND MCP.NROCOMPROBANTE = MCH.NROCOMPROBANTE 
--                        LEFT JOIN  TER  ON TER.IDTERCERO = MCH.IDTERCERO 
--                        LEFT JOIN  CEN  ON CEN.CCOSTO    = MCH.CCOSTO 
--                                       AND CEN.COMPANIA  = MCP.COMPANIA
--            WHERE MCP.COMPANIA=@COMPANIA AND MCP.FECHACONTABLE >= CAST('01/'+STR(LTRIM(@MESINI))+'/'+STR(LTRIM(@ANOINI)) AS DATETIME) 
--            AND   MCP.FECHACONTABLE < @FECHAINI 
--            AND   ISNULL(MCH.IDTERCERO,'') >= @IDTERCEROINI AND ISNULL(MCH.IDTERCERO,'') <= @IDTERCEROFIN 
--            AND   MCH.CUENTA >= @CUENTAINI AND MCH.CUENTA <= @CUENTAFIN 
--            AND   ISNULL(MCH.CCOSTO,'') >= @CCOSTOINI AND ISNULL(MCH.CCOSTO,'') <= @CCOSTOFIN 
--            AND   MCP.ESTADO=2 
--            AND   ISNULL(MCP.ANULADO,0) = 0
--            GROUP BY MCP.COMPANIA, ISNULL(TER.IDTERCERO,''), MCH.CUENTA, ISNULL(CEN.CCOSTO,''), 
--                     ISNULL(MCH.N_FACTURA,''), MCP.FECHACONTABLE, MCH.DETALLE, MCP.COMPROBANTE, 
--                     MCP.NOREFERENCIA, MCP.NROCOMPROBANTE, ISNULL(MCH.CODUNG,''), 
--                     ISNULL(MCH.CODPRG,'')) Y LEFT JOIN #TABLA_FNK_MOVXTERCERO X ON X.IDTERCERO = Y.IDTERCERO 
--                                                                                AND X.CUENTA    = Y.CUENTA 
--                                                                                AND X.CCOSTO    = Y.CCOSTO 
--                                                                                AND X.N_FACTURA = Y.N_FACTURA 
--                                                                                AND X.CODUNG    = Y.CODUNG 
--                                                                                AND X.CODPRG    = Y.CODPRG
--    WHERE X.CUENTA IS NULL
--    ORDER BY Y.CUENTA, Y.CCOSTO, Y.IDTERCERO, Y.N_FACTURA, Y.FECHAMOV 
-- END
-- PRINT 'ANTES DEL UPDATE(*3)'

   PRINT 'ACTUALIZO DATOS DE RAZON SOCIAL Y NIT ' 
   UPDATE #TABLA_FNK_MOVXTERCERO SET RAZONSOCIAL = LEFT(TER.RAZONSOCIAL,119), NOMCUENTA = CUE.NOMCUENTA, NOMCCOSTO = CEN.DESCRIPCION,
   DETALLE = LEFT (CASE WHEN COALESCE(DETALLE,'') LIKE '%'+TER.RAZONSOCIAL+'%'  THEN COALESCE(DETALLE,'') ELSE COALESCE(DETALLE,'')+ ' '+COALESCE(TER.TIPO_ID,'')+': ' +COALESCE(TER.NIT,'')+' '+COALESCE(TER.RAZONSOCIAL,'') END,512),
   IDTERCERO=CASE WHEN TER.NIT IS NULL THEN A.IDTERCERO ELSE TER.NIT END
   FROM #TABLA_FNK_MOVXTERCERO  A LEFT JOIN TER  ON A.IDTERCERO  = TER.IDTERCERO 
                                 LEFT JOIN CUE  ON CUE.CUENTA   = A.CUENTA 
                                               AND CUE.COMPANIA = @COMPANIA 
                                 LEFT JOIN CEN  ON CEN.CCOSTO   = A.CCOSTO 
                                               AND CEN.COMPANIA = @COMPANIA

   

   DELETE FROM RPDX2 WHERE CNS = @CONSECUTIVORPDX
   SET @QUERYFINAL =  'INSERT INTO RPDX2 (CNS, VALOR10, ID1, STRINGMEDIO1, ID2, STRINGMEDIO2, ID3, STRINGMEDIO3, VALOR1, VALOR2, VALOR3, VALOR4, FECHA1, FECHA2, ID4, FECHA3, STRINGGRANDE1, ID5, ID6, ID7, ID8, ID9, ID10) '+
   'SELECT ''' + @CONSECUTIVORPDX +''', TIPO, CUENTA, LEFT(NOMCUENTA,99), CCOSTO, NOMCCOSTO, IDTERCERO, LEFT(RAZONSOCIAL,99), (CASE WHEN ESTADO = ''A'' THEN 0 ELSE SI END) SI, (CASE WHEN ESTADO = ''A'' THEN 0 ELSE DB END) DB, ' +
   '(CASE WHEN ESTADO = ''A'' THEN 0 ELSE CR END) CR, (CASE WHEN ESTADO = ''A'' THEN 0 ELSE SF END) SF, FECHAINI, FECHAFIN, N_FACTURA, FECHAMOV, DETALLE, COMPROBANTE, NOREFERENCIA, CODUNG, CODPRG, NOCHEQUE, ESTADO ' +
   'FROM #TABLA_FNK_MOVXTERCERO ' + @WHERE + ' ORDER BY CUENTA, FECHAMOV, N_FACTURA'
   PRINT @QUERYFINAL
   EXEC (@QUERYFINAL)
   --SELECT * FROM RPDX2 WHERE CNS = @CONSECUTIVORPDX  
   DROP TABLE #TABLA_FNK_MOVXTERCERO
END


