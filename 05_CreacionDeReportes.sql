--=========
--Reportes
--=========

USE Com5600G12;
GO

--Generacion aleatoria de datos para la tabla GastosExtraordinarios (PRUEBA)
CREATE OR ALTER PROCEDURE dbo.InsertarDatosAleatoriosGastoExtraordinario
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
        INSERT INTO dbo.GastoExtraordinario (IDConsorcio, Mes, Año, Detalle, Importe)
        VALUES (@IDConsorcio, @Mes, 2025, @Detalle, @Importe);

        -- Incrementa el contador
        SET @i = @i + 1;
    END
END;

--Ejecucion del SP
EXEC dbo.InsertarDatosAleatoriosGastoExtraordinario @Cantidad = 50;

--Verifico que los datos se cargaron en la tabla GastoExtraordinario
SELECT *
FROM dbo.GastoExtraordinario

--==========
--Reporte 3
--==========

WITH CTE_Gastos AS (
    SELECT 'Ordinario' AS [Tipo de gasto], --Como no tengo un campo con los tipos de gasto, creo la columna [Tipo de gasto] y le asigno nombres fijos
           CONVERT(VARCHAR(7), DATEFROMPARTS(Año, Mes, 1), 120) AS Periodo,
           Importe
    FROM actualizacionDeDatosUF.GastoOrdinario

    UNION ALL

    SELECT 'Extraordinario' AS [Tipo de gasto],
           CONVERT(VARCHAR(7), DATEFROMPARTS(Año, Mes, 1), 120) AS Periodo,
           Importe
    FROM dbo.GastoExtraordinario

    UNION ALL --uno los resultados de la consulta en una sola tabla sin repetidos, ya que todas tiene la misma estructura en lo que se pide
			  -- Todas estan de la manera importe, año, mes
    SELECT 'Servicios' AS [Tipo de gasto],
           CONVERT(VARCHAR(7), DATEFROMPARTS(Año, Mes, 1), 120) AS Periodo,
           Importe
    FROM actualizacionDeDatosUF.GastoServicio
)
SELECT [Tipo de gasto], [2025-04], [2025-05], [2025-06]
FROM (
    SELECT [Tipo de gasto], Periodo, Importe
    FROM CTE_Gastos
) AS Fuente
PIVOT (
    SUM(Importe) FOR Periodo IN ([2025-04], [2025-05], [2025-06])
) AS CuadroCruzado;



