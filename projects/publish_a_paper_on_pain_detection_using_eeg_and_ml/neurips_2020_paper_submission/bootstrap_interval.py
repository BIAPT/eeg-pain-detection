from math import floor
import pickle

# Data manipulation
import numpy as np
import pandas as pd

from sklearn.utils import resample

# Library import
from ml_tools.classification import classify_loso
from ml_tools.pre_processing import pre_process
from ml_tools.classification import bootstrap_interval

from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.impute import SimpleImputer
from sklearn.svm import SVC

from math import floor

# Data manipulation
import numpy as np
import pandas as pd

from sklearn.utils import resample

# Library import
from ml_tools.classification import classify_loso
from ml_tools.pre_processing import pre_process

from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.impute import SimpleImputer
from sklearn.svm import SVC
from sklearn.svm import LinearSVC


# Setup the experiment to test the above function
input_filename = '/lustre03/project/6010672/yacine08/eeg_pain_result/features_all.csv'
output_dir = '/lustre03/project/6010672/yacine08/eeg_pain_result/'
bootstrap_filename = output_dir + 'bootstrap.pickle'

clf = LinearSVC(C=1)
pipe = Pipeline([
    ('imputer', SimpleImputer(missing_values=np.nan, strategy='mean')),
    ('scaler', StandardScaler()),
    ('SVM', clf)])

# Training and bootstrap interval generation
X, y, group = pre_process(input_filename)
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
print("Accuracy Distribution:")
print(acc_distribution)
print(f"Mean: {np.mean(acc_distribution)} and std: {np.std(acc_distribution)}")
print("Bootstrap Interval")
print(acc_interval)