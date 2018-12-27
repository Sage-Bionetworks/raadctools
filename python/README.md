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
import raadctools
raadctools.submit.submit_predictions("prediction.csv",validate_only=True)
```