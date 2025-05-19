IF EXISTS(SELECT NAME FROM SYSOBJECTS WHERE NAME='FNK_DE_VALORES_A_LETRAS' AND XTYPE='FN')
BEGIN
 DROP FUNCTION FNK_DE_VALORES_A_LETRAS
END
GO
CREATE FUNCTION [DBO].[FNK_DE_VALORES_A_LETRAS]( @NUMERO DECIMAL(18,2))
RETURNS VARCHAR(150)
AS
BEGIN
    DECLARE @IMPLETRA VARCHAR(180)
        DECLARE @LNENTERO BIGINT,
                        @LCRETORNO VARCHAR(512),
                        @LNTERNA INT,
                        @LCMILES VARCHAR(512),
                        @LCCADENA VARCHAR(512),
                        @LNUNIDADES INT,
                        @LNDECENAS INT,
                        @LNCENTENAS INT,
                        @LNFRACCION INT
        SELECT  @LNENTERO = CAST(@NUMERO AS BIGINT),
                        @LNFRACCION = (@NUMERO - @LNENTERO) * 100,
                        @LCRETORNO = '',
                        @LNTERNA = 1
  WHILE @LNENTERO > 0
  BEGIN /* WHILE */
            -- RECORRO TERNA POR TERNA
            SELECT @LCCADENA = ''
            SELECT @LNUNIDADES = @LNENTERO % 10
            SELECT @LNENTERO = CAST(@LNENTERO/10 AS INT)
            SELECT @LNDECENAS = @LNENTERO % 10
            SELECT @LNENTERO = CAST(@LNENTERO/10 AS INT)
            SELECT @LNCENTENAS = @LNENTERO % 10
            SELECT @LNENTERO = CAST(@LNENTERO/10 AS INT)
            -- ANALIZO LAS UNIDADES
            SELECT @LCCADENA =
            CASE /* UNIDADES */
              WHEN @LNUNIDADES = 1 THEN 'UNO ' + @LCCADENA
              WHEN @LNUNIDADES = 2 THEN 'DOS ' + @LCCADENA
              WHEN @LNUNIDADES = 3 THEN 'TRES ' + @LCCADENA
              WHEN @LNUNIDADES = 4 THEN 'CUATRO ' + @LCCADENA
              WHEN @LNUNIDADES = 5 THEN 'CINCO ' + @LCCADENA
              WHEN @LNUNIDADES = 6 THEN 'SEIS ' + @LCCADENA
              WHEN @LNUNIDADES = 7 THEN 'SIETE ' + @LCCADENA
              WHEN @LNUNIDADES = 8 THEN 'OCHO ' + @LCCADENA
              WHEN @LNUNIDADES = 9 THEN 'NUEVE ' + @LCCADENA
              ELSE @LCCADENA
            END /* UNIDADES */
            -- ANALIZO LAS DECENAS
            SELECT @LCCADENA =
            CASE /* DECENAS */
              WHEN @LNDECENAS = 1 THEN
                CASE @LNUNIDADES
                  WHEN 0 THEN 'DIEZ '
                  WHEN 1 THEN 'ONCE '
                  WHEN 2 THEN 'DOCE '
                  WHEN 3 THEN 'TRECE '
                  WHEN 4 THEN 'CATORCE '
                  WHEN 5 THEN 'QUINCE '
                  WHEN 6 THEN 'DIEZ Y SEIS '
                  WHEN 7 THEN 'DIEZ Y SIETE '
                  WHEN 8 THEN 'DIEZ Y OCHO '
                  WHEN 9 THEN 'DIEZ Y NUEVE '
                END
              WHEN @LNDECENAS = 2 THEN
              CASE @LNUNIDADES
                WHEN 0 THEN 'VEINTE '
                ELSE 'VEINTI' + @LCCADENA
              END
              WHEN @LNDECENAS = 3 THEN
              CASE @LNUNIDADES
                WHEN 0 THEN 'TREINTA '
                ELSE 'TREINTA Y ' + @LCCADENA
              END
              WHEN @LNDECENAS = 4 THEN
                CASE @LNUNIDADES
                    WHEN 0 THEN 'CUARENTA'
                    ELSE 'CUARENTA Y ' + @LCCADENA
                END
              WHEN @LNDECENAS = 5 THEN
                CASE @LNUNIDADES
                    WHEN 0 THEN 'CINCUENTA '
                    ELSE 'CINCUENTA Y ' + @LCCADENA
                END
              WHEN @LNDECENAS = 6 THEN
                CASE @LNUNIDADES
                    WHEN 0 THEN 'SESENTA '
                    ELSE 'SESENTA Y ' + @LCCADENA
                END
              WHEN @LNDECENAS = 7 THEN
                 CASE @LNUNIDADES
                    WHEN 0 THEN 'SETENTA '
                    ELSE 'SETENTA Y ' + @LCCADENA
                 END
              WHEN @LNDECENAS = 8 THEN
                CASE @LNUNIDADES
                    WHEN 0 THEN 'OCHENTA '
                    ELSE  'OCHENTA Y ' + @LCCADENA
                END
              WHEN @LNDECENAS = 9 THEN
                CASE @LNUNIDADES
                    WHEN 0 THEN 'NOVENTA '
                    ELSE 'NOVENTA Y ' + @LCCADENA
                END
              ELSE @LCCADENA
            END /* DECENAS */
            -- ANALIZO LAS CENTENAS
            SELECT @LCCADENA =
            CASE /* CENTENAS */
              WHEN @LNCENTENAS = 1 THEN CASE WHEN @LNUNIDADES = 0 AND  @LNDECENAS = 0 THEN 'CIEN ' ELSE  'CIENTO ' END + @LCCADENA
              WHEN @LNCENTENAS = 2 THEN 'DOSCIENTOS ' + @LCCADENA
              WHEN @LNCENTENAS = 3 THEN 'TRESCIENTOS ' + @LCCADENA
              WHEN @LNCENTENAS = 4 THEN 'CUATROCIENTOS ' + @LCCADENA
              WHEN @LNCENTENAS = 5 THEN 'QUINIENTOS ' + @LCCADENA
              WHEN @LNCENTENAS = 6 THEN 'SEISCIENTOS ' + @LCCADENA
              WHEN @LNCENTENAS = 7 THEN 'SETECIENTOS ' + @LCCADENA
              WHEN @LNCENTENAS = 8 THEN 'OCHOCIENTOS ' + @LCCADENA
              WHEN @LNCENTENAS = 9 THEN 'NOVECIENTOS ' + @LCCADENA
              ELSE @LCCADENA
            END /* CENTENAS */
            -- ANALIZO LA TERNA
            SELECT @LCCADENA =
            CASE /* TERNA */
              WHEN @LNTERNA = 1 THEN @LCCADENA
              WHEN @LNTERNA = 2 THEN @LCCADENA + 'MIL '
              WHEN @LNTERNA = 3 THEN @LCCADENA + 'MILLONES '
              WHEN @LNTERNA = 4 THEN @LCCADENA + 'MIL '
              ELSE ''
            END /* TERNA */
            -- ARMO EL RETORNO TERNA A TERNA
            SELECT @LCRETORNO = @LCCADENA  + @LCRETORNO
            SELECT @LNTERNA = @LNTERNA + 1
   END /* WHILE */
   IF @NUMERO=100
		SELECT @LCRETORNO='CIEN'

   IF @LNTERNA = 1
       SELECT @LCRETORNO = 'CERO'
   IF @LNFRACCION>0
   BEGIN
      DECLARE @SFRACCION VARCHAR(15)
      SET @SFRACCION = '00' + LTRIM(CAST(@LNFRACCION AS VARCHAR))
      SELECT @IMPLETRA =RTRIM(@LCRETORNO)+' Y '+ SUBSTRING(@SFRACCION,LEN(@SFRACCION)-1,2) + '/100 '
   END
   ELSE
   BEGIN
      SELECT @IMPLETRA = RTRIM(@LCRETORNO)  --+' Y 00/100 '
   END

   RETURN @IMPLETRA
END


