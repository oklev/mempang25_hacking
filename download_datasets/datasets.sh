accessions=""
infraspecific_names="isolate"
samples="seqs.tsv"
scratch_name=${SLURM_JOB_NAME#download_}; scratch_name=${scratch_name#graph_}
add=false
getname() {
    name=$(echo "$metadata" | jq -r ".reports[0].organism.infraspecific_names[\"$infraspecific_names\"] // \"$acc\"")
    if [[ "$name" == "$acc" ]]
    then
        name=$(echo "$metadata" | jq -r ".reports[0].organism.organism_name // \"$acc\"")
    fi
    echo "${name// /_}"
}
gethap() {
    h=$(echo $metadata | jq -r '.reports[0].assembly_info.diploid_role // "1"')
    h=${h#haplotype_*}; h=${h/principal/1}; h=${h/alternate/2}; h=${h%*_pseudohaplotype*}
    echo $h
}
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --getname=*) namef="${1#*=}" && eval "getname() { $namef; }";;
        --gethap=*) haplotypef="${1#*=}" && eval "gethap() { $haplotypef; }";;
        --infraspecific_names=*) infraspecific_names="${1#*=}";;
        --names=*) infraspecific_names="${1#*=}";;
        --samples=*) samples="${1#*=}";;
        --scratch_name=*) scratch_name="${1#*=}";;
        --scratch=*) scratch_name="${1#*=}";;
        --add) add=true;;
        *) accessions="$accessions $1";;
    esac
    shift
done

scratch_dir=/scratch/hkg58926/miniME/$scratch_name
mkdir -p $scratch_dir
cd $scratch_dir

ml NCBI-Datasets-CLI
ml jq

if [ $add = false ] && [ -f "$samples" ];
then
    rm $samples
fi 
for acc in $accessions
do
    if [ ! -f $acc.fna ]
    then
        mkdir -p $acc
        cd $acc
        datasets download genome accession $acc
        unzip ncbi_dataset.zip
        mv ncbi_dataset/data/$acc/*.fna $scratch_dir/$acc.fna
        cd $scratch_dir
        rm -r $acc
    fi
    metadata=$(datasets summary genome accession $acc)
    echo -e "$scratch_dir/$acc.fna\t$(getname)\t$(gethap)" >> $samples
    sleep 1s
done