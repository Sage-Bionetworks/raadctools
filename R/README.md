## Overview

The **submitRAADC2** wraps the Synapse R client with convenience functions for submitting predictions to the challenge evaluation queue.


## Installation

```r
devtools::install_github(
  "RAADC2019/submitRAADC2", 
  subdir = "R"
)
```

Alternatively, use these steps in the terminal to install the package:
```

git clone https://github.roche.com/RAADC2019/submitRAADC2
cd submitRAADC2/R
Rscript -e 'devtools::install()'
```

**Note:** This package uses the [**getRAADC2**](https://github.roche.com/RAADC2019/getRAADC2) package for functions related to validating data.

The **`submitRAADC2`** package should be loaded by default when you start a R new session in the **Portable Analytics** platform. If not, use this command to get started:
```r
library(submitRAADC2)
```

### Requirements

...

## Usage

You'll be generating a 2-column dataframe for your predictions. It should be formatted like `d_predictions` here (note: the name of your dataframe object doesn't matter).
```r
set.seed(2018)
d_predictions <- data.frame(
  PatientID = submitRAADC2::patient_ids,
  RespondingSubgroup = rep(c("Tecentriq","Chemo"), 500)
)
head(d_predictions)
```

```
    PatientID RespondingSubgroup
1 RAADCV00001 Tecentriq
2 RAADCV00003     Chemo
3 RAADCV00004 Tecentriq
4 RAADCV00005     Chemo
5 RAADCV00006 Tecentriq
6 RAADCV00007     Chemo
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
submit_raadc2(d_predictions)
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

It looks like this is your first time connecting to Synapse during
this R session. Let's store your credentials so that you won't need to
enter them again (during this session).

To find your API key:

    1. Log into www.synapse.org
    2. Click on your profile in the upper right of the page; see the Synapse
       docs on User Profiles for more details: 
       https://docs.synapse.org/articles/user_profiles.html
    3. Click on 'Settings' tab
    4. Click 'Show API key' at the bottom of the page; you can copy and paste
       the key directly into your console.

API key: <your-synapse-api-key>

Checking ability to submit...

 > Team: Your team, RAAD2 ADTest, is eligible to submit.
 > User: You're eligible to submit for your team.

Each team is allotted a total of THREE valid submissions to the challenge. 
You can submit anytime between February 19th and March 15th — it's up to
you and your team to decide when to submit predictions within the open
window. You will be able to see your score on the leaderboard only for your
FIRST TWO submissions. Once your team has reached its quota, you will not 
be able to submit again. 

Are you sure you want to submit?

1: Yes
2: No

Selection: 1

Writing data to local CSV file...

Uploading prediction file to Synapse...

Submitting prediction to challenge evaluation queue...

Successfully submitted file: 'prediction.csv'
 > stored as 'syn17173759' [version: 1]
 > submission ID: '9684379'

You can find the file with your predictions ('prediction.csv') on the RAAD2
Synapse project at
https://www.synapse.org/#!Synapse:syn17173759
```

## Troubleshooting

```r
To find your API key:

    1. Log into www.synapse.org
    2. Click on your profile in the upper right of the page; see the Synapse
       docs on User Profiles for more details: 
       https://docs.synapse.org/articles/user_profiles.html
    3. Click on 'Settings' tab
    4. Click 'Show API key' at the bottom of the page; you can copy and paste
       the key directly into your console.

API key: notreallyakey
Error: Something went wrong with the attempt too log you into Synapse. Please doublecheck your email and API key combination.
```


```r
Username: james.eddy@sagebase.org
Welcome, James Eddy!

Error: This Synapse account does not appear to be part of any RAAD2 Challenge 
teams. Did you mean to use a different account? Make sure to use the account 
associated with your @gene.com or @roche.com email address.
```


```r
Checking ability to submit...

 > Team: Your team, RAAD2 ADTest, is not eligible to submit at this time. The 
 team has filled its quota of 3 submissions for the challenge. 

Error: Exiting submission attempt.
Visit the RAAD2 Challenge page in Synapse to track results in the leaderboard.
```
