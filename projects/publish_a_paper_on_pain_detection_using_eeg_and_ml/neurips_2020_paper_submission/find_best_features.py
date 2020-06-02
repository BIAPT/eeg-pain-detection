import pickle

# Data manipulation
import numpy as np

# Library import
from ml_tools.pre_processing import pre_process

from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.impute import SimpleImputer

from sklearn.svm import LinearSVC
from sklearn.linear_model import LogisticRegression

# Configuration for this experiment
import config as cfg


# Setup the experiment to test the above function
output_dir = '/lustre03/project/6010672/yacine08/eeg_pain_result/'
features_filename = output_dir + 'features.pickle'

# TO MODIFY!
# clf = LinearSVC(C=10) #Both
clf = LogisticRegression() #healthy
pipe = Pipeline([
    ('imputer', SimpleImputer(missing_values=np.nan, strategy='mean')),
    ('scaler', StandardScaler()),
    ('SVM', clf)])

# Training and bootstrap interval generation
X, y, group, df = pre_process(cfg.DF_FILE_PATH, cfg.PARTICIPANT_TYPE)

# Fitting the classifier with all the data
pipe.fit(X, y)
clf = pipe.steps[2][1]
feature_weights = clf.coef_[0]

features = df.drop(['id', 'is_hot'], axis=1)
feature_names = list(features.columns.values)

# Save the data to disk
features_file = open(features_filename, 'ab')

features_data = {
    'weight': feature_weights,
    'name': feature_names
}

pickle.dump(features_data, features_file)
features_file.close()

# Print out some high level summary
print(features_data)
print("Num Weights: ")
print(len(feature_weights))
print("Num Names: ")
print(len(feature_names))
print("Features:")
for weight, name in zip(feature_weights, feature_names):
    print(f"Feature {name} has weights: {weight}")