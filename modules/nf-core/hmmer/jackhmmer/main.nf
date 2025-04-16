process HMMER_JACKHMMER {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hmmer:3.4--h503566f_3':
        'biocontainers/hmmer:3.4--h503566f_3' }"

    input:
    tuple val(meta), path(fasta), path(seqdb), val(write_align), val(write_target), val(write_domain)

    output:
    tuple val(meta), path('*.txt.gz')   , emit: output
    tuple val(meta), path('*.sto.gz')   , emit: alignments    , optional: true
    tuple val(meta), path('*.tbl.gz')   , emit: target_summary, optional: true
    tuple val(meta), path('*.domtbl.gz'), emit: domain_summary, optional: true
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args       = task.ext.args ?: ''
    def prefix     = task.ext.prefix ?: "${meta.id}"
    alignment      = write_align  ? "-A ${prefix}.sto" : ''
    target_summary = write_target ? "--tblout ${prefix}.tbl" : ''
    domain_summary = write_domain ? "--domtblout ${prefix}.domtbl" : ''
    """
    jackhmmer \\
        $args \\
        --cpu $task.cpus \\
        -o ${prefix}.txt \\
        $alignment \\
        $target_summary \\
        $domain_summary \\
        ${fasta} \\
        ${seqdb}

    gzip --no-name *.txt \\
        ${write_align ? '*.sto' : ''} \\
        ${write_target ? '*.tbl' : ''} \\
        ${write_domain ? '*.domtbl' : ''}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hmmer: \$(jackhmmer -h | grep -o '^# HMMER [0-9.]*' | sed 's/^# HMMER *//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch "${prefix}.txt"
    ${write_align ? "touch ${prefix}.sto" : ''} \\
    ${write_target ? "touch ${prefix}.tbl" : ''} \\
    ${write_domain ? "touch ${prefix}.domtbl" : ''}

    gzip --no-name *.txt \\
        ${write_align ? '*.sto' : ''} \\
        ${write_target ? '*.tbl' : ''} \\
        ${write_domain ? '*.domtbl' : ''}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hmmer: \$(jackhmmer -h | grep -o '^# HMMER [0-9.]*' | sed 's/^# HMMER *//')
    END_VERSIONS
    """
}
