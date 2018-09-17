# load libraries
library(shiny)
library(ggplot2)
library(dplyr)
library(scales)

# source helper function
# source('global.R')

# get mrr data
mrr <- readRDS("/srv/shiny-server/mrr.rds")

# define a server for the Shiny app
function(input, output) {
  
  # fill in the spot we created for a plot
  output$mrrPlot <- renderPlot({
    
    # if there are no choices checked
    if (length(input$segments) == 0) {
      
      mrr <- mrr %>% 
        group_by(date) %>% 
        summarise(mrr = sum(mrr)) %>% 
        mutate(segment = 'Total MRR')
      
    } else {
      mrr <- mrr[, c("date", input$segments, "mrr")]
      
      groups <- mrr %>%
        select(-date, -mrr)
      
      group_args <- c(groups, sep = "_")
      group_values <- do.call(paste, group_args)
      
      mrr$segment <- group_values
      
      # make the group names pretty
      mrr <- mrr %>% 
        mutate(segment = toupper(gsub("_", " ", segment)))
    }
    
    # render plot
    mrr %>% 
      group_by(date, segment) %>%
      summarise(mrr = sum(mrr)) %>%
      ungroup() %>%
      mutate(segment = reorder(segment, -mrr)) %>%
      ggplot(aes_string(x = 'date', y = 'mrr')) +
      geom_line() +
      stat_smooth(method = 'loess') +
      facet_wrap(~ segment, scales = "free_y") +
      scale_y_continuous(labels = dollar) +
      labs(x = NULL, y = NULL, title = NULL) +
      theme(legend.position = "none") +
      theme_minimal()
  })
}
