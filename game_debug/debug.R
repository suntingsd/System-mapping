
a <- read.csv("vwc.csv")

aa <- unlist(strsplit(a[,1]," "))[seq(1,4988,2)]

aai <- unique(aa)
aa1 <- a[,-1]

vwc <- c()
for(i in aai){
 vwc <- rbind(vwc,colMeans(aa1[which(aa==i),]))
}

vwc1 <- t(vwc)


Tran <- read.csv("Transpiration.csv")[1:6,-1]

dat <- list(vwc=vwc,Tran=Tran)

save(dat,file="dat.RData")

plot(NA,NA,xlim=c(0.5,6.5),ylim=c(0.1,0.5))
for(i in 1:97){
  lines(1:6,vwc[,i])
}



plot(NA,NA,xlim=c(0.5,6.5),ylim=c(1,250))
for(i in 1:97){
  lines(1:6,Tran[,i])
}
