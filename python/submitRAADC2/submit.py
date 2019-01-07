import argparse
from rpy2.robjects.packages import importr
from rpy2.robjects import pandas2ri
from rpy2.rinterface import RRuntimeError
#import rpy2.robjects as ro
import pandas as pd
r_submitRAADC2 = importr("submitRAADC2")
import os

from distutils.util import strtobool
import synapseclient
import sys
import base64
import requests
import json

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

def get_service_account():
    email = os.environ['EMAIL']
    apikey = os.environ['APIKEY']
    syn = synapseclient.login(email, apiKey=apikey)
    return(syn)

def join_team(syn, ownerid):
    '''
    '''
    # accessorId  STRING  The ID of the principal (user or group) approved for access
    # requirementId   INTEGER The ID of the Access Requirement that this object approves.

    teamid = 3378197
    syn.restPUT("/team/{teamid}/member/{principalId}".format(teamid=teamid, principalId=ownerid))


def upload_predictions(submission_filepath, folder_id, direct=False):
    '''
    Upload prediciton file to synapse

    Args:
        syn: Synapse object
        submission_filepath: File path of submission
        folder_id: Synapse id of Team submission folder

    Returns:
        Synapse File Entity
    '''
    if direct:
        syn_service = get_service_account()
        file_ent = synapseclient.File(submission_filepath, parentId=folder_id)
        file_ent = syn.store(file_ent)
        entity = file_ent
    else:
        with open(submission_filepath, 'rb') as data_file:
            prediction_data = data_file.read()
            encoded_prediction_data = base64.b64encode(prediction_data)
        url = "https://gja3h20usl.execute-api.us-east-1.amazonaws.com/v1/predictions"
        data = {"submission_folder":folder_id,
                "data":encoded_prediction_data.decode('utf-8')}
        res = requests.post(url, json=data)
        entity = json.loads(res.content)
    return(entity)

def submit_raadc2(predictiondf, validate_only=False, dry_run=False):
    '''
    Submitting RAAD2 prediction files

    Args:
        predictiondf: Prediction dataframe
        validate_only: If 'True', check data for any formatting errors but don't submit to the challenge.
        dry_run: If ‘TRUE', execute submission steps, but don’t store any data in Synapse. 
    '''
    pandas2ri.activate()
    print("Running checks to validate date frame format...\n\n")
    try:
        valid = r_submitRAADC2.validate_predictions(pandas2ri.py2ri(predictiondf))
        print("All checks passed")
    #This is done so the traceback isn't shown
    except RRuntimeError as e:
        print(e)
        sys.exit(1)

    if not validate_only:
        syn = synapse_login()
        ownerid = _lookup_owner_id(syn)
        team_info = get_team_info(syn, ownerid)
        is_eligible = check_eligibility(syn, team_info, ownerid)
        is_certified = True
        if not is_eligible or not is_certified:
            raise ValueError("Exiting submission attempt.")

        confirm_submission = r_submitRAADC2._confirm_prompt()
        if confirm_submission[0] in [0,2]:
            print("Exiting submission attempt.")
            sys.exit(1)
        else:
            print("Writing data to local CSV file...")
            submission_filename = r_submitRAADC2._create_submission(pandas2ri.py2ri(predictiondf))
            pandas2ri.deactivate()
            #This parameter determines if the submission file is directly uploaded by a service account
            direct=True
            prediction_ent = upload_predictions(submission_filename[0], team_info['folder_id'], direct=direct)
            print("\n\nSubmitting prediction to challenge evaluation queue...\n")
            submission_object = syn.submit(evaluation="9614112",entity=prediction_ent, team=team_info['team_name'])
            print("Successfully submitted file: '{filename}'".format(filename=submission_filename))
            print(" > stored as {entityid} [version: {version}]".format(entityid=prediction_ent.id,version=prediction_ent.versionNumber))
            print(" > submission Id: {subid}".format(subid=submission_object['id']))


def build_parser():
    """Builds the argument parser and returns the result."""
    parser = argparse.ArgumentParser()
    parser.add_argument("prediction", help="Prediction filepath")
    parser.add_argument("-v", "--validate_only", help="Validate file only", action='store_true')
    return parser

def main():
    args = build_parser().parse_args()
    predictiondf = pd.read_csv(args.prediction)
    submit_raadc2(predictiondf, validate_only=args.validate_only)

if __name__ == "__main__":
    main()
