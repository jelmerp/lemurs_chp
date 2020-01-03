library(here)
library(gdata)
library(tidyverse)

## Files:
infile_lookup <- here('metadata/radseq_metadata_link/lookup_IDshort.txt')
infile_allsamples <- here('metadata/radseq_metadata_link/Samples_RAD_consortium.xls')

outdir <- 'metadata/indsel'
if(! dir.exists(outdir)) dir.create(outdir, recursive = TRUE)
outfile_indsel <- here(outdir, 'mitleh_indsel.txt')
outfile_popmap <- here(outdir, 'mitleh_popmap.txt')

## Read input files:
allsamples <- read.xls(infile_allsamples, header = TRUE)
lookup <- read.delim(infile_lookup, header = TRUE)

## Selection:
focal_species <- c('mittermeieri', 'lehilahytsara')
outgroup_IDs <- c('msim003', 'msim004', 'msim007',
                  'mmae001', 'mmae002', 'mmae003',
                  'marn002', 'marn003', 'marn004',
                  'mgri041', 'mgri044', 'mgri045')

## Process:
lookup_sel <- lookup %>%
  filter(species %in% focal_species | ID %in% outgroup_IDs) %>%
  select(ID, Sample_ID, species, species.short, site)

lookup_sel %>% arrange(site)

popmap <- lookup_sel %>%
  select(ID, species)

table(droplevels(popmap$species))

## Write files:
write.table(lookup_sel, outfile_indsel,
            sep = '\t', quote = FALSE, row.names = FALSE)
write.table(popmap, outfile_popmap,
            sep = '\t', quote = FALSE, row.names = FALSE, col.names = FALSE)
