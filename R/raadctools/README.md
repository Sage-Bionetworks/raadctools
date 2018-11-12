# RAAD Challenge tools for R

The **`raadctools`** package should be loaded by default when you start a R new session in the **Portable Analytics** platform. If not, use this command to get started:
```r
library(raadctools)
```

You'll be generating a 2-column dataframe for your predictions. It should be formatted like `prediction_df` here (note: the name of your dataframe object doesn't matter).
```r
head(prediction_df)

```

```r
  Subject SubPopulation
1       1             Y
2       2             N
3       3             Y
4       4             N
5       5             Y
6       6             N
```

When you're ready to submit your prediction to the RAAD Challenge evaluation queue, simply run this command:
```r
submit_predictions(prediction_df)
```

You'll be guided through a series with progress messages and prompts.


