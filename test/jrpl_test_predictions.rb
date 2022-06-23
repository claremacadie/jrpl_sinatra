module TestPredictions
  def test_add_new_prediction
    post '/match/add_prediction', {match_id: '12', home_team_prediction: '98', away_team_prediction: '99'}, user_11_session
    
    assert_equal 302, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_equal 'Prediction submitted.', session[:message]
    
    get last_response['Location']
    assert_includes last_response.body, '98'
    assert_includes last_response.body, '99'
  end
  
  def test_change_prediction
    post '/match/add_prediction', {match_id: '11', home_team_prediction: '98', away_team_prediction: '99'}, user_11_session
    
    assert_equal 302, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_equal 'Prediction submitted.', session[:message]
    
    get last_response['Location']
    assert_includes last_response.body, '98'
    assert_includes last_response.body, '99'
  end
  
  def test_add_decimal_prediction
    post '/match/add_prediction', {match_id: '11', home_team_prediction: '2.3', away_team_prediction: '3'}, user_11_session_with_all_criteria
    
    assert_equal 422, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Your predictions must be integers.'
  end
  
  def test_add_negative_prediction
    post '/match/add_prediction', {match_id: '11', home_team_prediction: '-2', away_team_prediction: '3'}, user_11_session_with_all_criteria
    
    assert_equal 422, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Your predictions must be non-negative.'
  end
  
  def test_add_prediction_lockeddown_match
    post '/match/add_prediction', {match_id: '1', home_team_prediction: '2', away_team_prediction: '3'}, user_11_session_with_all_criteria
    
    assert_equal 422, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'You cannot add or change your prediction because this match is already locked down!'
  end
end
