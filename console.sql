CREATE OR REPLACE TABLE raw_games AS
SELECT *
FROM read_json_auto(
    '/Users/ffff/Downloads/steam_2025_5k-dataset-games_20250831.json',
    maximum_object_size = 200000000
);

CREATE OR REPLACE TABLE games_flat AS
SELECT UNNEST(games) AS g
FROM raw_games;

CREATE OR REPLACE TABLE games_clean AS
SELECT
    g.appid AS app_id,
    g.name_from_applist AS name,
    g.app_details.data.type AS type,
    g.app_details.data.is_free AS is_free,
    g.app_details.data.release_date.date AS release_date,
    CASE
        WHEN g.app_details.data.is_free = TRUE THEN 0
        WHEN g.app_details.data.price_overview.final IS NOT NULL
            THEN g.app_details.data.price_overview.final / 100.0
        ELSE 0
    END                               AS price_usd,
    genre.unnest.description          AS genre
FROM games_flat gf,
     UNNEST(gf.g.app_details.data.genres) AS genre;


CREATE OR REPLACE TABLE game_tags AS
SELECT
    g.appid AS app_id,
    g.name_from_applist AS name,
    tag.unnest.description AS tag
FROM games_flat gf,
     UNNEST(gf.g.app_details.data.categories) AS tag;


CREATE OR REPLACE TABLE raw_reviews AS
SELECT *
FROM read_json_auto(
    '/Users/ffff/Downloads/steam_2025_5k-dataset-reviews_20250901.json',
    maximum_object_size = 200000000
);


CREATE OR REPLACE TABLE reviews_flat AS
SELECT UNNEST(reviews) AS r
FROM raw_reviews;


CREATE OR REPLACE TABLE reviews_clean AS
SELECT
    CAST(r.appid AS INTEGER) AS app_id,
    r.review_data.query_summary.num_reviews AS num_reviews,
    r.review_data.query_summary.review_score AS review_score,
    r.review_data.query_summary.total_positive AS total_positive,
    r.review_data.query_summary.total_negative AS total_negative,
    r.review_data.query_summary.total_reviews AS total_reviews
FROM reviews_flat;




-- 1) Top 20 games by number of reviews
SELECT
    g.app_id,
    g.name,
    r.total_reviews
FROM games_clean g
JOIN reviews_clean r USING (app_id)
ORDER BY r.total_reviews DESC
LIMIT 20;

-- 2) Distribution of game release years
SELECT
    CASE
        WHEN LENGTH(g.release_date) = 4
            THEN CAST(g.release_date AS INTEGER)
        ELSE EXTRACT(
            YEAR FROM TRY_STRPTIME(g.release_date, '%d %b, %Y')
        )
    END AS release_year,
    COUNT(*) AS num_games
FROM games_clean g
GROUP BY release_year
ORDER BY release_year;

-- 3) Average price by genre
SELECT
    genre,
    ROUND(AVG(price_usd), 2) AS avg_price_usd
FROM games_clean
WHERE price_usd > 0
GROUP BY genre
ORDER BY avg_price_usd DESC;

-- 4) Most common tags across all games
SELECT
    tag,
    COUNT(*) AS games_count
FROM game_tags
GROUP BY tag
ORDER BY games_count DESC
LIMIT 20;


-- 5) Genres with higher average review scores
SELECT
    g.genre,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM games_clean g
JOIN reviews_clean r USING (app_id)
GROUP BY g.genre
HAVING AVG(r.review_score) IS NOT NULL
ORDER BY avg_review_score DESC;
