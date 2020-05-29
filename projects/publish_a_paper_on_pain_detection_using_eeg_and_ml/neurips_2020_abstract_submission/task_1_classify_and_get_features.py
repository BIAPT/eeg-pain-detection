# Goal of this task is to run the classification of pain/no pain on compute Quebec
# with an increase amount of cores, the only part that is actually making use of parallelization is
# the Gridsearch loop for model selections (Which is looking at quite a few models).
# We will pickle all the objects we will want to investigate afterward and will make sure
# we have some decent outputs

import pickle

from ml_tools.classification import classify_loso_model_selection
from ml_tools.classification import create_gridsearch_pipeline
from ml_tools.classification import save_model
from ml_tools.pre_processing import pre_process




if __name__ == '__main__':
    # Global Experimental Variable
    input_filename = '/lustre03/project/6010672/yacine08/eeg_pain_result/features_all.csv'
    #input_filename = '/home/yacine/Documents/features_all.csv'
    gs = create_gridsearch_pipeline()
    X, y, group, df = pre_process(input_filename)
    accuracies, best_params = classify_loso_model_selection(X, y, group, gs)

    # Create the files and save them
    save_model(gs, 'trained_gs.pickle')

    accuracy_file = open('accuracies_result', 'ab')
    best_params_file = open('best_params', 'ab')

    pickle.dump(accuracies, accuracy_file)
    accuracy_file.close()

    pickle.dump(best_params, best_params_file)
    best_params_file.close()