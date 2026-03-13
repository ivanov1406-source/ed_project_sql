-- добавляем колонку с рейтингом
WITH rate_index AS (
    SELECT *,
        ((CASE WHEN neighbourhood_cleansed IN ('Bay Village') THEN 10
               WHEN neighbourhood_cleansed IN ('Beacon Hill','Back Bay','West Roxbury') THEN 9
               WHEN neighbourhood_cleansed IN ('Charlestown','Roslindale','Hyde Park') THEN 8
               WHEN neighbourhood_cleansed IN ('Brighton','Jamaica Plain','North End','West End') THEN 7
               WHEN neighbourhood_cleansed IN ('Longwood Medical Area','South Boston','South Boston Waterfront') THEN 6
               ELSE 4
          END)*0.15
        +
        (CASE WHEN lc.distance < 3 THEN 10
              WHEN lc.distance BETWEEN 3 AND 5 THEN 8
              WHEN lc.distance BETWEEN 5 AND 8 THEN 6
              ELSE 4
         END)*0.25
        +
        (CASE WHEN number_of_reviews > 10 THEN
                   CASE WHEN review_scores_rating BETWEEN 91 AND 100 THEN 10
                        WHEN review_scores_rating BETWEEN 81 AND 90 THEN 9
                        WHEN review_scores_rating BETWEEN 71 AND 80 THEN 8
                        WHEN review_scores_rating BETWEEN 61 AND 70 THEN 7
                        ELSE 5
                   END
              ELSE 5
         END)*0.2
        +
        (CASE WHEN host_response_time = 'within an hour' THEN 10
              WHEN host_response_time = 'within a few hours' THEN 9
              WHEN host_response_time = 'within a day' THEN 8
              ELSE 5
         END)*0.1
        +
        (CASE WHEN bed_type = 'Real Bed' THEN 10
              ELSE 5
         END)*0.1
        +
        (CASE WHEN room_type = 'Entire home/apt' THEN 10
              ELSE 5
         END)*0.1
        +
        (CASE WHEN host_is_superhost = 't' THEN 10
              ELSE 5
         END)*0.1
        )::NUMERIC(4,2) AS rating
    FROM listings_clean lc
)
-- отбираем лучшие варианты для топ-менеджеров
,rate_index_top AS (
    SELECT *, 'top' AS stay
    FROM rate_index
    WHERE beds = 1 AND room_type = 'Entire home/apt'
    ORDER BY rating DESC, review_scores_rating DESC
    LIMIT 10 -- кол-во топ менеджеров
)
-- cчитаем количество кроватей для размещения 140 участников
,beds_for_group AS (
	SELECT beds, SUM(beds) OVER(ORDER BY rating DESC, review_scores_rating DESC, id)
    FROM rate_index
    WHERE beds BETWEEN 2 AND 4
)
-- выводим список лучших квартир для участников
,rate_index_group AS (
    SELECT *, 'group' AS stay
    FROM rate_index
    WHERE beds BETWEEN 2 AND 4
    ORDER BY rating DESC, review_scores_rating DESC
    LIMIT 57 -- необходимое количество на 140 человек
)
,rate_index_list AS (
    SELECT *
    FROM rate_index_top
    UNION
    SELECT * 
    FROM rate_index_group 
)
SELECT *
FROM rate_index_list
ORDER BY stay DESC, rating desc;