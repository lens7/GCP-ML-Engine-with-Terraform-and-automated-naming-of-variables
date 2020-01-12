# GCP-ML-Engine-with-Terraform-and-automated-naming-of-variables

This terraform script creates a ML Engine job in GCP using various components of Terraform and gcloud shell combined.
The variable names are timestamped and thus every time a timestamp is added to your variable names inside of variables.tf file.

The probability of getting a same name is very low as a real time timestamp is added on the fly, we can also alter this to provide more and more configurability to the code.

https://cloud.google.com/ml-engine/docs/tensorflow/getting-started-training-prediction
This script automates the above procedure and helps reduce manual inputs and saves time
