### SIR Model with Second Order Random Walk for $R_t$

*This model is not suitable for prediction. It is meant for retrospective data analysis.*

The file `Make_RW_SIR.R` estimates the model using Stan. It takes as input a data frame with the following columns:

* `date`: Observation date
* `dI_dt`: New local cases
* `dR_dt`: New case recoveries
* `S`: Susceptible individuals
* `I`: Active cases

Users also specify the parameter `N`, the population of the area being modelled or the number of susceptible individuals at the start of the period.

The file `Make_Trend_Plot.R` then takes the saved model object and plots the time trend for $R_t$.

### Methods

Let $L_t$ and $R_t$ be the daily number of local cases and recovered cases. The model is then written thus

$$
L_t \sim \mathrm{NegBin}\left(\beta_t\cdot I_{t-1}\cdot\frac{S_{t-1}}{N}, \phi\right) \\
\ln(\beta_t) = \nu_t \\
\nu_t \sim \mathrm{Normal}\left(2\nu_{t - 1} - \nu_{t-2}, \sigma \right) \\
\nu_1 \sim \mathrm{Normal}(-4, 2), \quad
\nu_2 \sim \mathrm{Normal}(-4, 2) \\
\sigma \sim \mathrm{Exponential}(1) \\
\sqrt{\phi} \sim \mathrm{Normal}_+(0, 1)
$$

We model the recovery time using an exponential distribution, which is the same as modeling the number of recovered cases with a Poisson distribution.

$$
R_t \sim \mathrm{Poisson}\left(\gamma \cdot I_{t-1}\right) \\
\gamma \sim \mathrm{Exponential}(1)
$$

Having $\beta_t$ and $\gamma$ we can then calculate the effective reproductive ratio, $r_t$, as

$$
r_t = \frac{\beta_t}{\gamma}
$$