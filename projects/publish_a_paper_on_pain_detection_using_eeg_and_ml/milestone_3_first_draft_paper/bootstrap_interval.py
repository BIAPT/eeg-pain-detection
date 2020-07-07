import pickle

# Data manipulation
import numpy as np

# Library import
from ml_tools.classification import bootstrap_interval
from ml_tools.pre_processing import pre_process

from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.impute import SimpleImputer

from sklearn.svm import LinearSVC
from sklearn.linear_model import LogisticRegression

import config as cfg


# Setup the experiment to test the above function
output_dir = '/lustre03/project/6010672/yacine08/eeg_pain_result/'
bootstrap_filename = output_dir + 'bootstrap.pickle'

# Classifier for Healthy, MSK and Both
clf = LogisticRegression()

pipe = Pipeline([
    ('imputer', SimpleImputer(missing_values=np.nan, strategy='mean')),
    ('scaler', StandardScaler()),
    ('SVM', clf)])

# Training and bootstrap interval generation
X, y, group, df = pre_process(cfg.DF_FILE_PATH, cfg.PARTICIPANT_TYPE)
acc_distribution, acc_interval = bootstrap_interval(X, y, group, pipe, num_resample=1000, p_value=0.05)

# Save the data to disk
bootstrap_file = open(bootstrap_filename, 'ab')
bootstrap_data = {
    'distribution': acc_distribution,
    'interval': acc_interval
}
pickle.dump(bootstrap_data, bootstrap_file)
bootstrap_file.close()

# Print out some high level sumarry
print("F1 Distribution:")
print(acc_distribution)
print(f"Mean: {np.mean(acc_distribution)} and std: {np.std(acc_distribution)}")
print("Bootstrap Interval")
print(acc_interval)
