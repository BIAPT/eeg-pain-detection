from math import floor
import numpy as np

from sklearn.metrics import accuracy_score
from sklearn.model_selection import LeaveOneGroupOut
from sklearn.model_selection import permutation_test_score
from sklearn.utils import resample

from sklearn.pipeline import Pipeline
from sklearn.base import BaseEstimator
from sklearn.model_selection import GridSearchCV

from sklearn.linear_model import LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.svm import SVC

from sklearn.preprocessing import StandardScaler
from sklearn.impute import SimpleImputer

import joblib
from dask.distributed import Client, progress


def classify_loso(X, y, group, clf):
    """ Main classification function to train and test a ml model with Leave one subject out

        Args:
            X (numpy matrix): this is the feature matrix with row being a data point
            y (numpy vector): this is the label vector with row belonging to a data point
            group (numpy vector): this is the group vector (which is a the participant id)
            clf (sklearn classifier): this is a classifier made in sklearn with fit, transform and predict functionality

        Returns:
            accuracies (list): the accuracy at for each leave one out participant
    """
    logo = LeaveOneGroupOut()

    accuracies = []
    for train_index, test_index in logo.split(X, y, group):
        X_train, X_test = X[train_index], X[test_index]
        y_train, y_test = y[train_index], y[test_index]

        clf.fit(X_train, y_train)
        y_hat = clf.predict(X_test)

        accuracy = accuracy_score(y_test, y_hat)
        accuracies.append(accuracy)
    return accuracies


def classify_loso_model_selection(X, y, group, gs):
    """ This do classification using LOSO while also doing model selection using LOSO

        Args:
            X (numpy matrix): this is the feature matrix with row being a data point
            y (numpy vector): this is the label vector with row belonging to a data point
            group (numpy vector): this is the group vector (which is a the participant id)
            gs (sklearn GridSearchCV): this is a gridsearch object that will output the best model

        Returns:
            accuracies (list): the accuracy at for each leave one out participant
    """

    logo = LeaveOneGroupOut()

    accuracies = []
    best_params = []
    num_folds = logo.get_n_splits(X, y, group) # keep track of how many folds left
    for train_index, test_index in logo.split(X, y, group):
        X_train, X_test = X[train_index], X[test_index]
        y_train, y_test = y[train_index], y[test_index]
        group_train, group_test = group[train_index], group[test_index]

        print(f"Number of folds left: {num_folds}")

        # Here we use Dask to be able to train on all the core on a cluster
        with joblib.parallel_backend('dask'):
            gs.fit(X_train, y_train, groups=group_train)

        y_hat = gs.predict(X_test)

        accuracy = accuracy_score(y_test, y_hat)

        accuracies.append(accuracy)
        best_params.append(gs.best_params_)

        num_folds = num_folds - 1
    return accuracies, best_params


def permutation_test(X, y, group, clf, num_permutation=1000):
    """ Helper function to validate that a classifier is performing higher than chance

        Args:
            X (numpy matrix): this is the feature matrix with row being a data point
            y (numpy vector): this is the label vector with row belonging to a data point
            group (numpy vector): this is the group vector (which is a the participant id)
            clf (sklearn classifier): this is a classifier made in sklearn with fit, transform and predict functionality
            num_permutation (int): the number of time to permute y
            random_state (int): this is used for reproducible output
        Returns:
            accuracies (list): the accuracy at for each leave one out participant

    """

    logo = LeaveOneGroupOut()
    train_test_splits = logo.split(X, y, group)
    (accuracy, permutation_scores, p_value) = permutation_test_score(clf, X, y, groups=group, cv=train_test_splits,
                                                                     n_permutations=num_permutation,
                                                                     verbose=num_permutation, n_jobs=-1)
    return accuracy, permutation_scores, p_value


def bootstrap_interval(X, y, group, clf, num_resample=1000, p_value=0.05):
    """Create a confidence interval for the classifier with the given p value

        Args:
            X (numpy matrix): The feature matrix with which we want to train on classifier on
            y (numpy vector): The label for each row of data point
            group (numpy vector): The group id for each row in the data (correspond to the participant ids)
            clf (sklearn classifier): The classifier that we which to train and validate with bootstrap interval
            num_resample (int): The number of resample we want to do to create our distribution
            p_value (float): The p values for the upper and lower bound

        Returns:
            acc_distribution (float vector): the distribution of all the accuracies
            acc_interval (float vector): a lower and upper interval on the accuracies corresponding to the p value
    """

    acc_distribution = []
    for sample_id in range(num_resample):
        print("Bootstrap sample #" + str(sample_id))

        # Get the sampled with replacement dataset
        sample_X, sample_y, sample_group = resample(X, y, group)

        # Classify and get the results
        accuracies = classify_loso(sample_X, sample_y, sample_group, clf)
        acc_distribution.append(np.mean(accuracies))

    # Sort the results
    acc_distribution.sort()

    # Set the confidence interval at the right index
    lower_index = floor(num_resample * (p_value / 2))
    upper_index = floor(num_resample * (1 - (p_value / 2)))
    acc_interval = acc_distribution[lower_index], acc_distribution[upper_index]

    return acc_distribution, acc_interval


def create_gridsearch_pipeline():
    """ Helper function to create a gridsearch with a search space containing classifiers

        Returns:
            gs (sklearn gridsearch): this is the grid search objec wrapping the pipeline
    """

    # Create LOSO Grid Search to search amongst many classifier
    class DummyEstimator(BaseEstimator):
        """Dummy estimator to allow gridsearch to test many estimator"""

        def fit(self): pass

        def score(self): pass

    # Create a pipeline
    pipe = Pipeline([
        ('imputer', SimpleImputer(missing_values=np.nan, strategy='mean')),
        ('scaler', StandardScaler()),
        ('clf', DummyEstimator())])  # Placeholder Estimator

    # Candidate learning algorithms and their hyperparameters
    search_space = [{'clf': [LogisticRegression()],  # Actual Estimator
                     'clf__penalty': ['l1', 'l2'],
                     'clf__solver': ['saga'],
                     'clf__max_iter': [1000],
                     'clf__C': np.logspace(0, 4, 10)},

                    {'clf': [SVC()],
                     'clf__kernel': ['linear'],
                     'clf__C': [1, 10, 100, 1000]},

                    {'clf': [DecisionTreeClassifier()],  # Actual Estimator
                     'clf__criterion': ['gini', 'entropy']}]

    # We will try to use as many processor as possible for the gridsearch
    gs = GridSearchCV(pipe, search_space, cv=LeaveOneGroupOut(), n_jobs=-1)
    return gs