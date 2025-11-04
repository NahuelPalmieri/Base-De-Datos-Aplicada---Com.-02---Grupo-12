--Creacion de la base de datos 
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'Com5600G12')
BEGIN
    CREATE DATABASE Com5600G12;
END
GO

USE Com5600G12;
GO

--Creacion de esquemas
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'administrativoGeneral') EXEC('CREATE SCHEMA administrativoGeneral');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'administrativoBancario') EXEC('CREATE SCHEMA administrativoBancario');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'administrativoOperativo') EXEC('CREATE SCHEMA administrativoOperativo');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Sistemas') EXEC ('CREATE SCHEMA Sistemas');
GO

--==============
--Tabla Persona
--==============
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'administrativoGeneral.Persona') AND type in (N'U'))
BEGIN
CREATE TABLE administrativoGeneral.Persona
(
	DNI int primary key CHECK(DNI > 9999999 AND DNI < 100000000),
	Nombres varchar(30) not null,
	Apellidos varchar(30) not null,
	Email varchar(50),
	NumeroDeTelefono char(10) CHECK(NumeroDeTelefono like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]') not null,
	CVU_CBU char(22) UNIQUE not null
);
END
GO

--==================
--Tabla Propietario
--==================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'administrativoGeneral.Propietario') AND type in (N'U'))
BEGIN
CREATE TABLE administrativoGeneral.Propietario
(
	IDPropietario int identity(1,1) primary key,
	DNI int UNIQUE,
	CONSTRAINT FK_Dni FOREIGN KEY (DNI) REFERENCES administrativoGeneral.Persona (DNI)
);
END
GO

--===============
--Tabla Consorcio
--===============
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'administrativoGeneral.Consorcio') AND type in (N'U'))
BEGIN
CREATE TABLE administrativoGeneral.Consorcio
(
	IdConsorcio int identity(1,1) primary key,
	NombreDeConsorcio varchar(20),
	Domicilio varchar(30),
	CantUnidadesFuncionales int CHECK(CantUnidadesFuncionales > 0),
	M2Totales int CHECK(M2Totales > 0)
);
END
GO

--=====================
--Tabla UnidadFuncional
--=====================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'administrativoGeneral.UnidadFuncional') AND type in (N'U'))
BEGIN
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
);
END 
GO

--===============
--Tabla Inquilino
--===============
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'administrativoGeneral.Inquilino') AND type in (N'U'))
BEGIN
CREATE TABLE administrativoGeneral.Inquilino
(
	IdInquilino int identity(1,1) primary key,
	NroDeConsorcio int,
	NroDeUnidad int,
	DNI int,

	CONSTRAINT FK_Inquilino_Persona FOREIGN KEY (DNI) REFERENCES administrativoGeneral.Persona (DNI),
	CONSTRAINT FK_Inquilino_UnidadFuncional FOREIGN KEY (NroDeConsorcio, NroDeUnidad) REFERENCES administrativoGeneral.UnidadFuncional (IdConsorcio, NumeroDeUnidad)
);
END 
GO

--==============
--Tabla Baulera
--==============
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'administrativoGeneral.Baulera') AND type in (N'U'))
BEGIN
CREATE TABLE administrativoGeneral.Baulera
(
	IdBaulera int identity(1,1) primary key,
	IdConsorcio int,
	NumeroUnidad int,
	M2Baulera int CHECK(M2Baulera > 0),

	CONSTRAINT FK_Baulera FOREIGN KEY (IdConsorcio, NumeroUnidad) REFERENCES administrativoGeneral.UnidadFuncional (IdConsorcio, NumeroDeUnidad)
);
END
GO

--==============
--Tabla Cochera
--==============
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'administrativoGeneral.Cochera') AND type in (N'U'))
BEGIN
CREATE TABLE administrativoGeneral.Cochera
(
	IdCochera int identity(1,1) primary key,
	IdConsorcio int,
	NumeroUnidad int,
	M2Cochera int CHECK(M2Cochera > 0),

	CONSTRAINT FK_Cochera FOREIGN KEY (IdConsorcio, NumeroUnidad) REFERENCES administrativoGeneral.UnidadFuncional (IdConsorcio, NumeroDeUnidad)
);
END
GO

--=========================
--Tabla GastoExtraordinario
--=========================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.GastoExtraordinario') AND type in (N'U'))
BEGIN
CREATE TABLE dbo.GastoExtraordinario
(
	IDGastoExtraordinario int identity(1,1) primary key,
	IDConsorcio int,
	Detalle varchar(80),
	Importe decimal(10,2),

	CONSTRAINT FK_Consorcio (IDConsorcio) REFERENCES dbo.Consorcio (IDConsorcio)
);
END
GO

--================================
--Tabla CuotasGastoExtraordinario
--================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.CuotasGastoExtraordinario') AND type in (N'U'))
BEGIN
CREATE TABLE dbo.CuotasGastoExtraordinario
(
	IDGastoExtraordinario int identity(1,1) primary key,
	TotalDeCuotas int CHECK(TotalDeCuotas >= 0),
	NumeroDeCuota int CHECK(NumeroDeCuota >= 1 AND NumeroDeCuota <= TotalDeCuotas),

	CONSTRAINT FK_CuotasGastoExtraordinario (IDGastoExtraordinario) REFERENCES dbo.GastoExtraordinario (IDGastoExtraordinario)
);
END 
GO

--====================
--Tabla GastoOrdinario
--====================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.GastoOrdinario') AND type in (N'U'))
BEGIN
CREATE TABLE dbo.GastoOrdinario
(
	IDGastoOrdinario int identity(1,1) primary key,
	IDConsorcio int,
	Mes int CHECK(Mes > 0 AND Mes <= 12),
	Año int CHECK(Año > 1999 AND Año < year(getdate())),
	Importe decimal(10,2),

	CONSTRAINT FK_Consorcio (IDConsorcio) REFERENCES dbo.Consorcio (IDConsorcio)
);
END
GO

--====================
--Tabla Gasto_Servicio
--====================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.Gasto_Servicio') AND type in (N'U'))
BEGIN
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
);
END
GO

--================
--Tabla Proveedor
--===============
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.Proveedor') AND type in (N'U'))
BEGIN
CREATE TABLE dbo.Proveedor
(
	IDProveedor int identity(1,1) primary key,
	TipoDeServicio varchar(50)
);
END 
GO

--====================
--Tabla PagoAConsorcio
--====================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.PagoAConsorcio') AND type in (N'U'))
BEGIN
CREATE TABLE dbo.PagoAConsorcio
(
	IDPAGO int identity(1,1) primary key,
	IDConsorcio int,
	NumeroDeUnidad int,
	Fecha smalldatetime,
	CVU_CBU char(22),
	Importe decimal(10,2) CHECK(Importe > 0),

	CONSTRAINT FK_Unidad (IDConsorcio, NumeroDeUnidad) REFERENCES dbo.UnidadFuncional (IDConsorcio, NumeroDeUnidad)
);
END 
GO

---====================
--Tabla EstadoDeCuenta
--====================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.EstadoDeCuenta') AND type in (N'U'))
BEGIN
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
);
END
GO