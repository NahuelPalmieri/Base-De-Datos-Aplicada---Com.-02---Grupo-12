/********************************************************************************
	Trabajo Practico Integrador - Bases de Datos Aplicadas (2º Cuatrimestre 2025)
	Creacion de Indices para los reportes
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

--================================================================
	--INDICES PARA REPORTE 3:
--=================================================================

CREATE NONCLUSTERED INDEX IDX_GastoOrdinario
ON actualizacionDeDatosUF.GastoOrdinario (Año, Mes)
INCLUDE (Importe);


CREATE NONCLUSTERED INDEX IDX_GastoServicio
ON actualizacionDeDatosUF.GastoServicio (Año, Mes)
INCLUDE (Importe);

CREATE NONCLUSTERED INDEX IDX_GastoExtraordinario
ON actualizacionDeDatosUF.GastoExtraordinario (Año, Mes)
INCLUDE (Importe);

--================================================================
	--INDICES PARA REPORTE 4:
--=================================================================
CREATE NONCLUSTERED INDEX IX_GastoExtraordinario_Filtros
ON actualizacionDeDatosUF.GastoExtraordinario (Año, IDConsorcio, Detalle, mes)
INCLUDE (importe);

CREATE NONCLUSTERED INDEX IX_GastoOrdinario_Filtros
ON actualizacionDeDatosUF.GastoOrdinario (Año, IDConsorcio, mes)
INCLUDE (importe);

--================================================================
	--INDICES PARA REPORTE 5:
--================================================================
CREATE NONCLUSTERED INDEX IX_EstadoDeCuenta_Deuda_Includes
ON importacionDeInformacionBancaria.EstadoDeCuenta(Deuda)
INCLUDE (IDConsorcio, NumeroDeUnidad); --

CREATE INDEX IX_UnidadFuncional_DNIPropietario
ON actualizacionDeDatosUF.UnidadFuncional(DNIPropietario);

--================================================================
	--INDICES PARA REPORTE 6 y REPORTE 2:
--================================================================
CREATE NONCLUSTERED INDEX IDX_PagoAConsorcio
ON importacionDeInformacionBancaria.PagoAConsorcio(IdConsorcio, NumeroDeUnidad, Fecha)
INCLUDE (Importe);