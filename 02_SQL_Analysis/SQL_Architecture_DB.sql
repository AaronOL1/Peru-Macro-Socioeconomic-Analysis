/*
PROJECT: Peru Macro-Econometrics Data Engine
AUTHOR: Aaron Olmedo López
DESCRIPTION: ETL process to clean and unify BCRP (Macro) and INEI (Social) indicators.
*/

CREATE DATABASE PeruMacroEconometrics;
GO

USE PeruMacroEconometrics;
GO

-- Create tables for BCRP (Macro) and INEI (Social) indicators
CREATE TABLE stg_bcrp_monthly (
	
);