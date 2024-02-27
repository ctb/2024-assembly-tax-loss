#WORT_PATH="/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{acc}.sig"

ASM_PATH="/group/ctbrowngrp2/scratch/annie/2023-swine-sra/atlas/atlas_{SRA}/{SRA}/{SRA}_contigs.fasta"

SRA_ACC="""SRR16235693
SRR11124890
SRR11183406
SRR11126167
SRR22460774
SRR11125758
SRR11125888
SRR11126428
SRR19906171
""".splitlines()
SRA_ACC = [ x.strip() for x in SRA_ACC ]

GTDB="/group/ctbrowngrp/sourmash-db/gtdb-rs214/gtdb-rs214-k31.zip"
GTDB_TAX="/group/ctbrowngrp/sourmash-db/gtdb-rs214/gtdb-rs214.lineages.sqlmf"

rule all:
    input:
        expand("outputs/asm/{SRA}.sig.zip", SRA=SRA_ACC),
        expand("outputs/{dir}/{SRA}.fastgather.csv", SRA=SRA_ACC,
               dir=['raw', 'asm']),
        expand("outputs/{dir}/{SRA}.gather.csv", SRA=SRA_ACC,
               dir=['raw', 'asm']),
        expand("outputs/{dir}/{SRA}.gather.with-lineages.csv", SRA=SRA_ACC,
               dir=['raw', 'asm']),

rule asm_sketch:
    input:
        ASM_PATH
    output:
        "outputs/asm/{SRA}.sig.zip"
    shell: """
        sourmash sketch dna {input} -o {output} --name {wildcards.SRA}
    """

rule fastgather:
    input:
        q="{location}.sig.zip",
        db=GTDB,
    output:
        "{location}.fastgather.csv",
    threads: 64
    shell: """
        sourmash scripts fastgather -k 31 {input.q} {input.db} \
            -o {output} -c {threads}
    """

rule gather:
    input:
        sketch="{location}.sig.zip",
        db=GTDB,
        fastgather="{location}.fastgather.csv",
    output:
        csv="{location}.gather.csv",
        out="{location}.gather.out",
    shell: """
        sourmash gather {input.sketch} {input.db} -o {output.csv} \
            --picklist {input.fastgather}:match_name:ident > {output.out}
    """

rule tax_gather:
    input:
        db=GTDB_TAX,
        csv="{location}.gather.csv",
    output:
        "{location}.gather.with-lineages.csv"
    params:
        dirname = lambda w: os.path.dirname(w.location)
    shell: """
        sourmash tax annotate -t {input.db} -g {input.csv} -o {params.dirname}
    """
