import pytest
from submitRAADC2.submit import _lookup_team_info, get_team_info
import mock
import synapseclient
import pandas as pd

syn =  mock.create_autospec(synapseclient.Synapse)

first_folder = {'name': 'First','id': 'syn12345'}
second_folder = {'name': 'Second','id': 'syn54321'}

team_ids = {'teamIds':[12345,23456]}
team_info = {'name':'RAAD2 First','id':'984323'}

lookup_team_info = (first_folder['id'],True)

class team_folder():
    def asDataFrame():
        return(pd.DataFrame({"folderId":first_folder['id'],"advancedCompute":True},index=[0]))

def test_first__lookup_team_info():
    with mock.patch.object(syn, "tableQuery", return_value=team_folder) as syn_table_query:
        first_folder_id, advanced_compute= _lookup_team_info(syn, "First")
        assert first_folder_id == first_folder['id']
        assert advanced_compute
        syn_table_query.called_once_with("select folderId, advancedCompute from syn17096669 where teamName = 'First'")


def test_call_get_team_info():
    with mock.patch.object(syn, "restGET", return_value=team_ids) as syn_rest_get, \
         mock.patch.object(syn, "getTeam", return_value=team_info) as syn_get_team, \
         mock.patch.object(syn, "tableQuery", return_value=team_folder) as syn_table_query:
        get_team_info_dict = get_team_info(syn, 22222)
        assert get_team_info_dict == {'team_id':team_info['id'],'team_name':team_info['name'],'folder_id':first_folder['id'],'advanced_compute':True}
        syn_rest_get.called_once_with(22222)
        syn_get_team.called_once_with(12345)

