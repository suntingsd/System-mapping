
ind_fit1 <- function(dat){
  
  data <- data.frame(tv=colMeans(t(dat$Tran)),vv=colMeans(t(dat$vwc)),times=1:6)
  
  model1 <- loess(vv~times,data=data,span=0.7)
  tp1 <- predict(model1, data.frame(times = seq(1, 6, 0.1)))
  
  model2 <- loess(data$tv~times,data=data,span=0.7)
  tp2 <- predict(model2, data.frame(times = seq(1, 6, 0.1)))
  
  nn <- dim(dat$Tran)[2]
  
  pdf("Figure1.pdf",width=10,height=4)
  par(fig=c(0,0.45,0,1),oma=c(4,4.5,0.5,0.5),mar=c(0,0,0,0))
  plot(NA,NA,pch=16,type="n",col="#757575",xlab=" ",ylab=" ",xlim=c(0.9,6.1),ylim=c(0.08,0.51),
       xaxt="n",yaxt="n",xaxs="i", yaxs="i")
  for(i in 1:nn){
    lines(1:6,dat$vwc[,i],col="#DBDBDB")
  }
  points(1:6,colMeans(t(dat$vwc)),cex=1.5,col="#5C5C5C")
  lines(seq(1, 6, 0.1),tp1,lwd=3,col="#FF4040")
  axis(1,at=1:6,labels=1:6,cex.axis=1.2,lwd=0.2)
  axis(2,at=seq(0.1,0.5,0.1),labels=seq(0.1,0.5,0.1),cex.axis=1.2,lwd=0.2,las=1)
  mtext("Time (Day)",1,cex=1.5,line=2.7)
  mtext("vwc",2,cex=1.5,line=2.7)
  mtext("A",3,cex=1.5,adj=0.1,line=-2)
  
  par(fig=c(0.55,1,0,1),oma=c(4,4.5,0.5,0.5),mar=c(0,0,0,0),new=TRUE)
  plot(NA,NA,pch=16,type="n",col="#757575",xlab=" ",ylab=" ",xlim=c(0.9,6.1),ylim=c(-10,261),
       xaxt="n",yaxt="n",xaxs="i", yaxs="i")
  for(i in 1:nn){
    lines(1:6,dat$Tran[,i],col="#DBDBDB")
  }
  points(1:6,colMeans(t(dat$Tran)),cex=1.5,col="#5C5C5C")
  lines(seq(1, 6, 0.1),tp2,lwd=3,col="#FF4040")
  axis(1,at=1:6,labels=1:6,cex.axis=1.2,lwd=0.2)
  axis(2,at=seq(0,250,50),labels=seq(0,250,50),cex.axis=1.2,lwd=0.2,las=1)
  mtext("Time (Day)",1,cex=1.5,line=2.7)
  mtext("Transpiration",2,cex=1.5,line=2.7)
  mtext("B",3,cex=1.5,adj=0.1,line=-2)
  dev.off()
  return(list(raw.T=dat$Tran,raw.V=dat$vwc,ntimes=seq(1, 6, 0.1),msm.T=tp1,msm.V=tp2))
}



smooth.optim <- function(times,para,y,nt=seq(1,6,length=150)){
  
  
  allpar <- c()
  smooth.d <- c()
  dsmooth.d <- c()
  for(i in 1:dim(y)[1]){
    L <- optim(para,smL,DS1=y[i,],times=times,method="BFGS")
    allpar <- rbind(allpar,c(L$par,L$value))
    smooth.d <- rbind(smooth.d,Legendre.model(nt,L$par))
    dsmooth.d <- rbind(dsmooth.d,dLegendre.model(nt,L$par))
  }
  
  list(allpar=allpar,smooth.d=smooth.d,dsmooth.d=dsmooth.d)
}

smL <- function(times,para,DS1){
  
  sum((DS1-Legendre.model(t=times,mu=para))^2)
}


Legendre.model <- function( t, mu, tmin=NULL, tmax=NULL )
{
  u <- -1;
  v <- 1;
  if (is.null(tmin)) tmin<-min(t);
  if (is.null(tmax)) tmax<-max(t);
  ti    <- u + ((v-u)*(t-tmin))/(tmax - tmin);
  np.order <- length(mu)-1;
  L <- mu[1] + ti*mu[2];
  if (np.order>=2)
    L <- L + 0.5*(3*ti*ti-1)* mu[3] ;
  if (np.order>=3)
    L <- L + 0.5*(5*ti^3-3*ti)*mu[4] ;
  if (np.order>=4)
    L <- L + 0.125*(35*ti^4-30*ti^2+3)* mu[5];
  if (np.order>=5)
    L <- L + 0.125*(63*ti^5-70*ti^3+15*ti)*mu[6];
  if (np.order>=6)
    L <- L + (1/16)*(231*ti^6-315*ti^4+105*ti^2-5)* mu[7];
  if (np.order>=7)
    L <- L + (1/16)*(429*ti^7-693*ti^5+315*ti^3-35*ti)* mu[8];
  if (np.order>=8)
    L <- L + (1/128)*(6435*ti^8-12012*ti^6+6930*ti^4-1260*ti^2+35)* mu[9];
  if (np.order>=9)
    L <- L + (1/128)*(12155*ti^9-25740*ti^7+18018*ti^5-4620*ti^3+315*ti)* mu[10];
  if (np.order>=10)
    L <- L + (1/256)*(46189*ti^10-109395*ti^8+90090*ti^6-30030*ti^4+3465*ti^2-63)* mu[11];
  if (np.order>=11)
  {
    for(r in 11:(np.order))
    {
      kk <- ifelse(r%%2==0, r/2, (r-1)/2);
      for (k in c(0:kk) )
      {
        L <- L + (-1)^k*factorial(2*r-2*k)/factorial(k)/factorial(r-k)/factorial(r-2*k)/(2^r)*ti^(r-2*k)*mu[r+1];
      }
    }
  }
  return(L);
}



game_fit <- function(dat){
  
  require(parallel)
  
  nt1 <- dat$ntimes
  t1 <- min(nt1)
  t2 <- max(nt1)
  nt2 <- seq(t1,t2,length=30)
  mm <- rbind(dat$msm.T,log(dat$msm.V))
  
  stage2 <- smooth.optim(times=nt1,para=rep(.1,5),y=mm,nt=nt2)
  
  connect <- matrix(c(1,1,1,1),nrow=2)
  TSS.odee <- optim.parallel(connect=connect,effect=t(stage2$smooth.d),
                             n.cores=1,proc=ode.optim,order=6,times=nt2,nstep=29)
  ret <- list(stage2=stage2,odee=TSS.odee)
  return(ret)
}

game_plot <- function(mt,mv,nt,ode_data){
  
  
  pdf("Figure2.pdf",width=10,height=4)
  par(fig=c(0,0.45,0,1),oma=c(4,4.5,0.5,0.5),mar=c(0,0,0,0))
  plot(NA,NA,pch=16,type="n",col="#757575",xlab=" ",ylab=" ",xlim=c(0.9,6.1),ylim=c(-0.12,0.51),
       xaxt="n",yaxt="n",xaxs="i", yaxs="i")
  lines(nt,mt,col="#EE7600",lwd=3)
  lines(seq(1,6,length=30),ode_data[[1]][,1]+mt[1],col="#EE7600",lty=2,lwd=2.5)
  lines(seq(1,6,length=30),ode_data[[1]][,2],col="#FFB90F",lty=3,lwd=2.5)
  abline(h=0)
  axis(1,at=1:6,labels=1:6,cex.axis=1.2,lwd=0.2)
  axis(2,at=seq(-0.1,0.5,0.1),labels=seq(-0.1,0.5,0.1),cex.axis=1.2,lwd=0.2,las=1)
  mtext("Time (Day)",1,cex=1.5,line=2.7)
  mtext("vwc",2,cex=1.5,line=2.7)
  mtext("A",3,cex=1.5,adj=0.1,line=-2)
  
  par(fig=c(0.55,1,0,1),oma=c(4,4.5,0.5,0.5),mar=c(0,0,0,0),new=TRUE)
  plot(NA,NA,pch=16,type="n",col="#757575",xlab=" ",ylab=" ",xlim=c(0.9,6.1),ylim=c(-1.2,6.2),
       xaxt="n",yaxt="n",xaxs="i", yaxs="i")
  lines(nt,log(mv),col="#FFB90F",lwd=3)
  lines(seq(1,6,length=30),ode_data[[2]][,1]+log(mv[1]),col="#FFB90F",lty=2,lwd=2.5)
  lines(seq(1,6,length=30),ode_data[[2]][,2],col="#EE7600",lty=3,lwd=2.5)
  axis(1,at=1:6,labels=1:6,cex.axis=1.2,lwd=0.2)
  axis(2,at=seq(-1,6,1),labels=seq(-1,6,1),cex.axis=1.2,lwd=0.2,las=1)
  abline(h=0)
  mtext("Time (Day)",1,cex=1.5,line=2.7)
  mtext("log(Transpiration)",2,cex=1.5,line=2.7)
  mtext("B",3,cex=1.5,adj=0.1,line=-2)
  dev.off()
  
}



####The first order derivative for Legendre model
dLegendre.model <- function( t, mu, tmin=NULL, tmax=NULL )
{
  u <- -1;
  v <- 1;
  if (is.null(tmin)) tmin<-min(t);
  if (is.null(tmax)) tmax<-max(t);
  ti    <- u + ((v-u)*(t-tmin))/(tmax - tmin);
  np.order <- length(mu)-1;
  L <- mu[1]*0 + 1*mu[2];
  if (np.order>=2)
    L <- L + 0.5 * (6 * ti)* mu[3] ;
  if (np.order>=3)
    L <- L +0.5 * (15 * ti ^ 2 - 3)*mu[4] ;
  if (np.order>=4)
    L <- L + 0.125 * (35 * 4 * ti ^ 3 - 60 * ti)* mu[5];
  if (np.order>=5)
    L <- L + 0.125 * (63 * 5 * ti ^ 4 - 210 * ti ^ 2 + 15)*mu[6];
  if (np.order>=6)
    L <- L + (1 / 16) * (231 * 6 * ti ^ 5 - 315 * 4 * ti ^ 3 + 105 * 2 *ti)* mu[7];
  if (np.order>=7)
    L <- L + (1 / 16) * (429 * 7 * ti ^ 6 - 693 * 5 * ti ^ 4 + 315 * 3 *ti ^ 2 - 35)* mu[8];
  return(L);
}

####Legendre model
Legendre.model <- function( t, mu, tmin=NULL, tmax=NULL )
{
  u <- -1;
  v <- 1;
  if (is.null(tmin)) tmin<-min(t);
  if (is.null(tmax)) tmax<-max(t);
  ti    <- u + ((v-u)*(t-tmin))/(tmax - tmin);
  np.order <- length(mu)-1;
  L <- mu[1] + ti*mu[2];
  if (np.order>=2)
    L <- L + 0.5*(3*ti*ti-1)* mu[3] ;
  if (np.order>=3)
    L <- L + 0.5*(5*ti^3-3*ti)*mu[4] ;
  if (np.order>=4)
    L <- L + 0.125*(35*ti^4-30*ti^2+3)* mu[5];
  if (np.order>=5)
    L <- L + 0.125*(63*ti^5-70*ti^3+15*ti)*mu[6];
  if (np.order>=6)
    L <- L + (1/16)*(231*ti^6-315*ti^4+105*ti^2-5)* mu[7];
  if (np.order>=7)
    L <- L + (1/16)*(429*ti^7-693*ti^5+315*ti^3-35*ti)* mu[8];
  if (np.order>=8)
    L <- L + (1/128)*(6435*ti^8-12012*ti^6+6930*ti^4-1260*ti^2+35)* mu[9];
  if (np.order>=9)
    L <- L + (1/128)*(12155*ti^9-25740*ti^7+18018*ti^5-4620*ti^3+315*ti)* mu[10];
  if (np.order>=10)
    L <- L + (1/256)*(46189*ti^10-109395*ti^8+90090*ti^6-30030*ti^4+3465*ti^2-63)* mu[11];
  if (np.order>=11)
  {
    for(r in 11:(np.order))
    {
      kk <- ifelse(r%%2==0, r/2, (r-1)/2);
      for (k in c(0:kk) )
      {
        L <- L + (-1)^k*factorial(2*r-2*k)/factorial(k)/factorial(r-k)/factorial(r-2*k)/(2^r)*ti^(r-2*k)*mu[r+1];
      }
    }
  }
  return(L);
}



######## nonparameter fit for Legendre model
smooth.optim <- function(times,para,y,nt=seq(1,6,length=150)){
  
  
  allpar <- c()
  smooth.d <- c()
  dsmooth.d <- c()
  for(i in 1:dim(y)[1]){
    L <- optim(para,smL,DS1=y[i,],times=times,method="BFGS")
    allpar <- rbind(allpar,c(L$par,L$value))
    smooth.d <- rbind(smooth.d,Legendre.model(nt,L$par))
    dsmooth.d <- rbind(dsmooth.d,dLegendre.model(nt,L$par))
  }
  
  list(allpar=allpar,smooth.d=smooth.d,dsmooth.d=dsmooth.d)
}

####nonparameter ODE by RK4
LMall <- function(NX,nt,nstep=30,order){
  
  stp <- (max(nt)-min(nt))/nstep
  res <- c()
  for(j in 1:nstep){
    
    tg1 <- Legendre.model11((j-1)*stp+1,np.order=order-1,tmin=min(nt), tmax=max(nt))
    tg2 <- Legendre.model11(j*stp/2+1,np.order=order-1,tmin=min(nt), tmax=max(nt))
    tg3 <- Legendre.model11(j*stp/2+1,np.order=order-1,tmin=min(nt), tmax=max(nt))
    tg4 <- Legendre.model11(j*stp+1,np.order=order-1,tmin=min(nt), tmax=max(nt))
    tmp1 <- rbind(tg1,tg2,tg3,tg4)
    res <- rbind(res,tmp1)
  }
  res
}

#### parameter estimate for ODE
fitPKM <- function(para,NG,self,nconnect,nt,order,nstep,LL){
  
  odes <- ode.sovle.ind(NG,para,nconnect,nt,order,nstep,LL)
  #index <- which(nconnect==1)
  #index1 <- which(index==self)
  
  #if(length(index)>1){
  #  if(sum(rowSums(as.matrix(odes[,-index1])))>0)
  #    return(50)
  #}else{
  sum((NG[,self]-(rowSums(odes)+NG[1,self]))^2)
  #}
}


####nonparameter ODE by RK4
ode.sovle.ind <- function(NG,fitpar,nconnect,nt,order,nstep,LL){
  
  stp <- (max(nt)-min(nt))/nstep
  index <- which(nconnect==1)
  
  ind.par <- matrix(fitpar[1:(length(index)*(order-1))],ncol=order-1,byrow=T)
  allrep <- matrix(rep(0,length(index)),nrow=1)
  nn <- 1
  for(j in 1:nstep){
    tg1 <- (rowSums(t(apply(ind.par,1,"*",LL[nn,])))*NG[j,index])
    tg2 <- (rowSums(t(apply(ind.par,1,"*",LL[nn+1,])))*NG[j,index])
    tg3 <- (rowSums(t(apply(ind.par,1,"*",LL[nn+2,])))*NG[j,index])
    tg4 <- (rowSums(t(apply(ind.par,1,"*",LL[nn+3,])))*NG[j,index])
    tmp <- allrep[j,] +stp*(tg1+2*tg2+2*tg3+tg4)/6
    allrep <- rbind(allrep,tmp)
    nn <- nn + 4
  }
  allrep
}




#####parallel estimate for unknown
optim.parallel <- function(connect,effect,n.cores,proc,order,times,nstep){
  
  diag(connect) <- 1
  nt1 <- min(times)
  nt2 <- max(times)
  
  LL <- LMall(NX=1,nt=seq(nt1,nt2,(nt2-nt1)/nstep),nstep=nstep,order=order)
  
  nx <- dim(effect)[2]
  
  grp <- floor(nx/n.cores)
  grp.i <- c()
  if(n.cores==1){
    grp.i <- c(grp.i,rep(1,nx))
  }else{
    for(ii in 1:n.cores){
      if(ii==n.cores){
        grp.i <- c(grp.i,rep(ii,nx-grp*(ii-1)))
      }else{
        grp.i <- c(grp.i,rep(ii,grp))
      }
    }
  }
  
  grp.ii <- unique(grp.i)
  
  res.list <- mclapply(grp.ii, function(i)
  {
    y.c <- 	which(grp.i==i)
    A <- sapply(y.c, proc, connect=connect,effect=effect,LL=LL,nstep=nstep,order=order,times=times);
    return (unlist(A));
  }, mc.cores=n.cores )
  
  res1 <- do.call("c", res.list)
  res2 <- parallel.data.optim(res1,connect,times)
  return(res2)
}

parallel.data.optim <- function(rd,nm,ntt){
  
  nrd <- matrix(rd,nrow=length(ntt))
  nn <- dim(nm)[1]
  ki <- 0
  allist <- list()
  for(i in 1:nn){
    iii <- (which(nm[i,]==1))
    iiil <- length(iii)
    tmp.d <- nrd[,(ki+1):(ki+iiil)]
    if(is.matrix(tmp.d)){
      colnames(tmp.d) <- iii
    }else{
      names(tmp.d) <- iii
    }
    
    allist[[i]] <- tmp.d
    ki <- ki + iiil
  }
  
  return(allist)
}


ode.optim <- function(y.c,connect,effect,LL,nstep,order,times){
  
  indexx <- which(connect[y.c,]==1)
  para <- rep(-0.0001,length(indexx)*(order-1))
  res <- optim(para,fitPKM,NG=(effect),self=y.c,nconnect=connect[y.c,],nt=times,order=order,nstep=nstep,
               LL=LL,method="BFGS",control=list(maxit=2000,trace=T))
  cat("Gene=",y.c," ",res$value,"\n")
  A <- ode.sovle.ind(NG=(effect),res$par,nconnect=connect[y.c,],nt=times,order=order,nstep=nstep,LL=LL)
  return(A)
}


Legendre.model11 <- function(t, np.order,tmin = NULL, tmax = NULL)
{
  u <- -1;
  v <- 1;
  if (is.null(tmin))
    tmin <- min(t);
  if (is.null(tmax))
    tmax <- max(t);
  ti    <- u + ((v - u) * (t - tmin)) / (tmax - tmin);
  L <- rep(NA,np.order)
  L[1] <- 1;
  if (np.order >= 2)
    L[2] <- 0.5 * (6 * ti) 
  if (np.order >= 3)
    L[3] <- 0.5 * (15 * ti ^ 2 - 3) 
  if (np.order >= 4)
    L[4] <-  0.125 * (35 * 4 * ti ^ 3 - 60 * ti) 
  if (np.order >= 5)
    L[5] <-  0.125 * (63 * 5 * ti ^ 4 - 210 * ti ^ 2 + 15)
  if (np.order >= 6)
    L[6] <-(1 / 16) * (231 * 6 * ti ^ 5 - 315 * 4 * ti ^ 3 + 105 * 2 *
                         ti) 
  if (np.order >= 7)
    L[7] <- (1 / 16) * (429 * 7 * ti ^ 6 - 693 * 5 * ti ^ 4 + 315 * 3 *
                          ti ^ 2 - 35)
  return(L);
}
