from typing import List
import csv
import pandas as pd
import os
import errno
import h5py
from pathlib import Path
from python.helper.exception import DirectoryDoesNotExist


def write_to_csv_from_dict(file, data, append_write='w'):
    """
    :param append_write:
    :param file: output file
    :param data: data in a dict format
    :return:
    """
    csv_columns = data.keys()
    try:
        with open(file, append_write) as f:
            csv_out = csv.DictWriter(f, fieldnames=csv_columns)
            if append_write != 'a':
                csv_out.writeheader()
            for data in data:
                csv_out.writerow(data)
    except IOError:
        print("I/O error")


def write_to_csv_from_list_of_dict(file, data, columns: List[str] = None, append_write='w'):
    try:
        if columns is None:
            columns = data[0].keys()
        with open(file, append_write) as f:
            csv_out = csv.writer(f)
            if append_write != 'a':
                csv_out.writerow(columns)
            for row in data:
                csv_out.writerow(row.values())
    except IOError:
        print("I/O error")


def file_2_sql(file):
    f = open(file, encoding='utf-8')
    try:
        sql = f.read()
    finally:
        f.close()

    return sql


def file_2_multiple_sqls(file):
    f = open(file, encoding='utf-8')
    try:
        sql_string = f.read()
        sql_list = sql_string.split(';')
    finally:
        f.close()

    return sql_list


def read_file(file):
    f = open(file)
    try:
        text = f.read()
    finally:
        f.close()

    return text


def mkdir(path):
    try:
        os.makedirs(path)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise (DirectoryDoesNotExist(path))


def pandas_to_hdf5(file, df):
    df.to_hdf(file, 'data')
    # with h5py.File(file, 'w') as f:
    #     dataset = f.create_dataset('dataset', data=df.values)
    #     dataset.attrs['index'] = np.array(df.index.tolist(), dtype='S')
    #     dataset.attrs['columns'] = np.array(df.columns.tolist(), dtype='S')
        # if other_attrs is not None:
        #     for key in other_attrs:
        #         dataset.attrs[key] = np.array(other_attrs[key], dtype='S')


def make_index(raw):
    index = raw.astype('U')
    if index.ndim > 1:
        return pd.MultiIndex.from_tuples(index.tolist())
    else:
        return pd.Index(index)


def read_hdf5_to_pandas():
    with h5py.File('data.hdf5') as file:
        dataset = file['dataset']
        index = make_index(dataset.attrs['index'])
        columns = make_index(dataset.attrs['columns'])
        df = pd.DataFrame(data=dataset[...], index=index, columns=columns)
        return df


def write_to_file(file, text):
    flag = -1
    try:
        with open(file, 'w') as f:
            if isinstance(text, list):
                f.writelines(text)
            else:
                f.write(text)
            flag = 1
    except IOError:
        print("I/O error")

    return flag


def get_sub_dirs(dir_path):
    try:
        return [e for e in Path(dir_path).iterdir() if e.is_dir()]
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(dir_path):
            pass
        else:
            raise (DirectoryDoesNotExist(dir_path))


def get_files(dir_path, suffix: str = None):
    try:
        if suffix is not None:
            return [e for e in Path(dir_path).rglob('*{}'.format(suffix))]
        else:
            return [e for e in Path(dir_path).iterdir() if e.is_file()]
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(dir_path):
            pass
        else:
            raise (DirectoryDoesNotExist(dir_path))


def backup_file(source_file, target_file):
    text = read_file(source_file)
    flag = write_to_file(target_file, text)
    return flag


def isFileExists(file):
    if isinstance(file, Path):
        if file.exists():
            return True
        else:
            return False
    else:
        return os.path.exists(file)
