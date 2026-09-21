# 🌾 AgriInsight: Agricultural Yield & Productivity Analytics Platform

> **An End-to-End Analytics, Data Warehousing, Machine Learning & Business Intelligence Solution**  
> *Technologies: Python, Pandas, SQL, Scikit-learn, Power BI, Streamlit, SQLite*

---

## 📌 Executive Summary & Key Highlights

**AgriInsight** is a production-grade analytics platform engineered to evaluate crop yield drivers, regional productivity variances, climate resilience, and resource elasticity across multi-year agricultural datasets.

- 📊 **Large-Scale Data Pipeline & Deep Statistical EDA**: Processed multi-year agricultural datasets across 12 states, 48 districts, and 10 major crops using Python and Pandas; handled intelligent median imputation, outlier bounds, feature engineering, and ANOVA statistical hypothesis testing ($p < 10^{-30}$).
- ⚡ **Advanced SQL Analytical Warehouse**: Designed a Star Schema relational warehouse in SQLite with indexes; authored complex analytical SQL queries featuring CTEs, multi-table JOINs, rolling averages, and window functions (`LAG`, `DENSE_RANK`, `ROWS BETWEEN 2 PRECEDING`, `NTILE(4)`) to extract actionable productivity trends.
- 🤖 **Scikit-learn Regression ML Suite**: Developed, tuned, and evaluated multiple regression algorithms (Linear, Ridge, Random Forest, Gradient Boosting) benchmarked closely against $R^2$, RMSE, MAE, and MAPE metrics, achieving a **0.9864 Test $R^2$** and **0.9863 5-fold CV score**, backed by an automated inference engine.
- 📈 **Interactive Power BI Dashboard & Companion Web App**: Engineered 15+ advanced enterprise DAX measures, dynamic slicers, productivity trend lines, and regional heatmaps; complemented with a live Streamlit dashboard featuring what-if yield scenario forecasting.

---

## 🏛️ System Architecture

```text
                                 [ RAW AGRICULTURAL DATA ]
                                             │
                                             ▼
                 [ Python & Pandas Data Preprocessing Pipeline ]
                                  (src/data_preprocessing.py)
                    ┌────────────────────────┴────────────────────────┐
                    ▼                                                 ▼
     [ Cleaned Analytical Datasets ]                   [ Star-Schema Dimension/Fact Tables ]
   (data/processed/agricultural_yield_cleaned.csv)      (dim_crop, dim_region, fact_crop_production)
                    │                                                 │
          ┌─────────┴─────────┐                                       ▼
          ▼                   ▼                            [ SQLite Data Warehouse ]
   [ Statistical EDA ]  [ Scikit-Learn ML Suite ]           (database/agri_insight.db)
  (Correlation/ANOVA)    (Linear, Ridge, RF, GBDT)                    │
  (reports/figures/)     (models/best_crop_yield.joblib)              ▼
          │                   │                            [ Advanced SQL Queries ]
          │                   │                          (CTEs, Windows: LAG, RANK, NTILE)
          │                   ▼                          (reports/sql_exports/)
          │           [ Inference Engine ]                            │
          │            (src/predict.py)                               │
          └───────────────────┬───────────────────────────────────────┘
                              ▼
           [ Business Intelligence & Web Dashboards ]
        Power BI Desktop Kit (powerbi/) & Streamlit Web App (src/dashboard_app.py)
```

---

## 🗄️ Relational Database Schema (Star Schema)

```text
       ┌───────────────────────────────────┐
       │             dim_crop              │
       ├───────────────────────────────────┤
       │ crop_id (PK)                      │
       │ crop_name, crop_category, season  │
       └─────────────────┬─────────────────┘
                         │ 1
                         │
                         │ *
┌────────────────────────▼──────────────────────────────────────────┐
│                       fact_crop_production                        │
├───────────────────────────────────────────────────────────────────┤
│ record_id (PK)                                                    │
│ region_id (FK), crop_id (FK), year, season                        │
│ area_hectares, production_tons, yield_tons_per_ha                 │
│ annual_rainfall_mm, seasonal_rainfall_mm, temperature_avg_c       │
│ humidity_pct, soil_ph, soil_nitrogen_n, soil_phosphorus_p         │
│ soil_potassium_k, npk_total, n_to_p_ratio                         │
│ fertilizer_usage_kg_per_ha, pesticide_usage_kg_per_ha            │
│ irrigation_coverage_pct, rainfall_efficiency_index               │
└────────────────────────▲──────────────────────────────────────────┘
                         │ *
                         │
                         │ 1
       ┌─────────────────┴─────────────────┐
       │            dim_region             │
       ├───────────────────────────────────┤
       │ region_id (PK)                    │
       │ state, district, zone, soil_type  │
       └───────────────────────────────────┘
```

---

## ⚡ Advanced SQL Analytical Queries Showcase

The platform includes 5 production-ready SQL analytics scripts in [`sql/productivity_queries.sql`](file:///sql/productivity_queries.sql):

### 1. YoY Crop Yield Growth & Momentum Analysis (`LAG()` Window Function & CTEs)
```sql
WITH AnnualCropProductivity AS (
    SELECT
        f.year, c.crop_name, c.crop_category,
        ROUND(AVG(f.yield_tons_per_ha), 3) AS avg_yield_tons_per_ha,
        ROUND(SUM(f.production_tons), 1) AS total_production_tons
    FROM fact_crop_production f
    JOIN dim_crop c ON f.crop_id = c.crop_id
    GROUP BY f.year, c.crop_name, c.crop_category
)
SELECT
    year, crop_name, avg_yield_tons_per_ha,
    LAG(avg_yield_tons_per_ha, 1) OVER (PARTITION BY crop_name ORDER BY year) AS prior_year_yield,
    ROUND(((avg_yield_tons_per_ha - LAG(avg_yield_tons_per_ha, 1) OVER (PARTITION BY crop_name ORDER BY year)) 
           / LAG(avg_yield_tons_per_ha, 1) OVER (PARTITION BY crop_name ORDER BY year)) * 100.0, 2) AS yoy_yield_growth_pct,
    CASE 
        WHEN LAG(avg_yield_tons_per_ha, 1) OVER (PARTITION BY crop_name ORDER BY year) IS NULL THEN 'Baseline Year'
        WHEN ((avg_yield_tons_per_ha - LAG(avg_yield_tons_per_ha, 1) OVER (PARTITION BY crop_name ORDER BY year)) 
              / LAG(avg_yield_tons_per_ha, 1) OVER (PARTITION BY crop_name ORDER BY year)) > 0.05 THEN 'High Expansion (>5%)'
        ELSE 'Stable / Contracting'
    END AS growth_momentum_status
FROM AnnualCropProductivity;
```

### 2. Top-3 Regional Productivity Leaders (`DENSE_RANK()`)
Identifies the top 3 performing districts within every agro-ecological zone partitioned by crop type.

### 3. 3-Year Rolling Average (`ROWS BETWEEN 2 PRECEDING AND CURRENT ROW`)
Smooths climate anomaly spikes (e.g. 2014-2015 El Niño drought) and isolates underlying yield growth trajectory.

### 4. Vulnerability & Productivity Quartiles (`NTILE(4)`)
Segments districts into 4 distinct productivity quartiles (`Tier 1 Elite`, `Tier 2 High`, `Tier 3 Moderate`, `Tier 4 Stressed`).

### 5. Fertilizer & Irrigation Elasticity
Computes marginal yield return per kg of fertilizer applied across geographical zones.

---

## 🤖 Machine Learning Model Benchmarks

Supervised regression models were trained on 80% of data and evaluated on 20% unseen test data across multiple metrics:

| Model Architecture | Train $R^2$ | Test $R^2$ | Train RMSE | Test RMSE | Train MAE | Test MAE | Test MAPE (%) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Linear Regression (OLS Baseline)** | 0.9433 | 0.9388 | 3.8513 | 4.0974 | 2.0949 | 2.1683 | 82.29% |
| **Ridge Regression (L2 Regularized)** | 0.9431 | 0.9386 | 3.8586 | 4.1037 | 2.1057 | 2.1698 | 82.26% |
| **Random Forest Regressor** | 0.9974 | 0.9847 | 0.8224 | 2.0503 | 0.2768 | 0.6694 | 11.17% |
| **Gradient Boosting Regressor (Winner)** | **0.9997** | **0.9864** | **0.2613** | **1.9324** | **0.1745** | **0.6152** | **10.48%** |

- **5-Fold Cross-Validation $R^2$**: `0.9863 (+/- 0.0027)`
- **Key Yield Predictors**: Irrigation Coverage (%), Seasonal Precipitation Ratio, Temperature Deviation, and Soil Nutrient (N-P-K) balance.

---

## 📊 Power BI & Web Dashboard Features

1. **Executive KPI Cards**: Real-time cards displaying Average Yield (MT/Ha), Total Harvest (Million Tons), Total Cultivated Land (Million Ha), and dynamic YoY Growth delta.
2. **Dynamic Multi-Level Slicers**: Interactive filtering by Year Range, State/Zone, Crop Category, and Season.
3. **Productivity Trend Lines**: Multi-year trend visual overlaying actual yield, 3-year rolling average, and precipitation bar charts.
4. **Regional Heatmaps & Decomposition Trees**: State-by-state productivity rankings and hierarchical breakdown by zone $\to$ state $\to$ soil $\to$ crop.
5. **Interactive What-If Scenario Predictor**: Real-time slider and numeric inputs allowing agronomists to simulate climate stress or fertilizer adjustments and forecast harvest yield.

---

## 📁 Repository Structure

```text
AgriInsight/
├── data/
│   ├── raw/
│   │   └── agricultural_yield_raw.csv         # Raw simulated sensor & harvest records
│   └── processed/
│       ├── agricultural_yield_cleaned.csv     # Master cleaned analytical dataset
│       ├── dim_crop.csv                       # Star-Schema Crop Dimension
│       ├── dim_region.csv                     # Star-Schema Region Dimension
│       └── fact_crop_production.csv           # Star-Schema Fact Production Table
├── database/
│   └── agri_insight.db                        # SQLite relational data warehouse
├── sql/
│   ├── schema.sql                             # DDL for star schema tables & indexes
│   └── productivity_queries.sql               # 5 production SQL queries (CTEs, Windows)
├── src/
│   ├── __init__.py
│   ├── generate_data.py                       # Synthesizes 6,240+ realistic records (2012-2024)
│   ├── data_preprocessing.py                  # Cleaning, median imputation, outlier handling
│   ├── eda_analysis.py                        # Correlation heatmaps, ANOVA tests, charts
│   ├── db_setup.py                            # SQLite database schema builder & data loader
│   ├── sql_analytics.py                       # Executes and exports SQL analytics queries
│   ├── model_training.py                      # Trains ML regression models & logs benchmarks
│   ├── predict.py                             # CLI & programmatic inference module
│   └── dashboard_app.py                       # Streamlit interactive multi-tab dashboard
├── models/
│   ├── best_crop_yield_model.joblib           # Serialized Gradient Boosting model
│   ├── preprocessor.joblib                    # Serialized ColumnTransformer
│   └── model_metadata.joblib                  # Model performance & feature metadata
├── notebooks/
│   ├── 01_eda_and_statistical_analysis.ipynb  # Interactive EDA & ANOVA notebook
│   └── 02_crop_yield_prediction.ipynb         # Interactive ML development notebook
├── powerbi/
│   ├── DAX_Measures.dax                       # 15+ production DAX measures
│   └── PowerBI_Dashboard_Guide.md             # Visual layout blueprint & setup guide
├── reports/
│   ├── figures/                               # Exported publication-grade figures
│   │   ├── correlation_heatmap.png
│   │   ├── yield_by_crop_boxplot.png
│   │   ├── yearly_yield_vs_rainfall_trend.png
│   │   ├── irrigation_yield_impact.png
│   │   ├── model_feature_importance.png
│   │   └── model_residuals_plot.png
│   ├── sql_exports/                           # Exported query results CSVs
│   └── model_benchmarks.csv                   # Algorithm comparison table
├── tests/
│   └── test_pipeline.py                       # Automated test suite
├── requirements.txt                           # Project dependencies
└── README.md                                  # Documentation
```

---

## 🚀 Quickstart & Execution Guide

### 1. Environment Setup
```bash
# Clone the repository and navigate into folder
cd AgriInsight

# Install required dependencies
pip install -r requirements.txt
```

### 2. End-to-End Pipeline Reproduction
Run the pipeline scripts in sequential order:

```bash
# 1. Generate realistic multi-regional agricultural dataset
python src/generate_data.py

# 2. Run data cleaning, imputation, outlier treatment, and feature engineering
python src/data_preprocessing.py

# 3. Perform statistical EDA and export charts
python src/eda_analysis.py

# 4. Build SQLite database and populate Star-Schema tables
python src/db_setup.py

# 5. Run complex SQL analytics queries
python src/sql_analytics.py

# 6. Train and benchmark Scikit-learn regression models
python src/model_training.py
```

### 3. Run Automated Tests
```bash
python -m unittest tests/test_pipeline.py -v
```

### 4. Interactive Prediction via CLI
```bash
python src/predict.py --crop Wheat --season Rabi --soil Alluvial --zone North --rainfall 650 --irrigation 95 --fert 180 --area 500
```

### 5. Launch Interactive Web Dashboard
```bash
streamlit run src/dashboard_app.py
```
