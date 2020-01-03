################################################################################
#### SET-UP ####
################################################################################
## Libraries and scripts:
library(here)
library(tidyverse)
library(gdsfmt)
library(SNPRelate)
library(vcfR)
library(tidyverse)
library(ggpubr)
library(cowplot)
library(ggforce)
source(here('scripts/genscriptlink_lemurs/PCA/PCA_R_fun.R'))

## Variables:
setID <- 'mitleh.nooutgroup.mac3.FS6'
focal_sp <- c('mmit', 'mleh')

## Input files:
infile_vcf <- here('seqdata/vcf/stacks', paste0(setID, '.vcf.gz'))

infile_lookup <- here('metadata/radseq_metadata_link/lookup_IDshort.txt')
infile_cols <- here('metadata/lemurs_metadata_link/lookup/colors.txt')
infile_pops <- here('metadata/lemurs_metadata_link/lookup/sites_pops.txt')

if(!file.exists(infile_vcf)) cat("ERROR: infile_vcf DOES NOT EXIST\n")
if(!file.exists(infile_lookup)) cat("ERROR: infile_lookup DOES NOT EXIST\n")
if(!file.exists(infile_cols)) cat("ERROR: infile_cols DOES NOT EXIST\n")
if(!file.exists(infile_sites)) cat("ERROR: infile_sites DOES NOT EXIST\n")

# Output files and dirs:
outdir_pca <- here('analyses/PCA/dfs/')
outdir_figs <- here('analyses/PCA/plots/')
outdir_snpgds <- here('analyses/PCA/gds_files/')
outfile_snpgds <- paste0(outdir_snpgds, '/', setID, '.gds')
outfile_fig <- paste0(outdir_figs, setID, '_all.eps')

if(!dir.exists(outdir_snpgds)) dir.create(outdir_snpgds, recursive = TRUE)
if(!dir.exists(outdir_pca)) dir.create(outdir_pca, recursive = TRUE)
if(!dir.exists(outdir_figs)) dir.create(outdir_figs, recursive = TRUE)

## Read metadata files:
lookup_raw <- read.delim(infile_lookup, as.is = TRUE) %>%
  filter(species.short %in% focal_sp) %>%
  select(ID, Sample_ID, species, species.short, site) %>%
  rename(sp = species.short)

cols <- read.delim(infile_cols, as.is = TRUE) %>%
  select(-popID)

pops <- read.delim(infile_pops, as.is = TRUE) %>%
  dplyr::filter(sp %in% focal_sp) %>%
  dplyr::mutate(pop2 = ifelse(is.na(pop2), sp, pop2)) %>%
  dplyr::select(site, site_short, site_lump, pop2)

pop2_order <- c('mmit', 'leh_N', 'leh_hi', 'leh_S') # For non-alphabetical ordering of species
pop2_labs <- c('mittermeieri', 'lehi: north', 'lehi: high', 'lehi: south')
pops <- pops %>%
  mutate(pop2 = fct_relevel(pop2, pop2_order),
         pop_group = as.factor(
           recode(pop2,
                  mmit = "mittermeieri", leh_N = "lehi: north",
                  leh_hi = 'lehi: high', leh_S = 'lehi: south')
         ))

## Merge metadata files:
lookup <- lookup_raw %>%
  merge(., pops, by = 'site', all.x = TRUE) %>%
  merge(., cols, by.x = 'pop2', by.y = 'popID_short', all.x = TRUE) %>%
  dplyr::rename(col_pop2 = col) %>%
  merge(., cols, by.x = 'sp', by.y = 'popID_short', all.x = TRUE) %>%
  dplyr::rename(col_sp = col) %>%
  dplyr::select(ID, Sample_ID, species, sp, site, site_short, site_lump,
                pop2, pop_group, col_sp, col_pop2)


################################################################################
#### READ VCF ####
################################################################################
snpgdsVCF2GDS(infile_vcf, outfile_snpgds, method = "biallelic.only") # Convert VCF to snpgds format, which is what SNPrelate uses within R
snps <- snpgdsOpen(outfile_snpgds) # Conversion above was to a file, which is now loaded
snpgdsSummary(outfile_snpgds) # Show summary of data in VCF/snpgds


################################################################################
#### SUBSETTING ####
################################################################################
## LD pruning:
#snpset <- snpgdsLDpruning(genofile, ld.threshold=0.2)
#snpset.id <- unlist(unname(snpset))
#pca <- snpgdsPCA(snpgds.file, snp.id = snpset.id, num.thread = 2)

## List of individuals:
inds_all <- read.gdsn(index.gdsn(snps, "sample.id"))
cat("#### List of individuals:\n")
print(inds_all)


################################################################################
#### RUN AND PLOT PCA ####
################################################################################
## Run PCA:
pca_raw <- snpgdsPCA(snps, autosome.only = FALSE, num.thread = 1)

## Process results:
pca <- pca.process(pca_raw, lookup = lookup, subset.ID = 'all',
                   pca.ID = paste0(setID, '_all')) %>%
  mutate(pop2 = factor(pop2, levels = pop2_order)) %>%
  arrange(pop2) %>%
  mutate(col_pop2 = fct_inorder(as.factor(col_pop2)))

eig <- data.frame(PC = 1:length(pca_raw$eigenval), eig = pca_raw$eigenval)
eig <- eig[complete.cases(eig), ]

## TESTPLOT
# ggplot(pca, aes(x = PC1, y = PC2, color = site_lump)) +
#   geom_point(size = 3, stroke = 1) +
#   geom_mark_ellipse(aes(label = site_lump), show.legend = FALSE,
#                     label.fontsize = 10, con.type = 'straight',
#                     tol = 0.001, label.buffer = unit(1, 'mm')) +
#   theme_minimal() +
#   guides(color = FALSE)


## Plot:
p1 <- pcplot(pca, eigenvals = eig$eig, strokesize = 1,
             xmin_buffer = 0.02, xmax_buffer = 0.1,
             ymin_buffer = 0.06, ymax_buffer = 0.06,
             shape.by = 'pop2', shape.by.name = 'Pop. group:',
             shape.by.labs = levels(pca$pop_group), shapes = c(8, 15, 17, 18),
             col.by = 'site_lump',
             draw_boxes = TRUE, boxlabsize = 10) +
  theme(plot.margin = margin(0.3, 0.6, 0.3, 0.3, "cm"),
        legend.justification = "top",
        legend.text = element_text(size = 18),
        legend.title = element_text(size = 18, face = 'bold'))
#p1

p2 <- pcplot(pca, eigenvals = eig$eig, strokesize = 1,
             xmin_buffer = 0.01, xmax_buffer = 0.01,
             ymin_buffer = 0.35, ymax_buffer = 0.01,
             col.by = 'pop_group', col.by.name = "Pop. group:",
             col.by.labs = levels(pca$pop_group), cols = levels(pca$col_pop2)) +
  guides(color = guide_legend(nrow = 2)) +
  labs(title = 'Color by pop. group:') +
  theme(plot.title = element_text(size = 16, hjust = 0.5),
        axis.ticks = element_blank(),
        axis.title = element_blank(),
        legend.position = c(0.5, 0.1),
        legend.text = element_text(size = 12),
        legend.title = element_blank(),
        legend.box.background = element_rect(colour = 'grey10', size = 1),
        legend.margin = margin(c(0, 0, 0, 0)),
        legend.spacing.y = unit(0, 'cm'),
        legend.key.height = unit(0.15, 'cm'),
        legend.box.spacing = unit(0, 'cm'),
        legend.box.margin = margin(c(0, 0, 0, 0)),
        plot.margin = margin(0.1, 0.2, 0, 0, "cm"))
#p2

p <- ggdraw() + draw_plot(p1) +
  draw_plot(p2, x = 0.65, y = 0.02, width = 0.35, height = 0.45)
ggsave(filename = outfile_fig, width = 9, height = 7)
system(paste0('xdg-open ', outfile_fig))
