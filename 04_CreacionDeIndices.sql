--======================================
--Creacion de indices para los Reportes
--======================================

--======================
--Indices para reporte 3
--======================

CREATE NONCLUSTERED INDEX IDX_GastoOrdinario
ON actualizacionDeDatosUF.GastoOrdinario (Año, Mes)
INCLUDE (Importe);


CREATE NONCLUSTERED INDEX IDX_GastoServicio
ON actualizacionDeDatosUF.GastoServicio (Año, Mes)
INCLUDE (Importe);

CREATE NONCLUSTERED INDEX IDX_GastoExtraordinario
ON dbo.GastoExtraordinario (Año, Mes)
INCLUDE (Importe);