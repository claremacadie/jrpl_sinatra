module RouteErrors
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
end
