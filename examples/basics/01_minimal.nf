#!/usr/bin/env nextflow

process minimal {
    script:
        """
        echo Hello World
        """
}

workflow {
    minimal()
}
