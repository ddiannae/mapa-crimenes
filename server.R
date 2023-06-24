library(shiny)
library(vroom)
library(dplyr)
library(janitor)
library(ggplot2)
library(ggraph)
library(ggmap)
library(sf)

delitos <- vroom("data/delitos.csv")
mun_shp <- st_read("data/mg_mun/00mun.shp")  %>%
  janitor::clean_names() %>%
  st_transform(crs = 4269)

ent_shp <- st_read("data/mg_ent/00ent.shp")  %>%
  janitor::clean_names() %>%
  st_transform(crs = 4269)

poblacion <- vroom("data/poblacion.tsv") %>%
  select(entidad, mun, pobfem) %>%
  mutate(cvegeo = paste0(entidad, mun))

crimen_lista <- delitos$crime_type %>% unique()


function(input, output, session) {

  output$check_crimen <- renderUI({checkboxGroupInput("check_crimen",
                                                      "Tipo de crimen", choices = crimen_lista, selected = crimen_lista)})


  observe({
    check_crimen <- input$check_crimen
    tipo_mapa <- input$tipo_mapa
    tipo_estadistico <- input$tipo_estadistico
    anio <- input$anio

    crimen_tbl <- delitos %>%
      filter(year %in% anio)

    if(tipo_mapa == "mun") {
      pbfem <- poblacion %>%
        mutate(cien = pobfem/100000) %>%
        select(cvegeo, cien)

      crimen_tbl <- crimen_tbl %>%
        filter(crime_type %in% check_crimen) %>%
        group_by(cvegeo, state, municipality_ma) %>%
        summarise(total = sum(value))

      if(tipo_estadistico == "muj") {
        crimen_tbl <- crimen_tbl %>%
          left_join(pbfem)  %>%
          mutate(total = round(total/cien, digits = 2)) %>%
          select(-cien)
        nleg = "Crímenes por 100mil mujeres"
      } else {
        nleg = "Total de crímenes"
      }

      crimen_shp <- crimen_tbl %>%
        left_join(mun_shp)

      output$geoPlot <- renderPlot({
        ggplot() +
          geom_sf(data = mun_shp) +
          geom_sf(data = st_as_sf(crimen_shp),
                  mapping = aes(fill = total)) +
          theme_minimal() +
          scale_fill_viridis_c(option = "A", direction = -1, name = nleg)
      })
    } else {

      pbfem <- poblacion %>%
        group_by(entidad) %>%
        summarise(pobfem = sum(pobfem)) %>%
        mutate(cien = pobfem/100000) %>%
        select(cve_ent = entidad, cien)

      crimen_tbl <- crimen_tbl %>%
        filter(crime_type %in% check_crimen) %>%
        group_by(cve_ent, state) %>%
        summarise(total = sum(value))

      if(tipo_estadistico == "muj") {
        crimen_tbl <- crimen_tbl %>%
          left_join(pbfem)  %>%
          mutate(total = round(total/cien, digits = 2)) %>%
          select(-cien)
        nleg = "Crímenes por 100mil mujeres"
      } else {
        nleg = "Total de crímenes"
      }

      crimen_shp <- crimen_tbl %>%
        left_join(ent_shp)

      output$geoPlot <- renderPlot({
        ggplot() +
          geom_sf(data = ent_shp) +
          geom_sf(data = st_as_sf(crimen_shp),
                  mapping = aes(fill = total)) +
          theme_minimal() +
          scale_fill_viridis_c(option = "A", direction = -1, name = nleg)
      })

    }

    output$crimentable <- DT::renderDataTable({
      if(tipo_mapa == "mun") {
        crimen_tbl <- crimen_tbl %>%
          select(ClaveGEO = cvegeo, Estado = state, Municipio = municipality_ma, Total = total )
      } else {
        crimen_tbl <- crimen_tbl %>%
          select(ClaveGEO = cve_ent, Estado = state, Total = total )
      }
      action <- DT::dataTableAjax(session, crimen_tbl, outputId = "crimentable")
      DT::datatable(crimen_tbl, options = list(ajax = list(url = action)), escape = FALSE)
    })

  })
}
