
# WAHA polyphenols study
# Data preparation

# Read data ---------------------------------------------------------------

# Lipid file: n = 369
message("Reading lipid data...")
lipid <- read_sav(unz(zipfile, lipid_file)) %>%
  clean_names() %>% 
  filter(patient_id >= 5000)

# Additional lipid file: n = 369
# Same order by patient_id
lipid_add <- read_sav("./data/Lipids year 0 year 1 year 2  22023 .sav") %>% 
  clean_names() %>% 
  filter(patient_id >= 5000)

# Merge HDL and LDL
lipid <- lipid %>% 
  inner_join(lipid_add %>% select(patient_id, hdl:ldl2), by = "patient_id")

# Inflammatory markers file: n = 371
message("Reading inflammatory marker data...")
inflm <- read_sav(unz(zipfile, inflm_file)) %>%
  clean_names() %>% 
  filter(patient_id >= 5000)

# Additional inflm file: n = 371
# Same order by patient_id
inflm_add <- read_sav("./data/Inflammation cytokines baseline and final 2023.sav") %>% 
  clean_names() %>% 
  filter(patient_id >= 5000)

inflm <- inflm %>% 
  inner_join(inflm_add %>% select(1, s_e_selectin_1:s_vcam_1_2), by = "patient_id")

# 24h diet recall data: n = 334
message("Reading 24h diet recall data...")
drec <- read_csv(unz(zipfile, diet_file)) %>% 
  clean_names() %>% 
  mutate(patient_id = parse_number(participant_id),
         recall_day = substr(participant_id, nchar(participant_id), nchar(participant_id)),
         recall_day = as.numeric(recall_day)) %>%
  select(participant_id, patient_id, recall_day, everything()) %>% 
  filter(patient_id >= 5000)

# Anthropometric data: n = 356
message("Reading anthropometric data...")
temp <- unzip(zipfile, body_file, exdir = tempdir())
body <- read_excel(temp) %>% 
  clean_names()

# Urine data: n = 307
message("Reading urine data...")
urine <- read_excel(urine_file) %>% 
  clean_names() %>% 
  mutate(patient_id = id,
         time = factor(collection_time, labels = c(0, 1, 2))) %>% 
  select(patient_id, time, polyphenol_yield_correction_factor_2, final_polyphenol_yield_mg_g_creatinine)

message("Done!")