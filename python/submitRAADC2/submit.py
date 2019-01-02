import argparse
from rpy2.robjects.packages import importr
import rpy2.robjects as ro
import pandas as pd
r_submitRAADC2 = importr("submitRAADC2")
from distutils.util import strtobool
import synapseclient

def synapse_login():
	'''
	Logging into Synapse assuming the user has logged in before.
	If not, _new_login is called.

	Returns:
		Synapse object
	'''
	syn = synapseclient.Synapse()
	email = r_submitRAADC2._user_email_prompt()[0]
	try:
		syn.login(email=email)
	except synapseclient.exceptions.SynapseNoCredentialsError as e:
		syn = _new_login(syn, email)
	return(syn)

def _new_login(syn, email):
	'''
	New login for users, prompts for API key.

	Args:
		syn: Synapse object
		email: User email

	Returns:
		Synapse Object
	'''
	print(''.join(r_submitRAADC2._new_login_text()))
	apikey = r_submitRAADC2._api_key_prompt()[0]
	try:
		syn.login(email, apiKey=apikey, rememberMe=True)
	except Exceptions as e:
		raise ValueError("Please double check your email and apiKey combination")
	return(syn)

def _lookup_prediction_folder(syn, teamname):
	'''
	Looks up team's prediction folder

	Args:
		syn: Synapse object
		teamname: Name of team
	'''
	submission_folder = "syn17097318"
	teamname = teamname.replace("RAAD2 ",'')
	folder_items = syn.getChildren(submission_folder)
	prediction_folder = filter(lambda folders: folders['name'] == teamname, folder_items)
	return(list(prediction_folder)[0]['id'])

def get_team_info(syn, ownerid):
	'''
	Get team information

	Args:
		syn: Synapse object
		ownerid: Synapse userid

	Returns:
		dict: team id, team name, folder id
	'''
	owner_teams = syn.restGET("/user/{id}/team/id".format(id = ownerid))
	owner_team_ids = owner_teams['teamIds']

	for teamid in owner_team_ids:
		team_object = syn.getTeam(teamid)
		teamname = team_object['name']
		if "Participants" not in teamname and "Admin" not in teamname and teamname.startswith("RAAD2 "):
			raad2_team = team_object
			break
		else:
			raad2_team =None
	team_folder_id = _lookup_prediction_folder(syn, raad2_team['name'])
	return({'team_id':raad2_team['id'],'team_name':raad2_team['name'],'folder_id':team_folder_id})

def _lookup_owner_id(syn):
	'''
	Lookup Owner Id

	Args:
		syn: Synapse object

	Returns:
		Owner id
	'''
	user_profile = syn.getUserProfile()
	return(user_profile['ownerId'])


def _get_eligibility_data(syn, teamid):
 	evalid = "9614112"
 	eligibility_data = syn.restGET('/evaluation/{evalId}/team/{id}/submissionEligibility'.format(evalId = evalid, id = teamid))
 	return(eligibility_data)


def _get_owner_eligibility(eligibility_data, ownerid):
	member_eligible = filter(lambda member: member['principalId'] == int(ownerid), eligibility_data['membersEligibility'])
	return(list(member_eligible)[0])


def check_eligibility(syn, team_info, ownerid):

	eligibility_data = _get_eligibility_data(syn, team_info['team_id'])
	team_eligibility = eligibility_data['teamEligibility']
	owner_eligibility = _get_owner_eligibility(eligibility_data, ownerid)

	#Need to fix print statements
	#print(' > Team: {0}'.format(team_obj['name']) + ''.join(r_submitRAADC2._team_eligibility_msg(team_eligibility)))
	#.owner_eligibility_msg

	return(team_eligibility['isEligible'] and owner_eligibility['isEligible'])

def submit_raadc2(prediction_filepath, validate_only=False, dry_run=False):
	'''
	Submitting RAAD2 prediction files

	Args:
		prediction_filepath: Filepath of the csv
		validate_only: If 'True', check data for any formatting errors but don't submit to the challenge.
		dry_run: If ‘TRUE', execute submission steps, but don’t store any data in Synapse. 
	'''

	syn = synapse_login()
	ownerid = _lookup_owner_id(syn)
	team_info = get_team_info(syn, ownerid)
	is_eligible = check_eligibility(syn, team_info, ownerid)
	is_certified = True
	if not is_eligible and not is_certified:
		raise ValueError("Exiting submission attempt.")

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
