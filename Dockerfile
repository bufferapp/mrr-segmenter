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

RUN mkdir -p /etc/shiny-server/
RUN echo 'sanitize_errors off;disable_protocols xdr-streaming xhr-streaming iframe-eventsource iframe-htmlfile;' >> /etc/shiny-server/shiny-server.conf

ADD mrrdash.Rmd mrr_source.R app/

WORKDIR /app

CMD ["R", "-e rmarkdown::run('mrrdash.Rmd',shiny_args=list(port=3405,host='0.0.0.0'))"]
