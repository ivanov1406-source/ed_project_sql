--очистка и предобработка таблицы calendar
WITH calendar_available AS (
    SELECT *, REGEXP_REPLACE(c.price, '[$,]', '', 'g')::NUMERIC(9,2) AS num_price
    FROM calendar c 
    WHERE c.available = 't' 
    	AND (c."date" BETWEEN '2017-01-01' AND '2017-06-30') 
)
,calendar_available_2 AS (
    SELECT ca.listing_id
    FROM calendar_available ca
    GROUP BY ca.listing_id 
    HAVING COUNT(date) >= 90			
)
,calendar_available_3 AS (
    SELECT *
    FROM calendar_available ca
    INNER JOIN calendar_available_2 ca2
    USING(listing_id)
)
,calendar_clean AS (
    SELECT ca3.listing_id, ca3.date::DATE, ca3.num_price 
    FROM calendar_available_3 ca3
    WHERE num_price <= (SELECT PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY num_price)
                        FROM calendar_available_3)
)
SELECT *
FROM calendar_clean;

--очистка и предобработка таблицы listings. 
WITH distinct_id_calendar AS (
    SELECT DISTINCT(cc.listing_id)
    FROM calendar_clean cc
)
,listings_clean AS (
    SELECT *
    ,COALESCE(NULLIF(REGEXP_REPLACE(l.cleaning_fee, '[$,]', '', 'g'), '')::NUMERIC, 0)::NUMERIC(9,2) AS num_cleaning_fee
    ,(6371 * 2 * ASIN(SQRT(POWER(SIN(RADIANS(l.latitude - 42.345606655126474) / 2), 2) + COS(RADIANS(42.345606655126474)) * COS(RADIANS(l.latitude))
    * POWER(SIN(RADIANS(l.longitude - -71.04651649300702) / 2), 2))))::NUMERIC(9,2) AS distance
    FROM listings l	
    INNER JOIN distinct_id_calendar d
    ON l.id = d.listing_id
    WHERE l.minimum_nights <= 3
)
SELECT *
FROM listings_clean;