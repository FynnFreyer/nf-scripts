#!/usr/bin/env nextflow

// here we fix the file naming issues from the previous script
// we also add an --out parameter to determine an output directory

// solution to the previous problem:
//      we used to execute `cat out.txt | some_cmd > out.txt`, which
//      deletes the contents of out.txt without doing any actual processing
//
//      now we rename them based on the input files, which avoids such conflicts

// set default values for the command line parameters
params.out = 'results/'

// groovy function, to avoid repetetive code
def tag_output(file, tag = "out") {
    // if file = "somefile.txt" and tag = "out"
    def base_name = file.getSimpleName()               // "some_file"
    def suffix = file.getExtension()                   // "txt"
    def tagged_name = "${base_name}.${tag}.${suffix}"  // "some_file.out.txt"

    tagged_name  // last expression is returned implicitly!
}

process normalize_words {
    input:
        path words_file

    output:
        path output

    script:
        output = tag_output(words_file, "normalized")
        """
        cat "$words_file" \
            | tr -s ' ' '\\n' \
            | tr -d '[:punct:]' \
            | tr '[:upper:]' '[:lower:]' \
          > "$output"
        """
}

process count_words {
    input:
        path words_file

    output:
        path output

    script:
        output = tag_output(words_file, "counts")
        """
        cat "$words_file" \
            | sort \
            | uniq -c \
            | sort -n \
          > "$output"
        """
}

process choose_words {
    publishDir params.out  // publishDir copies outputs to the specified directory

    input:
        path words_file

    output:
        path output

    script:
        output = tag_output(words_file, "most_common")
        """
        cat "$words_file" \
            | tail -1 \
            | tr -s ' ' \
            | cut -d ' ' -f 3 \
          > "$output"
        """
}

workflow {
    // if no --in is passed on the command line, then params.in is null
    if (params.in == null) {
        exit(1, "Didn't pass an input (via --in)")
    } else {
        // create a file channel from the path (or glob) passed as --in parameter
        def word_files_ch = channel.fromPath(params.in)
        normalize_words(word_files_ch)
            | count_words
            | choose_words
        log.info "Outputs are located in $params.out"
    }
}
