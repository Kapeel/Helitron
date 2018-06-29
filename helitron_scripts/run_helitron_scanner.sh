#!/bin/bash -login

GENOME=$1
GENOMEFA=$2
SHORTID=$3

### the base path to find all the lcv alignments
HSDIR=/HelitronScanner
## where to find HelitronScanner.jar
HSJAR=/HelitronScanner/HelitronScanner/HelitronScanner.jar

## path to vsearch and silix for clustering
SILIX=silix
VSEARCH=vsearch

### helitron scanner needs some memory to load each chromosome in, so remember that when picking a queue
CPU=4
MEMGB=8

###########################
##   DIRECT ORIENTATION  ##
###########################

##find helitron heads
### will load each chromosome into memory, without splitting into 1Mb batches (-buffer_size option ==0) 
java -Xmx${MEMGB}g -jar ${HSJAR} scanHead -lcv_filepath ${HSDIR}/TrainingSet/head.lcvs -g $GENOMEFA -buffer_size 0 -output ${GENOME}.HelitronScanner.head
## helitron tails
java -Xmx${MEMGB}g -jar ${HSJAR} scanTail -lcv_filepath ${HSDIR}/TrainingSet/tail.lcvs -g $GENOMEFA -buffer_size 0 -output ${GENOME}.HelitronScanner.tail

## pair the ends to generate possible helitrons
java -Xmx${MEMGB}g -jar ${HSJAR} pairends -head_score ${GENOME}.HelitronScanner.head -tail_score ${GENOME}.HelitronScanner.tail -output ${GENOME}.HelitronScanner.pairends

## draw the helitrons into fastas
java -Xmx${MEMGB}g -jar ${HSJAR} draw -pscore ${GENOME}.HelitronScanner.pairends -g $GENOMEFA -output ${GENOME}.HelitronScanner.draw -pure_helitron
 
############################
##    REVERSE COMPLEMENT  ##
############################

##find helitron heads
### will load each chromosome into memory, without splitting into 1Mb batches (-buffer_size option ==0) 
java -Xmx${MEMGB}g -jar ${HSJAR} scanHead -lcv_filepath ${HSDIR}/TrainingSet/head.lcvs -g $GENOMEFA -buffer_size 0 --rc -output ${GENOME}.HelitronScanner.rc.head
## helitron tails
java -Xmx${MEMGB}g -jar ${HSJAR} scanTail -lcv_filepath ${HSDIR}/TrainingSet/tail.lcvs -g $GENOMEFA -buffer_size 0 --rc -output ${GENOME}.HelitronScanner.rc.tail

## pair the ends to generate possible helitrons
java -Xmx${MEMGB}g -jar ${HSJAR} pairends -head_score ${GENOME}.HelitronScanner.rc.head -tail_score ${GENOME}.HelitronScanner.rc.tail --rc -output ${GENOME}.HelitronScanner.rc.pairends

## draw the helitrons
java -Xmx${MEMGB}g -jar ${HSJAR} draw -pscore ${GENOME}.HelitronScanner.rc.pairends -g $GENOMEFA -output ${GENOME}.HelitronScanner.draw.rc -pure_helitron
 

#########################
##   tab format output ##
######################### 

python2.7 /Helitron/helitron_scripts/helitron_scanner_out_to_tabout.py ${GENOME}.HelitronScanner.draw.hel.fa ${GENOME}.HelitronScanner.tabnames.fa > ${GENOME}.HelitronScanner.tabout

python2.7 /Helitron/helitron_scripts/helitron_scanner_out_to_tabout.py ${GENOME}.HelitronScanner.draw.rc.hel.fa ${GENOME}.HelitronScanner.tabnames.fa > ${GENOME}.HelitronScanner.rc.tabout

######################### 
##  Make families      ##
#########################

### think about whether this should be the entire element or the earlier classification based on the terminal 30bp of the helitron. 
### remember that the mtec helitrons have lots of N's in their internal regions, so this decision may have been due to data quality.

python2.7 /Helitron/helitron_scripts/get_last_30bp_fasta.py ${GENOME}.HelitronScanner.tabnames.fa > ${GENOME}.HelitronScanner.tabnames.terminal30bp.fa

$VSEARCH -allpairs_global ${GENOME}.HelitronScanner.tabnames.terminal30bp.fa -blast6out ${GENOME}.terminal30bp.allvall.out -id 0.8 -query_cov 0.8 -target_cov 0.8 --threads=$CPU


## command for clustering entire helitron length (too computationally expensive
##$VSEARCH -allpairs_global ${GENOME}.HelitronScanner.tabnames.fa -blast6out ${GENOME}.allvall.out -id 0.8 -query_cov 0.8 -target_cov 0.8 --threads=$CPU 

$SILIX ${GENOME}.HelitronScanner.tabnames.terminal30bp.fa ${GENOME}.terminal30bp.allvall.out -f DHH -i 0.8 -r 0.8 > ${GENOME}.8080.fnodes


# also cluster with MTEC for naming consistency
wget http://maizetedb.org/~maize/TE_12-Feb-2015_15-35.fa
$VSEARCH --usearch_global TE_12-Feb-2015_15-35.fa -db ${GENOME}.HelitronScanner.tabnames.fa -id 0.8 -query_cov 0.8 -target_cov 0.8 -blast6out ${GENOME}.TEDB.8080.searchglobal.toponly.out -strand both -top_hits_only --threads $CPU

# generate helitron gff3
Rscript /Helitron/helitron_scripts/generate_Helitron_gff.R ${GENOME} $SHORTID

mkdir Helitron_output
mv ${GENOME}* Helitron_output


