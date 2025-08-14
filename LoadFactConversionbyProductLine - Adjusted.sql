--SET ANSI_NULLS ON
--GO
--
--SET QUOTED_IDENTIFIER ON
--GO


--ALTER procedure [dbo].[LoadFactConversionByProductLine] as
--TRUNCATE TABLE FactConversionByProductLine;
WITH OriginalSubCategory AS (
    SELECT 
        c.customerID,
        os.firstSubID,
        os.firstSubDate,
        os.firstSubTypeID
    FROM pr.Customer c
    OUTER APPLY (
        SELECT TOP (1)
            s.subscriptionID            AS firstSubID,
            CAST(s.dateAdded AS date)   AS firstSubDate,
            CASE 
                WHEN st.category IN ('Regular Maintenance','Regular Maintenances') THEN 1
                WHEN st.category = 'Insulation Start' THEN 2
                WHEN st.category = 'Mosquito Maintenance' THEN 3
                WHEN st.category IN ('Termite Recurring Service','Termite Recurring Sentricon') THEN 4
                ELSE 5
            END                          AS firstSubTypeID
        FROM pr.Subscription s
        INNER JOIN pr.ServiceType st ON st.typeID = s.serviceID
        WHERE s.initialStatus = 1
          AND s.active = 1
          AND s.customerID = c.customerID
        ORDER BY s.dateAdded, s.subscriptionID
    ) os
)
--INSERT INTO FactConversionByProductLine
SELECT
    CAST(CONCAT(s2.customerID, s2.subscriptionID) AS bigint) AS conversionID,
    s2.subscriptionID,
    s2.customerID,
    s2.officeID,
    osc.firstSubDate,
    osc.firstSubTypeID,
    s2.serviceID AS typeID
FROM pr.Subscription s2
INNER JOIN pr.ServiceType st2 ON st2.typeID = s2.serviceID
INNER JOIN OriginalSubCategory osc
        ON osc.customerID = s2.customerID
       AND CAST(s2.dateAdded AS date) >= osc.firstSubDate
WHERE s2.initialStatus = 1
  AND s2.active = 1
  AND s2.subscriptionID <> osc.firstSubID
  AND CASE 
        WHEN st2.category IN ('Regular Maintenance','Regular Maintenances') THEN 1
        WHEN st2.category = 'Insulation Start' THEN 2
        WHEN st2.category = 'Mosquito Maintenance' THEN 3
        WHEN st2.category IN ('Termite Recurring Service','Termite Recurring Sentricon') THEN 4
        ELSE 5
      END <> osc.firstSubTypeID
ORDER BY s2.customerID, s2.dateAdded, s2.subscriptionID

--GO
