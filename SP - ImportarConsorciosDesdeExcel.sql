--PARA CREAR EL STORED PROCEDURE:
CREATE OR ALTER PROCEDURE administrativoGeneral.ImportarConsorciosDesdeExcel
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

    INSERT INTO administrativoGeneral.Consorcio (NombreDeConsorcio, Domicilio, CantUnidadesFuncionales, M2Totales)
    SELECT tc.NombreDeConsorcio, tc.Domicilio, tc.CantUnidadesFuncionales, tc.M2Totales
    FROM #TempConsorcio tc
    WHERE NOT EXISTS (
        SELECT 1 FROM administrativoGeneral.Consorcio c
        WHERE c.NombreDeConsorcio = tc.NombreDeConsorcio AND c.Domicilio = tc.Domicilio
    );

    DROP TABLE #TempConsorcio; --NO ES 100% NECESARIO PERO ME PARECE QUE ESTA BUENO TENERLO POR LAS DUDAS
END;
GO

--PARA EJECUTAR EL STORED PROCEDURE:
EXEC administrativoGeneral.ImportarConsorciosDesdeExcel 'C:\MIEL\datos varios.xlsx';
GO

--PARA PODER VER LO QUE EFECTIVAMENTE SE CARGO:
SELECT * FROM administrativoGeneral.Consorcio;
GO

--ESTABLECER CONFIGURACION PARA USAR Ad Hoc Distributed Queries:
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;