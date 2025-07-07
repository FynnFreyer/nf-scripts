#!/usr/bin/env nextflow

// set default values for params
params.in = "data/text"
params.glob = "*"
params.out = "results"

process published {
    // this is a directive, we'll see these again later
    publishDir params.out

    input:
        path infile

    output:
        path "output.txt"

    script:
        """
        wc -w "$infile" > output.txt
        """
}

workflow {
    Channel.fromPath("${params.in}/${params.glob}")
        | published
        | view
}
