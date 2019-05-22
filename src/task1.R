source("common.R")

library(RMySQL)

execute_task1 <- function() {
    # Create result table
    postgres_conn <- connect_to_postgres()
    create_result_table_if_needed(postgres_conn)
    
    # Get daily metrics
    mysql_conn <- connect_to_mysql()
    daily_metrics_resultset <- get_daily_metrics_result(mysql_conn)
    
    # Store results
    store_resultset_in_db(postgres_conn, daily_metrics_resultset)

    # Close resultSet
    dbClearResult(daily_metrics_resultset)

    # Close DB connections
    dbDisconnect(postgres_conn)
    dbDisconnect(mysql_conn)
}

create_result_table_if_needed <- function (db_connection) {
    create_table_statement <- "CREATE TABLE IF NOT EXISTS daily_metric_count (
                                    metric text not null,
                                    date date not null,
                                    count bigint,
                                    primary key (metric, date))"
    dbGetQuery(db_connection, create_table_statement)
}

store_resultset_in_db <- function(db_connection, resultset) {
    num_rows_in_result_chunk <- 1000
    result_chunk_df <- dbFetch(resultset, num_rows_in_result_chunk)
    while (nrow(result_chunk_df) > 0) {
        store_result_chunk_in_db(db_connection, result_chunk_df)
        result_chunk_df <- dbFetch(resultset, num_rows_in_result_chunk)
    }
}

store_result_chunk_in_db <- function(db_connection, result_chunk_df) {
    tryCatch({
        # Start transaction
        dbBegin(db_connection)
        
        # Delete old rows
        new_key_value_list <- paste("('", result_chunk_df$metric, "','", result_chunk_df$date, "')", sep="", collapse = ',')
        delete_statement <- paste("DELETE FROM daily_metric_count WHERE (metric, date) IN (", new_key_value_list, ")")
        rs <- dbSendQuery(db_connection, delete_statement)
        
        # Add new rows
        new_rows <- paste("('", result_chunk_df$metric, "','", result_chunk_df$date, "',", result_chunk_df$count, ")", sep="", collapse = ',')
        insert_statement <- paste("INSERT INTO daily_metric_count (metric, date, count) VALUES ", new_rows)
        rs <- dbSendQuery(db_connection, insert_statement)
        
        # Commit transaction
        dbCommit(db_connection)
    }, warning = function(w) {
    }, error = function(e) {
        dbRollback(db_connection)
    }, finally = {})
}

get_daily_metrics_result <- function(db_connection) {
    daily_metrics_statement <- "SELECT metric, date(timestamp) as date, COUNT(*) AS count
                                    FROM liligo.liligo GROUP BY metric, date"

    # Get only a chunk of a result at a time so that it can fit into memory in more extreme cases too
    daily_metrics_result <- dbSendQuery(db_connection, daily_metrics_statement)
    return(daily_metrics_result)
}

connect_to_mysql <- function() {
    mysql_db <- dbConnect(MySQL(), 
                            user='liligo', 
                            password='liligo', 
                            dbname='liligo', 
                            host='127.0.0.1', 
                            port=3306)    
    return(mysql_db)
}

