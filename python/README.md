# raadctools

```
pip install git+https://github.roche.com/RAADC2019/submitRAADC2#subdirectory=python
```

## Command line usage

```
raadctools submit prediction.csv -v
```

## Python usage

```
import raadctools
raadctools.submit.submit_predictions("prediction.csv",validate_only=True)
```