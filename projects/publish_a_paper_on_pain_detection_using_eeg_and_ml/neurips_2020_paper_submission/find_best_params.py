import numpy as np
import pickle

from ml_tools.classification import classify_loso_model_selection
from ml_tools.classification import create_gridsearch_pipeline
from ml_tools.classification import save_model
from ml_tools.pre_processing import pre_process

import config as cfg

def print_summary(accuracies, group, df):
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
    gs_filename = cfg.OUTPUT_DIR + 'trained_gs.pickle'
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

    # Create the files and save them
    save_model(gs, gs_filename)

    accuracy_file = open(acc_filename, 'ab')
    pickle.dump(accuracies, accuracy_file)
    accuracy_file.close()

    f1_file = open(f1_filename, 'ab')
    pickle.dump(f1s, f1_file)
    f1_file.close()

    cm_file = open(cm_filename, 'ab')
    pickle.dump(cms, cm_file)
    cm_file.close()

    best_params_file = open(best_params_filename, 'ab')
    pickle.dump(best_params, best_params_file)
    best_params_file.close()
