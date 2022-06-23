# Signup and Signin functionality

module TestLogin  
  def test_signin_form
    get '/users/signin'
    assert_equal 200, last_response.status
    assert_includes last_response.body, '<input'
    assert_includes last_response.body, %q(<button type="submit")
  end
  
  def test_signin_form_already_signed_in
    get '/users/signin', {}, user_11_session
    assert_equal 302, last_response.status
    assert_equal 'You must be signed out to do that.', session[:message]
  end
  
  def test_signin
    post '/users/signin', {login: 'Maccas', pword: 'a'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'Maccas', session[:user_name]
  
    get last_response['Location']
    assert_includes last_response.body, 'Signed in as Maccas.'
  end

  def test_signin_already_signed_in
    post '/users/signin', {login: 'Maccas', pword: 'a'}, user_11_session
    assert_equal 302, last_response.status
    assert_equal 'You must be signed out to do that.', session[:message]
  end
  
  def test_signin_strip_input
    post '/users/signin', {login: '   Maccas  ', pword: ' a '}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'Maccas', session[:user_name]
    
    get last_response['Location']
    assert_includes last_response.body, 'Signed in as Maccas.'
  end
  
  def test_signin_with_bad_credentials
    post '/users/signin', {login: 'guest', pword: 'shhhh'}, {}
    assert_equal 422, last_response.status
    assert_nil session[:user_name]
    assert_includes last_response.body, 'Invalid credentials.'
  end
  
  def test_signout
    get '/', {}, admin_session
    assert_equal 'Admin', session[:user_roles]
  
    post '/users/signout'
    assert_equal 'You have been signed out.', session[:message]
  
    get last_response['Location']
    assert_nil session[:user_name]
    assert_includes last_response.body, 'Sign In'
  end

  def test_signout_already_signed_out
    post '/users/signout'
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]
  end

  def test_view_signup_form_signed_out
    get '/users/signup'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Reenter password'
  end
  
  def test_view_signup_form_signed_in
    get '/users/signup', {}, admin_session
    assert_equal 302, last_response.status
    assert_equal 'You must be signed out to do that.', session[:message]
  end
  
  def test_signup_signed_out
    post '/users/signup', {new_user_name: 'joe', new_email: 'joe@joe.com', new_pword: 'Dfghiewo34334', reenter_pword: 'Dfghiewo34334'}
    assert_equal 302, last_response.status
    assert_equal 'Your account has been created.', session[:message]
  
    get '/'
    assert_includes last_response.body, 'Signed in as joe.'
  end
  
  def test_signup_signed_out_strip_input
    post '/users/signup', {new_user_name: '   joe  ', new_email: 'joe@joe.com', new_pword: ' Dfghiewo34334    ', reenter_pword: '  Dfghiewo34334 '}
    assert_equal 302, last_response.status
    assert_equal 'Your account has been created.', session[:message]
  
    get '/'
    assert_includes last_response.body, 'Signed in as joe.'
  end
  
  def test_signup_signed_in
    post '/users/signup', {new_user_name: 'joe', new_email: 'joe@joe.com', new_pword: 'dfghiewo34334', reenter_pword: 'dfghiewo34334'}, admin_session
    assert_equal 302, last_response.status
    assert_equal 'You must be signed out to do that.', session[:message]
  end
  
  def test_signup_existing_username
    post '/users/signup', {new_user_name: 'Clare Mac', new_email: 'joe@joe.com', new_pword: 'dfghiewo34334', reenter_pword: 'dfghiewo34334'}
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'That username already exists.'
  end
  
  def test_signup_blank_username
    post '/users/signup', {new_user_name: '', new_email: 'joe@joe.com', new_pword: 'dfghiewo34334', reenter_pword: 'dfghiewo34334'}
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Username cannot be blank! Please enter a username.'
  end
  
  def test_signup_blank_pword
    post '/users/signup', {new_user_name: 'joanna', new_email: 'joe@joe.com', new_pword: '', reenter_pword: ''}
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Password cannot be blank! Please enter a password.'
  end
  
  def test_signup_blank_username_and_pword
    post '/users/signup', {new_user_name: '', new_email: 'joe@joe.com', new_pword: '', reenter_pword: ''}
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Username cannot be blank! Please enter a username. Password cannot be blank! Please enter a password.'
  end
  
  def test_signup_mismatched_pwords
    post '/users/signup', {new_user_name: 'joanna', new_email: 'joe@joe.com', new_pword: 'dfghiewo34334', reenter_pword: 'mismatched'}
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'The passwords do not match.'
  end
  
  def test_signup_invalid_email
    post '/users/signup', {new_user_name: 'joanna', new_email: 'joe', new_pword: 'dfghiewo34334', reenter_pword: 'dfghiewo34334'}
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'That is not a valid email address.'
  end
  
  def test_signup_blank_email
    post '/users/signup', {new_user_name: 'joanna', new_email: '', new_pword: 'dfghiewo34334', reenter_pword: 'dfghiewo34334'}
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Email cannot be blank! Please enter an email.'
  end
  
  def test_signup_duplicate_email
    post '/users/signup', {new_user_name: 'joanna', new_email: 'clare@macadie.co.uk', new_pword: 'dfghiewo34334', reenter_pword: 'dfghiewo34334'}
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'That email address already exists.'
  end

  def test_view_administer_accounts
    get '/users/administer_accounts', {}, admin_session
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Clare Mac'
    assert_includes last_response.body, 'Administer users'
    assert_includes last_response.body, '<button type="submit">Grant Admin</button>'
    assert_includes last_response.body, '<button type="submit">Revoke Admin</button>'
    assert_includes last_response.body, '<button type="submit">Reset password</button>'
  end
  
  def test_view_administer_accounts_not_admin
    get '/users/administer_accounts', {}, user_11_session
    assert_equal 302, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_equal 'You must be an administrator to do that.', session[:message]
  end

  def test_reset_pword_admin
    post '/users/reset_pword', {user_name: 'Clare Mac'}, admin_session
    assert_equal 302, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_equal "The password has been reset to 'jrpl' for Clare Mac.", session[:message]
    post '/users/signout'

    post '/users/signin', {login: 'Clare Mac', pword: 'jrpl'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'Clare Mac', session[:user_name]
  end
  
  def test_reset_pword_not_admin
    post '/users/reset_pword', {user_name: 'Maccas'}, user_11_session
    assert_equal 302, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_equal 'You must be an administrator to do that.', session[:message]
    refute_includes last_response.body, "The password has been reset to 'jrpl' for Clare Mac."
    post '/users/signout'

    post '/users/signin', {login: 'Clare Mac', pword: 'jrpl'}, {}
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid credentials'
  end
  
  def test_reset_pword_signed_out
    post '/users/reset_pword', {user_name: 'Maccas'}
    assert_equal 302, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_equal 'You must be an administrator to do that.', session[:message]
    refute_includes last_response.body, "The password has been reset to 'jrpl' for Clare MacAdie."
    post '/users/signout'

    post '/users/signin', {login: 'Clare Mac', pword: 'jrpl'}, {}
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid credentials'
  end

  def test_make_user_admin_then_not_admin
    post '/users/toggle_admin', {user_id: '11', button: 'grant_admin'}, admin_session
    post '/users/signout'
    
    post '/users/signin', {login: 'Clare Mac', pword: 'a'}, {}
    assert_includes session[:user_roles], 'Admin'
    
    post '/users/toggle_admin', {user_id: '11', button: 'revoke_admin'}, admin_session
    post '/users/signout'
    
    post '/users/signin', {login: 'Clare Mac', pword: 'a'}, {}
    assert_nil session[:user_roles]
  end
  
  def test_make_user_admin_already_admin
    post '/users/toggle_admin', {user_id: '11', button: 'grant_admin'}, admin_session
    post '/users/toggle_admin', {user_id: '11', button: 'grant_admin'}, admin_session
    post '/users/signout'

    post '/users/signin', {login: 'Clare Mac', pword: 'a'}, {}
    assert_includes session[:user_roles], 'Admin'
  end
  
  def test_make_user_not_admin_already_not_admin
    post '/users/toggle_admin', {user_id: '11', button: 'revoke_admin'}, admin_session
    post '/users/signout'

    post '/users/signin', {login: 'Clare Mac', pword: 'a'}, {}
    assert_nil session[:user_roles]
  end

  def test_role_deleted_at_signout
    post '/users/signin', {login: 'Maccas', pword: 'a'}, {}
    assert_equal 'Admin', session[:user_roles]
    post '/users/signout'
    post '/users/signin', {login: 'Clare Mac', pword: 'a'}, {}
    refute_equal 'Admin', session[:user_roles]
  end
end
