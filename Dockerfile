
FROM r-base:latest

# Install dependencies and Download and install shiny server
RUN apt-get update && apt-get install -y -t unstable \
    sudo \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev/unstable \
    libssl-dev \
    libpq-dev \
    libxt-dev && \
    wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb && \
    rm -rf /var/lib/apt/lists/*

RUN install2.r --error \
    -r 'http://cran.rstudio.com' \
    httr \
    DBI \
    RPostgres \
    ggplot2 \
    plotly \
    scales \
    shiny \
    flexdashboard \
    forecast \
    lubridate \
    rmarkdown \
  && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
  && rm /srv/shiny-server/index.html 

EXPOSE 3838

COPY shiny-server.sh /usr/bin/shiny-server.sh

COPY mrrdash.Rmd mrr_source.R /srv/shiny-server/

CMD ["./usr/bin/shiny-server.sh"]
