# raadctools

```shell
pip install git+https://github.roche.com/RAADC2019/submitRAADC2#subdirectory=python
```

## Command line usage

```shell
submitRAADC2 submit prediction.csv -v
```

## Python usage

You'll be generating a 2-column dataframe for your predictions. It should be formatted like `prediction_df` here (note: the name of your dataframe object doesn't matter).
```
import pandas as pd
import submitRAADC2
patient_ids = submitRAADC2.submit.patient_ids()
subgroups = pd.np.repeat(['Tecentriq', 'Chemo'], [500, 500]).tolist()
prediction_df = pd.DataFrame(
    {"PatientID": patient_ids,
     "RespondingSubgroup": subgroups
    }
)
prediction_df.head()
```

```
     PatientID  RespondingSubgroup
0  RAADCV00001  Tecentriq
1  RAADCV00003  Tecentriq
2  RAADCV00004  Tecentriq
3  RAADCV00005  Tecentriq
4  RAADCV00007  Tecentriq
```

To check your predictions for any formatting errors, run the following command:
```r
submitRAADC2.submit_raadc2(prediction_df, validate_only=True)
```

When you're ready to submit your prediction to the RAAD Challenge evaluation queue, simply run this command:
```
submitRAADC2.submit_raadc2(prediction_df)
```

Note, this is an equivalent way to import an use the function:
```
from submitRAADC2 import submit_raadc2
submit_raadc2(prediction_df)
```

You'll be guided through a series with progress messages and prompts. A typical workflow for a first-time user would look like this:

```
Running checks to validate date frame format...

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
Welcome, eddyj1@gene.com!

Checking ability to submit...

 > Team: Your team, RAAD2 ADTest, is eligible to submit.
 > User: You're eligible to submit for your team.

Each team is allotted a total of TWO valid submissions to the challenge. 
You can submit anytime between February 14th and March 15th — it's up to
you and your team to decide when to submit predictions within the open
window. Once your team has reached its quota, you will not be able to 
submit again until.

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
Challenge Synapse project at
https://www.synapse.org/#!Synapse:syn17173759
```
