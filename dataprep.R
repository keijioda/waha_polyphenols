
# WAHA polyphenols study
# Data preparation

# Read data ---------------------------------------------------------------

# Lipid file: n = 369
message("Reading lipid data...")
lipid <- read_sav(unz(zipfile, lipid_file)) %>%
  clean_names() %>% 
  filter(patient_id >= 5000)

# Inflammatory markers file: n = 371
message("Reading inflammatory marker data...")
inflm <- read_sav(unz(zipfile, inflm_file)) %>%
  clean_names() %>% 
  filter(patient_id >= 5000)

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

message("Done!")