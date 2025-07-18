IF EXISTS (SELECT name FROM sysobjects WHERE name = 'SPK_PEDIDO_VENTA_WOOCOM' AND type = 'P')
BEGIN
   DROP PROCEDURE SPK_PEDIDO_VENTA_WOOCOM
END
GO
CREATE PROCEDURE DBO.SPK_PEDIDO_VENTA_WOOCOM 
 @ITEM INT,
 @IDPLAN VARCHAR(6)=NULL,
 @SECTOR VARCHAR(20)='VENTAS',
 @IDSEDE VARCHAR(6)='01',
 @IDBODEGA       VARCHAR(20)='PROD'
WITH ENCRYPTION
AS
DECLARE @PEDIDO NVARCHAR(MAX)
DECLARE @ARTICULOS NVARCHAR(MAX)
DECLARE @CLIENTE NVARCHAR(MAX)
DECLARE @IDTERCERO VARCHAR(20)
DECLARE @USUARIO VARCHAR(8)
DECLARE @ITEMWOCOMER INT
DECLARE @TIPOBODEGA     VARCHAR(10)
DECLARE @CNSIZSOL       VARCHAR(20)
DECLARE @CNSIZSOLD      VARCHAR(20)
DECLARE @CLASEPED       VARCHAR(10)
DECLARE @ESTADOPED      BIT
DECLARE @PNOMBRES VARCHAR(120)
DECLARE @APELLIDOS VARCHAR(120)
DECLARE @DIRECCION VARCHAR(256)
DECLARE @EMAIL VARCHAR(256)
DECLARE @TELEFONO  VARCHAR(30)
DECLARE @IDAFIAUTO VARCHAR(20)
DECLARE @COMPANIA  VARCHAR(2)='01'
DECLARE @IDTERKRY  VARCHAR(20)
DECLARE @IZSOLD   TABLE(ITEM INT IDENTITY(1,1),
   IDARTICULO VARCHAR(MAX),
   CANTIDAD VARCHAR(MAX),
   SUBTOTAL DECIMAL(14,2),
   SUBTOTAL_IMP DECIMAL(14,2) ,
   TOTAL DECIMAL(14,2),
   TOTAL_IMP DECIMAL(14,2)
)
BEGIN
   PRINT 'EMPIEZO EL PEDIDO '
   IF NOT EXISTS(SELECT * FROM WOOCOMMERCE WHERE ITEM=@ITEM AND ESTADO=0)
   BEGIN
      RAISERROR('Pedido ya procesado, Revise la Dispensación',1,16)
      RETURN
   END
   
   SELECT @PEDIDO=PEDIDO,
   @IDTERCERO=IDTERCERO,
   @USUARIO=USUARIO
   FROM WOOCOMMERCE
   WHERE ITEM=@ITEM
   AND ESTADO=0 -- REVISAR VALIDACION

   IF @ESTADOPED<>0
   BEGIN
      PRINT 'Pedido ya procesado, Revise las entregas...'
      RETURN
   END

   SELECT @ARTICULOS = order_items, @CLIENTE=billing,@ITEMWOCOMER=idpedido
   FROM OPENJSON(@PEDIDO) WITH (
   order_items NVARCHAR(MAX) AS JSON ,
   billing NVARCHAR(MAX) AS JSON,
   idpedido INT '$.id'
   )

   IF EXISTS(SELECT * FROM IZSOL WHERE NOADMISION=LTRIM(RTRIM(CAST(@ITEMWOCOMER AS VARCHAR(20)))))
   BEGIN
      PRINT 'Orden de Pedido ya procesado, Revise las entregas...'
      UPDATE WOOCOMMERCE SET COMENTARIOS = 'Orden de Pedido ya procesado, Revise las entregas...', ESTADO = 2 WHERE ITEM = @ITEM
      RETURN    
   END
   IF NOT EXISTS(SELECT * FROM TER WHERE(NIT=@IDTERCERO OR IDTERCERO=@IDTERCERO) )
   BEGIN
       PRINT 'NO EXISTE EL TERCERO VOY A BUSCAR LOS DATOS Y TRAERLOS'
       PRINT @CLIENTE
       SELECT @PNOMBRES=first_name,@APELLIDOS=last_name,@DIRECCION=address_1,@EMAIL=email,@TELEFONO=phone
       FROM  OPENJSON(@CLIENTE) WITH(
            first_name VARCHAR(120)'$.first_name',
            last_name VARCHAR(120)'$.last_name',
            address_1 VARCHAR(256)'$.address_1',
            email VARCHAR(120)'$.email',
            phone VARCHAR(30)'$.phone'
       )
      SELECT @IDAFIAUTO=SPACE(20)
      EXEC SPK_GENCONSECUTIVO @COMPANIA,@IDSEDE,'@AFI', @IDAFIAUTO OUTPUT  
      SELECT @IDAFIAUTO = @IDSEDE + REPLACE(SPACE(8 - LEN(@IDAFIAUTO))+LTRIM(RTRIM(@IDAFIAUTO)),SPACE(1),0)    

      INSERT INTO TER(IDTERCERO,RAZONSOCIAL,TIPO_ID,NIT,DV,DIRECCION,TELEFONOS,EMAIL,ESTADO,ENVIODICAJA)
      SELECT @IDAFIAUTO,COALESCE(@PNOMBRES,'')+' '+COALESCE(@APELLIDOS,''),'NIT',@IDTERCERO,
      dbo.FNK_CALCULA_DV(@IDTERCERO),@DIRECCION,@TELEFONO,@EMAIL,'Activo',1

      SELECT @IDTERKRY=@IDAFIAUTO
      


   END
   ELSE
   BEGIN 
      SELECT @IDTERKRY=IDTERCERO FROM TER  TER WHERE(NIT=@IDTERCERO OR IDTERCERO=@IDTERCERO)
   END

    IF NOT EXISTS(SELECT * FROM PPT WHERE IDTERCERO=@IDTERKRY)
    BEGIN
      INSERT INTO PPT(IDPLAN,IDTARIFA,IDTERCERO,TIPOTERCONTABLE)
      SELECT 'VENTA','VT',@IDTERKRY,'CLIENTE'
    END

   INSERT INTO @IZSOLD(IDARTICULO,CANTIDAD,SUBTOTAL,SUBTOTAL_IMP,TOTAL,TOTAL_IMP)
   SELECT IDARTICULO,CANTIDAD,SUBTOTAL,SUBTOTAL_IMP,TOTAL,TOTAL_IMP
   FROM OPENJSON(@ARTICULOS) WITH (
   IDARTICULO VARCHAR(MAX) '$.IDARTICULO',
   CANTIDAD VARCHAR(MAX) '$.quantity',
   SUBTOTAL DECIMAL(14,2) '$.subtotal',
   SUBTOTAL_IMP DECIMAL(14,2) '$.subtotal_tax',
   TOTAL DECIMAL(14,2) '$.total',
   TOTAL_IMP DECIMAL(14,2) '$.total_tax')


   PRINT 'VOY PARA IZSOL E IZSOLD'
   SELECT @CNSIZSOL = ''
   EXEC SPK_GENCONSECUTIVO '01',@IDSEDE,'@IZSOL', @CNSIZSOL OUTPUT  
   SELECT @CNSIZSOL = @IDSEDE + REPLACE(SPACE(10 - LEN(@CNSIZSOL))+LTRIM(RTRIM(@CNSIZSOL)),SPACE(1),0)  
      
   PRINT '@CNSIZSOL == '+@CNSIZSOL

   INSERT INTO IZSOL (CNSIZSOL, FECHASOL, USUARIOSOL, ESTADO, IDBODEGAATIENDE, SECTOR, CLASE, NOADMISION, CNSIZSOLM ,IDSEDE,IDTERCEROC,IDPLAN)
   SELECT @CNSIZSOL,  GETDATE(), @USUARIO, 1, @IDBODEGA,COALESCE(@SECTOR,'Ventas'), 'Ventas', @ITEMWOCOMER, @ITEM ,COALESCE(@IDSEDE,'01'),@IDTERKRY,COALESCE(@IDPLAN,'VENTA')

   --DECLARE @BANDERA INT
   --DECLARE @LIMITE  INT
   --SELECT @BANDERA=1,@LIMITE=0
      
   --SELECT @LIMITE=COUNT(*) FROM @IZSOLD
   
   --WHILE @BANDERA<=@LIMITE
   --BEGIN
   --   SELECT @CNSIZSOLD = ''
   --   EXEC SPK_GENCONSECUTIVO '01',@IDSEDE,'@IZSOLD', @CNSIZSOLD OUTPUT  
   --   SELECT @CNSIZSOLD = @IDSEDE + REPLACE(SPACE(10 - LEN(@CNSIZSOLD))+LTRIM(RTRIM(@CNSIZSOLD)),SPACE(1),0)  
   --   INSERT INTO IZSOLD (CNSIZSOLD , CNSIZSOL , IDARTICULO , CANTIDADSOL , ESTADO, CODOM,VLR_UNIVENT,VLR_IVAVENT,VLR_TOTVENT, IDSERVICIO, IDPRINCIPIO) 
   --   SELECT @CNSIZSOLD,@CNSIZSOL,#IZSOLD.IDARTICULO,#IZSOLD.CANTIDAD,1,NULL,(#IZSOLD.SUBTOTAL/#IZSOLD.CANTIDAD),
   --   (#IZSOLD.SUBTOTAL_IMP/#IZSOLD.CANTIDAD),#IZSOLD.TOTAL+#IZSOLD.TOTAL_IMP, #IZSOLD.IDARTICULO, #IZSOLD.IDARTICULO
   --   FROM @IZSOLD #IZSOLD INNER JOIN IART ON #IZSOLD.IDARTICULO=IART.IDARTICULO
   --         LEFT JOIN SER ON IART.IDARTICULO=SER.IDARTICULO
   --   WHERE #IZSOLD.ITEM=@BANDERA
      
   --   SELECT @BANDERA=@BANDERA+1       
   --END

   INSERT INTO IZSOLD (CNSIZSOL , IDARTICULO , CANTIDADSOL , ESTADO, CODOM,VLR_UNIVENT,VLR_IVAVENT,VLR_TOTVENT, IDSERVICIO, IDPRINCIPIO) 
   SELECT @CNSIZSOL,#IZSOLD.IDARTICULO,#IZSOLD.CANTIDAD,1,NULL,(#IZSOLD.SUBTOTAL/#IZSOLD.CANTIDAD),
   (#IZSOLD.SUBTOTAL_IMP/#IZSOLD.CANTIDAD),#IZSOLD.TOTAL+#IZSOLD.TOTAL_IMP, #IZSOLD.IDARTICULO, #IZSOLD.IDARTICULO
   FROM @IZSOLD #IZSOLD INNER JOIN IART ON #IZSOLD.IDARTICULO=IART.IDARTICULO
         LEFT JOIN SER ON IART.IDARTICULO=SER.IDARTICULO

   UPDATE WOOCOMMERCE SET ESTADO=1 WHERE ITEM=@ITEM
END


