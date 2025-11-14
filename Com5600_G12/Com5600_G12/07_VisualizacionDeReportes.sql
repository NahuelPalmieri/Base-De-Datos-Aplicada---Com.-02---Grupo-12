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
Go

--Especifica el entorno de idioma de la sesi?n a Espa?ol.
SET LANGUAGE Spanish;

--=======================================================================================
      -- REPORTE 2: Total de recaudacion por mes y departamento
	  -- Parametros:
		-- IDConsorcio:
		-- Piso:
		-- Departamento:
		-- Anio:
		-- Mes:
--=======================================================================================

EXEC generacionDeReportes.Reporte_Total_Recaudacion_Mes_Departamento

--=======================================================================================
        -- REPORTE 3: Recaudacion total desagregada segun su  procedencia (ordinario, 
        --            extraordinario, etc). segun el periodo.
--=======================================================================================

EXEC generacionDeReportes.Reporte_total_recaudacion_tipo_de_gasto @Año = 2025, @MesDesde = 1, @MesHasta = 12;

--===========================================================================================--
        -- REPORTE 4: Los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos.
		-- Parametros:
			-- A?o: Entro para filtrar gastos e ingresos por a?o.
			-- Consorcio: Entero para filtrar gastos e ingresos de determinado consorcio por su ID.
			-- Detalle: Digito entero para filtrar gastos por numero de detalle
--===========================================================================================--

EXEC generacionDeReportes.Reporte_De_Cinco_Meses 2025, 1, 2

--===========================================================================================
    -- REPORTE 5: Obtenga los 3 (tres) propietarios con mayor morosidad. Presente información de contacto y
	--DNI de los propietarios para que la administración los pueda contactar o remitir el trámite al
	--estudio jurídico.
	--Parametros:
		--TopN: Cantidad de puestos que desea mostrar.
		--IdConsorcio: Filtrar por consorcio, si es NULL, se hace la comparacion entre todos los reportes.
		--MinimoDeuda: Extra, agregar un minimo de deuda para mostrarlo.
--===========================================================================================

EXEC generacionDeReportes.ObtenerTopMorosos

--===========================================================================================
        -- REPORTE 6: Fechas de pagos de expensas ordinarias de cada UF y la cantidad de 
        --            dias que pasan entre un pago y el siguiente, para el conjunto examinado.
		-- Parametros:
			-- IdConsorcio (OBLIGATORIO)
			-- NroUnidadFuncional (OPCIONAL)
			-- AnioDesde (OPCIONAL)
			--Si se ingresa NroUnidad se debe ingresar AnioDede y viceversa. De caso contrario se tomara solo IdConsorcio
--===========================================================================================

EXEC generacionDeReportes.ReporteDiasEntrePagosOrdinarios, 1