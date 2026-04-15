# WaSPPipe
The consensus generation pipeline for the WaSPP project.

https://github.com/Desperate-Dan/WaSPPipe

## This pipeline is under active development and is liable to change at any point with no notice!
Initially the pipeline will focus on reference based consensus generation using the viral family references used for the primer coverage analysis. This will certainly be broadened in scope in the future.

## Installation
This pipeline can be run either on the command line as a typical nextflow pipeline or an epi2me workflow. We recommned using the EPI2ME platform for analysis at the moment.

### EPI2ME
First you need to ensure you have EPI2ME installed on the computer where you will be running this pipeline. To do this head to the [EPI2ME download](https://labs.epi2me.io/downloads/) page and select the appropriate version for your opperating system. Once downloaded, follow the installation instruction to ensure EPI2ME is working on your system. Once you launch EPI2ME you will be asked to to sign in. To continue withoyut signing in click the three dots at the bottom of the page and select "Continue as Guest". Once you launch EPI2ME for the first time it will need to run some initial installation steps. To ensure these have been run you can go to "Settings" (1) at the bottom left of the screen, then select "Local" (2) at the top right of the screen. Here you can select "Open setup" (3) and follow the steps to set up your epi2me installation fully.

<p align="center">
  <img src="docs/epi2me_setup.png" alt="epi2me setup" width="500" />
</p>

#### Add WaSPPipe workflow to EPI2ME:
To add the WaSSPipe workflow to EPI2ME select "Launch" from the panel on the left, then select "Import workflow" from the top of the page and past in the URL for the WaSSP workflow (https://github.com/Desperate-Dan/WaSPPipe), as in the image below, and click Download.

<p align="center">
  <img src="docs/import_WaSPPipe.png" alt="epi2me setup" width="500" />
</p>

#### Run WaSPPipe
Select WaSPPipe from the "launch" menu.


### Potential future additions
 - More (updated) references.
 - Read clustering/de novo based consensus generation?
 - Kraken2 or similar based krona plots?
