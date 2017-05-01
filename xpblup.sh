#!/bin/bash
#---------#---------#---------#---------#---------#---------#---------#---------
usage="
#---------#---------#---------#---------#---------#---------#---------#---------
# Introduction: 
#   	This script implements XP-BLUP, which improves complex traits prediction in
	minority populations via combining trans-ethnic and ethnic-specific
	information. It requires plink (https://www.cog-genomics.org/plink2 v1.90 or later) and
	gcta (http://cnsgenomics.com/software/gcta/, v1.25.3 or later). Please contact 	
	huatang@stanford.edu or hyfang@stanford.edu for bugs.
#---------#---------#---------#---------#---------#---------#---------#---------
Usage: 
	./xpblup.sh [--help] [--plink=/usr/local/bin/plink] [--gcta=/usr/local/bin/gcta64] [--pheno=./phenos/traindataN4k.pheno] --train=./example_data/trainN4k --test=./example_data/testN2k --snplist=./example_data/metaExtract.txt [--outdir=./output] [--outprefix=out]
# (The parameters in [ ] are optinal if the corresponding command is in system path.)
#---------#---------#---------#---------#---------#---------#---------#---------
Options:
  -h, --help		Print short help message and exit (Optional)
  --plink=plink_loc	Plink location (Optional if plink is in system paths.)
  --gcta=gcta_loc	 Gcta location (Optional if gcta/gcta64 is in system paths.)
  --pheno=filename	Phenotype file for train data (Optional if phenotype file
	 				is included in train_location.fam)
  --train=filename	Train data for model learning (Required in Plink binary
	 				format: train_location.bed/bim/fam)
  --test=filename  	Test data for model prediction (Required in Plink binary
	 				format: test_location.bed/bim/fam)
  --snplist=filename	SNP list file that defines SNP set C1 (Required)
  --outdir=out_dir	Output directory (Default: ./output if not given)
  --outprefix=out	Output prefix (Default: out if not given)
Example: 
  ./xpblup.sh --train=./example_data/trainN4k --test=./example_data/testN2k --snplist=./example_data/metaExtract.txt
  OR
  ./xpblup.sh --plink=/srv/gsfs0/software/plink/1.90/plink --gcta=/home/hyfang/bin/gcta64 --train=./example_data/trainN4k --test=./example_data/testN2k --snplist=./example_data/metaExtract.txt --outdir=./example_output --outprefix=example_out
#---------#---------#---------#---------#---------#---------#---------#---------
"
#---------#---------#---------#---------#---------#---------#---------#---------
# Assign default parameters
PLINK_=plink
GCTA_=gcta64
[ -x "$(command -v $GCTA_)" ] || GCTA_=gcta
outdir=./output;
outprefix=out;
pheno_=;
# Three required parameters
traindata=;
testdata=;
snplist=;
#---------#---------#---------#---------#---------#---------#---------#---------
# Arguments loop
SED_=sed;
[ -x "$(command -v $SED_)" ] || { echo "SED is not working ($SED_)" && exit 1; }
# AWK_=gawk;
AWK_=awk;
[ -x "$(command -v $AWK_)" ] || { echo "SED is not working ($AWK_)" && exit 1; }
while test -n "${1}"; do
	case ${1} in
		-h|--help)
			echo "${usage}"; 
			exit 0;;
		--plink=*)
			PLINK_=`echo "${1}" | ${SED_} -e 's/[^=]*=//'`;;
		--gcta=*)
			GCTA_=`echo "${1}" | ${SED_} -e 's/[^=]*=//'`;;
		--pheno=*)
			pheno_=`echo "${1}" | ${SED_} -e 's/[^=]*=//'`;;
		--train=*)
			traindata=`echo "${1}" | ${SED_} -e 's/[^=]*=//'`;;
		--test=*)
			testdata=`echo "${1}" | ${SED_} -e 's/[^=]*=//'`;;
		--snplist=*)
			snplist=`echo "${1}" | ${SED_} -e 's/[^=]*=//'`;;
		--outdir=*)
			outdir=`echo "${1}" | ${SED_} -e 's/[^=]*=//'`;
			[ -n "${outdir}" ] || outdir=./output;
			;;
		--outprefix=*)
			outprefix=`echo "${1}" | ${SED_} -e 's/[^=]*=//'`;
			[ -n "${outprefix}" ] || outprefix=out;
			;;
		*)
			echo $"${1} is not available for $0!";
			exit 1;;	
	esac
	shift;
done
#---------#---------#---------#---------#---------#---------#---------#---------
# Check existence of command and data files
# Plink and GCTA
[ -x "$(command -v $PLINK_)" ] || { echo "PLINK is not working ($PLINK_)."; exit 1; }
[ -x "$(command -v $GCTA_)" ] || { echo "GCTA is not working ($GCTA_)."; exit 1; }
# Train and test datasets
[ -f "$traindata.bed" -a -f "$traindata.bim" -a -f "$traindata.fam" ] || { echo "Please check the train dataset: $traindata.bed/bim/fam."; exit 1; }
[ -f "$testdata.bed" -a -f "$testdata.bim" -a -f "$testdata.fam" ] || { echo "Please check the train dataset: $testdata.bed/bim/fam."; exit 1; }
# SNP list for SNP set C1
[ -f "$snplist" -a -s "$snplist" ] || { echo "Please check the SNP set C1: $snplist."; exit 1; }
# Check phenotype file if given separate file
[ -n "$pheno_" -a ! -f "$pheno_" ] && { echo "Please check the separate phenotype file: $pheno_."; exit 1; }
# Using train dataset .fam if unset phenotype file
[ ! -d ${outdir} ] && mkdir -p ${outdir}
if [ -z "$pheno_" ]; then
	pheno_=${outdir}/train_.pheno; 
	${AWK_} '{print $1,$2,$6;}' ${traindata}.fam > ${pheno_};
fi
#---------#---------#---------#---------#---------#---------#---------#---------
out_prefix=${outdir}/${outprefix}
logfile=${out_prefix}.log
> ${logfile}
# Compute GRMs for SNPs (Set C1 and All SNPs)
echo -e "$(date): Calculating GRM...\n" >> ${logfile}
${GCTA_} --bfile ${traindata} --extract ${snplist} --make-grm-bin --out ${out_prefix}_small
${GCTA_} --bfile ${traindata} --make-grm-bin --out ${out_prefix}_full 
echo -e "$(date): GRM successful! \n" >> ${logfile}
# REML
grmlist=${outdir}/grmList.txt
> ${grmlist}
echo -e "${out_prefix}_full\n${out_prefix}_small" > ${grmlist} 
echo -e "$(date): Running REML analysis ...\n" >> ${logfile}
${GCTA_} --reml --mgrm-bin ${grmlist} --pheno ${pheno_} --out ${out_prefix} --reml-est-fix --reml-pred-rand 
${GCTA_} --bfile ${traindata} --mgrm-bin ${grmlist} --blup-snp ${out_prefix}.indi.blp --out ${out_prefix}
echo -e "$(date): REML successful! \n" >> ${logfile}
#---------#---------#---------#---------#---------#---------#---------#---------
## Reformat beta coefficients

betafn=${out_prefix}.snp.blp
newbetafn=${out_prefix}.betaRecal
echo -e "$(date): Reformatting beta coefficients ...\n" >> ${logfile}
M_full=`wc -l < ${traindata}.bim`;
M2_small=`wc -l < ${snplist}`;
# ${AWK_} -v M=${M_full} -v M2=${M2_small} '
export M_full;
export M2_small;
${AWK_} 'BEGIN{M = ENVIRON["M_full"]; M2 = ENVIRON["M2_small"];}
	NR==FNR {
	  arr[$1];
	  next;
  } 
  {
	  beta_fixed = $3 * 2 * M;
	  if($1 in arr) {
	  	beta_fixed += $4 * 2 * M * M / M2;
	  };
	  print $1,$2,beta_fixed;
  }
' ${snplist} ${betafn} > ${newbetafn}
echo -e "$(date): Reformatting beta coefficients successful! \n" >> ${logfile}
#---------#---------#---------#---------#---------#---------#---------#---------
# Prediction for test data
echo -e "$(date): Calculating final prediction ...\n" >> ${logfile}
${PLINK_} --bfile  ${testdata} --allow-no-sex --score ${newbetafn} --out ${out_prefix}.predict  
echo -e "$(date): Job Completed! \n" >> ${logfile}
#---------#---------#---------#---------#---------#---------#---------#---------



