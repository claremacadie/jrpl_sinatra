module LoginCookies
  def implement_cookies
    set_series_id_cookie()
    set_token_cookie()
    @storage.save_cookie_data(
      session[:user_id],
      cookies[:series_id],
      cookies[:token]
    )
  end

  def reset_cookie_token
    set_token_cookie()
    @storage.save_new_token(
      session[:user_id],
      cookies[:series_id],
      cookies[:token]
    )
  end

  def set_series_id_cookie
    series_id_value = unique_random_string()
    response.set_cookie(
      'series_id',
      { value: series_id_value,
        path: '/',
        expires: Time.now + (30 * 24 * 60 * 60) } # one month from now
    )
  end

  def set_token_cookie
    token_value = SecureRandom.hex(32)
    response.set_cookie(
      'token',
      { value: token_value,
        path: '/',
        expires: Time.now + (30 * 24 * 60 * 60) } # one month from now
    )
  end

  def signin_with_cookie
    return false unless cookies[:series_id] && cookies[:token]
    user_id = @storage.user_id_from_cookies(
      cookies[:series_id],
      cookies[:token]
    )
    return false unless user_id
    setup_user_session_data(user_id)
    reset_cookie_token()
  end

  def unique_random_string
    random_string = SecureRandom.hex(32)
    while @storage.series_id_list.include?(random_string)
      random_string = SecureRandom.hex(32)
    end
    random_string
  end
end
