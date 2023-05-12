

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
    conda: "../envs/twobittofa.yml"
    shell:
        "{params.command}"



rule make_decoy_fasta:
    output: "data/{dataset}/decoy.fasta"
    shell: "echo -n '' > {output}"