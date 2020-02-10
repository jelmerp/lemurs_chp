################################################################################
#### SELECT FILE ####
################################################################################
## GATK:
# VCF_DIR=/datacommons/yoderlab/users/jelmer/proj/chp/seqdata/vcf/map2mmur.gatk.joint/final/
# FILE_IDS=( chp_all.mac1.FS7 chp_all.mac1.FS6 )

## Stacks:
VCF_DIR=/datacommons/yoderlab/users/jelmer/proj/chp/geno/stacks/mitleh/all/vcf/
FILE_IDS=( mitleh.all.mac1.FS6 mitleh.all.mac3.FS6 mitleh.all.mac1.FS7 mitleh.all.mac3.FS7 mitleh.singleoutgroup.mac3.FS6)

################################################################################
#### RUN ####
################################################################################
FASTA_DIR=/work/jwp37/proj/chp/analyses/splitstree/fasta # Dir for fasta files (convert to Nexus via fasta)
NEXUS_DIR=/work/jwp37/proj/chp/analyses/splitstree/nexus/ # Dir for nexus files (Splitstree takes Nexus as input)
OUTDIR=/datacommons/yoderlab/users/jelmer/proj/chp/analyses/splitstree/output/ # Splitstree output dir
MEM=20 # Memory in GB

for FILE_ID in ${FILE_IDS[@]}
do
	#FILE_ID=mitleh.singleoutgroup.mac3.FS7
	echo -e "\n#### File ID: $FILE_ID"
	sbatch -p yoderlab,common,scavenger --mem=${MEM}G -o slurm.splitstree.pip.$FILE_ID \
	/datacommons/yoderlab/users/jelmer/scripts/genomics/splitstree/splitstree_pip.sh $FILE_ID $VCF_DIR $FASTA_DIR $NEXUS_DIR $OUTDIR $MEM
done



################################################################################
################################################################################
rsync -avr jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/proj/chp/analyses/splitstree/output/ /home/jelmer/Dropbox/sc_lemurs/proj/chp/analyses/splitstree/output/
