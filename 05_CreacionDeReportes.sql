--=========
--Reportes
--=========

--Para asegurarnos que se ejecute usando la BDD
use Com5600G12
GO

--Generacion aleatoria de datos para la tabla GastosExtraordinarios (PRUEBA)
CREATE OR ALTER PROCEDURE actualizacionDeDatosUF.InsertarDatosAleatoriosGastoExtraordinario
    @Cantidad INT -- parametro para indicar la cantidad a insertar
AS
BEGIN

    SET NOCOUNT ON;
	
    DECLARE @i INT = 0; -- contador de registros insertados
    DECLARE @TotalConsorcios INT; -- cantidad total de consorcios disponibles (lo de la tabla Consorcio)
    DECLARE @IDConsorcio INT; -- ID de consorcio elegido aleatoriamente (de los que hay en la tabla)
    DECLARE @NDetalle INT; -- Se usa para seleccionar un detalle de manera aleatoria (segun numero)
    DECLARE @Detalle VARCHAR(80); -- descripción del gasto extraordinario
    DECLARE @Mes INT; -- para obtener mes aleatorio entre 1 y 12
    DECLARE @Importe DECIMAL(10,2); -- Para obtener importe aleatorio entre 15.000 y 100.000

    -- Verifica si hay consorcios cargados en la tabla Consorcio
    SELECT @TotalConsorcios = COUNT(*) FROM actualizacionDeDatosUF.Consorcio;

    IF @TotalConsorcios = 0
    BEGIN
        --Si no hay consorcios no inserta datos y sale
        RAISERROR('No hay consorcios cargados. No se puede insertar en GastoExtraordinario.', 16, 1);
        RETURN;
    END

    -- Bucle para insertar la cantidad solicitada de registros
    WHILE @i < @Cantidad
    BEGIN
        -- Selecciona aleatoriamente un consorcio válido
        SELECT TOP 1 @IDConsorcio = IDConsorcio
        FROM actualizacionDeDatosUF.Consorcio
        ORDER BY NEWID();

        -- Guarda un numero entre 0 y 5 para seleccionar un detalle
        SET @NDetalle = ABS(CHECKSUM(NEWID())) % 6;

        SET @Detalle = CASE @NDetalle
            WHEN 0 THEN 'Detalle 1'
            WHEN 1 THEN 'Detalle 2'
            WHEN 2 THEN 'Detalle 3'
            WHEN 3 THEN 'Detalle 4'
            WHEN 4 THEN 'Detalle 5'
            WHEN 5 THEN 'Detalle 6'
        END;

        -- Genera mes aleatorio entre 1 y 12
        SET @Mes = 1 + ABS(CHECKSUM(NEWID())) % 12;

        -- Genera importe aleatorio entre 15.000 y 100.000
        SET @Importe = CAST(15000 + ABS(CHECKSUM(NEWID())) % 85001 AS DECIMAL(10,2));

        -- Inserta el registro en la tabla GastoExtraordinario con año 2025 (el año lo puse fijo para que sea igual al de los archivos de importacion)
        INSERT INTO actualizacionDeDatosUF.GastoExtraordinario (IDConsorcio, Mes, Año, Detalle, Importe)
        VALUES (@IDConsorcio, @Mes, 2025, @Detalle, @Importe);

        -- Incrementa el contador
        SET @i = @i + 1;
    END
END;

--Ejecucion del SP
EXEC actualizacionDeDatosUF.InsertarDatosAleatoriosGastoExtraordinario @Cantidad = 50;

--Verifico que los datos se cargaron en la tabla GastoExtraordinario
SELECT *
FROM actualizacionDeDatosUF.GastoExtraordinario

--delete from actualizacionDeDatosUF.GastoExtraordinario
--==========
--Reporte 3
--==========
;--PASAR REPORTE A SP DENTRO DE SCHEMA 'generacionDeReportes'
WITH CTE_Gastos AS (
    SELECT 'Ordinario' AS [Tipo de gasto], --Como no tengo un campo con los tipos de gasto, creo la columna [Tipo de gasto] y le asigno nombres fijos
           CONVERT(VARCHAR(7), DATEFROMPARTS(Año, Mes, 1), 120) AS Periodo,
           Importe
    FROM actualizacionDeDatosUF.GastoOrdinario

    UNION ALL

    SELECT 'Extraordinario' AS [Tipo de gasto],
           CONVERT(VARCHAR(7), DATEFROMPARTS(Año, Mes, 1), 120) AS Periodo,
           Importe
    FROM actualizacionDeDatosUF.GastoExtraordinario

    UNION ALL --uno los resultados de la consulta en una sola tabla sin repetidos, ya que todas tiene la misma estructura en lo que se pide
			  -- Todas estan de la manera importe, año, mes
    SELECT 'Servicios' AS [Tipo de gasto],
           CONVERT(VARCHAR(7), DATEFROMPARTS(Año, Mes, 1), 120) AS Periodo,
           Importe
    FROM actualizacionDeDatosUF.GastoServicio
)
SELECT [Tipo de gasto], [2025-04], [2025-05], [2025-06] ---Si se agregan nuevos meses?? SQL dinamico?
FROM (
    SELECT [Tipo de gasto], Periodo, Importe
    FROM CTE_Gastos
) AS Fuente
PIVOT (
    SUM(Importe) FOR Periodo IN ([2025-04], [2025-05], [2025-06])
) AS CuadroCruzado;


--==========
--Reporte 6
--==========

GO
EXEC sp_configure 'Ole Automation Procedures', 1;	-- Habilitamos esta opcion para poder interactuar con los objetos COM (para consumir la API)
RECONFIGURE;
GO

create or alter procedure generacionDeReportes.ReporteDiasEntrePagosOrdinarios
    @IdConsorcio int = NULL
as
begin
    
    declare @url nvarchar(45) = 'https://dolarapi.com/v1/dolares/oficial'

    DECLARE @Object INT
    DECLARE @json TABLE(respuesta NVARCHAR(MAX))	-- Uso una tabla variable
    DECLARE @respuesta NVARCHAR(MAX)

    EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT	-- Creo una instancia del objeto OLE, que nos permite hacer los llamados.
    EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE' -- Definino algunas propiedades del objeto para hacer una llamada HTTP Get.
    EXEC sp_OAMethod @Object, 'SEND' 
    EXEC sp_OAMethod @Object, 'RESPONSETEXT', @respuesta OUTPUT --, @json OUTPUT -- Decimos donde guardar la respuesta.

    INSERT @json 
	    EXEC sp_OAGetProperty @Object, 'RESPONSETEXT' -- Obtenemos el valor de la propiedad 'RESPONSETEXT' del objeto OLE desp de realizar la consulta.

    DECLARE @datos NVARCHAR(MAX) = (SELECT respuesta FROM @json)

    if @IdConsorcio is not null
    begin
        select pac.IDConsorcio, pac.NumeroDeUnidad, pac.Fecha, pac.Importe, pac.importe/(select importe from openjson(@datos)with([Importe] decimal(10,2) '$.venta')) as ImporteUSD,
        datediff(day, pac.fecha,lag(pac.Fecha, 1, NULL) over(partition by pac.IdConsorcio, pac.NumeroDeUnidad order by pac.Fecha desc)) as DiferenciaDias 
        from importacionDeInformacionBancaria.PagoAConsorcio pac
        where pac.IDConsorcio = @IdConsorcio
    end
    else
    begin
        select pac.IDConsorcio, pac.NumeroDeUnidad, pac.Fecha, pac.Importe, pac.importe/(select importe from openjson(@datos)with([Importe] decimal(10,2) '$.venta')) as ImporteUSD,
        datediff(day, pac.fecha,lag(pac.Fecha, 1, NULL) over(partition by pac.IdConsorcio, pac.NumeroDeUnidad order by pac.Fecha desc)) as DiferenciaDias 
        from importacionDeInformacionBancaria.PagoAConsorcio pac
    end
    
end

exec generacionDeReportes.ReporteDiasEntrePagosOrdinarios
