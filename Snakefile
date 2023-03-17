configfile: "config.yaml"
include: "rules/prepare_data.smk"
include: "rules/indexing.smk"
include: "rules/test.smk"

wildcard_constraints:
    genome="[A-Za-z0-9_-]+",
    genome_build="[A-Za-z0-9_-]+"
