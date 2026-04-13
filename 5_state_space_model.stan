// The input data is a vector 'y' of length 'N'.
data {
  int<lower=0> N;
  vector[N] y;
}

// The parameters accepted by the model. Our model
// accepts two parameters 'mu' and 'sigma'.
parameters {
  vector[N] X_unconstrained;
}

transformed parameters {
  vector<lower=0, upper=1>[N] X = inv_logit(X_unconstrained);
}

// The model to be estimated. We model the output
// 'y' to be normally distributed with mean 'mu'
// and standard deviation 'sigma'.
model {
  X_unconstrained[1] ~ normal(0,1);
  y[1] ~ gamma(50 * X[1], 1);
  for (i in 2:N) {
    X_unconstrained[i] ~ normal(X_unconstrained[i-1], 1);
    y[i] ~ gamma(50 * X[i], 1);
  }
}

generated quantities {
  real X_next_unconstrained = normal_rng(X_unconstrained[N], 1);
  real<lower=0, upper=1> X_next = inv_logit(X_next_unconstrained);
}

