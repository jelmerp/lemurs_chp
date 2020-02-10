#### SET-UP: ####
## Libraries and scripts:
library(tidyverse)
library(here)
library(sf) # handling geographical data
library(rnaturalearth) # base map
library(ggspatial) # scale bar
library(osmdata) # OSM coastline
library(osmplotr) # get_bbox()
library(patchwork) # plot placement
library(cowplot) # plot placement
library(raster)
library(ggrepel) # repelling labels
library(ggnewscale) # multiple color/fill scales
# library(ggforce)

## Input files - site-coords:
infile_sites <- here('metadata/lemurs_metadata_link/lookup/sites_gps.txt') # File with coordinates for all mouse lemur consortium sites
infile_pops <- here('metadata/lemurs_metadata_link/lookup/sites_pops.txt')
infile_cols <- here('metadata/lemurs_metadata_link/lookup/colors.txt')

## Input files - shapefiles:
# Mouse lemur distributions:
shp_leh <- here('metadata/lemurs_metadata_link/gps/range_data/IUCN_shapefiles/leh/data_0.shp')
shp_mit <- here('metadata/lemurs_metadata_link/gps/range_data/IUCN_shapefiles/mit/data_0.shp')

kml_mit_own1 <- here('metadata/lemurs_metadata_link/gps/range_data/own_kml/mit_own1.kml')
kml_mit_own2 <- here('metadata/lemurs_metadata_link/gps/range_data/own_kml/mit_own2.kml')
kml_leh_own <- here('metadata/lemurs_metadata_link/gps/range_data/own_kml/leh_own.kml')

# Vegetation:
shp_veg_all <- here('metadata/lemurs_metadata_link/gps/vegetation/kew/madagascar_veg_geol.shp')
elev_cut_file <- here('metadata/lemurs_metadata_link/gps/relief/SR_HR/SR_HR_Mada.RData')
rivers_gaia_shp <- here('metadata/lemurs_metadata_link/gps/rivers/gaia/afrivs.shp')

## Output files:
outdir <- here('map')
if(!dir.exists(outdir)) dir.create(outdir, recursive = TRUE)
out_map_base  <- file.path(outdir, 'map_')

## Coordinate system:
my_CRS <- 4297 # appropriate for Madagascar

## Coordinates to set map (and box) boundaries:
# Entire island:
lon_min_mad <- 43; lon_max_mad <- 50.6
lat_min_mad <- -25.8; lat_max_mad <- -11.8

# CHP (=Central Highland Plateau):
lon_min_chp <- 46.5; lon_max_chp <- 50.6
lat_min_chp <- -20; lat_max_chp <- -14.1

## Dataframe for box around CHP area:
chp_df <- data.frame(
  xmin = lon_min_chp, ymin = lat_min_chp, xmax = lon_max_chp, ymax = lat_max_chp
  )

## Species and colours:
col_leh <- '#0000FF'
col_mit <- '#00CD00'
focal_sp <- c('mleh', 'mmit')


#### LOAD AND PREPARE MAP DATA ####
## Metadata files:
sites_raw <- read.delim(infile_sites, as.is = TRUE) %>%
  dplyr::filter(sp %in% focal_sp) %>%
  dplyr::select(site, lat, lon, sp, species)
pops <- read.csv(infile_pops, as.is = TRUE) %>%
  dplyr::filter(sp %in% focal_sp) %>%
  dplyr::mutate(pop2 = ifelse(is.na(pop2), sp, pop2)) %>%
  dplyr::select(site, site_short, site_lump, pop2)
cols <- read.delim(infile_cols, as.is = TRUE) %>%
  dplyr::select(popID_short, col)

## Popgroup labels and factor orders:
pop2_order <- c('mmit', 'leh_N', 'leh_hi', 'leh_S')
pop2_labs <- c('mittermeieri', 'lehi: north', 'lehi: high', 'lehi: south')

pops <- pops %>%
  mutate(pop2 = fct_relevel(pop2, pop2_order),
         pop_group = as.factor(
           recode(pop2,
                  mmit = "mittermeieri", leh_N = "lehi: north",
                  leh_hi = 'lehi: high', leh_S = 'lehi: south')
         ))

## Merge metadata files:
sites <- sites_raw %>%
  merge(., pops, by = 'site', all.x = TRUE) %>%
  merge(., cols, by.x = 'pop2', by.y = 'popID_short', all.x = TRUE) %>%
  dplyr::rename(col_pop2 = col) %>%
  merge(., cols, by.x = 'sp', by.y = 'popID_short', all.x = TRUE) %>%
  dplyr::rename(col_sp = col) %>%
  dplyr::select(site, site_short, site_lump, lat, lon,
                sp, species, pop2, pop_group, col_pop2, col_sp) %>%
  dplyr::arrange(pop2) %>%
  dplyr::mutate(col_pop2 = fct_inorder(as.factor(col_pop2)),
                col_sp = fct_inorder(as.factor(col_sp)))
sites$site_lump[duplicated(sites$site_lump)] <- ""

## Basemap data from rnaturalearth for overview and CHP maps:
mada_map_rne <- ne_countries(scale = 10, returnclass = "sf") %>%
  filter(name_long == "Madagascar") %>%
  st_transform(my_CRS)

## Read shapefiles - species distributions:
dist_leh <- st_read(shp_leh)
dist_mit <- st_read(shp_mit)
dist_mit_own1 <- st_read(kml_mit_own1)
dist_mit_own2 <- st_read(kml_mit_own2)
dist_leh_own <- st_read(kml_leh_own)

## Kew files:
veg_all_org <- st_read(shp_veg_all) # Shapefile with all vegetation types

## Modify shapefile with all vegetation types:
veg_all_org$VEGETATION <- fct_recode(
  veg_all_org$VEGETATION,
  humid_low = "EVERGREEN, HUMID FOREST(LOW ALTITUDE):",
  humid_mid = "EVERGREEN, HUMID FOREST(MID ALTITUDE):",
  humid_lowmont = "EVERGREEN, HUMID FOREST(LOWER MONTANE):",
  mangrove = "MANGROVE",
  w_deciduous = "DECIDUOUS, SEASONALLY DRY, WESTERN FOREST:",
  marshland = "MARSHLAND",
  scrub_montane = "MONTANE (PHILIPPIA) SCRUBLAND:",
  coastal_western = "COASTAL FOREST (WESTERN):",
  uapaca = "EVERGREEN, SCLEROPHYLLOUS (UAPACA) WOODLAND:",
  dry = "DECIDUOUS, DRY, SOUTHERN FOREST AND SCRUBLAND:",
  coastal_eastern = "COASTAL FOREST (EASTERN):"
  )

## New object, remove marshland:
veg_all <- veg_all_org %>%
  rename(vegetation = VEGETATION)

## Change vegetation names:
veg_all$vegetation <- fct_recode(
  veg_all$vegetation,
  other = 'coastal_eastern',
  other = 'coastal_western',
  other = 'uapaca',
  other = 'mangrove',
  other = 'marshland',
  #other = 'dry',
  other = 'scrub_montane',
  humid_mont = 'humid_mid',
  humid_mont = 'humid_lowmont'
  )

## Reorder factor:
veg_all$vegetation <- fct_relevel(
  veg_all$vegetation,
  c('humid_low', 'humid_mont', 'w_deciduous', 'dry', 'other')
)

## Rivers:
rivers_gaia <- st_read(rivers_gaia_shp)

## Elevation:
elev_mada <- readRDS(elev_cut_file) %>%
  dplyr::select(value, geometry)
#elev_mada_se <- st_intersection(elev_mada, mada_se_sf)


#### INSET MAP OF ALL OF MADA ####
#veg_labs <- c('humid lowland', 'humid montane', 'W. deciduous', 'dry', 'other')
#veg_cols <- c('#440154FF', '#31688EFF', '#35B779FF', '#FDE725FF', 'grey50')
#geom_sf(data = veg_all, aes(fill = vegetation), alpha = 1, lwd = 0) +
#scale_fill_manual(name = 'Vegetation type:', labels = veg_labs, values = veg_cols) +

p_mad <- ggplot() +
  geom_sf(data = mada_map_rne, fill = NA, color = 'grey10', lwd = 0.5) +
 coord_sf(xlim = c(43, 50.6), ylim = c(-25.8, -11.8),
           expand = FALSE, crs = st_crs(my_CRS)) +
  theme_void() +
  geom_rect(data = chp_df,
            aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
            inherit.aes = FALSE, fill = NA, color = 'grey10', lwd = 1)
ggsave(paste0(out_map_base, 'mad.png'), p_mad, width = 8, height = 8)


#### CHP MAP WITH ELEVATION AND DISTRIBUTIONS ####
## Plot:
p_dist_raw <- ggplot() +
  geom_sf(data = elev_mada, aes(colour = value), alpha = 0.5) +
  geom_sf(data = mada_map_rne, fill = NA, colour = 'grey10', lwd = 1) +
  geom_sf(data = dist_mit_own1, fill = col_mit, colour = 'grey10',
          lwd = 0.4, linetype = 'dotted', alpha = 0.5) +
  geom_sf(data = dist_mit_own2, fill = col_mit, colour = 'grey10',
          lwd = 0.4, linetype = 'dotted', alpha = 0.5) +
  geom_sf(data = dist_leh_own, fill = col_leh, colour = 'grey10',
          lwd = 0.4, linetype = 'dotted', alpha = 0.35) +
  geom_sf(data = dist_leh, fill = col_leh, colour = 'black',
          lwd = 0.4, alpha = 1) +
  geom_sf(data = dist_mit, fill = col_mit, colour = 'black',
          lwd = 0.4, alpha = 1) +
  geom_sf(data = filter(rivers_gaia, WIDTH > 75),
          fill = 'skyblue3', colour = 'skyblue3', alpha = 1, lwd = 0.5) +
  coord_sf(xlim = c(lon_min_chp, lon_max_chp),
           ylim = c(lat_min_chp, lat_max_chp),
           expand = FALSE, crs = st_crs(my_CRS)) +
  scale_colour_gradient(low = 'grey50', high = 'white', guide = FALSE) +
  annotation_scale(location = "tl", width_hint = 0.12,
                   text_cex = 1.3, height = unit(0.4, 'cm'),
                   pad_x = unit(0.25, "cm"), pad_y = unit(0.25, "cm")) +
  annotation_north_arrow(location = "tl", which_north = "true",
                         height = unit(1.7, "cm"), width = unit(1.7, "cm"),
                         pad_x = unit(0.6, "cm"), pad_y = unit(0.8, "cm"),
                         style = north_arrow_fancy_orienteering) +
  theme_void() +
  theme(panel.border = element_rect(colour = "grey10", fill = NA, size = 1),
        plot.margin = unit(c(0.5, 0.5, 0.5, 0.5), 'lines'))

p_dist <- ggdraw() +
  draw_plot(p_dist_raw) +
  draw_plot(p_mad, x = 0.65, y = 0.02, width = 0.3, height = 0.3)
ggsave(paste0(out_map_base, 'dist_inset.png'), p_dist, width = 6, height = 8)
system(paste0('xdg-open ', out_map_base, 'dist_inset.png'))


#### MAP WITH VEGETATION AND SAMPLING ####
## Create dummy dataframe for forest-type legend:
forest_type_chp <- c('humid_low', 'humid_mont', 'w_deciduous', 'other')
veg_labs2 <- c('humid lowland', 'humid montane', 'W. deciduous', 'other')
veg_cols2 <- c('darkgreen', 'olivedrab2', '#FDE725FF', 'grey50')
lat <- rep(-16, 4)
long <- rep(55, 4)
dummy_chp <- data.frame(forest_type_chp, lat, long)
dummy_chp$forest_type <- factor(dummy_chp$forest_type, levels = forest_type_chp)

## Plot:
p_pops <- ggplot() +
  geom_sf(data = elev_mada, aes(colour = value), alpha = 0.5) +
  scale_colour_gradient(low = 'grey50', high = 'white', guide = FALSE) +
  geom_sf(data = filter(veg_all, vegetation == 'humid_low'),
          fill = veg_cols2[1], alpha = 0.6, lwd = 0) +
  geom_sf(data = filter(veg_all, vegetation == 'humid_mont'),
          fill = veg_cols2[2], alpha = 0.6, lwd = 0) +
  geom_sf(data = filter(veg_all, vegetation == 'w_deciduous'),
          fill = veg_cols2[3], alpha = 0.6, lwd = 0) +
  geom_sf(data = filter(veg_all, vegetation == 'other'),
          fill = veg_cols2[4], alpha = 0.6, lwd = 0) +
  geom_sf(data = mada_map_rne, fill = NA, color = 'grey10', lwd = 1) +
  geom_point(data = sites, aes(x = lon, y = lat, fill = col),
             color = 'black', shape = 21, size = 6, stroke = 2) +
  scale_fill_identity(name = 'Pop. group:',  guide = 'legend',
                      breaks = sites$col, labels = sites$pop_group) +
  new_scale_color() +
  geom_point(data = dummy_chp, size = 10,
             aes(x = long, y = lat, color = forest_type_chp)) +
  scale_color_manual(name = 'Vegetation type:',
                     labels = veg_labs2,
                     values = veg_cols2) +
  guides(color = guide_legend(override.aes = list(size = 8))) +
  coord_sf(xlim = c(lon_min_chp, lon_max_chp),
           ylim = c(lat_min_chp, lat_max_chp),
           expand = FALSE, crs = st_crs(my_CRS)) +
  annotation_scale(location = "br", width_hint = 0.12,
                   text_cex = 1.3, height = unit(0.4, 'cm'),
                   pad_x = unit(0.25, "cm"), pad_y = unit(0.25, "cm")) +
  annotation_north_arrow(location = "br", which_north = "true",
                         height = unit(1.7, "cm"), width = unit(1.7, "cm"),
                         pad_x = unit(0.6, "cm"), pad_y = unit(0.8, "cm"),
                         style = north_arrow_fancy_orienteering) +
  theme_void() +
  theme(plot.margin = unit(c(0.5, 0.5, 0.5, 0.5), 'lines'),
        panel.border = element_rect(colour = "grey10", fill = NA, size = 1),
        legend.title = element_text(size = 25, face = 'bold'),
        legend.text = element_text(size = 25),
        legend.spacing.y = unit(0.3, 'cm'))
#p_pops
ggsave(paste0(out_map_base, 'pops.png'), p_pops, width = 8, height = 8)
#system(paste0('xdg-open ', out_map_base, 'pops.png'))


#### MAP WITH NAMED SAMPLING SITES - BY POPGROUP ####
## Every site separate:
p_sites_each <- ggplot() +
  geom_sf(data = veg_all, fill = 'olivedrab', alpha = 0.5, lwd = 0) +
  geom_sf(data = mada_map_rne, fill = NA, color = 'grey30', lwd = 1) +
  geom_point(data = sites, aes(x = lon, y = lat, fill = col_pop2),
             color = 'black', shape = 21, size = 6, stroke = 2) +
  scale_fill_identity(breaks = sites$col_pop2) +
  geom_text_repel(data = sites, aes(x = lon, y = lat, label = site_short),
                  nudge_y = 0.2, point.padding = 0.5,
                  size = 5, fontface = 'bold') +
  coord_sf(xlim = c(lon_min_chp, lon_max_chp),
           ylim = c(lat_min_chp, lat_max_chp),
           expand = FALSE, crs = st_crs(my_CRS)) +
  theme_void() +
  labs(title = 'All sites') +
  theme(plot.margin = unit(c(0.2, 0.2, 0.2, 0.2), 'lines'),
        panel.border = element_rect(colour = "grey10", fill = NA, size = 1),
        plot.title = element_text(size = 25, hjust = 0.5))
#ggsave(paste0(out_map_base, 'sites_each.png'), p_sites_each, width = 8, height = 8)

## Nearby sites lumped:
p_sites_lumped <- ggplot() +
  geom_sf(data = veg_all, fill = 'olivedrab', alpha = 0.5, lwd = 0) +
  geom_sf(data = mada_map_rne, fill = NA, color = 'grey30', lwd = 1) +
  geom_point(data = sites, aes(x = lon, y = lat, fill = col_pop2),
             color = 'black', shape = 21, size = 6, stroke = 2) +
  scale_fill_identity(guide = 'legend',
                      breaks = sites$col_pop2, labels = sites$pop_group) +
  guides(fill = guide_legend(nrow = 1)) +
  geom_text_repel(data = sites, aes(x = lon, y = lat, label = site_lump),
                  force = 2, nudge_y = 0.2, point.padding = 0.5,
                  size = 5, fontface = 'bold') +
  coord_sf(xlim = c(lon_min_chp, lon_max_chp),
           ylim = c(lat_min_chp, lat_max_chp),
           expand = FALSE, crs = st_crs(my_CRS)) +
  theme_void() +
  labs(title = 'Lumped sites') +
  theme(plot.margin = unit(c(0.2, 0.2, 0.2, 0.2), 'lines'),
        panel.border = element_rect(colour = "grey10", fill = NA, size = 1),
        plot.title = element_text(size = 25, hjust = 0.5),
        legend.title = element_blank(),
        legend.text = element_text(size = 20),
        legend.margin = margin(c(0, 0, 0, 0)),
        legend.spacing.y = unit(0, 'cm'))
#ggsave(paste0(out_map_base, 'sites_lumped.png'), p_sites_lumped, width = 8, height = 8)

## Combine the two sites maps:
p_sites <- (p_sites_each + p_sites_lumped) / guide_area() +
  plot_layout(guides = 'collect', heights = c(15, 1))
ggsave(paste0(out_map_base, 'sites_pop2.png'), p_sites, width = 8, height = 7)
system(paste0('xdg-open ', out_map_base, 'sites_pop2.png'))


#### MAP WITH NAMED SAMPLING SITES - BY SPECIES ####
## Every site separate:
p_sites_each_sp <- ggplot() +
  geom_sf(data = veg_all, fill = 'olivedrab', alpha = 0.5, lwd = 0) +
  geom_sf(data = mada_map_rne, fill = NA, color = 'grey30', lwd = 1) +
  geom_point(data = sites, aes(x = lon, y = lat, fill = col_sp),
             color = 'black', shape = 21, size = 6, stroke = 2) +
  scale_fill_identity(breaks = sites$col_sp) +
  geom_text_repel(data = sites, aes(x = lon, y = lat, label = site_short),
                  nudge_y = 0.2, point.padding = 0.5,
                  size = 5, fontface = 'bold') +
  coord_sf(xlim = c(lon_min_chp, lon_max_chp),
           ylim = c(lat_min_chp, lat_max_chp),
           expand = FALSE, crs = st_crs(my_CRS)) +
  theme_void() +
  labs(title = 'All sites') +
  theme(plot.margin = unit(c(0.2, 0.2, 0.2, 0.2), 'lines'),
        panel.border = element_rect(colour = "grey10", fill = NA, size = 1),
        plot.title = element_text(size = 25, hjust = 0.5))
#ggsave(paste0(out_map_base, 'sites_each.png'), p_sites_each, width = 8, height = 8)

## Nearby sites lumped:
p_sites_lumped_sp <- ggplot() +
  geom_sf(data = veg_all, fill = 'olivedrab', alpha = 0.5, lwd = 0) +
  geom_sf(data = mada_map_rne, fill = NA, color = 'grey30', lwd = 1) +
  geom_point(data = sites, aes(x = lon, y = lat, fill = col_sp),
             color = 'black', shape = 21, size = 6, stroke = 2) +
  scale_fill_identity(guide = 'legend',
                      breaks = sites$col_sp, labels = sites$species) +
  guides(fill = guide_legend(nrow = 1)) +
  geom_text_repel(data = sites, aes(x = lon, y = lat, label = site_lump),
                  force = 2, nudge_y = 0.2, point.padding = 0.5,
                  size = 5, fontface = 'bold') +
  coord_sf(xlim = c(lon_min_chp, lon_max_chp),
           ylim = c(lat_min_chp, lat_max_chp),
           expand = FALSE, crs = st_crs(my_CRS)) +
  theme_void() +
  labs(title = 'Lumped sites') +
  theme(plot.margin = unit(c(0.2, 0.2, 0.2, 0.2), 'lines'),
        panel.border = element_rect(colour = "grey10", fill = NA, size = 1),
        plot.title = element_text(size = 25, hjust = 0.5),
        legend.title = element_blank(),
        legend.text = element_text(size = 20),
        legend.margin = margin(c(0, 0, 0, 0)),
        legend.spacing.y = unit(0, 'cm'))
#ggsave(paste0(out_map_base, 'sites_lumped.png'), p_sites_lumped, width = 8, height = 8)

## Combine the two sites maps:
p_sites_sp <- (p_sites_each_sp + p_sites_lumped_sp) / guide_area() +
  plot_layout(guides = 'collect', heights = c(15, 1))
ggsave(paste0(out_map_base, 'sites_sp.png'), p_sites_sp, width = 8, height = 7)
system(paste0('xdg-open ', out_map_base, 'sites_sp.png'))


##### LEAFLET MAP ####
# mur <- mapview(dist_mur) # fill=NA
# gan <- mapview(dist_gan)
# mur + gan
