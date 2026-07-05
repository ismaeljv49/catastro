-- ============================================================
-- Tabla: reportes_ciudadanos
-- Almacena reportes de problemas urbanos con geolocalización
-- ============================================================

DROP TABLE IF EXISTS reportes_ciudadanos CASCADE;

CREATE TABLE reportes_ciudadanos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo_problema TEXT NOT NULL,
    comentario TEXT,
    direccion TEXT,
    latitud DOUBLE PRECISION NOT NULL,
    longitud DOUBLE PRECISION NOT NULL,
    estado TEXT NOT NULL DEFAULT 'pendiente',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Comentarios para documentar la tabla
COMMENT ON TABLE reportes_ciudadanos IS 'Reportes de problemas urbanos realizados por ciudadanos';
COMMENT ON COLUMN reportes_ciudadanos.tipo_problema IS 'Categoría del problema (bache, alumbrado, basura, etc.)';
COMMENT ON COLUMN reportes_ciudadanos.estado IS 'Estado del reporte: pendiente, en_proceso, resuelto';
COMMENT ON COLUMN reportes_ciudadanos.latitud IS 'Latitud del punto reportado';
COMMENT ON COLUMN reportes_ciudadanos.longitud IS 'Longitud del punto reportado';

-- Agregar columna geométrica PostGIS (punto, SRID 4326)
SELECT AddGeometryColumn('public', 'reportes_ciudadanos', 'geom', 4326, 'POINT', 2);

-- Función trigger: calcula automáticamente el geom antes de insertar
CREATE OR REPLACE FUNCTION set_reporte_geom()
RETURNS TRIGGER AS $$
BEGIN
    NEW.geom = ST_SetSRID(ST_MakePoint(NEW.longitud, NEW.latitud), 4326);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger que se ejecuta antes de cada INSERT
CREATE TRIGGER trg_set_reporte_geom
    BEFORE INSERT ON reportes_ciudadanos
    FOR EACH ROW
    EXECUTE FUNCTION set_reporte_geom();

-- Índices para consultas espaciales y de filtrado
CREATE INDEX idx_reportes_geom ON reportes_ciudadanos USING GIST (geom);
CREATE INDEX idx_reportes_estado ON reportes_ciudadanos (estado);
CREATE INDEX idx_reportes_tipo ON reportes_ciudadanos (tipo_problema);
CREATE INDEX idx_reportes_created ON reportes_ciudadanos (created_at DESC);

-- ============================================================
-- Permisos (ejecutar en SQL Editor de Supabase)
-- ============================================================

-- Permitir INSERT anónimo (para que ciudadanos puedan reportar sin login)
-- ALTER TABLE reportes_ciudadanos ENABLE ROW LEVEL SECURITY;
--
-- CREATE POLICY "Anon puede insertar reportes"
--     ON reportes_ciudadanos
--     FOR INSERT
--     TO anon
--     WITH CHECK (true);
--
-- CREATE POLICY "Anon puede leer reportes"
--     ON reportes_ciudadanos
--     FOR SELECT
--     TO anon
--     USING (true);
