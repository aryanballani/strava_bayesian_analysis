library(cmdstanr)

data <- read.csv2("./data/weekly_data.csv", header = TRUE, sep = ",")

weekly_mileage_obs <- as.numeric(data$weekly_mileage)
stan_data <- list(
  N = length(weekly_mileage_obs),
  y = ifelse(weekly_mileage_obs == 0, 0.01, weekly_mileage_obs)
)
mod <- cmdstan_model("./5_state_space_model.stan")
# run the sampler
fit <- mod$sample(
  data = stan_data,
  seed = 405,
  chains = 4,
  parallel_chains = 4,
  iter_warmup = 1000,
  iter_sampling = 1000
)
# extract posterior means for each week
colMeans(fit$draws("X", format = "matrix"))
# Posterior mean and 80% credible interval for predicted
X_next_draws <- fit$draws("X_next", format = "matrix")
mean(X_next_draws)
quantile(X_next_draws, c(0.1, 0.9))

log_joint = function(X_unconstrained, y) {
  N = length(y)
  X = plogis(X_unconstrained)
  
  # Guard against numerical issues
  if (any(!is.finite(X_unconstrained))) return(-Inf)
  if (any(X < 1e-10)) return(-Inf)
  
  log_prior = dnorm(X_unconstrained[1], 0, 1, log = TRUE)
  for (i in 2:N) {
    log_prior = log_prior + dnorm(X_unconstrained[i], X_unconstrained[i-1], 5, log = TRUE)
  }
  
  log_lik = sum(dgamma(y, shape = 50 * X, rate = 1, log = TRUE))
  
  return(log_prior + log_lik)
}

stationary_mcmc = function(joint, n_iterations) {
  initialization = forward()
  y = initialization$y
  if (n_iterations == 0) { 
    return(initialization$x)
  } else {
    current_x = initialization$x
    for (i in 1:n_iterations) {
      proposed_x = current_x + rnorm(length(y)) 
      log_ratio = joint(proposed_x, y) - joint(current_x, y) 
      if (is.finite(log_ratio) && log(runif(1)) < log_ratio) {
        current_x = proposed_x
      }
    }
    return(current_x)
  }
}

forward = function() {
  N = length(weekly_mileage_obs)
  X_unconstrained = numeric(N)
  X_unconstrained[1] = rnorm(1, 0, 1)
  for (i in 2:N) {
    X_unconstrained[i] = rnorm(1, X_unconstrained[i-1], 5)
  }
  X = plogis(X_unconstrained)
  y = rgamma(N, shape = 50 * X, rate = 1)
  return(list(x = X_unconstrained, y = y))
}

exact_invariance = function(joint) {
  forward_only = colMeans(plogis(replicate(1000, stationary_mcmc(joint, 0))))
  with_mcmc    = colMeans(plogis(replicate(1000, stationary_mcmc(joint, 200))))
  
  ks.test(forward_only, with_mcmc)
}

result <- exact_invariance(log_joint)
print(result)
