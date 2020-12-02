
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
