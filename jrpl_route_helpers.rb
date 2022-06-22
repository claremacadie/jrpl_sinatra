module RouteHelpers
  def not_integer?(num)
    !(num.floor - num).zero?
  end
  
  def prediction_type_error(home_prediction, away_prediction)
    error = []
    error << 'integers' if
      not_integer?(home_prediction) || not_integer?(away_prediction)
    error << 'non-negative' if
      home_prediction < 0 || away_prediction < 0
    return nil if error.empty?
    "Your predictions must be #{error.join(' and ')}."
  end
  
  def prediction_error(match, home_prediction, away_prediction)
    if match_locked_down?(match)
      'You cannot add or change your prediction because ' \
      'this match is already locked down!'
    else
      prediction_type_error(home_prediction, away_prediction)
    end
  end
  
  def match_result_type_error(home_points, away_points)
    error = []
    error << 'integers' if
      not_integer?(home_points) || not_integer?(away_points)
    error << 'non-negative' if
      home_points < 0 || away_points < 0
    return nil if error.empty?
    "Match results must be #{error.join(' and ')}."
  end
  
  def match_result_error(match, home_points, away_points)
    if !match_locked_down?(match)
      'You cannot add or change the match result because ' \
      'this match has not yet been played.'
    else
      match_result_type_error(home_points, away_points)
    end
  end
  
  def extract_tournament_stages(params)
    params.select { |_, v| v == 'tournament_stage' }.keys
  end
  
  def extract_search_criteria(params)
    { match_status: params[:match_status],
      prediction_status: params[:prediction_status],
      tournament_stages: extract_tournament_stages(params) }
  end
  
  def set_criteria_to_all_matches
    { match_status: 'all',
      prediction_status: 'all',
      tournament_stages: @storage.tournament_stage_names }
  end
  
  def calculate_lockdown
    lockdown_timedate = Time.now + LOCKDOWN_BUFFER
    lockdown_date = lockdown_timedate.strftime("%Y-%m-%d")
    lockdown_time = lockdown_timedate.strftime("%k:%M:%S")
    { date: lockdown_date, time: lockdown_time }
  end
  
  def load_match_list
    lockdown = calculate_lockdown
    @storage.filter_matches_list(session[:user_id], session[:criteria], lockdown)
  end
  
  def load_matches
    lockdown = calculate_lockdown
    @storage.filter_matches(session[:user_id], session[:criteria], lockdown)
  end
  
  def result_type(home_points, away_points)
    case home_points <=> away_points
    when 1  then 'home_win'
    when -1 then 'away_win'
    else         'draw'
    end
  end
  
  def update_official_scoring(result, match_type, predictions)
    scoring_id = @storage.id_for_scoring_system('official')
    predictions.each do |pred|
      pred_type = result_type(pred[:home_pts], pred[:away_pts])
      result_pts = (match_type == pred_type ? 1 : 0)
      home_score_pts = (result[:home_pts] == pred[:home_pts] ? 1 : 0)
      away_score_pts = (result[:away_pts] == pred[:away_pts] ? 1 : 0)
      score_pts = home_score_pts + away_score_pts
      @storage.add_user_points(pred[:pred_id], scoring_id, result_pts, score_pts)
    end
  end
  
  def update_autoquiz_scoring(result, match_type, predictions)
    scoring_id = @storage.id_for_scoring_system('autoquiz')
    predictions.each do |pred|
      pred_type = result_type(pred[:home_pts], pred[:away_pts])
      result_pts = (match_type == pred_type ? 2 : 0)
      home_score_pts = (result[:home_pts] == pred[:home_pts] ? 2 : 0)
      away_score_pts = (result[:away_pts] == pred[:away_pts] ? 2 : 0)
      score_pts = home_score_pts + away_score_pts
      @storage.add_user_points(pred[:pred_id], scoring_id, result_pts, score_pts)
    end
  end
  
  def update_scoreboard(match_id)
    result = @storage.match_result(match_id)
    match_type = result_type(result[:home_pts], result[:away_pts])
    predictions = @storage.predictions_for_match(match_id)
  
    update_official_scoring(result, match_type, predictions)
    update_autoquiz_scoring(result, match_type, predictions)
  end
end