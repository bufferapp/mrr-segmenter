library(dplyr)
library(DBI)
library(RPostgres)

# connect to redshift
redshift_connect <- function() {

  if(Sys.getenv("REDSHIFT_USER") == "" | Sys.getenv("REDSHIFT_PASSWORD") == "") {
    user <- readline(prompt="Enter your Redshift user: ")
    pwd <- readline(prompt="Enter your Redshift password: ")
    Sys.setenv(REDSHIFT_USER = user)
    Sys.setenv(REDSHIFT_PASSWORD = pwd)
  }

  con <- dbConnect(RPostgres::Postgres(),
                   host=Sys.getenv("REDSHIFT_ENDPOINT"),
                   port=Sys.getenv("REDSHIFT_DB_PORT"),
                   dbname=Sys.getenv("REDSHIFT_DB_NAME"),
                   user=Sys.getenv("REDSHIFT_USER"),
                   password=Sys.getenv("REDSHIFT_PASSWORD"))

  con
}

# function to query database
query_db <- function(query, connection) {
  results <- dbGetQuery(connection, query)
  results
}

# get data from Redshift
get_redshift_data <- function() {

  # connect to redshift
  con <- redshift_connect()

  # define mrr query
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
  mrr_data <- query_db(mrr_query, con)

  # fix up billing intervals
  mrr_data <- mrr_data %>%
    mutate(billing_interval = ifelse(billing_interval == 'Annual' | billing_interval == 'Yearly', 'year',
                                     ifelse(billing_interval == 'Monthly', 'month',
                                            ifelse(billing_interval == 'Quarterly', 'year', billing_interval))))
  mrr_data
}


# function to save data
save_data <- function(df) {

  # create a unique file name
  filename <- sprintf("%s_%s.csv", as.character(Sys.Date()), 'mrr')

  # Write the file to the local system
  write.csv(df, file = file.path('.', filename), row.names = FALSE)
}


# function to read data
load_data <- function() {

  # get filename
  filename <- sprintf("%s_%s.csv", as.character(Sys.Date()), 'mrr')

  # read csv
  df <- read.csv(file = file.path('.', filename), stringsAsFactors = FALSE)

  df
}


# function to get data
get_mrr_data <- function() {

  # get filename
  filename <- sprintf("%s_%s.csv", as.character(Sys.Date()), 'mrr')
  file = file.path('.', filename)

  # check if file exists
  if (file.exists(file)) {
    df <- load_data()
  } else {
    df <- get_redshift_data()
    save_data(df)
  }

  # set dates
  df$date <- as.Date(df$date, format = '%Y-%m-%d')

  # return data frame
  df
}
