library(scales)
library(tidybayes)
library(tidyverse)
library(rstan)
library(lubridate)
library(cowplot)


theme_set(theme_classic(base_size = 12) + 
              # background_grid(minor = "none", major = "none") +
              theme(legend.position = "none"))

d <- read_csv("Data/iceland_data.csv")

model_date <- max(d$date)

m <- read_rds(paste0("Models/RW_SIR_", model_date, ".rds"))

plot_dat <- spread_draws(m, log_beta[day], slope_log_beta[day], r[day], phi) %>% 
    ungroup %>% 
    mutate(date = min(d$date) + day + 1) %>% 
    inner_join(d %>% dplyr::select(date, I, S, N), by = "date") %>% 
    mutate(new_cases = rnbinom(n(), mu = exp(log_beta) * I * S / N, size = phi)) %>% 
    select(-phi, -S, -I, -N, -log_beta) %>% 
    mutate(slope_log_beta = exp(slope_log_beta) - 1) %>% 
    pivot_longer(c(-.iteration, -.chain, -.draw, -day, -date), names_to = ".variable", values_to = ".value") %>%  
    na.omit %>% 
    group_by(date, .variable) %>% 
    summarise(estimate = median(.value),
              lower_50 = quantile(.value, .25),
              upper_50 = quantile(.value, .75),
              lower_95 = quantile(.value, .025),
              upper_95 = quantile(.value, .975)) %>% 
    ungroup %>% 
    pivot_longer(c(contains("lower"), contains("upper")), 
                 names_to = c("which", "quantile"), 
                 names_pattern = c("(^.{5})_([0-9]{2})"), values_to = "value") %>% 
    pivot_wider(names_from = which, values_from = value) %>% 
    mutate(.variable = fct_recode(.variable,
                                  "local_cases" = "new_cases",
                                  "Rt" = "r",
                                  "Perc_Change_Rt" = "slope_log_beta"),
           .variable = fct_relevel(.variable, "local_cases", "Rt", "Perc_Change_Rt"),
           vline = case_when(.variable == "Perc_Change_Rt" ~ 0,
                             .variable == "Rt" ~ 1,
                             TRUE ~ NA_real_))


p1 <- plot_dat %>%
    filter(.variable == "local_cases") %>% 
    ggplot(aes(date, estimate, ymin = lower, ymax = upper)) +
    geom_hline(aes(yintercept = vline), lty = 1, col = "grey50", alpha = 0.6) +
    geom_ribbon(aes(alpha = quantile)) +
    geom_line() +
    geom_point(data = d %>% 
                   select(date, dI_dt) %>% 
                   pivot_longer(c(dI_dt), 
                       names_to = ".variable",
                       values_to = "estimate") %>% 
                   mutate(.variable = as_factor(.variable)),
               aes(x = date, y = estimate), inherit.aes = F) +
    scale_alpha_manual(values = c(0.4, 0.3)) +
    scale_x_date(date_breaks = "month",
                 date_labels = "%d. %B",
                 expand = expansion(mult = 0.02),
                 guide = guide_axis(n.dodge = 1)) +
    scale_y_continuous(expand = expansion(mult = 0.02),
                       breaks = pretty_breaks(7)) +
    ggtitle(label = "Daily new local cases", subtitle = "Posterior median, 50% and 95% prediction intervals") +
    theme(axis.title = element_blank(),
          axis.text.x = element_blank(), 
          legend.position = "none",
          plot.margin = margin(5, 5, 5, 12)) +
    background_grid(major = "none", minor = "none")


p2 <- plot_dat %>%
    filter(.variable == "Rt") %>% 
    ggplot(aes(date, estimate, ymin = lower, ymax = upper)) +
    geom_hline(aes(yintercept = vline), lty = 1, col = "grey50", alpha = 0.6) +
    geom_ribbon(aes(alpha = quantile)) +
    geom_line() +
    scale_alpha_manual(values = c(0.4, 0.3)) +
    scale_x_date(date_breaks = "month",
                 date_labels = "%d. %B",
                 expand = expansion(mult = 0.02),
                 guide = guide_axis(n.dodge = 1),
                 limits = c(ymd("2020-02-29", NA))) +
    scale_y_continuous(expand = expansion(mult = 0.02),
                       breaks = pretty_breaks(7)) +
    ggtitle(label = latex2exp::TeX("$R_{t}$")) +
    theme(axis.title = element_blank(),
          axis.text.x = element_blank(), 
          legend.position = "none",
          plot.margin = margin(5, 5, 5, 16)) +
    background_grid(major = "none", minor = "none")


p3 <- plot_dat %>%
    filter(.variable == "Perc_Change_Rt") %>% 
    ggplot(aes(date, estimate, ymin = lower, ymax = upper)) +
    geom_hline(aes(yintercept = vline), lty = 1, col = "grey50", alpha = 0.6) +
    geom_ribbon(aes(alpha = quantile)) +
    geom_line() +
    scale_alpha_manual(values = c(0.4, 0.3)) +
    scale_x_date(breaks = "month",
                 date_labels = "%d. %B",
                 expand = expansion(mult = 0.02),
                 guide = guide_axis(n.dodge = 1),
                 limits = c(ymd("2020-02-29", NA))) +
    scale_y_continuous(expand = expansion(mult = 0.02),
                       breaks = pretty_breaks(7),
                       labels = label_percent()) +
    ggtitle(label = latex2exp::TeX("Proportional daily change in $R_{t}$")) +
    theme(axis.title = element_blank(),
          axis.text.x = element_text(size = 10), 
          legend.position = "none",
          plot.margin = margin(5, 5, 5, 5)) +
    background_grid(major = "none", minor = "none")

plot_grid(p1, p2, p3, ncol = 1) +
    ggsave("Figures/Log_Beta_Iceland.png", width = 1.4 * 5, height = 5, scale = 2,
           device = "png")

    
    

