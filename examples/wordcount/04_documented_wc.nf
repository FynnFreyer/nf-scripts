#!/usr/bin/env nextflow

// here we add a --help parameter and proper docstrings in JavaDoc format

// set default values for the command line parameters
params.help = false
params.out = 'results/'
// params.in is ommitted, because it doesn't make sense to define a default for that

/**
 * Generate a new file name based on an input file and a tag, by prepending the
 * tag to the file's extension.
 * <p>
 * E.g. if file = "somefile.txt" and tag = "out", we return "some_file.out.txt".
 *
 * @param file The file for which to generate the tagged name.
 * @param tag  The tag to prepend to the file's extension. Defaults to "out".
 * @returns    A string with the tagged file name.
 */
def tag_output(file, tag = "out") {
    def base_name = file.getSimpleName()
    def suffix = file.getExtension()
    def tagged_name = "${base_name}.${tag}.${suffix}"

    tagged_name  // last expression is returned implicitly!
}


/**
 * Print a help message to stdout.
 *
 * @returns Nothing.
 */
def printHelp() {
    log.info """
wordcount.nf - A Word Counter Pipeline

SYNOPSIS
    wordcount.nf [--help] --in INPUT [--out OUTPUT]

DESCRIPTION
    The word counter outputs the most common words in files.

OPTIONS
    --help    print this message and exit
    --in      path or glob pattern to specify files to count
    --out     path to an output directory (defaults to "results/")
"""
}

/**
 * Put words in a file on individual lines, convert them to lowercase,
 * and remove punctuation and empty lines.
 */
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
            | grep . \
          > "$output"
        """
}

/**
 * Produce a file with word counts.
 */
process count_words {
    input:
        path norm_words_file

    output:
        path output

    script:
        output = tag_output(norm_words_file, "counts")  // "some_file.txt.counts"
        """
        cat "$norm_words_file" \
            | sort \
            | uniq -c \
            | sort -n \
          > "$output"
        """
}

/**
 * Choose the most common word from a file with word counts.
 */
process choose_words {
    publishDir params.out  // publishDir copies outputs to the specified directory

    input:
        path sorted_words_file

    output:
        path output

    script:
        output = tag_output(sorted_words_file, "most_common")
        """
        cat "$sorted_words_file" \
            | tail -1 \
            | tr -s ' ' \
            | cut -d ' ' -f 3 \
          > "$output"
        """
}

workflow {
    // print help message if --help was passed
    if (params.help) {
        printHelp()
        exit(0)  // exit without error code
    }

    // if no --in is passed on the command line, then params.in is null
    if (params.in == null) {
        exit(1, "Didn't pass an input (via --in). Run with --help to see usage!")
    } else {
        // create a file channel from the path (or glob) passed as --in parameter
        def word_files_ch = channel.fromPath(params.in)
        normalize_words(word_files_ch)
            | count_words
            | choose_words
            | view
    }
}
