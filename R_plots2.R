#This R-code generates correlation plots for Uppsala County and Uppsala City.
#The version used is R 4.2.0.
library(rio)
library(ggplot2)
library(GGally)

data=import("C:/Users/ulfha881/PROJECTS/Tove/CRUSH/MyData/Corr_County.xlsx",col_names=F)
library(corrplot)
col <- colorRampPalette(rev(c("#BB4444", "#EE9988", "#FFFFFF", "#77AADD", "#4477AA")))
data$...1=NULL
colnames(data)=c("CNI","Women","Below 5",
                 "Non-EU","Single>65","Single parent","Moved in",
                 "Low educ.","Unemployed","Distance")
rownames(data)=c("CNI","Women","Below 5",
                 "Non-EU","Single>65","Single parent","Moved in",
                 "Low educ.","Unemployed","Distance")

pdf("C:/Users/ulfha881/PROJECTS/Tove/CRUSH/MyData/Corrplot.pdf", 
    width=26,height=13)
par(mfrow=c(1,2))
corrplot(as.matrix(data), method = "color", type = "upper", title="Uppsala County",cex.main=2.7,mar=c(0,0,2,0),
         col = col(200), tl.col = "black", tl.srt = 45, diag = F,tl.cex=1.4,cl.cex=1.4,tl.pos="td",font.main=1)
data=import("C:/Users/ulfha881/PROJECTS/Tove/CRUSH/MyData/Corr_City.xlsx",col_names=F)

library(corrplot)
col <- colorRampPalette(rev(c("#BB4444", "#EE9988", "#FFFFFF", "#77AADD", "#4477AA")))
data$...1=NULL
colnames(data)=c("CNI","Women","Below 5",
                 "Non-EU","Single>65","Single parent","Moved in",
                 "Low educ.","Unemployed","Distance")
rownames(data)=c("CNI","Women","Below 5",
                 "Non-EU","Single>65","Single parent","Moved in",
                 "Low educ.","Unemployed","Distance")

corrplot(as.matrix(data), method = "color", type = "upper", title="Uppsala City",mar=c(0,0,2,0),cex.main=2.7,
         col = col(200), tl.col = "black", tl.srt = 45, diag = F,tl.cex=1.4,cl.cex=1.4,tl.pos="td",font.main=1)
dev.off()    
#The .pdf-files are converted to .tif by online-converter (pdf2tiff.com)