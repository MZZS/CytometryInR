library(tidyverse)
library(flowCore)

Folder <- file.path("course", "05_GatingSets", "data")

fcs_files <- list.files(Folder, pattern=".fcs", full.names=TRUE)

fcs_files[1]

flowFrame <- read.FCS(filename=fcs_files[1], truncate_max_range = FALSE, transformation = FALSE)
flowFrame

#we can't do this with multiple files because a single value (a scalar) must be selected. fcs_files is mutliple files

#so we use flowSet instead

flowSet <- read.flowSet(files=fcs_files, truncate_max_range = FALSE, transformation = FALSE)
flowSet

#we can use c() to only pick specific files as well
read.flowSet(files=fcs_files[c(1, 3:4)], truncate_max_range = FALSE, transformation = FALSE)

class(flowSet)
str(flowSet)

# we need to look at memory usage because flowCore useslots of RAM for some reason

# base R
object.size(flowFrame)
object.size(flowSet)

#was not able to install lobstr
library(lobstr)
#I tried other ways but did not succeed
library(remotes)
library(devtools)

library(flowWorkspace)

#instead of using active RAM, flowWorkspace reduces memory overhead by using pointers to interact with the object in it's current storage location
cytoframe <- load_cytoframe_from_fcs(fcs_files[1], truncate_max_range = FALSE, transformation = FALSE)

#cytoframe is a single fcs object (scalar), so we can't load the entire set
cytoframe
class(cytoframe)

#so we just use cytoset instead
cytoset <- load_cytoset_from_fcs(fcs_files, truncate_max_range = FALSE, transformation = FALSE)

cytoset

class(cytoset)
str(cytoframe)

# so flowframes = all the data + more ram, cytoframe = most of the data + better memory efficiency

#you can convert between them

ConvertedToCytoframe <- flowFrame_to_cytoframe(flowFrame)
ConvertedToCytoframe

ConvertedToFlowframe <- flowWorkspace::cytoframe_to_flowFrame(cytoframe)
ConvertedToFlowframe

ConvertedToCytoset <- flowSet_to_cytoset(flowSet)
ConvertedToCytoset

ConvertedToFlowset <- cytoset_to_flowSet(flowSet)
ConvertedToFlowset

GatingSet1 <- GatingSet(flowSet)
GatingSet1 

class(GatingSet1)

GatingSet2 <- GatingSet(cytoset)
GatingSet2

class(GatingSet2)

#a gating set servces as infrastructural frameowrk to provide scale, compensation, vizualization, stats, etc.

#cytoML takes flowjo stuff and puts it into R as a fully assembled GatingSet object
library(CytoML)

FlowJoWsp <- list.files(path = Folder, pattern = ".wsp", full = TRUE)
FlowJoWsp

#define the filepath
ThisWorkspace <- FlowJoWsp[stringr::str_detect(FlowJoWsp, "Opened")]
ThisWorkspace

#proceed to set up intermediate object
ws <- open_flowjo_xml(ThisWorkspace)
ws

class(ws)

#does not work due, check library documentation to see that using additional.keys designates how the FCS header is parsed. 
gs <- flowjo_to_gatingset(ws=ws, name=1, path = Folder)

#so this is your gating set that you established in flowJo
gs <- flowjo_to_gatingset(ws=ws, name=1, path = Folder, additional.keys="GROUPNAME")
gs
pData(gs)
gs_data <- pData(gs)
#seeing how long it will take a function to run

#base R function to evaluate a line of code
#useful for very long analysis``
system.time({

flowjo_to_gatingset(ws=ws, name=1, path = Folder, additional.keys="GROUPNAME")

})

plot(gs)

#getting individual gates

gs_get_pop_paths(gs)

#getting counts

Data <- gs_pop_get_count_fast(gs)
head(Data, 5)



#metadata
#check metadata
pData(gs)

#so we can manually add metadata, or pull from the existing metadata

AlternateGS <- flowjo_to_gatingset(ws=ws, name=1, path = Folder,
 additional.keys="GROUPNAME",
 keywords=c("$DATE", "$CYT", "GROUPNAME"),
additional.sampleID = TRUE)

#here you pull keywords
pData(AlternateGS) #now you have more information for each file, which you pulled from the metadata

NameSet <- pData(AlternateGS) |> 
  mutate(
    UniqueName = paste(name, GROUPNAME)
  )

packageVersion("ggplot2")
packageVersion("ggcyto")

library(ggplot2)
library(ggcyto)

#just looking at the first one here with gs[1]
ggcyto(gs[1],
    #subset corresponds to the gating node we want to see
     subset="root",
      aes(x="FSC-A", y="SSC-A")) +
  geom_hex(bins=100) 

#just looking at the first one here with gs[1]
ggcyto(gs[1],
    #subset corresponds to the gating node we want to see
     subset="CD4+",
      aes(x="FSC-A", y="SSC-A")) +
  #bins sets the resolution
  geom_hex(bins=75)

ggcyto(gs[1], subset="CD4+", aes(x="FSC-A", y="SSC-A")) + geom_hex(bins=100) 

#marker passed in aes()
ggcyto(gs[1], subset="CD8+", aes(x="IFNg", y="TNFa")) + geom_hex(bins=100) 
#fluorophore passed in aes()
ggcyto(gs[1], subset="CD8+", aes(x="BV750-A", y="PE-Dazzle594-A")) + geom_hex(bins=100) 

ggcyto(gs[6], subset="Tcells", aes(x="CD4", y="CD8")) + geom_hex(bins=100)

#can use facet_wrap, but will need to discover ways to differentiate samples first
ggcyto(AlternateGS, subset="Tcells", aes(x="CD4", y="CD8")) + 
  geom_hex(bins=100) +
  facet_wrap(vars(GROUPNAME))

#that worked for all Tcells, so maybe I could subset this same graph across CD4+, CD4-CD8-, and CD8+ cells


