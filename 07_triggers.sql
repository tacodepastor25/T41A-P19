SET search_path TO optimizacion, public;

-- A_TRIGGER FUNCTION: Recalcula el aprovechamiento después de cada nuevo evento
CREATE OR REPLACE FUNCTION tgf_recalcular_aprovechamiento()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM fn_calcular_utilizacion(NEW.mp_id);
    RETURN NEW;
END;
$$;

-- A_TRIGGER: Se dispara después de insertar o actualizar un evento
CREATE TRIGGER tr_recalcular_aprovechamiento
AFTER INSERT OR UPDATE ON eventos
FOR EACH ROW
EXECUTE FUNCTION tgf_recalcular_aprovechamiento();

-- B_TRIGGER FUNCTION: Validar distancia mínima entre piezas (Simplificado)
CREATE OR REPLACE FUNCTION tgf_validar_parametros_mp()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    -- Ejemplo de validación de negocio: La distancia a la orilla no puede ser mayor a la mitad del ancho.
    IF NEW.distancia_min_orilla > (NEW.dimension_ancho / 2.0) THEN
        RAISE EXCEPTION 'La distancia mínima a la orilla (%) no puede exceder la mitad del ancho de la materia prima.', NEW.distancia_min_orilla;
    END IF;
    RETURN NEW;
END;
$$;

-- B_TRIGGER: Se dispara antes de insertar/actualizar Materia Prima para validación
CREATE TRIGGER tr_validar_parametros_mp
BEFORE INSERT OR UPDATE ON materia_prima
FOR EACH ROW
EXECUTE FUNCTION tgf_validar_parametros_mp();
