USE AltosDeSaintJust;
GO

CREATE OR ALTER PROCEDURE Importar_Inquilino_Propietarios_UF

		@ruta_archivo varchar(MAX)
AS 
BEGIN 
		--1.Creo una tabla temporal 
		CREATE TABLE #TempInqPropUF 
		(
			CVU_CBU char(22),
			NombreDeConsorcio varchar(20),
			NumeroDeUnidad int,
			Piso char(2),
			Departamento char(1)
		);

		--2. Armo y ejecuto el BULK INSERT para importar el archivo en la tabla temporal
		DECLARE @cadena nvarchar(MAX);

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

		--3.Actualizo la tabla Unidad Funcional cargando los CVU_CBU y los Id de propietarios.
		UPDATE UF
		SET	
			UF.CVU_CBU		 = T.CVU_CBU,
			UF.IdPropietario = P.IdPropietario
		FROM administrativoGeneral.UnidadFuncional AS UF
		INNER JOIN administrativoGeneral.Consorcio AS C
			ON C.IdConsorcio = UF.IdConsorcio
		INNER JOIN #TempInqPropUF AS T
			ON C.NombreDeConsorcio  = T.NombreDeConsorcio
			AND UF.NumeroDeUnidad   = T.NumeroDeUnidad
			AND UF.Piso				= T.Piso
			AND UF.Departamento		= T.Departamento 
		INNER JOIN administrativoGeneral.Persona AS Pe
			ON Pe.CVU_CBU = T.CVU_CBU
		INNER JOIN administrativoGeneral.Propietario AS P
			ON P.DNI = Pe.DNI;									

		--4. Actualizo la tabla Inquilino cargando el Nro de Consorcio y el Nro de Unidad.
		UPDATE IQ
		SET
			IQ.NroDeConsorcio = C.IdConsorcio,
			IQ.NroDeUnidad	  = T.NumeroDeUnidad
		FROM administrativoGeneral.Inquilino AS IQ
		INNER JOIN administrativoGeneral.Persona AS PE
			ON IQ.DNI = PE.DNI							
		INNER JOIN #TempInqPropUF as T					
			ON PE.CVU_CBU = T.CVU_CBU
		INNER JOIN administrativoGeneral.Consorcio AS C
			ON T.NombreDeConsorcio = C.NombreDeConsorcio
 
		--5. Elimino la tabla temporal
		DROP TABLE #TempInqPropUF;

END;

	