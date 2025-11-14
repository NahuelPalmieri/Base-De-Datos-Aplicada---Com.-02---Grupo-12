/********************************************************************************
	Trabajo Practico Integrador - Bases de Datos Aplicadas (2Âº Cuatrimestre 2025)
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

--=======================================================================================
                      -- REPORTE 1: Flujo de caja semanal
--=======================================================================================

CREATE OR ALTER PROCEDURE generacionDeReportes.ReporteFlujoDeCajaSemanal
    @Anio INT,                   --parametro obligatorio de enviar
    @MesInicio INT = NULL,       --parametro opcional de enviar
    @MesFin INT = NULL,          --parametro opcional de enviar
    @IDConsorcio INT = NULL      --parametro opcional de enviar
AS
BEGIN
    SET DATEFIRST 1; -- Seteo al lunes como primer día de la semana

    DECLARE @FechaInicio DATE;
    DECLARE @FechaFin DATE;

    -- Si no se especifican meses de inicio y fin, se toma todo el año
    IF @MesInicio IS NULL OR @MesFin IS NULL
    BEGIN
        SET @FechaInicio = DATEFROMPARTS(@Anio, 1, 1);
        SET @FechaFin = DATEFROMPARTS(@Anio + 1, 1, 1);
    END
    ELSE
    BEGIN
        SET @FechaInicio = DATEFROMPARTS(@Anio, @MesInicio, 1);
        SET @FechaFin = DATEADD(MONTH, 1, DATEFROMPARTS(@Anio, @MesFin, 1));
    END

    -- Tabla temporal con pagos semanales
    SELECT 
        DATEPART(WEEK, Fecha) AS Semana,
        DATEADD(DAY, 1 - DATEPART(WEEKDAY, Fecha), CAST(Fecha AS DATE)) AS InicioSemana,
        DATEADD(DAY, 7 - DATEPART(WEEKDAY, Fecha), CAST(Fecha AS DATE)) AS FinSemana,
        SUM(CASE WHEN Ordinario = 1 THEN Importe ELSE 0 END) AS TotalOrdinario,
        SUM(CASE WHEN Ordinario = 0 THEN Importe ELSE 0 END) AS TotalExtraordinario,
        SUM(Importe) AS TotalSemanal
    INTO #FlujoSemanal
    FROM importacionDeInformacionBancaria.PagoAConsorcio
    WHERE Fecha >= @FechaInicio AND Fecha < @FechaFin
      AND (@IDConsorcio IS NULL OR IDConsorcio = @IDConsorcio)
    GROUP BY DATEPART(WEEK, Fecha), DATEADD(DAY, 1 - DATEPART(WEEKDAY, Fecha), CAST(Fecha AS DATE)), DATEADD(DAY, 7 - DATEPART(WEEKDAY, Fecha), CAST(Fecha AS DATE));

    -- Muestro la tabla temporal, agregando el acumulado progresivo y el promedio semanal
    SELECT 
        Semana,
        InicioSemana,
        FinSemana,
        TotalOrdinario,
        TotalExtraordinario,
        TotalSemanal,
        SUM(TotalSemanal) OVER (ORDER BY InicioSemana ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS AcumuladoProgresivo,
        AVG(TotalSemanal) OVER () AS PromedioSemanal
    FROM #FlujoSemanal
    ORDER BY InicioSemana;

    DROP TABLE #FlujoSemanal;
END;
GO

EXEC generacionDeReportes.ReporteFlujoDeCajaSemanal 
    @Anio = 2025,        --parametro obligatorio de enviar
    @MesInicio = 3,      --parametro opcional de enviar
    @MesFin = 6;         --parametro opcional de enviar
GO

--=======================================================================================
      -- REPORTE 2: Total de recaudacion por mes y departamento
--=======================================================================================
GO
CREATE OR ALTER PROCEDURE generacionDeReportes.Reporte_Total_Recaudacion_Mes_Departamento
		@IDConsorcio INT = NULL,
		@Piso CHAR(2) = NULL,
		@Departamento CHAR(1) = NULL,
		@Anio INT,
		@Mes INT = NULL
AS
BEGIN
		----------------------1.CREACION DE FECHAS------------------------
		DECLARE @FechaInicial DATE;
		DECLARE @FechaFinal DATE;

		IF @Mes IS NULL
		BEGIN
			  SET @FechaInicial = DATEFROMPARTS(@Anio,1,1); --2025/01/01
			  SET @FechaFinal = DATEFROMPARTS(@Anio + 1,1,1); --2026/01/01
		END
		ELSE
		BEGIN
			  SET @FechaInicial = DATEFROMPARTS(@Anio,@Mes,1); --2025/mes/01
			  SET @FechaFinal = DATEFROMPARTS(@Anio,@Mes + 1,1); --2025/mes+1/01
			  END
		------------------------------------------------------------------------

		-----------------2.GENERACION DE LA TABLA TEMPORAL BASE-----------------
		SELECT
			  C.NombreDeConsorcio AS Consorcio,
			  UF.Piso,
			  UF.Departamento,
			  MONTH(P.Fecha) AS Mes,
			  SUM(P.Importe) AS TotalRecaudado
		INTO #Recaudacion
		FROM importacionDeInformacionBancaria.PagoAConsorcio AS P
		INNER JOIN actualizacionDeDatosUF.UnidadFuncional AS UF
			  ON P.IDConsorcio = UF.IDConsorcio
			  AND P.NumeroDeUnidad = UF.NumeroDeUnidad
		INNER JOIN actualizacionDeDatosUF.Consorcio AS C
			  ON C.IDConsorcio = UF.IDConsorcio 
		WHERE
			 (P.Fecha >= @FechaInicial AND P.Fecha < @FechaFinal) 
			 AND (@IDConsorcio IS NULL OR C.IDConsorcio= @IDConsorcio)
			 AND (@Departamento IS NULL OR UF.Departamento = @Departamento)
			 AND (@Piso IS NULL OR UF.Piso = @Piso) ----------------------------
		GROUP BY
			 C.NombreDeConsorcio,UF.Piso,UF.Departamento,MONTH(P.Fecha);
		-------------------------------------------------------------------------

		-----------------------------3.PIVOT-------------------------------------

		IF @Mes IS NULL    ---Si no ingreso un mes especifico muestro todos los meses
		BEGIN
			SELECT 
				  Consorcio,
				  Piso,
				  Departamento,
				  ISNULL([1],0)	 AS Enero,
				  ISNULL([2],0)	 AS Febrero,
				  ISNULL([3],0)	 AS Marzo,
				  ISNULL([4],0)	 AS Abril,
				  ISNULL([5],0)	 AS Mayo,
				  ISNULL([6],0)	 AS Junio,
				  ISNULL([7],0)	 AS Julio,
				  ISNULL([8],0)	 AS Agosto,
				  ISNULL([9],0)	 AS Septiembre,
				  ISNULL([10],0) AS Octubre,
				  ISNULL([11],0) AS Noviembre,
				  ISNULL([12],0) AS Diciembre
			FROM #Recaudacion
			PIVOT (
				SUM(TotalRecaudado)
				FOR Mes in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
			  ) AS PivotTable
				ORDER BY Consorcio, Piso
		END
		ELSE
		BEGIN
			SELECT
				Consorcio,
				Piso,
				Departamento, 
				SUM(ISNULL(TotalRecaudado,0)) AS MesIngresado
			FROM #Recaudacion
			GROUP BY Consorcio,Piso,Departamento
			ORDER BY Consorcio, Piso
		END  
		DROP TABLE #Recaudacion;
END;


--=======================================================================================
        -- REPORTE 3: Recaudacion total desagregada segun su  procedencia (ordinario, 
        --            extraordinario, etc). segun el periodo.
--=======================================================================================

CREATE OR ALTER PROCEDURE generacionDeReportes.Reporte_total_recaudacion_tipo_de_gasto AS
BEGIN

	DECLARE @ColumnasPivot NVARCHAR(MAX); --Guarda los meses en la forma yyyy-mm
	DECLARE @CadenaSQL NVARCHAR(MAX);

	--Armo la lista de columnas
	SELECT @ColumnasPivot = STRING_AGG(QUOTENAME(CONVERT(VARCHAR(7), DATEFROMPARTS(Año,Mes,1), 120)), ',')--Para que tenga la forma yyyy-mm
	FROM(SELECT DISTINCT Año, Mes
		 FROM actualizacionDeDatosUF.GastoOrdinario
		 UNION
		 SELECT DISTINCT Año, Mes  --Obtengo todos los Meses y Años distintos de las tablas
		 FROM actualizacionDeDatosUF.GastoExtraordinario 
		 UNION
		 SELECT DISTINCT Año, Mes
		 FROM actualizacionDeDatosUF.GastoServicio ) AS Periodos;

	SET @CadenaSQL = '
	WITH CTE_Gastos AS (
		SELECT ''Ordinario'' AS [Tipo de gasto],
			   CONVERT(VARCHAR(7), DATEFROMPARTS(Año, Mes, 1), 120) AS Periodo,  --Convierte Año y Mes en un formato yyyy-mm
			   SUM(Importe) AS Importe
		FROM (SELECT DISTINCT Año, Mes, Importe
			  FROM actualizacionDeDatosUF.GastoOrdinario) AS tOrdinario
		GROUP BY Año, Mes

		UNION ALL

		SELECT ''Extraordinario'' AS [Tipo de gasto],
			   CONVERT(VARCHAR(7), DATEFROMPARTS(Año, Mes, 1), 120) AS Periodo,
			   SUM(Importe) AS Importe
		FROM (SELECT DISTINCT Año, Mes, Importe   --Evita que se repitan la combinacion de Año,Mes,Importe y asi evitar duplicados antes de agrupar
			  FROM actualizacionDeDatosUF.GastoExtraordinario) AS tExtraordinario
		GROUP BY Año, Mes

		UNION ALL

		SELECT ''Servicios'' AS [Tipo de gasto],
			   CONVERT(VARCHAR(7), DATEFROMPARTS(Año, Mes, 1), 120) AS Periodo,
			   SUM(Importe) AS Importe
		FROM (SELECT DISTINCT Año, Mes, Importe
			  FROM actualizacionDeDatosUF.GastoServicio) AS tServicios
		GROUP BY Año, Mes
	)
	SELECT [Tipo de gasto], ' + @ColumnasPivot + '
	FROM (SELECT [Tipo de gasto], Periodo, Importe
		  FROM CTE_Gastos) AS tfuente
	PIVOT (SUM(Importe) FOR Periodo IN (' + @ColumnasPivot + ')) AS CuadroCruzado;';

	EXEC sp_executesql @CadenaSQL;
END;

EXEC generacionDeReportes.Reporte_total_recaudacion_tipo_de_gasto;

--===========================================================================================--
        -- REPORTE 4: Los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos. 
--===========================================================================================--
CREATE OR ALTER PROCEDURE generacionDeReportes.Reporte_De_Cinco_Meses
	@año INT = NULL, --Para filtrar gastos e ingresos por año
	@consorcio INT = NULL, --Para filtrar gastos e ingresos de determinado consorcio por su ID.
	@detalle CHAR(1) = NULL --Para filtrar gastos por numero de detalle
AS
BEGIN
	DECLARE @strDetalle VARCHAR(10) = NULL;
	IF @detalle IS NOT NULL
		SET @strDetalle = CONCAT('Detalle ', @detalle);

	SELECT TOP 5 
		IDConsorcio,
		Año,
		DATENAME(MONTH, DATEFROMPARTS(Año, mes, 1)) AS nombre_mes,
		sum(importe) as total_gastos
	FROM actualizacionDeDatosUF.GastoExtraordinario
	WHERE (@año IS NULL OR Año = @año)
		AND (@consorcio IS NULL OR IDConsorcio = @consorcio) 
		AND (@strDetalle IS NULL OR Detalle = @strDetalle)
	GROUP BY IDConsorcio, año, mes
	ORDER BY total_gastos DESC;

	SELECT TOP 5 
		IDConsorcio,
		YEAR(Fecha) AS año,
		DATENAME(MONTH, Fecha) AS mes,
		sum(importe) as total_ingresos
	FROM importacionDeInformacionBancaria.PagoAConsorcio
		WHERE (@año IS NULL OR YEAR(Fecha) = @año) 
		AND (@consorcio IS NULL OR @consorcio = IDConsorcio)
	GROUP BY IDConsorcio, YEAR(Fecha), DATENAME(MONTH, Fecha), MONTH(Fecha);
END;



--===========================================================================================
        -- REPORTE 6: Fechas de pagos de expensas ordinarias de cada UF y la cantidad de 
        --            dias que pasan entre un pago y el siguiente, para el conjunto examinado.
--===========================================================================================

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
		and pac.Ordinario = 1
    end
    else
    begin
        select pac.IDConsorcio, pac.NumeroDeUnidad, pac.Fecha, pac.Importe, pac.importe/(select importe from openjson(@datos)with([Importe] decimal(10,2) '$.venta')) as ImporteUSD,
        datediff(day, pac.fecha,lag(pac.Fecha, 1, NULL) over(partition by pac.IdConsorcio, pac.NumeroDeUnidad order by pac.Fecha desc)) as DiferenciaDias 
        from importacionDeInformacionBancaria.PagoAConsorcio pac
		where pac.Ordinario = 1
    end
    
end

exec generacionDeReportes.ReporteDiasEntrePagosOrdinarios


