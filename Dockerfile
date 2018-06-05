FROM rocker/tidyverse:3.5

# Install packages from CRAN
RUN install2.r --error \
    -r 'http://cran.rstudio.com' \
    httr \
    DBI \
    RPostgres \
    ggplot2 \
    scales \
    shiny \
    flexdashboard \
    rmarkdown \
  && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

ADD mrrdash.Rmd mrrdash.Rmd

CMD ["R", "-e rmarkdown::run('mrrdash.Rmd', shiny_args = list(port = 8088))"]
