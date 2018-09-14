library(shinythemes)

# use a fluid Bootstrap layout
fluidPage(    
  
  # theme
  theme = shinytheme("paper"),
  
  # title
  titlePanel("MRR Segmenter"),
  
  # Generate a row with a sidebar
  sidebarLayout(      
    
    # Define the sidebar with one input
    sidebarPanel(
      helpText("Choose what to segment MRR by. Total MRR will be grouped by the selected choices so that you can see how MRR has changed over time for each combination of choices."),
      helpText("For example, if 'Billing Interval' is selected, the app will display historic MRR for each billing interval, i.e. monthly and yearly MRR."),
      helpText("If multiple checkboxes are selected, the app will show historic MRR for all combinations of the selected options (e.g. Awesome Monthly, Awesome Yearly, Business Monthly, etc.)."),
      hr(),
      checkboxGroupInput(inputId = 'segments', 
                         label = 'Segment By:',
                         choices = c('Plan Type (Awesome, Business, Reply)' = 'simplified_plan_id',
                                     'Billing Interval (Month, Year)' = 'billing_interval',
                                     'Gateway (Stripe, Apple, Android)' = 'gateway'), 
                         selected = c('simplified_plan_id', 'billing_interval', 'gateway'))
    ),
    
    # create a spot for the MRR plot
    mainPanel(
      plotOutput("mrrPlot", height = 700)  
    )
    
  )
)

