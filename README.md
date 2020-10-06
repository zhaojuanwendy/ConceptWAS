# ConceptWAS -  a high-throughput approach for detecting COVID-19 symptoms from EHR notes

## Setup

### Installing dependencies
```
python3 -m venv nlp_pipeline 
source nlp_pipeline/bin/activate
pip install -r nlp_install_request.txt
```

Then reinstall jpype1 to jpype1==0.6.3. 
### Config the environment variables
Add to your .bashrc or .bash_profile
If on your own computer, add:
```
$export CURRENT_ENV="local"
```
If on server, add:
```
$export CURRENT_ENV="server"
```
### Config the note path
Config the note path in covid19/pipeline/config/sys.config
### Config the database information
config your netezza username, password and netezza driver path and MySQL connect info in
covid19/pipeline/config/db_server.config and covid19/pipeline/config/db_local.config

db_server.config for program running on server to use
db_local.config for program running on your own pc to use

The mysql and Netezza driver can use covid19/libs/mysql_netezza_jdbc.jar

### Set up database tables
sh setup_mysql.sh --db_user covid19 --db_name covid19 --db_pass covid19 --db_file create_mysql_covid_tables.sql

## Run pipeline

### fetch note
```
nz_pipe
sh pipeline/tools/run_fetch_notes.sh
```

### run knowlege map

### run processing the knowlegemap output 
pipeline/preprocessing

### conceptWAS analysis

R/conceptWAS.R







