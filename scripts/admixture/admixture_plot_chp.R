################################################################################
#### SET-UP ####
################################################################################
## Scripts and libraries:
library(here)
library(tidyverse)
library(gridExtra)
library(grid)
library(RColorBrewer)
library(forcats)
library(patchwork)
library(ggpubr)
source(here("scripts/genscriptlink_lemurs/admixture/admixture_plot_fun.R"))

## SetID:
setID <- 'mitleh.nooutgroup.mac3.FS6'
focal_sp <- c('mmit', 'mleh')

## Input files:
filedir <- here('analyses/admixture/output/')
infile_lookup <- here('metadata/radseq_metadata_link/lookup_IDshort.txt')
infile_cols <- here('metadata/lemurs_metadata_link/lookup/colors.txt')
infile_sites <- here('metadata/lemurs_metadata_link/lookup/sites_pops.txt')

## Output files:
figdir <- here('analyses/admixture/figures/')
if(!dir.exists(figdir)) dir.create(figdir, recursive = TRUE)

## Population factors and labels:
pop2_factor <- c('mmit', 'leh_N', 'leh_hi', 'leh_S')
pop2_labs <- c(leh_N = 'lehi: north',
               leh_S = 'lehi: south',
               leh_hi = 'lehi: high',
               mmit = 'mittermeieri')
grouplab.labeller <- labeller(pop2 = pop2_labs)

## Read metadata:
lookup_raw <- read.delim(infile_lookup, as.is = TRUE) %>%
  filter(species.short %in% focal_sp) %>%
  select(ID, Sample_ID, species, species.short, site) %>%
  rename(sp = species.short)
cols <- read.delim(infile_cols, as.is = TRUE) %>%
  select(-popID)
pops <- read.delim(infile_sites, as.is = TRUE) %>%
  filter(sp %in% focal_sp) %>%
  mutate(pop2 = ifelse(is.na(pop2), sp, pop2)) %>%
  select(site, site_short, site_lump, pop2)

## Process metadata:
lookup <- lookup_raw %>%
  merge(., pops, by = 'site', all.x = TRUE) %>%
  merge(., cols, by.x = 'pop2', by.y = 'popID_short', all.x = TRUE) %>%
  dplyr::rename(col_pop2 = col) %>%
  merge(., cols, by.x = 'sp', by.y = 'popID_short', all.x = TRUE) %>%
  dplyr::rename(col_sp = col) %>%
  mutate(ID2 = sub(':m', ':', paste0(site_lump, ':', ID)),
         pop2 = fct_relevel(pop2, pop2_factor)) %>%
  arrange(pop2) %>%
  mutate(col = fct_inorder(col))


################################################################################
#### INDIVIDUAL PLOTS ####
################################################################################
## Bar and panel background colours:
barcol_pal <- brewer.pal(name = 'Set2', n = 8)
bgcol_pal <- levels(lookup$col)

#library(scales) # for viridis palette
#barcol_pal <- viridis_pal(option = 'plasma')(4)

## CV-plot:
(kp <- k.plot(setID))

## K-plots:
k2 <- Qdf(setID, K = 2, sort_by = 'site_lump', inds_df = lookup) %>%
  ggax.v(., indID.column = 'ID2', group.column = 'pop2',
         barcols = barcol_pal, indlabs = FALSE, ylab = 'K=2',
         grouplab.bgcol = bgcol_pal, grouplab.labeller = grouplab.labeller)
k3 <- Qdf(setID, K = 3, sort_by = 'site_lump', inds_df = lookup) %>%
  ggax.v(., indID.column = 'ID2', group.column = 'pop2',
         barcols = barcol_pal, indlabs = FALSE, ylab = 'K=3',
         grouplab.bgcol = bgcol_pal, grouplab.labeller = grouplab.labeller)
k4 <- Qdf(setID, K = 4, sort_by = 'site_lump', inds_df = lookup) %>%
  ggax.v(., indID.column = 'ID2', group.column = 'pop2',
         barcols = barcol_pal, indlabs = TRUE, ylab = 'K=4',
         grouplab.bgcol = bgcol_pal, grouplab.labeller = grouplab.labeller)


#### COMBINE PLOTS #############################################################
p_admix <- ggarrange(k2, k3, k4,
                     ncol = 1, nrow = 3, heights = c(0.4, 0.4, 0.95))

figfile <- paste0(figdir, '/', setID, '_K234.eps')
ggsave(p, filename = figfile, width = 7, height = 8)
system(paste0('xdg-open ', figfile))
