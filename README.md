# Sistema de Monitoreo de Catalogo con KPIs, Agente de IA y Alertas Automatizadas

## 1. Objetivo

Automatizar el monitoreo del catalogo de productos mediante el calculo periodico de KPIs de calidad e inventario, la exposicion de esos datos a traves de un webhook, el envio de alertas por correo ante desviaciones, y la atencion a clientes y empleados mediante un agente conversacional de IA.

---

## 2. Arquitectura

```
DummyJSON API
     |
     v
[WF1 - Calculo de KPIs]  (cada 6h)
     |
     +---> PostgreSQL (tablas: kpi_history, reposition_priority)
     |
     +---> Gmail (alerta si catalog_quality_score < 0.80 o avg_priority_score > 50)

[WF2 - Webhook KPI]
     |
     +---> GET /webhook/kpi_actual --> SELECT en kpi_history --> respuesta JSON

[WF4 - Cargue de Inventario]  (cada 6h)
     |
     +---> DummyJSON API --> PostgreSQL (tabla: products)

[WF3 - Agente IA]
     |
     +-- Herramienta INVENTARIO --> PostgreSQL (tabla: products)   [clientes]
     |
     +-- Herramienta EMPLEADOS  --> WF1 (KPIs) + WF2 (webhook)   [empleados]
          |
          +-- Opcion 1: consulta reposition_priority
          +-- Opcion 2: registra y analiza KPIs desde kpi_history
```

El agente (WF3) distingue entre dos tipos de usuario en la conversacion. Si el usuario es cliente, consulta el inventario en PostgreSQL para responder preguntas sobre productos, precios y disponibilidad, y guia el proceso de venta hasta confirmar un pedido con contraentrega en Medellin. Si el usuario es empleado, puede consultar los productos que requieren reposicion urgente o revisar el estado actual de los KPIs con analisis e interpretacion automatica.

---

## 3. Tecnologias Utilizadas

| Componente | Rol |
|---|---|
| n8n | Orquestador de workflows y agente de IA |
| PostgreSQL | Almacenamiento de KPIs, historial e inventario |
| DummyJSON API | Fuente de datos de productos (simulacion de catalogo) |
| Gmail | Envio de alertas por correo electronico |
| OpenAI (GPT) | Modelo de lenguaje del agente conversacional (WF3) |

---

## 4. Supuestos y Umbrales

**KPI 1 - Catalog Quality Score**
- Se calcula como el promedio de tres porcentajes: productos con marca registrada, productos con imagenes y productos con dimensiones completas (ancho, alto, profundidad).
- Umbral: `0.80`. Se genera alerta y correo si el valor cae por debajo del 80%.

**KPI 2 - Average Priority Score**
- Mide la urgencia de reabastecimiento. Se calcula solo sobre productos con stock menor a 10 unidades, usando la formula: `priority_score = 1 * rating * price`.
- Umbral: `50.0`. Se genera alerta y correo si el promedio supera este valor.

**Frecuencia de ejecucion**
- WF1 (calculo de KPIs) y WF4 (cargue de inventario) se ejecutan automaticamente cada 6 horas.

**Inventario**
- Se carga desde `https://dummyjson.com/products?limit=100`, que devuelve hasta 100 productos en cada llamada.

**Agente conversacional**
- Opera en espanol o ingles segun el idioma del usuario.
- Solo atiende envios dentro de Medellin (Valle de Aburra) con tarifa fija de $15.000.
- Metodo de pago unico: contraentrega en efectivo.
- Nunca expone informacion de empleados (KPIs, reposiciones) a clientes.

**Webhook**
- El endpoint `GET /webhook/kpi_actual` devuelve el ultimo registro de `catalog_quality_score` en la tabla `kpi_history`.

---

## 5. Pasos para Ejecutar

### Requisitos previos

- Instancia de n8n activa (self-hosted o en la nube).
- Base de datos PostgreSQL accesible desde n8n.
- Cuenta de Gmail configurada para envio desde n8n.
- Credenciales de OpenAI con acceso al modelo requerido.

### Paso 1 - Crear las tablas en PostgreSQL

Ejecutar las siguientes sentencias en la base de datos:

```sql
CREATE TABLE IF NOT EXISTS kpi_history (
    id SERIAL PRIMARY KEY,
    kpi_name VARCHAR(100),
    kpi_value DECIMAL,
    status VARCHAR(20),
    threshold DECIMAL,
    timestamp TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS reposition_priority (
    id SERIAL PRIMARY KEY,
    execution_ts TIMESTAMPTZ,
    product_id INT,
    product_title TEXT,
    stock INT,
    rating DECIMAL,
    price DECIMAL,
    priority_score DECIMAL,
    rank_position BIGINT
);

CREATE TABLE IF NOT EXISTS products (
    id INT PRIMARY KEY,
    title TEXT,
    description TEXT,
    category VARCHAR(100),
    price DECIMAL,
    discount_percentage DECIMAL,
    rating DECIMAL,
    stock INT,
    brand VARCHAR(100),
    sku VARCHAR(100),
    availability_status VARCHAR(50),
    created_at TIMESTAMPTZ
);
```

### Paso 2 - Importar los workflows en n8n

1. Abrir la instancia de n8n.
2. Ir a **Workflows > Import from file**.
3. Importar los archivos en el siguiente orden:
   - `WF1_-_KPIs.json`
   - `WF2_-_Webhook_Consulta_KPI.json`
   - `WF4_Cargue_de_inventario.json`
   - `WF3_-_Agente_KPI_y_Atencion_al_cliente.json`

### Paso 3 - Configurar credenciales

Dentro de n8n, crear o asociar las siguientes credenciales en cada workflow:

| Credencial | Workflows que la usan |
|---|---|
| PostgreSQL (nombre sugerido: `Postgres PRUEBA`) | WF1, WF2, WF3, WF4 |
| Gmail OAuth2 | WF1 (nodo de envio de alerta) |
| OpenAI API Key | WF3 (modelo GPT) |

### Paso 4 - Verificar la direccion de correo de alertas

En WF1, el nodo de Gmail esta configurado para enviar alertas a `juanandresvm14@gmail.com`. Actualizar esta direccion si es necesario antes de activar el workflow.

### Paso 5 - Activar los workflows

Activar en este orden:

1. **WF4** - para cargar el inventario inicial de productos.
2. **WF1** - para iniciar el calculo y registro de KPIs.
3. **WF2** - para habilitar el endpoint webhook.
4. **WF3** - para poner en linea el agente conversacional.

Una vez activos, WF1 y WF4 se ejecutaran automaticamente cada 6 horas. WF2 quedara disponible en la URL `https://<tu-instancia-n8n>/webhook/kpi_actual`. WF3 estara accesible como chat publico desde la URL que n8n asigna al nodo `When chat message received`.

### Paso 6 - Prueba de funcionamiento

- Ejecutar WF4 manualmente para cargar el inventario antes de la primera ejecucion programada.
- Ejecutar WF1 manualmente para poblar `kpi_history` y `reposition_priority`.
- Llamar al endpoint `GET /webhook/kpi_actual` y verificar que retorna un JSON con `kpi_name`, `kpi_value`, `status`, `threshold` y `timestamp`.
- Abrir el chat del agente (WF3) y probar los flujos de cliente y empleado.
