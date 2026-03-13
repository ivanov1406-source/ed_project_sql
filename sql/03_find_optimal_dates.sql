--объеденяем отобранные апартаменты с календарём
WITH match_rate_calendar AS (
	SELECT * 
	FROM rate_index_list ril
	INNER JOIN calendar_clean cc
	ON ril.id = cc.listing_id 
)
-- делаем таблицу с тремя днями подряд
,three_days AS (
	SELECT id, date
        ,LAG(date, 1) OVER (PARTITION BY id ORDER BY date) AS d_prev1
        ,LAG(date, 2) OVER (PARTITION BY id ORDER BY date) AS d_prev2
    FROM match_rate_calendar
    WHERE date IS NOT NULL
)
-- фильтруем тройки на наличие и начало в Пн или Ср
,filtred_days AS (
    SELECT id,
        d_prev2 AS start_date,
        ARRAY[d_prev2, d_prev1, date] AS all_dates
    FROM three_days
    WHERE d_prev1 IS NOT NULL
      AND d_prev2 IS NOT NULL
      AND date = d_prev1 + INTERVAL '1 day'
      AND d_prev1 = d_prev2 + INTERVAL '1 day'
      AND EXTRACT(ISODOW FROM d_prev2) IN (1, 3)
)
-- смотрим наличие свободных дат три дня подряд одновременно у всех вариантов
SELECT 
    fd.all_dates, 
    COUNT(DISTINCT fd.id) AS total_apartments, 
    ROUND(sum(cc.num_price + ril.num_cleaning_fee/3), 2) AS sum_price
FROM filtred_days fd
INNER JOIN rate_index_list ril ON fd.id = ril.id
INNER JOIN calendar_clean cc ON fd.id = cc.listing_id 
    AND cc.date = ANY(fd.all_dates)
GROUP BY fd.all_dates
HAVING COUNT(DISTINCT fd.id) = (SELECT COUNT(DISTINCT id) FROM rate_index_list)
ORDER BY fd.all_dates[1];

-- все варианты соответствуют бюджету, выбираем любой. Например с 20-22 февраля.
WITH need_days AS (
    SELECT *
    FROM calendar_clean cc
    INNER JOIN rate_index_list ril ON cc.listing_id = ril.id
    WHERE cc."date" between '2017-02-20' AND '2017-02-22'
  	)
,total_price as (
	SELECT id, (sum(num_price) + avg(num_cleaning_fee)) AS total_price
	FROM need_days
	GROUP BY id
	)
,final_list AS (
    SELECT 
        l.id, 
        l.stay, 
        l.beds AS accommodates, 
        tp.total_price, 
        l.rating,
        l.host_response_time, 
        l.host_is_superhost, 
        l.neighbourhood_cleansed, 
        l.room_type, 
        l.bed_type,
        l.review_scores_rating, 
        l.distance
    FROM rate_index_list l
    INNER JOIN total_price tp
    USING(id)
    ORDER BY l.stay DESC, l.rating DESC
)
SELECT *
FROM final_list;
