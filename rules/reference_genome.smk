

def download_reference_genome_command(wildcards, input, output):
    genome_config = config["genomes"][wildcards.genome_build]

    url = genome_config["url"]

    out_file_name = output[0]
    tmp_file_name = out_file_name + ".tmp"

    if url.endswith(".2bit"):
        if url.startswith("http"):
            return f"wget -O {tmp_file_name} {url} && twoBitToFa {tmp_file_name} {out_file_name}"
        else:
            return f"cp {url} {tmp_file_name} && twoBitToFa {tmp_file_name} {out_file_name}"
    else:
        if url.startswith("http"):
            return f"wget -O {out_file_name} {url}"
        else:
            return f"cp {url} {out_file_name}"


rule download_reference_genome:
    output:
        "data/{genome_build}.fa"
    params:
        command=download_reference_genome_command
    conda: "../envs/prepare_data.yml"
    shell:
        "{params.command}"


"""
def get_ref_genome(wildcards):
    if config["genomes"][wildcards.genome]["url"].endswith(".2bit"):
        return f"data/{wildcards.genome}.2bit"
    else:
        return

rule convert_reference_genome_to_fasta:
    input:
        get_ref_genome
    output:
        ref="data/{genome}.fa",
        fai="data/{genome}.fa.fai"
    conda: "../envs/prepare_data.yml"
    shell:
        "twoBitToFa {input} {output.ref} && samtools faidx {output.ref}"
"""

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