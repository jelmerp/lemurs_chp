#### SET-UP ####################################################################
## Packages:
library(here)
library(tidyverse)
library(vcfR)
library(gdsfmt)
library(SNPRelate)

## Variables:
fileID <- 'mitleh.nooutgroup.mac3.FS6'
focal_sp <- c('mmit', 'mleh')

## Input files:
infile_vcf <- here('seqdata/vcf/stacks', paste0(fileID, '.vcf.gz'))
infile_lookup <- here('metadata/radseq_metadata_link/lookup_IDshort.txt')
infile_sites <- here('metadata/lemurs_metadata_link/lookup/sites_pops.txt')
if(!file.exists(infile_vcf)) cat("ERROR: infile_vcf DOES NOT EXIST\n")
if(!file.exists(infile_lookup)) cat("ERROR: infile_lookup DOES NOT EXIST\n")
if(!file.exists(infile_sites)) cat("ERROR: infile_sites DOES NOT EXIST\n")

## Output files:
file_snpgds <- here('analyses/PCA/gds_files/', paste0(fileID, '.gds'))


#### PROCESS INPUT FILES #######################################################
## Check VCF to get individuals that passed filtering:
if(!file.exists(file_snpgds)) snpgdsVCF2GDS(infile_vcf, file_snpgds, method = "biallelic.only")
snps <- snpgdsOpen(file_snpgds)
inds_pass <- read.gdsn(index.gdsn(snps, "sample.id"))

## Metadata files:
lookup_raw <- read.delim(infile_lookup, as.is = TRUE) %>%
  filter(species.short %in% focal_sp) %>%
  select(ID, Sample_ID, species, species.short, site) %>%
  rename(sp = species.short)
pops <- read.delim(infile_sites, as.is = TRUE) %>%
  filter(sp %in% focal_sp) %>%
  mutate(pop2 = ifelse(is.na(pop2), species.short, pop2)) %>%
  select(-sp, -pop1, -poptype)

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
lookup <- lookup_raw %>%
  merge(., pops, by = 'site', all.x = TRUE) %>%
  mutate(filtering = ifelse(ID %in% inds_pass, 'pass', 'fail')) %>%
  select(ID, Sample_ID, sp, site_short, site_lump,
         pop2, pop_group, filtering)

#length(which(lookup$filtering == 'pass'))
#all(inds_pass %in% lookup_raw$ID)


#### EXPLORE #######################################################
## Samples by popgroup:
lookup %>%
  group_by(pop_group, filtering) %>%
  summarise(count = n()) %>%
  pivot_wider(names_from = filtering, values_from = count) %>%
  ungroup() %>%
  mutate(total = fail + pass) %>%
  select(pop_group, pass, fail, total) %>%
  as.data.frame()

## Samples by site:
lookup %>%
  group_by(site_short, pass) %>%
  summarise(count = n()) %>%
  pivot_wider(names_from = pass, values_from = count, values_fill = list(count = 0)) %>%
  ungroup() %>%
  mutate(total = fail + pass) %>%
  merge(., select(pops, site_short, pop_group), by = 'site_short', all.x = TRUE) %>%
  select(site_short, pass, fail, total, pop_group) %>%
  as.data.frame()

## List of all samples:
lookup %>%
  arrange(pop_group, site_lump, ID) %>%
  select(-pop2)
