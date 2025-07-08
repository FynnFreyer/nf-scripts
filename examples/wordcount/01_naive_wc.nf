#!/usr/bin/env nextflow

// here we put everything into one process and hard code the data path

process count_words {
    input:
        path words_file

    output:
        path "out.txt"

    script:
        """
        cat "$words_file" \
            | tr -s ' ' '\\n' \
            | tr -d '[:punct:]' \
            | tr '[:upper:]' '[:lower:]' \
            | sort \
            | uniq -c \
            | sort -n \
            | tail -1 \
            | tr -s ' ' \
            | cut -d ' ' -f 3 \
          > out.txt
        """
}

workflow {
    // change /path/to/data according to your system
    def word_files = channel.fromPath("/path/to/data")
    count_words(word_files)
        | view { v -> "Output file is located here: $v"}
}
