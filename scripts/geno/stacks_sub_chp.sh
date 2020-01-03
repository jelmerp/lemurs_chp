## General options:
STACKSDIR=/datacommons/yoderlab/users/jelmer/proj/chp/geno/stacks/
SCR_PIP=/datacommons/yoderlab/users/jelmer/scripts/geno/stacks/stacks_pip.sh
LOOKUP=/datacommons/yoderlab/users/jelmer/proj/radseq/metadata/lookup_IDshort.txt
BAMDIR=/datacommons/yoderlab/data/radseq/bam/map2mmur/final_merged/
BAMSUFFIX=".sort.MQ30.dedup.bam"
REF=/datacommons/yoderlab/users/jelmer/seqdata/reference/mmur/GCF_000165445.2_Mmur_3.0_genomic_stitched.fasta
SCAF_FILE=/datacommons/yoderlab/users/jelmer/seqdata/reference/mmur/scaffoldLength_NC.txt
NCORES=8
BED_EXONS=notany
ADD_OPS_GSTACKS=""
ADD_OPS_POPSTACKS="--min-samples-overall 0.9 --fasta-samples"
CALLABLE_COMMAND="--minDepth 3"
MAXMISS_IND=10
MAXMISS_MEAN=10
MINDIST=10000 # Most were produced with 5k...
MINLENGTH=100
LENGTH_QUANTILE=10 # Locus length quantile to adjust locus length to. Compute quantiles across inds for a locus, then take LENGTH_QUANTILE/100 quantile as locus length.
MAXINDMISS=25 # Max % missing inds per locus
TO_SKIP="" # G: gstacks / P: popstacks / V: filter VCF / F: filter fasta

## All inds:
GSTACKS_ID=mitleh
POPSTACKS_ID=all
POPMAP_GSTACKS=/datacommons/yoderlab/users/jelmer/proj/chp/metadata/indsel/${GSTACKS_ID}_popmap.txt
POPMAP_POPSTACKS=$POPMAP_GSTACKS
FASTA_ID=notany
TO_SKIP="-GPF"
$SCR_PIP $GSTACKS_ID $POPSTACKS_ID $FASTA_ID $STACKSDIR $BAMDIR $BAMSUFFIX \
 $POPMAP_GSTACKS $POPMAP_POPSTACKS "$ADD_OPS_GSTACKS" "$ADD_OPS_POPSTACKS" \
 $REF $SCAF_FILE "$CALLABLE_COMMAND" $MAXMISS_IND $MAXMISS_MEAN $MINDIST $MINLENGTH $LENGTH_QUANTILE $MAXINDMISS $NCORES $TO_SKIP
 


## ...
GSTACKS_ID=berrufmyo
POPSTACKS_ID=3s1
FASTA_ID=final
POPMAP_GSTACKS=/datacommons/yoderlab/users/jelmer/proj/chp/metadata/indsel/stacks_popmap/$GSTACKS_ID.txt
POPMAP_POPSTACKS=/datacommons/yoderlab/users/jelmer/proj/chp/metadata/indsel/stacks_popmap/$GSTACKS_ID.$POPSTACKS_ID.txt
TO_SKIP="-GPV"
$SCR_PIP $GSTACKS_ID $POPSTACKS_ID $FASTA_ID $STACKSDIR $BAMDIR $BAMSUFFIX \
	$POPMAP_GSTACKS $POPMAP_POPSTACKS "$ADD_OPS_GSTACKS" "$ADD_OPS_POPSTACKS" $BED_EXONS \
	$REF $SCAF_FILE "$CALLABLE_COMMAND" $MAXMISS_IND $MAXMISS_MEAN $MINDIST $MINLENGTH $LENGTH_QUANTILE $MAXINDMISS $NCORES $TO_SKIP

	

	
################################################################################
################################################################################
rsync -avr --no-perms /home/jelmer/Dropbox/sc_lemurs/scripts/ jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/scripts/
rsync -avr --no-perms /home/jelmer/Dropbox/sc_lemurs/proj/radseq/metadata/ jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/proj/radseq/metadata/
rsync -avr --no-perms /home/jelmer/Dropbox/sc_lemurs/proj/chp/metadata/ jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/proj/chp/metadata/



################################################################################
#vcftools --gzvcf $VCF --missing-indv
#vcftools --gzvcf $VCF --depth