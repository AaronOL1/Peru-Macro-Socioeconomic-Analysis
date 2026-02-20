## PROJECT: Peru Macro-Econometrics Data Engine
## AUTHOR: Aaron Olmedo López
## DESCRIPTION: Creating the data architecture for the Peru Macro-Econometrics Data Engine, 
## including database creation, staging tables for raw data, and dimensional modeling for unified
## macroeconomic and regional development indicators.

# Library Imports
import pandas as pd
import pyodbc 
import seaborn as sns
import matplotlib.pyplot as plt

## Database Connection Setup
server= '(local)'
database = 'PeruMacroEconometrics'
conn_str = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={server};DATABASE={database};Trusted_Connection=yes;'

print("Connecting to SQL Server Database")

try:
# Data Extraction
    query = """
    SELECT 
        Date_Key,
        Gov_Spending_MSoles AS 'Fiscal_Spending_MEF',
        Reference_Rate AS 'Monetary_Rate_BCRP',
        GDP_Var_Rate AS 'GDP_Growth'
    FROM Fact_Macro_Indicators
    WHERE Date_Key >= '2010-01-01' 
    ORDER BY Date_Key ASC;
    """
    with pyodbc.connect(conn_str) as conn:
        df = pd.read_sql(query, conn)
    
    print(f"Data successfully loaded: {len(df)} records retrieved.")

    # Data Cleaning and Preparation
    cols_to_analyze = ['Fiscal_Spending_MEF', 'Monetary_Rate_BCRP', 'GDP_Growth']
    for col in cols_to_analyze:
        df[col] = pd.to_numeric(df[col], errors='coerce')
        
    df_clean = df.dropna(subset=cols_to_analyze)

    if len(df_clean) == 0:
        print(" ERROR: 0 rows.")
    else:
        # Pearson Correlation
        correlation_matrix = df_clean[cols_to_analyze].corr()

        print("\n Pearson Correlation Matrix:")
        print(correlation_matrix)

        # Data Visualization - Corr. Heatmap
        plt.figure(figsize=(10, 8))
        sns.heatmap(correlation_matrix, annot=True, cmap='RdBu', vmin=-1, vmax=1, fmt=".2f", linewidths=.5)
        plt.title('Correlation Analysis: Fiscal vs. Monetary Policy Impact on GDP', fontsize=14)
        plt.xticks(rotation=45)
        plt.yticks(rotation=0)
        plt.tight_layout()
        plt.show()

except Exception as e:
    print(f"Error: {e}")