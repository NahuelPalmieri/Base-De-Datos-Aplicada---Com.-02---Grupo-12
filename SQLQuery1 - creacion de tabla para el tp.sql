CREATE DATABASE AltosDeSaintJust

USE AltosDeSaintJust

CREATE TABLE dbo.Persona
(
	DNI int primary key CHECK(DNI > 9999999 AND DNI < 100000000),
	Nombres varchar(30),
	Apellidos varchar(30),
	Email varchar(50),
	NumeroDeTelefono varchar(15),
	CVU_CBU char(22)
)

CREATE TABLE dbo.Propietario
(
	IDPropietario int identity(1,1) primary key,
	DNI int UNIQUE,

	CONSTRAINT FK_DNI (DNI) REFERENCES dbo.Persona (DNI)
)

CREATE TABLE dbo.Inquilino
(
	IDInquilino int identity(1,1) primary key,
	NroDeConsorcio int,
	NroDeUnidad int,
	DNI int,

	CONSTRAINT FK_Persona (DNI) REFERENCES dbo.Persona (DNI),
	CONSTRAINT FK_UnidadFuncional (NroDeConsorcio, NroDeUnidad) REFERENCES dbo.UnidadFuncional (IDConsorcio, NumeroDeUnidad)
)

CREATE TABLE dbo.UnidadFuncional
(
	IDConsorcio int,
	NumeroDeUnidad int,
	IDPropietario int,
	Piso int,
	Departamento char(1),
	m2Unidad decimal(5,2) CHECK(m2Unidad > 0),
	CVU_CBU char(22),

	CONSTRAINT FK_Consorcio (IDConsorcio) REFERENCES dbo.Consorcio (IDConsorcio),
	CONSTRAINT FK_Persona (IDPropietario) REFERENCES dbo.Propietario (IDPropietario),
	CONSTRAINT PK_UnidadFuncional primary key clustered (IDConsorcio,NumeroDeUnidad)
)

CREATE TABLE dbo.Consorcio
(
	IdConsorcio int identity(1,1) primary key,
	NombreDeConsorcio varchar(20),
	Domicilio varchar(30),
	CantUnidadesFuncionales int CHECK(CantUnidadesFuncionales > 0),
	M2Totales int CHECK(M2Totales > 0)
)

CREATE TABLE dbo.Baulera
(
	IDBaulera int identity(1,1) primary key,
	IDConsorcio int,
	NumeroUnidad int,
	metrosCuadrados int CHECK(metrosCuadrados > 0),

	CONSTRAINT FK_Baulera (IDConsorcio, NumeroUnidad) REFERENCES dbo.UnidadFuncional (IDConsorcio, NumeroDeUnidad)
)

CREATE TABLE dbo.Cochera
(
	IDBCochera int identity(1,1) primary key,
	IDConsorcio int,
	NumeroUnidad int,
	metrosCuadrados int CHECK(metrosCuadrados > 0),

	CONSTRAINT FK_Cochera (IDConsorcio, NumeroUnidad) REFERENCES dbo.UnidadFuncional (IDConsorcio, NumeroDeUnidad)
)

CREATE TABLE dbo.GastoExtraordinario
(
	IDGastoExtraordinario int identity(1,1) primary key,
	IDConsorcio int,
	Detalle varchar(80),
	Importe decimal(10,2),

	CONSTRAINT FK_Consorcio (IDConsorcio) REFERENCES dbo.Consorcio (IDConsorcio)
)

CREATE TABLE dbo.CuotasGastoExtraordinario
(
	IDGastoExtraordinario int identity(1,1) primary key,
	TotalDeCuotas int CHECK(TotalDeCuotas >= 0),
	NumeroDeCuota int CHECK(NumeroDeCuota >= 1 AND NumeroDeCuota <= TotalDeCuotas),

	CONSTRAINT FK_CuotasGastoExtraordinario (IDGastoExtraordinario) REFERENCES dbo.GastoExtraordinario (IDGastoExtraordinario)
)

CREATE TABLE dbo.GastoOrdinario
(
	IDGastoOrdinario int identity(1,1) primary key,
	IDConsorcio int,
	Mes int CHECK(Mes > 0 AND Mes <= 12),
	Año int CHECK(Año > 1999 AND Año < year(getdate())),
	Importe decimal(10,2),

	CONSTRAINT FK_Consorcio (IDConsorcio) REFERENCES dbo.Consorcio (IDConsorcio)
)

CREATE TABLE dbo.Gasto_Servicio
(
	IDGasto int identity(1,1) primary key,
	IDConsorcio int,
	IDProveedor int,
	Importe decimal(10,2) CHECK(Importe > 0),
	Mes int CHECK(Mes > 0 AND Mes <= 12),
	Año int CHECK(Año > 1999 AND Año < year(getdate())),
	NroFactura int UNIQUE,

	CONSTRAINT FK_Consorcio (IDConsorcio) REFERENCES dbo.Consorcio (IDConsorcio),
	CONSTRAINT FK_Proveedor (IDProveedor) REFERENCES dbo.Proveedor (IDProveedor)
)

CREATE TABLE dbo.Proveedor
(
	IDProveedor int identity(1,1) primary key,
	TipoDeServicio varchar(50)
)

CREATE TABLE dbo.PagoAConsorcio
(
	IDPAGO int identity(1,1) primary key,
	IDConsorcio int,
	NumeroDeUnidad int,
	Fecha smalldatetime,
	CVU_CBU char(22),
	Importe decimal(10,2) CHECK(Importe > 0),

	CONSTRAINT FK_Unidad (IDConsorcio, NumeroDeUnidad) REFERENCES dbo.UnidadFuncional (IDConsorcio, NumeroDeUnidad)
)

CREATE TABLE dbo.EstadoDeCuenta
(
	IDConsorcio int,
	NumeroDeUnidad int,
	IDEstadoDeCuenta int identity(1,1),
	PorcentajeMetrosCuadrados decimal(4,2) CHECK(PorcentajeMetrosCuadrados > 0),
	PisoDepto char(4),
	Cocheras decimal(10,2) CHECK(Cocheras >= 0),
	Bauleras decimal(10,2) CHECK(Bauleras >= 0),
	Propietario varchar(30),
	SaldoAnteriorAbonado decimal(10,2) CHECK(SaldoAnteriorAbonado >= 0),
	PagoRecibido decimal(10,2) CHECK(PagoRecibido >= 0),
	Deuda decimal(10,2) CHECK(Deuda >= 0),
	InteresPorMora decimal(10,2) CHECK(InteresPorMora >= 0),
	ExpensaOrdinaria decimal(10,2) CHECK(ExpensaOrdinaria >= 0),
	ExpensaExtraordinaria decimal(10,2) CHECK(ExpensaExtraordinaria >= 0),

	CONSTRAINT FK_UnidadFuncional (IDConsorcio, NumeroDeUnidad) REFERENCES dbo.UnidadFuncional (IDConsorcio, NumeroDeUnidad),
	CONSTRAINT PK_EstadoDeCuenta primary key clustered (IDConsorcio, NumeroDeUnidad, IDEstadoDeCuenta)
)