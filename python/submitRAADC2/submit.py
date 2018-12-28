import argparse
from rpy2.robjects.packages import importr
import rpy2.robjects as ro
import pandas as pd
r_submitRAADC2 = importr("submitRAADC2")
from distutils.util import strtobool
import synapseclient

def synapse_login():
	syn = synapseclient.Synapse()
	email = r_submitRAADC2._user_email_prompt()[0]
	try:
		syn.login(email=email)
	except synapseclient.exceptions.SynapseNoCredentialsError as e:
		syn = _new_login(syn, email)
	return(syn)

def _new_login(syn, email):
	print(''.join(r_submitRAADC2._new_login_text()))
	apikey = r_submitRAADC2._api_key_prompt()[0]
	try:
		syn.login(email, apiKey=apikey, rememberMe=True)
	except Exceptions as e:
		raise ValueError("Please double check your email and apiKey combination")
	return(syn)

def submit_raadc2(prediction_filepath, validate_only=False, dry_run=False):
	'''
	Submitting RAAD2 prediction files

	Args:
		prediction_filepath: Filepath of the csv
		validate_only: If 'True', check data for any formatting errors but don't submit to the challenge.
		dry_run: If ‘TRUE', execute submission steps, but don’t store any data in Synapse. 
	'''
	# username = r_submitRAADC2._user_email_prompt()
	# apikey = r_submitRAADC2._api_key_prompt()
	#username = _user_email_prompt()
	#apikey = _api_key_prompt()

	team_info = r_submitRAADC2.get_team_info(owner_id)
	# is_eligible <- check_eligibility(team_info$team_id, owner_id)
	# submission_filename <- .create_submission(predictions, dry_run = dry_run)
	# submission_entity <- .upload_predictions(
    #     submission_filename,
    #     team_info
    #   )
	try:
		confirmation = input("y/n:")
		confirmation = strtobool(confirmation)
	except ValueError as e:
		raise ValueError("Please answer with y/n")
	predictiondf = ro.r['read.csv'](prediction_filepath)
	r_submitRAADC2.submit_raadc2(predictiondf, validate_only=validate_only, dry_run=dry_run)


# def _user_email_prompt():
# 	print(''.join(r_submitRAADC2._user_email_prompt_text()))
# 	return input("Username:")

# def _api_key_prompt():
# 	print(''.join(r_submitRAADC2._api_key_prompt_text()))
# 	return input("API key:")


def build_parser():
    """Builds the argument parser and returns the result."""
    parser = argparse.ArgumentParser()
    parser.add_argument("prediction", help="Prediction filepath")
    parser.add_argument("-v", "--validate_only", help="Validate file only", action='store_true')
    return parser

def main():
    args = build_parser().parse_args()
    submit_raadc2(args.prediction, validate_only=args.validate_only)

if __name__ == "__main__":
    main()
