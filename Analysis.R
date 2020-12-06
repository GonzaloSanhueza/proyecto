
# Cargar Paquetes
library(tidyverse)
library(tidymodels)
theme_set(theme_dark())

# Cargar Data
data(credit_data, package = "modeldata")
credit_data
credit_df <- credit_data %>% 
  as_tibble() %>% 
  janitor::clean_names()
credit_df

# Exploración
skimr::skim(credit_df)

plot_income_job <- credit_df %>% 
  filter(!is.na(income)) %>% 
  ggplot(mapping = aes(x = job, y = income)) +
  geom_boxplot(outlier.color = NA, fill = "salmon3", color = "grey90") +
  geom_jitter(alpha = 0.1, width = 0.2, shape = 16, color = "steelblue", size = 2) +
  scale_y_log10() + 
  labs(title = "Comparación Tipo de Trabajo vs Ingresos", 
       x = "Tipo de Trabajo", y = "Ingresos Diarios") +
  theme(plot.title = element_text(hjust = 0.5, size = 20, color = "grey90"), 
        axis.title = element_text(size = 16, color = "grey90"),
        axis.text = element_text(size = 12, color = "grey90"),
        panel.background = element_rect(fill = "grey10"),
        plot.background = element_rect(fill = "grey10")) +
  scale_x_discrete(labels = c("Fijo", "Independiente", "Otros", "Partime"))

ggsave(plot = plot_income_job, filename = "plots/plot_income_job.png", 
       type = "cairo", width = 9, height = 5, dpi = 500)

credit_numeric <- credit_df %>% 
  mutate(status = ifelse(status == "good", 1, 0)) %>% 
  select_if(is.numeric) %>% 
  na.omit()




cor(credit_numeric[,1], credit_numeric[,2])


ncol(credit_numeric)

for(i in 1:ncol(credit_numeric)){
  print(cor(credit_numeric[,"age"], credit_numeric[,i]), method = "pearson")
}

cor.test(credit_numeric$status, credit_numeric$seniority)

cor(credit_numeric)

library(ggpubr)
# install.packages("ggcorrplot")
library(ggcorrplot)

ggcorrplot(cor(credit_numeric), hc.order = T, type = "lower", lab = T)


ggplot(data = credit_numeric, mapping = aes(x = seniority, y = amount, color = status)) + 
  geom_point() +
  scale_y_log10()




##Machine Learning

credit_modeling <- credit_df %>% 
  na.omit() 

set.seed(2020)

credit_split <- initial_split(credit_modeling, prop = .75, strata = status)
credit_train <- training(credit_split)
credit_test <- testing(credit_split)

logistic_spec <- logistic_reg() %>% 
  set_mode("classification") %>% 
  set_engine("glm")

logistic_rec <- recipe(status ~ ., data = credit_train) %>% 
  step_dummy(all_nominal(), - status)


logistic_wf <- workflow() %>% 
  add_model(logistic_spec) %>% 
  add_recipe(logistic_rec)


logistic_fit <- logistic_wf %>% 
  fit(data = credit_train)

logistic_fit %>% 
  predict(new_data = credit_train, type = "prob") %>% 
  bind_cols(credit_train) %>% 
  select(1:3) %>% 
  roc_curve(truth = status, .pred_bad) %>% 
  ggplot(mapping = aes(x = 1 - specificity, y = sensitivity)) +
  geom_line() +
  geom_abline(linetype = "dashed") + 
  geom_point(data = mean_threshold, shape = "X", size = 3, color = "red")


mean_threshold <- logistic_fit %>% 
  predict(new_data = credit_train, type = "prob") %>% 
  bind_cols(credit_train) %>% 
  select(1:3) %>% 
  roc_curve(truth = status, .pred_bad) %>% 
  filter(.threshold >= .5) %>% 
  slice_min(.threshold, n = 1)


logistic_fit %>% 
  predict(new_data = credit_train, type = "prob") %>% 
  bind_cols(credit_train) %>% 
  select(1:3) %>% 
  mutate(pred = ifelse(.pred_good >= 0.6, "good", "bad"), 
         pred = factor(pred, levels = c("bad", "good"))) %>% 
  # accuracy(truth = status, pred)
  # specificity(truth = status, pred)
  # sensitivity(truth = status, pred)
count(status, pred, order = T)


logistic_fit %>% 
  predict(new_data = credit_test) %>% 
  bind_cols(credit_test) %>% 
  # accuracy(truth = status, .pred_class)
  # specificity(truth = status, .pred_class)
sensitivity(truth = status, .pred_class)

install.packages(c("ROSE", "themis"))

# Mejorando el modelo por medio del tratamiento al desbalance de clases

library(themis)

logistic_rec_upsample <- recipe(status ~ ., data = credit_train) %>% 
  step_dummy(all_nominal(), -all_outcomes()) %>% 
  step_upsample(status, skip = T) %>% 
  step_center(all_numeric()) %>% 
  step_scale(all_numeric())

logistic_fit_up <- logistic_wf %>% 
  update_recipe(logistic_rec_upsample) %>% 
  fit(data = credit_train)

logistic_fit_up %>%
  predict(new_data = credit_test) %>%
  bind_cols(credit_test) %>%
  accuracy(truth = status, .pred_class)
  # specificity(truth = status, .pred_class)
# sensitivity(truth = status, .pred_class)
