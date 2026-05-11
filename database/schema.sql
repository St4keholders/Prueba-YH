-- Eliminar tablas si existen (por si había versiones previas)
DROP TABLE IF EXISTS reposition_priority;
DROP TABLE IF EXISTS repositon_priority;

-- Tabla de histórico de KPIs
CREATE TABLE IF NOT EXISTS kpi_history (
    id SERIAL PRIMARY KEY,
    kpi_name VARCHAR(50) NOT NULL,
    kpi_value DECIMAL(10,4) NOT NULL,
    status VARCHAR(10) CHECK (status IN ('OK', 'ALERTA')) NOT NULL,
    threshold DECIMAL(10,4) NOT NULL,
    timestamp TIMESTAMP NOT NULL
);

-- Tabla para top 5 críticos
CREATE TABLE reposition_priority (
    id SERIAL PRIMARY KEY,
    execution_ts TIMESTAMP NOT NULL,
    product_id INT NOT NULL,
    product_title TEXT,
    stock INT,
    rating DECIMAL(5,2),
    price DECIMAL(10,2),
    priority_score DECIMAL(10,2),
    rank_position INT
);

-- Índices para mejorar búsquedas
CREATE INDEX IF NOT EXISTS idx_kpi_name ON kpi_history(kpi_name);
CREATE INDEX IF NOT EXISTS idx_timestamp ON kpi_history(timestamp);

-- Tabla de productos (opcional, la usas si quieres guardar productos)
CREATE TABLE IF NOT EXISTS products (
    id INT PRIMARY KEY,
    title TEXT,
    description TEXT,
    category VARCHAR(100),
    price DECIMAL(10,2),
    discount_percentage DECIMAL(5,2),
    rating DECIMAL(3,2),
    stock INT,
    brand VARCHAR(100),
    sku VARCHAR(50),
    availability_status VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);