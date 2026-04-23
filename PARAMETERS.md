# WaSPPipe Parameters Reference

This document describes all configurable parameters for the WaSPPipe pipeline.

---

## Input Options

Define where the pipeline should find input data and change some frequently used options.

### fastq
- **flag** ```--fastq```
- **Type:** String (path)
- **Required:** Yes
- **Description:** Provide the path to the fastq_pass directory for your run.
- **Help:** This should be the the path the the fastq_pass folder, which should contain a folder for each barcode in your run. This expects your data to be demultiplexed already, you will need to do that through Minknow if it is not already demultiplexed.

### ref
- **flag** ```--ref```
- **Type:** String (path)
- **Description:** The reference file your samples will be mapped against for reference based assembly (default: WaSPP curated viral family references).
- **Help:** Change this to a custom reference file to map your samples against. The default contains all NCBI reference sequences for the members of the viral families of interest to the WaSPP project.

### depth
- **flag** ```--depth```
- **Type:** Integer
- **Default:** 20
- **Description:** Positions below this depth will be masked in the resulting consensus sequences (default: 20).
- **Help:** When generating a consensus sequence, if there are less than this number of reads at that position it will be replaced with an N. The base quality (see below) is considered when counting the read depth at a position.

### baseQ
- **flag** ```--baseQ```
- **Type:** Integer
- **Default:** 20
- **Description:** Change the minimum base quality threshold (default: 20).
- **Help:** If a base quality score is below this value it won't be considered as part of the count for read depth.

### read_count
- **flag** ```--read_count```
- **Type:** Integer
- **Default:** 50
- **Description:** The minimum number of reads mapping to a reference to be considered for consensus generation (default: 50).
- **Help:** After mapping to your reference(s) of choice, if a given reference has at least this number of reads mapped to it WaSSPipe will try to generate a consensus sequence for it. The mapping quality of these reads (see below) is considered when read counting.

### mappingQ
- **flag** ```--mappingQ```
- **Type:** Integer
- **Default:** 15
- **Description:** Change the minimum read mapping quality threshold (default: 15).
- **Help:** If the read mapping quality is below this threshold it won't be considered as part of the count for minimum read count.

### max_len
- **flag** ```--max_len```
- **Type:** Integer
- **Default:** 1500
- **Description:** Reads above this length will be filtered before read mapping (default: 1500bp).
- **Help:** Standard WaSPP primers shouldn't generate a fragment longer than 1500bp.

### min_len
- **flag** ```--min_len```
- **Type:** Integer
- **Default:** 100
- **Description:** Reads below this length will be filtered before read mapping (default: 100bp).

### trim_len
- **flag** ```--trim_len```
- **Type:** Integer
- **Default:** 30
- **Description:** Number of bases to trim from the ends of the reads to remove primers (default: 30bp).
- **Help:** Currently WaSPP primers are not longer than 30bp, so trimming this length should remove primer sequences from downstream analysis.

---

## Kraken2 Options

Change Kraken2 options

### database
- **flag** ```--database```
- **Type:** String (path)
- **Default:** Viral
- **Description:** Change the database to use for Kraken2 read assignment (default: Viral).
- **Help:** NB VIRAL IS THE ONLY OPTION CURRENTLY AVAILABLE, BUT THIS WILL CHANGE IN THE FUTURE IF OTHER DATABASES ARE ADDED TO THE PIPELINE.
- **Options:** Viral, Other_ones

### individual_krona
- **flag** ```--individual_krona```
- **Type:** Boolean
- **Default:** False
- **Description:** Choose whether to generate individual krona plots for each sample or not (default: False).

---

## Miscellaneous Options

Everything else. These options are common to all nf-core pipelines and allow you to customise some of the core preferences for how the pipeline runs.

Typically these options would be set in a Nextflow config file loaded for all pipeline runs, such as `~/.nextflow/config`.

### help
- **flag** ```--help```
- **Type:** Boolean
- **Description:** Display help text

### version
- **flag** ```--version```
- **Type:** Boolean
- **Description:** Display version and exit.

---

## Pipeline Information

- **Title:** Desperate-Dan/WaSSPipe
- **Description:** Consensus generation and analysis pipeline for the WaSPP project (WIP).
- **URL:** https://github.com/Desperate-Dan/WaSSPipe
- **Schema:** http://json-schema.org/draft-07/schema
