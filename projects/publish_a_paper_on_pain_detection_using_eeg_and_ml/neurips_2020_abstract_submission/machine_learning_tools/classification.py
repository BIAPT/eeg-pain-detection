from sklearn.metrics import accuracy_score
from sklearn.model_selection import LeaveOneGroupOut
from sklearn.model_selection import permutation_test_score


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
