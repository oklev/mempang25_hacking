# Building the NCBI datasets downloading script

Our eventual goal is to have a script that follows these specifications:

| Step | Description |
| :---: | :--- |
| Input | A list of NCBI accession numbers |
| Download | Download each file from genbank using NCBI datasets |
| Validate | Validate that the file was downloaded correctly |
| Rename | Use metadata from NCBI to rename the file |

We may also want some options we can choose when running the script, such as what metadata field to look for the name.

## Step One: Prepare the conda environment

In the sample script datasets.sh, I use my cluster's module system to get access to datasets and jq; but we will use Conda in this exercise to make it useable regardless of what HPC we're on.

Do the following:
```
conda create --name datasets -y
conda activate datasets
```

Now there are two packages we need to install. Navigate to https://anaconda.org/ and search for the ncbi datasets cli package, and the "jq" package we will use to parse JSON data on the command line.

<p>
<details>
<summary>Try to build the conda environment yourself, or click here to reveal.</summary>
<pre><code>conda create --name datasets -y
conda activate datasets
conda install conda-forge::ncbi-datasets-cli -y
conda install conda-forge::jq -y
</code></pre>
</details>
</p>


**Question: What is the purpose of the `-y` flag at the end of these conda commands?**
<p>
<details>
<summary>Answer</summary>
The flag automatically answers `y` when conda asks `Proceed ([y]/n)?` so that you don't have to do it interactively. I used it here so that you could build the conda environment by copying and pasting the whole block of code at once if you wanted to.
</details>
</p>

**Question: What would happen if you wrote `conda install ncbi-datasets-cli?**
<p>
<details>
<summary>Answer</summary>
It depends on how your local conda installation is configured. You might have already set it up to search conda-forge automatically; in which case this would still work. If not, conda might not be able to find the ncbi-datasets-cli package.
</details>
</p>

## Step Two: Querying the database

We'll start with the `datasets summary` command to just retrieve some basic information.

### Query the help menu

Before we can write our script, we know how to run the datasets CLI. To get some instructions on how to run it, start by just running the command `datasets` by itself.

<p>
<details>
<summary>Show output</summary>
<pre><code>datasets is a command-line tool that is used to query and download biological sequence data
across all domains of life from NCBI databases.

Refer to NCBI's [download and install](https://www.ncbi.nlm.nih.gov/datasets/docs/v2/download-and-install/) documentation for information about getting started with the command-line tools.

Usage
  datasets [command]

Data Retrieval Commands
  summary     Print a data report containing gene, genome, taxonomy or virus metadata
  download    Download a gene, genome or virus dataset as a zip file
  rehydrate   Rehydrate a downloaded, dehydrated dataset

Miscellaneous Commands
  completion  Generate autocompletion scripts

Flags
      --api-key string   Specify an NCBI API key
      --debug            Emit debugging info
      --help             Print detailed help about a datasets command
      --version          Print version of datasets

Use datasets \<command> --help for detailed help about a command.
</code></pre>
</details>
</p>

Since we're looking for summary information, we'll query further to get instructions for that.

<p>
<details>
<summary>Show command</summary>
<pre><code>datasets summary --help
</code></pre>
</details>
</p>

<p>
<details>
<summary>Show output</summary>
<pre><code>Print a data report containing gene, genome, taxonomy or virus metadata in JSON format.

Usage
  datasets summary [flags]
  datasets summary [command]

Sample Commands
  datasets summary genome accession GCF_000001405.40
  datasets summary genome taxon "mus musculus"
  datasets summary gene gene-id 672
  datasets summary gene symbol brca1 --taxon "mus musculus"
  datasets summary gene accession NP_000483.3
  datasets summary taxonomy taxon "mus musculus"
  datasets summary virus genome accession NC_045512.2
  datasets summary virus genome taxon sars-cov-2 --host dog

Available Commands
  gene        Print a summary of a gene dataset
  genome      Print a data report containing genome metadata
  virus       Print a data report containing virus genome metadata
  taxonomy    Print a data report containing taxonomy metadata

Global Flags
      --api-key string   Specify an NCBI API key
      --debug            Emit debugging info
      --help             Print detailed help about a datasets command
      --version          Print version of datasets

Use datasets summary \<command> --help for detailed help about a command.
</code></pre>
</details>
</p>

Let's go ahead and get further instructions for how to get summary information about a genome:

<p>
<details>
<summary>Show command</summary>
<pre><code>datasets summary genome --help
</code></pre>
</details>
</p>

<p>
<details>
<summary>Show output</summary>
<pre><code>Print a data report containing genome metadata. The data report is returned in JSON format.

Usage
  datasets summary genome [flags]
  datasets summary genome [command]

Sample Commands
  datasets summary genome accession GCF_000001405.40
  datasets summary genome taxon "mus musculus"
  datasets summary genome taxon human --assembly-level chromosome,complete
  datasets summary genome taxon "mus musculus" --search C57BL/6J --search "Broad Institute"

Available Commands
  accession   Print a data report containing assembled genome metadata by Assembly or BioProject accession
  taxon       Print a data report containing genome metadata by taxon (NCBI Taxonomy ID, scientific or common name at any tax rank)

Flags
      --annotated                 Limit to annotated genomes
      --as-json-lines             Output results in JSON Lines format
      --assembly-level string     Limit to genomes at one or more assembly levels (comma-separated):
                                    * chromosome
                                    * complete
                                    * contig
                                    * scaffold
                                     (default "[]")
      --assembly-source string    Limit to 'RefSeq' (GCF_) or 'GenBank' (GCA_) genomes (default "all")
      --assembly-version string   Limit to 'latest' assembly accession version or include 'all' (latest + previous versions)
      --exclude-atypical          Exclude atypical assemblies
      --exclude-multi-isolate     Exclude assemblies from multi-isolate projects
      --from-type                 Only return records with type material
      --limit string              Limit the number of genome summaries returned
                                    * all:      returns all matching genome summaries
                                    * a number: returns the specified number of matching genome summaries
                                       (default "all")
      --mag string                Limit to metagenome assembled genomes (only) or remove them from the results (exclude) (default "all")
      --reference                 Limit to reference genomes
      --released-after string     Limit to genomes released on or after a specified date (free format, ISO 8601 YYYY-MM-DD recommended)
      --released-before string    Limit to genomes released on or before a specified date (free format, ISO 8601 YYYY-MM-DD recommended)
      --report string             Choose the output type:
                                    * genome:   Retrieve the primary genome report
                                    * sequence: Retrieve the sequence report
                                    * ids_only: Retrieve only the genome identifiers
                                     (default "genome")
      --search strings            Limit results to genomes with specified text in the searchable fields:
                                  species and infraspecies, assembly name and submitter.
                                  To search multiple strings, use the flag multiple times.


Global Flags
      --api-key string   Specify an NCBI API key
      --debug            Emit debugging info
      --help             Print detailed help about a datasets command
      --version          Print version of datasets

Use datasets summary genome \<command> --help for detailed help about a command.
</code></pre>
</details>
</p>

### Get summary information about a genome

For the purposes of this demonstration, let's use the reference genome assembly for *E. coli* DH5alpha, a common laboratory strain of *E. coli* used for transformations and plasmid propagation.

Let's start by looking at the webpage for this genome: [Escherichia coli strain DH5alpha chromosome, complete genome](https://www.ncbi.nlm.nih.gov/nuccore/CP026085)

**Question: This page lists the accession number for this record as "CP026085.1". Can we use that accession number with the datasets cli?**

<p>
<details>
<summary>Answer</summary>

No, this accession number won't work with NCBI datasets; it's the accession for the whole genome and all of its associated genbank records, but `datasets summary genome accession` expects the accession number for the genome assembly. If you try:

<pre><code>datasets summary genome accession CP026085.1
</code></pre>

You will get the following error message:

<pre><code>Error: invalid or unsupported assembly accession: CP026085.1

Use datasets summary genome accession \<command> --help for detailed help about a command.
</code></pre>

The genome assembly accession number that datasets is looking for will always start with GCF (for RefSeq curated reference genomes) or GCA (for all other assemblies).

</details>
</p>

To get the genome assembly acccession number, let's navigate to the ["Assembly" page](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_002899475.1/).

Its Refseq accession number is GCF_002899475.1; or we could also use the original GenBank assembly accession number, GCA_002899475.1.

Let's go ahead and get some summary information from datasets about this genome using one of these accession numbers.

<p>
<details>
<summary>Show command</summary>
<pre><code>datasets summary genome accession GCF_002899475.1
</code></pre>
</details>
</p>

<p>
<details>
<summary>Show output</summary>
<pre><code>{"reports": [{"accession":"GCF_002899475.1","annotation_info":{"method":"Best-placed reference protein set; GeneMarkS-2+","name":"GCF_002899475.1-RS_2025_06_21","pipeline":"NCBI Prokaryotic Genome Annotation Pipeline (PGAP)","provider":"NCBI RefSeq","release_date":"2025-06-21","software_version":"6.10","stats":{"gene_counts":{"non_coding":123,"protein_coding":4444,"pseudogene":143,"total":4710}}},"assembly_info":{"assembly_level":"Complete Genome","assembly_method":"AllPaths v. Falcon (v0.3.0)","assembly_name":"ASM289947v1","assembly_status":"current","assembly_type":"haploid","bioproject_accession":"PRJNA429943","bioproject_lineage":[{"bioprojects":[{"accession":"PRJNA429943","title":"Escherichia coli strain:DH5alpha Genome sequencing"}]}],"biosample":{"accession":"SAMN08362704","attributes":[{"name":"strain","value":"DH5alpha"},{"name":"collection_date","value":"2016-09-20"},{"name":"env_broad_scale","value":"industrial"},{"name":"env_local_scale","value":"acidification of an aquatic environment"},{"name":"env_medium","value":"water"},{"name":"geo_loc_name","value":"China: Peking"},{"name":"isol_growth_condt","value":"LB medium"},{"name":"lat_lon","value":"39.54 N 116.23 E"},{"name":"num_replicons","value":"Unknown"},{"name":"ref_biomaterial","value":"NO"}],"collection_date":"2016-09-20","description":{"comment":"Keywords: GSC:MIxS;MIGS:6.0","organism":{"organism_name":"Escherichia coli","tax_id":562},"title":"MIGS Cultured Bacterial/Archaeal sample from Escherichia coli"},"geo_loc_name":"China: Peking","last_updated":"2021-02-28T05:23:06.723","lat_lon":"39.54 N 116.23 E","models":["MIGS.ba","MIGS/MIMS/MIMARKS.miscellaneous"],"owner":{"contacts":[{}],"name":"Henan Nornal University"},"package":"MIGS.ba.miscellaneous.6.0","publication_date":"2018-01-14T00:00:00.000","sample_ids":[{"label":"Sample name","value":"Escherichia coli"}],"status":{"status":"live","when":"2018-01-14T06:05:04.597"},"strain":"DH5alpha","submission_date":"2018-01-14T06:05:04.596"},"comments":"The annotation was added by the NCBI Prokaryotic Genome Annotation Pipeline (PGAP). Information about PGAP can be found here: https://www.ncbi.nlm.nih.gov/genome/annotation_prok/","paired_assembly":{"accession":"GCA_002899475.1","annotation_name":"NCBI Prokaryotic Genome Annotation Pipeline (PGAP)","status":"current"},"release_date":"2018-01-25","sequencing_tech":"PacBio","submitter":"Henan Nornal University"},"assembly_stats":{"atgc_count":"4833062","contig_l50":1,"contig_n50":4833062,"gc_count":"2452920","gc_percent":51,"genome_coverage":"4.83306e+06","number_of_component_sequences":1,"number_of_contigs":1,"number_of_scaffolds":1,"scaffold_l50":1,"scaffold_n50":4833062,"total_number_of_chromosomes":1,"total_sequence_length":"4833062","total_ungapped_length":"4833062"},"average_nucleotide_identity":{"best_ani_match":{"ani":99.22,"assembly":"GCA_000010385.1","assembly_coverage":92.12,"category":"claderef","organism_name":"Escherichia coli","type_assembly_coverage":86.35},"category":"category_na","comment":"na","match_status":"species_match","submitted_ani_match":{"ani":99.22,"assembly":"GCA_000010385.1","assembly_coverage":92.12,"category":"claderef","organism_name":"Escherichia coli SE11","type_assembly_coverage":86.35},"submitted_organism":"Escherichia coli","submitted_species":"Escherichia coli","taxonomy_check_status":"OK"},"checkm_info":{"checkm_marker_set":"Escherichia coli","checkm_marker_set_rank":"species","checkm_species_tax_id":562,"checkm_version":"v1.2.3","completeness":99.37,"completeness_percentile":79.7309,"contamination":0.25},"current_accession":"GCF_002899475.1","organism":{"infraspecific_names":{"strain":"DH5alpha"},"organism_name":"Escherichia coli","tax_id":562},"paired_accession":"GCA_002899475.1","source_database":"SOURCE_DATABASE_REFSEQ"}],"total_count": 1}
</code></pre>
</details>
</p>

The output is a bunch of data in [JSON format](https://www.w3schools.com/js/js_json_syntax.asp).

> If you know python or other coding languages, you'll recognize that this format is similar to a "dictionary"; it stores data in key:value pairs or lists of items. In fact, there's a standard [python library](https://docs.python.org/3/library/json.html) for working with JSON-formatted data and files.

### What if we didn't already know the accession number for our data?

We can use ncbi datasets to find the accession number for the assembly we're interested in by using its other option, `taxon`. Try it yourself:

<p>
<details>
<summary>Show command</summary>
<pre><code>datasets summary genome taxon "Escherichia coli DH5alpha"
</code></pre>
</details>
</p>

<p>
<details>
<summary>Show output</summary>
<pre><code>{"reports": [{"accession":"GCF_000982435.1","annotation_info":{"method":"Best-placed reference protein set; GeneMarkS-2+","name":"GCF_000982435.1-RS_2025_06_15","pipeline":"NCBI Prokaryotic Genome Annotation Pipeline (PGAP)","provider":"NCBI RefSeq","release_date":"2025-06-15","software_version":"6.10","stats":{"gene_counts":{"non_coding":92,"protein_coding":4159,"pseudogene":186,"total":4437}}},"assembly_info":{"assembly_level":"Contig","assembly_method":"CLC NGS Cell v. 6.5","assembly_name":"ASM98243v1","assembly_status":"current","assembly_type":"haploid","bioproject_accession":"PRJNA263864","bioproject_lineage":[{"bioprojects":[{"accession":"PRJNA263864","title":"Escherichia coli DH5[alpha] strain:DH5alpha Genome sequencing and assembly"}]}],"biosample":{"accession":"SAMN03107817","attributes":[{"name":"strain","value":"DH5alpha"},{"name":"collection_date","value":"2013-03-20"},{"name":"geo_loc_name","value":"South Korea: Jinju"},{"name":"isolation_source","value":"common laboratory strain"},{"name":"sample_type","value":"missing"}],"collection_date":"2013-03-20","description":{"organism":{"organism_name":"Escherichia coli DH5[alpha]","tax_id":668369},"title":"Microbe sample from Escherichia coli DH5[alpha]"},"geo_loc_name":"South Korea: Jinju","isolation_source":"common laboratory strain","last_updated":"2021-02-28T02:28:40.766","models":["Microbe, viral or environmental"],"owner":{"contacts":[{}],"name":"Korea Advanced Institute of Science and Technology"},"package":"Microbe.1.0","publication_date":"2015-04-17T00:00:00.000","sample_ids":[{"label":"Sample name","value":"Escherichia coli DH5alpha"}],"status":{"status":"live","when":"2015-04-17T06:56:10.200"},"strain":"DH5alpha","submission_date":"2014-10-15T05:40:46.483"},"paired_assembly":{"accession":"GCA_000982435.1","status":"current"},"release_date":"2015-04-09","sequencing_tech":"Illumina MiSeq","submitter":"Korea Advanced Institute of Science and Technology"},"assembly_stats":{"atgc_count":"4507030","contig_l50":11,"contig_n50":132511,"gc_count":"2286777","gc_percent":50.5,"genome_coverage":"594","number_of_component_sequences":89,"number_of_contigs":89,"number_of_scaffolds":89,"scaffold_l50":11,"scaffold_n50":132511,"total_sequence_length":"4507030","total_ungapped_length":"4507030"},"average_nucleotide_identity":{"best_ani_match":{"ani":99.44,"assembly":"GCA_000210475.1","assembly_coverage":94.64,"category":"claderef","organism_name":"Escherichia coli","type_assembly_coverage":80.09},"category":"category_na","comment":"na","match_status":"species_match","submitted_ani_match":{"ani":99.44,"assembly":"GCA_000210475.1","assembly_coverage":94.64,"category":"claderef","organism_name":"Escherichia coli ETEC H10407","type_assembly_coverage":80.09},"submitted_organism":"Escherichia coli DH5[alpha]","submitted_species":"Escherichia coli","taxonomy_check_status":"OK"},"checkm_info":{"checkm_marker_set":"Escherichia coli","checkm_marker_set_rank":"species","checkm_species_tax_id":562,"checkm_version":"v1.2.3","completeness":98.49,"completeness_percentile":22.4983,"contamination":0.15},"current_accession":"GCF_000982435.1","organism":{"infraspecific_names":{"strain":"DH5alpha"},"organism_name":"Escherichia coli DH5[alpha]","tax_id":668369},"paired_accession":"GCA_000982435.1","source_database":"SOURCE_DATABASE_REFSEQ","wgs_info":{"master_wgs_url":"https://www.ncbi.nlm.nih.gov/nuccore/JRYM00000000.1","wgs_contigs_url":"https://www.ncbi.nlm.nih.gov/Traces/wgs/JRYM01","wgs_project_accession":"JRYM01"}},{"accession":"GCA_000982435.1","assembly_info":{"assembly_level":"Contig","assembly_method":"CLC NGS Cell v. 6.5","assembly_name":"ASM98243v1","assembly_status":"current","assembly_type":"haploid","bioproject_accession":"PRJNA263864","bioproject_lineage":[{"bioprojects":[{"accession":"PRJNA263864","title":"Escherichia coli DH5[alpha] strain:DH5alpha Genome sequencing and assembly"}]}],"biosample":{"accession":"SAMN03107817","attributes":[{"name":"strain","value":"DH5alpha"},{"name":"collection_date","value":"2013-03-20"},{"name":"geo_loc_name","value":"South Korea: Jinju"},{"name":"isolation_source","value":"common laboratory strain"},{"name":"sample_type","value":"missing"}],"collection_date":"2013-03-20","description":{"organism":{"organism_name":"Escherichia coli DH5[alpha]","tax_id":668369},"title":"Microbe sample from Escherichia coli DH5[alpha]"},"geo_loc_name":"South Korea: Jinju","isolation_source":"common laboratory strain","last_updated":"2021-02-28T02:28:40.766","models":["Microbe, viral or environmental"],"owner":{"contacts":[{}],"name":"Korea Advanced Institute of Science and Technology"},"package":"Microbe.1.0","publication_date":"2015-04-17T00:00:00.000","sample_ids":[{"label":"Sample name","value":"Escherichia coli DH5alpha"}],"status":{"status":"live","when":"2015-04-17T06:56:10.200"},"strain":"DH5alpha","submission_date":"2014-10-15T05:40:46.483"},"paired_assembly":{"accession":"GCF_000982435.1","annotation_name":"GCF_000982435.1-RS_2025_06_15","status":"current"},"release_date":"2015-04-09","sequencing_tech":"Illumina MiSeq","submitter":"Korea Advanced Institute of Science and Technology"},"assembly_stats":{"atgc_count":"4507030","contig_l50":11,"contig_n50":132511,"gc_count":"2286777","gc_percent":50.5,"genome_coverage":"594","number_of_component_sequences":89,"number_of_contigs":89,"number_of_scaffolds":89,"scaffold_l50":11,"scaffold_n50":132511,"total_sequence_length":"4507030","total_ungapped_length":"4507030"},"average_nucleotide_identity":{"best_ani_match":{"ani":99.44,"assembly":"GCA_000210475.1","assembly_coverage":94.64,"category":"claderef","organism_name":"Escherichia coli","type_assembly_coverage":80.09},"category":"category_na","comment":"na","match_status":"species_match","submitted_ani_match":{"ani":99.44,"assembly":"GCA_000210475.1","assembly_coverage":94.64,"category":"claderef","organism_name":"Escherichia coli ETEC H10407","type_assembly_coverage":80.09},"submitted_organism":"Escherichia coli DH5[alpha]","submitted_species":"Escherichia coli","taxonomy_check_status":"OK"},"checkm_info":{"checkm_marker_set":"Escherichia coli","checkm_marker_set_rank":"species","checkm_species_tax_id":562,"checkm_version":"v1.2.3","completeness":98.49,"completeness_percentile":22.4983,"contamination":0.15},"current_accession":"GCA_000982435.1","organism":{"infraspecific_names":{"strain":"DH5alpha"},"organism_name":"Escherichia coli DH5[alpha]","tax_id":668369},"paired_accession":"GCF_000982435.1","source_database":"SOURCE_DATABASE_GENBANK","wgs_info":{"master_wgs_url":"https://www.ncbi.nlm.nih.gov/nuccore/JRYM00000000.1","wgs_contigs_url":"https://www.ncbi.nlm.nih.gov/Traces/wgs/JRYM01","wgs_project_accession":"JRYM01"}}],"total_count": 2}
</code></pre>
</details>
</p>

**Question: Why did we put quotation marks around our search term, "Escherichia coli DH5alpha"?**

<p>
<details>
<summary>Answer</summary>
This allows us to include multiple words in the search term without bash treating them as separate arguments and getting confused. If we don't use the quotation marks, it performs a separate search for each word and gives us a bunch of stuff we're not looking for!
</details>
</p>


**Question: What's different about the results of this command vs our previous command which just used the accession number?**
<p>
<details>
<summary>Answer</summary>
Our last command gave us a single report, but this one gives us a list of two reports, one for each accession number that this genome assembly has.
</details>
</p>

**Question: Where can we find the accession number in this report?**

<p>
<details>
<summary>Answer</summary>
The accession number is at the very beginning of the report, under "accession".
</details>
</p>

## Step Three: Extracting specific information from the summary report

Let's go back to using `datasets summary genome accession` so we can work with only one report. What if we want to extract information from this report during our script? For example, we might want to use the species name instead of the accession number for our file name.

### Take a closer look at the report data

We'll start by getting a better view of the data. The accession number is relatively easy to spot because it's the first item in the report. But what about the content in the middle?

We will use the other command line utility I had you install with conda in the first step: [jq](https://www.baeldung.com/linux/jq-command-json). jq is a powerful utility for working with JSON-formatted data on the command line in bash.

The simplest thing we can do is reprint our data in a nicer format. The command for this is `jq .`. Try piping the output of datasets summary to this command:

<p>
<details>
<summary>Show command</summary>
<pre><code>datasets summary genome accession GCF_002899475.1 | jq .
</code></pre>
</details>
</p>

<p>
<details>
<summary>Show output</summary>
<pre><code>{
  "reports": [
    {
      "accession": "GCF_002899475.1",
      "annotation_info": {
        "method": "Best-placed reference protein set; GeneMarkS-2+",
        "name": "GCF_002899475.1-RS_2025_06_21",
        "pipeline": "NCBI Prokaryotic Genome Annotation Pipeline (PGAP)",
        "provider": "NCBI RefSeq",
        "release_date": "2025-06-21",
        "software_version": "6.10",
        "stats": {
          "gene_counts": {
            "non_coding": 123,
            "protein_coding": 4444,
            "pseudogene": 143,
            "total": 4710
          }
        }
      },
      "assembly_info": {
        "assembly_level": "Complete Genome",
        "assembly_method": "AllPaths v. Falcon (v0.3.0)",
        "assembly_name": "ASM289947v1",
        "assembly_status": "current",
        "assembly_type": "haploid",
        "bioproject_accession": "PRJNA429943",
        "bioproject_lineage": [
          {
            "bioprojects": [
              {
                "accession": "PRJNA429943",
                "title": "Escherichia coli strain:DH5alpha Genome sequencing"
              }
            ]
          }
        ],
        "biosample": {
          "accession": "SAMN08362704",
          "attributes": [
            {
              "name": "strain",
              "value": "DH5alpha"
            },
            {
              "name": "collection_date",
              "value": "2016-09-20"
            },
            {
              "name": "env_broad_scale",
              "value": "industrial"
            },
            {
              "name": "env_local_scale",
              "value": "acidification of an aquatic environment"
            },
            {
              "name": "env_medium",
              "value": "water"
            },
            {
              "name": "geo_loc_name",
              "value": "China: Peking"
            },
            {
              "name": "isol_growth_condt",
              "value": "LB medium"
            },
            {
              "name": "lat_lon",
              "value": "39.54 N 116.23 E"
            },
            {
              "name": "num_replicons",
              "value": "Unknown"
            },
            {
              "name": "ref_biomaterial",
              "value": "NO"
            }
          ],
          "collection_date": "2016-09-20",
          "description": {
            "comment": "Keywords: GSC:MIxS;MIGS:6.0",
            "organism": {
              "organism_name": "Escherichia coli",
              "tax_id": 562
            },
            "title": "MIGS Cultured Bacterial/Archaeal sample from Escherichia coli"
          },
          "geo_loc_name": "China: Peking",
          "last_updated": "2021-02-28T05:23:06.723",
          "lat_lon": "39.54 N 116.23 E",
          "models": [
            "MIGS.ba",
            "MIGS/MIMS/MIMARKS.miscellaneous"
          ],
          "owner": {
            "contacts": [
              {}
            ],
            "name": "Henan Nornal University"
          },
          "package": "MIGS.ba.miscellaneous.6.0",
          "publication_date": "2018-01-14T00:00:00.000",
          "sample_ids": [
            {
              "label": "Sample name",
              "value": "Escherichia coli"
            }
          ],
          "status": {
            "status": "live",
            "when": "2018-01-14T06:05:04.597"
          },
          "strain": "DH5alpha",
          "submission_date": "2018-01-14T06:05:04.596"
        },
        "comments": "The annotation was added by the NCBI Prokaryotic Genome Annotation Pipeline (PGAP). Information about PGAP can be found here: https://www.ncbi.nlm.nih.gov/genome/annotation_prok/",
        "paired_assembly": {
          "accession": "GCA_002899475.1",
          "annotation_name": "NCBI Prokaryotic Genome Annotation Pipeline (PGAP)",
          "status": "current"
        },
        "release_date": "2018-01-25",
        "sequencing_tech": "PacBio",
        "submitter": "Henan Nornal University"
      },
      "assembly_stats": {
        "atgc_count": "4833062",
        "contig_l50": 1,
        "contig_n50": 4833062,
        "gc_count": "2452920",
        "gc_percent": 51,
        "genome_coverage": "4.83306e+06",
        "number_of_component_sequences": 1,
        "number_of_contigs": 1,
        "number_of_scaffolds": 1,
        "scaffold_l50": 1,
        "scaffold_n50": 4833062,
        "total_number_of_chromosomes": 1,
        "total_sequence_length": "4833062",
        "total_ungapped_length": "4833062"
      },
      "average_nucleotide_identity": {
        "best_ani_match": {
          "ani": 99.22,
          "assembly": "GCA_000010385.1",
          "assembly_coverage": 92.12,
          "category": "claderef",
          "organism_name": "Escherichia coli",
          "type_assembly_coverage": 86.35
        },
        "category": "category_na",
        "comment": "na",
        "match_status": "species_match",
        "submitted_ani_match": {
          "ani": 99.22,
          "assembly": "GCA_000010385.1",
          "assembly_coverage": 92.12,
          "category": "claderef",
          "organism_name": "Escherichia coli SE11",
          "type_assembly_coverage": 86.35
        },
        "submitted_organism": "Escherichia coli",
        "submitted_species": "Escherichia coli",
        "taxonomy_check_status": "OK"
      },
      "checkm_info": {
        "checkm_marker_set": "Escherichia coli",
        "checkm_marker_set_rank": "species",
        "checkm_species_tax_id": 562,
        "checkm_version": "v1.2.3",
        "completeness": 99.37,
        "completeness_percentile": 79.7309,
        "contamination": 0.25
      },
      "current_accession": "GCF_002899475.1",
      "organism": {
        "infraspecific_names": {
          "strain": "DH5alpha"
        },
        "organism_name": "Escherichia coli",
        "tax_id": 562
      },
      "paired_accession": "GCA_002899475.1",
      "source_database": "SOURCE_DATABASE_REFSEQ"
    }
  ],
  "total_count": 1
}
</code></pre>
</details>
</p>

When it's formatted like this, it's easier to see some statistics about the assembly and how complete it is; and other information like who submitted it to genbank. We can also see the field we're looking for: "organism_name", which is under "organism". 

But how do we extract the value for "organism_name" automatically? Just because we can easily see it now doesn't mean the computer can easily retrieve it.

We can use .jq to retrieve this information, but in order to navigate to it, we have to go from the outside in. Looking at the output above, what is the first "key" in this json data that we have to go through to before we can get to the organism_name? If you're not sure, we can find it using another jq function, `jq keys`:

<p>
<details>
<summary>Show command</summary>
<pre><code>datasets summary genome accession GCF_002899475.1 | jq keys
</code></pre>
</details>
</p>

<p>
<details>
<summary>Show output</summary>

<pre><code>[
  "reports",
  "total_count"
]
</code></pre>
</details>
</p>

<p>
<details>
<summary>Answer</summary>
The first key we have to get through is "reports", which stores a list of reports! The report we're interested in is the first (and only) report in this list.
</details>
</p>

Let's use jq to get just the report we're looking for, instead of the whole printout of datasets summary. To get the features under a particular key in jq, you can use ".key" at the argument for it.

So, to get the list of reports, we would use the command
```
datasets summary genome accession GCF_002899475.1 | jq .reports
```

To get the first report in that list, we should access the report by its index. jq is 0-based, meaning it starts counting at 0 instead of 1, so to get the first report, our command would look like this:
```
datasets summary genome accession GCF_002899475.1 | jq .reports[0]
```

What if we wanted to see the list of keys in this report? We could pipe the output of this command to another call on jq:

<p>
<details>
<summary>Show command</summary>
<pre><code>datasets summary genome accession GCF_002899475.1 | jq .reports[0] | jq keys
</code></pre>
</details>
</p>

<p>
<details>
<summary>Show output</summary>
<pre><code>[
  "accession",
  "annotation_info",
  "assembly_info",
  "assembly_stats",
  "average_nucleotide_identity",
  "checkm_info",
  "current_accession",
  "organism",
  "paired_accession",
  "source_database"
]
</code></pre>
</details>
</p>

The key we're looking for is "organism_name", under "organism". Can you build out the full jq command to get the organism_name for this accession from ncbi using datasets summary?

<p>
<details>
<summary>Show command</summary>
<pre><code>datasets summary genome accession GCF_002899475.1 | jq .reports[0].organism.organism_name
</code></pre>
</details>
</p>

<p>
<details>
<summary>Show output</summary>
<pre><code>"Escherichia coli"
</code></pre>
</details>
</p>

Great! This tells us that GCF_002899475.1 is an *E. coli* assembly. But what if we were working with a bunch of different *E. coli* genomes, and wanted to know the strain name? Build a command to get the strain name instead.

<p>
<details>
<summary>Show command</summary>
<pre><code>datasets summary genome accession GCF_002899475.1 | jq .reports[0].organism.infraspecific_names.strain
</code></pre>
</details>
</p>

<p>
<details>
<summary>Show output</summary>
<pre><code>"DH5alpha"
</code></pre>
</details>
</p>

For our purposes, we probably don't want to have the quotation marks around the output. Looking at `jq --help`, can you find the flag we can add to tell jq to give us a raw string output instead of JSON format (which puts all strings in quotes)?

<p>
<details>
<summary>Answer</summary>
The <code>-r</code> flag tells jq to return the output as a raw string.
</details>
</p>

Finally, try using $() (command substitution) to store the organism_name and strain into bash variables that we can use later.

<p>
<details>
<summary>Show command</summary>
<pre><code>organism_name=$(datasets summary genome accession GCF_002899475.1 | jq .reports[0].organism.organism_name -r)
strain=$(datasets summary genome accession GCF_002899475.1 | jq .reports[0].organism.infraspecific_names.strain -r)
echo "${organism_name} ${strain}"
</code></pre>
</details>
</p>

## Step Four: Downloading files

Now, let's move on to actually downloading a genome file from ncbi.

### Query the help menu

Let's take a look at the download command in more detail using the suggested `--help` command.
<p>
<details>
<summary>Show command</summary>
<pre><code>datasets download --help
</code></pre>
</details>
</p>

<p>
<details>
<summary>Show output</summary>
<pre><code>Download genome, gene and virus data packages, including sequence, annotation, and metadata, as a zip file.

Refer to NCBI's [download and install](https://www.ncbi.nlm.nih.gov/datasets/docs/v2/download-and-install/) documentation for information about getting started with the command-line tools.

Usage
  datasets download [flags]
  datasets download [command]

Sample Commands
  datasets download genome accession GCF_000001405.40 --chromosomes X,Y --exclude-gff3 --exclude-rna
  datasets download genome taxon "bos taurus"
  datasets download gene gene-id 672
  datasets download gene symbol brca1 --taxon "mus musculus"
  datasets download gene accession NP_000483.3
  datasets download taxonomy taxon human,sars-cov-2
  datasets download virus genome taxon sars-cov-2 --host dog
  datasets download virus protein S --host dog --filename SARS2-spike-dog.zip

Available Commands
  gene        Download a gene data package
  genome      Download a genome data package
  taxonomy    Download a taxonomy data package
  virus       Download a virus data package

Flags
      --filename string   Specify a custom file name for the downloaded data package (default "ncbi_dataset.zip")
      --no-progressbar    Hide progress bar


Global Flags
      --api-key string   Specify an NCBI API key
      --debug            Emit debugging info
      --help             Print detailed help about a datasets command
      --version          Print version of datasets

Use datasets download \<command> --help for detailed help about a command.
</code></pre>
</details>
</p>

Since we're looking to download a genome, we'll query further to get instructions for that.

<p>
<details>
<summary>Show command</summary>
<pre><code>datasets download genome --help
</code></pre>
</details>
</p>

<p>
<details>
<summary>Show output</summary>
<pre><code>Download a genome data package. Genome data packages may include genome, transcript and protein sequences, annotation and one or more data reports. Data packages are downloaded as a zip archive.

The default genome data package includes the following files:
  * \<accession>_\<assembly_name>_genomic.fna (genomic sequences)
  * assembly_data_report.jsonl (data report with genome assembly and annotation metadata)
  * dataset_catalog.json (a list of files and file types included in the data package)

Usage
  datasets download genome [flags]
  datasets download genome [command]

Sample Commands
  datasets download genome accession GCF_000001405.40 --chromosomes X,Y --include genome,gff3,rna
  datasets download genome taxon "bos taurus" --dehydrated
  datasets download genome taxon human --assembly-level chromosome,complete --dehydrated
  datasets download genome taxon mouse --search C57BL/6J --search "Broad Institute" --dehydrated

Available Commands
  accession   Download a genome data package by Assembly or BioProject accession
  taxon       Download a genome data package by taxon (NCBI Taxonomy ID, scientific or common name at any tax rank)

Flags
      --annotated                 Limit to annotated genomes
      --assembly-level string     Limit to genomes at one or more assembly levels (comma-separated):
                                    * chromosome
                                    * complete
                                    * contig
                                    * scaffold
                                     (default "[]")
      --assembly-source string    Limit to 'RefSeq' (GCF_) or 'GenBank' (GCA_) genomes (default "all")
      --assembly-version string   Limit to 'latest' assembly accession version or include 'all' (latest + previous versions)
      --chromosomes strings       Limit to a specified, comma-delimited list of chromosomes, or 'all' for all chromosomes
      --dehydrated                Download a dehydrated zip archive including the data report and locations of data files (use the rehydrate command to retrieve data files).
      --exclude-atypical          Exclude atypical assemblies
      --exclude-multi-isolate     Exclude assemblies from multi-isolate projects
      --fast-zip-validation       Skip zip checksum validation after download
      --from-type                 Only return records with type material
      --include string(,string)   Specify the data files to include (comma-separated).
                                    * genome:     genomic sequence
                                    * rna:        transcript
                                    * protein:    amnio acid sequences
                                    * cds:        nucleotide coding sequences
                                    * gff3:       general feature file
                                    * gtf:        gene transfer format
                                    * gbff:       GenBank flat file
                                    * seq-report: sequence report file
                                    * none:       do not retrieve any sequence files
                                     (default [genome])
      --mag string                Limit to metagenome assembled genomes (only) or remove them from the results (exclude) (default "all")
      --preview                   Show information about the requested data package
      --reference                 Limit to reference genomes
      --released-after string     Limit to genomes released on or after a specified date (free format, ISO 8601 YYYY-MM-DD recommended)
      --released-before string    Limit to genomes released on or before a specified date (free format, ISO 8601 YYYY-MM-DD recommended)
      --search strings            Limit results to genomes with specified text in the searchable fields:
                                  species and infraspecies, assembly name and submitter.
                                  To search multiple strings, use the flag multiple times.


Global Flags
      --api-key string    Specify an NCBI API key
      --debug             Emit debugging info
      --filename string   Specify a custom file name for the downloaded data package (default "ncbi_dataset.zip")
      --help              Print detailed help about a datasets command
      --no-progressbar    Hide progress bar
      --version           Print version of datasets

Use datasets download genome \<command> --help for detailed help about a command.
</code></pre>
</details>
</p>

And just to be thorough, let's get some further details about downloading a genome by its accession number:

<p>
<details>
<summary>Show command</summary>
<pre><code>datasets download genome accession --help
</code></pre>
</details>
</p>

<p>
<details>
<summary>Show output</summary>
<pre><code>Download a genome data package by Assembly or BioProject accession. Genome data packages may include assembled genome, transcript and protein sequences, annotation and one or more data reports. Data packages are downloaded as a zip archive.

The default genome data package includes the following files:
  * \<accession>_\<assembly_name>_genomic.fna (genomic sequences)
  * assembly_data_report.jsonl (data report with genome assembly and annotation metadata)
  * dataset_catalog.json (a list of files and file types included in the data package)

Usage
  datasets download genome accession \<accession ...> [flags]

Sample Commands
  datasets download genome accession GCF_000001405.40 --chromosomes X,Y --include protein,cds
  datasets download genome accession GCA_003774525.2 GCA_000001635 --chromosomes X,Y,Un.9
  datasets download genome accession GCA_003774525.2 --preview
  datasets download genome accession PRJNA289059 --include none

Flags
      --inputfile string   Read a list of NCBI Assembly or BioProject accessions from a file to use as input


Global Flags
      --annotated                 Limit to annotated genomes
      --api-key string            Specify an NCBI API key
      --assembly-level string     Limit to genomes at one or more assembly levels (comma-separated):
                                    * chromosome
                                    * complete
                                    * contig
                                    * scaffold
                                     (default "[]")
      --assembly-source string    Limit to 'RefSeq' (GCF_) or 'GenBank' (GCA_) genomes (default "all")
      --assembly-version string   Limit to 'latest' assembly accession version or include 'all' (latest + previous versions)
      --chromosomes strings       Limit to a specified, comma-delimited list of chromosomes, or 'all' for all chromosomes
      --debug                     Emit debugging info
      --dehydrated                Download a dehydrated zip archive including the data report and locations of data files (use the rehydrate command to retrieve data files).
      --exclude-atypical          Exclude atypical assemblies
      --exclude-multi-isolate     Exclude assemblies from multi-isolate projects
      --fast-zip-validation       Skip zip checksum validation after download
      --filename string           Specify a custom file name for the downloaded data package (default "ncbi_dataset.zip")
      --from-type                 Only return records with type material
      --help                      Print detailed help about a datasets command
      --include string(,string)   Specify the data files to include (comma-separated).
                                    * genome:     genomic sequence
                                    * rna:        transcript
                                    * protein:    amnio acid sequences
                                    * cds:        nucleotide coding sequences
                                    * gff3:       general feature file
                                    * gtf:        gene transfer format
                                    * gbff:       GenBank flat file
                                    * seq-report: sequence report file
                                    * none:       do not retrieve any sequence files
                                     (default [genome])
      --mag string                Limit to metagenome assembled genomes (only) or remove them from the results (exclude) (default "all")
      --no-progressbar            Hide progress bar
      --preview                   Show information about the requested data package
      --reference                 Limit to reference genomes
      --released-after string     Limit to genomes released on or after a specified date (free format, ISO 8601 YYYY-MM-DD recommended)
      --released-before string    Limit to genomes released on or before a specified date (free format, ISO 8601 YYYY-MM-DD recommended)
      --search strings            Limit results to genomes with specified text in the searchable fields:
                                  species and infraspecies, assembly name and submitter.
                                  To search multiple strings, use the flag multiple times.
      --version                   Print version of datasets
</code></pre>
</details>
</p>

**Question: the script we'll be building will only download the genome fasta file. But what flag would we include if we wanted to download the gff3 annotation of the genome as well?**
<p>
<details>
<summary>Answer</summary>
We would add the <code>--include</code> flag to specify which sequence files to download. By default, datasets only downloads the genome file, but we could give the command <code>--include genome,gff3</code> to get the gff3 annotation as well.
</details>
</p>

### Try downloading a test genome

Let's download the *E. coli* Dh5alpha genome from earlier.

First, let's make a fresh directory and cd into it so we can see exactly what the command downloads for us:
```
mdkir test
cd test
```

Now, let's download the genome:

<p>
<details>
<summary>Show command</summary>
<pre><code>datasets download genome accession GCF_002899475.1
</code></pre>
</details>
</p>

<p>
<details>
<summary>Show output</summary>
<pre><code>Collecting 1 genome record [================================================] 100% 1/1
Downloading: ncbi_dataset.zip    1.44MB valid data package
Validating package files [================================================] 100% 5/5
</code></pre>

</details>
</p>

Use the `ls` command to see what's in the directory after downloading it.
<p>
<details>
<summary>Show output</summary>
<pre><code>ncbi_dataset.zip
</code></pre>
</details>
</p>

**Question: the name of the downloaded folder is ncbi_dataset. Why might this pose a problem for a script that downloads multiple genomes by their accesssion numbers?**
<p>
<details>
<summary>Answer</summary>
Because the name of the folder isn't unique or dependent on the genome inside of it, we may create conflicts or ambiguities if we try to download multiple genomes with this method in the same directory.
</details>
</p>

**Question: the data folder is downloaded as a zip file. Which basic linux command should we use to unzip it?**

<p>
<details>
<summary>Answer</summary>

Linux has two utilities that you will commonly see for unzipping compressed files: <code>unzip</code> and <code>gunzip</code>. You will use both of these often in bioinformatics.

The <code>.zip</code> file extension is a clue that we should use <code>unzip</code>; if the extension were <code>.gz</code>, we would use <code>gunzip</code>.
</details>
</p>

Let's go ahead and unzip the downloaded folder and take a look around:

<p>
<details>
<summary>Show command</summary>

(Enter these commands one line at a time)

<pre><code>unzip ncbi_dataset.zip
ls
ls ncbi_dataset
ls ncbi_dataset/data
ls ncbi_dataset/data/GCF_002899475.1
</code></pre>
</details>
</p>

**Question: where is the genomic fasta file we were trying to download?**
<p>
<details>
<summary>Answer</summary>
The file is located at <code>ncbi_dataset/data/GCF_002899475.1/GCF_002899475.1_ASM289947v1_genomic.fna</code>
</details>
</p>

**Question: what is the purpose of the md5sum.txt file?**

<p>
<details>
<summary>Answer</summary>

The purpose of this file is to allow you to verify for yourself that everything downloaded smoothly. It's possible for interruptions in your internet connection to lead to a corrupted or truncated file download, which would leave you with an incorrect genome download! The md5sum.txt file lets you verify later on that the data is all correct.

See also: https://www.ncbi.nlm.nih.gov/datasets/docs/v2/how-tos/validation/

When using ncbi datasets, this check isn't strictly necessary, because the datasets cli performs a validation step automatically. But it's still a good idea to use the md5sum to verify your data when you're downloading files with other methods.
</details>
</p>

**Question: what is in the `dataset_catalog.json` file?**

<p>
<details>
<summary>Answer</summary>

This file contains information about the different files you requested and where they're stored. This could be really useful if you requested many different types of data!
</details>
</p>

**Question: what is in the `assembly_data_report.jsonl` file?**

<p>
<details>
<summary>Answer</summary>
This is the summary report we saw earlier, the one that we would get for this accession number if we were using <code>datasets summary</code>! This lets us get all of that information about the genome we're downloading without having to query the database again.
</details>
</p>

Try getting the organism_name and strain out of the assembly_data_report.jsonl file!

Hint: the key names and formatting of this file is a little different than in the previous excercise, so you may need to take a look with `jq .` again first.

<p>
<details>
<summary>Answer</summary>
<pre><code>organism_name=$(jq .organism.organismName -r ncbi_dataset/data/assembly_data_report.jsonl)
strain=$(jq .organism.infraspecificNames.strain -r ncbi_dataset/data/assembly_data_report.jsonl)
echo "${organism_name} ${strain}"
</code></pre>
</details>
</p>


## Step Five: Validating the download

This step isn't strictly necessary because NCBI datasets automatically performs validation checks for you, but we'll do it anyways because it's a good idea when downloading data in general.

First, take a look at what is in the md5sum.txt file:
```
less md5sum.txt
```

It's a list of hash values and the corresponding files. [md5sum](https://www.geeksforgeeks.org/linux-unix/md5sum-linux-command/) calculates these values bashed on the contents of the file; you can't tell what's in the file from these values, but if two files have the same content, they will have the same hash value. Therefore, if any of the files got corrupted or truncated during the download, computing the md5sum will tell us there's something wrong with that file.

We can double check that the files downloaded correctly with this command:
```
md5sum -c md5sum.txt
```
Which tells md5sum to check the files specified in this txt file. The output should look like this:

```
ncbi_dataset/data/assembly_data_report.jsonl: OK
ncbi_dataset/data/GCF_002899475.1/GCF_002899475.1_ASM289947v1_genomic.fna: OK
ncbi_dataset/data/dataset_catalog.json: OK
```

### Use the output to check the download automatically

We can see everything looks fine by reading it, but what if we want to perform this check automatically? We need a way of catching in an if/else statement whether everything is OK: essentially, we need to transform this output into a boolean "True" or "False" value.

The second column of the output will say "OK" if the files are correct and "FAILED" if the files are incorrect. There are a lot of ways to get the second column of some output in bash, but one of the simplest is just by using awk to print the second column:

```
md5sum -c md5sum.txt | awk '{print $2}'
```

**Question: Why use ' ' instead of " " here?**

<p>
<details>
<summary>Answer</summary>
In bash, variables called with the <pre><code>$</code></pre> symbol inside of strings that are surrounded by <pre><code>" "</code></pre> quotes are replaced with their values, but variables called inside <pre><code>' '</code></pre> quotes are passed literally. You can test it like so:

<pre><code>echo '{print $2}'
echo "{print $2}"</code></pre>

<pre><code>{print $2}</code></pre> is the command awk needs to print column 2, so we have to put it inside single quotes to make sure the "$2" value is passed correctly.

</details>
</p>

Now we have a version of the output with the unique file names stripped out, that just says "OK OK OK". How do we then check automatically that every line in this output says OK?

We *could* just check that the output of this command is "OK OK OK". That would look something like this:

```
if  [[ $(md5sum -c md5sum.txt | awk '{print $2}') == $'OK\nOK\nOK' ]];
then echo "Everything is OK!"
fi
```

**Question: Why [[ ]]?**

<p>
<details>
<summary>Answer</summary>

The [[ ]] brackets surround a comparison in bash; this is how you will transform values and inequalities into a boolean "True" or "False" you can directly use.

</details>
</p>

**Question: Why `$'OK\nOK\nOK'`?**

<p>
<details>
<summary>Answer</summary>

This is one way to get a literal newline or enter character in bash; $'' strings can interpret certain escape characters whereas normal strings will just treat them literally. You can look at this [stack overflow post](https://stackoverflow.com/questions/3005963/how-can-i-have-a-newline-in-a-string-in-sh) for other alternative methods!

</details>
</p>

This approach works for our current download, but what if we wanted to download an additional file along with the genome, such as an annotation file? Then there would be more than three files, and the computer would respond incorrectly to this command, because "OK OK OK OK" is NOT the same as "OK OK OK". It would be better just to get a list of unique values for this second column; we can do this with the `uniq` command.

That would look something like this:
```
md5sum -c md5sum.txt | awk '{print $2}' | sort | uniq
```

Which just gives us "OK"! Then we can check if the value of all of the columns is "OK" like this:

```
if  [[ $(md5sum -c md5sum.txt | awk '{print $2}' | sort | uniq) == "OK" ]];
then echo "Everything is OK!"
fi
```

**Question: Why `| sort | uniq` instead of just `| uniq`?**

<p>
<details>
<summary>Answer</summary>

The bash command <code>uniq</code>< *expects* input to be sorted so it can give a proper output. If you give it unsorted input, it might give you output with some duplicated values, which isn't typically what you want when using the <code>uniq</code> command, so it's best to always <code>sort</code> the input first.

In this case though it doesn't matter! Since you're just using it to check if everything is "OK", just using <code>| uniq</code> by itself will give you the same True/False answer in the end.

</details>
</p>

## Step Six: Using the summary data to rename the genome file

Now that we've verified that all of the files downloaded correctly, let's extract the genomic fasta file and rename it based on the summary data.

Earlier, we used this command to get the organism name we wanted from NCBI datasets:

```
organism_name=$(datasets summary genome accession GCF_002899475.1 | jq .reports[0].organism.organism_name -r)
strain=$(datasets summary genome accession GCF_002899475.1 | jq .reports[0].organism.infraspecific_names.strain -r)
echo "${organism_name} ${strain}"
```

But, it would be wasteful to query their servers this many times in an automated download loop. If you look at the command above, it's querying the database and downloading this metadata twice, once for each call of `datasets summary genome accession`. Instead, we should get these values from the 
assembly_data_report.jsonl file we downloaded. We can do that by replacing `datasets summary genome accession GCF_002899475.1 | jq` with `jq ncbi_dataset/data/assembly_data_report.jsonl`. That would look like this:

```
organism_name=$(jq .reports[0].organism.organism_name -r ncbi_dataset/data/assembly_data_report.jsonl)
strain=$(jq .reports[0].organism.infraspecific_names.strain -r ncbi_dataset/data/assembly_data_report.jsonl)
echo "${organism_name} ${strain}"
```

But if we try that, it won't work as expected. Can you tell why?
<p>
<details>
<summary>Hint: Try looking at the data in this file with <code>jq . ncbi_dataset/data/assembly_data_report.jsonl</code></summary>

The assembly_data_report.jsonl file uses variable names in camelCase instead of snake_case. So, we'll need to change our variable calls in the command. It also doesn't have the outer level "reports" field; the data is just the report by itself. So we won't need the <code>.reports[0]</code> field anymore.

<pre><code>organism_name=$(jq .organism.organismName -r ncbi_dataset/data/assembly_data_report.jsonl)
strain=$(jq .organism.infraspecificNames.strain -r ncbi_dataset/data/assembly_data_report.jsonl)
echo "${organism_name} ${strain}"</code></pre>

</details>
</p>

Great! Now we've extracted the organism name. Let's say we want our genomic fasta file to be called "Escherichia_coli_DH5alpha.GCF_002899475.1.fna"

**Question: Why would we want to name the file this way?**

<p>
<details>
<summary>Answer</summary>

It's helpful to have the organism name in a human readable format for when you want to work with it later -- that way you don't have to memorize the accession numbers of the different genomes you're working with. However, it's also a good idea to leave the accession number as part of the name; that way we never lose track of where we got this file from.

Also, spaces are allowed in file names in bash, but if you're not careful, they can cause problems. To make things easier, it's best to just replace the spaces with "_".

</details>
</p>

To replace the spaces, one easy method we can use is the `tr`, to text replace, command. You can see it work like this:
```
echo "${organism_name} ${strain}" | tr " " _
```

Or to get our final file name:
```
filename=$(echo "${organism_name} ${strain}.GCF_002899475.1.fna" | tr " " _)
echo $filename
```

To rename the file, we can simply use the mv (move) command with our new filename! 

```
mv ncbi_dataset/data/GCF_002899475.1/GCF_002899475.1_*_genomic.fna $filename
```

And once we don't need it anymore, we can delete the ncbi_dataset directory and other downloaded data:
```
rm -r ncbi_dataset README.md md5sum.txt ncbi_dataset.zip
```

Now, we've got a downloaded and helpfully named genomic fasta file, using only the accession number!

## Step Seven: Actually writing the script

Now that we've manually tested out all the different steps that will be carried out in this script, it's time to actually download the files. Start by creating a script file; you can put it in the mempang_hacking directory if you want. Mine will be called `oliver.datasets.sh`.

The next step is to write the script! We can worry about looping through different accession numbers later; for now, let's write the script to accept a single accession number, which will be the first input argument to the script. For bash, that looks like this:

```
acc=$1
```

A bash script will always treat $1 as the first argument, $2 as the second argument, and so on. 

Try to go ahead and write your script! It should use `datasets download genome accession` to download the data and unzip the download, then check if everything downloaded correctly. If it did, then use data from the assembly_data_report.jsonl file to rename the downloaded genome file; and finally, delete the ncbi_dataset directory and other downloads.

Bonus points if you add an "else" clause to your if statement checking the md5sum and print an error message if everything didn't download  "OK".

## Step Eight: Creating the loop

To be added