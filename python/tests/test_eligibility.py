import pytest

from submitRAADC2.submit import _get_eligibility_data, check_eligibility, _get_owner_eligibility, _team_eligibility_message, _owner_eligibility_message
import mock
import synapseclient

syn =  mock.create_autospec(synapseclient.Synapse)

team_info = {'team_id':'123456','team_name':'TEST','folder_id':"syn1234",'advanced_compute':True}

member4444 = {'isEligible': True,
'isRegistered': True,
'isQuotaFilled': False,
'principalId': 4444,
'hasConflictingSubmission': False}

member5555 = {'isEligible': False,
'isRegistered': False,
'isQuotaFilled': False,
'principalId': 5555,
'hasConflictingSubmission': False}

member6666 = {'isEligible': False,
'isRegistered': True,
'isQuotaFilled': False,
'principalId': 6666,
'hasConflictingSubmission': True}

eligible_team = {'isEligible': True,
  'isRegistered': True,
  'isQuotaFilled': False}

inelgible_team = {'isEligible': False,
  'isRegistered': False,
  'isQuotaFilled': True}

eligibility_data = {'teamId': team_info['team_id'],
 'evaluationId': '9614112',
 'teamEligibility': eligible_team,
 'membersEligibility': [member4444,member5555,member6666],
 'eligibilityStateHash': 32345}

def test_call__get_eligibility_data():
    with mock.patch.object(syn, "restGET", return_value=eligibility_data) as syn_rest_get:
        data = _get_eligibility_data(syn, "123456")
        syn_rest_get.called_once_with('/evaluation/9614112/team/123456/submissionEligibility')
        assert data == eligibility_data

def test_call_check_eligibility():
    with mock.patch.object(syn, "restGET", return_value=eligibility_data) as syn_rest_get:
        eligible = check_eligibility(syn, team_info, 4444)
        assert eligible

def test_ineligible_check_eligibility():
    with mock.patch.object(syn, "restGET", return_value=eligibility_data) as syn_rest_get:
        eligible = check_eligibility(syn, team_info, 5555)
        assert not eligible

def test__get_owner_eligibility():
    owner_eligibility = _get_owner_eligibility(eligibility_data, 4444)
    assert owner_eligibility == member4444
    owner_eligibility = _get_owner_eligibility(eligibility_data, 5555)
    assert owner_eligibility == member5555

#owner doesn't exist in team
def test_nonexistent__get_owner_eligibility():
    with pytest.raises(IndexError, match='list index out of range'):
        _get_owner_eligibility(eligibility_data, 4)

def test_eligible__team_eligibility_message():
    message = _team_eligibility_message(eligibility_data['teamEligibility'], team_info['team_name'])
    assert message == [' > Team : Your team, {}, is eligible to submit.'.format(team_info['team_name'])]

def test_ineligible__team_eligibility_message():
    message = _team_eligibility_message(inelgible_team, team_info['team_name'])
    assert message == [' > Team : Your team, {}, is not eligible to submit at this time.'.format(team_info['team_name'])," > Team : The team has reached its submission quota for this 24 hour period.",' > Team : The team is not registered for the challenge.']

def test_eligible__owner_eligibility_message():
    message = _owner_eligibility_message(member4444, True)
    assert message == [" > User : You're eligible to submit for your team."]

def test_ineligible_acregistered__owner_eligibility_message():
    message = _owner_eligibility_message(member5555, True)
    assert message == [" > User : You're not currently eligible to submit.",' > User : You have not accepted the terms of the challenge. Please follow the link below to accept the terms.\nhttps://www.synapse.org/#!Synapse:syn16910051/wiki/584254']

def test_ineligible_ncregistered__owner_eligibility_message():
    message = _owner_eligibility_message(member5555, False)
    assert message == [" > User : You're not currently eligible to submit.",' > User : You have not accepted the terms of the challenge. Please follow the link below to accept the terms.\nhttps://www.synapse.org/#!Synapse:syn16810563/wiki/584196']

def test_ineligible_conflict__owner_eligibility_message():
    message = _owner_eligibility_message(member6666, True)
    assert message == [" > User : You're not currently eligible to submit."," > User : It appears you've submitted for a different challenge team."]

