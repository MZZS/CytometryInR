library(tidyverse)
library(flowCore)
library(flowWorkspace)
library(CytoML)
library(ggplot2)
library(ggcyto)

#let's take the fcs files and make a cytoset (CytoML), then make our gating set from there

Folder <- file.path("course", "05_GatingSets", "data")

fcs_files <- list.files(Folder, pattern=".fcs", full.names=TRUE)

cytoset <- load_cytoset_from_fcs(fcs_files, truncate_max_range = FALSE, transformation = FALSE)

gs <- GatingSet(cytoset)

pData(gs)

ggcyto(gs[1], subset="root", aes(x="FSC-A", y="SSC-A")) + geom_hex(bins=100) 
