FROM rocker/shiny:latest

RUN apt-get update -qq && apt-get -y --no-install-recommends install \
    libpq-dev

# Install packages from CRAN
RUN install2.r --error \
    -r 'http://cran.rstudio.com' \
    DBI \
    RPostgres \
    ggplot2 \
    scales \
    shiny \
  && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

  ADD global.R /
  ADD run.sh /
  ADD ui.R /
  ADD server.R /srv/shiny-server/

  CMD ["/run.sh"]
