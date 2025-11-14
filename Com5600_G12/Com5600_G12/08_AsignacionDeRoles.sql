/********************************************************************************
	Trabajo Practico Integrador - Bases de Datos Aplicadas (2? Cuatrimestre 2025)
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

--Para asegurarnos que se ejecute usando la BDD
use Com5600G12
GO

--================================================================
	--Creacion de Logins
--=================================================================
CREATE LOGIN usuarioAdminGeneral 
	WITH PASSWORD = 'grupo12_AG';

CREATE LOGIN usuarioAdminBancario
	WITH PASSWORD = 'grupo12_AB';

CREATE LOGIN usuarioAdminOperativo 
	WITH PASSWORD = 'grupo12_AO';

CREATE LOGIN usuarioSistema
	WITH PASSWORD = 'grupo12_S';

--================================================================
	--Creacion de Roles
--=================================================================

CREATE ROLE administrativo_general;
GO

CREATE ROLE administrativo_bancario;
GO

CREATE ROLE administrativo_operativo;
GO

CREATE ROLE rol_sistemas;
GO


--================================================================
	--Asignacion de Permisos a Roles
--=================================================================

GRANT SELECT, INSERT, UPDATE, DELETE
ON SCHEMA::actualizacionDeDatosUF
TO administrativo_general, administrativo_operativo;
GO