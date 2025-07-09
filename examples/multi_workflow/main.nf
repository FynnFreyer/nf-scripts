#!/usr/bin/env nextflow

// here we run a preprocessing workflow from within another workflow, use conda
// for dependency management, allow passing args via the config file,
// and execute a python script in a process

// helper functions
def tag_output(file, tag = "out") {
    def base_name = file.getSimpleName()
    def suffix = file.getExtension()
    "${base_name}.${tag}.${suffix}"
}

def change_ext(file, ext) {
    def base_name = file.getSimpleName()
    "${base_name}.${ext}"
}

process fastqc {
    conda 'fastqc'

    input:
        path read_file

    output:
        path report_dir

    script:
        report_dir = "${read_file.getSimpleName()}_report"
        """
        mkdir "$report_dir"
        fastqc -o "$report_dir" "$read_file"
        """
}

// this process can use externally provided arguments
// look at the contents of nextflow.config...
process fastp {
    conda 'fastp'

    input:
        path read_file

    output:  // we emit multiple outputs to different channels
        path trimmed_reads, emit: fastq
        path json_report,   emit: json

    script:
        // this allows us to pass arguments via the config file
        args = task.ext.args ?: ""  // "?:" is the so-called "Elvis" operator

        trimmed_reads = tag_output(read_file, "trimmed")
        json_report = change_ext(read_file, "json")
        """
        fastp ${args} -i "$read_file" -o "$trimmed_reads" -j "$json_report"
        """
}

workflow preprocess {
    take:
        raw_reads
    main:
        raw_reads | fastqc
        raw_reads | fastp
    emit:
        trimmed_reads  = fastp.out.fastq
        fastp_reports  = fastp.out.json
        fastqc = fastqc.out
}

// this process uses python code
process plot_result {
    conda 'pandas matplotlib'

    input:
        path data_csv

    output:
        path "${base_name}_*.${suffix}"

    script:
        base_name = "${data_csv.getSimpleName()}"
        suffix = "png"
        metric = "valid_coverage"
        """
        #!/usr/bin/env python3
        import pandas as pd
        from matplotlib import pyplot as plt

        # read and clean data
        df = pd.read_csv("$data_csv").set_index(["sample_id", "fragment"]).sort_index()
        cols = [col for col in df.columns if not col.startswith("$metric")]
        df = df.drop(cols, axis="columns").rename(lambda col: col.split("_")[-1], axis="columns")

        # print sample plots
        sample_ids = df.index.get_level_values("sample_id").unique()
        for sample_id in sample_ids:
            sample_data = df.xs(sample_id).T
            sample_data.plot.bar()
            plt.savefig(f"${base_name}_{sample_id}.${suffix}")
        """
}

process publish {
    publishDir 'results'
    input:
        val foo
    output:
        val bar
    exec:
        bar = foo
        println "Hallo $foo"
}


workflow {
    if (params.reads == null || params.table == null) {
        exit(1, "Need to provide --reads and --table parameters.\n\n" +
                "E.g. 'data/samples/*_R1.fq' for reads and 'data/tables/stats.csv' for table.\n" +
                "Glob patterns need to be quoted or they won't work.")
    }
    def reads = channel.fromPath("$params.reads")
    def table = channel.fromPath("$params.table")

    preprocess(reads)
    plot_result(table)

    // preprocess.out.fastp_reports
    // preprocess.out.fastqc
    // preprocess.out.trimmed_reads
    //     | view
        
}