
rule get_truth_data:
    input:
        vcf="local_data/truth_{id}.vcf.gz",
        regions="local_data/truth_{id}_regions.bed",
    output:
        vcf="data/{dataset}/truth_{id}.vcf.gz",
        regions="data/{dataset}/truth_{id}_regions.bed",
    shell:
        "cp {input.vcf} {output.vcf} && cp {input.regions} {output.regions}"


rule run_kage:
    input:
        index="data/{dataset}/testindex.npz",
        reads="data/{dataset}/{reads}.fa"
    output:
        "data/{dataset}/{reads}.genotyped.vcf"
    shell:
        """
        #kage genotype -i {input.index} -k 31 -r {input.reads} -b True -B True -i {input.index} -o {output} -t 1
        kage genotype -i {input.index} -k 31 -r {input.reads} -b True -B True -i {input.index} -o {output} -t 1
        """


# test kage with realistic data on a human index
rule test:
    input:
        #"local_data/hg38_small_test-hg002_simulated_reads_15x.genotyped-truth_hg002.summary.csv"
        "data/dataset1/ref-hg002_simulated_reads_15x.genotyped-truth_hg002.summary.csv"
    output:
        touch("test.txt")
    run:
        import pandas as pd
        results = pd.read_csv(input[0])
        f1_scores = results["METRIC.F1_Score"]
        print(f1_scores)
        assert f1_scores[0] >= 0.64
        assert f1_scores[2] >= 0.94


rule test_yeast:
    input:
        "data/yeast_small_test/ref-BKI_simulated_reads_30x.genotyped-truth_BKI.summary.csv"
    output:
        touch("test_yeast.txt")
    run:
        import pandas as pd
        results = pd.read_csv(input[0])
        f1_scores = results["METRIC.F1_Score"]
        print(f1_scores)
        assert f1_scores[0] >= 0.88
        assert f1_scores[2] >= 0.94

rule test_yeast_full:
    input:
        "data/yeast_whole_genome/ref-BKI_simulated_reads_30x.genotyped-truth_BKI.summary.csv"
    output:
        touch("test_yeast_whole.txt")
    run:
        import pandas as pd
        results = pd.read_csv(input[0])
        f1_scores = results["METRIC.F1_Score"]
        print(f1_scores)

rule run_happy:
    input:
        ref="{folder}/{ref}.fa",
        genotypes="{folder}/{genotypes}.vcf",
        truth_vcf="{folder}/{truth}.vcf.gz",
        #truth_regions_file="{folder}/{truth}_regions.bed",
    output:
        summary_output_file="{folder}/{ref}-{genotypes}-{truth}.summary.csv",
    params:
        out_base_name=lambda wildcards, input, output: output.summary_output_file.replace(".summary.csv", "")
    conda:
        "../envs/happy.yml"
    shell:
        "hap.py {input.truth_vcf} {input.genotypes} -r {input.ref} -o {params.out_base_name} " # -f {input.truth_regions_file}"
