library(dplyr)
library(ggplot2)

output_dir <- "../out"

source("common.R")

execute_task2 <- function() {
    postgres_conn <- connect_to_postgres()
    
    # Get data from DB
    data <- get_data_from_db(postgres_conn)
    
    # Save plots
    save_all_plots(data)
    
    # Close DB connection
    dbDisconnect(postgres_conn)
}


get_data_from_db <- function(db_connection) {
    statement <- "SELECT * FROM daily_metric_count"

    resultset <- dbSendQuery(db_connection, statement)
    
    # Return all the rows at the same time
    # We assume that the data in this table fits into the memory
    result_df <- dbFetch(resultset, -1)
    
    dbClearResult(resultset)
    
    return(result_df)
}

save_all_plots <- function(data) {
    lapply(unique(data$metric), function (current_metric) {
        save_plot(current_metric, data %>% filter(metric == current_metric))
    })
}

save_plot <- function(metric, data) {
    format <- "png"
    output_file <- paste(metric, format,  sep = ".")

    p <- data %>%
        ggplot(aes(x = date, y = count)) +
            geom_line(color = 'steelblue') +
            theme_bw() + 
            labs(title = metric, x = "Date", y = "Count")

    ggsave(output_file, plot = p, device = format, path = output_dir)
}

execute_task2()

