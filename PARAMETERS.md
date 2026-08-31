# WaSPPipe Parameters Reference

This document describes the current configurable parameters for the WaSPPipe pipeline, synced with the workflow config and JSON schema.

---

## Input Options

Define where the pipeline should find input data and change some of the core run settings.

### fastq
- **flag** ```--fastq```
- **Type:** String (path)
- **Required:** Yes
- **Description:** Path to the fastq_pass directory for the sequencing run.
- **Help:** This should point to the fastq_pass folder containing one directory per barcode. Data must already be demultiplexed.

### run_ID
- **flag** ```--run_ID```
- **Type:** String
- **Required:** Yes
- **Description:** Run ID for the sequencing run. This must match the Run ID entered into REDCap.

### ref
- **flag** ```--ref```
- **Type:** String (path)
- **Default:** WaSPP curated viral family reference set
- **Description:** Reference file the samples will be mapped against for reference-based assembly.
- **Help:** Change this to a custom reference FASTA if needed.

### remap_all
- **flag** ```--remap_all```
- **Type:** Boolean
- **Default:** False
- **Description:** Remap reads against every reference that had at least one read mapped in the initial pass.
- **Help:** This can improve sensitivity for divergent but related references, but it can also significantly slow the pipeline.

### top_hit_only
- **flag** ```--top_hit_only```
- **Type:** Boolean
- **Default:** False
- **Description:** Build consensus sequences only for the top-hit reference in each sample.
- **Help:** After the first mapping, the pipeline selects the reference with the largest read count and remaps to that reference only.

### parse_all
- **flag** ```--parse_all```
- **Type:** Boolean
- **Default:** False
- **Description:** Parse all folders in the fastq_pass directory instead of only barcode-prefixed folders.
- **Help:** This allows folders such as Unclassified to be included, but can increase runtime and memory use substantially.

---

## Filtering Options

These options control read quality and trimming before mapping.

### readQ
- **flag** ```--readQ```
- **Type:** Integer
- **Default:** 12
- **Description:** Minimum read quality threshold for filtering.
- **Help:** During initial filtering, reads with average quality below this value are discarded.

### max_len
- **flag** ```--max_len```
- **Type:** Integer
- **Default:** 1500
- **Description:** Reads above this length are filtered before mapping.
- **Help:** Standard WaSPP primers should not create fragments longer than ~1500bp.

### min_len
- **flag** ```--min_len```
- **Type:** Integer
- **Default:** 100
- **Description:** Reads below this length are filtered before mapping.

### trim_len
- **flag** ```--trim_len```
- **Type:** Integer
- **Default:** 30
- **Description:** Number of bases trimmed from read ends to remove primer sequence.
- **Help:** WaSPP primers are typically <=30bp, so trimming this length should remove them from downstream analysis.

---

## Mapping Options

### mappingQ
- **flag** ```--mappingQ```
- **Type:** Integer
- **Default:** 15
- **Description:** Minimum read mapping quality threshold.
- **Help:** Reads below this threshold are not counted toward the minimum read count.

### read_count
- **flag** ```--read_count```
- **Type:** Integer
- **Default:** 50
- **Description:** Minimum number of reads mapping to a reference required to attempt consensus generation.
- **Help:** If a reference has at least this many mapped reads, the pipeline will try to build a consensus for it.

### unmapped_out
- **flag** ```--unmapped_out```
- **Type:** Boolean
- **Default:** False
- **Description:** Output unmapped reads in a separate file.
- **Help:** Unmapped reads are written in the read_mapping_3 output directory after the first mapping step.

---

## Consensus Options

### depth
- **flag** ```--depth```
- **Type:** Integer
- **Default:** 20
- **Description:** Positions below this depth are masked in the final consensus sequences.
- **Help:** If a site has fewer than this number of reads, it is replaced with an N.

### baseQ
- **flag** ```--baseQ```
- **Type:** Integer
- **Default:** 20
- **Description:** Minimum base quality threshold used when counting read depth.
- **Help:** Bases below this quality do not contribute to the depth calculation.

---

## Kraken2 Options

### database
- **flag** ```--database```
- **Type:** String
- **Default:** Viral
- **Description:** Kraken2 database to use for read classification.
- **Options:** Viral, Standard-8Gb
- **Help:** The Viral database is the default option. The Standard-8Gb database is available but requires appropriate memory.

### individual_krona
- **flag** ```--individual_krona```
- **Type:** Boolean
- **Default:** False
- **Description:** Generate individual Krona plots for each sample.

---

## Variant Calling Options

### clair3_model
- **flag** ```--clair3_model```
- **Type:** String
- **Default:** r1041_e82_400bps_hac_v500
- **Description:** Clair3 model used for variant calling.
- **Help:** This is passed directly to the Clair3 step for the selected sequencing chemistry/basecalling model.

---

## Miscellaneous Options

These options are common to Nextflow workflows and allow tuning of runtime behavior.

### help
- **flag** ```--help```
- **Type:** Boolean
- **Description:** Display help text.

### version
- **flag** ```--version```
- **Type:** Boolean
- **Description:** Display version and exit.

### outdir
- **flag** ```--outdir```
- **Type:** String
- **Default:** output
- **Description:** Output directory for pipeline results.

### publish_dir_mode
- **flag** ```--publish_dir_mode```
- **Type:** String
- **Default:** copy
- **Description:** File publish mode used by Nextflow for output staging.

---

## Pipeline Information

- **Title:** Desperate-Dan/WaSSPipe
- **Description:** Consensus generation and analysis pipeline for the WaSPP project (WIP).
- **URL:** https://github.com/Desperate-Dan/WaSSPipe
- **Schema:** http://json-schema.org/draft-07/schema
