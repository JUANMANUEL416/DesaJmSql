IF EXISTS (SELECT NAME FROM SYSOBJECTS WHERE NAME = 'SPK_GENERA_ORDENPAGO_IZIPAY' AND TYPE = 'P')
BEGIN
   DROP PROCEDURE SPK_GENERA_ORDENPAGO_IZIPAY
END
GO
CREATE PROCEDURE DBO.SPK_GENERA_ORDENPAGO_IZIPAY
@NOADMISION VARCHAR(20),
@TABLA      VARCHAR(20),
@PROCEDENCIA VARCHAR(20),
@IDAFILIADO  VARCHAR(20),
@VALOR       DECIMAL(14,2),
@N_FACTURA   VARCHAR(20),
@USUARIO     VARCHAR(20),
@IDKPAGE     INT = 0,
@PROCESO     VARCHAR(20)
WITH ENCRYPTION
AS 
DECLARE @FECHA		DATETIME
DECLARE @DATE		VARCHAR(19)
DECLARE @MES		VARCHAR(2)
DECLARE @ANIO		VARCHAR(4)
DECLARE @DIA		VARCHAR(2)
DECLARE @HORA		VARCHAR(8)
DECLARE @BODY		VARCHAR(1000)
DECLARE @sUrl		VARCHAR(3096)
DECLARE @obj		INT
DECLARE @response	VARCHAR(max)
DECLARE @urlpago	VARCHAR(255)
DECLARE @CNSFCJ		VARCHAR(20)
DECLARE @answer		NVARCHAR(max)
DECLARE @RESPUESTA	VARCHAR(20)
DECLARE @paymentOrderId		 VARCHAR(40)
DECLARE @paymentOrderStatus	 VARCHAR(40)
DECLARE @MENSAJE	VARCHAR(200)
DECLARE @BASIC   VARCHAR(500) 
DECLARE @EMAIL   VARCHAR(500)
DECLARE @CELULAR VARCHAR(20)
DECLARE @NOMBREAFI VARCHAR(150)
BEGIN
   IF @PROCESO='CREAR'
   BEGIN
      IF @IDKPAGE>0
      BEGIN
         IF EXISTS(SELECT * FROM KPAGE WHERE IDKPAGE=@IDKPAGE AND ESTADO='PAID')
         BEGIN
            PRINT 'Orden ya fue Pagada por el Usuario'
            RETURN
         END
         IF EXISTS(SELECT * FROM KPAGE WHERE IDKPAGE=@IDKPAGE AND ESTADO IN('UNPAID','RUNNING'))
         BEGIN
            PRINT 'Orden activa  a la espera del pago'
            RETURN
         END
         PRINT 'Orden cancelada o expirada debo Crear una nueva'
      END

      INSERT INTO KPAGE(CONSECUTIVO, TABLA, PROCEDENCIA, FECHAGEN,MODO, VALOR, ESTADO,USUCOBRA, IDPLAN,REF_PAGO)
   	SELECT @NOADMISION,@TABLA,@PROCEDENCIA, CONVERT(SMALLDATETIME,GETDATE()),'PRODUCTION', @VALOR, 'CREATED',@USUARIO,NULL,@N_FACTURA
	
		SET @IDKPAGE = @@IDENTITY
      IF @PROCEDENCIA='CIT'
      BEGIN
         UPDATE CIT SET IDKPAGE=@IDKPAGE WHERE CONSECUTIVO=@NOADMISION
      END
   END
   IF COALESCE(@IDKPAGE,0)=0
   BEGIN
      RETURN
   END
   SELECT @sUrl= DBO.FNK_VALORVARIABLE('URL_PASARELA_IZIPAY')+'CreatePaymentOrder'
   IF DB_NAME()=DBO.FNK_VALORVARIABLE('BDATA_PRODUCCION')
   BEGIN
      SELECT @BASIC=DBO.FNK_VALORVARIABLE('IZIPAY_SERVICEMODE')
   END
   ELSE
   BEGIN
      SELECT @BASIC=LTRIM(RTRIM(DBO.FNK_VALORVARIABLE('IZIPAYSERVCEMODETEST')))
   END
   SELECT @FECHA=DATEADD(HOUR,6,GETDATE())
   SELECT @DIA  =  convert(varchar, @FECHA, 3)
	SELECT @MES  = 	convert(varchar, @FECHA, 1)
	SELECT @ANIO =  convert(varchar, @FECHA, 23)
	SELECT @HORA =  convert(varchar, @FECHA, 8)

	SET @DATE = @ANIO+'-'+@MES+'-'+@DIA--+'T'+@HORA
   
   SELECT @EMAIL = LTRIM(RTRIM(REPLACE(REPLACE(EMAIL,CHAR(13),''),CHAR(10),''))), @CELULAR = CELULAR, @NOMBREAFI =LTRIM(TRIM(NOMBREAFI)) FROM AFI WHERE IDAFILIADO = @IDAFILIADO

   SELECT @BODY='{ '
   SELECT @BODY=@BODY+'"amount":'+REPLACE(REPLACE(CONVERT(varchar(50), CAST(@VALOR AS money), 1),'.',''),',','')+','
   SELECT @BODY=@BODY+' "currency": "PEN",'
   SELECT @BODY=@BODY+' "customer": { '
   SELECT @BODY=@BODY+' "reference": "Servicios de Salud", '
   SELECT @BODY=@BODY+' "email": "'+@EMAIL+'"'
   SELECT @BODY=@BODY+'},'
   SELECT @BODY=@BODY+' "dataCollectionForm": false,'
   SELECT @BODY=@BODY+' "expirationDate": "2024-09-26T23:59:14+00:00",'
   SELECT @BODY=@BODY+'"orderId": "'+CAST(@IDKPAGE AS VARCHAR(10))+'",'
   SELECT @BODY=@BODY+'"subMerchantDetails": { '
   SELECT @BODY=@BODY+'"name": "'+@NOMBREAFI+'" '
   SELECT @BODY=@BODY+' } '
   SELECT @BODY=@BODY+'}'

   PRINT '@BODY '+ @BODY

	EXEC sys.sp_OACreate 'MSXML2.ServerXMLHttp', @obj OUT
	EXEC sys.sp_OAMethod @obj, 'Open', NULL, 'POST', @sUrl, false
	EXEC sys.sp_OAMethod @Obj, 'setRequestHeader', null, 'Authorization', @basic 
	EXEC sys.sp_OAMethod @Obj, 'setRequestHeader', null, 'Content-Type', 'application/json'
	EXEC sys.sp_OAMethod @Obj, 'setRequestHeader', null, 'Accept', 'application/json'
	EXEC SYS.sp_OAMethod @obj, 'send', null, @Body
	EXEC sys.sp_OAMethod @obj, 'responseText', @response OUTPUT
	IF @response IS NULL
	BEGIN
		DECLARE @TABLA_TMP AS TABLE (ITEM INT IDENTITY(1,1), RESPONSE VARCHAR(MAX))
		INSERT INTO @TABLA_TMP(RESPONSE)
		EXEC sys.sp_OAGetProperty @obj, 'responseText'
		SELECT @response=RESPONSE FROM @TABLA_TMP
	END
   PRINT @response
	EXEC sys.sp_OADestroy @obj

	select @RESPUESTA = [status] from openjson (@response) with (status varchar(20) '$.status')

	UPDATE KPAGE SET BODY = @BODY WHERE IDKPAGE = @IDKPAGE	
	--select @response
         
	IF @RESPUESTA = 'SUCCESS'
	BEGIN
		SELECT @answer = answer FROM OPENJSON(@response) with( answer NVARCHAR(MAX) AS JSON )
		SELECT @urlpago = paymentURL, @paymentOrderId = paymentOrderId 
      FROM OPENJSON( @answer ) 
      with ( paymentURL VARCHAR(100) '$.paymentURL',
      paymentOrderId  varchar(40) '$.paymentOrderId'
      )
		UPDATE KPAGE SET ESTADO='SEND',RESPUESTA = @response, paymentOrderId = @paymentOrderId,LINKPAGO=@urlpago WHERE IDKPAGE = @IDKPAGE	
   END

END