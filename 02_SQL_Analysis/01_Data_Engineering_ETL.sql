/*
PROJECT: Peru Macro-Econometrics Data Engine
AUTHOR: Aaron Olmedo López
DESCRIPTION: Creating the data architecture for the Peru Macro-Econometrics Data Engine, 
including database creation, staging tables for raw data, and dimensional modeling for unified
macroeconomic and regional development indicators.
*/

CREATE DATABASE PeruMacroEconometrics;
GO

USE PeruMacroEconometrics;
GO


ALTER AUTHORIZATION ON DATABASE::PeruMacroEconometrics TO sa;
GO


-- Importing data from CSV files into staging tables

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


-- Create TABLE for unified macroeconomic indicators
	
	-- Geography Dimension
DROP TABLE IF EXISTS Dim_Department;
CREATE TABLE Dim_Department (
	DepartmentID INT IDENTITY (1,1) PRIMARY KEY,
	Department_Name NVARCHAR(100) UNIQUE,
    Location_Type VARCHAR(50)
);

SELECT COLUMN_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Dim_Department';


	-- Time Dimension
DROP TABLE IF EXISTS Dim_Calendar;
CREATE TABLE Dim_Calendar (
	Date_Key DATE PRIMARY KEY, 
	Year_Num INT,
	Month_Num INT,
	Month_Name VARCHAR(20)
);

-- Monthly Macroeconomic Facts
DROP TABLE IF EXISTS Fact_Macro_Indicators;
CREATE TABLE Fact_Macro_Indicators (
    Date_Key DATE,
    Inflation_Rate DECIMAL(10,4),
    GDP_Var_Rate DECIMAL(10,4),
    Reference_Rate DECIMAL(10,4),
    Net_Int_Reserves_MUSD DECIMAL(18,2),
    Gov_Spending_MSoles DECIMAL(18,2),
    CONSTRAINT FK_Macro_Calendar FOREIGN KEY (Date_Key) REFERENCES Dim_Calendar(Date_Key)
);

-- Annual Social & Regional Facts
DROP TABLE IF EXISTS Fact_Regional_Development;
CREATE TABLE Fact_Regional_Development (
    Year_Num INT,
    DepartmentID INT,
    Poverty_Rate DECIMAL(10,4),
    Informality_Rate DECIMAL(10,4),
    Real_Household_Exp DECIMAL(18,2),
    Nominal_Household_Exp DECIMAL(18,2),
    CONSTRAINT FK_Regional_Dept FOREIGN KEY (DepartmentID) REFERENCES Dim_Department(DepartmentID)
);
GO


-- **Insert data into TABLES**

USE PeruMacroEconometrics
GO

-- Insert data into Dim_Department 
INSERT INTO Dim_Department (Department_Name, Location_Type)
SELECT DISTINCT Department, 'Department'
FROM stg_INEI_Pobreza_dptos
WHERE Department NOT IN ('Nacional', 'Urbano', 'Rural', 'Urbana') 
  AND Department IS NOT NULL;

INSERT INTO Dim_Department (Department_Name, Location_Type)
VALUES 
('Nacional', 'National'),
('Urbana', 'Area'),
('Rural', 'Area');
GO


-- Insert data into Dim_Calendar 
DECLARE @StartDate DATE = '2000-01-01';
DECLARE @EndDate DATE = '2026-12-31';
WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO Dim_Calendar (Date_Key, Year_Num, Month_Num, Month_Name)
    SELECT @StartDate, YEAR(@StartDate), MONTH(@StartDate), DATENAME(MONTH, @StartDate);
    SET @StartDate = DATEADD(MONTH, 1, @StartDate);
END;
GO

-- Insert data into Fact_Macro_Indicators
DELETE FROM Fact_Macro_Indicators;

INSERT INTO Fact_Macro_Indicators (Date_Key, Inflation_Rate, GDP_Var_Rate, Reference_Rate, Net_Int_Reserves_MUSD, Gov_Spending_MSoles)
SELECT 
    CAST('20' + RIGHT(inf.Period, 2) + '-' + 
        CASE LEFT(inf.Period, 3)
            WHEN 'Ene' THEN '01' WHEN 'Feb' THEN '02' WHEN 'Mar' THEN '03'
            WHEN 'Abr' THEN '04' WHEN 'May' THEN '05' WHEN 'Jun' THEN '06'
            WHEN 'Jul' THEN '07' WHEN 'Ago' THEN '08' WHEN 'Sep' THEN '09'
            WHEN 'Oct' THEN '10' WHEN 'Nov' THEN '11' WHEN 'Dic' THEN '12'
        END + '-01' AS DATE) as Date_Key,
    TRY_CAST(inf.Inflation_Rate AS DECIMAL(10,4)),
    TRY_CAST(pbi.GDP_Var_Rate AS DECIMAL(10,4)),
    TRY_CAST(tr.Reference_Rate AS DECIMAL(10,4)),
    TRY_CAST(rin.Net_Int_Reserves_MUSD AS DECIMAL(18,2)),
    TRY_CAST(gs.Gov_Spending_MSoles AS DECIMAL(18,2))
FROM stg_BCRP_Inflacion inf
LEFT JOIN stg_BCRP_PBI pbi ON inf.Period = pbi.Period
LEFT JOIN stg_BCRP_Tasa_Referencia tr ON inf.Period = tr.Period
LEFT JOIN stg_BCRP_RIN rin ON inf.Period = rin.Period
LEFT JOIN stg_BCRP_GastoNoFinanciero gs ON inf.Period = gs.Period;
GO

-- Insert data into Fact_Regional_Development
INSERT INTO Fact_Regional_Development (Year_Num, DepartmentID, Poverty_Rate, Informality_Rate, Real_Household_Exp, Nominal_Household_Exp)
SELECT 
    CAST(pob.Period AS INT), 
    d.DepartmentID,
    TRY_CAST(pob.Poverty_Rate AS DECIMAL(10,4)),
    TRY_CAST(inf.Informality_Rate AS DECIMAL(10,4)),
    TRY_CAST(gas.Real_Household_Exp AS DECIMAL(18,2)),
    TRY_CAST(gas.Nominal_Household_Exp AS DECIMAL(18,2))
FROM stg_INEI_Pobreza_dptos pob
JOIN Dim_Department d ON pob.Department = d.Department_Name
LEFT JOIN stg_INEI_Map_Informalidad_dptos inf ON pob.Department = inf.Department AND pob.Period = inf.Period
LEFT JOIN stg_INEI_GastoHogares_dptos gas ON pob.Department = gas.Department AND pob.Period = gas.Period;
GO
