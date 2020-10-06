from pathlib import PurePosixPath


app_dir = PurePosixPath(__file__).parent.parent
project_dir = app_dir.parent
log_dir = project_dir / 'logs'
data_dir = project_dir / 'data'
images_dir = project_dir / 'images'
model_dir = project_dir / 'models'
experiments_dir = project_dir / 'experiments'
raw_data_dir = data_dir / 'raw'
interim_data_dir = data_dir / 'interim'
pro_data_dir = data_dir / 'processed'
summarized_data_dir = data_dir / 'summarized'


