--SPs de Importacion
CREATE OR ALTER PROCEDURE administrativoGeneral.ImportarPagosConsorcio
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
    INNER JOIN administrativoGeneral.UnidadFuncional AS uf
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
EXECUTE administrativoGeneral.ImportarPagosConsorcio 
    @RutaArchivo = N'C:\Users\Usuario\OneDrive\Desktop\datos TP DBA\pagos_consorcios.csv';
GO


create or alter trigger InsercionPersona
on administrativoGeneral.Persona
instead of insert
as
begin
	merge into administrativoGeneral.Persona destino
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
create or alter procedure administrativoGeneral.importarDatosPersonas
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
	insert into administrativoGeneral.PersonasConError (DNI, Nombres, Apellidos, Email, NumeroDeTelefono, CVU_CBU, Inquilino)
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

	insert into administrativoGeneral.Persona
	select cast(DNI as int), Nombres, Apellidos, Email, NumeroDeTelefono, CVU_CBU, cast(Inquilino as bit) from #personasCrudoTemp
	where DNI IS NOT NULL or Nombres is not null or Apellidos is not null or NumeroDeTelefono is not null or CVU_CBU is not null or Inquilino is not null --INSERTO MIENTRAS TENGAN LOS CAMPOS NOT NULL DE LA TABLA
	

	insert into administrativoGeneral.Propietario ---Las personas con inquilino = 0 van a la tabla propietarios
	select DNI from administrativoGeneral.Persona per
	where Inquilino = 0
	and not exists(select 1 from administrativoGeneral.Propietario pro where pro.DNI = per.DNI)

	insert into administrativoGeneral.Inquilino (DNI) ---Las personas con inquilino = 1 van a la tabla inquilino
	select DNI from administrativoGeneral.Persona per
	where Inquilino = 1
	and not exists(select 1 from administrativoGeneral.Inquilino inq where inq.DNI = per.DNI)
end


CREATE PROCEDURE Importar_UFxConsorcio 
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
    INSERT INTO dbo.UnidadFuncional (IDConsorcio, NumeroDeUnidad, Piso, Departamento, m2Unidad)
    SELECT con.idConsorcio, UF.NumeroDeUnidad, UF.Piso, UF.Departamento, UF.m2Unidad
    FROM #UFxConsorcioTemp UF
        inner join dbo.Consorcio con ON UF.NombreDeConsorcio = con.NombreDeConsorcio;

    --Insertando datos en Baulera
    INSERT INTO dbo.Baulera (IDConsorcio, NumeroUnidad, metrosCuadrados)
    SELECT con.idConsorcio, UF.NumeroDeUnidad, UF.metrosCuadradosBaulera 
    FROM #UFxConsorcioTemp UF
        inner join dbo.Consorcio con ON UF.NombreDeConsorcio = con.NombreDeConsorcio
    WHERE UF.tieneBauleras = 'SI';

    --Insertando datos en Cochera
    INSERT INTO dbo.Cochera (IDConsorcio, NumeroUnidad, metrosCuadrados)
    SELECT con.idConsorcio, UF.NumeroDeUnidad, UF.metrosCuadradosCochera 
    FROM #UFxConsorcioTemp UF
        inner join dbo.Consorcio con ON UF.NombreDeConsorcio = con.NombreDeConsorcio
    WHERE UF.tieneCocheras = 'SI';

    DROP TABLE #UFxConsorcioTemp;
END