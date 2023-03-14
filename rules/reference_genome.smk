

rule download_reference_genome:
    output:
        "data/{genome_build}.2bit"
    params:
        url=lambda wildcards: config["genomes"][wildcards.genome_build]["url"]
    shell:
        "wget -O {output} {params.url}"


rule convert_reference_genome_to_fasta:
    input:
        "data/{genome}.2bit"
    output:
        ref="data/{genome}.fa",
        fai="data/{genome}.fa.fai"
    conda: "../envs/prepare_data.yml"
    shell:
        "twoBitToFa {input} {output.ref} && samtools faidx {output.ref}"

rule convert_reference_to_numeric:
    input:
        "data/{genome}.fa"
    output:
        ref="data/{genome}_numeric.fa",
        fai="data/{genome}_numeric.fa.fai"
    conda: "../envs/prepare_data.yml"
    shell:
        "sed 's/chr//g' {input} > {output.ref} && samtools faidx {output.ref}"


rule make_decoy_fasta:
    output: "data/{dataset}/decoy.fasta"
    shell: "echo -n '' > {output}"