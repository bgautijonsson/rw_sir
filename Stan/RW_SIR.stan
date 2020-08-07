data {
  int<lower = 0> N_days;
  
  vector<lower = 0>[N_days] N;
  vector<lower = 0>[N_days] S;
  vector<lower = 0>[N_days] I;
  
  int<lower = 0> dI_dt[N_days];
  int<lower = 0> dR_dt[N_days];
}

transformed data {
  vector[N_days] log_S = log(S);
  vector[N_days] log_I = log(I);
  vector[N_days] log_N = log(N);
}


parameters {
  // Stan parametrises the negative binomial with var(x) = mu + mu^2/phi
  // so we define and put priors on the inverse of sqrt(phi).
  real<lower = 0> phi_inv_sqrt;
  
  real<lower = 0> sigma_beta;
  real<lower = 0> gamma;
  
  real log_beta1;
  real log_beta2;
  vector[N_days - 2] z;
} 

transformed parameters {
  vector[N_days] log_beta;
  vector<lower = 0>[N_days] beta;
  real<lower = 0> phi = inv(square(phi_inv_sqrt));
  real log_gamma = log(gamma);

  log_beta[1] = log_beta1;
  log_beta[2] = log_beta2;
  
  // If X ~ Normal(mu, sigma), the non-centered parametrization defines
  // X = mu + Z * sigma, where Z ~ Normal(0, 1)
  for (t in 3:N_days) {
    log_beta[t] = 2 * log_beta[t - 1] - log_beta[t - 2] + sigma_beta * z[t - 2];
  }
  
  beta = exp(log_beta);
}

model {
  
  log_beta1 ~ normal(-4, 2);
  log_beta2 ~ normal(-4, 2);
  sigma_beta ~ exponential(1);
  z ~ std_normal();
  
  
  gamma ~ exponential(1);
  
  
  phi_inv_sqrt ~ std_normal();
  
  dI_dt ~ neg_binomial_2_log(log_beta + log_I + log_S - log_N, phi);
  dR_dt ~ poisson_log(log_gamma + log_I);
  
  
}

generated quantities {
  real<lower = 0> recovery_period = inv(gamma);
  vector<lower = 0>[N_days] r = beta * recovery_period;
  vector[N_days - 1] slope_log_beta = log_beta[2:N_days] - log_beta[1:(N_days - 1)];
}



