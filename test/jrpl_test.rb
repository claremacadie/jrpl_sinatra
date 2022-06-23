ENV['RACK_ENV'] = 'test'
	
require 'minitest/autorun'
require 'rack/test'
require 'simplecov'

require_relative '../jrpl'
require_relative 'jrpl_test_login'
require_relative 'jrpl_test_matches_filter'
require_relative 'jrpl_test_predictions'
require_relative 'jrpl_test_scoreboard'
require_relative 'jrpl_test_view_match'

SimpleCov.start

class CMSTest < Minitest::Test
  include Rack::Test::Methods
  include TestLogin
  include TestMatchesFilter
  include TestPredictions
  include TestScoreboard
  include TestViewMatch

  def app
    Sinatra::Application
  end

  def setup
    sql = File.read('test/test_data.sql')
    PG.connect(dbname: 'jrpl_test').exec(sql)
  end

  def teardown  
  end

  def session
    last_request.env['rack.session']
  end

  def admin_session
    { 'rack.session' => { user_name: 'Maccas' , user_id: 4, user_email: 'james.macadie@telerealtrillium.com', user_roles: 'Admin'} }
  end

  def user_11_session
    { 'rack.session' => { user_name: 'Clare Mac', user_id: 11, user_email: 'clare@macadie.co.uk'} }
  end
  
  def nil_session
    { 'rack.session' => { user_name: nil, user_id: nil, user_email: nil} }
  end
  
  def user_11_session_with_all_criteria
    { 'rack.session' => { 
      user_name: 'Clare Mac',
      user_id: 11,
      user_email: 'clare@macadie.co.uk',
      criteria: { 
        match_status: "all",
        prediction_status: "all",
        tournament_stages: ["Group Stages", "Round of 16", "Quarter Finals", "Semi Finals", "Third Fourth Place Play-off", "Final"]
      }
    }}
  end
  
  def user_11_session_predicted_criteria
    { 'rack.session' => { 
      user_name: 'Clare Mac',
      user_id: 11,
      user_email: 'clare@macadie.co.uk',
      criteria: { 
        match_status: "all",
        prediction_status: "predicted",
        tournament_stages: ["Group Stages", "Round of 16", "Quarter Finals", "Semi Finals", "Third Fourth Place Play-off", "Final"]
      }
    }}
  end
  
  def user_11_session_not_predicted_group_stages_criteria
    { 'rack.session' => { 
      user_name: 'Clare Mac',
      user_id: 11,
      user_email: 'clare@macadie.co.uk',
      criteria: { 
        match_status: "all",
        prediction_status: "not_predicted",
        tournament_stages: ["Group Stages"]
      }
    }}
  end
  
  def admin_session_with_all_criteria
    { 'rack.session' => { 
      user_name: 'Maccas',
      user_id: 4,
      user_email: 'james.macadie@telerealtrillium.com',
      user_roles: 'Admin',
      criteria: { 
        match_status: "all",
        prediction_status: "all",
        tournament_stages: ["Group Stages", "Round of 16", "Quarter Finals", "Semi Finals", "Third Fourth Place Play-off", "Final"]
      }
    }}
  end

  def test_homepage_signed_out
    get '/'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Julian Rimet Prediction League'
    refute_includes last_response.body, 'Administer account'
    refute_includes last_response.body, 'Administer users'
  end
  
  def test_homepage_signed_in
    get '/', {}, user_11_session
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Julian Rimet Prediction League'
    assert_includes last_response.body, 'Administer account'
    refute_includes last_response.body, 'Administer users'
  end
 
  def test_homepage_signed_in_admin
    get '/', {}, admin_session
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Julian Rimet Prediction League'
    assert_includes last_response.body, 'Administer account'
    assert_includes last_response.body, 'Administer users'
  end

  def test_view_matches_list_signed_in
    get '/matches/all', {}, user_11_session

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Match filter form'
    assert_includes last_response.body, 'type="radio"'
    assert_includes last_response.body, 'type="checkbox"'
    assert_includes last_response.body, 'Matches List'
    assert_includes last_response.body, '<td>77</td>'
    assert_includes last_response.body, "<a href=\"/match/48\">View match</a>"
    assert_includes last_response.body, 'Winner Group A'
  end

  def test_view_matches_list_signed_out
    get '/matches/all'

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
  end
  
  def test_add_new_result
    post '/match/add_result', {match_id: '3', home_pts: '98', away_pts: '99'}, admin_session
    
    assert_equal 302, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_equal 'Result submitted.', session[:message]
    
    get last_response['Location']
    assert_includes last_response.body, '98'
    assert_includes last_response.body, '99'
  end

  def test_add_new_result_not_admin
    post '/match/add_result', {match_id: '3', home_pts: '98', away_pts: '99'}, user_11_session
    assert_equal 302, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_equal 'You must be an administrator to do that.', session[:message]
    
    get last_response['Location']
    refute_includes last_response.body, '98'
    refute_includes last_response.body, '99'
  end
  
  def test_change_result
    post '/match/add_result', {match_id: '2', home_pts: '98', away_pts: '99'}, admin_session
    
    assert_equal 302, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_equal 'Result submitted.', session[:message]
    
    get last_response['Location']
    assert_includes last_response.body, '98'
    assert_includes last_response.body, '99'
  end
  
  def test_add_decimal_result
    post '/match/add_result', {match_id: '3', home_pts: '2.3', away_pts: '3'}, admin_session_with_all_criteria
    
    assert_equal 422, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Match results must be integers.'
  end
  
  def test_add_negative_result
    post '/match/add_result', {match_id: 3, home_pts: '-2', away_pts: '3'}, admin_session_with_all_criteria
    
    assert_equal 422, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Match results must be non-negative.'
  end
  
  def test_add_result_not_lockeddown_match
    post '/match/add_result', {match_id: '64', home_pts: '2', away_pts: '3'}, admin_session_with_all_criteria
    
    assert_equal 422, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'You cannot add or change the match result because this match has not yet been played.'
  end

  

  def test_carousel_predicted
    get '/match/6', {}, user_11_session_predicted_criteria

    assert_includes last_response.body, '<a href="/match/7">Next match'
    refute_includes last_response.body, 'Previous match'
  end

  def test_carousel_not_predicted_group_stages
    get '/match/3', {}, user_11_session_not_predicted_group_stages_criteria

    assert_includes last_response.body, '<a href="/match/2">Previous match'
    assert_includes last_response.body, '<a href="/match/1">Next match'
  end

  def test_carousel_not_predicted_group_stages
    get '/match/48', {}, user_11_session_not_predicted_group_stages_criteria

    assert_includes last_response.body, '<a href="/match/47">Previous match'
    refute_includes last_response.body, 'Next match'
  end

  def test_locked_down_displayed_matches_list
    get '/matches/all', {}, user_11_session

    assert_includes last_response.body.gsub(/\n/, ''), '<td>England</td>          <td>no prediction</td>          <td>no prediction</td>          <td>Iran</td>            <td>Locked down</td>            <td>4</td>            <td>5</td>'
    assert_includes last_response.body.gsub(/\n/, ''), '<td>Qatar</td>          <td>no prediction</td>          <td>no prediction</td>          <td>Ecuador</td>            <td>Locked down</td>            <td>no result</td>            <td>no result</td>          <td>'
    assert_includes last_response.body.gsub(/\n/, ''), '<td>Denmark</td>          <td>71</td>          <td>72</td>          <td>Tunisia</td>            <td>Locked down</td>            <td>no result</td>            <td>no result</td>          <td>'
    assert_includes last_response.body.gsub(/\n/, ''), '<td>Morocco</td>          <td>no prediction</td>          <td>no prediction</td>          <td>Croatia</td>            <td></td>            <td></td>            <td></td>          <td>'
  end

  def test_select_deslect_all_on_match_filter_form
    get '/matches/all', {}, user_11_session

    assert_includes last_response.body, 'Select/Deselect All'
  end
end
