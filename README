# 🌸 Iris Telemetry App

A Shiny application built on R's `iris` dataset, instrumented with **OpenTelemetry** (OTel) to export traces, metrics, and logs to [Grafana Cloud](https://grafana.com/products/cloud/).

---

## 📋 Overview

This app lets users interactively filter the `iris` dataset by species and minimum sepal length, visualizing results as a scatter plot and a data table. Every user interaction, filter execution, and render event is fully observable via OTel signals sent to a Grafana OTLP endpoint.

---

## 🚀 Features

- **Interactive filtering** by species and sepal length
- **Scatter plot** of Sepal Length vs. Sepal Width
- **Data table** showing the top 10 filtered rows
- **Distributed tracing** for filter, plot, and table render operations
- **Metrics** tracking filter executions, rows returned, plot/table renders, and input changes
- **Structured logging** for all key events with session and user context

---

## 📦 Dependencies

This project uses [`renv`](https://rstudio.github.io/renv/) for dependency management.

Key packages:

| Package | Purpose |
|---------|---------|
| `shiny` | Web application framework |
| `dplyr` | Data filtering |
| `otel` | OpenTelemetry API for R |
| `otelsdk` | OpenTelemetry SDK for R |
| `box` | Module-style imports |

---

## ⚙️ Setup

### 1. Clone the repository

```bash
git clone https://github.com/pieriponcwbd/iris_telemetry_app.git
cd iris_telemetry_app
```

### 2. Restore dependencies

Open R in the project directory and run:

```r
renv::restore()
```

### 3. Configure environment variables

Create a `.Renviron` file in the project root (or edit your existing one). This file is **not committed to the repo** for security reasons.

```env
OTEL_SERVICE_NAME="shiny-iris-app"
OTEL_LOG_LEVEL="debug"
SHINY_OTEL_COLLECT="all"

OTEL_TRACES_EXPORTER="http"
OTEL_METRICS_EXPORTER="http"
OTEL_LOGS_EXPORTER="http"

OTEL_EXPORTER_OTLP_TRACES_ENDPOINT="https://otlp-gateway-prod-<region>.grafana.net/otlp/v1/traces"
OTEL_EXPORTER_OTLP_METRICS_ENDPOINT="https://otlp-gateway-prod-<region>.grafana.net/otlp/v1/metrics"
OTEL_EXPORTER_OTLP_LOGS_ENDPOINT="https://otlp-gateway-prod-<region>.grafana.net/otlp/v1/logs"

OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf"
OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic <your-base64-token>"
```

You can obtain your Grafana OTLP credentials from **Grafana Cloud → Connections → OpenTelemetry**.

### 4. Run the app

```r
shiny::runApp()
```

---

## 📡 Observability

The app emits three OTel signals:

### Traces
Each key operation is wrapped in a span:
- `iris.filter` — data filtering with species and sepal length attributes
- `iris.render.plot` — plot rendering
- `iris.render.table` — table rendering

### Metrics
| Metric | Type | Description |
|--------|------|-------------|
| `iris.filter.executions` | Counter | Times the filter reactive ran |
| `iris.filter.rows_returned` | UpDownCounter | Rows after filtering |
| `iris.plot.renders` | Counter | Times the plot was rendered |
| `iris.table.renders` | Counter | Times the table was rendered |
| `iris.input.changes` | Counter | Input changes by input name |

### Logs
Structured JSON logs are emitted for:
- `input_changed` — when the user changes a filter input
- `filter_applied` — after data filtering, with row count
- `plot_rendered` — after the plot is drawn
- `table_rendered` — after the table is rendered

All log events include `session_id` and `user` fields for context.

---

## 🗂️ Project Structure

```
iris_telemetry_app/
├── app.R          # Main Shiny application
├── .Renviron      # Environment variables (not committed)
├── renv/          # renv environment
├── renv.lock      # Locked dependency versions
└── README.md
```

---