

load("dat.RData")
source("test_sup.R")

init.data <- ind_fit1(dat)


ode.fit <- game_fit(dat=init.data)



game_plot(mt=init.data$msm.T,mv=init.data$msm.V,nt=init.data$ntimes,ode_data=ode.fit$odee)


