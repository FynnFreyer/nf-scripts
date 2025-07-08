#!/usr/bin/env nextflow

//params.in = "*.txt"


process normalize_words {
    input:
        path words_file

    output:
        path "out.txt"

    script:
        """
        cat "$words_file" \
            | tr -s ' ' '\n' \
            | tr -d '[:punct:]' \
            | tr '[:upper:]' '[:lower:]' \
          > out.txt
        """
}

process count_words {
    input:
        path words_file

    output:
        path "out.txt"

    script:
        """
        cat "$words_file" \
            | sort \
            | uniq -c \
            | sort -n \
          > out.txt
        """
}

process choose_words {
    input:
        path words_file

    output:
        path "out.txt"

    script:
        """
        cat "$words_file" \
            | tail -1 \
            | tr -s ' ' \
            | cut -d ' ' -f 3 \
          > out.txt
        """
}

workflow {
    if (params.in == null) {
        exit(1, "Didn't pass an input")
    } else {
        def word_files_ch = channel.fromPath(params.in)
        normalize_words(word_files_ch)
            | count_words
            | choose_words
            | view
    }
}
