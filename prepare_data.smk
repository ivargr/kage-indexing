
include:
    "reference_genome.smk"

def get_dataset_regions(wildcards):
    return config["analysis_regions"][wildcards.dataset]["region"]

def get_dataset_regions_comma_separated(wildcards):
    return config["analysis_regions"][wildcards.dataset]["region"].replace(" ", ",")

rule download_vcf:
    output:
        vcf="data/variants.vcf.gz",
        index="data/variants.vcf.gz.tbi"

    shell:
        "wget -O {output.vcf} {config[thousand_genomes_vcf]} && wget -O {output.index} {config[thousand_genomes_vcf]}.tbi "

rule prepare_dataset_vcf:
    input:
        vcf="data/variants.vcf.gz"
    output:
        "data/{dataset}/variants.vcf.gz"
    params:
        regions=get_dataset_regions_comma_separated
    shell:
        #"bcftools view -O z --regions {config[analysis_regions][{dataset}]} variants.vcf.gz > {output} && tabix -p vcf {output} "
        "bcftools view -O z --regions {params.regions} {input.vcf} > {output} && tabix -p vcf {output} "

rule prepare_dataset_reference:
    input:
        "data/hg38_chr1-Y.fa"
    output:
        full_reference="data/{dataset}/ref.fa",
        #index="data/{dataset}/ref.fa.fai"
    params:
        regions=get_dataset_regions
    shell:
        "samtools faidx {input} {params.regions} | python3 scripts/format_fasta_header.py > {output.full_reference} "
        #"samtools faidx {output.full_reference}"

rule make_flat_reference:
    input: "data/{d}/ref.fa"
    output:
        fasta="data/{d}/ref_flat.fa",
        index="data/{d}/ref_flat.fa.fai"
    #shell: "grep -v '^>' {input} > {input}.no-headers && echo -e \">ref\n$(cat {input}.no-headers)\" > {output.fasta} && samtools faidx {output.fasta}"
    #shell: "grep -v '^>' {input} > {output.fasta}.tmp && echo '>ref' > {output.fasta} && cat {output.fasta}.tmp >> {output.fasta} && samtools faidx {output.fasta}"
    shell:
        r"""python3 scripts/make_flat_reference.py {input} | sed -e 's/.\{{80\}}/&\n/g' > {output.fasta} && samtools faidx {output.fasta}"""


rule remove_genotype_info:
    input: "{sample}.vcf.gz"
    output: "{sample}_no_genotypes.vcf"
    shell: "zcat {input} | cut -f 1-9 - > {output}"

rule get_all_sample_names_from_vcf:
    input:
        "data/{dataset}/variants.vcf.gz"
    output:
        sample_names="data/{dataset}/sample_names.txt",
        sample_names_random="data/{dataset}/sample_names_random_order.txt"
    shell:
        "bcftools query -l {input} > {output.sample_names} && shuf {output.sample_names} > {output.sample_names_random}"


rule create_vcf_with_subsample_of_individuals:
    input:
        vcf="data/{dataset}/variants.vcf.gz",
        sample_names_random="data/{dataset}/sample_names_random_order.txt"
    output:
        subsamples="data/{dataset}/sample_names_random_order_{n_individuals}.txt",
        vcf="data/{dataset}/variants_{n_individuals}individuals.vcf.gz"
    shell:
        "head -n {wildcards.n_individuals} {input.sample_names_random} > {output.subsamples} && "
        "bcftools view -O z -S {output.subsamples} {input.vcf} > {output.vcf}"


rule uncompress_subsampled_vcf:
    input:
        vcf="data/{dataset}/variants_{n_individuals,\d+}individuals.vcf.gz"
    output:
        vcf="data/{dataset}/variants_{n_individuals,\d+}individuals.vcf"
    shell:
        "zcat {input} > {output}"


rule bwa_index_reference_genome:
    input:
        "data/{dataset}/ref.fa"
    output:
        "data/{dataset}/ref.fa.bwt"
    shell:
        "bwa index {input}"


rule convert_fa_to_fq:
    input: "{reads}.fa"
    output: "{reads}.fq"
    shell: "scripts/convert_fa_to_fq.sh {input} > {output}"


rule make_dict_file:
    input: "data/{dataset}/ref.fa"
    output: "data/{dataset}/ref.dict"
    shell: "java -jar /home/ivar/dev/picard.jar CreateSequenceDictionary -R {input} -O {output}"
    