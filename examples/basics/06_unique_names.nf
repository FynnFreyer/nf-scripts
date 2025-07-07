#!/usr/bin/env nextflow

params.in = "data/text"
params.glob = "*"
params.out = "results"

process published {
    publishDir params.out, mode: "copy"

    input:
        path infile

    output:
        path "*.counts"

    script:
        """
        wc -w "$infile" > "${infile.getSimpleName()}.counts"
        """
}

workflow {
    Channel.fromPath("${params.in}/${params.glob}")
        | published
}
