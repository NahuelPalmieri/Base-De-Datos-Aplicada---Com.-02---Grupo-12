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
USE Com5600G12
--agregar atributo extra a la tabla que tiene el dato que vamos a cifrar
ALTER TABLE actualizacionDeDatosUF.Persona
	ADD 
    CVU_Cifrado VARBINARY(256),
	Email_Cifrado VARBINARY(256),
	NumeroDeTelefono_Cifrado VARBINARY(256);
GO
---
DECLARE @FraseClaveCVU NVARCHAR(128) = 'Clave1234!';
DECLARE @FraseClaveEmail NVARCHAR(128) = 'Clave1234!';
DECLARE @FraseClaveTelefono NVARCHAR(128) = 'Clave1234!';

-- Usamos el UPDATE con la sintaxis correcta
UPDATE actualizacionDeDatosUF.Persona
SET 
    CVU_Cifrado = EncryptByPassPhrase(
        @FraseClaveCVU,
        CVU_CBU, 
        1, 
        CONVERT(varbinary, DNI)
    ),
    Email_Cifrado = EncryptByPassPhrase(
        @FraseClaveEmail,
        Email, 
        1, 
        CONVERT(varbinary, DNI)
    ),
    NumeroDeTelefono_Cifrado = EncryptByPassPhrase(
        @FraseClaveTelefono,
        NumeroDeTelefono, 
        1, 
        CONVERT(varbinary, DNI)
    );
GO

ALTER TABLE actualizacionDeDatosUF.Persona
DROP CONSTRAINT UNQ_CVU;
GO
 
ALTER TABLE actualizacionDeDatosUF.Persona
DROP CONSTRAINT CK_Telefono;
GO

ALTER TABLE actualizacionDeDatosUF.Persona
    DROP COLUMN Email, NumeroDeTelefono,CVU_CBU;
GO

EXEC sp_rename 'actualizacionDeDatosUF.Persona.CVU_Cifrado', 'CVU_CBU', 'COLUMN';
EXEC sp_rename 'actualizacionDeDatosUF.Persona.Email_Cifrado', 'Email', 'COLUMN';
EXEC sp_rename 'actualizacionDeDatosUF.Persona.NumeroDeTelefono_Cifrado', 'NumeroDeTelefono', 'COLUMN';

GO

select * from actualizacionDeDatosUF.Persona

--descrifrar
CREATE OR ALTER PROCEDURE actualizacionDeDatosUF.VerDatosDesencriptados
AS
BEGIN
DECLARE @FraseClaveCVU NVARCHAR(128) = 'Clave1234!';
DECLARE @FraseClaveEmail NVARCHAR(128) = 'Clave1234!';
DECLARE @FraseClaveTelefono NVARCHAR(128) = 'Clave1234!';

SELECT
    DNI,
    Nombres,
    Apellidos,
    -- Convertimos el resultado (que es binario) de vuelta a texto
    CONVERT(char(22), 
        DecryptByPassPhrase(@FraseClaveCVU, CVU_CBU, 1, CONVERT(varbinary, DNI))
    ) AS CVU_CBU,
    CONVERT(varchar(50), 
        DecryptByPassPhrase(@FraseClaveEmail, Email, 1, CONVERT(varbinary, DNI))
    ) AS Email,
    
    CONVERT(char(10), 
        DecryptByPassPhrase(@FraseClaveTelefono, NumeroDeTelefono, 1, CONVERT(varbinary, DNI))
    ) AS NumeroDeTelefono
FROM 
    actualizacionDeDatosUF.Persona
END
GO
--ver tabla persona
EXEC actualizacionDeDatosUF.VerDatosDesencriptados
select * from actualizacionDeDatosUF.Persona