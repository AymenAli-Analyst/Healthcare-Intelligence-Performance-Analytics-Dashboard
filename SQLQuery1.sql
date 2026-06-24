WITH DeptFinancials AS (
    SELECT 
        a.Department,
        COUNT(a.Appointment_ID) AS Total_Appointments,
        SUM(CASE WHEN a.Status = 'Completed' THEN 1 ELSE 0 END) AS Completed_Appointments,
        SUM(CAST(b.Revenue AS INT)) AS Total_Revenue,
        SUM(CAST(b.Profit AS INT)) AS Total_Profit
    FROM dbo.Appointments a
    LEFT JOIN dbo.Billing b ON a.Appointment_ID = b.Appointment_ID
    GROUP BY a.Department
),
DeptSatisfaction AS (
    SELECT 
        a.Department,
        AVG(CAST(s.Rating AS FLOAT)) AS Avg_Satisfaction_Rating,
        AVG(CAST(s.Waiting_Time_Min AS FLOAT)) AS Avg_Waiting_Time_Minutes
    FROM dbo.Appointments a
    INNER JOIN dbo.Satisfaction s ON a.Patient_ID = s.Patient_ID AND a.Appointment_Date = s.Survey_Date
    GROUP BY a.Department
)
SELECT 
    f.Department,
    f.Total_Appointments,
    f.Completed_Appointments,
    FORMAT(ISNULL(f.Total_Revenue, 0), 'C', 'en-US') AS Total_Revenue,
    FORMAT(ISNULL(f.Total_Profit, 0), 'C', 'en-US') AS Total_Profit,
    ROUND(ISNULL(s.Avg_Satisfaction_Rating, 0), 2) AS Avg_Satisfaction,
    ROUND(ISNULL(s.Avg_Waiting_Time_Minutes, 0), 1) AS Avg_Waiting_Time_Min,
    ROUND((CAST(f.Completed_Appointments AS FLOAT) / f.Total_Appointments) * 100, 2) AS Completion_Rate_Percentage
FROM DeptFinancials f
LEFT JOIN DeptSatisfaction s ON f.Department = s.Department
ORDER BY f.Total_Profit DESC;


SELECT 
    p.Gender,
    p.Insurance_Type,
    COUNT(DISTINCT p.Patient_ID) AS Total_Patients,
    COUNT(a.Appointment_ID) AS Total_Visits,
    SUM(CAST(b.Profit AS INT)) AS Total_Profit_Generated,
    AVG(CAST(p.Age AS FLOAT)) AS Avg_Patient_Age
FROM dbo.Patients p
INNER JOIN dbo.Appointments a ON p.Patient_ID = a.Patient_ID
LEFT JOIN dbo.Billing b ON a.Appointment_ID = b.Appointment_ID
GROUP BY p.Gender, p.Insurance_Type
ORDER BY Total_Profit_Generated DESC;



WITH DoctorStats AS (
    SELECT 
        d.Department,
        d.Doctor_ID,
        d.Doctor_Name,
        CAST(d.Experience_Years AS INT) AS Experience_Years,
        COUNT(a.Appointment_ID) AS Total_Appointments_Handled,
        AVG(COUNT(a.Appointment_ID)) OVER(PARTITION BY d.Department) AS Dept_Avg_Appointments_Per_Doc
    FROM dbo.Doctors d
    LEFT JOIN dbo.Appointments a ON d.Doctor_ID = a.Doctor_ID
    GROUP BY d.Department, d.Doctor_ID, d.Doctor_Name, d.Experience_Years
)
SELECT 
    Department,
    Doctor_Name,
    Experience_Years,
    Total_Appointments_Handled,
    ROUND(Dept_Avg_Appointments_Per_Doc, 1) AS Dept_Avg_Appointments,
    Total_Appointments_Handled - ROUND(Dept_Avg_Appointments_Per_Doc, 0) AS Workload_Variance,
    DENSE_RANK() OVER(PARTITION BY Department ORDER BY Total_Appointments_Handled DESC) AS Doctor_Rank_In_Dept
FROM DoctorStats
ORDER BY Department, Doctor_Rank_In_Dept;





SELECT 
    p.City,
    p.Insurance_Type,
    COUNT(a.Appointment_ID) AS Total_Bookings,
    SUM(CASE WHEN a.Status IN ('Cancelled', 'No-Show') THEN 1 ELSE 0 END) AS Total_Loss_Appointments,
    ROUND(
        (SUM(CASE WHEN a.Status IN ('Cancelled', 'No-Show') THEN 1 ELSE 0 END) * 100.0) / COUNT(a.Appointment_ID), 
        2
    ) AS Attrition_Rate_Percentage
FROM dbo.Patients p
INNER JOIN dbo.Appointments a ON p.Patient_ID = a.Patient_ID
GROUP BY p.City, p.Insurance_Type
HAVING COUNT(a.Appointment_ID) >= 5 -- Filters out low-sample noise
ORDER BY Attrition_Rate_Percentage DESC;




CREATE VIEW dbo.v_PowerBI_Ready_Analysis AS
SELECT 
    -- 1. Appointment Details
    a.Appointment_ID,
    a.Appointment_Date,
    a.Department,
    a.Status,

    -- 2. Patient Demographics
    p.Patient_ID,
    p.Patient_Name,
    p.Gender,
    p.Age,
    p.City,
    p.Insurance_Type,

    -- 3. Doctor Details
    d.Doctor_Name,
    CAST(d.Experience_Years AS INT) AS Experience_Years,

    -- 4. Financial Calculations (Row-Level Operations)
    CAST(b.Revenue AS INT) AS Revenue,
    CAST(b.Cost AS INT) AS Cost,
    CAST(b.Profit AS INT) AS Profit,
    -- حساب الهامش الربحي على مستوى الصف
    CASE 
        WHEN CAST(b.Revenue AS INT) > 0 
        THEN ROUND((CAST(b.Profit AS INT) * 1.0 / CAST(b.Revenue AS INT)) * 100, 2)
        ELSE 0 
    END AS Row_Profit_Margin_Percentage,

    -- 5. Satisfaction & Waiting Time
    CAST(s.Rating AS INT) AS Patient_Rating,
    CAST(s.Waiting_Time_Min AS INT) AS Waiting_Time_Min

FROM dbo.Appointments a
INNER JOIN dbo.Patients p ON a.Patient_ID = p.Patient_ID
INNER JOIN dbo.Doctors d ON a.Doctor_ID = d.Doctor_ID
LEFT JOIN dbo.Billing b ON a.Appointment_ID = b.Appointment_ID
LEFT JOIN dbo.Satisfaction s ON a.Patient_ID = s.Patient_ID AND a.Appointment_Date = s.Survey_Date;







































































































































