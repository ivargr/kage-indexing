configfile: "config.yaml"

include:
    "rules/prepare_data.smk"

include:
    "rules/indexing.smk"

wildcard_constraints:
    genome="[A-Za-z0-9]+"
