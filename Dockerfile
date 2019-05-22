FROM rocker/tidyverse:3.3.2

# Install additional packages
RUN R -e "install.packages(c('RMySQL', 'RPostgreSQL'), repos='https://cran.rstudio.com/')"

# Create directories and get codes
RUN mkdir -p liligo; git clone https://github.com/posfaig/liligo liligo; mkdir -p liligo/out

# Go to the src directory at start
WORKDIR /liligo/src

# Execute computations
CMD bash

