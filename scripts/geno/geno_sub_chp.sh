## General settings:
SCR_GJOINT=/datacommons/yoderlab/users/jelmer/scripts/genomics/geno/gatk/jgeno_pip.sh
REF_DIR=/datacommons/yoderlab/users/jelmer/seqdata/reference/mmur/
REF_ID=GCF_000165445.2_Mmur_3.0_genomic_stitched
REF=$REF_DIR/$REF_ID.fasta
SCAFFOLD_FILE=$REF_DIR/$REF_ID.scaffoldList_NC.txt # Only do mapped (NC_) scaffolds + exclude mtDNA
GVCF_DIR=/datacommons/yoderlab/data/radseq/vcf/map2mmur.gatk.ind/gvcf
VCF_DIR=/datacommons/yoderlab/users/jelmer/proj/sisp/seqdata/vcf/map2mmur.gatk.joint/
QC_DIR_VCF=/datacommons/yoderlab/users/jelmer/proj/sisp/qc/vcf/map2mmur.gatk.joint/
LOOKUP=/datacommons/yoderlab/users/jelmer/radseq/metadata/lookup_IDshort.txt
ADD_COMMANDS="none"
MEM_JOB=24
MEM_GATK=20
NCORES=1
SKIP_GENO=FALSE
DP_MEAN=5

################################################################################
#### ALL TOGETHER ####
################################################################################
FILE_ID=sisp_all
IDs=( $(cat $LOOKUP | egrep -v "excl" | cut -f 1 | egrep "mber|mruf|mmyo|mbor|msim|mger|mmar|mjol|mbon|mdan|mrav|mmam|mmae|msam|marn|mspp001|mspp011|mspp013|mspp014|mspp015|mspp033|mgan008|mmur001|mmur009|mmur083|mgri041|mgri043|mgri044|mgri045|mmur009") )
sbatch -p yoderlab,common,scavenger --job-name=jgeno -o slurm.jgeno.pip.$FILE_ID \
	$SCR_GJOINT $FILE_ID $SCAFFOLD_FILE $GVCF_DIR $VCF_DIR $QC_DIR_VCF $REF \
	"$ADD_COMMANDS" $MEM_JOB $MEM_GATK $NCORES $SKIP_GENO $DP_MEAN ${IDs[@]}

FILE_ID=north
IDs=( $(cat $LOOKUP | egrep -v "excl" | cut -f 1 | egrep "mmam|mmae|msam|marn|mspp001|mspp011|mspp013|mspp014|mspp015|mspp033|mgri044|mmur009") )
sbatch -p yoderlab,common,scavenger --job-name=jgeno -o slurm.jgeno.pip.$FILE_ID \
	$SCR_GJOINT $FILE_ID $SCAFFOLD_FILE $GVCF_DIR $VCF_DIR $QC_DIR_VCF $REF \
	"$ADD_COMMANDS" $MEM_JOB $MEM_GATK $NCORES $SKIP_GENO $DP_MEAN ${IDs[@]}

	
################################################################################
#### BERRUFMYO ####
################################################################################
FILE_ID=berrufmyo
IDs=( $(cat $LOOKUP | egrep -v "excl" | cut -f 1 | egrep "mber|mruf|mmyo|mgri044|mmur009") )
sbatch -p yoderlab,common,scavenger --job-name=jgeno -o slurm.jgeno.pip.$FILE_ID \
	$SCR_GJOINT $FILE_ID $SCAFFOLD_FILE $GVCF_DIR $VCF_DIR $QC_DIR_VCF $REF \
	"$ADD_COMMANDS" $MEM_JOB $MEM_GATK $NCORES $SKIP_GENO $DP_MEAN ${IDs[@]}
