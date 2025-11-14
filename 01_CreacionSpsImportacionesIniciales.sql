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

--===============================================================================
          -- DECLARACION Y SETTEO DE VARIABLES PARA LOS PATH:
          -- (Ruta, ArchDatosVarios Y ArchPagosConsorcio)
--===============================================================================
--Para asegurarnos que se ejecute usando la BDD
use Com5600G12

-- PARA HACER USO DE LAS VARIABLES QUE VAMOS A DECLARAR, HACER LOS SIG. PASOS:
-- 1. Dirigirse al apartado consulta.
-- 2. Presionar el boton "Modo SQLCMD"

:SETVAR Ruta "C:\consorcios"
GO
:SETVAR ArchDatosVarios "datos varios.xlsx"
GO

--===============================================================================
    -- CONFIGURACION INICIAL PARA TRABAJAR CON ARCHIVOS DE EXTENSION xlsx
--===============================================================================

-- PARA QUE EL SQL SERVER MANAGEMENT STUDIO PUEDA REALIZAR CON EXITO,
-- SEGUIR LOS SIGUIENTES PASOS:
    -- Dirigirse a la carpeta donde se encuentran los archivos .xlsx
    -- Presionar boton derecho y seleccionar propiedades
    -- Dirigirse a seguridad, y presionar el boton editar
    -- Añadir a la lista el usuario que controla el SSMS
    -- Darle permisos de lectura
    -- Aplicar los cambios y guardar
    -- Seguir los pasos que figuran debajo

--ESTABLECER CONFIGURACION PARA USAR Ad Hoc Distributed Queries:
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO


--===============================================================================
                -- IMPORTACION DE ARCHIVO: datos varios.xlsx
--===============================================================================
                -- IMPORTACION DE CONSORCIOS
--===============================================================================

--PARA CREAR EL STORED PROCEDURE:
CREATE OR ALTER PROCEDURE actualizacionDeDatosUF.ImportarConsorciosDesdeExcel -- DE ACA
    @RutaArchivo NVARCHAR(500)
AS
BEGIN

    CREATE TABLE #TempConsorcio (
        NombreDeConsorcio VARCHAR(20),
        Domicilio VARCHAR(30),
        CantUnidadesFuncionales INT,
        M2Totales INT
    );

    DECLARE @SQL NVARCHAR(MAX);

    SET @SQL = '
    INSERT INTO #TempConsorcio (NombreDeConsorcio, Domicilio, CantUnidadesFuncionales, M2Totales)
    SELECT 
        [Nombre del consorcio], 
        [Domicilio], 
        [Cant unidades funcionales], 
        [m2 totales]
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0;Database=' + @RutaArchivo + ';HDR=YES'',
        ''SELECT * FROM [Consorcios$]''
    );';

    EXEC sp_executesql @SQL;

    DELETE FROM #TempConsorcio WHERE CantUnidadesFuncionales <= 0 OR M2Totales <= 0;

    INSERT INTO actualizacionDeDatosUF.Consorcio (NombreDeConsorcio, Domicilio, CantUnidadesFuncionales, M2Totales)
    SELECT tc.NombreDeConsorcio, tc.Domicilio, tc.CantUnidadesFuncionales, tc.M2Totales
    FROM #TempConsorcio tc
    WHERE NOT EXISTS (
        SELECT 1 FROM actualizacionDeDatosUF.Consorcio c
        WHERE c.NombreDeConsorcio = tc.NombreDeConsorcio AND c.Domicilio = tc.Domicilio
    );

    DROP TABLE #TempConsorcio; --NO ES 100% NECESARIO PERO ME PARECE QUE ESTA BUENO TENERLO POR LAS DUDAS
END;
GO --HASTA ACA

--PARA EJECUTAR EL STORED PROCEDURE:
EXEC actualizacionDeDatosUF.ImportarConsorciosDesdeExcel '$(Ruta)/$(ArchDatosVarios)'
GO

--===============================================================================
                -- IMPORTACION DE ARCHIVO: datos varios.xlsx
--===============================================================================
                -- IMPORTACION DE PROVEEDORES
--===============================================================================

--PARA CREAR EL STORED PROCEDURE:
CREATE OR ALTER PROCEDURE actualizacionDeDatosUF.ImportarProveedoresDesdeExcel --DE ACA
    @RutaArchivo NVARCHAR(500)
AS
BEGIN

    CREATE TABLE #TempProveedores (
        TipoDeServicio NVARCHAR(50)
    );

    DECLARE @SQL NVARCHAR(MAX);

    SET @SQL = '
    INSERT INTO #TempProveedores (TipoDeServicio)
    SELECT 
        F1
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0;Database=' + @RutaArchivo + ';HDR=NO'',
        ''SELECT * FROM [Proveedores$]''
    )
	WHERE F1 IS NOT NULL AND LEN(F1) <= 50;';

    EXEC sp_executesql @SQL;

    INSERT INTO actualizacionDeDatosUF.Proveedor (TipoDeServicio)
    SELECT DISTINCT tP.TipoDeServicio
    FROM #TempProveedores tP;

    DROP TABLE #TempProveedores; --NO ES 100% NECESARIO PERO ME PARECE QUE ESTA BUENO TENERLO POR LAS DUDAS
END;
GO --HASTA ACA

--PARA EJECUTAR EL STORED PROCEDURE:
EXEC actualizacionDeDatosUF.ImportarProveedoresDesdeExcel '$(Ruta)/$(ArchDatosVarios)'
GO


--===============================================================================
                -- IMPORTACION DE ARCHIVO: UF por consorcio.txt                    
--===============================================================================
GO
CREATE OR ALTER PROCEDURE actualizacionDeDatosUF.Importar_UFxConsorcio --DE ACA
    @ruta_archivo varchar(100)
AS BEGIN
    CREATE TABLE #UFxConsorcioTemp (
        NombreDeConsorcio varchar(20),
        NumeroDeUnidad int,
        Piso char(2),
        Departamento char(1),
        coeficiente char(3),
        m2Unidad decimal(5,2) CHECK(m2Unidad > 0),
        tieneBauleras char(2),
        tieneCocheras char(2),
        metrosCuadradosBaulera int CHECK(metrosCuadradosBaulera > 0),
        metrosCuadradosCochera int CHECK(metrosCuadradosCochera > 0)
    );

    DECLARE @ImportarDinamico nvarchar(MAX);

    SET @ImportarDinamico = '
        BULK INSERT #UFxConsorcioTemp
        FROM ''' + @ruta_archivo + '''
        WITH (
            FIELDTERMINATOR = ''\t'',
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2,
            CODEPAGE = ''ACP''
        );
    ';

    EXEC sp_executesql @ImportarDinamico;

    --Insertando datos en UnidadFuncional
    INSERT INTO actualizacionDeDatosUF.UnidadFuncional (IDConsorcio, NumeroDeUnidad, Piso, Departamento, m2Unidad)
    SELECT con.idConsorcio, UF.NumeroDeUnidad, UF.Piso, UF.Departamento, UF.m2Unidad
    FROM #UFxConsorcioTemp UF
        inner join actualizacionDeDatosUF.Consorcio con ON UF.NombreDeConsorcio = con.NombreDeConsorcio;

    --Insertando datos en Baulera
    INSERT INTO actualizacionDeDatosUF.Baulera (IDConsorcio, NumeroUnidad, M2Baulera)
    SELECT con.idConsorcio, UF.NumeroDeUnidad, UF.metrosCuadradosBaulera 
    FROM #UFxConsorcioTemp UF
        inner join actualizacionDeDatosUF.Consorcio con ON UF.NombreDeConsorcio = con.NombreDeConsorcio
    WHERE UF.tieneBauleras = 'SI';

    --Insertando datos en Cochera
    INSERT INTO actualizacionDeDatosUF.Cochera (IDConsorcio, NumeroUnidad, M2Cochera)
    SELECT con.idConsorcio, UF.NumeroDeUnidad, UF.metrosCuadradosCochera 
    FROM #UFxConsorcioTemp UF
        inner join actualizacionDeDatosUF.Consorcio con ON UF.NombreDeConsorcio = con.NombreDeConsorcio
    WHERE UF.tieneCocheras = 'SI';

    DROP TABLE #UFxConsorcioTemp;
END --HASTA ACA
GO

--EJECUCION DEL STORED PROCEDURE
EXEC actualizacionDeDatosUF.Importar_UFxConsorcio '$(Ruta)/$(ArchUFPorConsorcio)'
GO