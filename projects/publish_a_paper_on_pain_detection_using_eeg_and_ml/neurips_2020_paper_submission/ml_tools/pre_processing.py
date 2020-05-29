import pandas as pd

# Helper dict
POPULATION_ID = {
    "MSK": 0,
    "HEALTHY": 1,
    "BOTH": 2
}


def pre_process(input_filename, population_id="BOTH"):
    """This function load, reshape and clean up the data frame so that it is amenable for machine learning

        Args:
            input_filename (string): This is the path to the data which should be in csv
            population_id (string): We can get either MSK, HEALTHY or BOTH

        Returns:
            X: the features for this data in the form of a matrix
            y: the label vector for the data which in this analysis is 0 or 1
            group: the group vector for the data which tell which user the row below, used for
            Leave-One-Subject-Out (LOSO) cross validation
    """

    # Read the CSV
    df = pd.read_csv(input_filename)

    # Get the right population
    if population_id != "BOTH":
        df = df[df.type == POPULATION_ID[population_id]]

    # We had this weird column appearing so we will remove it
    df.drop(df.filter(regex="Unnamed"), axis=1, inplace=True)

    # Increment the id for the MSK so that we don't have the same id for
    # both healthy and msk participant
    df.loc[df['type'] == 0, ['id']] += 1000

    # Extract the right information for ml part
    if population_id == 'BOTH':
        X = df.drop(['id', 'is_hot'], axis=1).to_numpy()
    else:
        X = df.drop(['id', 'type', 'is_hot'], axis=1).to_numpy()

    y = df.is_hot.to_numpy()
    group = df.id.to_numpy()

    return X, y, group, df
