import pytest
import submitRAADC2
import mock
import synapseclient

syn =  mock.create_autospec(synapseclient.Synapse)

first_folder = {'name': 'First','id': 'syn12345'}
second_folder = {'name': 'Second','id': 'syn54321'}

team_ids = {'teamIds':[12345,23456]}
team_info = {'name':'RAAD2 First','id':'984323'}

def get_children_gen():

    # Generator function contains yield statements
    yield first_folder
    yield second_folder


def test_first__lookup_prediction_folder():
    with mock.patch.object(syn, "getChildren", return_value=get_children_gen()) as syn_get_children:
        first_folder_id = submitRAADC2.submit._lookup_prediction_folder(syn, "First")
        assert first_folder_id == first_folder['id']
        syn_get_children.called_once_with("syn17097318")

def test_second__lookup_prediction_folder():
    with mock.patch.object(syn, "getChildren", return_value=get_children_gen()) as syn_get_children:
        first_folder_id = submitRAADC2.submit._lookup_prediction_folder(syn, "Second")
        assert first_folder_id == second_folder['id']
        syn_get_children.called_once_with("syn17097318")


def test_call_get_team_info():
    with mock.patch.object(syn, "restGET", return_value=team_ids) as syn_rest_get, \
         mock.patch.object(syn, "getTeam", return_value=team_info) as syn_get_team, \
         mock.patch.object(syn, "getChildren", return_value=get_children_gen()) as syn_get_children:
        get_team_info = submitRAADC2.submit.get_team_info(syn, 22222)
        assert get_team_info == {'team_id':team_info['id'],'team_name':team_info['name'],'folder_id':first_folder['id']}
        syn_rest_get.called_once_with(22222)
        syn_get_team.called_once_with(12345)

