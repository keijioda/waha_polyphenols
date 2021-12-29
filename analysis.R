
# WAHA polyphenols study

# GitHub
browseURL("https://github.com/keijioda/waha_polyphenols")

# Required packages
pacs <- c("tidyverse", "haven", "janitor", "readxl", "tableone")
sapply(pacs, require, character.only = TRUE)

# Read functions
source("functions.R")

# Read data ---------------------------------------------------------------
# Will be using only LLU data -- make sure to subset for id >= 5000

zipfile <- "./data/Dietary Polyphenol Lipid and Inflammation files.zip"

lipid_file <- "BDLab_BCNLLU1709lipids.sav"
inflm_file <- "WAHA_ BD_Cytokines_BCN_LLU Inflammation.sav"
diet_file  <- "waha-recalls-per-recalls-overlapping-foodgroups-with-pOH.csv"
# diet_file  <- "waha-recalls-per-subject-overlapping-foodgroups-with-pOH.csv"
body_file  <- "Table1Data.xlsx"

source("dataprep.R")

# lipid data --------------------------------------------------------------
# n = 369
dim(lipid)
n_distinct(lipid$patient_id)

names(lipid)

# Note that 13 subjects were not assigned to any group
table(lipid$assigned_group, useNA = "ifany")

# Hemoglobin A1c values are all missing
lipid %>% 
  select(contains("hb")) %>% 
  summary()

# Select variables and rename
lipid2 <- lipid %>% 
  select(-contains("hb"), -total_cholesterol1, -triglycerides1) %>%
  rename(TC_0 = total_cholesterol,
         TC_2 = total_cholesterol2,
         Trig_0 = triglycerides,
         Trig_2 = triglycerides2,
         VLDL_0 = vldl_c_b,
         VLDL_2 = vldl_c_f,
         LDL_0 = ldl_c_b,
         LDL_2 = ldl_c_f,
         HDL_0 = hdl_c_b,
         HDL_2 = hdl_c_f)

names(lipid2)

# inflammatory marker data ------------------------------------------------
# n = 371
dim(inflm)
n_distinct(inflm$patient_id)

names(inflm)
table(inflm$assigned_group, useNA = "ifany")

inflm %>% 
  select(patient_id, lipid_lowering:ezetimibe)

inflm %>% 
  select(patient_id, lipid_lowering:ezetimibe) %>% 
  filter(lipid_lowering != statin)

# Rename variables
inflm2 <- inflm %>% 
  rename(hsCRP_0 = high_sensitivity_crp,
         hsCRP_2 = high_sensitivity_crp2,
         IL1_0 = il_1ss_1,
         IL1_2 = il_1ss_2,
         IL6_0 = il_6_1,
         IL6_2 = il_6_2,
         TNFa_0 = tnf_a_1,
         TNFa_2 = tnf_a_2) %>% 
  select(-high_sensitivity_crp1)

# Check treatment group and demographics
inflm2 %>% 
  select(patient_id, assigned_group, gender, age)

inflm2 %>% 
  select(starts_with("hs"), starts_with("IL"), starts_with("TNF"))

# Merge lipid and inflammation data, exlucding missing group
# n = 356
lipinf <- lipid2 %>% 
  select(-assigned_group) %>% 
  inner_join(inflm2, by = "patient_id") %>%
  filter(!is.na(assigned_group)) %>% 
  mutate(group = factor(assigned_group, labels = c("Walnut", "Control")),
         group = relevel(group, ref = "Control"),
         gender = factor(gender, labels = c("F", "M"))) %>% 
  select(-center, -dropout_visit) %>% 
  select(patient_id, group, assigned_group, gender, age, dropout, everything())

names(lipinf)
head(lipinf)

# Anthropometric data -----------------------------------------------------
# n = 356
dim(body)
n_distinct(body$patient_id)

names(body)

# Select variables
# BMI needs to be re-calculated
body2 <- body %>% 
  mutate(educ = factor(education),
         educ_yr = education_years,
         race = factor(race),
         BMI = weight_basal / (height_basal / 100) ^ 2) %>% 
  select(patient_id, race, educ_yr, educ, race, BMI)

# Merge to lipid/inflammation data
lipinf2 <- lipinf %>% 
  inner_join(body2, by = "patient_id")

dim(lipinf2)

# Diet recall data --------------------------------------------------------
# n.obs = 1246, n.subj = 334
# Need polyphenols
dim(drec)
n_distinct(drec$patient_id)

names(drec)

# Freq tab of # recalls
drec %>% 
  group_by(patient_id) %>% 
  tally() %>% 
  group_by(n) %>% 
  tally() %>% 
  mutate(pct = nn / sum(nn) * 100)

# There is one ID not found in lipid/inflammation merge file
ids_no_lipid <- drec %>% 
  distinct(patient_id) %>% 
  anti_join(lipinf, by = "patient_id")

ids_no_lipid

# There are 23 IDs not found in dietary recalls
ids_no_recall <- lipinf %>% 
  anti_join(distinct(drec, patient_id), by = "patient_id") %>% 
  select(patient_id)

ids_no_recall

# Remove subjects with no lipid
# Rename long names
# n.obs = 1242, n.subj = 333
drec2 <- drec %>% 
  anti_join(ids_no_lipid, by = "patient_id") %>% 
  rename(flavanols = flavanols_proanthocyanidins_np)

dim(drec2)
n_distinct(drec2$patient_id)

# Check total kcal and total phenols
pps <- c("total_polyphenol", "total_flavonoids", "flavanols", "phenolic_acid", "lignin")
drec2 %>% select(patient_id, recall_day, all_of(pps))

drec2 %>% 
  select(energy_kcal, all_of(pps)) %>% 
  summary()

drec2 %>% 
  ggplot(aes(x = energy_kcal)) +
  geom_histogram(bins = 30)

# Energy-adjust each recall day and then take the average
ea_pps <- paste0(pps, "_ea")
drec2[ea_pps] <- lapply(drec2[pps], kcal_adjust, kcal = drec2$energy_kcal)

dintake <- drec2 %>% 
  group_by(patient_id) %>% 
  summarize_at(c("energy_kcal", ea_pps), mean, na.rm = TRUE)

# Merge three files -------------------------------------------------------
# n = 333 after merging
pp_df <- lipinf2 %>% 
  inner_join(dintake, by = "patient_id")

dim(pp_df)
n_distinct(pp_df$patient_id)

names(pp_df)
table(pp_df$group)

# Check missing values
pp_df %>% 
  select(group, gender, age, BMI, TC_0:HDL_2, hsCRP_0:TNFa_2, energy_kcal:lignin_ea) %>% 
  summary()

pp_df %>% 
  filter(is.na(TC_0)) %>% 
  select(TC_0:HDL_2, hsCRP_0:TNFa_2) %>% 
  print(n = Inf)

# Complete cases only -----------------------------------------------------

lipid_vars <- c("TC_0", "TC_2", "LDL_0", "LDL_2", "HDL_0", "HDL_2", "Trig_0", "Trig_2")
infl_vars  <- c("hsCRP_0", "hsCRP_2", "IL1_0", "IL1_2", "IL6_0", "IL6_2", "TNFa_0", "TNFa_2")
vars       <- c("TC", "LDL", "HDL", "Trig", "hsCRP", "IL1", "IL6", "TNFa")

# Complete cases only: n = 300
pp_df_comp_id <- pp_df %>% 
  select(patient_id, group, all_of(lipid_vars), all_of(infl_vars)) %>% 
  na.omit() %>% 
  select(patient_id)

pp_df_comp <- pp_df %>% 
  semi_join(pp_df_comp_id, by = "patient_id") %>% 
  mutate(TC_change = TC_2 - TC_0,
         LDL_change = LDL_2 - LDL_0,
         HDL_change = HDL_2 - HDL_0,
         Trig_change = Trig_2 - Trig_0,
         hsCRP_change = hsCRP_2 - hsCRP_0,
         IL1_change = IL1_2 - IL1_0,
         IL6_change = IL6_2 - IL6_0,
         TNFa_change = TNFa_2 - TNFa_0) 

dim(pp_df_comp)
names(pp_df_comp)

# Descriptive table at baseline -------------------------------------------

table_vars <- c("gender", "age", "BMI", "TC_0", "HDL_0", "LDL_0", "Trig_0", "hsCRP_0", "IL1_0", "IL6_0", "TNFa_0")

pp_df_comp %>% 
  select(group, all_of(table_vars)) %>% 
  summary()

# Check distributions
pp_df_comp %>% 
  select(all_of(table_vars), -gender, -age) %>% 
  pivot_longer(BMI:TNFa_0, names_to = "variable", values_to = "value") %>% 
  ggplot(aes(x = value)) +
  geom_histogram(bins = 30) +
  facet_wrap(~ variable, scales = "free")

# Note outliers on inflammatory markers
pp_df_comp %>% 
  select(hsCRP_0, IL1_0, IL6_0, TNFa_0) %>% 
  pivot_longer(hsCRP_0:TNFa_0, names_to = "variable", values_to = "value") %>% 
  ggplot(aes(x = value)) +
  geom_histogram(bins = 30) +
  facet_wrap(~ variable, scales = "free", ncol = 4)

# Descriptive table at baseline
pp_df_comp %>% 
  CreateTableOne(table_vars, strata = "group", data = .) %>% 
  print(showAllLevels = TRUE)

pp_df_comp %>% 
  CreateTableOne(table_vars, strata = "group", data = .) %>% 
  print(showAllLevels = TRUE, nonnormal = c("HDL_0", "Trig_0", "hsCRP_0", "IL1_0", "IL6_0", "TNFa_0"))

# Descriptive table of energy-adjusted intakes ----------------------------

# Check distributions
pp_df_comp %>% 
  select(all_of(ea_pps)) %>% 
  pivot_longer(1:5, names_to = "variable", values_to = "value") %>% 
  ggplot(aes(x = value)) +
  geom_histogram(bins = 30) +
  facet_wrap(~ variable, scales = "free", ncol = 5)

# Intake comparison by group
pp_df_comp %>% 
  CreateTableOne(ea_pps, strata = "group", data = .) %>% 
  print(nonnormal = ea_pps)

# Denstiy plot by group
pp_df_comp %>% 
  select(all_of(ea_pps), group) %>% 
  pivot_longer(1:5, names_to = "variable", values_to = "value") %>% 
  ggplot(aes(x = value, fill = group)) +
  geom_density(alpha = 0.5) +
  facet_wrap(~ variable, scales = "free")

# Lipid/inflammation: Table by group & year -------------------------------

table(pp_df_comp$group)

# Transform to long format
pp_df_long <- pp_df_comp %>% 
  pivot_longer(c(all_of(lipid_vars), all_of(infl_vars)), names_pattern = "(.*)_(.*)", names_to = c(".value", "year")) %>% 
  mutate(year = as.numeric(year)) 

# Check distribution
pp_df_long %>% 
  pivot_longer(vars, names_to = "variable", values_to = "value") %>% 
  ggplot(aes(x = value)) +
  geom_histogram(bins = 30) +
  facet_wrap(~variable, scales = "free")

# Descriptive table of lipids and inflammatory markers by year and group
pp_df_long %>% 
  CreateTableOne(vars, strata = c("year", "group"), data = ., test = FALSE)

pp_df_comp %>% 
  CreateTableOne(paste0(vars, "_change"), strata = "group", data =., test = FALSE)

# Profile plots for lipid
pp_df_long %>% 
  pivot_longer(TC:Trig, names_to = "variable", values_to = "value") %>% 
  ggplot(aes(x = year, y = value, color = group, group = patient_id)) +
  geom_line() +
  scale_x_continuous(breaks = c(0, 2)) +
  labs(x = "Year", color = "") +
  facet_wrap(~ variable, scales = "free", ncol = 4) +
  theme(legend.position = "bottom")

# Profile plots for inflammatory markers
pp_df_long %>% 
  pivot_longer(hsCRP:TNFa, names_to = "variable", values_to = "value") %>% 
  ggplot(aes(x = year, y = value, color = group, group = patient_id)) +
  geom_line() +
  scale_x_continuous(breaks = c(0, 2)) +
  labs(x = "Year", color = "") +
  facet_wrap(~ variable, scales = "free", ncol = 4) +
  theme(legend.position = "bottom")

# ANCOVA models -----------------------------------------------------------

# Specify covariates
covar <- c("age", "gender", "BMI", "lipid_lowering")

pp_df_comp %>% 
  select(all_of(covar)) %>% 
  summary()

# Function for ANCOVA model
ancova_mod <- function(data, yvar, basevar){
  covar <- paste(covar, collapse = " + ")
  fm <- formula(paste0(yvar, "~ total_polyphenol_ea + ", basevar, " + ", covar))
  print(fm)
  mod <- data %>% lm(fm, data = .)
  print(ggResidpanel::resid_panel(mod, plots = "all"))
  return(summary(mod))
}

pp_df_comp %>% ggp_scatter(TC_change, "Changes in total cholesterol (Year 2 - Baseline, mg/dL")
pp_df_comp %>% ancova_mod("TC_change", "TC_0")

pp_df_comp %>% ggp_scatter(LDL_change, "Changes in LDL cholesterol (Year 2 - Baseline, mg/dL)")
pp_df_comp %>% ancova_mod("LDL_change", "LDL_0")

pp_df_comp %>% ggp_scatter(hsCRP_change, "Changes in hsCRP (Year 2 - Baseline, mg/dL)")
pp_df_comp %>% ancova_mod("hsCRP_change", "hsCRP_0")

pp_df_comp %>% ggp_scatter(IL1_change, "Changes in IL-1 (Year 2 - Baseline, pg/ml)")
pp_df_comp %>% ancova_mod("IL1_change", "IL1_0")

pp_df_comp %>% ggp_scatter(IL6_change, "Changes in IL-6 (Year 2 - Baseline, pg/ml)")
pp_df_comp %>% ancova_mod("IL6_change", "IL6_0")

pp_df_comp %>% ggp_scatter(TNFa_change, "Changes in TNFa (Year 2 - Baseline, pg/ml)")
pp_df_comp %>% ancova_mod("TNFa_change", "TNFa_0")
