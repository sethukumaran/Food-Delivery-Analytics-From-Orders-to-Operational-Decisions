"""
Food Delivery Analytics - End-to-End EDA & Visualization
=========================================================
Input:
    data/Order_delivery.csv

Outputs:
    outputs/cleaned_orders.csv
    outputs/summary_metrics.csv
    outputs/figures/*.png
    outputs/interactive_delivery.html

Notes:
- Raw data is never overwritten.
- IQR outliers are flagged in the full cleaned dataset.
- A filtered analysis dataset is also created for delivery time and order value
  to prevent extreme observations from dominating selected descriptive charts.
- Change DB/CSV paths through environment variables if needed.
"""

from pathlib import Path
import warnings
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import plotly.express as px

warnings.filterwarnings("ignore")

BASE_DIR = Path(__file__).resolve().parents[1]
DATA_PATH = BASE_DIR / "data" / "Order_delivery.csv"
OUTPUT_DIR = BASE_DIR / "outputs"
FIG_DIR = OUTPUT_DIR / "figures"
OUTPUT_DIR.mkdir(exist_ok=True)
FIG_DIR.mkdir(exist_ok=True)

# ----------------------------
# 1. Load and inspect
# ----------------------------
df = pd.read_csv(DATA_PATH)

print(f"Raw shape: {df.shape}")
print("\nColumns:")
print(df.columns.tolist())
print("\nData types:")
print(df.dtypes)
print("\nMissing values:")
print(df.isna().sum().sort_values(ascending=False))
print(f"\nDuplicate rows: {df.duplicated().sum()}")

# ----------------------------
# 2. Data cleaning
# ----------------------------
date_cols = ["Order_Time", "Delivery_Time"]
for col in date_cols:
    df[col] = pd.to_datetime(
        df[col],
        format="%d-%m-%Y %H:%M",
        errors="coerce"
    )

numeric_cols = [
    "Quantity", "Total_Price", "Delivery_Duration_Minutes",
    "Restaurant_Lat", "Restaurant_Lon", "Customer_Lat", "Customer_Lon",
    "Driver_Lat", "Driver_Lon", "Delivery_Distance_km"
]

for col in numeric_cols:
    df[col] = pd.to_numeric(df[col], errors="coerce")

# Remove exact duplicates.
df = df.drop_duplicates().copy()

# Business-safe missing value handling:
# numeric fields -> median; categorical fields -> explicit Unknown.
for col in numeric_cols:
    if df[col].isna().any():
        df[col] = df[col].fillna(df[col].median())

categorical_cols = df.select_dtypes(include="object").columns
for col in categorical_cols:
    if df[col].isna().any():
        df[col] = df[col].fillna("Unknown")

# Dates: if a date is missing, derive from the other timestamp where possible.
df["Order_Time"] = df["Order_Time"].fillna(df["Delivery_Time"])
df["Delivery_Time"] = df["Delivery_Time"].fillna(df["Order_Time"])

# Derived features
df["Order_Date"] = df["Order_Time"].dt.date
df["Order_Hour"] = df["Order_Time"].dt.hour
df["Order_Day"] = df["Order_Time"].dt.day_name()
df["Order_Month"] = df["Order_Time"].dt.to_period("M").astype(str)
df["Delivery_Speed_km_per_min"] = (
    df["Delivery_Distance_km"] / df["Delivery_Duration_Minutes"].replace(0, np.nan)
)
df["Is_Delivered"] = df["Order_Status"].eq("Delivered")
df["Is_Cancelled"] = df["Order_Status"].eq("Cancelled")

# ----------------------------
# 3. IQR outlier detection
# ----------------------------
def add_iqr_flags(data: pd.DataFrame, column: str) -> pd.DataFrame:
    q1 = data[column].quantile(0.25)
    q3 = data[column].quantile(0.75)
    iqr = q3 - q1
    lower = q1 - 1.5 * iqr
    upper = q3 + 1.5 * iqr

    data[f"{column}_Outlier"] = (
        (data[column] < lower) | (data[column] > upper)
    )
    data.attrs[f"{column}_q1"] = q1
    data.attrs[f"{column}_q3"] = q3
    data.attrs[f"{column}_lower"] = lower
    data.attrs[f"{column}_upper"] = upper
    return data

df = add_iqr_flags(df, "Delivery_Duration_Minutes")
df = add_iqr_flags(df, "Total_Price")

delivery_lower = df.attrs["Delivery_Duration_Minutes_lower"]
delivery_upper = df.attrs["Delivery_Duration_Minutes_upper"]
value_lower = df.attrs["Total_Price_lower"]
value_upper = df.attrs["Total_Price_upper"]

print("\nIQR thresholds")
print(f"Delivery duration: {delivery_lower:.2f} to {delivery_upper:.2f} minutes")
print(f"Order value: {value_lower:.2f} to {value_upper:.2f}")

# Keep all observations for KPI reporting, but create a filtered dataset
# for analyses where extreme values can distort distributions.
analysis_df = df.loc[
    (~df["Delivery_Duration_Minutes_Outlier"]) &
    (~df["Total_Price_Outlier"])
].copy()

# ----------------------------
# 4. Descriptive statistics
# ----------------------------
numeric_analysis_cols = [
    "Quantity", "Total_Price", "Delivery_Duration_Minutes",
    "Delivery_Distance_km", "Delivery_Speed_km_per_min"
]

desc = df[numeric_analysis_cols].describe().T
desc["skewness"] = df[numeric_analysis_cols].skew()
desc.to_csv(OUTPUT_DIR / "descriptive_statistics.csv")

corr = df[numeric_analysis_cols].corr(numeric_only=True)
corr.to_csv(OUTPUT_DIR / "correlation_matrix.csv")

# ----------------------------
# 5. Business KPI summary
# ----------------------------
total_orders = len(df)
delivered = df["Is_Delivered"].sum()
cancelled = df["Is_Cancelled"].sum()

kpis = pd.DataFrame({
    "Metric": [
        "Total Orders", "Delivered Orders", "Cancelled Orders",
        "Delivery Rate %", "Cancellation Rate %",
        "Delivered Revenue", "Average Delivered Order Value",
        "Average Delivered Delivery Minutes", "Unique Customers",
        "Unique Restaurants", "Unique Drivers"
    ],
    "Value": [
        total_orders,
        delivered,
        cancelled,
        round(100 * delivered / total_orders, 2),
        round(100 * cancelled / total_orders, 2),
        round(df.loc[df["Is_Delivered"], "Total_Price"].sum(), 2),
        round(df.loc[df["Is_Delivered"], "Total_Price"].mean(), 2),
        round(df.loc[df["Is_Delivered"], "Delivery_Duration_Minutes"].mean(), 2),
        df["User_ID"].nunique(),
        df["Restaurant_ID"].nunique(),
        df["Driver_ID"].nunique()
    ]
})
kpis.to_csv(OUTPUT_DIR / "summary_metrics.csv", index=False)
print("\nKPI summary:")
print(kpis.to_string(index=False))

# ----------------------------
# 6. Theme
# ----------------------------
sns.set_theme(style="whitegrid", context="talk")
plt.rcParams["figure.figsize"] = (12, 7)
plt.rcParams["axes.titleweight"] = "bold"

def savefig(name: str):
    plt.tight_layout()
    plt.savefig(FIG_DIR / name, dpi=180, bbox_inches="tight")
    plt.close()

# ----------------------------
# 7. Univariate analysis
# ----------------------------
fig, axes = plt.subplots(1, 2, figsize=(16, 6))
sns.histplot(df["Total_Price"], kde=True, ax=axes[0])
axes[0].set_title("Order Value Distribution")
axes[0].set_xlabel("Order Value")

sns.histplot(df["Delivery_Duration_Minutes"], kde=True, ax=axes[1])
axes[1].set_title("Delivery Duration Distribution")
axes[1].set_xlabel("Minutes")
savefig("01_univariate_distributions.png")

# ----------------------------
# 8. Correlation heatmap
# ----------------------------
plt.figure(figsize=(11, 8))
sns.heatmap(corr, annot=True, fmt=".2f", cmap="vlag", center=0)
plt.title("Numerical Correlation Matrix")
savefig("02_correlation_heatmap.png")

# ----------------------------
# 9. Order volume by hour
# ----------------------------
hourly = (
    df.groupby("Order_Hour")
      .agg(Orders=("Order_ID", "count"),
           Revenue=("Total_Price", "sum"))
      .reset_index()
)

fig, ax1 = plt.subplots(figsize=(13, 7))
sns.lineplot(data=hourly, x="Order_Hour", y="Orders", marker="o", ax=ax1)
ax1.set_title("Hourly Demand Pattern")
ax1.set_xlabel("Hour of Day")
ax1.set_ylabel("Orders")
savefig("03_hourly_demand.png")

# ----------------------------
# 10. Order status mix
# ----------------------------
status = df["Order_Status"].value_counts().reset_index()
status.columns = ["Order_Status", "Orders"]

plt.figure(figsize=(10, 6))
sns.barplot(data=status, x="Order_Status", y="Orders")
plt.title("Order Status Distribution")
plt.xlabel("")
plt.ylabel("Orders")
savefig("04_order_status.png")

# ----------------------------
# 11. City revenue and service performance
# ----------------------------
city = (
    df.groupby("City")
      .agg(
          Orders=("Order_ID", "count"),
          Delivered_Revenue=("Total_Price", lambda s: s[df.loc[s.index, "Is_Delivered"]].sum()),
          Avg_Delivery_Min=("Delivery_Duration_Minutes", "mean"),
          Cancellation_Rate=("Is_Cancelled", "mean")
      )
      .reset_index()
)
city["Cancellation_Rate"] *= 100

plt.figure(figsize=(13, 7))
sns.barplot(
    data=city.sort_values("Delivered_Revenue", ascending=False),
    x="Delivered_Revenue", y="City"
)
plt.title("Delivered Revenue by City")
plt.xlabel("Revenue")
plt.ylabel("")
savefig("05_city_revenue.png")

# ----------------------------
# 12. Traffic vs delivery time
# ----------------------------
plt.figure(figsize=(10, 6))
sns.boxplot(
    data=analysis_df,
    x="Traffic_Level",
    y="Delivery_Duration_Minutes",
    order=["Low", "Medium", "High"]
)
plt.title("Delivery Time by Traffic Level")
plt.xlabel("Traffic")
plt.ylabel("Delivery Minutes")
savefig("06_traffic_delivery_time.png")

# ----------------------------
# 13. Distance vs delivery duration
# ----------------------------
plt.figure(figsize=(11, 7))
sns.scatterplot(
    data=analysis_df.sample(min(15000, len(analysis_df)), random_state=42),
    x="Delivery_Distance_km",
    y="Delivery_Duration_Minutes",
    hue="Traffic_Level",
    alpha=0.45
)
plt.title("Delivery Distance vs Delivery Duration")
plt.xlabel("Distance (km)")
plt.ylabel("Delivery Duration (min)")
savefig("07_distance_vs_duration.png")

# ----------------------------
# 14. Top menu items
# ----------------------------
items = (
    df[df["Is_Delivered"]]
    .groupby("Item_Name")
    .agg(
        Units_Sold=("Quantity", "sum"),
        Revenue=("Total_Price", "sum")
    )
    .reset_index()
    .sort_values("Revenue", ascending=False)
)

plt.figure(figsize=(12, 7))
sns.barplot(data=items, x="Revenue", y="Item_Name")
plt.title("Top Menu Items by Delivered Revenue")
plt.xlabel("Revenue")
plt.ylabel("")
savefig("08_top_items_revenue.png")

# ----------------------------
# 15. Vehicle performance
# ----------------------------
vehicle = (
    df[df["Is_Delivered"]]
    .groupby("Driver_Vehicle")
    .agg(
        Orders=("Order_ID", "count"),
        Avg_Delivery_Min=("Delivery_Duration_Minutes", "mean"),
        Avg_Distance_Km=("Delivery_Distance_km", "mean")
    )
    .reset_index()
)

plt.figure(figsize=(10, 6))
sns.barplot(data=vehicle, x="Driver_Vehicle", y="Avg_Delivery_Min")
plt.title("Average Delivery Time by Driver Vehicle")
plt.xlabel("")
plt.ylabel("Average Minutes")
savefig("09_vehicle_delivery_performance.png")

# ----------------------------
# 16. Cancellation heatmap: hour x traffic
# ----------------------------
cancel_heat = pd.pivot_table(
    df,
    index="Order_Hour",
    columns="Traffic_Level",
    values="Is_Cancelled",
    aggfunc="mean"
) * 100

plt.figure(figsize=(10, 9))
sns.heatmap(cancel_heat, annot=True, fmt=".1f", cmap="Reds")
plt.title("Cancellation Rate by Hour and Traffic Level (%)")
plt.xlabel("Traffic")
plt.ylabel("Order Hour")
savefig("10_cancellation_heatmap.png")

# ----------------------------
# 17. Customer frequency distribution
# ----------------------------
customer = (
    df.groupby("User_ID")
      .agg(
          Orders=("Order_ID", "count"),
          Delivered_Revenue=("Total_Price", lambda s: s[df.loc[s.index, "Is_Delivered"]].sum())
      )
      .reset_index()
)

plt.figure(figsize=(11, 6))
sns.histplot(customer["Orders"], bins=20, kde=True)
plt.title("Customer Order Frequency")
plt.xlabel("Orders per Customer")
plt.ylabel("Customers")
savefig("11_customer_frequency.png")

# ----------------------------
# 18. Interactive Plotly chart
# ----------------------------
fig = px.scatter(
    analysis_df.sample(min(15000, len(analysis_df)), random_state=42),
    x="Delivery_Distance_km",
    y="Delivery_Duration_Minutes",
    color="Traffic_Level",
    hover_data=["City", "Driver_Vehicle", "Order_Status", "Total_Price"],
    title="Interactive Delivery Bottleneck Explorer"
)
fig.write_html(OUTPUT_DIR / "interactive_delivery.html")

# ----------------------------
# 19. Save processed data
# ----------------------------
df.to_csv(OUTPUT_DIR / "cleaned_orders.csv", index=False)

print("\nAnalysis complete.")
print(f"Cleaned data: {OUTPUT_DIR / 'cleaned_orders.csv'}")
print(f"Figures: {FIG_DIR}")
print(f"Interactive chart: {OUTPUT_DIR / 'interactive_delivery.html'}")
