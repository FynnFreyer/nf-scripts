#!/usr/bin/env nextflow

process to_sam {
    input:
      path bam_file

    output:
      path("${base_name}.sam')

    script:
      def base_name = bam_file.getSimpleName()
      """
      cat "$bam_file" | samtools view > "${base_name}.sam"
      """
}

workflow {
  def input_ch = channel.fromPath(params.in)
  to_sam(input_ch)
}
