source("./simPPLe/simple.R")
source("./simPPLe/simpleUtils.R")
library(distr)
set.seed(42)

data <- read.csv2("./data/weekly_data.csv", header = TRUE, sep = ",")
weekly_mileage_obs <- as.numeric(data$weekly_mileage)

# =========== Modified SimplePPL ===========
# New Global: Store the log of the weight instead of the weight itself
log_weight <<- 0.0 

# Use observe(realization, distribution) for observed random variables
observe = function(realization, distribution) {
  # Change: Add the log-density instead of multiplying the raw density
  # d(distribution)(realization) returns the density; we take the log.
  log_weight <<- log_weight + d(distribution)(realization, log = TRUE)
}

# Revised Posterior to handle log-weights
posterior = function(ppl_function, number_of_iterations) {
  samples <- numeric(number_of_iterations)
  log_weights <- numeric(number_of_iterations)
  
  for (i in 1:number_of_iterations) {
    log_weight <<- 0.0  # Reset log weight to 0 (which is log(1))
    samples[i] <- ppl_function()
    log_weights[i] <- log_weight
  }
  
  # --- THE LOG-SUM-EXP TRICK ---
  # To avoid underflow when converting back to normal weights:
  # 1. Find the maximum log weight
  max_log_w <- max(log_weights)
  
  # 2. Subtract the max from all (shifts weights so the best one is 1.0)
  # 3. Exponentiate to get relative weights
  weights <- exp(log_weights - max_log_w)
  
  # 4. Compute weighted average
  return(sum(samples * weights) / sum(weights))
}
# =========== End of Modified SimplePPL ===========

scale <- 1
X <- Unif(0,1)

fitness_function = function() {
  # fitness = simulate(X)
  for (i in seq_along(weekly_mileage_obs)) {
    fitness = simulate(X)
    obs = max(weekly_mileage_obs[i], 0.01)
    observe(obs, Gammad(scale = scale, shape = 50*fitness))
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
    #cat(g_i, "\n")
    numerator = numerator + weight * g_i
    denominator = denominator + weight
    #cat(numerator, "\n")
    #cat(denominator, "\n")
  }
  return(numerator/denominator)
}

posterior(fitness_function, 10000)

