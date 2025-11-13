/********************************************************************************
	Trabajo Practico Integrador - Bases de Datos Aplicadas (2º Cuatrimestre 2025)
	Creacion de Base de Datos, Esquemas y Tablas
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

-- ===============================
-- 1. CREACION DE LA BASE DE DATOS
-- ===============================

--DROP DATABASE Com5600G12
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'Com5600G12')
BEGIN
    CREATE DATABASE Com5600G12;
END
GO

USE Com5600G12;
GO


-- ===============================
-- 2. CREACION DE ESQUEMAS
-- ===============================

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'actualizacionDeDatosUF') EXEC('CREATE SCHEMA actualizacionDeDatosUF');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'importacionDeInformacionBancaria') EXEC('CREATE SCHEMA importacionDeInformacionBancaria');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'generacionDeReportes') EXEC('CREATE SCHEMA generacionDeReportes');
GO 


/********************************************************************************
								3. CREACION DE TABLAS
*********************************************************************************/

--==============================
-- TABLA: Persona
--==============================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'actualizacionDeDatosUF.Persona') AND type in (N'U'))
BEGIN
CREATE TABLE actualizacionDeDatosUF.Persona
(
	DNI int primary key CHECK(DNI > 9999999 AND DNI < 100000000),
	Nombres varchar(30) not null,
	Apellidos varchar(30) not null,
	Email varchar(50),
	NumeroDeTelefono char(10) CHECK(NumeroDeTelefono like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]') not null,
	CVU_CBU char(22) UNIQUE not null,
	Inquilino bit NOT NULL
);
END
GO

--==============================
-- TABLA: Propietario
--==============================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'actualizacionDeDatosUF.Propietario') AND type in (N'U'))
BEGIN
CREATE TABLE actualizacionDeDatosUF.Propietario
(
	DNI int primary key,
	CONSTRAINT FK_Dni FOREIGN KEY (DNI) REFERENCES actualizacionDeDatosUF.Persona (DNI)
);
END
GO

--==============================
-- TABLA: Consorcio
--==============================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'actualizacionDeDatosUF.Consorcio') AND type in (N'U'))
BEGIN
CREATE TABLE actualizacionDeDatosUF.Consorcio
(
	IDConsorcio int identity(1,1) primary key,
	NombreDeConsorcio varchar(20),
	Domicilio varchar(30),
	CantUnidadesFuncionales int CHECK(CantUnidadesFuncionales > 0),
	M2Totales int CHECK(M2Totales > 0)
);
END
GO

--==============================
-- TABLA: UnidadFuncional
--==============================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'actualizacionDeDatosUF.UnidadFuncional') AND type in (N'U'))
BEGIN
CREATE TABLE actualizacionDeDatosUF.UnidadFuncional
(
	IDConsorcio int,
	NumeroDeUnidad int,
	DNIPropietario int,
	Piso char(2) NOT NULL,
	Departamento char(1) NOT NULL,
	M2Unidad int CHECK(m2Unidad > 0) NOT NULL,  --es M2Unidad NO m2Unidad
	CVU_CBU char(22),

	CONSTRAINT PK_UnidadFuncional PRIMARY KEY CLUSTERED (IDConsorcio,NumeroDeUnidad),
	CONSTRAINT FK_UnidadFuncional_Consorcio FOREIGN KEY (IDConsorcio) REFERENCES actualizacionDeDatosUF.Consorcio (IDConsorcio),
	CONSTRAINT FK_UnidadFuncional_Persona FOREIGN KEY (DNIPropietario) REFERENCES actualizacionDeDatosUF.Propietario (DNI)
);
END 
GO

--==============================
-- TABLA: Inquilino
--==============================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'actualizacionDeDatosUF.Inquilino') AND type in (N'U'))
BEGIN
CREATE TABLE actualizacionDeDatosUF.Inquilino
(
	DNI int primary key,
	NroDeConsorcio int,
	NroDeUnidad int,

	CONSTRAINT FK_Inquilino_Persona FOREIGN KEY (DNI) REFERENCES actualizacionDeDatosUF.Persona (DNI),
	CONSTRAINT FK_Inquilino_UnidadFuncional FOREIGN KEY (NroDeConsorcio, NroDeUnidad) REFERENCES actualizacionDeDatosUF.UnidadFuncional (IdConsorcio, NumeroDeUnidad)
);
END 
GO

--==============================
-- TABLA: Baulera
--==============================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'actualizacionDeDatosUF.Baulera') AND type in (N'U'))
BEGIN
CREATE TABLE actualizacionDeDatosUF.Baulera
(
	IdBaulera int identity(1,1) primary key,
	IDConsorcio int,
	NumeroUnidad int,
	M2Baulera int CHECK(M2Baulera > 0),

	CONSTRAINT FK_Baulera FOREIGN KEY (IDConsorcio, NumeroUnidad) REFERENCES actualizacionDeDatosUF.UnidadFuncional (IDConsorcio, NumeroDeUnidad)
);
END
GO

--==============================
-- TABLA: Cochera
--==============================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'actualizacionDeDatosUF.Cochera') AND type in (N'U'))
BEGIN
CREATE TABLE actualizacionDeDatosUF.Cochera
(
	IdCochera int identity(1,1) primary key,
	IdConsorcio int,
	NumeroUnidad int,
	M2Cochera int CHECK(M2Cochera > 0),

	CONSTRAINT FK_Cochera FOREIGN KEY (IDConsorcio, NumeroUnidad) REFERENCES actualizacionDeDatosUF.UnidadFuncional (IDConsorcio, NumeroDeUnidad)
);
END
GO

--==============================
-- TABLA: GastoExtraordinario
--==============================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'actualizacionDeDatosUF.GastoExtraordinario') AND type in (N'U'))
BEGIN
CREATE TABLE actualizacionDeDatosUF.GastoExtraordinario
(
	IDGastoExtraordinario int identity(1,1) primary key,
	IDConsorcio int, 
	Mes int CHECK(Mes > 0 AND Mes <= 12),  --le agregue Mes y Año ya que son necesarios para el informe
	Año int CHECK(Año > 1999 AND Año <= year(getdate())),
	Detalle varchar(80),
	Importe decimal(10,2),

	CONSTRAINT FK_Consorcio FOREIGN KEY (IDConsorcio) REFERENCES actualizacionDeDatosUF.Consorcio (IDConsorcio)
); --Le agrege el FOREIGN KEY porque no se le coloco
END
GO


--==================================
-- TABLA: CuotasGastoExtraordinario
--==================================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'actualizacionDeDatosUF.CuotasGastoExtraordinario') AND type in (N'U'))
BEGIN
CREATE TABLE actualizacionDeDatosUF.CuotasGastoExtraordinario
(
	IDGastoExtraordinario int identity(1,1) primary key,  --no se esta usando el PK de la tabla GastoExtraordinario, 
	TotalDeCuotas int CHECK(TotalDeCuotas >= 0),		  --si es PK+FK como se muestra deberia ser IDGastoExtraordinario y NO IdGastoExtraordinario
	NumeroDeCuota int
	CONSTRAINT FK_CuotasGastoExtraordinario FOREIGN KEY (IDGastoExtraordinario) REFERENCES actualizacionDeDatosUF.GastoExtraordinario (IDGastoExtraordinario)
); --Le agrege el FOREIGN KEY porque no se le coloco
END 
GO

--==============================
-- TABLA: GastoOrdinario
--==============================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'actualizacionDeDatosUF.GastoOrdinario') AND type in (N'U'))
BEGIN
CREATE TABLE actualizacionDeDatosUF.GastoOrdinario
(
	IDGastoOrdinario int identity(1,1) primary key,
	IDConsorcio int, 
	Mes int CHECK(Mes > 0 AND Mes <= 12),
	Año int CHECK(Año > 1999 AND Año <= year(getdate())),
	Importe decimal(10,2),

	CONSTRAINT FK_Consorcio2 FOREIGN KEY (IDConsorcio) REFERENCES actualizacionDeDatosUF.Consorcio (IDConsorcio)
); --Le agrege el FOREIGN KEY porque no se le coloco, le cambio nombre del FK ya que existe el
END --nombre FK_Consorcio en la tabla dbo.GastoExtraordinario
GO

--==============================
-- TABLA: Proveedor
--==============================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'actualizacionDeDatosUF.Proveedor') AND type in (N'U'))
BEGIN
CREATE TABLE actualizacionDeDatosUF.Proveedor
(
	IDProveedor int identity(1,1) primary key,
	TipoDeServicio varchar(50)
);
END 
GO

--==============================
-- TABLA: GastoServicio
--==============================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'actualizacionDeDatosUF.GastoServicio') AND type in (N'U'))
BEGIN
CREATE TABLE actualizacionDeDatosUF.GastoServicio
(
	IDGasto int identity(1,1) primary key,
	IDConsorcio int,
	IDProveedor int,
	Importe decimal(10,2) CHECK(Importe > 0),
	Mes int CHECK(Mes > 0 AND Mes <= 12),
	Año int CHECK(Año > 1999 AND Año <= year(getdate())),
	--NroFactura int UNIQUE,-- la saque porque daba problemas con la importacion del JSON, en el sp mas explicado.

	CONSTRAINT FK_Consorcio3 FOREIGN KEY (IDConsorcio) REFERENCES actualizacionDeDatosUF.Consorcio (IDConsorcio),
	CONSTRAINT FK_Proveedor FOREIGN KEY (IDProveedor) REFERENCES actualizacionDeDatosUF.Proveedor (IDProveedor)
); --Le agrege el FOREIGN KEY porque no se le coloco
END --Le agrege el FOREIGN KEY porque no se le coloco, le cambio nombre del FK ya que existe el
GO --nombre FK_Consorcio en la tabla dbo.GastoExtraordinario

--==============================
-- TABLA: PagoAConsorcio
--==============================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'importacionDeInformacionBancaria.PagoAConsorcio') AND type in (N'U'))
BEGIN
CREATE TABLE importacionDeInformacionBancaria.PagoAConsorcio
(
	IDPAGO int identity(1,1) primary key,
	IDConsorcio int,
	NumeroDeUnidad int,
	Fecha smalldatetime, --pasar a date?
	CVU_CBU char(22),
	Importe decimal(10,2) CHECK(Importe > 0),
	Ordinario bit not null,

	CONSTRAINT FK_Unidad FOREIGN KEY (IDConsorcio, NumeroDeUnidad) REFERENCES actualizacionDeDatosUF.UnidadFuncional (IDConsorcio, NumeroDeUnidad)
);
END 
GO

--==============================
-- TABLA: EstadoDeCuenta
--==============================

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'importacionDeInformacionBancaria.EstadoDeCuenta') AND type in (N'U'))
BEGIN
CREATE TABLE importacionDeInformacionBancaria.EstadoDeCuenta
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

	CONSTRAINT FK_UnidadFuncional FOREIGN KEY (IDConsorcio, NumeroDeUnidad) REFERENCES actualizacionDeDatosUF.UnidadFuncional (IDConsorcio, NumeroDeUnidad),
	CONSTRAINT PK_EstadoDeCuenta primary key clustered (IDConsorcio, NumeroDeUnidad, IDEstadoDeCuenta)
); --Le agrege el FOREIGN KEY porque no se le coloco
END
GO

--==============================
-- TABLA DE CONTROL DE ERRORES
--==============================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'actualizacionDeDatosUF.PersonasConError') AND type in (N'U'))
BEGIN
CREATE TABLE actualizacionDeDatosUF.PersonasConError --Esta tabla es para no perder la informacion de los registros mal ingresados o duplicados
(
	Id int identity(1,1) primary key,
	DNI varchar(8),
	Nombres varchar(30),
	Apellidos varchar(30),
	Email varchar(50),
	NumeroDeTelefono char(10),
	CVU_CBU varchar(22),
	Inquilino char(1)
)
END