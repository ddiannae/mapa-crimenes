library(shiny)
library(shinythemes)
library(shinyWidgets)
library(ggplot2)
library(DT)

navbarPage("Mapa de crímenes en México", id="nav",
  tabPanel("Mapa",
           sidebarLayout(
             sidebarPanel(
               selectInput("tipo_mapa", "Agregación", choices = c("Por entidad" = "ent", "Por municipio" = "mun")),
               selectInput("tipo_estadistico", "Estadístico", choices = c("Total" = "total", "Por 100 mil mujeres" = "muj")),
               sliderTextInput(
                 inputId = "anio",
                 label = "Año",
                 choices = 2015:2022,
                 grid = FALSE,
                 force_edges = TRUE,
                 selected =  2015:2022,
                 dragRange = TRUE
               ),
               uiOutput("check_crimen"),
               width = 3
             ),
             mainPanel(
               plotOutput(outputId = "geoPlot"),
               width = 9
             )
           )

  ),

  tabPanel("Explorador de datos",
    dataTableOutput("crimentable")
  ),
)
