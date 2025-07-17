acc=$1

if [[ -f *.$acc.fna ]]; then 
	echo "$acc already exists"
else
	datasets download genome accession $acc
	unzip ncbi_dataset.zip

	if  [[ $(md5sum -c md5sum.txt | awk '{print $2}' | sort | uniq) == "OK" ]]; then 
		organism_name=$(jq .organism.organismName -r ncbi_dataset/data/assembly_data_report.jsonl)
		strain=$(jq .organism.infraspecificNames.strain -r ncbi_dataset/data/assembly_data_report.jsonl)
		echo "${organism_name} ${strain}"
	else
		echo "The download didn't work properly!!!!!!!"
	fi
fi

rm -r ncbi_dataset README.md md5sum.txt ncbi_dataset.zip
