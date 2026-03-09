box::use(
  shiny[...],
  dplyr[filter],
  otel[
    get_tracer, get_meter,
    log_info, log_warn    
  ],
  otelsdk[...]
)


tracer <- get_tracer("shiny-iris-app")
meter  <- get_meter("shiny-iris-app")

filter_counter     <- meter$create_counter("iris.filter.executions",
                        description = "Times the filter reactive ran")
rows_gauge         <- meter$create_up_down_counter("iris.filter.rows_returned",
                        description = "Rows after filtering")
plot_render_count  <- meter$create_counter("iris.plot.renders",
                        description = "Times the plot was rendered")
table_render_count <- meter$create_counter("iris.table.renders",
                        description = "Times the table was rendered")
input_change_count <- meter$create_counter("iris.input.changes",
                        description = "Input changes by input name")

ui <- fluidPage(
  selectInput(
    "species",   
    "Species:",          
    choices = c("All", levels(iris$Species))
  ),
  sliderInput("sepal_len", "Min Sepal Length:", min = 4, max = 8, value = 4, step = 0.1),
  plotOutput("iris_plot"),
  tableOutput("iris_table")
)

server <- function(input, output, session) {

  sid  <- session$token
  user <- Sys.info()[["user"]]

  # Format structured fields as a JSON string inside the log message
  fmt <- function(...) {
    kv <- list(...)
    pairs <- mapply(function(k, v) sprintf('"%s":"%s"', k, v), names(kv), kv)
    paste0("{", paste(pairs, collapse = ","), "}")
  }

  observe_input <- function(input_name, value_reactive) {
    reactive({
      val <- value_reactive()

      log_info(fmt(
        event       = "input_changed",
        input_name  = input_name,
        input_value = as.character(val),
        session_id  = sid,
        user        = user
      ))

      input_change_count$add(1L, attributes = list(input_name = input_name))
      val
    })
  }

  species   <- observe_input("species",   reactive(input$species))
  sepal_len <- observe_input("sepal_len", reactive(input$sepal_len))

  filtered <- reactive({
    req(species(), sepal_len())

    sp   <- species()
    slen <- sepal_len()

    span <- tracer$start_span("iris.filter", attributes = list(
      "filter.species"   = sp,
      "filter.sepal_min" = slen,
      "session.id"       = sid,
      "user"             = user
    ))
    on.exit(span$end(), add = TRUE)

    result <- iris |>
      filter(if (sp != "All") Species == sp else TRUE) |>
      filter(Sepal.Length >= slen)

    n <- nrow(result)
    span$set_attribute("filter.rows_returned", n)
    span$set_attribute("filter.species_in_result",
                       paste(unique(as.character(result$Species)), collapse = ", "))

    filter_counter$add(1L, attributes = list(species = sp, sepal_min = as.character(slen)))
    rows_gauge$add(n, attributes = list(species = sp))

    log_info(fmt(
      event         = "filter_applied",
      species       = sp,
      sepal_min     = as.character(slen),
      rows_returned = as.character(n),
      session_id    = sid,
      user          = user
    ))

    result
  })

  output$iris_plot <- renderPlot({
    df <- filtered()
    req(nrow(df) > 0)

    span <- tracer$start_span("iris.render.plot", attributes = list(
      "plot.rows"  = nrow(df),
      "session.id" = sid,
      "user"       = user
    ))
    on.exit(span$end(), add = TRUE)

    plot_render_count$add(1L)

    log_info(fmt(
      event      = "plot_rendered",
      rows       = as.character(nrow(df)),
      species    = species(),
      sepal_min  = as.character(sepal_len()),
      session_id = sid,
      user       = user
    ))

    plot(df$Sepal.Length, df$Sepal.Width,
         col  = as.integer(df$Species), pch = 19,
         xlab = "Sepal Length", ylab = "Sepal Width",
         main = paste0("Species: ", species(), " | Sepal >= ", sepal_len()))
  })

  output$iris_table <- renderTable({
    df <- head(filtered(), 10)

    span <- tracer$start_span("iris.render.table", attributes = list(
      "table.rows" = nrow(df),
      "session.id" = sid,
      "user"       = user
    ))
    on.exit(span$end(), add = TRUE)

    table_render_count$add(1L)

    log_info(fmt(
      event      = "table_rendered",
      rows       = as.character(nrow(df)),
      session_id = sid,
      user       = user
    ))

    df
  })
}

shinyApp(ui, server)