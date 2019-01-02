import pytest
import submitRAADC2
import mock
import synapseclient

syn = synapseclient.Synapse()

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

eligibility_data = {'teamId': '123456',
 'evaluationId': '9614112',
 'teamEligibility': eligible_team,
 'membersEligibility': [member4444,member5555,member6666],
 'eligibilityStateHash': 32345}

def test_call__get_eligibility_data():
    with mock.patch.object(syn, "restGET", return_value=eligibility_data) as syn_rest_get:
        data = submitRAADC2.submit._get_eligibility_data(syn, "123456")
        syn_rest_get.called_once_with('/evaluation/9614112/team/123456/submissionEligibility')
        assert data == eligibility_data

def test__get_owner_eligibility():
    owner_eligibility = submitRAADC2.submit._get_owner_eligibility(eligibility_data, 4444)
    assert owner_eligibility == member4444
    owner_eligibility = submitRAADC2.submit._get_owner_eligibility(eligibility_data, 5555)
    assert owner_eligibility == member5555

#owner doesn't exist in team
def test_nonexistent__get_owner_eligibility():
    with pytest.raises(IndexError, match='list index out of range'):
        submitRAADC2.submit._get_owner_eligibility(eligibility_data, 4)

def test_eligible__team_eligibility_message():
    message = submitRAADC2.submit._team_eligibility_message(eligibility_data['teamEligibility'], 'TEST')
    assert message == [' > Team : Your team, TEST, is eligible to submit.']

def test_ineligible__team_eligibility_message():
    message = submitRAADC2.submit._team_eligibility_message(inelgible_team, 'TEST')
    assert message == [' > Team : Your team, TEST, is not eligible to submit at this time.'," > Team : The team has reached its submission quota for this 24 hour period.",' > Team : The team is not registered for the challenge.']

def test_eligible__owner_eligibility_message():
    message = submitRAADC2.submit._owner_eligibility_message(member4444)
    assert message == [" > User : You're eligible to submit for your team."]

def test_ineligible_registered__owner_eligibility_message():
    message = submitRAADC2.submit._owner_eligibility_message(member5555)
    assert message == [" > User : You're not currently eligible to submit.",' > User : You are not registered for the challenge.']

def test_ineligible_conflict__owner_eligibility_message():
    message = submitRAADC2.submit._owner_eligibility_message(member6666)
    assert message == [" > User : You're not currently eligible to submit."," > User : It appears you've submitted for a different challenge team."]

