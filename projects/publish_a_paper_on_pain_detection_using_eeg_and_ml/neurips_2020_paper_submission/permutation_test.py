import numpy as np
import pickle

from sklearn.svm import LinearSVC

from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression

from ml_tools.classification import create_gridsearch_pipeline
from ml_tools.classification import permutation_test
from ml_tools.pre_processing import pre_process

import config as cfg

# Global Experimental Variable
input_filename = '/lustre03/project/6010672/yacine08/eeg_pain_result/features_all.csv'
output_dir = '/lustre03/project/6010672/yacine08/eeg_pain_result/'
perms_filename = output_dir + 'permutation_test.pickle'

# Classifier for Healthy, MSK and Both
clf = LogisticRegression()

pipe = Pipeline([
    ('imputer', SimpleImputer(missing_values=np.nan, strategy='mean')),
    ('scaler', StandardScaler()),
    ('clf', clf)])

# Train and do the permutaiton test
gs = create_gridsearch_pipeline()
X, y, group, df = pre_process(cfg.DF_FILE_PATH, cfg.PARTICIPANT_TYPE)
acc, perms, p_value = permutation_test(X, y, group, pipe, num_permutation=1000)

# Print out some high level sumarry
print("Random:")
print(np.mean(perms))
print("Actual Improvement")
print(acc)
print("P Value:")
print(p_value)

# Save the data to disk
perms_file = open(perms_filename, 'ab')
pickle.dump(perms, perms_file)
perms_file.close()
