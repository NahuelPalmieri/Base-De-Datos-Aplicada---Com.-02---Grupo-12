CREATE DATABASE AltosDeSaintJust

USE AltosDeSaintJust

CREATE TABLE administrativoGeneral.Persona
(
	DNI int primary key CHECK(DNI > 9999999 AND DNI < 100000000),
	Nombres varchar(30) not null,
	Apellidos varchar(30) not null,
	Email varchar(50),
	NumeroDeTelefono char(10) CHECK(NumeroDeTelefono like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]') not null,
	CVU_CBU char(22) UNIQUE not null
)

CREATE TABLE administrativoGeneral.Propietario
(
	IDPropietario int identity(1,1) primary key,
	DNI int UNIQUE,
	CONSTRAINT FK_Dni FOREIGN KEY (DNI) REFERENCES administrativoGeneral.Persona (DNI)
)

CREATE TABLE administrativoGeneral.Consorcio
(
	IdConsorcio int identity(1,1) primary key,
	NombreDeConsorcio varchar(20),
	Domicilio varchar(30),
	CantUnidadesFuncionales int CHECK(CantUnidadesFuncionales > 0),
	M2Totales int CHECK(M2Totales > 0)
)

CREATE TABLE administrativoGeneral.UnidadFuncional
(
	IdConsorcio int,
	NumeroDeUnidad int,
	IdPropietario int,
	Piso int NOT NULL,
	Departamento char(1) NOT NULL,
	M2Unidad int CHECK(m2Unidad > 0) NOT NULL,
	CVU_CBU char(22),

	CONSTRAINT PK_UnidadFuncional PRIMARY KEY CLUSTERED (IdConsorcio,NumeroDeUnidad),
	CONSTRAINT FK_UnidadFuncional_Consorcio FOREIGN KEY (IdConsorcio) REFERENCES administrativoGeneral.Consorcio (IdConsorcio),
	CONSTRAINT FK_UnidadFuncional_Persona FOREIGN KEY (IdPropietario) REFERENCES administrativoGeneral.Propietario (IdPropietario)
)

CREATE TABLE administrativoGeneral.Inquilino
(
	IdInquilino int identity(1,1) primary key,
	NroDeConsorcio int,
	NroDeUnidad int,
	DNI int,

	CONSTRAINT FK_Inquilino_Persona FOREIGN KEY (DNI) REFERENCES administrativoGeneral.Persona (DNI),
	CONSTRAINT FK_Inquilino_UnidadFuncional FOREIGN KEY (NroDeConsorcio, NroDeUnidad) REFERENCES administrativoGeneral.UnidadFuncional (IdConsorcio, NumeroDeUnidad)
)

CREATE TABLE administrativoGeneral.Baulera
(
	IdBaulera int identity(1,1) primary key,
	IdConsorcio int,
	NumeroUnidad int,
	M2Baulera int CHECK(M2Baulera > 0),

	CONSTRAINT FK_Baulera FOREIGN KEY (IdConsorcio, NumeroUnidad) REFERENCES administrativoGeneral.UnidadFuncional (IdConsorcio, NumeroDeUnidad)
)

CREATE TABLE administrativoGeneral.Cochera
(
	IdCochera int identity(1,1) primary key,
	IdConsorcio int,
	NumeroUnidad int,
	M2Cochera int CHECK(M2Cochera > 0),

	CONSTRAINT FK_Cochera FOREIGN KEY (IdConsorcio, NumeroUnidad) REFERENCES administrativoGeneral.UnidadFuncional (IdConsorcio, NumeroDeUnidad)
)

CREATE TABLE dbo.GastoExtraordinario
(
	IDGastoExtraordinario int identity(1,1) primary key,
	IDConsorcio int,
	Detalle varchar(80),
	Importe decimal(10,2),

	CONSTRAINT FK_Consorcio (IDConsorcio) REFERENCES dbo.Consorcio (IDConsorcio)
)

CREATE TABLE administrativoGeneral.CuotasGastoExtraordinario
(
	IDGastoExtraordinario int identity(1,1) primary key,
	TotalDeCuotas int CHECK(TotalDeCuotas >= 0),
	NumeroDeCuota int CHECK(NumeroDeCuota >= 1 AND NumeroDeCuota <= TotalDeCuotas),

	CONSTRAINT FK_CuotasGastoExtraordinario (IDGastoExtraordinario) REFERENCES dbo.GastoExtraordinario (IDGastoExtraordinario)
)
----------------------------------------------------------------------------------
---------------------------------------------------------------------------------

CREATE TABLE administrativoGeneral.GastoOrdinario
(
	IDGastoOrdinario int identity(1,1) primary key,
	IdConsorcio int,
	Mes int CHECK(Mes > 0 AND Mes <= 12),
	Año int CHECK(Año > 1999 AND Año < year(getdate())),
	Importe decimal(10,2),

	CONSTRAINT FK_Consorcio (IdConsorcio) REFERENCES administrativoGeneral.Consorcio (IdConsorcio)
)

CREATE TABLE administrativoGeneral.Gasto_Servicio
(
	IDGasto int identity(1,1) primary key,
	IDConsorcio int,
	IDProveedor int,
	Importe decimal(10,2) CHECK(Importe > 0),
	Mes int CHECK(Mes > 0 AND Mes <= 12),
	Año int CHECK(Año > 1999 AND Año < year(getdate())),
	NroFactura int UNIQUE,

	CONSTRAINT FK_Consorcio (IDConsorcio) REFERENCES dbo.Consorcio (IdConsorcio),
	CONSTRAINT FK_Proveedor (IDProveedor) REFERENCES dbo.Proveedor (IdProveedor)
)

CREATE TABLE administrativoGeneral.Proveedor
(
	IDProveedor int identity(1,1) primary key,
	TipoDeServicio varchar(50)
)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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