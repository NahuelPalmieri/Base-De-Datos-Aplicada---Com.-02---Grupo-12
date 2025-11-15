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
	Email_Cifrado VARBINARY(256),
	NumeroDeTelefono_Cifrado VARBINARY(256);
GO

---
DECLARE @FraseClaveEmail NVARCHAR(128) = 'Clave1234!';
DECLARE @FraseClaveTelefono NVARCHAR(128) = 'Clave1234!';

-- Usamos el UPDATE con la sintaxis correcta
UPDATE actualizacionDeDatosUF.Persona
SET 
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
/*
--descrifrar
DECLARE @FraseClaveEmail NVARCHAR(128) = 'Clave1234!';
DECLARE @FraseClaveTelefono NVARCHAR(128) = 'Clave1234!';

SELECT
    DNI,
    Nombres,
    Apellidos,
    -- Convertimos el resultado (que es binario) de vuelta a texto
    CONVERT(varchar(50), 
        DecryptByPassPhrase(@FraseClaveEmail, Email_Cifrado, 1, CONVERT(varbinary, DNI))
    ) AS Email_Cifrado,
    
    CONVERT(char(10), 
        DecryptByPassPhrase(@FraseClaveTelefono, NumeroDeTelefono_Cifrado, 1, CONVERT(varbinary, DNI))
    ) AS NumeroDeTelefono_Cifrado
    
FROM 
    actualizacionDeDatosUF.Persona
*/
--ver tabla persona
--select * from actualizacionDeDatosUF.Persona