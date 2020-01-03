################################################################################
#### SELECT FILES ####
################################################################################
# VCF_DIR=/datacommons/yoderlab/users/jelmer/proj/sisp/seqdata/vcf/map2mmur.gatk.joint/final
# ROOT=mgri
# FILE_IDS=( berrufmyo.mac1.FS6 berrufmyo.mac3.FS6 )
# FILE_IDS=( borsim_germarjol.mac1.FS6 borsim_germarjol.mac3.FS6 borsim_germarjol.mac1.FS7 borsim_germarjol.mac3.FS7)

VCF_DIR=/datacommons/yoderlab/users/jelmer/proj/sisp/seqdata/stacks/ruftan/all/vcf/
ROOT=mgri
FILE_IDS=( ruftan.all.mac1.FS6 ruftan.all.mac1.FS7 ruftan.all.mac3.FS6 ruftan.all.mac3.FS7 ruftan.no_ruf.mac3.FS6 ruftan.no_mitlehmae.mac3.FS6 ruftan.no_mitleh.mac3.FS6 )

################################################################################
#### RUN TREEMIX ####
################################################################################
PREP_INPUT=TRUE
MINMIG=0
MAXMIG=10
TREEMIX_DIR=/datacommons/yoderlab/users/jelmer/proj/sisp/analyses/treemix/
INDS_METADATA=/datacommons/yoderlab/users/jelmer/proj/radseq/metadata/lookup_IDshort.txt
SELECT_BY_COLUMN="species.short"
SCR_TREEMIX=/datacommons/yoderlab/users/jelmer/scripts/treemix/treemix_pip.sh
#ROOT=none

for FILE_ID in ${FILE_IDS[@]}
do
	echo -e "\n\n\n #### File ID: $FILE_ID"
	$SCR_TREEMIX $FILE_ID $VCF_DIR $PREP_INPUT $MINMIG $MAXMIG $ROOT $TREEMIX_DIR $INDS_METADATA $SELECT_BY_COLUMN
done



	
################################################################################
# rsync -avr --no-perms /home/jelmer/Dropbox/sc_lemurs/proj/sisp/scripts/ jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/proj/sisp/scripts/
# rsync -avr --no-perms /home/jelmer/Dropbox/sc_lemurs/scripts/ jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/scripts/

# rsync -avr /home/jelmer/Dropbox/sc_lemurs/proj/radseq/metadata/ jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/proj/radseq/metadata/
# rsync -avr /home/jelmer/Dropbox/sc_lemurs/proj/sisp/metadata/* jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/proj/sisp/metadata/
# rsync -avr /home/jelmer/Dropbox/sc_lemurs/proj/sisp/analyses/trees/treemix/popfiles/* jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/proj/sisp/analyses/treemix/popfiles/

# rsync -avr jwp37@dcc-slogin-02.oit.duke.edu:/datacommons/yoderlab/users/jelmer/proj/sisp/analyses/treemix/output/* /home/jelmer/Dropbox/sc_lemurs/proj/sisp/analyses/treemix/output


################################################################################
################################################################################
## Gri root:
FILE_IDS=( berrufmyo.mac1.FS6 berrufmyo.mac3.FS6 berrufmyo_gri45.mac1.FS6 berrufmyo_gri45.mac3.FS6 )
ROOT=mgri
for FILE_ID in ${FILE_IDS[@]}
do
	echo $FILE_ID
	/datacommons/yoderlab/users/jelmer/scripts/treemix/treemix_pip.sh \
	$FILE_ID $VCF_DIR $PREP_INPUT $MINMIG $MAXMIG $ROOT $TREEMIX_DIR $INDS_METADATA $SELECT_BY_COLUMN
done

## Mur root:
FILE_IDS=( berrufmyo_mur1.mac1.FS6 berrufmyo_mur1.mac3.FS6 berrufmyo_mur9.mac1.FS6 berrufmyo_mur9.mac3.FS6 berrufmyo_4og.mac1.FS6 berrufmyo_4og.mac3.FS6 )
ROOT=mmur
for FILE_ID in ${FILE_IDS[@]}
do
	echo $FILE_ID
	/datacommons/yoderlab/users/jelmer/scripts/treemix/treemix_pip.sh \
	$FILE_ID $VCF_DIR $PREP_INPUT $MINMIG $MAXMIG $ROOT $TREEMIX_DIR $INDS_METADATA $SELECT_BY_COLUMN
done

## No outgroup:
FILE_IDS=( berrufmyo.noOutg.mac1.FS6 berrufmyo.noOutg.mac3.FS6 )
ROOT=mmyo
for FILE_ID in ${FILE_IDS[@]}
do
	echo "#### File ID: $FILE_ID"
	/datacommons/yoderlab/users/jelmer/scripts/treemix/treemix_pip.sh \
	$FILE_ID $VCF_DIR $PREP_INPUT $MINMIG $MAXMIG $ROOT $TREEMIX_DIR $INDS_METADATA $SELECT_BY_COLUMN
done
