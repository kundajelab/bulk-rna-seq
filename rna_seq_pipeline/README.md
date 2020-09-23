If running on the lab cluster, the dependencies (STAR, RSEM, Trimmomatic) are installed: 

```
module load STAR  
module load rsem   
module load trimmomatic  
```
Adapters for trimmomatic are in `/software/trimmomatic/0.39/adapters` 

The STAR and RSEM genomes for hg38 are in `/mnt/data`: 
```
/mnt/data/STAR/GRCh38
/mnt/data/RSEM/GRCh38
```

To build STAR index: build_index_star.sh  
To build RSEM index: build_rsem_index.sh  

A typical workflow would include:   

* Adapter trimming: 
    * trim_rna_trimmomatic.sh (for paired end reads) 
    * trim_rna_trimmomatic_SE.sh (for single end reads)

* Alignment with STAR on the trimmed reads: 
   * map_rna_start.sh (for paired end reads) 
   * map_rna_star_single_end.sh (for single-end reads) 
   
* gene quantification with RSEM  
   * quant_rna_rsem.sh (for paired-end reads)   
   * quant_rna_rsem_single_end.sh (for single-end reads) 
   
