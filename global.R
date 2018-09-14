library(DBI)
library(RPostgres)
library(dplyr)

# function to get MRR data
get_mrr_data <- function() {
  
  # connect to redshift
  con <- dbConnect(RPostgres::Postgres(),
                   host=Sys.getenv("REDSHIFT_ENDPOINT"),
                   port=Sys.getenv("REDSHIFT_DB_PORT"),
                   dbname=Sys.getenv("REDSHIFT_DB_NAME"),
                   user=Sys.getenv("REDSHIFT_USER"),
                   password=Sys.getenv("REDSHIFT_PASSWORD"))
  
  
    # define MRR query
    mrr_query <- "
      select
        date(date) as date
        , gateway
        , simplified_plan_id
        , billing_cycle as billing_interval
        , sum(total_mrr) as mrr
      from dbt.daily_mrr_values
      where date >= (current_date - 182)
      and gateway != 'Manual'
      and simplified_plan_id != 'other'
      and date < (current_date - 2)
      group by 1, 2, 3, 4
    "
  
  # query redshift
  df <- dbGetQuery(con, mrr_query) %>% 
      mutate(billing_interval = gsub("Annual", "year", billing_interval),
             billing_interval = gsub("Yearly", "year", billing_interval),
             billing_interval = gsub("Quarterly", "year", billing_interval))
  
  # return data
  # df
    
  # save data
  saveRDS(df, "/srv/shiny-server/mrr.rds")
  
}



