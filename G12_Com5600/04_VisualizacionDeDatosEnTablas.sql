/********************************************************************************
	Trabajo Practico Integrador - Bases de Datos Aplicadas (2? Cuatrimestre 2025)
	Visualizacion de los datos que tienen las tablas de la base de datos
	mediante el uso de consultas SELECT
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

-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'BAULERA'
SELECT IdBaulera, IDConsorcio, NumeroUnidad, M2Baulera
FROM actualizacionDeDatosUF.Baulera
GO

-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'COCHERA'
SELECT IdCochera, IdConsorcio, NumeroUnidad, M2Cochera
FROM actualizacionDeDatosUF.Cochera
GO

-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'CONSORCIO'
SELECT IDConsorcio, NombreDeConsorcio, Domicilio,
	   CantUnidadesFuncionales, M2Totales 
FROM actualizacionDeDatosUF.Consorcio
GO

-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'GASTO ORDINARIO'
SELECT IDGastoOrdinario, IDConsorcio, Mes, Año, Importe 
FROM actualizacionDeDatosUF.GastoOrdinario
GO

-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'GASTO SERVICIO'
SELECT IDGasto, IDConsorcio, IDProveedor, Importe, Mes, Año 
FROM actualizacionDeDatosUF.GastoServicio
GO

-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'INQUILINO'
SELECT DNI, NroDeConsorcio, NroDeUnidad
FROM actualizacionDeDatosUF.Inquilino
GO

-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'PERSONA'
SELECT DNI, Nombres, Apellidos, Email, NumeroDeTelefono,
	   CVU_CBU, Inquilino AS esInquilino
FROM actualizacionDeDatosUF.Persona
GO

-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'PERSONAS CON ERROR'
SELECT Id, DNI, Nombres, Apellidos, Email, NumeroDeTelefono,
	   CVU_CBU, Inquilino AS esInquilino
FROM actualizacionDeDatosUF.PersonasConError
GO

-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'PROPIETARIO'
SELECT DNI
FROM actualizacionDeDatosUF.Propietario
GO

-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'PROVEEDOR'
SELECT IDProveedor, TipoDeServicio 
FROM actualizacionDeDatosUF.Proveedor
GO

-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'UNIDAD FUNCIONAL'
SELECT IDConsorcio, NumeroDeUnidad, DNIPropietario,
       Piso, Departamento, M2Unidad, CVU_CBU 
FROM actualizacionDeDatosUF.UnidadFuncional
GO

/*-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'CUOTAS GASTO EXTRAORDINARIO'
SELECT  IDGastoExtraordinario, TotalDeCuotas, NumeroDeCuota
FROM actualizacionDeDatosUF.CuotasGastoExtraordinario
GO
*/
-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'ESTADO DE CUENTA'
SELECT IDConsorcio, NumeroDeUnidad, IDEstadoDeCuenta,
	   PorcentajeMetrosCuadrados, PisoDepto, Cocheras,
	   Bauleras, Propietario, SaldoAnteriorAbonado, PagoRecibido,
	   Deuda, InteresPorMora, ExpensaOrdinaria, ExpensaExtraordinaria
FROM importacionDeInformacionBancaria.EstadoDeCuenta
GO

-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'GASTO EXTRAORDINARIO'
SELECT IDGastoExtraordinario, IDConsorcio, Mes, Año, Detalle, Importe
FROM actualizacionDeDatosUF.GastoExtraordinario g
ORDER BY g.IDConsorcio
GO

-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'PAGO A CONSORCIO'
SELECT IDPAGO, IDConsorcio, NumeroDeUnidad, Fecha, CVU_CBU, Importe
FROM importacionDeInformacionBancaria.PagoAConsorcio
GO