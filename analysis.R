
# WAHA polyphenols study

# GitHub
browseURL("https://github.com/keijioda/waha_polyphenols")

# Required packages
pacs <- c("tidyverse", "haven")
sapply(pacs, require, character.only = TRUE)

# Read data ---------------------------------------------------------------
# Will be using only LLU data -- make sure to subset for id >= 5000

zipfile <- "./data/Archive.zip"

lipid_file <- "BDLab_BCNLLU1709.sav"
inflm_file <- "WAHA_ BD_Cytokines_BCN_LLU.sav"
diet_file  <- "waha-recalls-per-recalls-overlapping-foodgroups-with-pOH.csv"
# diet_file  <- "waha-recalls-per-subject-overlapping-foodgroups-with-pOH.csv"

source("dataprep.R")

# lipid data --------------------------------------------------------------

names(lipid)

# inflammatory marker data ------------------------------------------------

names(inflm)

inflm %>% 
  select(patient_id, assigned_group, gender, age_)

inflm %>% 
  select(-ends_with("outlier"), -ends_with("dif")) %>% 
  select(starts_with("high_"), starts_with("il"), starts_with("tnf"))

# Diet recall data --------------------------------------------------------
# Need polyphenols

names(drec)
pps <- c("tp", "tf", "fl", "ph", "li")
drec %>% select(patient_id, recall_day, all_of(pps))
