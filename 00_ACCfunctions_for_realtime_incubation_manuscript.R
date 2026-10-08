#**********************************************************************************************************************************
#**********************************************************************************************************************************

# Project: Monitoring Incubation 
# Date: December 2026
# Author: Anonymous

#**********************************************************************************************************************************
#**********************************************************************************************************************************

# Function to add burst and index column to acc data
addBurst <- function(x) {
  #calculate the difference between two consecutive time points
  x <- mutate(x,lagtime=timestamp-lag(timestamp))
  
  #Following commands create a variable burst which repeats value for each unique burst
  lagtime=abs(x$lagtime)
  lagtime[is.na(lagtime)] <- 6 
  burststart = c(6,lagtime[-1])>5 
  burst = rep(0,dim(x)[1])
  burst2 = burst+burststart
  burst3 = cumsum(burst2)
  
  #creates an index within each burst 1:length(burst)
  runlen = rle(burst3)$lengths
  index = unlist(apply(matrix(runlen,length(runlen),1),1,seq,from=1,by=1))
  x$burst=burst3
  x$index=index
  return(x)
}







