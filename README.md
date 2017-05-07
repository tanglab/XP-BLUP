# Introduction
This script implements XP-BLUP, which improves complex traits prediction in minority populations by combining trans-ethnic and ethnic-specific information. It requires plink (https://www.cog-genomics.org/plink2 v1.90 or later) and gcta (http://cnsgenomics.com/software/gcta/, v1.25.3 or later). Please contact huatang@stanford.edu or hyfang@stanford.edu for questions or bug report.

# Usage 
	./xpblup.sh [--help] [--plink=/usr/local/bin/plink] [--gcta=/usr/local/bin/gcta64] [--pheno=./phenos/traindataN4k.pheno] 
	--train=./example_data/trainN4k --test=./example_data/testN2k --snplist=./example_data/metaExtract.txt 
	[--outdir=./output] [--outprefix=out]

 The parameters in [ ] are optinal if the corresponding command is in system path. Or
 
	./xpblup.sh --train=./example_data/trainN4k --test=./example_data/testN2k --snplist=./example_data/metaExtract.txt

# Options
  -h, --help		Print short help message and exit (Optional)
  
  --plink=plink_loc	PLINK location (Optional if plink is in system paths.)
  
  --gcta=gcta_loc	 GCTA location (Optional if gcta/gcta64 is in system paths.)
  
  --pheno=filename	Phenotype file for train data (Optional if phenotype file is included in train_location.fam)
  
  --train=filename	Train data for model learning (Required in PLINK binary format: train_location.bed/bim/fam)
  
  --test=filename  	Test data for model prediction (Required in PLINK binary format: test_location.bed/bim/fam)
	 			
  --snplist=filename	SNP list file that defines SNP set C1 (Required)
  
  --outdir=out_dir	Output directory (Default: ./output if not given)
  
  --outprefix=out	Output prefix (Default: out if not given)

# Example
  An example data is included in the data directory:
  
  --metaExtract.txt File defines C1 SNP set
  
  --train4k.bed: binary format of genotype data of the training individuals 
  
  --test2k.bed: binary format of genotype data of the test individuals
  
  In this case, the phenotype is in the binary data. Otherwise it can be supplied by --pheno
