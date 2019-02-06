library(dplyr)
library(DBI)
library(RPostgres)
library(forecast)

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
      , plan_id
      , simplified_plan_id
      , sum(total_mrr) as mrr
    from dbt.daily_mrr_values
    where date >= (current_date - 182)
    and gateway in ('Stripe', 'Manual') 
    and date < (current_date - 1)
    group by 1, 2, 3, 4
    "

  # query redshift
  mrr_data <- query_db(mrr_query, con)

  mrr_data
}


# function to save data
save_data <- function(df) {

  # create a unique file name
  filename <- sprintf("%s_%s.csv", as.character(Sys.Date()), 'mrr')

  # Write the file to the local system
  write.csv(df, file = file.path('~', filename), row.names = FALSE)
}


# function to read data
load_data <- function() {

  # get filename
  filename <- sprintf("%s_%s.csv", as.character(Sys.Date()), 'mrr')

  # read csv
  df <- read.csv(file = file.path('~', filename), stringsAsFactors = FALSE)

  df
}


# function to get data
get_mrr_data <- function() {

  # get filename
  filename <- sprintf("%s_%s.csv", as.character(Sys.Date()), 'mrr')
  file = file.path('~', filename)

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

# forecast revenue 90 days into the future
get_forecast_obj <- function(mrr, h = 90, freq = 7) {
  
  # arrage data by date
  df <- mrr %>% 
    arrange(date)
  
  # create timeseries object
  ts <- ts(mrr$point_forecast, frequency = 7)
  
  # fit exponential smoothing algorithm to data
  etsfit <- ets(ts)
  
  # get forecast
  fcast <- forecast(etsfit, h = h, frequency = freq)
  
  # convert to a data frame
  fcast_df <- as.data.frame(fcast)
  
  # get the forecast dates
  fcast_df$date <- seq(max(mrr$date) + 1, max(mrr$date) + h, 1)
  
  # rename columns of data frame
  names(fcast_df) <- c('point_forecast','lo_80','hi_80','lo_95','hi_95', 'date')
  
  fcast_df

}

# forecast revenue 90 days into the future
get_forecast <- function(mrr, h = 90, freq = 7, application) {
  
  # filter by application
  if (application == "publish") {
    
    mrr <- mrr %>% 
      filter(simplified_plan_id != 'reply' & simplified_plan_id != 'analyze') %>% 
      group_by(date) %>% 
      summarise(mrr = sum(mrr, na.rm = TRUE)) %>% 
      rename(point_forecast = mrr) %>% 
      arrange(date)
    
  } else {
    
    mrr <- mrr %>% 
      filter(simplified_plan_id == application) %>% 
      group_by(date) %>% 
      summarise(mrr = sum(mrr, na.rm = TRUE)) %>% 
      rename(point_forecast = mrr) %>% 
      arrange(date)
    
  }
  
  # create timeseries object
  ts <- ts(mrr$point_forecast, frequency = 7)
  
  # fit exponential smoothing algorithm to data
  etsfit <- ets(ts)
  
  # get forecast
  fcast <- forecast(etsfit, h = h, frequency = freq)
  
  # convert to a data frame
  fcast_df <- as.data.frame(fcast)
  
  # get the forecast dates
  fcast_df$date <- seq(max(mrr$date) + 1, max(mrr$date) + h, 1)
  
  # rename columns of data frame
  names(fcast_df) <- c('point_forecast','lo_80','hi_80','lo_95','hi_95', 'date')
  
  # merge data frames
  mrr_forecast <- rbind(mrr, select(fcast_df, date, point_forecast))
  
  # set value as int
  mrr_forecast$point_forecast <- as.integer(mrr_forecast$point_forecast)
  
  # set created_at date
  mrr_forecast$forecast_created_at <- Sys.time()
  
  # rename columns
  names(mrr_forecast) <- c('forecast_at', 'forecasted_mrr_value', 'forecast_created_at')
  
  # return the new data frame
  mrr_forecast
}

# get end of month forecast value
get_eom_value <- function(fc, eom) {
  eom_fc <- filter(fc, forecast_at == eom)
  return(dollar(eom_fc[1,]$forecasted_mrr_value))
}

# get projected growth rate
get_growth_rate <- function(fc, eom, last_month) {
  eom_fc <- filter(fc, forecast_at == eom)
  fc_last_month <- filter(fc, forecast_at == last_month)[1,]$forecasted_mrr_value
  gr <- eom_fc[1,]$forecasted_mrr_value / fc_last_month - 1
  return(gr)
}