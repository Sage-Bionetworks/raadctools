# raadctools

```
pip install git+https://github.roche.com/RAADC2019/submitRAADC2#subdirectory=python
```

## Command line usage

```
submitRAADC2 submit prediction.csv -v
```

## Python usage

```
import pandas as pd
import submitRAADC2
predictiondf = pd.DataFrame({"PatientID":range(0,400),"RespondingSubgroup":pd.np.repeat(["Tecentriq","Chemo"],[200,200]).tolist()})

submitRAADC2.submit.submit_raadc2(predictiondf)
```