#VCF_DIR=/datacommons/yoderlab/users/jelmer/proj/chp/seqdata/vcf/map2mmur.gatk.joint/final # Dir with existing VCF file(s)
VCF_DIR=/datacommons/yoderlab/users/jelmer/proj/chp/geno/stacks/mitleh/all/vcf/
PLINK_DIR=/work/jwp37/chp/seqdata/plink # Dir for PLINK files (to be produced)
OUTDIR=/datacommons/yoderlab/users/jelmer/proj/chp/analyses/admixture/output/ # Dir for Admixture files (to be produced)
MAF=0 # Minor Allele Frequency (normally set to 0, meaning that low-frequency alleles will not be removed)
LD_MAX=1 # Max Linkage Disequilibrium (LD) (normally set to 1, meaning to no "LD-pruning" will be done)
NCORES=1 # Number of cores

SET_ID=mitleh.all
INDFILE=/datacommons/yoderlab/users/jelmer/proj/chp/analyses/admixture/indsel/$SET_ID.txt
FILE_IDS=( $SET_ID.mac1.FS6 $SET_ID.mac3.FS6 $SET_ID.mac1.FS7 $SET_ID.mac3.FS7) # File IDs for VCF files, VCF files should be: $VCF_DIR/$FILE_ID.vcf.gz

SET_ID=mitleh.singleoutgroup
INDFILE=/datacommons/yoderlab/users/jelmer/proj/chp/analyses/admixture/indsel/$SET_ID.txt
FILE_IDS=(  $SET_ID.mac3.FS6 $SET_ID.mac3.FS7)

SET_ID=mitleh.nooutgroup
INDFILE=/datacommons/yoderlab/users/jelmer/proj/chp/analyses/admixture/indsel/$SET_ID.txt
FILE_IDS=(  $SET_ID.mac3.FS6 $SET_ID.mac3.FS7)

for FILE_ID in ${FILE_IDS[@]}
do
	echo -e "\n#### File ID: $FILE_ID"
	bcftools query -l $VCF_DIR/$FILE_ID.vcf.gz > $INDFILE # Send list of inds minus "mruf" (outgroup) to separate textfile

	sbatch -p yoderlab,common,scavenger --mem 8G -o slurm.admixture.pip.$FILE_ID \
	/datacommons/yoderlab/users/jelmer/scripts/admixture/admixture_pip.sh $FILE_ID $VCF_DIR $PLINK_DIR $OUTDIR $MAF $LD_MAX $NCORES $INDFILE
done


################################################################################
################################################################################
rsync -avr --no-perms /home/jelmer/Dropbox/sc_lemurs/scripts/ jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/scripts/
rsync -avr jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/proj/chp/analyses/admixture/output/* /home/jelmer/Dropbox/sc_lemurs/proj/chp/analyses/admixture/output/
