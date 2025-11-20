SET search_path TO optimizacion, public;

-- Función para calcular el porcentaje de aprovechamiento de la materia prima.
CREATE OR REPLACE FUNCTION fn_calcular_utilizacion(
    p_mp_id INT
)
RETURNS NUMERIC
LANGUAGE plpgsql AS $$
DECLARE
    v_area_total NUMERIC;
    v_area_piezas_colocadas NUMERIC;
    v_aprovechamiento NUMERIC;
    v_area_utilizada_total NUMERIC;
BEGIN
    -- 1. Obtener área total de la materia prima
    SELECT area_total INTO v_area_total
    FROM materia_prima
    WHERE mp_id = p_mp_id;

    IF v_area_total IS NULL OR v_area_total = 0 THEN
        RETURN 0.0; -- Evitar división por cero
    END IF;

    -- 2_Calcular el área total utilizada por las geometrías finales (sumando el área de todas las piezas colocadas)

    SELECT 
        COALESCE(SUM(pi.area_pieza), 0)
    INTO 
        v_area_piezas_colocadas
    FROM 
        eventos ev
    JOIN 
        piezas pi ON ev.pieza_id = pi.pieza_id
    WHERE 
        ev.mp_id = p_mp_id;
        
    v_area_utilizada_total := v_area_piezas_colocadas; -- Asumimos que esta es el área ocupada

    -- 3_Calcular el porcentaje de aprovechamiento
    v_aprovechamiento := (v_area_utilizada_total / v_area_total) * 100.0;

    -- 4_Actualizar la tabla de aprovechamiento
    INSERT INTO aprovechamiento (mp_id, area_utilizada, porcentaje_aprovechamiento)
    VALUES (p_mp_id, v_area_utilizada_total, v_aprovechamiento)
    ON CONFLICT (mp_id) DO UPDATE
    SET 
        area_utilizada = EXCLUDED.area_utilizada,
        porcentaje_aprovechamiento = EXCLUDED.porcentaje_aprovechamiento;

    RETURN v_aprovechamiento;
END;
$$;
