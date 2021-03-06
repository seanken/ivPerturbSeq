source("PertLM.R")
source("WGCNA.Get.Eigen.R")
source("BatchSample.v2.R")

library(Seurat)


TestWGCNA<-function(seur,tab,ref="GFP",form=Cluser1~perturbation+batch+nGene,maxCells=0,seed=1,numRep=1000,getScore=F,minPert=10,plotIt=F)
{

print("Pert only")
print(length(seur@ident))
seur=SubsetData(seur,names(seur@ident)[!is.na(seur@meta.data$perturbation)])
print(length(seur@ident))

mods<-unique(tab[,1])

ret=list()

scores<-list()

for(i in mods)
{
print(i)

print("Subset")
tab_cur=tab[tab[,1]==i,]

cur<-SubsetData(seur,WhichCells(seur,tab_cur[1,"CellType"]))

print(length(cur@ident))

print("Make list")

genes<-as.character(tab_cur[,"Gene"])

lst<-list()
lst[["Genes"]]=genes

print("Get Module")
#cur<-AddModuleScore(cur,lst)
cur<-getEigen(cur,lst[[1]])

if(plotIt)
{
FeaturePlot(cur,"Cluster1")
}

if(maxCells>0)
{
set.seed(seed)
print("Downsample!")
lst<-table(cur@meta.data$perturbation)
maxCells=2*median(as.numeric(lst))
print(maxCells)
cur<-batchSample(cur,total=maxCells,maxPerc=1.0)
}

print("Perform DE")
cur@meta.data["nGene"]=scale(cur@meta.data[,"nGene"])
cur@meta.data["Xist"]=scale(cur@data["Xist",])

mrk<-lm.pert(cur@meta.data,form,useBatch=T,dep_var = "Cluster1",ref = ref,numRep=numRep,minPert=minPert)


ret[[i]]=mrk
scores[[i]]=cur@meta.data
}
if(getScore)
{
return(scores)
}
return(ret)

}


drawResults<-function(out,meanCenter=F,centerBy="",ref="GFP")
{
for(i in names(out)){out[[i]]["Module"]=i;out[[i]]=add_row(out[[i]],perturbation=ref,Module=i,Effect_Size=0);if(meanCenter){out[[i]]["Effect_Size"]=out[[i]][,"Effect_Size"]-mean(out[[i]][,"Effect_Size"])}}

toPlot=c()


for(i in out){toPlot=rbind(toPlot,i)}

p=ggplot(toPlot,aes(x=Module,y=perturbation,fill=Effect_Size))+geom_tile()+theme(axis.text.x = element_text(angle = 90, hjust = 1))+scale_fill_gradient2(low="blue",high="red",mid="white")

return(p)

}


