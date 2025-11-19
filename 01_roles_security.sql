-- 1_Crear roles de la aplicación 
CREATE ROLE administrador NOLOGIN;
CREATE ROLE operador NOLOGIN;

-- 2_Crear usuarios y asignar roles
CREATE USER app_admin WITH PASSWORD 'superpass';
CREATE USER app_operador WITH PASSWORD 'opass';

GRANT administrador TO app_admin;
GRANT operador TO app_operador;

-- 3_Crear el esquema principal para la aplicación
CREATE SCHEMA IF NOT EXISTS optimizacion;
GRANT USAGE ON SCHEMA optimizacion TO administrador;
GRANT USAGE ON SCHEMA optimizacion TO operador;
