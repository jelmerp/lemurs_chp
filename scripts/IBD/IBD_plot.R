#### SET-UP --------------------------------------------------------------------
## Settings:
setID <- 'mitleh.nooutgroup.mac3.FS6'

## Script with functions:
library(here)
source(here('scripts/genomics_link/IBD/IBD_fun.R'))

## Dirs/files:
input_dir <- here('analyses/IBD/RDS/')
output_dir <- here('analyses/IBD/fig/')
plotbase <- paste0(output_dir, 'IBD_', setID, '_')

## Colors:
my_cols <- RColorBrewer::brewer.pal(name = 'Set1', n = 3)[1:2]
#my_cols <- colorblindr::palette_OkabeIto[1:2]


#### RUN -----------------------------------------------------------------------
outfile_plot <- paste0(plotbase, '.png')
my_title <- expression(paste(italic("mittermeieri - lehilahytsara"), ': all pops'))

p_mitleh <- ibd_plot_wrap(
  setID, subsetID = 'mitleh', my_cols = my_cols,
  input_dir, output_dir, saveplot = FALSE, plot_title = my_title
  )

pl <- p_mitleh + aes(text = paste0(site1, '(', sp1, ') - ', site2, '(', sp2, ')'))
pl <- ggplotly(pl)

#### RESULT --------------------------------------------------------------------
## Statistic: Pearson's product-moment correlation
## Value: 0.5723
## Significance: 0.001