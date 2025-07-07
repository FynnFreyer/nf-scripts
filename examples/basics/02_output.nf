#!/usr/bin/env nextflow

process out {
    output:
        path "output.txt"

    script:
        """
        echo Hello World > output.txt
        """
}

workflow {
    out()
}
