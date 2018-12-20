import argparse
from rpy2.robjects.packages import importr
import rpy2.robjects as ro
import pandas as pd
raadctools = importr("submitRAADC2")


def submit_predictions(prediction_filepath, validate_only=False, dry_run=False):
	'''
	Submitting RAAD2 prediction files

	Args:
		prediction_filepath: Filepath of the csv
		validate_only: If 'True', check data for any formatting errors but don't submit to the challenge.
		dry_run: If ‘TRUE', execute submission steps, but don’t store any data in Synapse. 
	'''
	predictiondf = ro.r['read.csv'](prediction_filepath)
	raadctools.submit_raadc2(predictiondf, validate_only=validate_only, dry_run=dry_run)


def build_parser():
    """Builds the argument parser and returns the result."""
    parser = argparse.ArgumentParser()
    parser.add_argument("prediction", help="Prediction filepath")
    parser.add_argument("-v", "--validate_only", help="Validate file only",action='store_true')
    return parser

def main():
    args = build_parser().parse_args()
    submit_predictions(args.prediction, validate_only=args.validate_only)

if __name__ == "__main__":
    main()
