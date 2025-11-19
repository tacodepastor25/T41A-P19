-- Usar el esquema de la aplicación
SET search_path TO optimizacion, public;

-- 1_Tablas de Seguridad y Roles
CREATE TABLE roles (
    rol_id SERIAL PRIMARY KEY,
    nombre TEXT UNIQUE NOT NULL
);

CREATE TABLE usuarios (
    user_id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    rol_id INT REFERENCES roles(rol_id) NOT NULL
);

-- 2_Registro de Materia Prima (Lámina)
CREATE TABLE materia_prima (
    mp_id SERIAL PRIMARY KEY,
    numero_parte TEXT UNIQUE NOT NULL,
    dimension_largo NUMERIC NOT NULL CHECK (dimension_largo > 0),
    dimension_ancho NUMERIC NOT NULL CHECK (dimension_ancho > 0),
    distancia_min_piezas NUMERIC NOT NULL DEFAULT 0.0,
    distancia_min_orilla NUMERIC NOT NULL DEFAULT 0.0,
    area_total NUMERIC GENERATED ALWAYS AS (dimension_largo * dimension_ancho) STORED
);

-- 3_Gestión de Productos (Lo que se obtiene del corte)
CREATE TABLE productos (
    prod_id SERIAL PRIMARY KEY,
    numero_parte TEXT UNIQUE NOT NULL,
    descripcion TEXT,
    cantidad_piezas_requeridas INT NOT NULL CHECK (cantidad_piezas_requeridas > 0)
);

-- 4_Geometría y Piezas (Definición de lo que se va a cortar)
CREATE TABLE piezas (
    pieza_id SERIAL PRIMARY KEY,
    prod_id INT REFERENCES productos(prod_id) NOT NULL,
    nombre TEXT NOT NULL,
    area_pieza NUMERIC NOT NULL CHECK (area_pieza > 0),
    geometria_inicial GEOMETRY -- Geometría de la pieza (PostGIS/Native type)
);

-- 5_Registro de Configuración y Eventos de Corte
CREATE TABLE eventos (
    evento_id BIGSERIAL PRIMARY KEY,
    mp_id INT REFERENCES materia_prima(mp_id) NOT NULL,
    pieza_id INT REFERENCES piezas(pieza_id) NOT NULL,
    -- Geometría final con rotación y posición aplicadas
    geometria_final GEOMETRY,
    -- JSON para registrar la acción (rotación, ajuste, posición)
    payload JSONB NOT NULL,
    fecha_registro TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    registrado_por INT REFERENCES usuarios(user_id)
);

-- 6. Tabla de Aprovechamiento (Calculado)
CREATE TABLE aprovechamiento (
    mp_id INT PRIMARY KEY REFERENCES materia_prima(mp_id),
    area_utilizada NUMERIC NOT NULL DEFAULT 0.0,
    porcentaje_aprovechamiento NUMERIC NOT NULL DEFAULT 0.0
);
