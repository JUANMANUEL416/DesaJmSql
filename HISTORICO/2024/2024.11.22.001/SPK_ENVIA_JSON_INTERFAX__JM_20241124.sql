CREATE OR ALTER PROCEDURE DBO.SPK_ENVIA_JSON_INTERFAX @JSON NVARCHAR(MAX),@URL VARCHAR(2024),@OK VARCHAR(10) OUTPUT,@RESPUESTA VARCHAR(MAX) OUTPUT
	WITH ENCRYPTION
AS
SET DATEFORMAT dmy
DECLARE @obj INT;
DECLARE @Body NVARCHAR(MAX)
DECLARE @response NVARCHAR(MAX);
DECLARE @sUrl VARCHAR(2048)
BEGIN
   -- Ruta completa al certificado en el servidor
   DECLARE @certPath NVARCHAR(256) = 'D:\Kryst_TSPLUS\FacturacionElectronica\PINTERNACIONAL\Certificates\cinrhapsodyqas1.cinternacional.com.pe_2050.pfx';
   DECLARE @certPassword NVARCHAR(256) = 'Rh4ps0dyC1Q4s';

   IF LEN(@JSON)<=0
   BEGIN
      SELECT 'KO','json no tiene datos, Verifique e intente de nuevo'RESPUESTA
      RETURN
   END
   if ISJSON(@JSON)=0
   BEGIN
      SELECT 'KO','Json No Valido. Error de Estructura, Verifique e intente de nuevo'RESPUESTA
      RETURN
   END
   IF COALESCE(@URL,'')=''
   BEGIN
      SELECT 'KO','Url No Valida o en Blanco, verifique e intente de nuevo'RESPUESTA
      RETURN      
   END
   SELECT @sUrl=@URL
   PRINT '@sUrl= '+@sUrl
   -- Crear el objeto XMLHTTP
   EXEC sys.sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @obj OUT;

   -- Abrir la solicitud
   EXEC sys.sp_OAMethod @obj, 'open', NULL, 'POST', @sUrl, false;

   -- Configurar el certificado
   EXEC sys.sp_OAMethod @obj, 'setRequestHeader', NULL, 'Content-Type', 'application/json';
   -- Opción de certificado si necesario, usar la constante 2 para SXH_OPTION_SELECT_CLIENT_SSL_CERT

   DECLARE @sslConfig INT;
   SET @sslConfig = 2; -- SXH_OPTION_SELECT_CLIENT_SSL_CERT

   -- Ajustar las opciones SSL
   EXEC sys.sp_OAMethod @obj, 'setOption', NULL, @sslConfig, @certPath;

   -- Establecer las cabeceras
   EXEC sys.sp_OAMethod @obj, 'setRequestHeader', NULL, 'Content-Type', 'application/json';

   -- Enviar la solicitud
   BEGIN TRY           
      EXEC sys.sp_OAMethod @obj, 'send', NULL, @Body;

      -- Obtener la respuesta
      EXEC sys.sp_OAMethod @obj, 'responseText', @response OUTPUT;                       
   END TRY
   BEGIN CATCH
           SELECT ERROR_MESSAGE()
   END CATCH


   -- Imprimir la respuesta
   PRINT COALESCE(@response,'NO TENGO RESPUESTAS');
   -- Liberar el objeto
   EXEC sys.sp_OADestroy @obj

   SELECT 'OK',@response RESPUESTA

END