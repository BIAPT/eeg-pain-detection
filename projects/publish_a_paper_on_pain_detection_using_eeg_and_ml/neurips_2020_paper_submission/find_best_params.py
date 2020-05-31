# Goal of this task is to run the classification of pain/no pain on compute Quebec
# with an increase amount of cores, the only part that is actually making use of parallelization is
# the Gridsearch loop for model selections (Which is looking at quite a few models).
# We will pickle all the objects we will want to investigate afterward and will make sure
# we have some decent outputs

import numpy as np
import pickle

from ml_tools.classification import classify_loso_model_selection
from ml_tools.classification import create_gridsearch_pipeline
from ml_tools.classification import save_model
from ml_tools.pre_processing import pre_process

from sklearn.linear_model import LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.svm import LinearSVC

import config as cfg

def find_best_model(best_params):
    models_occurence = {}
    for param in best_params:
        clf = param['clf']
        if isinstance(clf, LogisticRegression):
            key = "LOG" + "_penality=" + str(clf.penalty) + "_C=" + str(clf.C)
        elif isinstance(clf, LinearSVC):
            key = "SVC" + "_kernel=linear_C=" + str(clf.C)
        elif isinstance(clf, DecisionTreeClassifier):
            key = "DEC" + "_criterion" + str(clf.criterion)

        if key not in models_occurence:
            models_occurence[key] = 1
        else:
            models_occurence[key] = models_occurence[key] + 1

    return models_occurence


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
    input_filename = '/lustre03/project/6010672/yacine08/eeg_pain_result/features_all.csv'
    output_dir = '/lustre03/project/6010672/yacine08/eeg_pain_result/'
    gs_filename = output_dir + 'trained_gs.pickle'
    acc_filename = output_dir + 'accuracies_result.pickle'
    f1_filename = output_dir + 'f1s_result.pickle'
    best_params_filename = output_dir + 'best_params.pickle'


    # Actual Training
    gs = create_gridsearch_pipeline()
    X, y, group, df = pre_process(input_filename, cfg.PARTICIPANT_TYPE)
    accuracies, f1s, best_params = classify_loso_model_selection(X, y, group, gs)

    # Print out the summary in the console
    print_summary(accuracies, group, df)

    # Find te best model by looking at the occurence of the model parameters
    model_occurence = find_best_model(best_params)
    print(model_occurence)

    # Create the files and save them
    save_model(gs, gs_filename)

    accuracy_file = open(acc_filename, 'ab')
    pickle.dump(accuracies, accuracy_file)
    accuracy_file.close()

    f1_file = open(f1_filename, 'ab')
    pickle.dump(f1s, f1_file)
    f1_file.close()

    best_params_file = open(best_params_filename, 'ab')
    pickle.dump(model_occurence, best_params_file)
    best_params_file.close()