

def download_reference_genome_command(wildcards, input, output):
    genome_config = config["genomes"][wildcards.genome_build]

    url = genome_config["url"]
    if url.startswith("http"):
        print("Data is remote")
        return f"wget -O {output[0]} {url}"
    else:
        print("Data is local")
        return f"cp {url} {output[0]}"



rule download_reference_genome:
    output:
        "data/{genome_build}.2bit"
    params:
        command=download_reference_genome_command
    shell:
        "{params.command}"


rule convert_reference_genome_to_fasta:
    input:
        "data/{genome}.2bit"
    output:
        ref="data/{genome}.fa",
        fai="data/{genome}.fa.fai"
    conda: "../envs/prepare_data.yml"
    shell:
        "twoBitToFa {input} {output.ref} && samtools faidx {output.ref}"

"""
rule convert_reference_to_numeric:
    input:
        "data/{genome}.fa"
    output:
        ref="data/{genome}_numeric.fa",
        fai="data/{genome}_numeric.fa.fai"
    conda: "../envs/prepare_data.yml"
    shell:
        "sed 's/chr//g' {input} > {output.ref} && samtools faidx {output.ref}"
"""

rule make_decoy_fasta:
    output: "data/{dataset}/decoy.fasta"
    shell: "echo -n '' > {output}"