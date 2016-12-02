# tetra
Tetra-Time estimation tool for Aquarium

## How to use

### Generating job timing data csv files

```
ruby job_log_processing.rb
```
This will process the Aquarium job logs with id from lower_bound_id to upper_bound_id and generate a csv file for each types of job (for example PCR, miniprep, etc) with job_id, size, duration, ajusted_duration, max_time_interval, user_id, user_name.

### Generating summary job timing data csv file

```
ruby data_summary.rb
```
This will process the all job timing data csv files and produce a summary file with job_name, average_time_per_reaction, num, stddev, average_size, mode_size, week_size.