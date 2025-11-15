--=======================
--Politicas de respaldo
--======================

/*
El sistema de consorcios gestiona informacion sensible como pagos, intereses, deudas y cálculos
mensuales de expensas, por lo que se requiere uno politica de respaldo que garantice disponibi
lidad, integridad y recuperabilidad ante cualquier incidente.

El modelo de recuperació que se adoptará sera el Modelo de recuperación FULL, que permite regis
trar todas las transacciones realizadas en la base de datos y restaurarla en un punto especifico
del tiempo. Este modelo es el más adecuado para entornos donde la perdida de datos es inaceptable.

Programa de respaldos (SCHEDULE)

--======================================================================================
--Tipo de respaldo				| Frecuencia	  | Horario | Contenido respaldado
--=======================================================================================
Back up FULL					|Semanal (Dom)	  | 23hs	| Base de datos completa
Back up diferencial				|Diario(Lun a Sab)| 22hs	| cambios desde ultimo FULL
Back up de Log de transacciones |cada 40 minutos  |9h a 18h | Registro de transacciones

Recovery Point Objetive (RPO)
Se establece en 40 minutos, lo que significa que ante una falla, la perdida máxima de datos 
será de 40 minutos. Este valor es adecuado para el ritmo operativo de un consorcio, donde las
transacciones son importantes pero no masivas por hora. 

Buenas practicas Complementarias
Separacion fisica de respaldos: los respaldos se van a almacenar en medios distintos, evitando 
que una falla afecte tanto a la base de datos como a sus copias.

Estrategia 3-2-1: Se matendra 3 copias de los datos, en 2 tipos de medios distintos, 1 copia
fuera del entorno local (Nube).

Pruebas de restauracion trimestral: Se realizaran simulaciones de recuperacion en entornos de 
prueba para garantizar que el procedimiento sea efectivo y seguro. 

Conclusión: 
Esta politica permite proteger los datos criticos del sistema de consorcios, asegurando que 
los calculos de expensas, pagos registrados y reportes generados esten siempre disponibles y 
recuperables. Además se alinea con los principios de protección visto en clases como el uso 
Modelo FULL, la gestión del Log de transacciones y la aplicación de buenas practicas como la
estrategia 3-2-1. 

*/