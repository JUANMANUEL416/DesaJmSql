CREATE OR ALTER PROCEDURE DBO.SPK_JSON_FTR_PERU_INTERFAX_FNOT
@CNSFNOT  VARCHAR(20),
@N_FACTURA  VARCHAR(20)
WITH ENCRYPTION
AS 
DECLARE 
 @JSON VARCHAR(MAX)
,@JSOND VARCHAR(MAX)                    ,@CODDOC VARCHAR(4)                      ,@PREFACT VARCHAR(4)                     ,@NFACTURA VARCHAR(20)
,@PK_PREABO VARCHAR(20)                 ,@NU_PREABO VARCHAR(20)                  ,@PK_PREFA_ORIG VARCHAR(20)              ,@NU_PREFA_ORIG VARCHAR(20)
,@NU_COMP_SUNAT VARCHAR(20)             ,@CO_MOTI_SAP VARCHAR(20)                ,@IM_TOTA_BASE VARCHAR(20)               ,@IM_TOTA_IGV VARCHAR(20)
,@IM_TOTAL VARCHAR(20)                  ,@CO_USUA_TRAN VARCHAR(20)               ,@CO_USUA_REM VARCHAR(20)                ,@NU_REME VARCHAR(20)
,@CAN_REM VARCHAR(20)                   ,@FEC_PRE_ABONO VARCHAR(20)              ,@BODY VARCHAR(MAX)                      ,@TIPOFNOT VARCHAR(10)
,@TIPODOC VARCHAR(4)                    ,@CNSDOCUMENTO VARCHAR(20)               ,@COMPANIA VARCHAR(2)                    ,@IDSEDE VARCHAR(6)
,@TIPODOCREL VARCHAR(2)                 ,@ID_ITEM_PREABO VARCHAR(20)
,@PK_VALE_PREABO VARCHAR(20)            ,@IM_BASE_ITEM VARCHAR(20)               ,@CO_PRES_ITEM VARCHAR(20)               ,@DE_PRES_ITEM VARCHAR(20)
,@CA_ITEM VARCHAR(20)                   ,@PC_IGV VARCHAR(20)                     ,@CO_SUB_MECA VARCHAR(20)                ,@CO_TIPO_ITEM VARCHAR(20)
,@CONTADOR INT                          ,@OK VARCHAR(4)                          ,@sUrl VARCHAR(2049)                     ,@response VARCHAR(MAX)
BEGIN
   IF EXISTS(SELECT  * FROM FNOT WHERE CNSFNOT=@CNSFNOT AND N_FACTURA=@N_FACTURA AND COALESCE(CNSDIANFE,'')='')
   BEGIN
      SELECT @TIPODOC=(CASE FNOT.CLASE WHEN 'C' THEN '07' WHEN 'D' THEN '08' ELSE '' END),@IDSEDE=FTR.IDSEDE, @COMPANIA='01',
      @TIPODOCREL= CASE WHEN FTR.TIPOFIN='N' THEN '03' ELSE '01' END 
      FROM FNOT INNER JOIN FTR ON FNOT.N_FACTURA=FTR.N_FACTURA
      WHERE  CNSFNOT=@CNSFNOT 
      AND FTR.N_FACTURA=@N_FACTURA 
      SET @TIPOFNOT=(CASE @TIPODOC WHEN '07' THEN IIF(@TIPODOCREL='03','NCB','NCF') WHEN '08' THEN IIF(@TIPODOCREL='03','NDB','NDF') END)
      SET @CNSDOCUMENTO = SPACE(20)
      PRINT '@COMPANIA= '+COALESCE(@COMPANIA,'SIN CIA')+'@IDSEDE '+COALESCE(@IDSEDE,'SIN SEDE')+'@TIPOFNOT ='+COALESCE(@TIPOFNOT,'SINTIPONC')
      EXEC SPK_GENNUMEROFACTURA @COMPANIA, @IDSEDE, NULL, @CNSDOCUMENTO OUTPUT, @TIPOFNOT
      PRINT 'REGRESO DE SPK_GENNUMEROFACTURA '
      UPDATE FNOT SET CNSDIANFE=@CNSDOCUMENTO WHERE CNSFNOT=@CNSFNOT AND N_FACTURA=@N_FACTURA

   END


    SELECT @PK_PREABO=CONVERT(int,REPLACE(FNOT.CNSFNOT,'C','')),@NU_PREABO=FNOT.CNSDIANFE,@NU_PREFA_ORIG=FNOT.N_FACTURA,@NU_COMP_SUNAT='',
    @CO_MOTI_SAP='C44',@IM_TOTA_BASE= CAST(SUM(FNOTD.VR_TOTAL-CASE WHEN COALESCE(FNOTD.PIVA,0)>0 THEN FNOTD.VALORIVA ELSE 0 END) AS VARCHAR(20)),
    @IM_TOTA_IGV=CAST(SUM(CASE WHEN COALESCE(FNOTD.PIVA,0)>0 THEN FNOTD.VALORIVA ELSE 0 END)AS VARCHAR(20)),
    @IM_TOTAL=CAST(FNOT.VR_TOTAL AS VARCHAR(20)),
    @CO_USUA_TRAN=FNOT.USUARIO,
    @NU_REME='',
    @CAN_REM='',
    @FEC_PRE_ABONO=REPLACE(CONVERT(VARCHAR,FNOT.F_NOTA,102),'.',''),
    @PK_PREFA_ORIG=CONVERT(VARCHAR,CONCAT(CONVERT(INT,FTR.IDSEDE),CONVERT(INT,RIGHT(CNSFCT,LEN(FTR.IDSEDE)))),20)
    FROM FNOT INNER JOIN FNOTD ON FNOT.CNSFNOT=FNOTD.CNSFNOT
              INNER JOIN FTR ON FNOT.N_FACTURA=FTR.N_FACTURA
    WHERE FNOT.CNSFNOT= @CNSFNOT
    AND FNOT.N_FACTURA= @N_FACTURA
    GROUP BY CONVERT(int,REPLACE(FNOT.CNSFNOT,'C','')),FNOT.CNSDIANFE,FNOT.N_FACTURA,
    FNOT.VR_TOTAL,
    FNOT.USUARIO,
    REPLACE(CONVERT(VARCHAR,FNOT.F_NOTA,102),'.',''),
    CONVERT(VARCHAR,CONCAT(CONVERT(INT,FTR.IDSEDE),CONVERT(INT,RIGHT(CNSFCT,LEN(FTR.IDSEDE)))),20)


   SELECT @JSON='{ '
   SELECT @JSON=@JSON+' "EPreabono":{ '
   SELECT @JSON=@JSON+'"PK_PREABO":"'+@PK_PREABO+'",'
   SELECT @JSON=@JSON+'"NU_PREABO":"'+@NU_PREABO+'",'
   SELECT @JSON=@JSON+'"PK_PREFA_ORIG":"'+@PK_PREFA_ORIG+'",'
   SELECT @JSON=@JSON+'"NU_PREFA_ORIG":"'+@NU_PREFA_ORIG+'",'
   SELECT @JSON=@JSON+'"NU_COMP_SUNAT":"'+@NU_COMP_SUNAT+'",'
   SELECT @JSON=@JSON+'"CO_MOTI_SAP":"'+@CO_MOTI_SAP+'",'
   SELECT @JSON=@JSON+'"IM_TOTA_BASE":"'+@IM_TOTA_BASE+'",'
   SELECT @JSON=@JSON+'"IM_TOTA_IGV":"'+@IM_TOTA_IGV+'",'
   SELECT @JSON=@JSON+'"IM_TOTAL":"'+@IM_TOTAL+'",'
   SELECT @JSON=@JSON+'"CO_USUA_TRAN":"'+@CO_USUA_TRAN+'",'
   SELECT @JSON=@JSON+'"CO_USUA_REM":"'+COALESCE(@CO_USUA_REM,'')+'",'
   SELECT @JSON=@JSON+'"NU_REME":"'+@NU_REME+'",'
   SELECT @JSON=@JSON+'"CAN_REM":"'+@CAN_REM+'",'
   SELECT @JSON=@JSON+'"FEC_PRE_ABONO":"'+@FEC_PRE_ABONO+'",'

   PRINT @JSON

   SELECT @JSON=@JSON+' "EPreabonoDetalle": [ '
   PRINT 'DETALLES DE LA NOTA' --FNOTD

   SELECT @CONTADOR =0
   DECLARE @N_CUOTA INT 
   DECLARE XMLFNOTD_CURSOR CURSOR FOR
   SELECT ITEM  FROM FNOTD WHERE CNSFNOT=@CNSFNOT AND N_FACTURA=@N_FACTURA
   AND COALESCE(FNOTD.VR_TOTAL,0)>0
   ORDER BY ITEM ASC
   OPEN XMLFNOTD_CURSOR    
   FETCH NEXT FROM XMLFNOTD_CURSOR    
   INTO @N_CUOTA
   WHILE @@FETCH_STATUS = 0    
   BEGIN 
      SELECT @CONTADOR=@CONTADOR+1
      IF @CONTADOR>1
      BEGIN
         SELECT @JSON=@JSON+' , '
      END
      SELECT @ID_ITEM_PREABO=CAST((@CONTADOR*10) AS varchar(20)),@PK_VALE_PREABO='',@IM_BASE_ITEM=CAST(VR_TOTAL AS varchar(20)),
      @CO_PRES_ITEM=FNOTD.IDSERVICIO,@DE_PRES_ITEM=dbo.FNK_LIMPIATEXTO(FNOTD.DESCRIPCION,'0-9 A-Z().;:,'),
      @CA_ITEM=CAST(FNOTD.CANTIDAD AS VARCHAR(20)),
      @PC_IGV=CAST(CASE WHEN  FNOTD.PIVA>0 THEN FNOTD.PIVA ELSE 0 END AS VARCHAR(20)),
      @CO_SUB_MECA='', @CO_TIPO_ITEM='I'
      FROM FNOTD LEFT JOIN SER ON FNOTD.IDSERVICIO=SER.IDSERVICIO AND FNOTD.TIPO='S'
                 LEFT JOIN CPNT ON FNOTD.IDSERVICIO=CPNT.CODIGO AND FNOTD.TIPO='C'
      WHERE CNSFNOT=@CNSFNOT
      AND N_FACTURA=@N_FACTURA
      AND N_CUOTA=@N_CUOTA
      SELECT @JSON=@JSON+'{ '
      SELECT @JSON=@JSON+'"PK_PREABO":"'+@PK_PREABO+'",'
      SELECT @JSON=@JSON+'"NU_PREABO":"'+@NU_PREABO+'",'
      SELECT @JSON=@JSON+'"ID_ITEM_PREABO":"'+@ID_ITEM_PREABO+'",'
      SELECT @JSON=@JSON+'"PK_VALE_PREABO":"'+@PK_VALE_PREABO+'",'
      SELECT @JSON=@JSON+'"IM_BASE_ITEM":"'+@IM_BASE_ITEM+'",'
      SELECT @JSON=@JSON+'"CO_PRES_ITEM":"'+@CO_PRES_ITEM+'",'
      SELECT @JSON=@JSON+'"DE_PRES_ITEM":"'+@DE_PRES_ITEM+'",'
      SELECT @JSON=@JSON+'"CA_ITEM":"'+@CA_ITEM+'",'
      SELECT @JSON=@JSON+'"PC_IGV":"'+@PC_IGV+'",'
      SELECT @JSON=@JSON+'"CO_SUB_MECA":"'+@CO_SUB_MECA+'",'
      SELECT @JSON=@JSON+'"CO_TIPO_ITEM":"'+@CO_TIPO_ITEM+'"'
           
      SELECT @JSON=@JSON+'}'


	   FETCH NEXT FROM XMLFNOTD_CURSOR    
	   INTO @N_CUOTA
   END
   CLOSE XMLFNOTD_CURSOR
   DEALLOCATE XMLFNOTD_CURSOR

	SELECT @JSON=LTRIM(RTRIM(@JSON)) +' ] } }'

   PRINT @JSON

   IF LEN(@JSON)<10
   BEGIN
      PRINT 'NO TENGO DATOS'
      RETURN
   END


  PRINT 'DEFINITIVO'
  PRINT @JSON
  SELECT @BODY=@JSON
  IF @TIPODOCREL='03' -- BOLETA
  BEGIN
      SELECT @sUrl='/FacturacionPaciente/AbonoPacienteEM'
  END
  ELSE
  BEGIN
      SELECT @sUrl='/FacturacionGarante/AbonoGaranteEM'
  END

  EXEC SPK_ENVIA_TRAMAS_CIPERU @ENDPOINT=@sUrl, @TRAMA = @BODY,@OK=@OK OUTPUT,  @RESPUESTA= @response OUTPUT

  --EXEC SPK_ENVIA_JSON_INTERFAX @JSON,@sUrl,@OK OUTPUT,@response OUTPUT

  IF @OK='KO'
  BEGIN
     INSERT INTO FTRAPILOG(N_FACTURA,TIPODOC,ESTADOC,ERRORES,METODO,JSONSOLICITUD,JSONRESPUESTA)
     SELECT @N_FACTURA,@TIPODOC,'KO',@response,'INTER_FNOT',@JSON,@response
  END
  ELSE
  BEGIN
     IF ISJSON(@response)=1
     BEGIN
        PRINT 'PARCIAR RESPUESTA'
     END
     UPDATE FNOT SET FACTEP='104',RESPUESTAJSON=@response WHERE N_FACTURA=@N_FACTURA
   
     INSERT INTO FTRAPILOG(N_FACTURA,TIPODOC,ESTADOC,ERRORES,METODO,JSONSOLICITUD,JSONRESPUESTA)
     SELECT @N_FACTURA,@TIPODOC,'OK',@response,'INTER_FNOT',@JSON,@response
  END

END



