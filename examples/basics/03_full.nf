#!/usr/bin/env nextflow

process full {
    input:
        path infile

    output:
        path "output.txt"

    script:  // command changed!
        """
        wc -w "$infile" > output.txt
        """
}

workflow {
    // Channel.fromPath("data/text/*.md")  // you can use glob patterns
    Channel.fromPath("data/text/slipsum.md")
        | full
}
