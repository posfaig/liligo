# Requirements

The original specification with more context can be found [here](https://gitlab.com/liligo/analytics-developer-take-home-challenge).

## Functional

1. Aggregate how many times the metrics occurred on daily basis. Save the aggregated results to a table in the provided Postgres database.

    - Executing the code for this task multiple times should not cause errors.
    - The table containing the results should have only one (the most recent) count for the individual *(metric, date)* pairs. I.e. when executing the code of this task multiple times, only the most recent counts should remain in the result table for each *(metric, date)* pair.
    - Existing records from the result table should not get deleted, i.e. for example if someone truncates the source table as it is getting too big, then any subsequent execution of the codes should not delete the records from the result table that belonged to previously aggregated metrics.

2. Using any framework or tool create a visualization from the results you've saved to Postgres. (e.g.: a line chart with values per metric and day.)
    
## Non-Functional

- Avoid reading the entire liligo table into memory at once.
- Database should not go into an inconsistent state even if the aggregation is simultanously executed on multiple threads.

# Out of scope

The current approach does not address the following points:
    
- Writing tests (unit/integration tests).
- Scheduling / Triggering the the tasks (like triggering the visualization automatically after every aggregation).
- Setting up an API/endpoints for the solution.
- Handling the case when the entire aggregated result table does not fit into memory.
- Error handling.
- Logging.


Some of these would be crucial if the solution would be used in production (e.g. writing tests).

# Implementation

R was used to solve the tasks.

The approach can be found in this git repo (master branch): https://github.com/posfaig/liligo

Code for task 1: `src/task1.R`
Code for task 2: `src/task2.R`
    
Name of result table in the Postgres DB: *daily_metric_count*

## Task 1

- The implementation first creates the result table if it does not exist already.
- Then runs a query on the MySQL db to get the aggregated metric counts for each day for each metric.
    - The query returns only the aggregated metrics.
    - The result is read in chunks of 1000 rows so if the table is big (or even if the aggregated data is big) the process should not run into memory issues.
- For each result chunk it starts a transcation in the Postgres DB:
    - It deletes all the existing records where the *(metric, date)* pair of the existing record can also be found in the current result chunk.
    - Adds all the records of the current result chunk to the target table.
    - Commits the transaction (or if there was an error, it rolls back the transaction.)


By using transactions we ensure that the result table cannot go into an inconsistent state even if the task is executed by multiple threads at the same time.

## Task 2

- The implementation first reads the entire result table from the Postgres DB.
- Then for each metric it creates a *.png* file with a simple plot showing the metric count by date on a line chart.


We always read the whole result table at once. If the amount of aggregated daily metrics would grow significantly and could potentially fill up the memory, then this should be changed (e.g. read only data from a recent time window at once). (Note: in this case the code for task 1 would not need to be rewritten as it already processes the aggregated metrics in smaller chunks.)

# Running the Codes

1. Prerequisites:
    - Setup environment as described [here](https://gitlab.com/liligo/analytics-developer-take-home-challenge) (i.e. run `docker-compose up`).
    - Have Docker for Linux installed. (The Linux version is needed for the host networking driver. [See.](https://docs.docker.com/network/host/))
    - Logged into the Docker Hub with the Docker command line.

2. Set the *LILIGO_OUTPUT_DIR* environment variable to the path of a directory where the outputs of task 2 (i.e. plots) will be stored. 

`export LILIGO_OUTPUT_DIR=/absolute/path/of/output/dir`

3. Execute codes
- To run task 1:
    `docker run --network="host" -v $LILIGO_OUTPUT_DIR:/liligo/out -it posfaig/liligo:1 Rscript task1.R`
- To run task 2:
    `docker run --network="host" -v $LILIGO_OUTPUT_DIR:/liligo/out -it posfaig/liligo:1 Rscript task2.R`
- To run all tasks:
    `docker run --network="host" -v $LILIGO_OUTPUT_DIR:/liligo/out -it posfaig/liligo:1 Rscript main.R`
- To start terminal session in the environment where the solution can be executed:
    `docker run --network="host" -v $LILIGO_OUTPUT_DIR:/liligo/out -it posfaig/liligo:1`

