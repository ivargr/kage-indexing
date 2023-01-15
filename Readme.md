
# Making indexes for KAGE

This repository contains a snakemake pipeline for making an index that can be used with KAGE. To use this pipeline, you will need:
    
* A VCF with genotypes of a population, e.g. a thousand genomes VCF. Only biallelic variants are supported for now.
* A reference genome

**Note**

Making indexes for a species such as human with e.g. using Thousands Genomes Project variants, unfortunately takes some time (2-3 days) and requires a lot of computational power. You should have a system with 30+ cores and 512 GB of RAM. We are working on rewriting a lot of the indexing code, and hope to have a much quicker and smoother process in the future. If you are genotyping humans, a good option is to use one of our prebuilt indexes. If you want to make indexes for another species, feel free to contact us (ivargry@ifi.uio.no) and we might be able to build the indexes for you or help you out.

## Running the pipeline

### Step 1: Intall Snakemake and Conda
Before you start, you will need both Snakemake (to run the benchmarking pipeline) and Conda (to get all the correct dependencies. [Follow the instructions](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html) to install Snakemake if you don't have Snakemake allready.

### Step 2: Clone this repository
```bash
git clone https://github.com/ivargr/kage-indexing
```

### Step 3: Install Python dependencies

All Python dependencies you will need are listed in `python_requirements.txt` and can be installed by running:

```python
pip install -r python_requirements.txt
```

### Step 4: Get your variants and reference genome

Put these somewhere (e.g in the data folder) and edit config.yml to point to the location.

* Your reference genome should be a `.fa` file
* Your variants should be a `vcf.gz` file with an accompanying index ending with `vcf.gz.tbi`. Your variants need to have phased genotypes.


### Step 4: Edit config.yml

Edit the `config.yml` file so that it fits with your data (e.g. specify chromosomes). The file includes an explanation of what needs to be edited.


### Step 5: Run

Run the snakemake pipeline:

```bash
snakemake --use-conda --cores 40 --resource mem_gb=450 data/dataset2/index_1000all.npz
```

The important parts here are:

* `--use-conda` (can be skipped, but then you will need to manually install alot of tools, such as bcftools, samtools, etc)
* `--resources mem_gb=450`: Should be set to approximately how much memory your system has. Snakemake will try to adjust which and how many jobs are run in parallel. Note that the memory requirements of each job are hardcoded, so this will be very approximate. If you run out of memory, you can try to lower the number here.
* `data/dataset2/index_1000all.npz`: This is the index file we tell Snakemake to create and this is the index file that kage will need. Here we specify the `dataset2` folder because we have defined this in the `config.yml` file. It is a good idea to try to create an index for e.g. one chromosome or a small part of a chromosome first, to check that nothing crashes. The `1000all` tells the pipeline to include 1000 individuals in the model. Running time scales linearly with the number of individuals, so to save time you can specify fewer individuals.

If the Snakemake command runs sucecssfully, you should end up with the given index which can be used directly with kage.


Note:

* If the snakemake pipeline crashes, you might be left with used memory that is not freed. You can free this by running `kage free_memory`.