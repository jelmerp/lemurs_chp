################################################################################
#### SPLIT BY INDS ####
################################################################################
## Subset VCF - Single outgroup:
ID_IN=mitleh.all
ID_OUT=mitleh.singleoutgroup
INDLIST=/datacommons/yoderlab/users/jelmer/proj/chp/geno/stacks/mitleh/all/vcf/indsel/$ID_OUT.indsel
TO_GREP="mmae|marn|msim"
GREP_ADD="-v"
bcftools query -l $VCF_IN | egrep $GREP_ADD "$TO_GREP" > $INDLIST
for SUFFIX in mac3.FS6 mac3.FS7
do
	echo "$SUFFIX"
	VCF_IN=/datacommons/yoderlab/users/jelmer/proj/chp/geno/stacks/mitleh/all/vcf/$ID_IN.$SUFFIX.vcf.gz
	VCF_OUT=/datacommons/yoderlab/users/jelmer/proj/chp/geno/stacks/mitleh/all/vcf/$ID_OUT.$SUFFIX.vcf.gz
	bcftools view -O z -S $INDLIST $VCF_IN > $VCF_OUT
done

## Subset VCF - No outgroups:
ID_IN=mitleh.all
ID_OUT=mitleh.nooutgroup
INDLIST=/datacommons/yoderlab/users/jelmer/proj/chp/geno/stacks/mitleh/all/vcf/indsel/$ID_OUT.indsel
TO_GREP="mmae|marn|msim|mgri"
GREP_ADD="-v"
for SUFFIX in mac3.FS6 mac3.FS7
do
	echo "$SUFFIX"
	VCF_IN=/datacommons/yoderlab/users/jelmer/proj/chp/geno/stacks/mitleh/all/vcf/$ID_IN.$SUFFIX.vcf.gz
	VCF_OUT=/datacommons/yoderlab/users/jelmer/proj/chp/geno/stacks/mitleh/all/vcf/$ID_OUT.$SUFFIX.vcf.gz
	bcftools query -l $VCF_IN | egrep $GREP_ADD "$TO_GREP" > $INDLIST
	bcftools view -O z -S $INDLIST $VCF_IN > $VCF_OUT
done


################################################################################
#### SPLIT BY SCAFFOLD ####
################################################################################
## Remove scaffoldO:
ID_IN=mitleh.all
ID_OUT=mitleh.chromsel
VCF_IN=/datacommons/yoderlab/users/jelmer/proj/chp/geno/stacks/mitleh/all/vcf/$ID_IN.mac3.FS6.vcf.gz
VCF_OUT=/datacommons/yoderlab/users/jelmer/proj/chp/geno/stacks/mitleh/all/vcf/$ID_OUT.mac3.FS6.vcf.gz
REGION_FILE=/datacommons/yoderlab/users/jelmer/geno/reference/mmur/scaffolds_mapped_autosomal.bed
bcftools view -O z -R $REGION_FILE $VCF_IN > $VCF_OUT


################################################################################
rsync -avr jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/proj/chp/geno/stacks/mitleh/all/vcf/mitleh.nooutgroup.mac3.FS6.vcf.gz /home/jelmer/Dropbox/sc_lemurs/proj/chp/seqdata/vcf/stacks/