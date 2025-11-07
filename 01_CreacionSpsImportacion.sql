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


--===============================================================================
                -- IMPORTACION DE ARCHIVO: datos varios.xlsx
--===============================================================================
                -- IMPORTACION DE CONSORCIOS
--===============================================================================

--PARA CREAR EL STORED PROCEDURE:
CREATE OR ALTER PROCEDURE actualizacionDeDatosUF.ImportarConsorciosDesdeExcel
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
GO

--PARA EJECUTAR EL STORED PROCEDURE:
EXEC actualizacionDeDatosUF.ImportarConsorciosDesdeExcel 'C:\consorcios\datos varios.xlsx';
GO

--PARA PODER VER LO QUE EFECTIVAMENTE SE CARGO:
SELECT * FROM actualizacionDeDatosUF.Consorcio;
GO

--ESTABLECER CONFIGURACION PARA USAR Ad Hoc Distributed Queries:
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;


--===============================================================================
                -- IMPORTACION DE ARCHIVO: datos varios.xlsx
--===============================================================================
                -- IMPORTACION DE PROVEEDORES
--===============================================================================

--PARA CREAR EL STORED PROCEDURE:
CREATE OR ALTER PROCEDURE actualizacionDeDatosUF.ImportarProveedoresDesdeExcel
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
GO

--PARA EJECUTAR EL STORED PROCEDURE:
EXEC actualizacionDeDatosUF.ImportarProveedoresDesdeExcel 'C:\consorcios\datos varios.xlsx';
GO

--PARA PODER VER LO QUE EFECTIVAMENTE SE CARGO:
SELECT * FROM actualizacionDeDatosUF.Proveedor;
GO

--===============================================================================
                -- IMPORTACION DE ARCHIVO: pagos_consorcios.csv
--===============================================================================
 

--SPs de Importacion
CREATE OR ALTER PROCEDURE actualizacionDeDatosUF.ImportarPagosConsorcio
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
        Fecha VARCHAR(20),             -- Fecha como texto para transformaci�n 
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
            ROWTERMINATOR = ''\n'',        -- Fin de l�nea
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

    -- Limpio s�mbolo $ del importe 
    UPDATE #PagoTemp
    SET Importe = REPLACE(Importe, '$', '');

    -- Elimino espacios en blanco de CVU_CBU por si lo requiere
    UPDATE #PagoTemp
    SET CVU_CBU = LTRIM(RTRIM(CVU_CBU));

    -- Convierto fecha de DD/MM/YYYY a formato YYYY-MM-DD usando estilo 103
	UPDATE #PagoTemp
	SET Fecha = CONVERT(VARCHAR(10), CONVERT(DATE, Fecha, 103), 120);

    -- Inserto datos en la tabla final
    INSERT INTO dbo.PagoAConsorcio (IDConsorcio, NumeroDeUnidad, Fecha, CVU_CBU, Importe)
    SELECT 
        uf.IdConsorcio,
        uf.NumeroDeUnidad,
        TRY_CONVERT(smalldatetime, pt.Fecha),
        pt.CVU_CBU,
        TRY_CAST(pt.Importe AS DECIMAL(10,2))
    FROM #PagoTemp AS pt
    INNER JOIN actualizacionDeDatosUF.UnidadFuncional AS uf
        ON pt.CVU_CBU = uf.CVU_CBU
    WHERE TRY_CAST(pt.Importe AS DECIMAL(10,2)) > 0
      AND NOT EXISTS (
          -- Validaci�n para evitar duplicados: si el IdPago ya existe, no se inserta
          SELECT 1
          FROM dbo.PagoAConsorcio AS pa
          WHERE pa.IdPago = pt.IdPago --el IdPago es de la tabla temporal
      );

    -- Mensaje de confirmaci�n
    PRINT 'Importaci�n finalizada correctamente';

    --Verifico que los datos del Csv se cargaron en la tabla temporal
    SELECT * FROM #PagoTemp;

    -- Limpio tabla temporal
    DROP TABLE #PagoTemp;
END;
GO

--Ejecucion del SP
EXECUTE actualizacionDeDatosUF.ImportarPagosConsorcio 
    @RutaArchivo = 'C:\consorcios\pagos_consorcios.csv';
GO

--===============================================================================
                -- IMPORTACION DE ARCHIVO: inquilino-propietarios-datos.csv
--===============================================================================


create or alter trigger actualizacionDeDatosUF.InsercionPersona
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
create or alter procedure actualizacionDeDatosUF.importarDatosPersonas
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

	declare @CadenaSQL nvarchar(MAX) --necesito que sea NVARCHAR para poder usar el sp_executesql

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

	select * from #personasCrudoTemp

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
	or p.DNI is null or p.Nombres is null or p.Apellidos is null or p.NumeroDeTelefono is null or p.CVU_CBU is null or p.Inquilino is null
	or Patindex('%[^A-Za-z ]%', p.Nombres)>0 or Patindex('%[^A-Za-z ]%', p.Apellidos)>0

	;with Duplicados(DNI, Apariciones) as(
		select DNI, count(DNI) over(partition by DNI) as apariciones
		from #personasCrudoTemp
	)
	delete from #personasCrudoTemp 
	where exists(select 1 from Duplicados d where #personasCrudoTemp.DNI = d.DNI and d.Apariciones>1) --SI HAY DUPLICADOS LOS ELIMINO
	or Patindex('%[^A-Za-z ]%', #personasCrudoTemp.Nombres)>0 or Patindex('%[^A-Za-z ]%', #personasCrudoTemp.Apellidos)>0 --SI HAY ALGUN NOMBRE O APELLIDO INVALIDO TAMBIEN

	insert into actualizacionDeDatosUF.Persona
	select cast(DNI as int), Nombres, Apellidos, Email, NumeroDeTelefono, CVU_CBU, cast(Inquilino as bit) from #personasCrudoTemp
	where DNI IS NOT NULL or Nombres is not null or Apellidos is not null or NumeroDeTelefono is not null or CVU_CBU is not null or Inquilino is not null --INSERTO MIENTRAS TENGAN LOS CAMPOS NOT NULL DE LA TABLA
	

	insert into actualizacionDeDatosUF.Propietario ---Las personas con inquilino = 0 van a la tabla propietarios
	select DNI from actualizacionDeDatosUF.Persona per
	where Inquilino = 0
	and not exists(select 1 from actualizacionDeDatosUF.Propietario pro where pro.DNI = per.DNI)

	insert into actualizacionDeDatosUF.Inquilino (DNI) ---Las personas con inquilino = 1 van a la tabla inquilino
	select DNI from actualizacionDeDatosUF.Persona per
	where Inquilino = 1
	and not exists(select 1 from actualizacionDeDatosUF.Inquilino inq where inq.DNI = per.DNI)
end

exec actualizacionDeDatosUF.importarDatosPersonas 
@ubicacion='C:\consorcios\Inquilino-propietarios-datos.csv'

/*
select * from actualizacionDeDatosUF.Persona
select * from actualizacionDeDatosUF.Propietario
select * from actualizacionDeDatosUF.Inquilino

select * from actualizacionDeDatosUF.PersonasConError
*/


--===============================================================================
                -- IMPORTACION DE ARCHIVO: UF por consorcio.txt
--===============================================================================
 GO
CREATE OR ALTER PROCEDURE actualizacionDeDatosUF.Importar_UFxConsorcio 
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
END

EXEC actualizacionDeDatosUF.Importar_UFxConsorcio 
@ruta_archivo='C:\consorcios\UF por consorcio.txt'

EXEC xp_servicecontrol 'QUERYSTATE', 'MSSQLSERVER';

--===============================================================================
                -- IMPORTACION DE ARCHIVO: Inquilino-propietarios-UF.csv
--===============================================================================
 GO
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
 
		DROP TABLE #TempInqPropUF; --5. Elimino la tabla temporal
END;

exec actualizacionDeDatosUF.Importar_Inquilino_Propietarios_UF @ruta_archivo 
='C:\consorcios\Inquilino-propietarios-UF.csv'


--===============================================================================
                -- IMPORTACION DE ARCHIVO: Servicios.Servcios.json
--===============================================================================
GO
CREATE OR ALTER PROCEDURE actualizacionDeDatosUF.ImportarServiciosServicios
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
    SELECT * 
    FROM #tempServicios

END
GO

exec actualizacionDeDatosUF.ImportarServiciosServicios 'C:\consorcios\Servicios.Servicios.json'
