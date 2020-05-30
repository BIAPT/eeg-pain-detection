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
    output_dir = '/lustre03/project/6010672/yacine08/eeg_pain_result/'
    gs_filename = output_dir + 'trained_gs.pickle'
    acc_filename = output_dir + 'accuracies_result.pickle'
    f1_filename = output_dir + 'f1s_result.pickle'
    best_params_filename = output_dir + 'best_params.pickle'

    gs = create_gridsearch_pipeline()
    X, y, group, df = pre_process(input_filename)
    
    accuracies, f1s, best_params = classify_loso_model_selection(X, y, group, gs)

    # Create the files and save them
    save_model(gs, gs_filename)

    accuracy_file = open(acc_filename, 'ab')
    pickle.dump(accuracies, accuracy_file)
    accuracy_file.close()

    f1_file = open(f1_filename, 'ab')
    pickle.dump(f1s, f1_file)
    f1_file.close()

    best_params_file = open(best_params_filename, 'ab')
    pickle.dump(best_params, best_params_file)
    best_params_file.close()