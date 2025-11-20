# test_project.py

import psycopg2
import pytest
import json

# --- Configuración de pruebas ---
DB_CONFIG = {
    "dbname": "test_db", 
    "user": "postgres", 
    "password": "postgres", 
    "host": "localhost"
}
MP_ID_TEST = 1
PIEZA_ID_TEST = 1
USER_ID_TEST = 1

# --- Funciones de utilidad ---
def run_query(query, fetch=True):
    with psycopg2.connect(**DB_CONFIG) as conn:
        with conn.cursor() as cur:
            cur.execute(query)
            if fetch:
                try:
                    return cur.fetchall()
                except psycopg2.ProgrammingError:
                    return []
            conn.commit()

# --- SETUP INICIAL PARA GARANTIZAR DATOS DE PRUEBA ---
@pytest.fixture(scope="session", autouse=True)
def setup_db():
    run_query("SET search_path TO optimizacion, public", fetch=False)
    
    # 1_Crear usuario Admin 
    run_query("CALL sp_alta_usuario('Admin Test', 'test@admin.com', 'Administrador')", fetch=False)
    
    # 2_Alta de Materia Prima 
    run_query("CALL sp_alta_materia_prima('MP-LAM-001', 100.0, 50.0, 1.0, 2.0)", fetch=False) # Área total: 5000
    
    # 3_Alta de Producto/Pieza (PROD_ID=1, PIEZA_ID=1)
    # Geometría 'POLYGON' simple y Área 100.0
    run_query(f"""
        CALL sp_alta_producto(
            'PROD-SQ-001', 
            'Pieza Cuadrada de 10x10', 
            'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))', 
            100.0, 
            5
        )
    """, fetch=False)
    
    # 4_Obtener IDs para usar en las pruebas
    global MP_ID_TEST, PIEZA_ID_TEST, USER_ID_TEST
    MP_ID_TEST = run_query("SELECT mp_id FROM materia_prima WHERE numero_parte = 'MP-LAM-001'")[0][0]
    PIEZA_ID_TEST = run_query("SELECT pieza_id FROM piezas WHERE prod_id = 1")[0][0]
    USER_ID_TEST = run_query("SELECT user_id FROM usuarios WHERE email = 'test@admin.com'")[0][0]


# Pruebas de Rubrica

## PRUEBAS DE TRIGGERS
def test_trigger_validation_mp_fail():
    """Verifica que el trigger B (Validación) bloquee una inserción inválida."""
    # Ancho 50, mitad 25. Intentamos distancia_min_orilla = 30
    with pytest.raises(psycopg2.errors.RaiseException) as excinfo:
        run_query("CALL sp_alta_materia_prima('MP-FAIL-TRIG', 10.0, 50.0, 0.0, 30.0)", fetch=False)
    assert 'La distancia mínima a la orilla' in str(excinfo.value)

## PRUEBAS DE PROCEDIMIENTOS (Rotación/Posicionamiento - 06_proc_placement.sql)
def test_proc_rotar_posicionar_figuras():
    """Verifica que el procedimiento de posicionamiento registre el evento JSON."""
    payload = json.dumps({
        "rotacion": 45.0, 
        "posicion_x": 10.0, 
        "posicion_y": 5.0
    })
    
    run_query(
        f"CALL sp_rotar_posicionar_figuras({MP_ID_TEST}, {PIEZA_ID_TEST}, {USER_ID_TEST}, '{payload}'::JSONB)", 
        fetch=False
    )
    
    # Verificar que se insertó el evento
    result = run_query(f"SELECT payload->>'rotacion' FROM eventos WHERE pieza_id = {PIEZA_ID_TEST} ORDER BY evento_id DESC LIMIT 1")
    assert result is not None
    assert result[0][0] == "45.0"
    
## PRUEBAS DE FUNCIONES (Cálculo de Utilización - 05_func_utilization.sql)
def test_func_calcular_utilizacion():
    """Verifica el cálculo de aprovechamiento y la actualización de la tabla aprovechamiento."""
    # 1_Ejecutar la función
    # Se insertó 1 evento (arriba), área de la pieza es 100.0
    # Área total MP = 5000.0
    # Utilización esperada: (100.0 / 5000.0) * 100 = 2.0%
    
    query_result = run_query(f"SELECT fn_calcular_utilizacion({MP_ID_TEST})")
    utilizacion_calculada = query_result[0][0]
    
    # Verificar el valor retornado
    assert utilizacion_calculada == pytest.approx(2.0), "La utilización calculada no es 2.0%"
    
    # 2_Verificar la actualización del trigger (o la función, ya que la función actualiza la tabla)
    aprov_db = run_query(f"SELECT porcentaje_aprovechamiento FROM aprovechamiento WHERE mp_id = {MP_ID_TEST}")
    assert aprov_db is not None
    assert aprov_db[0][0] == pytest.approx(2.0), "La tabla aprovechamiento no se actualizó correctamente."
