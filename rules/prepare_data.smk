
include:
    "reference_genome.smk"

def get_dataset_regions(wildcards):
    return config["analysis_regions"][wildcards.dataset]["region"]

def get_dataset_regions_comma_separated(wildcards):
    return config["analysis_regions"][wildcards.dataset]["region"].replace(" ", ",")

def get_dataset2_regions_comma_separated(wildcards):
    return config["analysis_regions"]["dataset2"]["region"].replace(" ", ",")

def only_snps_command(wildcards):
    if "only_snps" in config["analysis_regions"][wildcards.dataset]:
        return " | bcftools filter -i 'TYPE=\"snp\"' /dev/stdin -O z"
    return ""

def get_svdataset_regions_comma_separated(wildcards):
    return config["analysis_regions"]["svdataset" + wildcards.number]["region"].replace(" ", ",")

def get_n_individuals(wildcards):
    return config["analysis_regions"]["simulated_dataset" + wildcards.number]["n_individuals"]

def get_n_variants(wildcards):
    return config["analysis_regions"]["simulated_dataset" + wildcards.number]["n_variants"]

def get_dataset_skipped_individuals_comma_separated(wildcards):
    return config["analysis_regions"]["svdataset" + wildcards.number]["skip_individuals"].replace(" ", ",")


def download_variants_command(wildcards, input, output):
    genome_config = config["variants"][wildcards.variants_id]

    url = genome_config["url"]
    if url.startswith("http"):
        print("Data is remote")
        return f"wget -O {output.variants} {url}  &&  wget -O {output.index} {url}.tbi"
    else:
        print("Data is local")
        return f"cp {url} {output.variants}  && cp {url}.tbi {output.index}"


rule download_variants:
    output:
        variants="data/{variants_id,\w+}.vcf.gz",
        index="data/{variants_id,\w+}.vcf.gz.tbi"
    params:
        command=download_variants_command
    shell:
        "{params.command}"


rule prepare_dataset_vcf:
    input:
        vcf=lambda wildcards: "data/" + config["analysis_regions"][wildcards.dataset]["variants"] + ".vcf.gz",
        ref=lambda wildcards: "data/" + config["analysis_regions"][wildcards.dataset]["reference"] + ".fa"
    output:
        "data/{dataset}/variants.vcf.gz"
    params:
        regions=get_dataset_regions_comma_separated,
        only_snps_command=only_snps_command
    conda: "../envs/prepare_data.yml"
    shell:
        "bcftools view --regions {params.regions} {input.vcf} {params.only_snps_command} | "
        "bcftools norm -m-any --check-ref -w -f {input.ref} - > {output}.tmp &&  "
        "python3 scripts/remove_overlapping_indels.py {output}.tmp | "
        "python3 scripts/remove_extra_format_fields_from_vcf.py | "
        "bgzip -c > {output} && tabix -f -p vcf {output} "


rule prepare_dataset_reference:
    input:
        #config["reference_file"]
        ref=lambda wildcards: "data/" + config["analysis_regions"][wildcards.dataset]["reference"] + ".fa"
    output:
        full_reference="data/{dataset}/ref.fa",
        index="data/{dataset}/ref.fa.fai"
    params:
        regions=get_dataset_regions
    conda: "../envs/prepare_data.yml"
    shell:
        "samtools faidx {input} {params.regions} | python3 scripts/format_fasta_header.py > {output.full_reference}  && " 
        "samtools faidx {output.full_reference}"


# makes a "flat" reference, one sequence for the whole genome
rule make_flat_reference:
    input: "data/{d}/ref.fa"
    output:
        fasta="data/{d}/ref_flat.fa",
        index="data/{d}/ref_flat.fa.fai"
    conda: "../envs/prepare_data.yml"
    shell:
        r"""python scripts/make_flat_reference.py {input} | fold -w 80 > {output.fasta} && samtools faidx {output.fasta}"""


rule remove_genotype_info:
    input: "{sample}.vcf.gz"
    output: "{sample}_no_genotypes.vcf"
    shell: "zcat {input} | cut -f 1-9 - > {output}"


rule get_all_sample_names_from_vcf:
    input:
        "data/{dataset}/variants.vcf.gz"
    output:
        sample_names="data/{dataset}/sample_names_all.txt",
        sample_names_random="data/{dataset}/sample_names_random_order_all.txt"
    conda: "../envs/prepare_data.yml"
    shell:
        "bcftools query -l {input} > {output.sample_names} && "
        "python scripts/shuffle_lines.py {output.sample_names} {config[random_seed]} > {output.sample_names_random} "


rule create_vcf_with_subsample_of_individuals:
    input:
        vcf="data/{dataset}/variants.vcf.gz",
        sample_names_random="data/{dataset}/sample_names_random_order_{subpopulation}.txt"
    output:
        subsamples="data/{dataset}/sample_names_random_order_{n_individuals,\d+}{subpopulation,[a-z]+}.txt",
        vcf="data/{dataset}/variants_{n_individuals,\d+}{subpopulation,[a-z]+}.vcf.gz",
        vcfindex="data/{dataset}/variants_{n_individuals,\d+}{subpopulation,[a-z]+}.vcf.gz.tbi"
    conda: "../envs/prepare_data.yml"
    shell:
        "head -n {wildcards.n_individuals} {input.sample_names_random} > {output.subsamples} && "
        "bcftools view -O z -S {output.subsamples} {input.vcf} > {output.vcf} && tabix -f -p vcf {output.vcf}"


rule uncompress_subsampled_vcf:
    input:
        vcf="data/{dataset}/variants_{n_individuals,\d+}{subpopulation}.vcf.gz"
    output:
        vcf="data/{dataset}/variants_{n_individuals,\d+}{subpopulation}.vcf"
    shell:
        "zcat {input} > {output}"


rule convert_fa_to_fq:
    input: "{reads}.fa"
    output: "{reads}.fq"
    conda: "../envs/prepare_data.yml"
    shell: "scripts/convert_fa_to_fq.sh {input} > {output}"


rule make_dict_file:
    input: "data/{dataset}/ref.fa"
    output: "data/{dataset}/ref.dict"
    conda: "../envs/picard.yml"
    shell: "picard CreateSequenceDictionary -R {input} -O {output}"
    