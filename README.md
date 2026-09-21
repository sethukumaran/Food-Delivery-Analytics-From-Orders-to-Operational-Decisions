# Food-Delivery-Analytics-From-Orders-to-Operational-Decisions
Food-delivery businesses need to balance **delivery speed, rider capacity, customer experience, cancellation risk, restaurant performance, and revenue** at the same time.
This project analyzes a food-delivery dataset with approximately **100K order records** to answer practical business questions across three areas:

- **Operational Efficiency:** delivery duration, distance, traffic, vehicle type, driver workload, and bottlenecks.
- **Customer Behavior:** order frequency, peak ordering hours, cancellations, payment methods, and spending.
- **Restaurant / Menu Performance:** top menu items, revenue drivers, restaurant-level performance, and city-level demand.

### Project objectives

1. Build a reproducible data-cleaning and EDA workflow.
2. Use SQL for business-focused aggregation and segmentation.
3. Identify operational bottlenecks rather than relying only on descriptive statistics.
4. Produce decision-ready visualizations.
5. Package the work as a portfolio-quality GitHub analytics project.

---

## Tech Stack Used

![Python](https://img.shields.io/badge/Python-3.x-blue?logo=python)
![Pandas](https://img.shields.io/badge/Pandas-Data%20Analysis-150458?logo=pandas)
![NumPy](https://img.shields.io/badge/NumPy-Numerical%20Computing-013243?logo=numpy)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-SQL-4169E1?logo=postgresql)
![Matplotlib](https://img.shields.io/badge/Matplotlib-Visualization-11557C)
![Seaborn](https://img.shields.io/badge/Seaborn-Visualization-76B7B2)
![Plotly](https://img.shields.io/badge/Plotly-Interactive-3F4F75?logo=plotly)
![GitHub](https://img.shields.io/badge/GitHub-Portfolio-181717?logo=github)

---

## Dataset Overview

| Field | Description |
|---|---|
| `Order_ID` | Unique order identifier |
| `User_ID` | Customer identifier |
| `Restaurant_ID` | Restaurant identifier |
| `Driver_ID` | Delivery driver identifier |
| `Item_Name` | Ordered menu item |
| `Quantity` | Units ordered |
| `Total_Price` | Order value |
| `Order_Time` | Order timestamp |
| `Delivery_Time` | Delivery timestamp |
| `Delivery_Duration_Minutes` | Delivery duration |
| `City` | Customer/order city |
| `Payment_Method` | Cash, wallet, or credit card |
| `Order_Status` | Delivered, cancelled, or in transit |
| `Driver_Vehicle` | Bicycle, car, or motorbike |
| `Delivery_Distance_km` | Delivery distance |
| `Traffic_Level` | Low, medium, or high |
| `Driver_Availability` | Online/offline driver availability |

## Data Quality & Cleaning

The Python pipeline performs:

- Duplicate-row detection and removal.
- Timestamp conversion from string/object to `datetime`.
- Numeric type coercion.
- Missing-value treatment.
- Derived time features such as hour, day, and month.
- Delivery speed calculation.
- Delivered/cancelled indicator fields.
- IQR-based outlier detection for:
  - `Delivery_Duration_Minutes`
  - `Total_Price`
- Creation of a filtered analytical dataset so extreme values do not dominate selected distributional analyses.
- Correlation matrix and skewness calculations.

> **Important:** Outliers are flagged rather than blindly deleted from the source data. This preserves the original observations for operational investigation.

---

## SQL Deep-Dive Business Questions

The SQL layer answers questions such as:

1. What is the overall delivery, cancellation, and revenue profile?
2. Which hours generate the highest order volume?
3. Which cities generate the most delivered revenue?
4. Does traffic level correspond with longer delivery times?
5. How does delivery distance affect delivery duration?
6. Which restaurants combine high demand and high revenue?
7. Which menu items drive revenue and units sold?
8. Which drivers have high workload or slow average delivery times?
9. Does vehicle type relate to delivery performance?
10. Are cancellations concentrated in specific cities, hours, or traffic conditions?
11. Which customers are the highest-value repeat customers?
12. Which payment methods have different order values or cancellation rates?
13. Which city × menu-item combinations are important?
14. Where are unusually slow deliveries concentrated?
15. How do operational KPIs change over time?

## Key Insights & Business Recommendations

> Replace the placeholders below with the metrics produced by `outputs/summary_metrics.csv` and the SQL results after running the project.

### 1. Operational Efficiency

- **Average delivery time:** 
- **Median delivery time:** 
- **Average delivery distance:** 
- **Slow-delivery threshold:** 
- **Highest-risk traffic condition:** 

**Recommendation:** Prioritize capacity planning around the hours and traffic conditions associated with the highest delivery durations. Use city × traffic × hour combinations to identify localized bottlenecks rather than applying one company-wide rule.

### 2. Customer Behavior

- **Total customers:** 
- **Average delivered order value:** 
- **Cancellation rate:** 
- **Peak ordering hour:**
- **Highest-volume day:** 

**Recommendation:** Use peak-hour demand patterns to align driver availability with expected order volume. Monitor cancellation hotspots separately because a high-volume market and a high-risk market require different interventions.

### 3. Restaurant & Menu Performance

- **Top revenue item:** `[Item]`
- **Top unit-volume item:** `[Item]`
- **Top revenue city:** `[City]`
- **Top restaurant:** `[Restaurant ID]`
- **Top restaurant revenue:** `[Currency XX]`

**Recommendation:** Protect availability of high-revenue menu items and evaluate restaurant-level service performance together with sales volume. High sales with slow delivery or high cancellation rates may indicate capacity constraints.

### 4. Driver Performance

- **Top workload driver group:** `[Driver / Segment]`
- **Average delivery time by vehicle:** `[Metric]`
- **Slowest operational segment:** `[Vehicle / City / Traffic combination]`

### This project demonstrates practical capability in:

- SQL aggregation and analytical querying
- Data cleaning with Pandas
- Exploratory Data Analysis
- Statistical reasoning
- Outlier detection
- Business KPI development
- Operational bottleneck analysis
- Customer segmentation
- Restaurant performance analysis
- Data visualization
- Interactive analytics
- GitHub project organization

## Conclusion Summary

This project analyzed 100,002 food delivery orders to understand operational efficiency, customer behavior, restaurant performance, and revenue drivers using SQL and Python.
The analysis generated several important business findings:

- The platform achieved an overall 85.20% delivery rate, while approximately 9.81% of orders were cancelled. This indicates that cancellation reduction represents a meaningful operational improvement opportunity.
- Delivered orders generated approximately 22.92 million in total order value, with an average delivered order value of approximately 268.99.
- The average delivered order took approximately 37.55 minutes, with a median of 38 minutes, indicating a relatively concentrated delivery-time distribution.
- The average delivered distance was approximately 2.17 km, suggesting that the dataset is primarily composed of relatively short-distance deliveries.
- Traffic level did not show a large difference in average delivery duration in this dataset. High-traffic deliveries averaged about 37.46 minutes, compared with   approximately 37.60 minutes for low traffic. This suggests that traffic alone may not explain delivery delays and that other factors such as restaurant    preparation time, driver availability, dispatching, or order characteristics should be investigated.
- Zagazig generated the highest delivered revenue, at approximately 3.34 million, among the cities in the dataset.
- Shawarma was the highest-revenue menu item, generating approximately 2.61 million in delivered revenue, followed by Pizza and Fried Chicken.
- Customer behavior indicates a strong repeat-ordering component: the average customer placed approximately 11 orders, while the highest-frequency customer  placed 26 orders.
- The relationship between quantity and order value was relatively strong, with a correlation of approximately 0.74, which is expected because larger quantities generally increase order value.
- In contrast, delivery duration had almost no linear correlation with delivery distance in this dataset. This is an important finding because it indicates that distance alone should not be used as the primary explanation for delivery delays.
- Vehicle-level differences in average delivery time were relatively small, with motorbikes averaging about 37.49 minutes, bicycles about 37.56 minutes, and cars about 37.60 minutes.
- 
## Business Interpretation

The analysis suggests that the biggest opportunities are not simply about increasing delivery speed. Instead, the business should focus on reducing cancellations, improving dispatch and capacity planning, understanding city-level differences, and protecting high-performing menu items and restaurants.

For operations, cancellation hotspots should be investigated by combining city, hour, traffic, driver availability, restaurant, and order characteristics. Since traffic and distance alone do not explain much of the variation in delivery duration, further analysis should investigate the complete order lifecycle, particularly restaurant preparation and driver assignment.

For commercial teams, high-revenue menu items such as Shawarma, Pizza, and Fried Chicken should receive attention because availability and operational reliability for these items can have a direct impact on revenue.

For customer strategy, the presence of repeat customers creates an opportunity for customer segmentation, loyalty programs, personalized promotions, and retention analysis. High-frequency customers can be analyzed separately from occasional customers to understand their contribution to overall revenue.

## Final Project Conclusion

Overall, this project demonstrates how raw food-delivery transaction data can be transformed into actionable business intelligence using SQL and Python. The analysis moves beyond basic descriptive statistics by connecting demand, customer behavior, operational performance, cancellations, delivery characteristics, and revenue. The results show that improving food-delivery performance requires a combination of operational capacity management, cancellation reduction, customer retention, and restaurant/menu optimization rather than focusing on delivery time alone.
