cd $DIR_MEMPANG25

mkdir -p day2_impg/assemblies
cd day2_impg/assemblies

if [ ! -f primates16.hsa6.fa.gz ]; then #only download the file if it isn't already there
    wget https://garrisonlab.s3.amazonaws.com/teaching/primates16.hsa6.fa.gz
fi
if [ !-f primates16.hsa6.fa.gz.fai ]; then
    samtools faidx primates16.hsa6.fa.gz
fi

cd $DIR_MEMPANG25/day2_impg
mkdir -p alignments

# IT TAKES TIME
if [ ! -f alignments/primates16-vs-chm13.hsa6.paf ]; then
    wfmash assemblies/primates16.hsa6.fa.gz --target-prefix chm13 -t 32 -p 95 > alignments/primates16-vs-chm13.hsa6.paf
fi