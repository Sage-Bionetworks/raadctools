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
    teamname = teamname.replace("RAAD2 ",'', 1)
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
    '''
    Getting team and team members eligibilty to submit
    
    Args:
        syn: Synapse object
        teamid: Synapse team id

    Returns:
        dict: Eligibility data dict containing teamId, evaluationId, teamEligibility, membersEligibility, and eligibilityStateHash
    '''
    evalid = "9614112"
    eligibility_data = syn.restGET('/evaluation/{evalId}/team/{id}/submissionEligibility'.format(evalId = evalid, id = teamid))
    return(eligibility_data)

def _get_owner_eligibility(eligibility_data, ownerid):
    '''
    Gets owner eligibility

    Args:
        eligibility_data: Response from _get_eligibility_data()
        ownerid: Synapse user id

    Returns:
        dict: Eligbility of member dict containing isEligible, isRegistered, isQuotaFilled, principalId, and hasConflictingSubmission
    '''
    member_eligible = filter(lambda member: member['principalId'] == int(ownerid), eligibility_data['membersEligibility'])
    return(list(member_eligible)[0])


def _team_eligibility_message(team_eligibility, teamname):
    '''
    Gets list of team eligibility messages

    Args:
        team_eligibility:  A dictionary containing isEligible, isQuotaFilled, and isRegistered
        teamname: Team name

    Returns:
        list: Team eligibility messages
    '''
    starter = " > Team : "
    if team_eligibility['isEligible']:
        messages = [starter + "Your team, {name}, is eligible to submit.".format(name=teamname)]
    else:
        messages = [starter + "Your team, {name}, is not eligible to submit at this time.".format(name=teamname)]
        if team_eligibility['isQuotaFilled']:
            messages.append(starter + "The team has reached its submission quota for this 24 hour period.")
        else:
            pass
        if not team_eligibility['isRegistered']:
            messages.append(starter + "The team is not registered for the challenge.")
        else:
            pass 
    return(messages)

def _owner_eligibility_message(owner_eligibility):
    '''
    Gets list of owner eligibility messages

    Args:
        owner_eligibility:  A dictionary containing isEligible, hasConflictingSubmission, and isRegistered

    Returns:
        list: Owner eligibility messages
    '''
    starter = " > User : "
    if owner_eligibility['isEligible']:
        messages = [starter + "You're eligible to submit for your team."]
    else:
        messages = [starter + "You're not currently eligible to submit."]
        if not owner_eligibility['isRegistered']:
            messages.append(starter + "You are not registered for the challenge.")
        else:
            pass
        if owner_eligibility['hasConflictingSubmission']:
            messages.append(starter + "It appears you've submitted for a different challenge team.")
        else:
            pass
    return(messages)

def check_eligibility(syn, team_info, ownerid):
    '''
    Check eligibility of the team and user submitting for the team

    Args:
        team_info:  Response from get_team_info()
        ownerid: Synapse user id

    Returns:
        bool: If user and team is eligible for submission
    '''
    eligibility_data = _get_eligibility_data(syn, team_info['team_id'])
    team_eligibility = eligibility_data['teamEligibility']
    owner_eligibility = _get_owner_eligibility(eligibility_data, ownerid)

    messages = _team_eligibility_message(team_eligibility, team_info['team_name'])
    [print(message) for message in messages]
    messages = _owner_eligibility_message(owner_eligibility)
    [print(message) for message in messages]

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
    # try:
    #     confirmation = input("y/n:")
    #     confirmation = strtobool(confirmation)
    # except ValueError as e:
    #     raise ValueError("Please answer with y/n")
    # predictiondf = ro.r['read.csv'](prediction_filepath)
    # r_submitRAADC2.submit_raadc2(predictiondf, validate_only=validate_only, dry_run=dry_run)



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
