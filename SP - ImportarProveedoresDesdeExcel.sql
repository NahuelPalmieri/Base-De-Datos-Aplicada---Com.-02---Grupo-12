--ESTABLECER CONFIGURACION PARA USAR Ad Hoc Distributed Queries:
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;

--PARA CREAR EL STORED PROCEDURE:
CREATE OR ALTER PROCEDURE dbo.ImportarProveedoresDesdeExcel
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

    INSERT INTO dbo.Proveedor (TipoDeServicio)
    SELECT DISTINCT tP.TipoDeServicio
    FROM #TempProveedores tP;

    DROP TABLE #TempProveedores; --NO ES 100% NECESARIO PERO ME PARECE QUE ESTA BUENO TENERLO POR LAS DUDAS
END;
GO

--PARA EJECUTAR EL STORED PROCEDURE:
EXEC dbo.ImportarProveedoresDesdeExcel 'C:\MIEL\datos varios.xlsx';
GO

--PARA PODER VER LO QUE EFECTIVAMENTE SE CARGO:
SELECT * FROM dbo.Proveedor;
GO