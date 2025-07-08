#!/usr/bin/env nextflow

// here we break up the logic into multiple processes
// we also allow passing an input via the --in flag

// this file has a problem, try to figure it out!
// hint:
//      it has to do with the naming of the output files
//      and how shell redirects (e.g. in `cat a > b`) work
// check .command.sh in the work directory


process normalize_words {
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
    // if no --in is passed on the command line, then params.in is null
    if (params.in == null) {
        // exit with an error code and a message
        exit(1, "Didn't pass an input (via --in)")
    } else {
        // create a file channel from the path (or glob) passed as --in parameter
        def word_files_ch = channel.fromPath(params.in)
        normalize_words(word_files_ch)
            | count_words
            | choose_words
            | view { v -> "Output file is located here: $v"}
    }
}
