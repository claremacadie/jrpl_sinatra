module TestResults
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
end
