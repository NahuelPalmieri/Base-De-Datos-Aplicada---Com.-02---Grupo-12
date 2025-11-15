/********************************************************************************
	Trabajo Practico Integrador - Bases de Datos Aplicadas (2º Cuatrimestre 2025)
	Importacion de Datos mediante Stored Procedures
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

-- HAY QUE EJECUTAR EL CODIGO DE ESTE ARCHIVO TODO JUNTO DE UNA SOLA VEZ

--Para asegurarnos que se ejecute usando la BDD
use Com5600G12

--===============================================================================
          -- DECLARACION Y SETTEO DE VARIABLES PARA LOS PATH:
          -- (Ruta, ArchPagosConsorcio, ArchInquilinoPropietariosDatos,
          -- ArchUFPorConsorcio, ArchInquilinoPropietariosUF Y
          -- ArchServiciosServicios)
--===============================================================================

-- PARA HACER USO DE LAS VARIABLES QUE VAMOS A DECLARAR, HACER LOS SIG. PASOS:
-- 1. Dirigirse al apartado consulta.
-- 2. Presionar el boton "Modo SQLCMD"

:SETVAR Ruta "C:\consorcios"
GO
:SETVAR ArchPagosConsorcio "pagos_consorcios.csv"
GO
:SETVAR ArchInquilinoPropietariosDatos "Inquilino-propietarios-datos.csv"
GO
:SETVAR ArchInquilinoPropietariosUF "Inquilino-propietarios-UF.csv"
GO
:SETVAR ArchServiciosServicios "Servicios.Servicios.json"
GO


--===============================================================================
                -- IMPORTACION DE ARCHIVO: inquilino-propietarios-datos.csv
--===============================================================================


create or alter trigger actualizacionDeDatosUF.InsercionPersona --DE ACA (TRIGGER)
on actualizacionDeDatosUF.Persona
instead of insert
as
begin
	merge into actualizacionDeDatosUF.Persona destino
	using inserted origen
	on destino.DNI = origen.DNI
	when MATCHED THEN
		UPDATE SET
			destino.Email = origen.Email,
			destino.NumeroDeTelefono = origen.NumeroDeTelefono,
			destino.CVU_CBU = origen.CVU_CBU
	WHEN NOT MATCHED THEN
		INSERT (DNI, Nombres, Apellidos, Email, NumeroDeTelefono, CVU_CBU, Inquilino)
		VALUES (origen.DNI, origen.Nombres, origen.Apellidos, origen.Email, origen.NumeroDeTelefono, origen.CVU_CBU, origen.Inquilino);
end 
go

create or alter procedure actualizacionDeDatosUF.importarDatosPersonas --DE ACA
	@ubicacion varchar(MAX)
as
begin

	create table #personasCrudoTemp(
		Nombres varchar(30),
		Apellidos varchar(30),
		DNI varchar(8),
		Email varchar(50),
		NumeroDeTelefono char(10),
		CVU_CBU varchar(22),
		Inquilino char(1)
	)

	declare @CadenaSQL nvarchar(MAX) 

	select @CadenaSQL = '

	bulk insert #personasCrudoTemp
	from ''' + @ubicacion + '''
	with(
		fieldterminator = '';'',
		rowterminator = ''\n'',
		codepage = ''ACP'',
		firstrow = 2
	)'

	EXEC sp_executesql @CadenaSQL


	update #personasCrudoTemp --LIMPIEZA DE DATOS
	set Email = lower(replace(Email, ' ', '')),
	Nombres = upper(ltrim(rtrim(Nombres))),
	Apellidos = upper(ltrim(rtrim(Apellidos))),
	DNI = ltrim(rtrim(DNI)),
	NumeroDeTelefono = ltrim(rtrim(NumeroDeTelefono)),
	CVU_CBU = ltrim(rtrim(CVU_CBU)),
	Inquilino = ltrim(rtrim(Inquilino))

	;with Duplicados(DNI, Apariciones) as(
		select DNI, count(DNI) over(partition by DNI) as apariciones
		from #personasCrudoTemp
	)
	insert into actualizacionDeDatosUF.PersonasConError (DNI, Nombres, Apellidos, Email, NumeroDeTelefono, CVU_CBU, Inquilino)
	select DNI, Nombres, Apellidos, Email, NumeroDeTelefono, CVU_CBU, Inquilino
	from #personasCrudoTemp p
	where exists(select 1 from Duplicados d  where p.DNI = d.DNI and d.Apariciones>1)

	;with Duplicados(DNI, Apariciones) as(
		select DNI, count(DNI) over(partition by DNI) as apariciones
		from #personasCrudoTemp
	)
	delete from #personasCrudoTemp 
	where exists(select 1 from Duplicados d where #personasCrudoTemp.DNI = d.DNI and d.Apariciones>1) --SI HAY DUPLICADOS LOS ELIMINO
	
	insert into actualizacionDeDatosUF.Persona
	select cast(DNI as int), Nombres, Apellidos, Email, NumeroDeTelefono, CVU_CBU, cast(Inquilino as bit) from #personasCrudoTemp
	where DNI IS NOT NULL 
    or Nombres is not null 
    or Apellidos is not null 
    or NumeroDeTelefono is not null 
    or CVU_CBU is not null 
    or Inquilino is not null --INSERTO MIENTRAS TENGAN LOS CAMPOS NOT NULL DE LA TABLA
	

	insert into actualizacionDeDatosUF.Propietario ---Las personas con inquilino = 0 van a la tabla propietarios
	select DNI from actualizacionDeDatosUF.Persona per
	where Inquilino = 0
	and not exists(select 1 from actualizacionDeDatosUF.Propietario pro where pro.DNI = per.DNI)

	insert into actualizacionDeDatosUF.Inquilino (DNI) ---Las personas con inquilino = 1 van a la tabla inquilino
	select DNI from actualizacionDeDatosUF.Persona per
	where Inquilino = 1
	and not exists(select 1 from actualizacionDeDatosUF.Inquilino inq where inq.DNI = per.DNI)

end 

GO

--EJECUCION DEL STORED PROCEDURE
EXEC actualizacionDeDatosUF.importarDatosPersonas '$(Ruta)/$(ArchInquilinoPropietariosDatos)'
GO

--===============================================================================
                -- IMPORTACION DE ARCHIVO: Inquilino-propietarios-UF.csv           
--===============================================================================
go
CREATE OR ALTER PROCEDURE actualizacionDeDatosUF.Importar_Inquilino_Propietarios_UF 

		@ruta_archivo varchar(MAX)
AS 
BEGIN 
		
		CREATE TABLE #TempInqPropUF --1. Creo una tabla temporal donde guardo el contenido del archivo
		(
			CVU_CBU char(22),
			NombreDeConsorcio varchar(20),
			NumeroDeUnidad int,
			Piso char(2),
			Departamento char(1)
		);

		
		DECLARE @cadena nvarchar(MAX); --2. Armo y ejecuto el BULK INSERT para importar el archivo en la tabla temporal

		SET @cadena = '
				BULK INSERT #TempInqPropUF
				FROM ''' + @ruta_archivo+ '''
				WITH (
						FIELDTERMINATOR = ''|'',
						ROWTERMINATOR = ''\n'',
						CODEPAGE = ''ACP'',
						FIRSTROW = 2
					 ); ';

		EXEC sp_executesql @cadena;

	    UPDATE UF       --3. Actualizo la tabla Unidad Funcional 
        --cargando los CVU_CBU y DNI de propietarios.
		SET	
			UF.CVU_CBU		  = T.CVU_CBU,
			UF.DNIPropietario = P.DNI
		FROM actualizacionDeDatosUF.UnidadFuncional AS UF
		INNER JOIN actualizacionDeDatosUF.Consorcio AS C
			ON C.IdConsorcio = UF.IdConsorcio
		INNER JOIN #TempInqPropUF AS T
			ON C.NombreDeConsorcio  = T.NombreDeConsorcio
			AND UF.NumeroDeUnidad   = T.NumeroDeUnidad
			AND UF.Piso				= T.Piso
			AND UF.Departamento		= T.Departamento 
		INNER JOIN actualizacionDeDatosUF.Persona AS Pe
			ON Pe.CVU_CBU = T.CVU_CBU
		INNER JOIN actualizacionDeDatosUF.Propietario AS P
			ON P.DNI = Pe.DNI;


		UPDATE IQ     --4.Actualizo la tabla Inquilino cargando el Nro de Consorcio y el Nro de Unidad.
		SET
			IQ.NroDeConsorcio = C.IdConsorcio,
			IQ.NroDeUnidad	  = T.NumeroDeUnidad
		FROM actualizacionDeDatosUF.Inquilino AS IQ
		INNER JOIN actualizacionDeDatosUF.Persona AS PE
			ON IQ.DNI = PE.DNI							
		INNER JOIN #TempInqPropUF as T					
			ON PE.CVU_CBU = T.CVU_CBU
		INNER JOIN actualizacionDeDatosUF.Consorcio AS C
			ON T.NombreDeConsorcio = C.NombreDeConsorcio;
 
		DROP TABLE #TempInqPropUF; 
END; 
GO

--EJECUCION DEL STORED PROCEDURE
EXEC actualizacionDeDatosUF.Importar_Inquilino_Propietarios_UF '$(Ruta)/$(ArchInquilinoPropietariosUF)'
GO

--===============================================================================
                -- IMPORTACION DE ARCHIVO: Servicios.Servcios.json
--===============================================================================

CREATE OR ALTER PROCEDURE actualizacionDeDatosUF.ImportarServiciosServicios --DE ACA
    @RutaArchivo nvarchar(200)
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

   DECLARE @ImportarDinamico nvarchar(MAX);
   --
   SET @ImportarDinamico ='INSERT INTO #tempServicios (NombreConsorcio,
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
    FROM OPENROWSET (BULK '''+ @RutaArchivo + ''', 
    SINGLE_CLOB) as jsonFile
    CROSS APPLY OPENJSON(BulkColumn)
    WITH (
    NombreConsorcio NVARCHAR(200) ''$."Nombre del consorcio"'',
    Mes NVARCHAR(50) ''$.Mes'',
    Bancarios NVARCHAR(100) ''$.BANCARIOS'',
    Limpieza NVARCHAR(100) ''$.LIMPIEZA'',
    Administracion nVARCHAR(100) ''$.ADMINISTRACION'',
    Seguros NVARCHAR(100) ''$.SEGUROS'',
    Gastos_Generales NVARCHAR(100) ''$."GASTOS GENERALES"'',
    Servicios_Publicos_Agua NVARCHAR(100) ''$."SERVICIOS PUBLICOS-Agua"'',
    Servicios_Publicos_Luz NVARCHAR(100) ''$."SERVICIOS PUBLICOS-Luz"''
    )'
	exec (@ImportarDinamico)
    

    --creo tabla temporal limpia
    CREATE TABLE #tempServicios_Limpia
    (
        NombreConsorcio NVARCHAR(200),
        Mes NVARCHAR(50),
        Bancarios DECIMAL(18, 2),
        Limpieza DECIMAL(18, 2),
        Administracion DECIMAL(18, 2),
        Seguros DECIMAL(18, 2),
        Gastos_Generales DECIMAL(18, 2),
        Servicios_Publicos_Agua DECIMAL(18, 2),
        Servicios_Publicos_Luz DECIMAL(18, 2)
    );

    -- proceso ETL para insertar los datos en la tabla temporal limpia
    -- Limpiamos y convertimos los datos
    INSERT INTO #tempServicios_Limpia (
        NombreConsorcio, Mes, Bancarios, Limpieza, Administracion,
        Seguros, Gastos_Generales, Servicios_Publicos_Agua, Servicios_Publicos_Luz
    )
    --como los decimales vienen algunos con "." y otros con ",", casteo los valores como correspondan sus datos
    SELECT                          
        NombreConsorcio,
        Mes,
        COALESCE(                       
            TRY_CONVERT(DECIMAL(18, 2), REPLACE(Bancarios, ',', '')), -- Intento Formato Americano: "1,234.56"
            TRY_CONVERT(DECIMAL(18, 2), REPLACE(REPLACE(Bancarios, '.', ''), ',', '.')) -- Intento Formato Europeo: "1.234,56"
        ) AS Bancarios,
        
        COALESCE(
            TRY_CONVERT(DECIMAL(18, 2), REPLACE(Limpieza, ',', '')),
            TRY_CONVERT(DECIMAL(18, 2), REPLACE(REPLACE(Limpieza, '.', ''), ',', '.'))
        ) AS Limpieza,
        
        COALESCE(
            TRY_CONVERT(DECIMAL(18, 2), REPLACE(Administracion, ',', '')),
            TRY_CONVERT(DECIMAL(18, 2), REPLACE(REPLACE(Administracion, '.', ''), ',', '.'))
        ) AS Administracion,
        
        COALESCE(
            TRY_CONVERT(DECIMAL(18, 2), REPLACE(Seguros, ',', '')),
            TRY_CONVERT(DECIMAL(18, 2), REPLACE(REPLACE(Seguros, '.', ''), ',', '.'))
        ) AS Seguros,
        
        COALESCE(
            TRY_CONVERT(DECIMAL(18, 2), REPLACE(Gastos_Generales, ',', '')),
            TRY_CONVERT(DECIMAL(18, 2), REPLACE(REPLACE(Gastos_Generales, '.', ''), ',', '.'))
        ) AS Gastos_Generales,
        
        COALESCE(
            TRY_CONVERT(DECIMAL(18, 2), REPLACE(Servicios_Publicos_Agua, ',', '')),
            TRY_CONVERT(DECIMAL(18, 2), REPLACE(REPLACE(Servicios_Publicos_Agua, '.', ''), ',', '.'))
        ) AS Servicios_Publicos_Agua,
        
        COALESCE(
            TRY_CONVERT(DECIMAL(18, 2), REPLACE(Servicios_Publicos_Luz, ',', '')),
            TRY_CONVERT(DECIMAL(18, 2), REPLACE(REPLACE(Servicios_Publicos_Luz, '.', ''), ',', '.'))
        ) AS Servicios_Publicos_Luz
        
    FROM #tempServicios;


    --carga de las tablas GastoServicio y GastosOrdinarios

    --inserto en gasto servicio
    INSERT INTO actualizacionDeDatosUF.GastoServicio (
        IDConsorcio, IDProveedor, Importe, Mes, Año
    )
    SELECT
        c.IDConsorcio,
        p.IDProveedor,
        unpvt.Importe,
        CASE LOWER(tsl.Mes) --paso el mes a numero, para que respete el formaro de la tabla
            WHEN 'enero' THEN 1 WHEN 'febrero' THEN 2 WHEN 'marzo' THEN 3
            WHEN 'abril' THEN 4 WHEN 'mayo' THEN 5 WHEN 'junio' THEN 6
            WHEN 'julio' THEN 7 WHEN 'agosto' THEN 8 WHEN 'septiembre' THEN 9
            WHEN 'octubre' THEN 10 WHEN 'noviembre' THEN 11 WHEN 'diciembre' THEN 12
            ELSE 0 
        END AS MesNumero,
        YEAR(GETDATE())
    FROM #tempServicios_Limpia AS tsl
    CROSS APPLY (
        VALUES
            ('GASTOS BANCARIOS', tsl.Bancarios),
            ('GASTOS DE LIMPIEZA', tsl.Limpieza),
            ('GASTOS DE ADMINISTRACION', tsl.Administracion),
            ('SEGUROS', tsl.Seguros),
            ('GASTOS GENERALES', tsl.Gastos_Generales),-- a cual va?
            ('SERVICIOS PUBLICOS', tsl.Servicios_Publicos_Agua),
            ('SERVICIOS PUBLICOS', tsl.Servicios_Publicos_Luz)
    ) AS unpvt(TipoDeServicio, Importe)
    JOIN actualizacionDeDatosUF.Consorcio c ON c.NombreDeConsorcio = tsl.NombreConsorcio
    JOIN actualizacionDeDatosUF.Proveedor p ON p.TipoDeServicio = unpvt.TipoDeServicio
    WHERE unpvt.Importe IS NOT NULL AND unpvt.Importe > 0;


    -- inserto en gasto ordinario (Sumar)
    INSERT INTO actualizacionDeDatosUF.GastoOrdinario (
        IDConsorcio, Mes, Año, Importe
    )
    SELECT
        c.IDConsorcio,
        CASE LOWER(tsl.Mes) 
            WHEN 'enero' THEN 1 WHEN 'febrero' THEN 2 WHEN 'marzo' THEN 3
            WHEN 'abril' THEN 4 WHEN 'mayo' THEN 5 WHEN 'junio' THEN 6
            WHEN 'julio' THEN 7 WHEN 'agosto' THEN 8 WHEN 'septiembre' THEN 9
            WHEN 'octubre' THEN 10 WHEN 'noviembre' THEN 11 WHEN 'diciembre' THEN 12
            ELSE 0 
        END AS MesNumero,
        YEAR(GETDATE()),
        (
            ISNULL(tsl.Bancarios, 0) + ISNULL(tsl.Limpieza, 0) + ISNULL(tsl.Administracion, 0) +
            ISNULL(tsl.Seguros, 0) + ISNULL(tsl.Gastos_Generales, 0) + 
            ISNULL(tsl.Servicios_Publicos_Agua, 0) + ISNULL(tsl.Servicios_Publicos_Luz, 0)
        ) AS ImporteTotal
    FROM #tempServicios_Limpia AS tsl
    JOIN actualizacionDeDatosUF.Consorcio c ON c.NombreDeConsorcio = tsl.NombreConsorcio;

END
GO 

--EJECUCION DEL STORED PROCEDURE
EXEC actualizacionDeDatosUF.ImportarServiciosServicios '$(Ruta)/$(ArchServiciosServicios)'
GO
--===============================================================================
                -- IMPORTACION DE ARCHIVO: pagos_consorcios.csv
--===============================================================================
 GO
--SPs de Importacion
CREATE OR ALTER PROCEDURE importacionDeInformacionBancaria.ImportarPagosConsorcio
    @RutaArchivo NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- Eliminar tabla temporal si ya existe
    IF OBJECT_ID('#PagoTemp') IS NOT NULL
        DROP TABLE #PagoTemp;

    -- Crear tabla temporal 
    CREATE TABLE #PagoTemp ( 
        IdPago INT,                     -- Viene del CSV
        Fecha VARCHAR(20),             -- Fecha como texto para transformaci?n 
        CVU_CBU CHAR(22),              -- Para hacer el JOIN
        Importe VARCHAR(20)            -- Importe como texto para limpieza de "$"
    );

    -- BULK INSERT para importar el archivo
    DECLARE @CadenaSQL NVARCHAR(MAX) = '
        BULK INSERT #PagoTemp
        FROM ''' + @RutaArchivo + '''
        WITH (
            FIRSTROW = 2,                  -- Saltear encabezado
            FIELDTERMINATOR = '','',       -- Separador de campos
            ROWTERMINATOR = ''\n'',        -- Fin de l?nea
            CODEPAGE = ''65001'',          -- UTF-8
            TABLOCK
        );
    ';

    -- Ejecuto el Bulk Insert usando manejo de errores
    BEGIN TRY
        EXEC sp_executesql @CadenaSQL;
    END TRY
    BEGIN CATCH
        PRINT 'Error al importar el archivo CSV: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH

    -- Limpio simbolo $ del importe 
    UPDATE #PagoTemp
    SET Importe = REPLACE(Importe, '$', '');

    -- Elimino espacios en blanco de CVU_CBU por si lo requiere
    UPDATE #PagoTemp
    SET CVU_CBU = LTRIM(RTRIM(CVU_CBU));

    -- Convierto fecha de DD/MM/YYYY a formato YYYY-MM-DD usando estilo 103
	UPDATE #PagoTemp
	SET Fecha = CONVERT(VARCHAR(10), CONVERT(DATE, Fecha, 103), 120);

    -- Inserto datos en la tabla final
    INSERT INTO importacionDeInformacionBancaria.PagoAConsorcio (IDConsorcio, NumeroDeUnidad, Fecha, CVU_CBU, Importe, Ordinario)
    SELECT 
        uf.IdConsorcio,
        uf.NumeroDeUnidad,
        TRY_CONVERT(smalldatetime, pt.Fecha),
        pt.CVU_CBU,
        TRY_CAST(pt.Importe AS DECIMAL(10,2)),
        ( select ABS(CHECKSUM(NEWID())) % 2 )
    FROM #PagoTemp AS pt
    INNER JOIN actualizacionDeDatosUF.UnidadFuncional AS uf
        ON pt.CVU_CBU = uf.CVU_CBU
    WHERE TRY_CAST(pt.Importe AS DECIMAL(10,2)) > 0
      AND NOT EXISTS (
          -- Validacion para evitar duplicados: si el IdPago ya existe, no se inserta
          SELECT 1
          FROM importacionDeInformacionBancaria.PagoAConsorcio AS pa
          WHERE pa.IdPago = pt.IdPago --el IdPago es de la tabla temporal
      );

    -- Mensaje de confirmacion
    PRINT 'Importacion finalizada correctamente';


    -- Limpio tabla temporal
    DROP TABLE #PagoTemp;
END;
GO 

--Ejecucion del SP
EXEC importacionDeInformacionBancaria.ImportarPagosConsorcio '$(Ruta)\$(ArchPagosConsorcio)'
GO