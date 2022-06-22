module RouteHelpers
  def extract_search_criteria(params)
    tournament_stages = params.select do |_, v|
      v == 'tournament_stage'
    end.keys
    { match_status: params[:match_status],
      prediction_status: params[:prediction_status],
      tournament_stages: tournament_stages }
  end

  def load_matches
    lockdown = calculate_lockdown()
    @storage.filter_matches(session[:user_id], session[:criteria], lockdown)
  end

  def load_match_list
    lockdown = calculate_lockdown()
    @storage.filter_matches_list(
      session[:user_id],
      session[:criteria],
      lockdown
    )
  end

  def set_criteria_to_all_matches
    { match_status: 'all',
      prediction_status: 'all',
      tournament_stages: @storage.tournament_stage_names }
  end

  def update_autoquiz_scoring(result, match_type, predictions)
    scoring_id = @storage.id_for_scoring_system('autoquiz')
    predictions.each do |pred|
      pred_type = result_type(pred[:home_pts], pred[:away_pts])
      result_pts = (match_type == pred_type ? 2 : 0)
      home_score_pts = (result[:home_pts] == pred[:home_pts] ? 2 : 0)
      away_score_pts = (result[:away_pts] == pred[:away_pts] ? 2 : 0)
      score_pts = home_score_pts + away_score_pts
      @storage.add_points(pred[:pred_id], scoring_id, result_pts, score_pts)
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
      @storage.add_points(pred[:pred_id], scoring_id, result_pts, score_pts)
    end
  end

  def update_scoreboard(match_id)
    result = @storage.match_result(match_id)
    match_type = result_type(result[:home_pts], result[:away_pts])
    predictions = @storage.predictions_for_match(match_id)
    update_official_scoring(result, match_type, predictions)
    update_autoquiz_scoring(result, match_type, predictions)
  end

  private

  def calculate_lockdown
    lockdown_timedate = Time.now + LOCKDOWN_BUFFER
    lockdown_date = lockdown_timedate.strftime("%Y-%m-%d")
    lockdown_time = lockdown_timedate.strftime("%k:%M:%S")
    { date: lockdown_date, time: lockdown_time }
  end

  def result_type(home_points, away_points)
    case home_points <=> away_points
    when 1  then 'home_win'
    when -1 then 'away_win'
    else         'draw'
    end
  end
end
