library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)


get_mrr_metrics <- function(metric = "all", start_date, end_date, interval = "month", plans = NULL) {
  
  require(httr)
  require(jsonlite)
  
  token = Sys.getenv("CHARTMOGUL_API_TOKEN")
  secret = Sys.getenv("CHARTMOGUL_API_SECRET")
  
  base_url = paste0("https://api.chartmogul.com/v1/metrics/", metric)
  
  print(paste("Getting data from:", base_url))
  
  r <- GET(base_url,
           query = list(`start-date` = start_date,
                        `end-date` = end_date,
                        `interval` = interval,
                        `plans` = plans),
           authenticate(token, secret))
  
  stop_for_status(r)
  
  res_txt <- content(r, type = "text", encoding = "UTF-8")
  results <- fromJSON(res_txt)
  results_df <- results$entries
  
  results_df
}

# function to get data
get_mrr_data <- function(start_date, end_date, interval = "week", plans = NULL) {
  
  # unique file name
  filename <- sprintf("%s_%s_%s.rds", start_date, end_date, 'mrr')
  
  # check if data already exists
  if (file.exists(filename)) {
    
    print("Data already exists. Reading it from RDS file.")
    all <- readRDS(filename)
    
  } else {
    
    # list the plan names
    pro_plans <- "Pro8 v1 - Monthly,Pro8, v1 - Yearly"
    premium_plans <- "Premium Business v1 - Monthly - Monthly,Premium Business v1 - Yearly - Yearly"
    small_plans <- "Small Business v2 - Monthly,Small Business v2 - Yearly"
    medium_plans <- "Medium Business v2 - Monthly,Medium Business v2 - Yearly"
    large_plans <- "Large Business v2 - Monthly,Large Business v2 - Yearly"
    
    # get mrr data for each plan group
    pro <- get_mrr_metrics(metric = "mrr", start_date, end_date, interval, plans = pro_plans) %>% 
      mutate(plan = "pro")
    
    premium <- get_mrr_metrics(metric = "mrr", start_date, end_date, interval, plans = premium_plans) %>% 
      mutate(plan = "premium")
    
    small <- get_mrr_metrics(metric = "mrr", start_date, end_date, interval, plans = small_plans) %>% 
      mutate(plan = "small business v2")
    
    medium <- get_mrr_metrics(metric = "mrr", start_date, end_date, interval, plans = medium_plans) %>% 
      mutate(plan = "medium business v2")
    
    large <- get_mrr_metrics(metric = "mrr", start_date, end_date, interval, plans = large_plans) %>% 
      mutate(plan = "large business v2")
    
    # merge dataframes
    all <- pro %>% 
      rbind(premium) %>% 
      rbind(small) %>% 
      rbind(medium) %>% 
      rbind(large)
    
    # rename columns
    all <- all %>% 
      rename(total = mrr,
             new = `mrr-new-business`,
             expansion = `mrr-expansion`,
             contraction = `mrr-contraction`,
             churn = `mrr-churn`,
             reactivation = `mrr-reactivation`) %>% 
      mutate(date = as.Date(date)) %>% 
      mutate_if(is.numeric, funs(. / 100)) %>% 
      filter(date != min(date) & date != max(date))
    
    # save data to csv
    saveRDS(all, file = filename)
    
  }
  
  # return dataframe
  return(all)
}

