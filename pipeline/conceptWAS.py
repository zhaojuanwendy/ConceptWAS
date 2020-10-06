import pandas as pd
import numpy as np
import argparse
from pathlib import Path
import statsmodels.api as sm
from pprint import pprint
from patsy import dmatrices
from scipy import stats
from io import StringIO

from pipeline.helper.io_helper import write_to_csv_from_list_of_dict
from pipeline.config.config import pro_data_dir, summarized_data_dir

"""
multiple hypothesis testing
"""


def get_statistics_from_data(df, feature, outcome):
    attr = ['n_cases_feq', 'n_controls_freq', 'n_cases', 'n_controls', 'n_total']
    n_total = df.shape[0]
    n_cases_has_feature = df[(df[outcome] == 1) & (df[feature] == 1)].shape[0]
    n_controls_has_feature = df[(df[outcome] == 0) & (df[feature] == 1)].shape[0]
    print('{} cases has {}'.format(n_cases_has_feature, feature))
    print('{} controls has {}'.format(n_controls_has_feature, feature))
    in_case_feq = round(n_cases_has_feature / df[(df[outcome] == 1)].shape[0], 3)
    in_control_feq = round(n_controls_has_feature / df[(df[outcome] == 0)].shape[0], 3)
    return dict(zip(attr, [in_case_feq, in_control_feq, n_cases_has_feature, n_controls_has_feature, n_total]))


def fisher_exact(df, **params):
    _attr = ['feature', 'odds_ratio', 'p-value', 'n_cases_feq',
             'n_controls_freq', 'n_cases', 'n_controls', 'n_total'] #the parameters
    """
    :param df: pandas dataframe
    :param feature: feature column
    :param outcome: outcome column
    :param correction:
    :return: dict
    """
    try:
        feature = params['feature']
        outcome = params['outcome']
    except KeyError:
        raise

    obs = pd.crosstab(index=df[outcome],
                      columns=df[feature])

    oddsratio, pvalue= stats.fisher_exact(obs)
    data_stat = get_statistics_from_data(df, feature, outcome)
    result = [feature, oddsratio, pvalue,
              data_stat['n_cases_feq'], data_stat['n_controls_freq'], data_stat['n_cases'],
              data_stat['n_controls'], data_stat['n_total']]

    return dict(zip(_attr, result))


def chi2(df, **params):
    _attr = ['feature', 'g', 'p-value', 'n_cases_feq', 'n_controls_freq', 'n_cases', 'n_controls', 'n_total'] #the parameters
    """
    :param df: pandas dataframe
    :param feature: feature column
    :param outcome: outcome column
    :param correction:
    :return: dict
    """
    try:
        feature = params['feature']
        outcome = params['outcome']
        correction = params['correction']
    except KeyError:
        raise

    obs = pd.crosstab(index=df[outcome],
                      columns=df[feature])

    g, p, dof, expctd = stats.chi2_contingency(obs, correction=correction)
    data_stat = get_statistics_from_data(df, feature, outcome)
    result = [feature, g, p, data_stat['n_cases_feq'], data_stat['n_controls_freq'], data_stat['n_cases'],
              data_stat['n_controls'], data_stat['n_total']]

    return dict(zip(_attr, result))


def logitStats(df, return_only_feature_result=True, **params):
    """
    :param df: dataframe
    :param return_only_feature_result: If True (default), only return the parameters for target feature ; If False,
    return all summary
    :param feature: target feature
    :param covariates:covariates
    :param outcome:outcome
    :return: dict of parameters
    """

    _basic_attr = ['coef', 'std_err', 'z', 'p-value', '[0.025', '0.975]']
    _extended_attr = ['feature', 'coef', 'std_err', 'z', 'p-value', '[0.025', '0.975]', 'n_cases', 'n_controls',
                      'n_total']

    try:
        feature = params['feature']
        outcome = params['outcome']
        covariates = params['covariates']
    except KeyError:
        raise

    try:
        if isinstance(feature, list):
            feature_formula = " + ".join([f for f in feature])
        else:
            print("not list")
            feature_formula = feature

        if covariates is not None:
            covariates_formula = " + ".join([f for f in covariates])
            y, X = dmatrices('{0} ~ {1} + {2}'.format(outcome, feature_formula, covariates_formula), data=df,
                             return_type='dataframe')

        else:
            y, X = dmatrices('{0} ~ {1}'.format(outcome, feature_formula),  data=df, return_type='dataframe')

        mod = sm.Logit(y, X)
        res = mod.fit()
        smry = res.summary()
        print(smry)
        df_result = wrap_summary(smry, _basic_attr)
        if  return_only_feature_result:
            results = df_result.loc[feature].tolist() # parameters list: e.g. coefficient, p-value
            results.insert(0, feature)  # add the feature name to the parameters list
        else:
            return df_result

    except np.linalg.LinAlgError as err:
        results = [feature, 'NA', 'NA', 'NA', 'NA', 'NA', 'NA']
        if 'Singular matrix' in str(err):
            print("{} has {}".format(feature, err))
        else:
            raise
    finally:
        if return_only_feature_result:
            data_stat = get_statistics_from_data(df, feature, outcome)
            results = results + [data_stat['n_cases'], data_stat['n_controls'], data_stat['n_total']]
            return dict(zip(_extended_attr, results))


def wrap_summary(summary, attr):
    print(summary.tables[1].as_csv())
    df_result = pd.read_csv(StringIO(summary.tables[1].as_csv()), index_col=0, error_bad_lines=False)
    print(df_result.head(10))
    df_result.columns = attr
    # remove the blanks
    df_result.index = df_result.index.str.rstrip()
    return df_result


def preprocess_helper(cui_table_path, unique_indexer='person_id', merged_table=False, demo_feature_file=None, demo_features_length=5):
    """
    :param cui_table_path: the file path of cui_table. Each row is a patient and each row is a concept.
    :param unique_indexer: the unique ID of each row of cui table e.g. person_id (default)
    :param demo_feature_file: the file path of other features such as demographic and labels
    :param merged_table: if the conceptable is a merged table with demo and label
    :return: concept table or merged table with index of unique_indexer, cui features
    """
    suffix = cui_table_path.suffix
    if suffix == '.hd5' or suffix == '.hdf5' or suffix == '.hf5':
        concept_table = pd.read_hdf(cui_table_path)
    else:
        concept_table = pd.read_csv(cui_table_path, index_col=unique_indexer)
    print(concept_table.shape)
    print(concept_table.head())

    # add prefix "c" to column name because name like '10010_pos' would cause error for StatesModel
    # TODO determine if column starts with number
    if merged_table:
        new_names = [(i, 'c'+i) for i in concept_table.iloc[:, :-demo_features_length].columns.values]
        concept_table.rename(columns=dict(new_names), inplace=True)
        cui_features = concept_table.iloc[:, :-demo_features_length].columns.tolist()
        print(concept_table.shape)
        print(len(cui_features))
        return concept_table, cui_features

    concept_table = concept_table.add_prefix('c')
    print(concept_table.head())
    cui_features = concept_table.columns.tolist()

    if demo_feature_file is not None:
        df = pd.read_csv(demo_feature_file)
        df.index = df[unique_indexer]
        print(df.shape)
        print(df.head())
        merged = concept_table.join(df, on=unique_indexer, how='inner')
        return merged, cui_features

    return concept_table, cui_features


class ConceptWAS:
    """
    ConceptWAS multiple hypothesis testing between cases and controls
    """

    def __init__(self, df, features, outcome, covariates=None):
        """
        :param df: pandas dataframe, each row is a patient, each column is a feature, e.g. concept, phecode, and outcome
        :param features: predictors, independent column name
        :param covariates: covariates column name
        :param outcome: outcome column name
        """
        self.df = df.copy()
        self.features = features
        self.covariates = covariates
        self.outcome = outcome

    def fit(self, method='chi2'):
        """
        :param method:  the testing association method, default is chi2
        :return: a list of dicts that contains the parameters
        """
        method_dict = {
            'chi2': chi2,
            'fisher_exact': fisher_exact,
            'logit': logitStats
        }
        params = {
            'outcome': self.outcome,
            'covariates': self.covariates,
            'correction': False
        }
        pprint(params)
        result = []
        examine_assoc = method_dict[method]
        for fea in self.features:
            params['feature'] = fea
            res = examine_assoc(self.df, **params)
            result.append(res)
        return result

    @staticmethod
    def save_result_to_file(file, result):
        """
        :param file: file path
        :param result: the result of the parameters of the conceptwas
        :return:
        """
        write_to_csv_from_list_of_dict(file, result)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', '-i', type=str, required=True, help='input concept file name, e.g. cui_table.csv')
    parser.add_argument('--method', '-m', type=str, default='chi2',
                        help='set the conceptWAS association method: chi2, logit, or fisher_exact')
    # parser.add_argument('--demo_file', '-d', default='demo_label.csv', type=str)
    # parser.add_argument('--merge_with_demo', '-m',
    #                     action='store_true',
    #                     help='if merge with demo')
    # parser.add_argument('--preprocess_demo', '-pd',
    #                     action='store_true',
    #                     help='if preprocess the demo file')

    args = parser.parse_args()
    input_concept_file = args.input
    method = args.method
    print("loading concept table", input_concept_file)
    print("method is {}".format(method))
    cui_table_path = Path(pro_data_dir / input_concept_file)
    # demo_label_path = Path(pro_data_dir) / 'demo_label.csv'
    # merged, cui_features = preprocess_helper(cui_table_path, 'person_id', demo_label_path)
    merged, cui_features = preprocess_helper(cui_table_path, 'person_id', merged_table=True, demo_features_length=5)
    print("running ConceptWAS ", method)
    cws = ConceptWAS(merged, cui_features, outcome='label', covariates=['age', 'gender', 'race'])
    result = cws.fit(method=method)
    output_path = Path(summarized_data_dir) / 'new_conceptWAS-{}_{}.csv'.format(method, input_concept_file)
    cws.save_result_to_file(output_path, result)


if __name__ == '__main__':
    main()




















