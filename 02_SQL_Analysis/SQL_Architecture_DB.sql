/*
PROJECT: Peru Macro-Econometrics Data Engine
AUTHOR: Aaron Olmedo López
DESCRIPTION: ETL process to clean and unify BCRP (Macro) and INEI (Social) indicators.
*/

CREATE DATABASE PeruMacroEconometrics;
GO

USE PeruMacroEconometrics;
GO


-- Create a data model table to unify the indicators
    -- DIMS (Filters) 
CREATE TABLE Dim_Calendario (
    Fecha DATE PRIMARY KEY,
    Anio INT,
    Mes INT
);

CREATE TABLE Dim_Geografia (
    ID_Region INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_Region VARCHAR(100) UNIQUE
);
 
    -- FACTS 
CREATE TABLE Fact_Macro_Mensual (
    Fecha DATE,
    Inflacion DECIMAL(10,4),
    PBI DECIMAL(10,4),
    Tasa_Referencia DECIMAL(10,4),
    RIN DECIMAL(18,2),
    Gasto_Gobierno DECIMAL(18,2),
    CONSTRAINT FK_Macro_Calendario FOREIGN KEY (Fecha) REFERENCES Dim_Calendario(Fecha)
);

CREATE TABLE Fact_Social_Anual (
    Anio INT,
    ID_Region INT,
    Tasa_Pobreza DECIMAL(10,4),
    Gasto_Real DECIMAL(18,2),
    Gasto_Nominal DECIMAL(18,2),
    CONSTRAINT FK_Social_Geo FOREIGN KEY (ID_Region) REFERENCES Dim_Geografia(ID_Region)
);

CREATE TABLE Fact_Informalidad (
    Anio INT,
    ID_Region INT,
    Tasa_Informalidad DECIMAL(10,4),
    CONSTRAINT FK_Info_Geo FOREIGN KEY (ID_Region) REFERENCES Dim_Geografia(ID_Region)
);
GO


SELECT * FROM stg_BCRP_Inflacion
EXEC sp_rename 'stg_BCRP_Inflacion.Periodo', 'Period', 'COLUMN';
EXEC sp_rename 'stg_BCRP_Inflacion.Inflacion_Prc', 'Inflation_Rate', 'COLUMN';

SELECT * FROM stg_BCRP_PBI
EXEC sp_rename 'stg_BCRP_PBI.Periodo', 'Period', 'COLUMN';
EXEC sp_rename 'stg_BCRP_PBI.Producto_bruto_interno_y_demanda_interna_variación_porcentual_interanual_PBI', 'GDP_Var_Rate', 'COLUMN';

SELECT * FROM stg_BCRP_Tasa_Referencia
DELETE FROM stg_BCRP_Tasa_Referencia WHERE column1 LIKE '%Periodo%';
EXEC sp_rename 'stg_BCRP_Tasa_Referencia.Periodo', 'Period', 'COLUMN';
EXEC sp_rename 'stg_BCRP_Tasa_Referencia.Tasas_de_interés_del_Banco_Central_de_Reserva_Tasa_de_Referencia_de_la_Política_Monetaria', 'Reference_Rate', 'COLUMN';

SELECT * FROM stg_BCRP_RIN
DELETE FROM stg_BCRP_RIN WHERE column1 LIKE '%Periodo%';
EXEC sp_rename 'stg_BCRP_RIN.Periodo', 'Period', 'COLUMN';
EXEC sp_rename 'stg_BCRP_RIN.Column2', 'Net_Int_Reserves_MUSD', 'COLUMN';

SELECT * FROM stg_BCRP_GastoNoFinanciero
EXEC sp_rename 'stg_BCRP_GastoNoFinanciero.Periodo', 'Period', 'COLUMN';
EXEC sp_rename 'stg_BCRP_GastoNoFinanciero.Gastos_del_gobierno_central_millones_S_Resultado_Primario_Gastos_No_Financieros', 'Gov_Spending_MSoles', 'COLUMN';

SELECT * FROM stg_INEI_Informalidad
EXEC sp_rename 'stg_INEI_Informalidad.Periodo', 'Period', 'COLUMN';
EXEC sp_rename 'stg_INEI_Informalidad.Tasa_Informalidad_Porcentaje', 'Informality_Rate', 'COLUMN';

SELECT * FROM stg_INEI_Pobreza_dptos
EXEC sp_rename 'stg_INEI_Pobreza_dptos.Region', 'Department', 'COLUMN';
EXEC sp_rename 'stg_INEI_Pobreza_dptos.Periodo', 'Period', 'COLUMN';
EXEC sp_rename 'stg_INEI_Pobreza_dptos.Tasa_Pobreza','Poverty_Rate', 'COLUMN';

SELECT * FROM stg_INEI_Map_Informalidad_dptos
EXEC sp_rename 'stg_INEI_Map_Informalidad_dptos.Region', 'Department', 'COLUMN';   
EXEC sp_rename 'stg_INEI_Map_Informalidad_dptos.Periodo', 'Period', 'COLUMN';
EXEC sp_rename 'stg_INEI_Map_Informalidad_dptos.Tasa_Informalidad', 'Informality_Rate', 'COLUMN';

SELECT * FROM stg_INEI_GastoHogares_dptos
EXEC sp_rename 'stg_INEI_GastoHogares_dptos.Region', 'Department', 'COLUMN';
EXEC sp_rename 'stg_INEI_GastoHogares_dptos.Periodo', 'Period', 'COLUMN';
EXEC sp_rename 'stg_INEI_GastoHogares_dptos.Gasto_Real_Mensual_PerCapita', 'Real_Household_Exp', 'COLUMN';
EXEC sp_rename 'stg_INEI_GastoHogares_dptos.Gasto_Nominal_Mensual_PerCapita', 'Nominal_Household_Exp', 'COLUMN';



