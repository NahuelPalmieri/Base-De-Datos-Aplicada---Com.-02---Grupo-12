--======================================
--Creacion de indices para los Reportes
--======================================

--Para asegurarnos que se ejecute usando la BDD
use Com5600G12

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
ON actualizacionDeDatosUF.GastoExtraordinario (Año, Mes)
INCLUDE (Importe);

--======================
--Indices para reporte 6
--======================
CREATE NONCLUSTERED INDEX IDX_PagoAConsorcio
ON importacionDeInformacionBancaria.PagoAConsorcio(IdConsorcio, NumeroDeUnidad, Fecha)
INCLUDE (Importe);
