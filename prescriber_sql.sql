--2. Specialty with the highest and lowest prescription cost per day?
WITH specialty_cost AS (
    SELECT
        pr.specialty_description,
        SUM(rx.total_drug_cost) / NULLIF(SUM(rx.total_day_supply), 0)
            AS cost_per_day
    FROM prescriber AS pr
    JOIN prescription AS rx
        ON pr.npi = rx.npi
    GROUP BY pr.specialty_description
)
(
    SELECT
        'Highest' AS cost_level,
        specialty_description,
        ROUND(cost_per_day::numeric, 2) AS cost_per_day
    FROM specialty_cost
    ORDER BY cost_per_day DESC
    LIMIT 1
)
UNION ALL
(
    SELECT
        'Lowest' AS cost_level,
        specialty_description,
        ROUND(cost_per_day::numeric, 2) AS cost_per_day
    FROM specialty_cost
    WHERE cost_per_day IS NOT NULL
    ORDER BY cost_per_day ASC
    LIMIT 1
);

--hightest cost_level is hematology-oncology 35.31
--lowest cost_lever is pyschologist,clinical 0.25
--Claude has the same answers as mine 
--3. Number of providers assigned to each specialty?
SELECT
    specialty_description,
    COUNT(DISTINCT npi) AS provider_count
FROM prescriber
GROUP BY specialty_description
ORDER BY provider_count DESC;

--number of providers assigned to each specialty
--Claude answers to proiders assigned to each specailty????/
--Claude anwers is---
SELECT specialty_description,
       COUNT(DISTINCT npi) AS provider_count
FROM prescriber
GROUP BY specialty_description
ORDER BY provider_count DESC;

3. Number of providers assigned to each specialty?

SELECT
    pr.specialty_description,
    COUNT(DISTINCT pr.npi) AS provider_count,
    CASE
        WHEN COUNT(DISTINCT rx.npi) > 0 THEN TRUE
        ELSE FALSE
    END AS has_written_prescription
FROM prescriber AS pr
LEFT JOIN prescription AS rx
    ON pr.npi = rx.npi
GROUP BY pr.specialty_description
ORDER BY provider_count DESC;

--Claude Answer is
SELECT pr.specialty_description,
       COUNT(DISTINCT pr.npi) AS provider_count,
       BOOL_OR(ps.npi IS NOT NULL) AS wrote_prescription
FROM prescriber pr
LEFT JOIN prescription ps ON pr.npi = ps.npi
GROUP BY pr.specialty_description
ORDER BY provider_count DESC;

--answers matched 

--5 Specialty that has written prescriptions with the most providers?
SELECT
    pr.specialty_description,
    COUNT(DISTINCT pr.npi) AS prescribing_provider_count
FROM prescriber AS pr
JOIN prescription AS rx
    ON pr.npi = rx.npi
GROUP BY pr.specialty_description
ORDER BY prescribing_provider_count DESC
LIMIT 1;

--claude answers
WITH spec_summary AS (
    SELECT pr.specialty_description,
           COUNT(DISTINCT pr.npi) AS provider_count,
           BOOL_OR(ps.npi IS NOT NULL) AS wrote_prescription
    FROM prescriber pr
    LEFT JOIN prescription ps ON pr.npi = ps.npi
    GROUP BY pr.specialty_description
)
SELECT * FROM spec_summary
WHERE wrote_prescription = TRUE
ORDER BY provider_count DESC
LIMIT 1;

--Even got my answer right still the numbers mismatch due the left join or maybe cite used??????????????????????

--6. Specialty with the most providers where none has written a prescription?
SELECT
    pr.specialty_description,
    COUNT(DISTINCT pr.npi) AS provider_count
FROM prescriber AS pr
LEFT JOIN prescription AS rx
    ON pr.npi = rx.npi
GROUP BY pr.specialty_description
HAVING COUNT(rx.npi) = 0
ORDER BY provider_count DESC
LIMIT 1;
--claude anwer is 
WITH spec_summary AS (
    SELECT pr.specialty_description,
           COUNT(DISTINCT pr.npi) AS provider_count,
           BOOL_OR(ps.npi IS NOT NULL) AS wrote_prescription
    FROM prescriber pr
    LEFT JOIN prescription ps ON pr.npi = ps.npi
    GROUP BY pr.specialty_description
)
SELECT * FROM spec_summary
WHERE wrote_prescription = FALSE
ORDER BY provider_count DESC
LIMIT 1;
--both anwers are the same

--8. Can we find prescribers who prescribed a drug to only one beneficiary?
SELECT
    npi,
    drug_name,
    bene_count
FROM prescription
WHERE bene_count = 1;

--claude answers is 
--claude is the same null so we have to come up with find out only the null numbers to get result 
SELECT npi, drug_name, bene_count, total_claim_count
FROM prescription
WHERE bene_count IS NULL;

--Part 2
--1. Get each distinct generic drug name?
SELECT DISTINCT
    generic_name
FROM drug
WHERE generic_name IS NOT NULL
ORDER BY generic_name;

--cluade answer is 
SELECT DISTINCT generic_name
FROM drug
ORDER BY generic_name;
--have some result 
--csv table in pgadmin

-------------------------------------------------------------------
--part 3 4. Find total day supply and total cost for each specialty and drug category?
CREATE TABLE drug_categories (
    generic_name TEXT PRIMARY KEY,
    category     TEXT NOT NULL
);


SELECT category, COUNT(*) 
FROM drug_categories 
GROUP BY category 
ORDER BY COUNT(*) DESC;

SELECT COUNT(*) AS unmatched
FROM drug d
LEFT JOIN drug_categories dc ON dc.generic_name = d.generic_name
WHERE dc.generic_name IS NULL;

SELECT p.specialty_description,
       dc.category                              AS drug_categories,
       SUM(rx.total_day_supply)                 AS total_day_supply,
       SUM(rx.total_drug_cost)::numeric(14,2)   AS total_cost
FROM prescription   rx
JOIN prescriber     p  ON p.npi           = rx.npi
JOIN drug           d  ON d.drug_name     = rx.drug_name
JOIN drug_categories  dc ON dc.generic_name = d.generic_name
GROUP BY p.specialty_description, dc.category
ORDER BY total_cost DESC;
