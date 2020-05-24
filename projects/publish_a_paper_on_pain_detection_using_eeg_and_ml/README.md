# Publish a paper on Pain detection usgin EEG and ML
The goal of this project is to publish a paper using the dataset we currently that delves in recognizing pain using EEG signal by building a ML model. We want something solid and interpretable.

## NeurIPS 2020 (Deadline is May 27)
The first step is to send this out to a big conference in ML, it's a 5-6 page write up so we need to have some decent result to show. They have a neuroscience section so we have a good shot at this.

### Model to use (classification of pain and no-pain)
- Linear SVM
- Linear Regression
- Decision Trees

All of them are available on Sklearn, we want to use a white-box model so that we can interpret what the weights output are.

### Minimal Features To Use
- wPLI at Delta, Theta, Alpha, Beta
- Power at Delta, Theta, Alpha, Beta
- Peak frequency at (6-14Hz)

### Feature to add later on
- AEC
- Graph Theory feature (Degree, Clustering Coefficient, small worldness, efficiency)