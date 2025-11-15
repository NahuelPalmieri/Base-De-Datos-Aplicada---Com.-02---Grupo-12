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
    DECLARE @Detalle VARCHAR(80); -- descripci?n del gasto extraordinario
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
        -- Selecciona aleatoriamente un consorcio v?lido
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

        -- Inserta el registro en la tabla GastoExtraordinario con año 2025 (el a?o lo puse fijo para que sea igual al de los archivos de importacion)
        INSERT INTO actualizacionDeDatosUF.GastoExtraordinario (IDConsorcio, Mes, Año, Detalle, Importe)
        VALUES (@IDConsorcio, @Mes, 2025, @Detalle, @Importe);

        -- Incrementa el contador
        SET @i = @i + 1;
    END
END;
GO

EXEC actualizacionDeDatosUF.InsertarDatosAleatoriosGastoExtraordinario @Cantidad = 50;
GO

--=======================================================================================
                      -- INSERTAR DATOS: Estado De Cuenta
--=======================================================================================

-- Declaracion De Vistas Y Stored Procedures Para InsertarEstadoDeCuentaInicial + Ejecucion:

CREATE OR ALTER VIEW importacionDeInformacionBancaria.VistaEstadoDeCuenta
AS
    SELECT DISTINCT c.IdConsorcio, uf.NumeroDeUnidad, b.M2Baulera, ch.M2Cochera, uf.M2Unidad, c.M2Totales,
                    uf.Piso, uf.Departamento, uf.DNIPropietario
    FROM actualizacionDeDatosUF.UnidadFuncional uf
    JOIN actualizacionDeDatosUF.Consorcio c ON uf.IDConsorcio = c.IDConsorcio
    LEFT JOIN actualizacionDeDatosUF.Baulera b ON b.IDConsorcio = c.IDConsorcio AND b.NumeroUnidad = uf.NumeroDeUnidad
    LEFT JOIN actualizacionDeDatosUF.Cochera ch ON ch.IDConsorcio = c.IDConsorcio AND ch.NumeroUnidad = uf.NumeroDeUnidad
GO

CREATE OR ALTER PROCEDURE importacionDeInformacionBancaria.InsertarEstadoDeCuentaInicial
AS
BEGIN
    INSERT INTO importacionDeInformacionBancaria.EstadoDeCuenta (IDConsorcio,
                NumeroDeUnidad, PorcentajeMetrosCuadrados, PisoDepto, Propietario,
                SaldoAnteriorAbonado, PagoRecibido, Deuda, InteresPorMora,
                ExpensaExtraordinaria, ExpensaOrdinaria, Cocheras, Bauleras)
    SELECT v.IdConsorcio, v.NumeroDeUnidad, 
           (cast( (ISNULL(v.M2Baulera,0) + ISNULL(v.M2Cochera,0) + v.M2Unidad) as decimal(4,2) ) / v.M2Totales * 100) as porcentaje,
            v.piso + '-' + v.Departamento, v.DNIPropietario, 0, 0, 0, 0, 0, 0, 0, 0
    FROM importacionDeInformacionBancaria.VistaEstadoDeCuenta v
    WHERE NOT EXISTS (
        SELECT 1
        FROM importacionDeInformacionBancaria.EstadoDeCuenta ec
        WHERE ec.IDConsorcio = v.IDConsorcio AND ec.NumeroDeUnidad = v.NumeroDeUnidad
    )
END
GO

EXEC importacionDeInformacionBancaria.InsertarEstadoDeCuentaInicial
GO

-- Declaracion De Vistas Y Stored Procedures Para InsertarEstadoDeCuentaFrecuente + Ejecucion:

CREATE OR ALTER VIEW importacionDeInformacionBancaria.VistaEstadoDeCuenta
AS
    SELECT DISTINCT uf.IDConsorcio, uf.NumeroDeUnidad, ISNULL(b.M2Baulera, 0) AS M2Baulera, ISNULL(c.M2Cochera, 0) AS M2Cochera,
    ISNULL(sum(gextord.Importe) over(partition by gextord.IDConsorcio), 0) as ImporteGExtOrdinario,
    sum(gord.Importe) over(partition by gord.IDConsorcio) as ImporteGOrdinario, cons.M2Totales
    FROM actualizacionDeDatosUF.UnidadFuncional uf
    JOIN actualizacionDeDatosUF.Consorcio cons ON uf.IDConsorcio = cons.IDConsorcio
    LEFT JOIN actualizacionDeDatosUF.GastoOrdinario gord ON uf.IDConsorcio = gord.IDConsorcio
    FULL JOIN actualizacionDeDatosUF.GastoExtraordinario gextord ON uf.IDConsorcio = gextord.IDConsorcio AND gextord.Mes = 4
    LEFT JOIN actualizacionDeDatosUF.Baulera b ON b.IDConsorcio = uf.IDConsorcio AND b.NumeroUnidad = uf.NumeroDeUnidad
    LEFT JOIN actualizacionDeDatosUF.Cochera c ON c.IDConsorcio = uf.IDConsorcio AND c.NumeroUnidad = uf.NumeroDeUnidad
    WHERE gord.Mes = 4 -- LO HARDCODEAMOS PARA PODER HACER USO DE LOS DATOS DE MUESTRA QUE NOSOTROS CARGAMOS
                       -- PERO EN REALIDAD DEBERIA IR "WHERE gord.Mes = MONTH(GETDATE())"
GO

CREATE OR ALTER VIEW importacionDeInformacionBancaria.VistaPagosRecibidos
AS
    SELECT uf.IDConsorcio, uf.NumeroDeUnidad, YEAR(pg.Fecha) AS Anio, MONTH(pg.Fecha) AS Mes, ISNULL(SUM(pg.Importe), 0) AS Total
    FROM actualizacionDeDatosUF.UnidadFuncional uf
    LEFT JOIN importacionDeInformacionBancaria.PagoAConsorcio pg ON  uf.IDConsorcio = pg.IDConsorcio
    AND uf.NumeroDeUnidad = pg.NumeroDeUnidad
    AND MONTH(Fecha) = 4 -- LO HARDCODEAMOS PARA PODER HACER USO DE LOS DATOS DE MUESTRA QUE NOSOTROS CARGAMOS
                         -- PERO EN REALIDAD DEBERIA IR "WHERE gord.Mes = MONTH(GETDATE())"
    GROUP BY uf.IDConsorcio, uf.NumeroDeUnidad, YEAR(pg.Fecha), MONTH(pg.Fecha)
GO

CREATE OR ALTER PROCEDURE importacionDeInformacionBancaria.InsertarEstadoDeCuentaFrecuente
    @DiaActual TINYINT = null, 
    @PrimerVencimiento TINYINT = 10,
    @SegundoVencimiento TINYINT = 15
AS
BEGIN
    
    IF(@DiaActual IS NULL)
        SET @DiaActual = Day(getDate());

    DECLARE @interes decimal(3,2) = 0;

    IF(@DiaActual = 1)
    BEGIN
         UPDATE importacionDeInformacionBancaria.EstadoDeCuenta
         SET SaldoAnteriorAbonado = (InteresPorMora + ExpensaOrdinaria + ExpensaExtraordinaria + Bauleras + Cocheras),
             InteresPorMora = 0;
    END

    IF(@DiaActual = 28) -- ULTIMO DEL MES    DAY(GETDATE()) = 28
    BEGIN
        UPDATE estCuenta
        SET Cocheras = ((cast(vist.M2Cochera as decimal(10,2)))/(vist.M2Totales)*vist.ImporteGOrdinario),
            Bauleras = ((cast(vist.M2Baulera as decimal(10,2)))/(vist.M2Totales)*vist.ImporteGOrdinario),
            ExpensaOrdinaria = ((cast(vist.ImporteGOrdinario as decimal(10,2)))*estCuenta.PorcentajeMetrosCuadrados/100),
            ExpensaExtraordinaria = ((cast(vist.ImporteGExtOrdinario as decimal(10,2))*estCuenta.PorcentajeMetrosCuadrados)/(vist.M2Totales)) 
        FROM importacionDeInformacionBancaria.EstadoDeCuenta estCuenta
        JOIN importacionDeInformacionBancaria.VistaEstadoDeCuenta vist
        ON estCuenta.IDConsorcio = vist.IDConsorcio AND estCuenta.NumeroDeUnidad = vist.NumeroDeUnidad

        UPDATE importacionDeInformacionBancaria.EstadoDeCuenta
        SET Deuda = Deuda + (SaldoAnteriorAbonado - PagoRecibido)
    END
    

    UPDATE estCuenta
    SET estCuenta.PagoRecibido = vist.Total
    FROM importacionDeInformacionBancaria.EstadoDeCuenta estCuenta
    JOIN importacionDeInformacionBancaria.VistaPagosRecibidos vist
    ON estCuenta.IDConsorcio = vist.IDConsorcio AND estCuenta.NumeroDeUnidad = vist.NumeroDeUnidad

    IF(@DiaActual > @PrimerVencimiento AND @DiaActual <= @SegundoVencimiento)
        set @interes = 0.02; -- CALCULAMOS CON EL 2%
    ELSE IF(@DiaActual > @SegundoVencimiento)
        set @interes = 0.05; -- CALCULAMOS CON EL 5%

    update estCuenta
    set estCuenta.InteresPorMora = @interes * estCuenta.SaldoAnteriorAbonado
    from importacionDeInformacionBancaria.EstadoDeCuenta estCuenta
    where estCuenta.PagoRecibido = 0
END
GO

EXEC importacionDeInformacionBancaria.InsertarEstadoDeCuentaFrecuente
        @DiaActual = 28;
GO