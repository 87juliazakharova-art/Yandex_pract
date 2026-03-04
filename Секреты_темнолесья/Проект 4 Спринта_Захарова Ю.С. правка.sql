/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Захарова Юлия
 * Дата: 25.01.2025
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:

SELECT
    COUNT(id) AS total_users,
    SUM(CASE WHEN payer = 1 THEN 1 ELSE 0 END) AS paying_users,
    ROUND(SUM(CASE WHEN payer = 1 THEN 1 ELSE 0 END)::decimal / COUNT(id), 3) AS paying_ratio
FROM
    fantasy.users;

-- Таблица:
--total_users|paying_users|paying_ratio|
-------------+------------+------------+
--      22214|        3929|       0.177|
--  Почти 18% зарегистрированных пользователей купили внутриигровую валюту «райские лепестки» за реальные деньги 

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:

SELECT
    r.race AS race_name,
    COUNT(u.id) AS total_players,
    COUNT(CASE WHEN u.payer = 1 THEN 1 END) AS paying_players,
    (COUNT(CASE WHEN u.payer = 1 THEN 1 END)::decimal / NULLIF(COUNT(u.id), 0))::NUMERIC(10, 3) AS paying_ratio
FROM
    fantasy.users u
JOIN
    fantasy.race r ON u.race_id = r.race_id
GROUP BY
    r.race
ORDER BY
    COUNT(u.id) ASC;


--Таблица:
--race_name|total_players|paying_players|paying_ratio|
-----------+-------------+--------------+------------+
--Demon    |         1229|           238|       0.194|
--Angel    |         1327|           229|       0.173|
--Elf      |         2501|           427|       0.171|
--Northman |         3562|           626|       0.176|
--Orc      |         3619|           636|       0.176|
--Hobbit   |         3648|           659|       0.181|
--Human    |         6328|          1114|       0.176|

-- доля платящих игроков от общего количества пользователей, зарегистрированных в игре в разрезе каждой расы персонажа примерно одинакова - колеблется в пределах
-- 17-19%. Самый высокий показатель у рассы Демонов, самый низкий - у Эльфов. При этом, больше всего покупок по количеству совершено в рассе Людей.

--Доля платящих пользователей в разрезе расы персонажа без нулевых покупок:

SELECT
    r.race AS race_name,
    COUNT(DISTINCT u.id) AS total_players,
    COUNT(CASE WHEN u.payer = 1 THEN 1 END) AS paying_players,
    (COUNT(CASE WHEN u.payer = 1 THEN 1 END)::decimal / NULLIF(COUNT(DISTINCT u.id), 0))::NUMERIC(10, 3) AS paying_ratio
FROM
    fantasy.users u
JOIN
    fantasy.race r ON u.race_id = r.race_id
WHERE
    u.id IN (SELECT DISTINCT e.id FROM fantasy.events e)
GROUP BY
    r.race
ORDER BY
    COUNT(DISTINCT u.id) ASC;

--Таблица:
--race_name|total_players|paying_players|paying_ratio|
-----------+-------------+--------------+------------+
--Demon    |          737|           147|       0.199|
--Angel    |          820|           137|       0.167|
--Elf      |         1543|           251|       0.163|
--Northman |         2229|           406|       0.182|
--Hobbit   |         2267|           401|       0.177|
--Orc      |         2276|           396|       0.174|
--Human    |         3921|           706|       0.180|

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:

SELECT 
    COUNT(*) AS total_purchases,
    SUM(amount) AS total_spent,
    MIN(amount) AS min_purchase,
    MAX(amount) AS max_purchase,
    ROUND(AVG(amount)::numeric, 2) AS average_purchase,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount)::numeric, 2) AS median_purchase,
    ROUND(STDDEV(amount)::numeric, 2) AS stddev_purchase
FROM 
    fantasy.events;

--Таблица:
--total_purchases|total_spent|min_purchase|max_purchase|average_purchase|median_purchase|stddev_purchase|
-----------------+-----------+------------+------------+----------------+---------------+---------------+
--        1307678|  686615040|         0.0|    486615.1|          525.69|          74.86|        2517.35|

--Статистические показатели по полю amount без нулевых покупок:

SELECT 
    COUNT(*) AS total_purchases,
    SUM(amount) AS total_spent,
    MIN(amount) AS min_purchase,
    MAX(amount) AS max_purchase,
    ROUND(AVG(amount)::numeric, 2) AS average_purchase,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount)::numeric, 2) AS median_purchase,
    ROUND(STDDEV(amount)::numeric, 2) AS stddev_purchase
FROM 
    fantasy.events
WHERE 
    amount > 0;

--Таблица
--total_purchases|total_spent|min_purchase|max_purchase|average_purchase|median_purchase|stddev_purchase|
-----------------+-----------+------------+------------+----------------+---------------+---------------+
--        1306771|  686615040|        0.01|    486615.1|          526.06|          74.86|        2518.18|

-- 2.2: Аномальные нулевые покупки:

SELECT 
    COUNT(CASE WHEN amount = 0 THEN 1 END) AS zero_cost_purchases,
    COUNT(*) AS total_purchases,
    ROUND(COUNT(CASE WHEN amount = 0 THEN 1 END)::NUMERIC / COUNT(*),5) AS zero_cost_ratio
FROM 
    fantasy.events;

--zero_cost_purchases|total_purchases|zero_cost_ratio|
---------------------+---------------+---------------+
--                907|        1307678|        0.00069|

--Тип предметов, которые приобретались за нулевую стоимость:

SELECT 
    i.game_items AS item_name,
    COUNT(e.transaction_id) AS purchase_count
FROM 
    fantasy.events e
JOIN 
    fantasy.items i ON e.item_code = i.item_code
WHERE 
    e.amount = 0
GROUP BY 
    i.game_items
ORDER BY 
    purchase_count ASC;

--Таблица

--item_name      |purchase_count|
-----------------+--------------+
--Book of Legends|           907|

--Вывод информации о количетсве нулевых покупок на пользователя:

SELECT 
    e.id AS player_id,
    COUNT(e.transaction_id) AS zero_purchase_count
FROM 
    fantasy.events e
WHERE 
    e.amount = 0
GROUP BY 
    e.id
HAVING 
    COUNT(e.transaction_id) > 1;

--Таблица: 
--player_id |zero_purchase_count|
------------+-------------------+
--01-0074905|                  3|
--05-4786250|                  2|
--06-2087517|                  6|
--06-5381730|                  2|
--10-9330719|                  5|
--12-1058351|                810|
--35-9222579|                  2|
--42-0460342|                  6|
--43-1868563|                  2|
--60-9357143|                  2|
--68-7223575|                  2|
--72-8559492|                  3|
--91-5947409|                  2|
--98-9613732|                  2|

--Данные по пользователю с id 12-1058351:

SELECT 
    u.id,
    u.tech_nickname,
    u.birthdate,
    u.registration_dt,
    u.server,
    co.location AS country_name
FROM 
    fantasy.users u
LEFT JOIN 
    fantasy.country co ON u.loc_id = co.loc_id
WHERE 
    u.id = '12-1058351';

--Таблица
--id        |tech_nickname       |birthdate |registration_dt|server  |country_name |
------------+--------------------+----------+---------------+--------+-------------+
--12-1058351|MajesticGuardian6128|12/13/2004|11/19/2006     |server_1|United States|

--выявление годов и числа нулевых покупок по этому пользователю с разбивкой по месяцам:

SELECT 
    EXTRACT(YEAR FROM e.date::date) AS purchase_year,
    EXTRACT(MONTH FROM e.date::date) AS purchase_month,
    COUNT(e.transaction_id) AS zero_purchase_count
FROM 
    fantasy.events e
WHERE 
    e.id = '12-1058351'
    AND e.amount = 0
GROUP BY 
    purchase_year, purchase_month
ORDER BY 
    zero_purchase_count DESC;

--purchase_year|purchase_month|zero_purchase_count|
---------------+--------------+-------------------+
--         2020|             2|                428|
--         2020|             4|                174|
--         2020|             3|                110|
--         2020|             5|                 96|
--         2020|             1|                  2|

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:

--общие данные:

WITH player_purchase_data AS (
    SELECT 
        u.id,
        u.payer,
        COUNT(e.transaction_id) AS total_purchases,
        SUM(e.amount) AS total_spent
    FROM 
        fantasy.users u
    INNER JOIN 
        fantasy.events e USING (id)
    WHERE 
        e.amount > 0
    GROUP BY 
        u.id, u.payer
),
purchasing_users AS (
    SELECT DISTINCT id, payer
    FROM player_purchase_data
)
SELECT 
    CASE 
        WHEN pu.payer = 1 THEN 'Платящие игроки'
        ELSE 'Неплатящие игроки'
    END AS player_group,
    COUNT(pu.id) AS total_players,
    SUM(ppd.total_purchases) AS total_purchases,
    ROUND(CASE 
        WHEN COUNT(pu.id) > 0 THEN SUM(ppd.total_purchases) :: NUMERIC / COUNT(pu.id)
        ELSE 0
    END, 2) AS average_purchases_per_player,
    ROUND(CASE 
        WHEN COUNT(pu.id) > 0 THEN SUM(ppd.total_spent) :: NUMERIC / COUNT(pu.id)
        ELSE 0
    END, 2) AS average_spent_per_player
FROM 
    purchasing_users pu
JOIN 
    player_purchase_data ppd USING (id)
GROUP BY 
    pu.payer;

--Таблица
--player_group     |total_players|total_purchases|average_purchases_per_player|average_spent_per_player|
-------------------+-------------+---------------+----------------------------+------------------------+
--Неплатящие игроки|        11348|        1107145|                       97.56|                48631.65|
--Платящие игроки  |         2444|         199626|                       81.68|                55467.68|

--Данные с разбивкой по расе:

WITH player_purchase_data AS (
    SELECT 
        u.id,
        u.payer,
        r.race AS race_name,
        COUNT(e.transaction_id) AS total_purchases,
        SUM(e.amount) AS total_spent
    FROM 
        fantasy.users u
    INNER JOIN 
        fantasy.events e USING (id)
    LEFT JOIN 
        fantasy.race r ON u.race_id = r.race_id
    WHERE 
        e.amount > 0
    GROUP BY 
        u.id, u.payer, r.race
),
purchasing_users AS (
    SELECT DISTINCT id, payer, race_name
    FROM player_purchase_data
)
SELECT 
    CASE 
        WHEN pu.payer = 1 THEN 'Платящие игроки'
        ELSE 'Неплатящие игроки'
    END AS player_group,
    pu.race_name AS race,
    COUNT(pu.id) AS total_players,
    SUM(ppd.total_purchases) AS total_purchases,
    ROUND(CASE 
        WHEN COUNT(pu.id) > 0 THEN SUM(ppd.total_purchases) :: NUMERIC / COUNT(pu.id)
        ELSE 0
    END, 2) AS average_purchases_per_player,
    ROUND(CASE 
        WHEN COUNT(pu.id) > 0 THEN SUM(ppd.total_spent) :: NUMERIC / COUNT(pu.id)
        ELSE 0
    END, 2) AS average_spent_per_player
FROM 
    purchasing_users pu
JOIN 
    player_purchase_data ppd USING (id)
GROUP BY 
    pu.payer, pu.race_name
ORDER BY 
    player_group DESC,
    race ASC;

--Таблица
--player_group     |race    |total_players|total_purchases|average_purchases_per_player|average_spent_per_player|
-------------------+--------+-------------+---------------+----------------------------+------------------------+
--Платящие игроки  |Angel   |          137|          19199|                      140.14|                44359.85|
--Платящие игроки  |Demon   |          147|          11844|                       80.57|                31069.46|
--Платящие игроки  |Elf     |          251|          16713|                       66.59|                50908.76|
--Платящие игроки  |Hobbit  |          401|          37861|                       94.42|                42651.87|
--Платящие игроки  |Human   |          706|          65963|                       93.43|                47260.76|
--Платящие игроки  |Northman|          406|          21796|                       53.68|               115727.09|
--Платящие игроки  |Orc     |          396|          26250|                       66.29|                37085.61|
--Неплатящие игроки|Angel   |          683|          68381|                      100.12|                49532.94|
--Неплатящие игроки|Demon   |          590|          45546|                       77.20|                43720.85|
--Неплатящие игроки|Elf     |         1292|         104861|                       81.16|                54315.87|
--Неплатящие игроки|Hobbit  |         1865|         157307|                       84.35|                48689.33|
--Неплатящие игроки|Human   |         3215|         410055|                      127.54|                49310.11|
--Неплатящие игроки|Northman|         1823|         161209|                       88.43|                50671.04|
--Неплатящие игроки|Orc     |         1880|         159786|                       84.99|                42744.63|

-- 2.4: Популярные эпические предметы:

WITH total_sales AS (
    SELECT 
        COUNT(*) AS total_sales_count
    FROM 
        fantasy.events
    WHERE 
        amount > 0
),
item_sales AS (
    SELECT 
        e.item_code,
        COUNT(e.transaction_id) AS item_sales_count,
        COUNT(DISTINCT e.id) AS unique_buyers
    FROM 
        fantasy.events e
    WHERE 
        e.amount > 0
    GROUP BY 
        e.item_code
)
SELECT 
    it.game_items,
    isa.item_sales_count,
    ROUND((isa.item_sales_count::NUMERIC / ts.total_sales_count), 4) AS sales_ratio,
    isa.unique_buyers,
    ROUND((isa.unique_buyers::NUMERIC / (SELECT COUNT(DISTINCT id) FROM fantasy.users)), 4) AS buyer_ratio
FROM 
    item_sales isa
JOIN 
    fantasy.items it ON isa.item_code = it.item_code
JOIN 
    total_sales ts ON true  
WHERE 
    isa.item_sales_count > 0
ORDER BY 
    isa.item_sales_count DESC
LIMIT 10;

--Таблица 
--game_items          |item_sales_count|sales_ratio|unique_buyers|buyer_ratio|
----------------------+----------------+-----------+-------------+-----------+
--Book of Legends     |         1004516|     0.7687|        12194|     0.5489|
--Bag of Holding      |          271875|     0.2081|        11968|     0.5388|
--Necklace of Wisdom  |           13828|     0.0106|         1627|     0.0732|
--Gems of Insight     |            3833|     0.0029|          926|     0.0417|
--Treasure Map        |            3084|     0.0024|          753|     0.0339|
--Amulet of Protection|            1078|     0.0008|          445|     0.0200|
--Silver Flask        |             795|     0.0006|          633|     0.0285|
--Strength Elixir     |             580|     0.0004|          331|     0.0149|
--Glowing Pendant     |             563|     0.0004|          354|     0.0159|
--Gauntlets of Might  |             514|     0.0004|          281|     0.0126|

--Непопулярные эпические предметы, которые не кукпили ни разу:

SELECT 
    i.item_code,
    i.game_items
FROM 
    fantasy.items i
LEFT JOIN 
    fantasy.events e ON i.item_code = e.item_code AND e.amount > 0
WHERE 
    e.transaction_id IS NULL;

--Количество ни разу не купленных эпических предметов:


SELECT 
    COUNT(i.item_code) AS un_purchased_items_count
FROM 
    fantasy.items i
LEFT JOIN 
    fantasy.events e ON i.item_code = e.item_code AND e.amount > 0
WHERE 
    e.transaction_id IS NULL;

--Таблица 
--un_purchased_items_count|
--------------------------+
--                      39|


-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:


WITH player_activity AS (
    SELECT
        r.race AS race_name,
        COUNT(DISTINCT u.id) AS total_players, -- Общее количество зарегистрированных игроков
        COUNT(DISTINCT CASE WHEN e.transaction_id IS NOT NULL AND e.amount > 0 THEN u.id END) AS buyers, -- Количество игроков, которые совершили покупки (исключая нулевые)
        COUNT(DISTINCT CASE WHEN u.payer = 1 AND e.amount > 0 THEN u.id END) AS paying_players, -- Количество платящих игроков с ненулевой суммой покупок
        COUNT(CASE WHEN e.amount > 0 THEN e.transaction_id END) AS total_purchases, -- Общее количество покупок (исключая нулевые)
        SUM(CASE WHEN e.amount > 0 THEN e.amount END) AS total_spent -- Общая стоимость всех покупок (исключая нулевые)
    FROM
        fantasy.users u
    LEFT JOIN
        fantasy.events e ON u.id = e.id AND e.amount > 0 -- Исключение покупок с нулевой стоимостью
    JOIN
        fantasy.race r ON u.race_id = r.race_id
    GROUP BY
        r.race
)
SELECT
    race_name,
    total_players,
    buyers,
    paying_players,
    ROUND(buyers::NUMERIC / NULLIF(total_players, 0), 4) AS buyer_ratio, -- Доля игроков, совершивших покупки
    ROUND(paying_players::NUMERIC / NULLIF(buyers, 0), 4) AS paying_ratio, -- Доля платящих игроков среди покупателей
    ROUND(total_purchases::NUMERIC / NULLIF(buyers, 0), 2) AS avg_purchases_per_player, -- Среднее количество покупок на покупателя
    ROUND(total_spent::NUMERIC / NULLIF(total_purchases, 0), 2) AS avg_spent_per_purchase, -- Средняя стоимость одной покупки
    ROUND(total_spent::NUMERIC / NULLIF(buyers, 0), 2) AS avg_spent_per_buyer, -- Средняя сумма потраченная на покупателя
    ROUND(total_spent::NUMERIC / NULLIF(total_players, 0), 2) AS avg_total_spent_per_player -- Средняя суммарная стоимость всех покупок на одного игрока
FROM
    player_activity
ORDER BY
    avg_purchases_per_player DESC;



--Таблица
--race_name|total_players|buyers|paying_players|buyer_ratio|paying_ratio|avg_purchases_per_player|avg_spent_per_purchase|avg_spent_per_buyer|avg_total_spent_per_player|
-----------+-------------+------+--------------+-----------+------------+------------------------+----------------------+-------------------+--------------------------+
--Human    |         6328|  3921|           706|     0.6196|      0.1801|                  121.40|                403.09|           48935.99|                  30322.06|
--Angel    |         1327|   820|           137|     0.6179|      0.1671|                  106.80|                455.65|           48665.61|                  30072.19|
--Hobbit   |         3648|  2266|           401|     0.6212|      0.1770|                   86.13|                552.92|           47622.68|                  29581.41|
--Northman |         3562|  2229|           406|     0.6258|      0.1821|                   82.10|                761.49|           62519.96|                  39123.25|
--Orc      |         3619|  2276|           396|     0.6289|      0.1740|                   81.74|                510.93|           41762.57|                  26264.60|
--Elf      |         2501|  1543|           251|     0.6170|      0.1627|                   78.79|                682.33|           53760.92|                  33167.97|
--Demon    |         1229|   737|           147|     0.5997|      0.1995|                   77.87|                529.02|           41194.98|                  24703.58|

-- Задача 2: Частота покупок

WITH player_activity AS (
    SELECT
        r.race AS race_name,
        COUNT(DISTINCT u.id) AS total_players,  -- Общее количество зарегистрированных игроков
        COUNT(DISTINCT CASE WHEN e.transaction_id IS NOT NULL THEN u.id END) AS buyers,  -- Количество игроков, которые совершили покупки
        COUNT(DISTINCT CASE WHEN u.payer = 1 AND e.amount > 0 THEN u.id END) AS paying_players,  -- Количество платящих игроков с ненулевой суммой покупок
        COUNT(e.transaction_id) FILTER (WHERE u.payer = 1 AND e.amount > 0) AS total_purchases,  -- Общее количество покупок платящих игроков
        SUM(e.amount) FILTER (WHERE u.payer = 1 AND e.amount > 0) AS total_spent,  -- Общая стоимость всех покупок платящих игроков
        AVG(CASE WHEN u.payer = 1 AND e.amount > 0 THEN e.amount END) AS avg_purchase_amount_per_transaction  -- Средняя стоимость одной ненулевой покупки платящих игроков
    FROM
        fantasy.users u
    LEFT JOIN
        fantasy.events e USING (id)
    JOIN
        fantasy.race r ON u.race_id = r.race_id
    WHERE 
        e.amount > 0 OR e.amount IS NULL
    GROUP BY
        r.race
)
SELECT
    pa.race_name,
    pa.total_players,
    pa.buyers,
    pa.paying_players,
    ROUND((pa.buyers::NUMERIC / NULLIF(pa.total_players, 0)), 4) AS buyer_ratio,  -- Доля игроков, совершивших покупки
    ROUND((pa.paying_players::NUMERIC / NULLIF(pa.buyers, 0)), 4) AS paying_ratio,  -- Доля платящих игроков среди покупателей
    ROUND((pa.total_purchases::NUMERIC / NULLIF(pa.paying_players, 0)), 2) AS avg_purchases_per_player,  -- Среднее количество покупок на одного платящего игрока
    ROUND((pa.total_spent::NUMERIC / NULLIF(pa.total_purchases, 0)), 2) AS avg_spent_per_purchase,  -- Средняя стоимость одной покупки на платящего игрока
    ROUND((pa.total_spent::NUMERIC / NULLIF(pa.paying_players, 0)), 2) AS avg_total_spent_per_player  -- Средняя суммарная стоимость всех покупок на одного платящего игрока
FROM 
    player_activity pa
ORDER BY 
    avg_purchases_per_player DESC;  -- Сортировка по среднему количеству покупок на платящего игрока в порядке убывания
    
    WITH PurchaseDays AS (
    SELECT 
        e.id AS player_id,
        COUNT(e.transaction_id) AS total_purchases,
        AVG(days_between) AS avg_days_between
    FROM (
        SELECT 
            id,
            transaction_id,
            date::date AS purchase_date,
            amount,
            (date::date - LAG(date::date) OVER (PARTITION BY id ORDER BY date)) AS days_between
        FROM 
            fantasy.events
        WHERE 
            amount > 0  -- Исключаем покупки с нулевой стоимостью
    ) AS e
    JOIN 
        fantasy.users u ON e.id = u.id
    GROUP BY 
        e.id
    HAVING 
        COUNT(e.transaction_id) >= 25  -- Учитываем только тех, у кого 25 и более покупок
),
RankedPlayers AS (
    SELECT 
        player_id,
        total_purchases,
        avg_days_between,
        NTILE(3) OVER (ORDER BY avg_days_between ASC) AS purchase_group  -- Разделяем на 3 группы по возрастанию avg_days_between
    FROM 
        PurchaseDays
),
UniquePayingPlayers AS (
    SELECT DISTINCT 
        e.id AS player_id
    FROM 
        fantasy.events e
    JOIN 
        fantasy.users u ON e.id = u.id
    WHERE 
        e.amount > 0 AND u.payer = 1  -- Учитываем только платящих игроков с ненулевыми суммами
)
SELECT 
    CASE 
        WHEN purchase_group = 1 THEN 'высокая частота'
        WHEN purchase_group = 2 THEN 'умеренная частота'
        ELSE 'низкая частота'
    END AS frequency_category,
    COUNT(rp.player_id) AS number_of_players,  -- Количество игроков с ненулевыми покупками (>= 25)
    COUNT(up.player_id) AS number_of_paying_players,  -- Количество уникальных платящих игроков с ненулевыми покупками
    ROUND(COUNT(up.player_id)::decimal / NULLIF(COUNT(rp.player_id), 0), 2) AS paying_share,  -- Доля платящих игроков от общего числа
    ROUND(AVG(total_purchases), 2) AS avg_purchases_per_player,  -- Среднее количество покупок на игрока
    ROUND(AVG(avg_days_between), 2) AS avg_days_between_purchases_per_player  -- Среднее количество дней между покупками на игрока
FROM 
    RankedPlayers rp
LEFT JOIN 
    UniquePayingPlayers up ON rp.player_id = up.player_id
GROUP BY 
    purchase_group
ORDER BY 
    purchase_group;

--Таблица
--frequency_category|number_of_players|number_of_paying_players|paying_share|avg_purchases_per_player|avg_days_between_purchases_per_player|
--------------------+-----------------+------------------------+------------+------------------------+-------------------------------------+
--высокая частота   |             2572|                     473|        0.18|                  390.66|                                 3.29|
--умеренная частота |             2572|                     450|        0.17|                   58.81|                                 7.54|
--низкая частота    |             2572|                     434|        0.17|                   33.64|                                13.29|


