SET search_path TO optimizacion, public;

-- Procedimiento sp_rotar_posicionar_figuras
CREATE OR REPLACE PROCEDURE sp_rotar_posicionar_figuras(
    p_mp_id INT,
    p_pieza_id INT,
    p_usuario_id INT,
    p_payload JSONB
)
LANGUAGE plpgsql AS $$
DECLARE
    v_geometria_inicial GEOMETRY;
    v_geometria_final GEOMETRY;
    v_rotacion NUMERIC := (p_payload ->> 'rotacion')::NUMERIC;
    v_pos_x NUMERIC := (p_payload ->> 'posicion_x')::NUMERIC;
    v_pos_y NUMERIC := (p_payload ->> 'posicion_y')::NUMERIC;
    -- Aquí se usará una lógica conceptual simple, ya que el tipo GEOMETRY en PostgreSQL nativo no tiene funciones de rotación.
BEGIN
    -- 1_Obtener geometría inicial de la pieza
    SELECT geometria_inicial INTO v_geometria_inicial
    FROM piezas
    WHERE pieza_id = p_pieza_id;

    IF v_geometria_inicial IS NULL THEN
        RAISE EXCEPTION 'Pieza con ID % no encontrada.', p_pieza_id;
    END IF;

    -- 2_Simular la rotación y el posicionamiento (Lógica Conceptual)

    v_geometria_final := v_geometria_inicial; 

    -- 3_Registrar el evento y la nueva geometría
    INSERT INTO eventos (mp_id, pieza_id, geometria_final, payload, registrado_por)
    VALUES (p_mp_id, p_pieza_id, v_geometria_final, p_payload, p_usuario_id);

    RAISE NOTICE 'Evento de posicionamiento registrado para Pieza ID %.', p_pieza_id;
END;
$$;
