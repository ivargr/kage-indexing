
rule run_kage:
    input:
        index="data/dataset1/index_25all.npz",
        reads="{reads}.fa"
    output:
        "{reads}.genotyped.vcf"
    shell:
        """
        kage genotype -i {input.index} -k 31 -r {input.reads} -b True -B True -i {input.index} -o {output}
        """


# test kage with realistic data on a human index
rule test:
    input:
        "local_data/hg38_small_test-hg002_simulated_reads_15x.genotyped-truth_hg002.summary.csv"
    output:
        touch("test.txt")
    run:
        import pandas as pd
        results = pd.read_csv(input[0])
        f1_scores = results["METRIC.F1_Score"] 
        assert f1_scores[0] >= 0.68
        assert f1_scores[2] >= 0.95


rule run_happy:
    input:
        ref="{folder}/{ref}.fa",
        genotypes="{folder}/{genotypes}.vcf",
        truth_vcf="{folder}/{truth}.vcf.gz",
        truth_regions_file="{folder}/{truth}_regions.bed",
    output:
        summary_output_file="{folder}/{ref}-{genotypes}-{truth}.summary.csv",
    params:
        out_base_name=lambda wildcards, input, output: output.summary_output_file.replace(".summary.csv", "")
    conda:
        "../envs/happy.yml"
    shell:
        "hap.py {input.truth_vcf} {input.genotypes} -r {input.ref} -o {params.out_base_name} -f {input.truth_regions_file}"
