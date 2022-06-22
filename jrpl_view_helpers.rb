module ViewHelpers
  def home_team_name(match)
    if match[:home_team_name].nil?
      match[:home_tournament_role]
    else
      match[:home_team_name]
    end
  end

  def away_team_name(match)
    if match[:away_team_name].nil?
      match[:away_tournament_role]
    else
      match[:away_team_name]
    end
  end

  def home_team_prediction(match)
    prediction = match[:home_team_prediction]
    if prediction.nil?
      'no prediction'
    else
      prediction
    end
  end

  def away_team_prediction(match)
    prediction = match[:away_team_prediction]
    if prediction.nil?
      'no prediction'
    else
      prediction
    end
  end

  def home_team_points(match)
    if match[:home_pts].nil?
      'no result'
    else
      match[:home_pts]
    end
  end

  def away_team_points(match)
    if match[:away_pts].nil?
      'no result'
    else
      match[:away_pts]
    end
  end

  def match_locked_down?(match)
    match_date_time = "#{match[:match_date]} #{match[:kick_off]}"
    (Time.now + LOCKDOWN_BUFFER) > Time.parse(match_date_time)
  end

  def previous_match(match_id)
    match_list = load_match_list()
    current_match_index = match_list.index { |match| match == match_id }
    current_match_index = 1 if current_match_index.nil?
    previous_match_index = current_match_index - 1
    if previous_match_index < 0
      nil
    else
      match_list[previous_match_index]
    end
  end

  def next_match(match_id)
    match_list = load_match_list()
    max_index = match_list.size - 1
    current_match_index = match_list.index { |match| match == match_id }
    current_match_index = 1 if current_match_index.nil?
    next_match_index = current_match_index + 1
    if next_match_index > max_index
      nil
    else
      match_list[next_match_index]
    end
  end
end