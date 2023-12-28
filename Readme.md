[![Test]( https://github.com/ivargr/kage-indexing/actions/workflows/test.yml/badge.svg)](https://github.com/ivargr/kage-indexing/actions/workflows/test.yml)


**NB: This way of making indexes for KAGE is outdated and indexes can now be created much more easily using the `kage index` comman. Please see the main kage repository for instructions.**

# Making indexes for KAGE

This repository contains a snakemake pipeline for making an index that can be used with KAGE. To use this pipeline, you will need:
    
* A VCF with genotypes of a population, e.g. a thousand genomes VCF. Only biallelic variants are supported for now. The snakemake pipeline will try to split variants into biallelic if you have multiallelic variants, and it will also remove some overlapping indels that may cause trouble if there are any.
* A reference genome (.fa or .2bit format)

**Note**

Making indexes for a species such as human with e.g. using Thousands Genomes Project variants, unfortunately takes some time (2-3 days) and requires a lot of computational power. You should have a system with 30+ cores and 512 GB of RAM. We are working on rewriting a lot of the indexing code, and hope to have a much quicker and smoother process in the future. If you are genotyping humans, a good option is to use one of our prebuilt indexes. If you want to make indexes for another species, feel free to contact us (ivargry@ifi.uio.no) and we might be able to build the indexes for you or help you out.

The pipeline has been tested to work with human and yeast data, and we would be happy to try to make indexes for other species -- feel free to reach out.

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

### Step 4: Test that the pipeline works

This repository comes with some real data for testing that the pipeline works as expected. It is a very good idea to run this test before starting to run with your own data, so that you know that things have been installed correctly. Simply run:

```bash
snakemake --use-conda test
```

This will run a full build of a small human index and runs kage with the final index and checks that the accuracy is as expected. This should take about 5 minutes to finish. If you don't get any error messages, things are fine.


### Step 4: Get your variants and reference genome

Put these somewhere (e.g in the local_data folder or anywhere else on your computer):

* Your reference genome should end with `.fa` or a `.2bit` in order to be detected by snakemake.
* Your variants should be a `vcf.gz` file with an accompanying index ending with `vcf.gz.tbi`. Your variants should ideally be phased and not have many missing genotypes. If there are missing genotypes (i.e. "."), these will be treated as the reference allele. Variants are not required to be phased, but accuracy will likely be better with phased variants.


### Step 4: Edit config.yml

Edit the `config.yml` file so that it fits with your data.

* Add an entry for your variants under `variants:`. Note that your variants can either point to a local path or some url. 
* Add an entry for you reference genome under `genomes:` 
* Create a new dataset under `analysis_regions`. Specify chromsomes. Note: It is a good idea to define a small dataset for just a single or a few chromosomes first and test the whole pipeline to see that it doesn't crash before you try to make an index for the whole genome.
* Change all the parameters starting with `n_threads`. These specifies the number of threads used for various parts of the pipeline. These can usually be set to the number of cores available.


### Step 5: Run

Run the snakemake pipeline:

```bash
snakemake --use-conda --cores 40 --resource mem_gb=450 data/your_dataset/index_100all.npz
```

The important parts here are:

* `--use-conda` (can be skipped, but then you will need to manually install alot of tools, such as bcftools, samtools, etc)
* `--resources mem_gb=450`: Should be set to approximately how much memory your system has. Snakemake will try to adjust which and how many jobs are run in parallel. Note that the memory requirements of each job are hardcoded, so this will be very approximate. If you run out of memory, you can try to lower the number here.
* `data/dataset2/index_100all.npz`: This is the index file we tell Snakemake to create and this is the index file that kage will need. Here we specify the `your_dataset` folder because we have defined this datset in the `config.yml` file. It is a good idea to try to create an index for e.g. one chromosome or a small part of a chromosome first, to check that nothing crashes. The `100all` tells the pipeline to include 100 individuals in the model. Running time scales linearly with the number of individuals, so to save time you can specify fewer individuals. It might be a good idea to set this number really low first to see that things run smootly and then increase it for the final index.

If the Snakemake command runs sucecssfully, you should end up with the given index which can be used directly with kage.


Note:

* If the snakemake pipeline crashes, you might be left with used memory that is not freed. You can free this by running `kage free_memory`.
* Feel free to reach out if anything doesn't seem to work as it should. This pipeline is under development and has been tested with human and yeast genomes.

