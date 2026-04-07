source("./simPPLe/simple.R")
source("./simPPLe/simpleUtils.R")
library(distr)
data <- read.csv2("./data/weekly_data_naive.csv", header = TRUE, sep = ",")
weekly_mileage_obs <- as.numeric(filter(data, data$weekly_mileage>1)$weekly_mileage)
scale <- 0.5
X <- Unif(0,1)
fitness_function = function() {
  #fitness = simulate(X)
  for (i in seq_along(weekly_mileage_obs)) {
    fitness = simulate(X)
    observe(weekly_mileage_obs[i], Gammad(scale = scale, shape = 100*fitness))
  }
  pred = simulate(X)
  return(pred)
}
posterior = function(ppl_function, number_of_iterations) {
  numerator = 0.0
  denominator = 0.0
  for (i in 1:number_of_iterations) {
    weight <<- 1.0
    g_i = ppl_function()
    cat(g_i, "\n")
    numerator = numerator + weight * g_i
    denominator = denominator + weight
    cat(numerator, "\n")
    cat(denominator, "\n")
  }
  return(numerator/denominator)
}
posterior(fitness_function, 10)
