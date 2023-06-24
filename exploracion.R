library(vroom)
library(janitor)
library(sf)
library(ggplot2)

poblacion <- vroom("data/poblacion.tsv")

dm_crimen <- "https://api.datamexico.org/tesseract/data.jsonrecords?Crime+Type=202%2C203%2C301%2C302%2C303%2C305%2C306%2C502&cube=sesnsp_crimes&drilldowns=Crime+Type%2CState%2CMunicipality+MA%2CYear&locale=es&measures=Value"
resp <- jsonlite::fromJSON(txt = dm_crimen)
violencia <-  resp$data %>%
  janitor::clean_names() %>%
  as_tibble()
rm(resp)

violencia %>%
  pull(year) %>%
  unique()

violencia <- violencia %>%
  mutate(cvegeo = ifelse(nchar(municipality_ma_id) == 5, municipality_ma_id, paste0("0", municipality_ma_id)),
         cve_ent = ifelse(nchar(state_id) == 2, state_id, paste0("0", state_id)))

vroom_write(violencia, "data/delitos.csv")

mun_shp <- st_read("data/mg_mun/00mun.shp")  %>%
  janitor::clean_names() %>%
  st_transform(crs = 4269)

ent_shp <- st_read("data/mg_ent/00ent.shp")  %>%
  janitor::clean_names() %>%
  st_transform(crs = 4269)

violencia_2020 <- violencia %>%
  filter(year == 2020)

violencia_2020_shp <- violencia_2020 %>%
  group_by(cvegeo) %>%
  summarise(total = sum(value)) %>%
  left_join(mun_shp)

ggplot() +
  geom_sf(data = mun_shp) +
  geom_sf(data = st_as_sf(violencia_2020_shp),
          mapping = aes(fill = total)) +
  theme_minimal() +
  scale_fill_viridis_c(option = "A", direction = -1, name = "No. Crímenes")

violencia_2020_shp <- violencia_2020 %>%
  group_by(cve_ent) %>%
  summarise(total = sum(value)) %>%
  left_join(ent_shp)

ggplot() +
  geom_sf(data = ent_shp) +
  geom_sf(data = st_as_sf(violencia_2020_shp),
          mapping = aes(fill = total)) +
  theme_minimal() +
  scale_fill_viridis_c(option = "A", direction = -1, name = "No. Crímenes")
