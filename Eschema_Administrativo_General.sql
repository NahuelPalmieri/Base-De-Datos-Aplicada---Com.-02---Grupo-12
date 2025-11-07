create schema administrativoGeneral

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

CREATE TABLE administrativoGeneral.CuotasGastoExtraordinario
(
	IDGastoExtraordinario int identity(1,1) primary key,
	TotalDeCuotas int CHECK(TotalDeCuotas >= 0),
	NumeroDeCuota int CHECK(NumeroDeCuota >= 1 AND NumeroDeCuota <= TotalDeCuotas),

	CONSTRAINT FK_CuotasGastoExtraordinario (IDGastoExtraordinario) REFERENCES administrativoGeneral.GastoExtraordinario (IDGastoExtraordinario)
)
--------------------------------------------------------
--------------------------------------------------------
CREATE TABLE administrativoGeneral.GastoOrdinario
(
	IDGastoOrdinario int identity(1,1) primary key,
	IdConsorcio int,
	Mes int CHECK(Mes > 0 AND Mes <= 12),
	Año int CHECK(Año > 1999 AND Año < year(getdate())),
	Importe decimal(10,2),

	CONSTRAINT FK_GastoOrdinario_Consorcio FOREIGN KEY (IdConsorcio) REFERENCES administrativoGeneral.Consorcio (IdConsorcio)
)

CREATE TABLE administrativoGeneral.Propietario
(
	IDPropietario int identity(1,1) primary key,
	DNI int UNIQUE,
	CONSTRAINT FK_Dni FOREIGN KEY (DNI) REFERENCES administrativoGeneral.Persona (DNI)
)

CREATE TABLE administrativoGeneral.Proveedor
(
	IDProveedor int identity(1,1) primary key,
	TipoDeServicio varchar(50)
)

CREATE TABLE administrativoGeneral.GastoServicio
(
	IDGasto int identity(1,1) primary key,
	IdConsorcio int,
	IDProveedor int,
	Importe decimal(10,2) CHECK(Importe > 0),
	Mes int CHECK(Mes > 0 AND Mes <= 12),
	Año int CHECK(Año > 1999 AND Año < year(getdate())),
	NroFactura int UNIQUE,

	CONSTRAINT FK_GastoServicio_Consorcio FOREIGN KEY (IdConsorcio) REFERENCES administrativoGeneral.Consorcio (IdConsorcio),
	CONSTRAINT FK_GastoServicio_Proveedor FOREIGN KEY (IDProveedor) REFERENCES administrativoGeneral.Proveedor (IDProveedor)
)
go
create or alter procedure administrativoGeneral.ImportarServiciosServicios
as
BEGIN
		
   create table #tempServicios
   (
	NombreConsorcio NVARCHAR(200),
    Mes NVARCHAR(50),
    Bancarios NVARCHAR(100),
    Limpieza NVARCHAR(100),
    Administracion NVARCHAR(100),
    Seguros NVARCHAR(100),
    Gastos_Generales NVARCHAR(100),
    Servicios_Publicos_Agua NVARCHAR(100),
    Servicios_Publicos_Luz NVARCHAR(100)
   );
   
-- Utilizar OPENROWSET con OPENJSON para leer el archivo JSON y cargar los datos en la tabla
    INSERT INTO #tempServicios (NombreConsorcio,
    Mes ,
    Bancarios,
    Limpieza ,
    Administracion ,
    Seguros ,
    Gastos_Generales ,
    Servicios_Publicos_Agua,
    Servicios_Publicos_Luz)
    SELECT NombreConsorcio, Mes, Bancarios, Limpieza, Administracion, Seguros, Gastos_Generales, 
    Servicios_Publicos_Agua, Servicios_Publicos_Luz
    FROM OPENROWSET (BULK 'C:\Users\CIRCO STUDIO\Desktop\consorcios\Servicios.Servicios.json', 
    SINGLE_CLOB) as jsonFile
    CROSS APPLY OPENJSON(BulkColumn)
    WITH (
    NombreConsorcio NVARCHAR(200) '$."Nombre del consorcio"',
    Mes NVARCHAR(50) '$.Mes',
    Bancarios NVARCHAR(100) '$.BANCARIOS',
    Limpieza NVARCHAR(100) '$.LIMPIEZA',
    Administracion nVARCHAR(100) '$.ADMINISTRACION',
    Seguros NVARCHAR(100) '$.SEGUROS',
    Gastos_Generales NVARCHAR(100) '$."GASTOS GENERALES"',
    Servicios_Publicos_Agua NVARCHAR(100) '$."SERVICIOS PUBLICOS-Agua"',
    Servicios_Publicos_Luz NVARCHAR(100) '$."SERVICIOS PUBLICOS-Luz"'
    )
	SELECT *
    FROM #tempServicios
END
GO

exec administrativoGeneral.ImportarServiciosServicios

