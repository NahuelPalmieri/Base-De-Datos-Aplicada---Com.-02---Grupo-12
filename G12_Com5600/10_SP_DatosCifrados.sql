/********************************************************************************
	Trabajo Practico Integrador - Bases de Datos Aplicadas (2º Cuatrimestre 2025)
	Generacion de Reportes
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

--Para asegurarnos que se ejecute usando la BDD
use Com5600G12
GO
--===========================================================================================
    -- REPORTE 5: Obtenga los 3 (tres) propietarios con mayor morosidad. Presente informaci?n de contacto y
	--DNI de los propietarios para que la administraci?n los pueda contactar o remitir el tr?mite al
	--estudio jur?dico.
--===========================================================================================

CREATE OR ALTER PROCEDURE generacionDeReportes.ObtenerTopMorosos
    --Defino valores por defecto (de respaldo)
	@TopN int = 3,
    @IDConsorcio int = NULL,
    @MinDeuda decimal(10, 2) = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FraseClaveEmail NVARCHAR(128) = 'Clave1234!';
    DECLARE @FraseClaveTelefono NVARCHAR(128) = 'Clave1234!';

    SELECT TOP (@TopN) --los primeros N
        p.DNI,
        per.Nombres, 
        per.Apellidos,
        CONVERT(varchar(50), 
        DecryptByPassPhrase(@FraseClaveEmail, per.Email, 1, CONVERT(varbinary, p.DNI))
        ) AS Email,
        CONVERT(char(10), 
        DecryptByPassPhrase(@FraseClaveTelefono, per.NumeroDeTelefono, 1, CONVERT(varbinary, p.DNI))
        ) AS NumeroDeTelefono,    
        SUM(ec.Deuda) AS TotalDeuda
    FROM 
	--arranco con los joins entre las tablas Estado Cuenta, UF, propietario y persona
    
	importacionDeInformacionBancaria.EstadoDeCuenta AS ec
    JOIN 
        actualizacionDeDatosUF.UnidadFuncional AS uf 
        ON ec.IDConsorcio = uf.IDConsorcio 
        AND ec.NumeroDeUnidad = uf.NumeroDeUnidad
    JOIN 
        actualizacionDeDatosUF.Propietario AS p 
        ON uf.DNIPropietario = p.DNI
    JOIN
        actualizacionDeDatosUF.Persona AS per 
        ON p.DNI = per.DNI
        
    WHERE 
        --dejo el filtro para el parametro de minimo
        (@IDConsorcio IS NULL OR ec.IDConsorcio = @IDConsorcio)
        AND ec.Deuda < @MinDeuda
        
    GROUP BY 
        -- agrupamos por persona (por si hay alguna persona con mas de una UF con deudas)
        p.DNI, 
        per.Nombres,
        per.Apellidos,
        per.NumeroDeTelefono, 
        per.Email
        
    ORDER BY 
        -- ordenamos por la deuda total (es asc, porque contamos la deuda en negatibo)
        TotalDeuda ASC;
END
GO

EXEC generacionDeReportes.ObtenerTopMorosos 3

select * from actualizacionDeDatosUF.Persona
select * from actualizacionDeDatosUF.Propietario
select * from actualizacionDeDatosUF.Consorcio
select * from actualizacionDeDatosUF.UnidadFuncional
