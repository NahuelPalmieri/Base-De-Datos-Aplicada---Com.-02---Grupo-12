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

-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'CUOTAS GASTO EXTRAORDINARIO'
SELECT  IDGastoExtraordinario, TotalDeCuotas, NumeroDeCuota
FROM dbo.CuotasGastoExtraordinario
GO

-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'ESTADO DE CUENTA'
SELECT IDConsorcio, NumeroDeUnidad, IDEstadoDeCuenta,
	   PorcentajeMetrosCuadrados, PisoDepto, Cocheras,
	   Bauleras, Propietario, SaldoAnteriorAbonado, PagoRecibido,
	   Deuda, InteresPorMora, ExpensaOrdinaria, ExpensaExtraordinaria
FROM dbo.EstadoDeCuenta
GO

-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'GASTO EXTRAORDINARIO'
SELECT IDGastoExtraordinario, IDConsorcio, Detalle, Importe 
FROM dbo.GastoExtraordinario
GO

-- PARA PODER VER TODA LA INFORMACION QUE CONTIENE LA TABLA 'PAGO A CONSORCIO'
SELECT IDPAGO, IDConsorcio, NumeroDeUnidad, Fecha, CVU_CBU, Importe
FROM dbo.PagoAConsorcio
GO