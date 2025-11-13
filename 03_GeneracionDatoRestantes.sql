/********************************************************************************
	Trabajo Practico Integrador - Bases de Datos Aplicadas (2º Cuatrimestre 2025)
	Generacion de Reportes
	Comision: 5600
	Grupo: 12
	Integrantes:
		- Nahuel Palmieri		(DNI: 45074926)
		- Ivan Morales			(DNI: 39772619)
		- Tobias Argain			(DNI: 42998669)
		- Tomas Daniel Yagueddu (DNI: 44100611)
		- Fernando Pereyra		(DNI: 45738989)
		- Gian Luca Di Salvio   (DNI: 45236135)

*********************************************************************************/

--Para asegurarnos que se ejecute usando la BDD
use Com5600G12
GO

--Generacion aleatoria de datos para la tabla GastosExtraordinarios (PRUEBA)
CREATE OR ALTER PROCEDURE actualizacionDeDatosUF.InsertarDatosAleatoriosGastoExtraordinario
    @Cantidad INT --Cantidad a insertar
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

         -- Importe aleatorio con decimales
        SET @Importe = ROUND(15000 + (RAND(CHECKSUM(NEWID())) * 85000), 2);

        -- Inserta el registro en la tabla GastoExtraordinario con año 2025 (el año lo puse fijo para que sea igual al de los archivos de importacion)
        INSERT INTO actualizacionDeDatosUF.GastoExtraordinario (IDConsorcio, Mes, Año, Detalle, Importe)
        VALUES (@IDConsorcio, @Mes, 2025, @Detalle, @Importe);

        -- Incrementa el contador
        SET @i = @i + 1;
    END
END;


EXEC actualizacionDeDatosUF.InsertarDatosAleatoriosGastoExtraordinario @Cantidad = 50;