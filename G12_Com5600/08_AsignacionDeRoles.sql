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
--cuando inicies sesion con un rol, poner la conexion en opcional, NO ENCRIPTADO
--================================================================
	--Creacion de Logins -- a nivel servidor
--=================================================================
use master
GO

CREATE LOGIN AdminGeneral
WITH PASSWORD = '<1234>';

CREATE LOGIN AdminBancario
WITH PASSWORD = '<1234>';

CREATE LOGIN AdminOperativo
WITH PASSWORD = '<1234>';

CREATE LOGIN AdminSistemas
WITH PASSWORD = '<1234>';

GO
--scripst para endurecer las contraseñas (pedido requerido de Microsoft)
GO
ALTER LOGIN AdminGeneral
WITH PASSWORD = 'UnaClaveFuerte123!';

ALTER LOGIN AdminBancario
WITH PASSWORD = 'UnaClaveFuerte123!';

ALTER LOGIN AdminOperativo
WITH PASSWORD = 'UnaClaveFuerte123!';

ALTER LOGIN AdminSistemas
WITH PASSWORD = 'UnaClaveFuerte123!';
GO
--================================================================
	--Creacion de Usuarios -- a nivel base de datos
--=================================================================
use Com5600G12
GO

CREATE USER AdminGeneral FOR LOGIN AdminGeneral

CREATE USER AdminBancario FOR LOGIN AdminBancario

CREATE USER AdminOperativo FOR LOGIN AdminOperativo

CREATE USER AdminSistemas FOR LOGIN AdminSistemas

GO
--================================================================
	--Creacion de Roles
--=================================================================

CREATE ROLE Rol_administrativo_general;
GO

CREATE ROLE Rol_administrativo_bancario;
GO

CREATE ROLE Rol_administrativo_operativo;
GO

CREATE ROLE Rol_administrativo_sistemas;
GO

--================================================================
	--Agregado de usuarios a Roles
--=================================================================
GO
ALTER ROLE Rol_administrativo_general ADD MEMBER AdminGeneral
GO

ALTER ROLE Rol_administrativo_bancario ADD MEMBER AdminBancario
GO

ALTER ROLE Rol_administrativo_operativo ADD MEMBER AdminOperativo
GO

ALTER ROLE Rol_administrativo_sistemas ADD MEMBER AdminSistemas
GO

--================================================================
	--Asignacion de Permisos a Roles
--=================================================================

GRANT SELECT, INSERT, UPDATE, DELETE, EXEC
ON SCHEMA::actualizacionDeDatosUF
TO Rol_administrativo_general, Rol_administrativo_operativo;
GO

GRANT SELECT, INSERT, UPDATE, DELETE, EXEC
ON SCHEMA::generacionDeReportes
TO Rol_administrativo_general, Rol_administrativo_operativo, 
	Rol_administrativo_sistemas, Rol_administrativo_bancario;
GO

GRANT SELECT, INSERT, UPDATE, DELETE
ON SCHEMA::importacionDeInformacionBancaria
TO Rol_administrativo_bancario;
GO

--================================================================
	--TEST
--=================================================================

--ejemplo adminGeneral
--deberia poder ver esta
select * from actualizacionDeDatosUF.UnidadFuncional
--esta no
select * from importacionDeInformacionBancaria.EstadoDeCuenta

--ejemplo adminOperativo
select * from actualizacionDeDatosUF.UnidadFuncional
--esta no
select * from importacionDeInformacionBancaria.EstadoDeCuenta

--ejemplo adminSist
--estas si
EXEC generacionDeReportes.ObtenerTopMorosos
--esta no
select * from actualizacionDeDatosUF.UnidadFuncional
select * from importacionDeInformacionBancaria.EstadoDeCuenta

--ejemplo adminBancario
--esta no
select * from actualizacionDeDatosUF.UnidadFuncional
--esta si
select * from importacionDeInformacionBancaria.EstadoDeCuenta
