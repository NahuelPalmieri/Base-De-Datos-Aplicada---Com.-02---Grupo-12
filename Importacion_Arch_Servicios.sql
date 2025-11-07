use AltosDeSaintJust
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
    NombreConsorcio NVARCHAR(200) '$.Nombre del consorcio',
    Mes NVARCHAR(50) '$.Mes',
    Bancarios NVARCHAR(100) '$.BANCARIOS',
    Limpieza NVARCHAR(100) '$.LIMPIEZA',
    Administracion nVARCHAR(100) '$.ADMINISTRACION',
    Seguros NVARCHAR(100) '$.SEGUROS',
    Gastos_Generales NVARCHAR(100) '$.GASTOS GENERALES',
    Servicios_Publicos_Agua NVARCHAR(100) '$.SERVICIOS PUBLICOS-Agua',
    Servicios_Publicos_Luz NVARCHAR(100) '$.SERVICIOS PUBLICOS-Luz'
    )
    SELECT *
    FROM #tempServicios
END
GO

