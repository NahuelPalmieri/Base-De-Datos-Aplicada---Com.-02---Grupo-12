drop database AltosDeSaintJust

create database AltosDeSaintJust

use AltosDeSaintJust
go
create schema administrativoGeneral
go

CREATE TABLE administrativoGeneral.Persona
(
	DNI int primary key CHECK(DNI > 999999 AND DNI < 100000000),
	Nombres varchar(30) not null,
	Apellidos varchar(30) not null,
	Email varchar(50),
	NumeroDeTelefono char(10) CHECK(NumeroDeTelefono like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]') not null,
	CVU_CBU char(22) UNIQUE not null,
	Inquilino bit not null
)

CREATE TABLE administrativoGeneral.Propietario --CHARLAR ESTA MODIF DE TABLA (SE VA ID PROPIETARIO, PASA A SER PK/FK DNI)
(
	DNI int primary key,
	CONSTRAINT FK_Propietario FOREIGN KEY (DNI) REFERENCES administrativoGeneral.Persona (DNI)
)

CREATE TABLE administrativoGeneral.Consorcio
(
	IdConsorcio int identity(1,1) primary key,
	NombreDeConsorcio varchar(20),
	Domicilio varchar(30),
	CantUnidadesFuncionales int CHECK(CantUnidadesFuncionales > 0),
	M2Totales int CHECK(M2Totales > 0)
)

CREATE TABLE administrativoGeneral.UnidadFuncional
(
	IdConsorcio int,
	NumeroDeUnidad int,
	DNIPropietario int,
	Piso int NOT NULL,
	Departamento char(1) NOT NULL,
	M2Unidad int CHECK(m2Unidad > 0) NOT NULL,
	CVU_CBU char(22),

	CONSTRAINT PK_UnidadFuncional PRIMARY KEY CLUSTERED (IdConsorcio,NumeroDeUnidad),
	CONSTRAINT FK_UnidadFuncional_Consorcio FOREIGN KEY (IdConsorcio) REFERENCES administrativoGeneral.Consorcio (IdConsorcio),
	CONSTRAINT FK_UnidadFuncional_Persona FOREIGN KEY (DNIPropietario) REFERENCES administrativoGeneral.Propietario (DNI)
)

CREATE TABLE administrativoGeneral.Inquilino --CHARLAR TAMBIEN ESTE CAMBIO DE TABLA
(
	DNI int primary key,
	NroDeConsorcio int,
	NroDeUnidad int,

	CONSTRAINT FK_Inquilino_Persona FOREIGN KEY (DNI) REFERENCES administrativoGeneral.Persona (DNI),
	CONSTRAINT FK_Inquilino_UnidadFuncional FOREIGN KEY (NroDeConsorcio, NroDeUnidad) REFERENCES administrativoGeneral.UnidadFuncional (IdConsorcio, NumeroDeUnidad)
)

CREATE TABLE administrativoGeneral.Baulera
(
	IdBaulera int identity(1,1) primary key,
	IdConsorcio int,
	NumeroUnidad int,
	M2Baulera int CHECK(M2Baulera > 0),

	CONSTRAINT FK_Baulera FOREIGN KEY (IdConsorcio, NumeroUnidad) REFERENCES administrativoGeneral.UnidadFuncional (IdConsorcio, NumeroDeUnidad)
)

CREATE TABLE administrativoGeneral.Cochera
(
	IdCochera int identity(1,1) primary key,
	IdConsorcio int,
	NumeroUnidad int,
	M2Cochera int CHECK(M2Cochera > 0),

	CONSTRAINT FK_Cochera FOREIGN KEY (IdConsorcio, NumeroUnidad) REFERENCES administrativoGeneral.UnidadFuncional (IdConsorcio, NumeroDeUnidad)
)

CREATE TABLE administrativoGeneral.PersonasConError --Esta tabla es para no perder la informacion de los registros mal ingresados o duplicados
(
	Id int identity(1,1) primary key,
	DNI varchar(8),
	Nombres varchar(30),
	Apellidos varchar(30),
	Email varchar(50),
	NumeroDeTelefono char(10),
	CVU_CBU varchar(22),
	Inquilino char(1)
)

go

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

exec administrativoGeneral.importarDatosPersonas @ubicacion='C:\Users\tobia\OneDrive\Desktop\TOBI\TOBI\Bases de Datos Aplicadas\TP-Expensas_consorcio\consorcios\Inquilino-propietarios-datos.csv'

/*
select * from administrativoGeneral.Persona
select * from administrativoGeneral.Propietario
select * from administrativoGeneral.Inquilino

select * from administrativoGeneral.PersonasConError

select p.* from administrativoGeneral.Persona p
join administrativoGeneral.Propietario pro on p.DNI = pro.DNI

select p.* from administrativoGeneral.Persona p
join administrativoGeneral.Inquilino inq on p.DNI = inq.DNI

delete from administrativoGeneral.Propietario
delete from administrativoGeneral.Inquilino
delete from administrativoGeneral.Persona
delete from administrativoGeneral.PersonasConError
*/