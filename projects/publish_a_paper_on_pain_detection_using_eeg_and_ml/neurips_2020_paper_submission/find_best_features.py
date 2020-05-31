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
features_filename = output_dir + 'features.pickle'

# TO MODIFY!
clf = LinearSVC(C=1)
pipe = Pipeline([
    ('imputer', SimpleImputer(missing_values=np.nan, strategy='mean')),
    ('scaler', StandardScaler()),
    ('SVM', clf)])

# Training and bootstrap interval generation
X, y, group, df = pre_process(input_filename)

# Fitting the classifier with all the data
pipe.fit(X, y)
clf = pipe.steps[2][1]
feature_weights = clf.coef_[0]


feature_df = df.drop(['id', 'is_hot'], axis=1)
feature_names = list(feature_df.columns.values)


# Save the data to disk
features_file = open(features_filename, 'ab')
features_data = {
    'weight': feature_weights,
    'name': feature_names
}
pickle.dump(features_data, features_file)
features_file.close()

# Print out some high level sumary
print("Features:")
for weight, name in zip(feature_weights, feature_names):
    print(f"Feature {name} has weights: {weight}")