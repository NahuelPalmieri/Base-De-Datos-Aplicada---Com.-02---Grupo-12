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

--Especifica el entorno de idioma de la sesion a Español.
SET LANGUAGE Spanish;

--=======================================================================================
      -- REPORTE 1: Flujo de caja semanal
	  -- Parametros:
		-- @Anio: parametro opcional de enviar
		-- @MesInicio: parametro opcional de enviar
		-- @MesFin: parametro opcional de enviar
		-- @IDConsorcio: parametro opcional de enviar
--=======================================================================================
EXEC generacionDeReportes.ReporteFlujoDeCajaSemanal 
    @Anio = 2025,        --parametro obligatorio de enviar
    @MesInicio = 3,      --parametro opcional de enviar
    @MesFin = 6;         --parametro opcional de enviar
GO

--=======================================================================================
      -- REPORTE 2: Total de recaudacion por mes y departamento
--=======================================================================================

EXEC generacionDeReportes.Reporte_Total_Recaudacion_Mes_Departamento
	@IDConsorcio = 1,		--parametro opcional de enviar
	@Piso = 'PB',			--parametro opcional de enviar
	@Departamento = 'D',	--parametro opcional de enviar
	@Anio = 2025,			--parametro OBLIGATORIO de enviar
	@Mes = 	5				--parametro opcional de enviar
GO
go
--=======================================================================================
        -- REPORTE 3: Recaudacion total desagregada segun su  procedencia (ordinario, 
        --            extraordinario, etc). segun el periodo.
--=======================================================================================
go

EXEC generacionDeReportes.Reporte_total_recaudacion_tipo_de_gasto 
	@Año = 2025,		--parametro opcional de enviar
	@MesDesde = 1,		--parametro opcional de enviar
	@MesHasta = 12;		--parametro opcional de enviar
GO

--===========================================================================================--
        -- REPORTE 4: Los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos.
		-- Parametros:
			-- Anio: Entro para filtrar gastos e ingresos por anio.
			-- Consorcio: Entero para filtrar gastos e ingresos de determinado consorcio por su ID.
			-- Detalle: Digito entero para filtrar gastos por numero de detalle
--===========================================================================================--


EXEC generacionDeReportes.Reporte_De_Cinco_Meses
	@año = 2025,	--parametro opcional de enviar
	@consorcio = 1, --parametro opcional de enviar
	@detalle = 5	--parametro opcional de enviar
GO

--===========================================================================================
    -- REPORTE 5: Obtenga los 3 (tres) propietarios con mayor morosidad. Presente información de contacto y
	--DNI de los propietarios para que la administración los pueda contactar o remitir el trámite al
	--estudio jurídico.
	--Parametros:
		--TopN: Cantidad de puestos que desea mostrar.
		--IdConsorcio: Filtrar por consorcio, si es NULL, se hace la comparacion entre todos los reportes.
		--MinimoDeuda: Extra, agregar un minimo de deuda para mostrarlo.

	-- SI EN LA TABLA ESTADODECUENTA NO HAY DEUDAS EL REPORTE SE MUESTRA VACIO
--===========================================================================================

EXEC generacionDeReportes.ObtenerTopMorosos
	@TopN = 3,			--parametro opcional de enviar
    @IDConsorcio = 1,	--parametro opcional de enviar
    @MinDeuda = 0	--parametro opcional de enviar
GO

--===========================================================================================
        -- REPORTE 6: Fechas de pagos de expensas ordinarias de cada UF y la cantidad de 
        --            dias que pasan entre un pago y el siguiente, para el conjunto examinado.
		-- Parametros:
			-- IdConsorcio (OBLIGATORIO)
			-- NroUnidadFuncional (OPCIONAL)
			-- AnioDesde (OPCIONAL)
			--Si se ingresa NroUnidad se debe ingresar AnioDede y viceversa. De caso contrario se tomara solo IdConsorcio
--===========================================================================================

EXEC generacionDeReportes.ReporteDiasEntrePagosOrdinarios
    @IdConsorcio = 1,			--parametro OBLIGATORIO de enviar
    @NroUnidadFuncional = 4,	--parametro opcional de enviar
    @AnioDesde = 2025			--parametro opcional de enviar
GO