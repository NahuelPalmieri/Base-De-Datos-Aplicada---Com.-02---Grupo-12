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
        Fecha VARCHAR(20),             -- Fecha como texto para transformación 
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
            ROWTERMINATOR = ''\n'',        -- Fin de línea
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

    -- Limpio símbolo $ del importe 
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
          -- Validación para evitar duplicados: si el IdPago ya existe, no se inserta
          SELECT 1
          FROM dbo.PagoAConsorcio AS pa
          WHERE pa.IdPago = pt.IdPago --el IdPago es de la tabla temporal
      );

    -- Mensaje de confirmación
    PRINT 'Importación finalizada correctamente';

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
