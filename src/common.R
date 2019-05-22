library(RPostgreSQL)

connect_to_postgres <- function() {
    drv <- dbDriver("PostgreSQL")
    postgres_db <- DBI::dbConnect(drv, 
                                    dbname = "liligo", 
                                    user = "liligo", 
                                    password = "liligo", 
                                    host = "127.0.0.1", 
                                    port=5432)
    return(postgres_db)
}

