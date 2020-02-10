  #https://rdrr.io/cran/dartR/f/inst/doc/IntroTutorial_dartR.pdf

  #### SET-UP --------------------------------------------------------------------
  ## Settings:
  setID <- 'mitleh.nooutgroup.mac3.FS6'
  subsets <- list('mitleh' = c('mmit', 'mleh'))

  ## Script with functions:
  library(here)
  source(here('scripts/genomics_link/IBD/IBD_fun.R'))

  ## Input files:
  infile_vcf <- here('seqdata/vcf/stacks/', paste0(setID, '.vcf.gz'))
  stopifnot(file.exists(infile_vcf))

  infile_lookup <- here('metadata/radseq_metadata_link/lookup_IDshort.txt')
  infile_sites <- here('metadata/lemurs_metadata_link/lookup/sites_gps.txt')
  infile_pops <- here('metadata/lemurs_metadata_link/lookup/sites_pops.txt')
  stopifnot(file.exists(infile_lookup), file.exists(infile_sites),
            file.exists(infile_pops))

  ## Output files:
  outdir_RDS <- here('analyses/IBD/RDS/')
  RDS_vcf <- paste0(outdir_RDS, setID, '_snps.RDS')
  if(!dir.exists(outdir_RDS)) dir.create(outdir_RDS, recursive = TRUE)


  #### RUN MANTEL TEST -----------------------------------------------------------
  ## Prep:
  lookup <- prep_metadata(setID)
  snps <- read_vcf(infile_vcf, lookup, RDS_vcf)

  ## Run for subsets:
  mantel_wrap(subsets['mitleh'], snps, lookup)
