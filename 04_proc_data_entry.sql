SET search_path TO optimizacion, public;

-- Procedimiento para Alta de Materia Prima
CREATE OR REPLACE PROCEDURE sp_alta_materia_prima(
    p_numero_parte TEXT,
    p_largo NUMERIC,
    p_ancho NUMERIC,
    p_dist_min_p NUMERIC DEFAULT 0.0,
    p_dist_min_o NUMERIC DEFAULT 0.0
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO materia_prima (
        numero_parte, 
        dimension_largo, 
        dimension_ancho, 
        distancia_min_piezas, 
        distancia_min_orilla
    )
    VALUES (
        p_numero_parte, 
        p_largo, 
        p_ancho, 
        p_dist_min_p, 
        p_dist_min_o
    );
END;
$$;

-- Procedimiento para Alta de Productos
CREATE OR REPLACE PROCEDURE sp_alta_producto(
    p_numero_parte TEXT,
    p_descripcion TEXT,
    p_geometria_pieza GEOMETRY,
    p_area_pieza NUMERIC,
    p_cantidad_requerida INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_prod_id INT;
BEGIN
    -- 1_Insertar Producto
    INSERT INTO productos (numero_parte, descripcion, cantidad_piezas_requeridas)
    VALUES (p_numero_parte, p_descripcion, p_cantidad_requerida)
    RETURNING prod_id INTO v_prod_id;

    -- 2_Insertar Pieza base asociada
    INSERT INTO piezas (prod_id, nombre, area_pieza, geometria_inicial)
    VALUES (v_prod_id, 'Pieza Principal', p_area_pieza, p_geometria_pieza);
END;
$$;
