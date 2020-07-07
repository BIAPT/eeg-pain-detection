import numpy as np
import pickle

from ml_tools.classification import classify_loso_model_selection
from ml_tools.classification import create_gridsearch_pipeline
from ml_tools.pre_processing import pre_process

import config as cfg


def print_summary(accuracies, group, df):
    """
    Helper function to print a summary of a classifier performance
    :param accuracies: a list of the accuracy obtained across fold (participant)
    :param group: ids of the participants windows
    :param df: dataframe containing all the data about the participant
    :return: None
    """

    p_ids = np.unique(group)
    print("Accuracies: ")
    for accuracy, p_id in zip(accuracies, p_ids):
        print(f"Participant {p_id}: accuracy = {accuracy}")
        num_window_baseline = len(df[(df['id'] == p_id) & (df['is_hot'] == 0)].to_numpy())
        num_window_pain = len(df[(df['id'] == p_id) & (df['is_hot'] == 1)].to_numpy())
        print(f"Baseline = {num_window_baseline}")
        print(f"Pain = {num_window_pain}")
        print(f"Ratio Baseline/Pain = {num_window_baseline / num_window_pain}")
        print("------")

    print(f"Mean accuracy: {np.mean(accuracies)}")


if __name__ == '__main__':

    # Global Experimental Variable
    performance_filename = cfg.OUTPUT_DIR + 'performance.pickle'

    acc_filename = cfg.OUTPUT_DIR + 'accuracies_result.pickle'
    f1_filename = cfg.OUTPUT_DIR + 'f1s_result.pickle'
    cm_filename = cfg.OUTPUT_DIR + 'cms_result.pickle'
    best_params_filename = cfg.OUTPUT_DIR + 'best_params.pickle'

    # Actual Training
    gs = create_gridsearch_pipeline()
    X, y, group, df = pre_process(cfg.DF_FILE_PATH, cfg.PARTICIPANT_TYPE)
    accuracies, f1s, cms, best_params = classify_loso_model_selection(X, y, group, gs)

    # Print out the summary in the console
    print_summary(accuracies, group, df)

    # Saving the performance metrics
    performance = {
        'accuracies': accuracies,
        'f1s': f1s,
        'cms': cms
    }
    performance_file = open(performance_filename, 'ab')
    pickle.dump(performance, performance_file)
    performance_file.close()

    # Saving the list of best parameters found so far
    best_params_file = open(best_params_filename, 'ab')
    pickle.dump(best_params, best_params_file)
    best_params_file.close()
