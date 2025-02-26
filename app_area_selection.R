###############################################################################
#' Description: Area selection app
#'
#' Input: Rds file prepared by SA2_map_data_prep.R
#'
#' Output: Shiny app that permits interactive selection of areas
#'
#' Author: Simon Anastasiadis
#'
#' Dependencies: shiny, leaflet, and sf packages
#'
#' Notes:
#' - Uses code folding by headers (Alt + O to collapse all).
#'
#' Issues:
#'
#' History (reverse order):
#' 2025-01-27 SA v1
#' ############################################################################

## install required packages ---------------------------------------------- ----

sys_timeout = getOption("timeout")
options(timeout = 1000)

req_packages = c("shiny", "leaflet", "sf")
for(pp in req_packages){
  if(pp %in% installed.packages())
    next
  install.packages(pp)
}

options(timeout = sys_timeout)

## setup ------------------------------------------------------------------ ----

library(sf)
library(leaflet)
library(shiny)

# Load shapefile (modify the path accordingly)
shape_data = readRDS(here::here("SA2_higher_geographies_2025.Rds"))

debug = FALSE

## user interface --------------------------------------------------------- ----

# Define UI
ui <- fluidPage(
  
  # header
  shiny::fluidRow(
    shiny::column(width = 1),
    shiny::column(
      width = 11,
      shiny::h2("Area Selector")
    )
  ),
  
  shiny::fluidRow(
    # control panel
    shiny::column(
      width = 4,
      shiny::wellPanel(
        hr(),
        p("Initial map loading can be slow. Please be patient."),
        p(
          "Click areas to add them to the selection. Click them again to remove",
          "Changing the selection type will select multiple nearby areas at once"
        ),
        hr(),
        actionButton("reset", label = "Reset map selections", width = "75%"),
        hr(),
        fileInput("load", label = "Load previous export", width = "75%", accept = ".csv"),
        hr(),
        downloadButton("export", label = "Export current selection", width = "75%"),
        hr(),
        verbatimTextOutput("selected_polygons")
      )
    ),
    
    # map display
    shiny::column(
      width = 8,
      shiny::wellPanel(
        leafletOutput("map", width = "100%", height = "80vw")
      )
    )
  )
)

## server ----------------------------------------------------------------- ----

# Define Server
server <- function(input, output, session) {
  
  # Reactive value to store selected polygon IDs
  selected_polygons <- reactiveVal(c())
  
  # initial map ----
  output$map <- renderLeaflet({
    leaflet(shape_data) %>%
      addTiles() %>%
      addPolygons(
        layerId = ~id,
        color = "#979aa0",
        opacity = 0.4,
        fillOpacity = 0.7,
        weight = 2,
        highlight = highlightOptions(weight = 5, color = "#e8731b", bringToFront = TRUE)
      )
  })
  
  # select polygon function ----
  
  select_polygon = function(id){
    leafletProxy("map") %>%
      removeShape(id) %>%
      addPolygons(
        data = shape_data[shape_data$id == id,],
        layerId = id,
        color = "#6b9b5f",
        opacity = 0.3,
        fillOpacity = 0.7,
        weight = 2,
        highlight = highlightOptions(weight = 5, color = "#366a59", bringToFront = TRUE)
      )
  }
  
  # unselect polygon function ----
  
  unselect_polygon = function(id){
    leafletProxy("map") %>%
      removeShape(id) %>%
      addPolygons(
        data = shape_data[shape_data$id == id,],
        layerId = id,
        color = "#979aa0",
        opacity = 0.3,
        fillOpacity = 0.7,
        weight = 2,
        highlight = highlightOptions(weight = 5, color = "#e8731b", bringToFront = TRUE)
      )
  }
  
  # Observe clicks to toggle selection ----
  observeEvent(input$map_shape_click, {
    clicked_id <- input$map_shape_click$id
    
    if (clicked_id %in% selected_polygons()) {
      # Remove the polygon if already selected
      selected_polygons(setdiff(selected_polygons(), clicked_id))
      unselect_polygon(clicked_id)
      
    } else {
      # Add the polygon if not selected
      selected_polygons(c(selected_polygons(), clicked_id))
      select_polygon(clicked_id)
      
    }
  })
  
  # action button - reset ----
  observeEvent(input$reset, {
    
    for(sp_id in selected_polygons()){
      unselect_polygon(sp_id)
    }
    # empty selected_polygons
    selected_polygons(c())
  })
  
  # action button - load ----
  observeEvent(input$load, {
    req(file.exists(input$load$datapath))
    loaded_df = read.csv(input$load$datapath, stringsAsFactors = FALSE)
    
    req(is.data.frame(loaded_df))
    req("SA2_code" %in% colnames(loaded_df))
    
    # remove current polygons
    for(sp_id in selected_polygons()){
      unselect_polygon(sp_id)
    }
    
    # update selected polygons
    selected_polygons(c())
    selected_polygons(shape_data$id[shape_data$SA2_code %in% loaded_df$SA2_code])
    
    # refresh uploaded polygons
    for(sp_id in selected_polygons()){
      select_polygon(sp_id)
    }
    
  })
  
  ## action button - export ----
  output$export = downloadHandler(
    filename = function(){
      fn = Sys.time()
      fn = substr(as.character(fn), 1, 19)
      fn = gsub(":", "", fn)
      fn = paste0("selected region ",fn,".csv")
    },
    content = function(file){
      out_df = data.frame(
        SA2_code = shape_data$SA2_code[shape_data$id %in% selected_polygons()],
        SA2_name = shape_data$SA2_name[shape_data$id %in% selected_polygons()]
      )
      write.csv(out_df, file, row.names = FALSE)
    }
  )
  
  ## Display selected polygons ----
  output$selected_polygons <- renderPrint({
    req(debug)
    selected_polygons() # Show selected polygon data
  })
}

## execute app ------------------------------------------------------------ ----

# Run the application
shinyApp(ui, server)
