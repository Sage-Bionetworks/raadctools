## Overview

The **submitRAADC2** wraps the Synapse R client with convenience functions for submitting predictions to the challenge evaluation queue.


## Installation

```r
devtools::install_github(
  "RAADC2019/submitRAADC2", 
  subdir = "R",
  host = "https://github.roche.com/api/v3"
)
```

Alternatively, use these steps in the terminal to install the package:
```
git clone https://github.roche.com/RAADC2019/submitRAADC2
cd R
Rscript -e 'devtools::install()'
```

**Note:** This package uses the [**getRAADC2**](https://github.roche.com/RAADC2019/getRAADC2) package for functions related to validating data.

The **`submitRAADC2`** package should be loaded by default when you start a R new session in the **Portable Analytics** platform. If not, use this command to get started:
```r
library(submitRAADC2)
```

## Administrative setup

The submission package assumes that Synapse credentials for an admin service account are stored locally at `~/.synapseConfig`. In other words, the **synapser** command `synLogin()` (with no additional arguments) should be sufficient to log in with the service account.

## Usage

You'll be generating a 2-column dataframe for your predictions. It should be formatted like `d_predictions` here (note: the name of your dataframe object doesn't matter).
```r
set.seed(2018)
d_predictions <- data.frame(
  PatientID = paste0("Pat",1:400),
  RespondingSubgroup = rep(c("Tecentriq","Chemo"), 200)
)

head(d_predictions)
```

```
  PatientID RespondingSubgroup
1      Pat1          Tecentriq
2      Pat2              Chemo
3      Pat3          Tecentriq
4      Pat4              Chemo
5      Pat5          Tecentriq
6      Pat6              Chemo
```

To check your predictions for any formatting errors, run the following command:
```r
submit_raadc2(d_predictions, validate_only = TRUE)
```

If any errors are found, you'll see a message that looks like this:
```
Running checks to validate data frame format...

 Error in getRAADC2::validate_predictions(predictions) : 
  Predictions not of the format PatientID,RespondingSubgroup 
```

Otherwise, you should see:
```
Running checks to validate data frame format...

All checks passed.
```

When you're ready to submit your prediction to the RAAD Challenge evaluation queue, simply run this command:
```r
submit_raadc2(prediction_df)
```

You'll be guided through a series with progress messages and prompts. A typical workflow for a first-time user would look like this:

```
Running checks to validate data frame format...

All checks passed.

Enter your Synapse user email.

Your username should be the same as what you use to log into Synapse
with your Google credentials, for example:
'adamsd42@gene.com' or 'smith.joe@roche.com'

Username: eddyj1@gene.com

It looks like this is your first time connecting to Synapse from this
machine. Let's store your credentials so that you won't need to enter
them in the future (unless you switch to a different machine).


For instructions on how to find your API key, refer to this page on
the RAAD Challenge Synapse project:
https://www.synapse.org/#!Synapse:syn16910051/wiki/584268

API key: <your-synapse-api-key>

Checking ability to submit...

 > Team: Your team, CompOncInfra, is eligible to submit.
 > User: You're eligible to submit for your team.

Each team is allotted ONE submission per 24 hours. After submitting
these predictions, you will not be able to submit again until tomorrow.

Are you sure you want to submit? 

1: Yes
2: No

Selection: 1

Writing data to local CSV file...

Uploading prediction file to Synapse...

Uploading [####################]100.00%   5.8kB/5.8kB  prediction.csv Done...    age ##################################################

Submitting prediction to challenge evaluation queue...

Successfully submitted file: 'prediction.csv'
 > stored as 'syn17093036'
 > submission ID: '9684081'

You can find the file with your predictions ('prediction.csv') on your team's
Synapse project at
https://www.synapse.org/#!Synapse:syn17093036
```

