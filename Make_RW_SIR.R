library(rstan)
library(readr)

options(mc.cores = parallel::detectCores())
parallel:::setDefaultClusterOptions(setup_strategy = "sequential")
    
d <- read_csv("Data/iceland_data.csv")

# The first date must have at least one infected individual
d <- d[-1, ]

N_days <- nrow(d)

S <- d$S
I <- d$I
L <- d$L
dR_dt <- d$dR_dt
N <- d$N

stan_data <- list(
    N_days = N_days,
    N = N,
    S  = S,
    I = I,
    L = L,
    dR_dt = dR_dt
)


m <- stan(
    file = "Stan/RW_SIR.stan", 
    data  = stan_data, 
    chains = 4,
    iter = 2000, 
    warmup = 500,
    control = list(max_treedepth = 15),
    save_warmup = FALSE
)

cur_date <- max(d$date)

write_rds(m, paste0("Models/RW_SIR_", cur_date, ".rds"))




