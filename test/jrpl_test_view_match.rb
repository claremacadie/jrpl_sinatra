module TestViewMatch
  def test_carousel
    get '/match/1', {}, user_11_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, '<a href="/match/3">Previous match</a>'
    assert_includes last_response.body, '<a href="/match/4">Next match</a>'
  end
  
  def test_carousel_below_minimum
    get '/match/2', {}, user_11_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, '<a href="/match/3">Next match</a>'
    refute_includes last_response.body, 'Previous match'
  end
  
  def test_carousel_above_maximum
    get '/match/64', {}, user_11_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, '<a href="/match/63">Previous match</a>'
    refute_includes last_response.body, 'Next match'
  end
  
  def test_view_match_not_lockdown_no_pred_not_admin
    get 'match/64', {}, user_11_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Add/Change prediction'
    refute_includes last_response.body, 'Winner Semi-Final 1: no result'
    refute_includes last_response.body, 'Winner Semi-Final 2: no result'
    refute_includes last_response.body, 'Match locked down!'
    refute_includes last_response.body, 'Add/Change match result'
  end
  
  def test_view_match_not_lockdown_no_pred_admin
    get 'match/64', {}, admin_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Add/Change prediction'
    refute_includes last_response.body, 'Winner Semi-Final 1: no result'
    refute_includes last_response.body, 'Winner Semi-Final 2: no result'
    refute_includes last_response.body, 'Match locked down!'
    refute_includes last_response.body, 'Add/Change match result'
  end
  
  def test_view_match_not_lockdown_prediction_not_admin
    get 'match/11', {}, user_11_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, '77'
    assert_includes last_response.body, '78'
    assert_includes last_response.body, 'Add/Change prediction'
    refute_includes last_response.body, 'Spain: no result'
    refute_includes last_response.body, 'IC Play Off 2: no result'
    refute_includes last_response.body, 'Match locked down!'
    refute_includes last_response.body, 'Add/Change match result'
  end
  
  def test_view_match_not_lockdown_prediction_admin
    get 'match/12', {}, admin_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, '88'
    assert_includes last_response.body, '89'
    assert_includes last_response.body, 'Add/Change prediction'
    refute_includes last_response.body, 'Belgium: no result'
    refute_includes last_response.body, 'Canada no result'
    refute_includes last_response.body, 'Match locked down!'
    refute_includes last_response.body, 'Add/Change match result'
  end
  
  def test_view_match_lockdown_no_pred_no_result_not_admin
    get 'match/3', {}, user_11_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body,'Match locked down!'
    assert_includes last_response.body, 'Qatar: no prediction'
    assert_includes last_response.body, 'Ecuador: no prediction'
    assert_includes last_response.body, 'Qatar: no result'
    assert_includes last_response.body, 'Ecuador: no result'
    refute_includes last_response.body, 'Add/Change prediction'
    refute_includes last_response.body, 'Add/Change match result'
  end
  
  def test_view_match_lockdown_no_pred_no_result_admin
    get 'match/3', {}, admin_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body,'Match locked down!'
    assert_includes last_response.body, 'Qatar: no prediction'
    assert_includes last_response.body, 'Ecuador: no prediction'
    assert_includes last_response.body, 'Add/Change match result'
    refute_includes last_response.body, 'Add/Change prediction'
  end
  
  def test_view_match_lockdown_prediction_no_result_not_admin
    get 'match/6', {}, user_11_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Match locked down!'
    assert_includes last_response.body, '71'
    assert_includes last_response.body, '72'
    assert_includes last_response.body, 'Denmark: no result'
    assert_includes last_response.body, 'Tunisia: no result'
    refute_includes last_response.body, 'Add/Change prediction'
    refute_includes last_response.body, 'Add/Change match result'
  end
  
  def test_view_match_lockdown_prediction_no_result_admin
    get 'match/6', {}, admin_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Match locked down!'
    assert_includes last_response.body, '81'
    assert_includes last_response.body, '82'
    assert_includes last_response.body, 'Denmark'
    assert_includes last_response.body, 'Tunisia'
    assert_includes last_response.body, 'Add/Change match result'
    refute_includes last_response.body, 'Add/Change prediction'
  end
  
  def test_view_match_lockdown_no_pred_result_not_admin
    get 'match/1', {}, user_11_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Match locked down!'
    assert_includes last_response.body, 'Senegal: no prediction'
    assert_includes last_response.body, 'Netherlands: no prediction'
    assert_includes last_response.body, 'Senegal: 6'
    assert_includes last_response.body, 'Netherlands: 3'
    refute_includes last_response.body, 'Add/Change prediction'
    refute_includes last_response.body, 'Add/Change match result'
  end
  
  def test_view_match_lockdown_no_pred_result_admin
    get 'match/1', {}, admin_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Match locked down!'
    assert_includes last_response.body, 'Senegal: no prediction'
    assert_includes last_response.body, 'Netherlands: no prediction'
    assert_includes last_response.body, '6'
    assert_includes last_response.body, '3'
    assert_includes last_response.body, 'Add/Change match result'
    refute_includes last_response.body, 'Add/Change prediction'
  end

  def test_view_match_lockdown_prediction_result_not_admin
    get 'match/8', {}, user_11_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Match locked down!'
    assert_includes last_response.body, 'France: 73'
    assert_includes last_response.body, 'IC Play Off 1: 74'
    assert_includes last_response.body, 'France: 63'
    assert_includes last_response.body, 'IC Play Off 1: 64'
    refute_includes last_response.body, 'Add/Change prediction'
    refute_includes last_response.body, 'Add/Change match result'
  end

  def test_view_match_lockdown_prediction_result_admin
    get 'match/8', {}, admin_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Match locked down!'
    assert_includes last_response.body, 'France: 83'
    assert_includes last_response.body, 'IC Play Off 1: 84'
    assert_includes last_response.body, '63'
    assert_includes last_response.body, '64'
    assert_includes last_response.body, 'Add/Change match result'
    refute_includes last_response.body, 'Add/Change prediction'
  end
  
  def test_view_single_match_signed_in
    get '/match/11', {}, user_11_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Match details'
    assert_includes last_response.body, 'Spain'
    assert_includes last_response.body, 'IC Play Off 2'
  end
  
  def test_view_single_match_signed_in_tournament_role
    get '/match/64', {}, user_11_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Match details'
    assert_includes last_response.body, 'Winner Semi-Final 1'
    assert_includes last_response.body, 'Winner Semi-Final 2'
  end
end
