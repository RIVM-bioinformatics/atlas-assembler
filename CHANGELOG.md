# Changelog

## [0.2.0](https://github.com/RIVM-bioinformatics/atlas-assembler/compare/v0.1.0...v0.2.0) (2026-05-22)


### Features

* updated juno library to new tag ([c7452f0](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/c7452f058d84eaf133be691acde5029d0acb3c60))

## 0.1.0 (2026-05-19)


### Features

* add skani to autocycler branch ([02e127f](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/02e127fe3aece597aeccca67bbf555a16d27b925))
* add species identification and post qc for autocycler ([07353ca](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/07353ca2f09b4e6366fd59b99f5a7ac9d8194a56))
* added bracken and checkm ([9b1147b](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/9b1147bcea3070b3fc7cacb00cfedf18dfd35fb0))
* added checkm ([823541a](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/823541a1faf5b0533b1e2de978f983a3e08eb89c))
* added fastplong ([6ad53ee](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/6ad53eeb9cecae4e239949587db3fdbe178c72fe))
* added flye assembler and env ([b3e8c50](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/b3e8c505590121dde85a9d238a5df0400f181776))
* added flye assembler and env ([ce803a0](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/ce803a0cd44ab847bca54a35003dc8426c722d27))
* added genome calculation and coverage calculation ([7a0a1e0](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/7a0a1e0661171d949742e47762f0af1ca2f6af34))
* added quast and multiqc ([3705f9e](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/3705f9e0a7236e34cc8eae5f70044223ea2ca6c4))
* added rule for kraken2 ([d85c153](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/d85c153a36d54298b5fd4bda6bc9d6d32f88f52a))
* added tool BUSCO ([ee1eaad](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/ee1eaad9909994308b8896714a6c39b1c778cad2))
* adding atlas environments and params ([6c76039](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/6c76039bee997b72721a9843c2b23895415e74d8))
* autocycler rules and scripts ([ae30da3](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/ae30da3e901d0a11aad978aa05da8472ca95b635))
* checkpoints for autocycler to check coverage ([bd02da1](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/bd02da194fc2e333224e194909ce0e4d43b87c23))
* custom quast section in multiqc ([78b6aec](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/78b6aec2cf90ac5ee691eadab0532a321bd2c122))
* enabling filtlong ([dbdbfce](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/dbdbfce7fc590c862507480ec00f7f515d58ef7e))
* fastplong in multiqc and creating qc report ([c4123f5](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/c4123f5918014e2d4ddf00e8cfc142446504db3d))
* implemented genome size calc and autocycler subsampling ([ac92fca](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/ac92fca455137cea8611f367a17fa4338a1c0082))
* including fastp and nanoplot ([33a390b](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/33a390bbd34cd0221f12694a1669312c8f72ea68))
* modifications to use exclude file ([6410fbd](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/6410fbd7b16f0533407d28ff4e148ac5b948826d))
* parse nanostats function to extract NanoPlot output and incorporate into multiqc ([4e8708a](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/4e8708ad1deb2aa93d8b6dfc7479206f320f44d5))
* qc report, and fastplong output in multiqc ([667614f](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/667614ffac5356cdfb66de581b09a854d8dea9e5))
* rule chopper ([9a6ab21](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/9a6ab218c772ba1f001f8e431ebb253fe5c00c48))
* scripts for executing assemblers ([3565d76](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/3565d76d1383acc839bda1f0ad39440ed9984195))


### Bug Fixes

* add variable to increase time limit for jobs getting killed ([72ad602](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/72ad60262079dd70afa85ed1cb3baafa5771bda6))
* added fastplong output to multiqc ([9a8d173](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/9a8d1733f435c1adae1fc692bd94424fad63154b))
* added missing canu commands ([ba3700b](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/ba3700b85ab3cde5c72c9eff670f4f78e1215b01))
* assembly name in flye output ([99911f2](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/99911f2fcef0743a6aa04f1b4b6bf0cf8d3feffc))
* bug in parsing fastplong data ([ec55393](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/ec55393fa442b257880c570cf9168e795b030722))
* bug reading checkm values in qc report ([f80bd8e](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/f80bd8e16c2ad7d207fdfee994c3128b15625bcf))
* bug with coverage calculation not in QC report ([8c823c8](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/8c823c8f714f8eaeedeac1339b2d2e40200a3e5b))
* checkploints for post qc steps for low coverage samples ([b79a9ba](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/b79a9bae74582dcde8f61bf34e5d6c31844c84b0))
* cleanup ([0291dab](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/0291dab01dddf473a05ffbbac998cb6d4ae7502f))
* code cleanup ([8b93088](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/8b930887cc62feba2d2c6f766c5fdd02707d3cd3))
* code cleanup ([18e2327](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/18e23270c31d9310254542e0791f118e8e5d4799))
* comment out mamba in main env yaml ([b603a24](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/b603a242bd4083e68af50792a51aa42fd9b7621c))
* duplicated lines ([8b72313](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/8b723136b20cc42b50005ec4f171ccba260e1b80))
* fastplong and determine genome to work with file or folder input ([608d905](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/608d9056fae6134fcbd9ea6fa4bbc2cebbb92a7c))
* fixed problems with checkm and added fastplong ([5793375](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/5793375b59dc0a005e4c193c923c47e42546a9e0))
* irods metadata variable for exclude file ([61336fa](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/61336fae929e4e031c8141c23e447832f14b3bda))
* modify bash script to set working dir ([01f8cf2](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/01f8cf2cd813315896e5bb034d54c262af813448))
* openpyxl dependency ([7137bb6](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/7137bb6425de6056fe49fc6b2c4033a26cd03656))
* pin versions of tools strictly ([ee60b93](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/ee60b9309d2a9a497f16b049696aeb3ea7060016))
* remove prints ([509e31c](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/509e31cc88f0aee157022566be6fd2263f2f71c9))
* removing canu and necat ([187d9c3](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/187d9c3141559fec192b7e5f664cfe695725db33))
* test adding setuptools to checkm yaml ([2b37fe8](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/2b37fe84713539d88925fe3e0307e3b4468361d0))
* try to use dataset_id to exclude ([909cc64](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/909cc64f87cce6ec619607bb6b5c84a42c01a1c7))
* typo ([94471bb](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/94471bb24f0fed6066bf477a464161387a0bdbfc))
* unbound variable ([3858b86](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/3858b86698405d61e5cf792fbeea735a747dea2a))
* update run_pipeline script ([dfa9086](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/dfa90869e6f69ca3f2e614a9d2ef2215abf03223))
* updated checkm version due to error ([cb4c0ab](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/cb4c0aba857c67306088ba924697430d2a481eb3))
* use busco db from mnt db instead of re-downloading ([d2e9794](https://github.com/RIVM-bioinformatics/atlas-assembler/commit/d2e97944975ecf18f72098e0610f732ba85e5410))

## [1.0.1](https://github.com/RIVM-bioinformatics/juno-template/compare/v1.0.0...v1.0.1) (2023-07-12)


### Dependencies

* remove anaconda and defaults and add no defaults channel ([0b4fccb](https://github.com/RIVM-bioinformatics/juno-template/commit/0b4fccb29d192570060ed81f6222b78293e195a7))
