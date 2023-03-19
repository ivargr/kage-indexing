

def get_simulation_tmp_datasets(wildcards):
    haplotypes = [0, 1]
    chromosomes = config["analysis_regions"][wildcards.dataset]["simulation_chromosomes"].split()
    files = []
    for chromosome in chromosomes:
        for haplotype in haplotypes:
            files.append("data/" + wildcards.dataset + "/" + wildcards.truth_dataset + "_raw_simulated_reads_chromosome" + chromosome + "_haplotype" + str(haplotype) + "_coverage" + wildcards.coverage + ".txt")

    return files


rule prepare_simulation:
    input:
        vcf="local_data/truth_{truth_dataset}.vcf.gz",
        reference="data/{dataset}/ref.fa"
    output:
        coordinate_map="data/{dataset}/{truth_dataset}_coordinate_map_chromosome{chromosome}_haplotype{haplotype}.npz",
        haplotype_reference="data/{dataset}/{truth_dataset}_chromosome{chromosome}_haplotype{haplotype}_reference.fasta",
        haplotype_reference_fasta="data/{dataset}/{truth_dataset}_chromosome{chromosome}_haplotype{haplotype}_reference.fasta.fai",
    conda: "../envs/graph_read_simulator.yml"
    shell:
        "graph_read_simulator prepare_simulation --chromosome {wildcards.chromosome} --haplotype {wildcards.haplotype} "
        "--vcf {input.vcf} --reference {input.reference} -o data/{wildcards.dataset}/{wildcards.truth_dataset}_ && "
        "samtools faidx {output.haplotype_reference} "


rule simulate_reads_for_chromosome_and_haplotype:
    input:
        coordinate_map="data/{dataset}/{truth_dataset}_coordinate_map_chromosome{chromosome}_haplotype{haplotype}.npz",
        haplotype_reference="data/{dataset}/{truth_dataset}_chromosome{chromosome}_haplotype{haplotype}_reference.fasta"
    output:
        "data/{dataset}/{truth_dataset}_raw_simulated_reads_chromosome{chromosome}_haplotype{haplotype}_coverage{coverage}.txt"
    conda: "../envs/graph_read_simulator.yml"
    shell:
        "graph_read_simulator simulate_reads -s 0.001 --deletion_prob 0.001 --insertion_prob 0.001 -D data/{wildcards.dataset}/{wildcards.truth_dataset}_ '{wildcards.chromosome} {wildcards.haplotype}' {wildcards.coverage} > {output}"


rule simulate_reads:
    input:
        get_simulation_tmp_datasets
    output:
        reads="data/{dataset}/{truth_dataset}_simulated_reads_{coverage,\d+}x.fa",
        read_positions="data/{dataset}/{truth_dataset}_simulated_reads_{coverage,\d+}x.readpositions"
    conda: "../envs/graph_read_simulator.yml"
    shell:
        "cat {input} | graph_read_simulator assign_ids {output.read_positions} {output.reads}"

