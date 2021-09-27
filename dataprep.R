
# WAHA polyphenols study
# Data preparation

# Read data ---------------------------------------------------------------

# Lipid file: n = 369
message("Reading lipid data...")
lipid <- read_sav(unz(zipfile, lipid_file)) %>%
  rename_all(tolower) %>% 
  filter(patient_id >= 5000)

# Inflammatory markers file: n = 371
message("Reading inflammatory marker data...")
inflm <- read_sav(unz(zipfile, inflm_file)) %>%
  rename_all(tolower) %>% 
  filter(patient_id >= 5000)

# 24h diet recall data: n = 334
message("Reading 24h diet recall data...")
drec <- read_csv(unz(zipfile, diet_file)) %>% 
  rename_all(tolower) %>% 
  mutate(patient_id = parse_number(partid),
         recall_day = substr(partid, nchar(partid), nchar(partid)),
         recall_day = as.numeric(recall_day)) %>%
  select(partid, patient_id, recall_day, everything()) %>% 
  filter(patient_id >= 5000)
