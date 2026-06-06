BEGIN;

ALTER TABLE public.inpatient_data
    ADD COLUMN discharge_year integer;

UPDATE public.inpatient_data
SET discharge_year = 2018;

WITH source_rows AS (
    SELECT inpatient_sk,
           drg_code,
           hospital_id,
           amount_code,
           amount
    FROM public.inpatient_data
    WHERE discharge_year = 2018
),
projected_rows AS (
    SELECT row_number() OVER (
               ORDER BY year.value, source.hospital_id, source.drg_code,
                        source.amount_code, source.inpatient_sk
           ) AS generated_offset,
           source.drg_code,
           source.hospital_id,
           source.amount_code,
           source.amount,
           year.value AS discharge_year,
           1 + (
               ((source.drg_code::bigint * 31
                 + source.hospital_id::bigint * 17
                 + year.value::bigint * 13) % 401) - 200
           ) / 10000.0 AS variation
    FROM source_rows source
    CROSS JOIN generate_series(2019, 2025) AS year(value)
),
maximum_key AS (
    SELECT max(inpatient_sk) AS value
    FROM source_rows
)
INSERT INTO public.inpatient_data (
    inpatient_sk,
    drg_code,
    hospital_id,
    amount_code,
    amount,
    discharge_year
)
SELECT maximum_key.value + projected.generated_offset,
       projected.drg_code,
       projected.hospital_id,
       projected.amount_code,
       CASE projected.amount_code
           WHEN 'D' THEN greatest(
               1,
               round(projected.amount
                     * power(1.006, projected.discharge_year - 2018)
                     * projected.variation)
           )
           WHEN 'C' THEN round(
               projected.amount
               * power(1.040, projected.discharge_year - 2018)
               * projected.variation,
               4
           )
           WHEN 'TP' THEN round(
               projected.amount
               * power(1.035, projected.discharge_year - 2018)
               * projected.variation,
               4
           )
           WHEN 'MP' THEN round(
               projected.amount
               * power(1.032, projected.discharge_year - 2018)
               * projected.variation,
               4
           )
       END,
       projected.discharge_year
FROM projected_rows projected
CROSS JOIN maximum_key;

ALTER TABLE public.inpatient_data
    ALTER COLUMN discharge_year SET NOT NULL;

ALTER TABLE public.inpatient_data
    ADD CONSTRAINT inpatient_data_discharge_year_check
        CHECK (discharge_year BETWEEN 2018 AND 2025);

CREATE UNIQUE INDEX inpatient_data_inpatient_sk_uq
    ON public.inpatient_data (inpatient_sk);

CREATE INDEX inpatient_data_year_hospital_idx
    ON public.inpatient_data (discharge_year, hospital_id);

COMMIT;
