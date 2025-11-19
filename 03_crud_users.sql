SET search_path TO optimizacion, public;

-- Inicializar Roles
INSERT INTO roles (nombre) VALUES ('Administrador'), ('Operador')
ON CONFLICT (nombre) DO NOTHING;

-- Procedimiento para Alta de Usuario 
CREATE OR REPLACE PROCEDURE sp_alta_usuario(
    p_nombre TEXT, 
    p_email TEXT, 
    p_rol_nombre TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_rol_id INT;
BEGIN
    SELECT rol_id INTO v_rol_id FROM roles WHERE nombre = p_rol_nombre;
    
    IF v_rol_id IS NULL THEN
        RAISE EXCEPTION 'El rol % no existe.', p_rol_nombre;
    END IF;

    INSERT INTO usuarios (nombre, email, rol_id)
    VALUES (p_nombre, p_email, v_rol_id);
    
    RAISE NOTICE 'Usuario % creado con éxito.', p_nombre;
END;
$$;

-- Función para Consultar Usuario 
CREATE OR REPLACE FUNCTION fn_get_usuario_by_email(p_email TEXT)
RETURNS TABLE(user_id INT, nombre TEXT, email TEXT, rol TEXT)
LANGUAGE sql AS $$
    SELECT 
        u.user_id, 
        u.nombre, 
        u.email, 
        r.nombre AS rol
    FROM 
        usuarios u
    JOIN 
        roles r ON u.rol_id = r.rol_id
    WHERE 
        u.email = p_email;
$$;

