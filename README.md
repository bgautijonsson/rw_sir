**This model is not suitable for prediction. It is meant for retrospective data analysis.**

The file `Make_RW_SIR.R` estimates the model using Stan. It takes as input a data frame with the following columns:

* `date`: Observation date
* `L`: New local cases
* `dR_dt`: New case recoveries
* `S`: Susceptible individuals
* `I`: Active cases

Users also specify the parameter `N`, the population of the area being modelled or the number of susceptible individuals at the start of the period.

The file `Make_Trend_Plot.R` then takes the saved model object and plots the time trend for $R_t$.


Read `Methods.pdf` for a short explanation of the model.