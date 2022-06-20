ENV['RACK_ENV'] = 'test'
	
require 'minitest/autorun'
require 'rack/test'
require 'simplecov'

SimpleCov.start

require_relative '../jrpl'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

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
  
  def test_view_administer_account_form_signed_out
    get '/users/edit_credentials'
    assert_equal 302, last_response.status
    assert_includes session[:message], 'You must be signed in to do that.'
  end
  
  def test_view_administer_account_form_signed_in
    get '/users/edit_credentials', {}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Enter new username'
    assert_includes last_response.body, 'Enter your new email address'
    assert_includes last_response.body, 'Enter current password'
    assert_includes last_response.body, 'Enter new password'
    assert_includes last_response.body, 'Reenter new password'
  end
  
  def test_change_username
    post '/users/edit_credentials', {current_pword: 'a', new_user_name: 'joe', new_email: 'clare@macadie.co.uk', new_pword: '', reenter_pword: ''}, user_11_session
    assert_equal 302, last_response.status
    assert_equal 'joe', session[:user_name]
    assert_equal 'The following have been updated: username.', session[:message]
    
    get '/'
    assert_includes last_response.body, 'Signed in as joe.'
  end
  
  def test_change_username_strip_input
    post '/users/edit_credentials', {current_pword: '   a ', new_user_name: '   joe ', new_email: 'clare@macadie.co.uk',  new_pword: '', reenter_pword: ''}, user_11_session
    assert_equal 302, last_response.status
    assert_equal 'joe', session[:user_name]
    assert_equal 'The following have been updated: username.', session[:message]
    
    get '/'
    assert_includes last_response.body, 'Signed in as joe.'
  end
  
  def test_change_username_to_blank
    post '/users/edit_credentials', {current_pword: 'a', new_user_name: '', new_email: 'clare@macadie.co.uk', new_pword: '', reenter_pword: ''}, user_11_session
    assert_equal 422, last_response.status
    assert_equal 'Clare Mac', session[:user_name]
    assert_includes last_response.body, 'Username cannot be blank! Please enter a username.'
  end
  
  def test_change_username_to_existing_username
    post '/users/edit_credentials', {current_pword: 'a', new_user_name: 'Maccas', new_email: 'clare@macadie.co.uk', new_pword: '', reenter_pword: ''}, user_11_session
    assert_equal 422, last_response.status
    assert_equal 'Clare Mac', session[:user_name]
    assert_includes last_response.body, 'That username already exists. Please choose a different username.'
  end
  
  def test_change_pword
    post '/users/edit_credentials', {current_pword: 'a', new_user_name: 'Clare Mac', new_email: 'clare@macadie.co.uk', new_pword: 'Qwerty90', reenter_pword: 'Qwerty90'}, user_11_session
    assert_equal 302, last_response.status
    assert_equal 'Clare Mac', session[:user_name]
    assert_equal 'The following have been updated: password.', session[:message]
    post '/users/signout'

    post '/users/signin', {login: 'Clare Mac', pword: 'Qwerty90'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'Clare Mac', session[:user_name]
  end
  
  def test_change_pword_strip_input
    post '/users/edit_credentials', {current_pword: ' a   ', new_user_name: 'Clare Mac', new_email: 'clare@macadie.co.uk', new_pword: ' Qwerty90 ', reenter_pword: '   Qwerty90 '}, user_11_session
    assert_equal 302, last_response.status
    assert_equal 'Clare Mac', session[:user_name]
    assert_equal 'The following have been updated: password.', session[:message]
    post '/users/signout'

    post '/users/signin', {login: 'Clare Mac', pword: 'Qwerty90'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'Clare Mac', session[:user_name]
  end
  
  def test_change_pword_mismatched
    post '/users/edit_credentials', {current_pword: 'a', new_user_name: 'Clare Mac', new_email: 'clare@macadie.co.uk', new_pword: 'b', reenter_pword: 'c'}, user_11_session
    assert_equal 422, last_response.status
    assert_equal 'Clare Mac', session[:user_name]
    assert_includes last_response.body, 'The passwords do not match.'
  end
  
  def test_change_username_and_pword
    post '/users/edit_credentials', {current_pword: 'a', new_user_name: 'joe', new_email: 'clare@macadie.co.uk', new_pword: 'Qwerty90', reenter_pword: 'Qwerty90'}, user_11_session
    assert_equal 302, last_response.status
    assert_equal 'joe', session[:user_name]
    assert_equal 'The following have been updated: username, password.', session[:message]
    post '/users/signout'

    post '/users/signin', {login: 'joe', pword: 'Qwerty90'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'joe', session[:user_name]
  end
  
  def test_change_username_and_pword_strip
    post '/users/edit_credentials', {current_pword: 'a', new_user_name: '   joe   ', new_email: 'clare@macadie.co.uk', new_pword: ' Qwerty90', reenter_pword: '   Qwerty90 '}, user_11_session
    assert_equal 302, last_response.status
    assert_equal 'joe', session[:user_name]
    assert_equal 'The following have been updated: username, password.', session[:message]
    post '/users/signout'

    post '/users/signin', {login: 'joe', pword: 'Qwerty90'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'joe', session[:user_name]
  end
  
  def test_change_username_and_pword_empty
    post '/users/edit_credentials', {current_pword: 'a', new_user_name: '   joe   ', new_email: 'clare@macadie.co.uk', new_pword: '   ', reenter_pword: '   '}, user_11_session
    assert_equal 302, last_response.status
    assert_equal 'joe', session[:user_name]
    assert_equal 'The following have been updated: username.', session[:message]
    post '/users/signout'

    post '/users/signin', {login: 'joe', pword: 'a'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'joe', session[:user_name]
  end
  
  def test_change_user_credentials_pword_mismatched
    post '/users/edit_credentials', {current_pword: 'wrong_pword', new_user_name: 'joe', new_email: 'clare@macadie.co.uk', new_pword: 'b', reenter_pword: 'b'}, user_11_session
    assert_equal 422, last_response.status
    assert_equal 'Clare Mac', session[:user_name]
    assert_includes last_response.body, 'That is not the correct current password. Try again!'
  end
  
  def test_change_user_credentials_nothing_changed
    post '/users/edit_credentials', {current_pword: 'a', new_user_name: 'Clare Mac', new_email: 'clare@macadie.co.uk', new_pword: '', reenter_pword: ''}, user_11_session
    assert_equal 422, last_response.status
    assert_equal 'Clare Mac', session[:user_name]
    assert_includes last_response.body, 'You have not changed any of your details.'
  end

  def test_change_admin_pword
    post '/users/edit_credentials', {current_pword: 'a', new_user_name: 'Maccas', new_email: 'james.macadie@telerealtrillium.com', new_pword: 'b', reenter_pword: 'b'}, admin_session
    assert_equal 302, last_response.status
    assert_equal 'Maccas', session[:user_name]
    assert_equal 'The following have been updated: password.', session[:message]
    post '/users/signout'

    post '/users/signin', {login: 'Maccas', pword: 'b'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'Maccas', session[:user_name]
  end

  def test_change_email
    post '/users/edit_credentials', {current_pword: 'a', new_user_name: 'Clare Mac', new_email: 'new@email.com', new_pword: '', reenter_pword: ''}, user_11_session
    assert_equal 302, last_response.status
    assert_equal 'Clare Mac', session[:user_name]
    assert_equal 'new@email.com', session[:user_email]
    assert_equal 'The following have been updated: email.', session[:message]
    
    get '/'
    assert_includes last_response.body, 'Signed in as Clare Mac.'
  end
 
  def test_change_invalid_email
    post '/users/edit_credentials', {current_pword: 'a', new_user_name: 'Clare Mac', new_email: 'joe', new_pword: '', reenter_pword: ''}, user_11_session
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'That is not a valid email address.'
  end
  
  def test_change_blank_email
    post '/users/edit_credentials', {current_pword: 'a', new_user_name: 'Clare Mac', new_email: '', new_pword: '', reenter_pword: ''}, user_11_session
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Email cannot be blank! Please enter an email.'
  end
  
  def test_change_duplicate_email
    post '/users/edit_credentials', {current_pword: 'a', new_user_name: 'Clare Mac', new_email: 'mrmean@julianrimet.com', new_pword: '', reenter_pword: ''}, user_11_session
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'That email address already exists.'
  end

  def test_change_username_and_email
    post '/users/edit_credentials', {current_pword: 'a', new_user_name: 'joe', new_email: 'new@email.com', new_pword: '', reenter_pword: ''}, user_11_session
    assert_equal 302, last_response.status
    assert_equal 'joe', session[:user_name]
    assert_equal 'new@email.com', session[:user_email]
    assert_equal 'The following have been updated: username, email.', session[:message]
    
    get '/'
    assert_includes last_response.body, 'Signed in as joe.'
  end
  
  def test_change_username_pword_and_email
    post '/users/edit_credentials', {current_pword: 'a', new_user_name: 'joe', new_email: 'new@email.com', new_pword: 'Qwerty90', reenter_pword: 'Qwerty90'}, user_11_session
    assert_equal 302, last_response.status
    assert_equal 'joe', session[:user_name]
    assert_equal 'new@email.com', session[:user_email]
    assert_equal 'The following have been updated: username, password, email.', session[:message]
    post '/users/signout'

    post '/users/signin', {login: 'joe', pword: 'Qwerty90'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'joe', session[:user_name]
  end
  
  def test_change_username_pword_and_email_strip
    post '/users/edit_credentials', {current_pword: 'a', new_user_name: '   joe ', new_email: '  new@email.com ', new_pword: 'Qwerty90  ', reenter_pword: ' Qwerty90 '}, user_11_session
    assert_equal 302, last_response.status
    assert_equal 'joe', session[:user_name]
    assert_equal 'new@email.com', session[:user_email]
    assert_equal 'The following have been updated: username, password, email.', session[:message]
    post '/users/signout'

    post '/users/signin', {login: 'joe', pword: 'Qwerty90'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'joe', session[:user_name]
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
    refute_equal 'Match locked down!', session[:message]
    refute_includes last_response.body, 'Add/Change match result'
  end
  
  def test_view_match_not_lockdown_no_pred_admin
    get 'match/64', {}, admin_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Add/Change prediction'
    refute_includes last_response.body, 'Winner Semi-Final 1: no result'
    refute_includes last_response.body, 'Winner Semi-Final 2: no result'
    refute_equal 'Match locked down!', session[:message]
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
    refute_equal 'Match locked down!', session[:message]
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
    refute_equal 'Match locked down!', session[:message]
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
    get 'match/7', {}, user_11_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Match locked down!'
    assert_includes last_response.body, 'Mexico: no prediction'
    assert_includes last_response.body, 'Poland: no prediction'
    assert_includes last_response.body, 'Mexico: 61'
    assert_includes last_response.body, 'Poland: 62'
    refute_includes last_response.body, 'Add/Change prediction'
    refute_includes last_response.body, 'Add/Change match result'
  end
  
  def test_view_match_lockdown_no_pred_result_admin
    get 'match/7', {}, admin_session
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Match locked down!'
    assert_includes last_response.body, 'Mexico: no prediction'
    assert_includes last_response.body, 'Poland: no prediction'
    assert_includes last_response.body, '61'
    assert_includes last_response.body, '62'
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

  def test_add_new_result
    post '/match/add_result', {match_id: '3', home_team_points: '98', away_team_points: '99'}, admin_session
    
    assert_equal 302, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_equal 'Result submitted.', session[:message]
    
    get last_response['Location']
    assert_includes last_response.body, '98'
    assert_includes last_response.body, '99'
  end

  def test_add_new_result_not_admin
    post '/match/add_result', {match_id: '3', home_team_points: '98', away_team_points: '99'}, user_11_session
    assert_equal 302, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_equal 'You must be an administrator to do that.', session[:message]
    
    get last_response['Location']
    refute_includes last_response.body, '98'
    refute_includes last_response.body, '99'
  end
  
  def test_change_result
    post '/match/add_result', {match_id: '2', home_team_points: '98', away_team_points: '99'}, admin_session
    
    assert_equal 302, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_equal 'Result submitted.', session[:message]
    
    get last_response['Location']
    assert_includes last_response.body, '98'
    assert_includes last_response.body, '99'
  end
  
  def test_add_decimal_result
    post '/match/add_result', {match_id: '3', home_team_points: '2.3', away_team_points: '3'}, admin_session_with_all_criteria
    
    assert_equal 422, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Match results must be integers.'
  end
  
  def test_add_negative_result
    post '/match/add_result', {match_id: 3, home_team_points: '-2', away_team_points: '3'}, admin_session_with_all_criteria
    
    assert_equal 422, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Match results must be non-negative.'
  end
  
  def test_add_result_not_lockeddown_match
    post '/match/add_result', {match_id: '64', home_team_points: '2', away_team_points: '3'}, admin_session_with_all_criteria
    
    assert_equal 422, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'You cannot add or change the match result because this match has not yet been played.'
  end

  def test_filter_matches_all
    post '/matches/filter',
      {match_status: 'all', prediction_status: 'all', "Group Stages"=>"tournament_stage", "Round of 16"=>"tournament_stage", "Quarter Finals"=>"tournament_stage", "Semi Finals"=>"tournament_stage", "Third Fourth Place Play-off"=>"tournament_stage", "Final"=>"tournament_stage"},
      user_11_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Matches List'
    assert_includes last_response.body, '<td hidden>1</td>'
    assert_includes last_response.body, '<td hidden>2</td>'
    assert_includes last_response.body, '<td hidden>3</td>'
    assert_includes last_response.body, '<td hidden>4</td>'
    assert_includes last_response.body, '<td hidden>5</td>'
    assert_includes last_response.body, '<td hidden>6</td>'
    assert_includes last_response.body, '<td hidden>7</td>'
    assert_includes last_response.body, '<td hidden>8</td>'
    assert_includes last_response.body, '<td hidden>9</td>'
    assert_includes last_response.body, '<td hidden>10</td>'
    assert_includes last_response.body, '<td hidden>11</td>'
    assert_includes last_response.body, '<td hidden>12</td>'
    assert_includes last_response.body, '<td hidden>13</td>'
    assert_includes last_response.body, '<td hidden>14</td>'
    assert_includes last_response.body, '<td hidden>15</td>'
    assert_includes last_response.body, '<td hidden>16</td>'
    assert_includes last_response.body, '<td hidden>17</td>'
    assert_includes last_response.body, '<td hidden>18</td>'
    assert_includes last_response.body, '<td hidden>29</td>'
    assert_includes last_response.body, '<td hidden>20</td>'
    assert_includes last_response.body, '<td hidden>21</td>'
    assert_includes last_response.body, '<td hidden>22</td>'
    assert_includes last_response.body, '<td hidden>23</td>'
    assert_includes last_response.body, '<td hidden>24</td>'
    assert_includes last_response.body, '<td hidden>25</td>'
    assert_includes last_response.body, '<td hidden>26</td>'
    assert_includes last_response.body, '<td hidden>27</td>'
    assert_includes last_response.body, '<td hidden>28</td>'
    assert_includes last_response.body, '<td hidden>29</td>'
    assert_includes last_response.body, '<td hidden>20</td>'
    assert_includes last_response.body, '<td hidden>31</td>'
    assert_includes last_response.body, '<td hidden>32</td>'
    assert_includes last_response.body, '<td hidden>33</td>'
    assert_includes last_response.body, '<td hidden>34</td>'
    assert_includes last_response.body, '<td hidden>35</td>'
    assert_includes last_response.body, '<td hidden>36</td>'
    assert_includes last_response.body, '<td hidden>37</td>'
    assert_includes last_response.body, '<td hidden>38</td>'
    assert_includes last_response.body, '<td hidden>39</td>'
    assert_includes last_response.body, '<td hidden>40</td>'
    assert_includes last_response.body, '<td hidden>41</td>'
    assert_includes last_response.body, '<td hidden>42</td>'
    assert_includes last_response.body, '<td hidden>43</td>'
    assert_includes last_response.body, '<td hidden>44</td>'
    assert_includes last_response.body, '<td hidden>45</td>'
    assert_includes last_response.body, '<td hidden>46</td>'
    assert_includes last_response.body, '<td hidden>47</td>'
    assert_includes last_response.body, '<td hidden>48</td>'
    assert_includes last_response.body, '<td hidden>49</td>'
    assert_includes last_response.body, '<td hidden>50</td>'
    assert_includes last_response.body, '<td hidden>51</td>'
    assert_includes last_response.body, '<td hidden>52</td>'
    assert_includes last_response.body, '<td hidden>53</td>'
    assert_includes last_response.body, '<td hidden>54</td>'
    assert_includes last_response.body, '<td hidden>55</td>'
    assert_includes last_response.body, '<td hidden>56</td>'
    assert_includes last_response.body, '<td hidden>57</td>'
    assert_includes last_response.body, '<td hidden>58</td>'
    assert_includes last_response.body, '<td hidden>59</td>'
    assert_includes last_response.body, '<td hidden>60</td>'
    assert_includes last_response.body, '<td hidden>61</td>'
    assert_includes last_response.body, '<td hidden>62</td>'
    assert_includes last_response.body, '<td hidden>63</td>'
    assert_includes last_response.body, '<td hidden>64</td>'
  end
  
  def test_filter_matches_locked_down
    post '/matches/filter',
      {match_status: 'locked_down', prediction_status: 'all', "Group Stages"=>"tournament_stage", "Round of 16"=>"tournament_stage", "Quarter Finals"=>"tournament_stage", "Semi Finals"=>"tournament_stage", "Third Fourth Place Play-off"=>"tournament_stage", "Final"=>"tournament_stage"},
      user_11_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Matches List'
    assert_includes last_response.body, '<td hidden>1</td>'
    assert_includes last_response.body, '<td hidden>2</td>'
    assert_includes last_response.body, '<td hidden>3</td>'
    assert_includes last_response.body, '<td hidden>4</td>'
    assert_includes last_response.body, '<td hidden>5</td>'
    assert_includes last_response.body, '<td hidden>6</td>'
    assert_includes last_response.body, '<td hidden>7</td>'
    assert_includes last_response.body, '<td hidden>8</td>'
    refute_includes last_response.body, '<td hidden>9</td>'
    refute_includes last_response.body, '<td hidden>10</td>'
    refute_includes last_response.body, '<td hidden>11</td>'
    refute_includes last_response.body, '<td hidden>12</td>'
    refute_includes last_response.body, '<td hidden>13</td>'
    refute_includes last_response.body, '<td hidden>14</td>'
    refute_includes last_response.body, '<td hidden>15</td>'
    refute_includes last_response.body, '<td hidden>16</td>'
    refute_includes last_response.body, '<td hidden>17</td>'
    refute_includes last_response.body, '<td hidden>18</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>21</td>'
    refute_includes last_response.body, '<td hidden>22</td>'
    refute_includes last_response.body, '<td hidden>23</td>'
    refute_includes last_response.body, '<td hidden>24</td>'
    refute_includes last_response.body, '<td hidden>25</td>'
    refute_includes last_response.body, '<td hidden>26</td>'
    refute_includes last_response.body, '<td hidden>27</td>'
    refute_includes last_response.body, '<td hidden>28</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>31</td>'
    refute_includes last_response.body, '<td hidden>32</td>'
    refute_includes last_response.body, '<td hidden>33</td>'
    refute_includes last_response.body, '<td hidden>34</td>'
    refute_includes last_response.body, '<td hidden>35</td>'
    refute_includes last_response.body, '<td hidden>36</td>'
    refute_includes last_response.body, '<td hidden>37</td>'
    refute_includes last_response.body, '<td hidden>38</td>'
    refute_includes last_response.body, '<td hidden>39</td>'
    refute_includes last_response.body, '<td hidden>40</td>'
    refute_includes last_response.body, '<td hidden>41</td>'
    refute_includes last_response.body, '<td hidden>42</td>'
    refute_includes last_response.body, '<td hidden>43</td>'
    refute_includes last_response.body, '<td hidden>44</td>'
    refute_includes last_response.body, '<td hidden>45</td>'
    refute_includes last_response.body, '<td hidden>46</td>'
    refute_includes last_response.body, '<td hidden>47</td>'
    refute_includes last_response.body, '<td hidden>48</td>'
    refute_includes last_response.body, '<td hidden>49</td>'
    refute_includes last_response.body, '<td hidden>50</td>'
    refute_includes last_response.body, '<td hidden>51</td>'
    refute_includes last_response.body, '<td hidden>52</td>'
    refute_includes last_response.body, '<td hidden>53</td>'
    refute_includes last_response.body, '<td hidden>54</td>'
    refute_includes last_response.body, '<td hidden>55</td>'
    refute_includes last_response.body, '<td hidden>56</td>'
    refute_includes last_response.body, '<td hidden>57</td>'
    refute_includes last_response.body, '<td hidden>58</td>'
    refute_includes last_response.body, '<td hidden>59</td>'
    refute_includes last_response.body, '<td hidden>60</td>'
    refute_includes last_response.body, '<td hidden>61</td>'
    refute_includes last_response.body, '<td hidden>62</td>'
    refute_includes last_response.body, '<td hidden>63</td>'
    refute_includes last_response.body, '<td hidden>64</td>'
  end
  
  def test_filter_matches_not_locked_down
    post '/matches/filter',
      {match_status: 'not_locked_down', prediction_status: 'all', "Group Stages"=>"tournament_stage", "Round of 16"=>"tournament_stage", "Quarter Finals"=>"tournament_stage", "Semi Finals"=>"tournament_stage", "Third Fourth Place Play-off"=>"tournament_stage", "Final"=>"tournament_stage"},
      user_11_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Matches List'
    refute_includes last_response.body, '<td hidden>1</td>'
    refute_includes last_response.body, '<td hidden>2</td>'
    refute_includes last_response.body, '<td hidden>3</td>'
    refute_includes last_response.body, '<td hidden>4</td>'
    refute_includes last_response.body, '<td hidden>5</td>'
    refute_includes last_response.body, '<td hidden>6</td>'
    refute_includes last_response.body, '<td hidden>7</td>'
    refute_includes last_response.body, '<td hidden>8</td>'
    assert_includes last_response.body, '<td hidden>9</td>'
    assert_includes last_response.body, '<td hidden>10</td>'
    assert_includes last_response.body, '<td hidden>11</td>'
    assert_includes last_response.body, '<td hidden>12</td>'
    assert_includes last_response.body, '<td hidden>13</td>'
    assert_includes last_response.body, '<td hidden>14</td>'
    assert_includes last_response.body, '<td hidden>15</td>'
    assert_includes last_response.body, '<td hidden>16</td>'
    assert_includes last_response.body, '<td hidden>17</td>'
    assert_includes last_response.body, '<td hidden>18</td>'
    assert_includes last_response.body, '<td hidden>29</td>'
    assert_includes last_response.body, '<td hidden>20</td>'
    assert_includes last_response.body, '<td hidden>21</td>'
    assert_includes last_response.body, '<td hidden>22</td>'
    assert_includes last_response.body, '<td hidden>23</td>'
    assert_includes last_response.body, '<td hidden>24</td>'
    assert_includes last_response.body, '<td hidden>25</td>'
    assert_includes last_response.body, '<td hidden>26</td>'
    assert_includes last_response.body, '<td hidden>27</td>'
    assert_includes last_response.body, '<td hidden>28</td>'
    assert_includes last_response.body, '<td hidden>29</td>'
    assert_includes last_response.body, '<td hidden>20</td>'
    assert_includes last_response.body, '<td hidden>31</td>'
    assert_includes last_response.body, '<td hidden>32</td>'
    assert_includes last_response.body, '<td hidden>33</td>'
    assert_includes last_response.body, '<td hidden>34</td>'
    assert_includes last_response.body, '<td hidden>35</td>'
    assert_includes last_response.body, '<td hidden>36</td>'
    assert_includes last_response.body, '<td hidden>37</td>'
    assert_includes last_response.body, '<td hidden>38</td>'
    assert_includes last_response.body, '<td hidden>39</td>'
    assert_includes last_response.body, '<td hidden>40</td>'
    assert_includes last_response.body, '<td hidden>41</td>'
    assert_includes last_response.body, '<td hidden>42</td>'
    assert_includes last_response.body, '<td hidden>43</td>'
    assert_includes last_response.body, '<td hidden>44</td>'
    assert_includes last_response.body, '<td hidden>45</td>'
    assert_includes last_response.body, '<td hidden>46</td>'
    assert_includes last_response.body, '<td hidden>47</td>'
    assert_includes last_response.body, '<td hidden>48</td>'
    assert_includes last_response.body, '<td hidden>49</td>'
    assert_includes last_response.body, '<td hidden>50</td>'
    assert_includes last_response.body, '<td hidden>51</td>'
    assert_includes last_response.body, '<td hidden>52</td>'
    assert_includes last_response.body, '<td hidden>53</td>'
    assert_includes last_response.body, '<td hidden>54</td>'
    assert_includes last_response.body, '<td hidden>55</td>'
    assert_includes last_response.body, '<td hidden>56</td>'
    assert_includes last_response.body, '<td hidden>57</td>'
    assert_includes last_response.body, '<td hidden>58</td>'
    assert_includes last_response.body, '<td hidden>59</td>'
    assert_includes last_response.body, '<td hidden>60</td>'
    assert_includes last_response.body, '<td hidden>61</td>'
    assert_includes last_response.body, '<td hidden>62</td>'
    assert_includes last_response.body, '<td hidden>63</td>'
    assert_includes last_response.body, '<td hidden>64</td>'
  end
  
  def test_filter_matches_predicted
    post '/matches/filter',
      {match_status: 'all', prediction_status: 'predicted', "Group Stages"=>"tournament_stage", "Round of 16"=>"tournament_stage", "Quarter Finals"=>"tournament_stage", "Semi Finals"=>"tournament_stage", "Third Fourth Place Play-off"=>"tournament_stage", "Final"=>"tournament_stage"},
      user_11_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Matches List'
    refute_includes last_response.body, '<td hidden>1</td>'
    refute_includes last_response.body, '<td hidden>2</td>'
    refute_includes last_response.body, '<td hidden>3</td>'
    refute_includes last_response.body, '<td hidden>4</td>'
    refute_includes last_response.body, '<td hidden>5</td>'
    assert_includes last_response.body, '<td hidden>6</td>'
    refute_includes last_response.body, '<td hidden>7</td>'
    assert_includes last_response.body, '<td hidden>8</td>'
    refute_includes last_response.body, '<td hidden>9</td>'
    refute_includes last_response.body, '<td hidden>10</td>'
    assert_includes last_response.body, '<td hidden>11</td>'
    refute_includes last_response.body, '<td hidden>12</td>'
    refute_includes last_response.body, '<td hidden>13</td>'
    refute_includes last_response.body, '<td hidden>14</td>'
    refute_includes last_response.body, '<td hidden>15</td>'
    refute_includes last_response.body, '<td hidden>16</td>'
    refute_includes last_response.body, '<td hidden>17</td>'
    refute_includes last_response.body, '<td hidden>18</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>21</td>'
    refute_includes last_response.body, '<td hidden>22</td>'
    refute_includes last_response.body, '<td hidden>23</td>'
    refute_includes last_response.body, '<td hidden>24</td>'
    refute_includes last_response.body, '<td hidden>25</td>'
    refute_includes last_response.body, '<td hidden>26</td>'
    refute_includes last_response.body, '<td hidden>27</td>'
    refute_includes last_response.body, '<td hidden>28</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>31</td>'
    refute_includes last_response.body, '<td hidden>32</td>'
    refute_includes last_response.body, '<td hidden>33</td>'
    refute_includes last_response.body, '<td hidden>34</td>'
    refute_includes last_response.body, '<td hidden>35</td>'
    refute_includes last_response.body, '<td hidden>36</td>'
    refute_includes last_response.body, '<td hidden>37</td>'
    refute_includes last_response.body, '<td hidden>38</td>'
    refute_includes last_response.body, '<td hidden>39</td>'
    refute_includes last_response.body, '<td hidden>40</td>'
    refute_includes last_response.body, '<td hidden>41</td>'
    refute_includes last_response.body, '<td hidden>42</td>'
    refute_includes last_response.body, '<td hidden>43</td>'
    refute_includes last_response.body, '<td hidden>44</td>'
    refute_includes last_response.body, '<td hidden>45</td>'
    refute_includes last_response.body, '<td hidden>46</td>'
    refute_includes last_response.body, '<td hidden>47</td>'
    refute_includes last_response.body, '<td hidden>48</td>'
    refute_includes last_response.body, '<td hidden>49</td>'
    refute_includes last_response.body, '<td hidden>50</td>'
    refute_includes last_response.body, '<td hidden>51</td>'
    refute_includes last_response.body, '<td hidden>52</td>'
    refute_includes last_response.body, '<td hidden>53</td>'
    refute_includes last_response.body, '<td hidden>54</td>'
    refute_includes last_response.body, '<td hidden>55</td>'
    refute_includes last_response.body, '<td hidden>56</td>'
    refute_includes last_response.body, '<td hidden>57</td>'
    refute_includes last_response.body, '<td hidden>58</td>'
    refute_includes last_response.body, '<td hidden>59</td>'
    refute_includes last_response.body, '<td hidden>60</td>'
    refute_includes last_response.body, '<td hidden>61</td>'
    refute_includes last_response.body, '<td hidden>62</td>'
    refute_includes last_response.body, '<td hidden>63</td>'
    refute_includes last_response.body, '<td hidden>64</td>'
  end
  
  def test_filter_matches_not_predicted
    post '/matches/filter',
      {match_status: 'all', prediction_status: 'not_predicted', "Group Stages"=>"tournament_stage", "Round of 16"=>"tournament_stage", "Quarter Finals"=>"tournament_stage", "Semi Finals"=>"tournament_stage", "Third Fourth Place Play-off"=>"tournament_stage", "Final"=>"tournament_stage"},
      user_11_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Matches List'
    assert_includes last_response.body, '<td hidden>1</td>'
    assert_includes last_response.body, '<td hidden>2</td>'
    assert_includes last_response.body, '<td hidden>3</td>'
    assert_includes last_response.body, '<td hidden>4</td>'
    assert_includes last_response.body, '<td hidden>5</td>'
    refute_includes last_response.body, '<td hidden>6</td>'
    assert_includes last_response.body, '<td hidden>7</td>'
    refute_includes last_response.body, '<td hidden>8</td>'
    assert_includes last_response.body, '<td hidden>9</td>'
    assert_includes last_response.body, '<td hidden>10</td>'
    refute_includes last_response.body, '<td hidden>11</td>'
    assert_includes last_response.body, '<td hidden>12</td>'
    assert_includes last_response.body, '<td hidden>13</td>'
    assert_includes last_response.body, '<td hidden>14</td>'
    assert_includes last_response.body, '<td hidden>15</td>'
    assert_includes last_response.body, '<td hidden>16</td>'
    assert_includes last_response.body, '<td hidden>17</td>'
    assert_includes last_response.body, '<td hidden>18</td>'
    assert_includes last_response.body, '<td hidden>29</td>'
    assert_includes last_response.body, '<td hidden>20</td>'
    assert_includes last_response.body, '<td hidden>21</td>'
    assert_includes last_response.body, '<td hidden>22</td>'
    assert_includes last_response.body, '<td hidden>23</td>'
    assert_includes last_response.body, '<td hidden>24</td>'
    assert_includes last_response.body, '<td hidden>25</td>'
    assert_includes last_response.body, '<td hidden>26</td>'
    assert_includes last_response.body, '<td hidden>27</td>'
    assert_includes last_response.body, '<td hidden>28</td>'
    assert_includes last_response.body, '<td hidden>29</td>'
    assert_includes last_response.body, '<td hidden>20</td>'
    assert_includes last_response.body, '<td hidden>31</td>'
    assert_includes last_response.body, '<td hidden>32</td>'
    assert_includes last_response.body, '<td hidden>33</td>'
    assert_includes last_response.body, '<td hidden>34</td>'
    assert_includes last_response.body, '<td hidden>35</td>'
    assert_includes last_response.body, '<td hidden>36</td>'
    assert_includes last_response.body, '<td hidden>37</td>'
    assert_includes last_response.body, '<td hidden>38</td>'
    assert_includes last_response.body, '<td hidden>39</td>'
    assert_includes last_response.body, '<td hidden>40</td>'
    assert_includes last_response.body, '<td hidden>41</td>'
    assert_includes last_response.body, '<td hidden>42</td>'
    assert_includes last_response.body, '<td hidden>43</td>'
    assert_includes last_response.body, '<td hidden>44</td>'
    assert_includes last_response.body, '<td hidden>45</td>'
    assert_includes last_response.body, '<td hidden>46</td>'
    assert_includes last_response.body, '<td hidden>47</td>'
    assert_includes last_response.body, '<td hidden>48</td>'
    assert_includes last_response.body, '<td hidden>49</td>'
    assert_includes last_response.body, '<td hidden>50</td>'
    assert_includes last_response.body, '<td hidden>51</td>'
    assert_includes last_response.body, '<td hidden>52</td>'
    assert_includes last_response.body, '<td hidden>53</td>'
    assert_includes last_response.body, '<td hidden>54</td>'
    assert_includes last_response.body, '<td hidden>55</td>'
    assert_includes last_response.body, '<td hidden>56</td>'
    assert_includes last_response.body, '<td hidden>57</td>'
    assert_includes last_response.body, '<td hidden>58</td>'
    assert_includes last_response.body, '<td hidden>59</td>'
    assert_includes last_response.body, '<td hidden>60</td>'
    assert_includes last_response.body, '<td hidden>61</td>'
    assert_includes last_response.body, '<td hidden>62</td>'
    assert_includes last_response.body, '<td hidden>63</td>'
    assert_includes last_response.body, '<td hidden>64</td>'
  end
  
  def test_filter_matches_group_stages
    post '/matches/filter',
      {match_status: 'all', prediction_status: 'all', "Group Stages"=>"tournament_stage"},
      user_11_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Matches List'
    assert_includes last_response.body, '<td hidden>1</td>'
    assert_includes last_response.body, '<td hidden>2</td>'
    assert_includes last_response.body, '<td hidden>3</td>'
    assert_includes last_response.body, '<td hidden>4</td>'
    assert_includes last_response.body, '<td hidden>5</td>'
    assert_includes last_response.body, '<td hidden>6</td>'
    assert_includes last_response.body, '<td hidden>7</td>'
    assert_includes last_response.body, '<td hidden>8</td>'
    assert_includes last_response.body, '<td hidden>9</td>'
    assert_includes last_response.body, '<td hidden>10</td>'
    assert_includes last_response.body, '<td hidden>11</td>'
    assert_includes last_response.body, '<td hidden>12</td>'
    assert_includes last_response.body, '<td hidden>13</td>'
    assert_includes last_response.body, '<td hidden>14</td>'
    assert_includes last_response.body, '<td hidden>15</td>'
    assert_includes last_response.body, '<td hidden>16</td>'
    assert_includes last_response.body, '<td hidden>17</td>'
    assert_includes last_response.body, '<td hidden>18</td>'
    assert_includes last_response.body, '<td hidden>29</td>'
    assert_includes last_response.body, '<td hidden>20</td>'
    assert_includes last_response.body, '<td hidden>21</td>'
    assert_includes last_response.body, '<td hidden>22</td>'
    assert_includes last_response.body, '<td hidden>23</td>'
    assert_includes last_response.body, '<td hidden>24</td>'
    assert_includes last_response.body, '<td hidden>25</td>'
    assert_includes last_response.body, '<td hidden>26</td>'
    assert_includes last_response.body, '<td hidden>27</td>'
    assert_includes last_response.body, '<td hidden>28</td>'
    assert_includes last_response.body, '<td hidden>29</td>'
    assert_includes last_response.body, '<td hidden>20</td>'
    assert_includes last_response.body, '<td hidden>31</td>'
    assert_includes last_response.body, '<td hidden>32</td>'
    assert_includes last_response.body, '<td hidden>33</td>'
    assert_includes last_response.body, '<td hidden>34</td>'
    assert_includes last_response.body, '<td hidden>35</td>'
    assert_includes last_response.body, '<td hidden>36</td>'
    assert_includes last_response.body, '<td hidden>37</td>'
    assert_includes last_response.body, '<td hidden>38</td>'
    assert_includes last_response.body, '<td hidden>39</td>'
    assert_includes last_response.body, '<td hidden>40</td>'
    assert_includes last_response.body, '<td hidden>41</td>'
    assert_includes last_response.body, '<td hidden>42</td>'
    assert_includes last_response.body, '<td hidden>43</td>'
    assert_includes last_response.body, '<td hidden>44</td>'
    assert_includes last_response.body, '<td hidden>45</td>'
    assert_includes last_response.body, '<td hidden>46</td>'
    assert_includes last_response.body, '<td hidden>47</td>'
    assert_includes last_response.body, '<td hidden>48</td>'
    refute_includes last_response.body, '<td hidden>49</td>'
    refute_includes last_response.body, '<td hidden>50</td>'
    refute_includes last_response.body, '<td hidden>51</td>'
    refute_includes last_response.body, '<td hidden>52</td>'
    refute_includes last_response.body, '<td hidden>53</td>'
    refute_includes last_response.body, '<td hidden>54</td>'
    refute_includes last_response.body, '<td hidden>55</td>'
    refute_includes last_response.body, '<td hidden>56</td>'
    refute_includes last_response.body, '<td hidden>57</td>'
    refute_includes last_response.body, '<td hidden>58</td>'
    refute_includes last_response.body, '<td hidden>59</td>'
    refute_includes last_response.body, '<td hidden>60</td>'
    refute_includes last_response.body, '<td hidden>61</td>'
    refute_includes last_response.body, '<td hidden>62</td>'
    refute_includes last_response.body, '<td hidden>63</td>'
    refute_includes last_response.body, '<td hidden>64</td>'
  end
  
  def test_filter_matches_round_of_16
    post '/matches/filter',
      {match_status: 'all', prediction_status: 'all', "Round of 16"=>"tournament_stage"},
      user_11_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Matches List'
    refute_includes last_response.body, '<td hidden>1</td>'
    refute_includes last_response.body, '<td hidden>2</td>'
    refute_includes last_response.body, '<td hidden>3</td>'
    refute_includes last_response.body, '<td hidden>4</td>'
    refute_includes last_response.body, '<td hidden>5</td>'
    refute_includes last_response.body, '<td hidden>6</td>'
    refute_includes last_response.body, '<td hidden>7</td>'
    refute_includes last_response.body, '<td hidden>8</td>'
    refute_includes last_response.body, '<td hidden>9</td>'
    refute_includes last_response.body, '<td hidden>10</td>'
    refute_includes last_response.body, '<td hidden>11</td>'
    refute_includes last_response.body, '<td hidden>12</td>'
    refute_includes last_response.body, '<td hidden>13</td>'
    refute_includes last_response.body, '<td hidden>14</td>'
    refute_includes last_response.body, '<td hidden>15</td>'
    refute_includes last_response.body, '<td hidden>16</td>'
    refute_includes last_response.body, '<td hidden>17</td>'
    refute_includes last_response.body, '<td hidden>18</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>21</td>'
    refute_includes last_response.body, '<td hidden>22</td>'
    refute_includes last_response.body, '<td hidden>23</td>'
    refute_includes last_response.body, '<td hidden>24</td>'
    refute_includes last_response.body, '<td hidden>25</td>'
    refute_includes last_response.body, '<td hidden>26</td>'
    refute_includes last_response.body, '<td hidden>27</td>'
    refute_includes last_response.body, '<td hidden>28</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>31</td>'
    refute_includes last_response.body, '<td hidden>32</td>'
    refute_includes last_response.body, '<td hidden>33</td>'
    refute_includes last_response.body, '<td hidden>34</td>'
    refute_includes last_response.body, '<td hidden>35</td>'
    refute_includes last_response.body, '<td hidden>36</td>'
    refute_includes last_response.body, '<td hidden>37</td>'
    refute_includes last_response.body, '<td hidden>38</td>'
    refute_includes last_response.body, '<td hidden>39</td>'
    refute_includes last_response.body, '<td hidden>40</td>'
    refute_includes last_response.body, '<td hidden>41</td>'
    refute_includes last_response.body, '<td hidden>42</td>'
    refute_includes last_response.body, '<td hidden>43</td>'
    refute_includes last_response.body, '<td hidden>44</td>'
    refute_includes last_response.body, '<td hidden>45</td>'
    refute_includes last_response.body, '<td hidden>46</td>'
    refute_includes last_response.body, '<td hidden>47</td>'
    refute_includes last_response.body, '<td hidden>48</td>'
    assert_includes last_response.body, '<td hidden>49</td>'
    assert_includes last_response.body, '<td hidden>50</td>'
    assert_includes last_response.body, '<td hidden>51</td>'
    assert_includes last_response.body, '<td hidden>52</td>'
    assert_includes last_response.body, '<td hidden>53</td>'
    assert_includes last_response.body, '<td hidden>54</td>'
    assert_includes last_response.body, '<td hidden>55</td>'
    assert_includes last_response.body, '<td hidden>56</td>'
    refute_includes last_response.body, '<td hidden>57</td>'
    refute_includes last_response.body, '<td hidden>58</td>'
    refute_includes last_response.body, '<td hidden>59</td>'
    refute_includes last_response.body, '<td hidden>60</td>'
    refute_includes last_response.body, '<td hidden>61</td>'
    refute_includes last_response.body, '<td hidden>62</td>'
    refute_includes last_response.body, '<td hidden>63</td>'
    refute_includes last_response.body, '<td hidden>64</td>'
  end
  
  def test_filter_matches_quarter_finals
    post '/matches/filter',
      {match_status: 'all', prediction_status: 'all', "Quarter Finals"=>"tournament_stage"},
      user_11_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Matches List'
    refute_includes last_response.body, '<td hidden>1</td>'
    refute_includes last_response.body, '<td hidden>2</td>'
    refute_includes last_response.body, '<td hidden>3</td>'
    refute_includes last_response.body, '<td hidden>4</td>'
    refute_includes last_response.body, '<td hidden>5</td>'
    refute_includes last_response.body, '<td hidden>6</td>'
    refute_includes last_response.body, '<td hidden>7</td>'
    refute_includes last_response.body, '<td hidden>8</td>'
    refute_includes last_response.body, '<td hidden>9</td>'
    refute_includes last_response.body, '<td hidden>10</td>'
    refute_includes last_response.body, '<td hidden>11</td>'
    refute_includes last_response.body, '<td hidden>12</td>'
    refute_includes last_response.body, '<td hidden>13</td>'
    refute_includes last_response.body, '<td hidden>14</td>'
    refute_includes last_response.body, '<td hidden>15</td>'
    refute_includes last_response.body, '<td hidden>16</td>'
    refute_includes last_response.body, '<td hidden>17</td>'
    refute_includes last_response.body, '<td hidden>18</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>21</td>'
    refute_includes last_response.body, '<td hidden>22</td>'
    refute_includes last_response.body, '<td hidden>23</td>'
    refute_includes last_response.body, '<td hidden>24</td>'
    refute_includes last_response.body, '<td hidden>25</td>'
    refute_includes last_response.body, '<td hidden>26</td>'
    refute_includes last_response.body, '<td hidden>27</td>'
    refute_includes last_response.body, '<td hidden>28</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>31</td>'
    refute_includes last_response.body, '<td hidden>32</td>'
    refute_includes last_response.body, '<td hidden>33</td>'
    refute_includes last_response.body, '<td hidden>34</td>'
    refute_includes last_response.body, '<td hidden>35</td>'
    refute_includes last_response.body, '<td hidden>36</td>'
    refute_includes last_response.body, '<td hidden>37</td>'
    refute_includes last_response.body, '<td hidden>38</td>'
    refute_includes last_response.body, '<td hidden>39</td>'
    refute_includes last_response.body, '<td hidden>40</td>'
    refute_includes last_response.body, '<td hidden>41</td>'
    refute_includes last_response.body, '<td hidden>42</td>'
    refute_includes last_response.body, '<td hidden>43</td>'
    refute_includes last_response.body, '<td hidden>44</td>'
    refute_includes last_response.body, '<td hidden>45</td>'
    refute_includes last_response.body, '<td hidden>46</td>'
    refute_includes last_response.body, '<td hidden>47</td>'
    refute_includes last_response.body, '<td hidden>48</td>'
    refute_includes last_response.body, '<td hidden>49</td>'
    refute_includes last_response.body, '<td hidden>50</td>'
    refute_includes last_response.body, '<td hidden>51</td>'
    refute_includes last_response.body, '<td hidden>52</td>'
    refute_includes last_response.body, '<td hidden>53</td>'
    refute_includes last_response.body, '<td hidden>54</td>'
    refute_includes last_response.body, '<td hidden>55</td>'
    refute_includes last_response.body, '<td hidden>56</td>'
    assert_includes last_response.body, '<td hidden>57</td>'
    assert_includes last_response.body, '<td hidden>58</td>'
    assert_includes last_response.body, '<td hidden>59</td>'
    assert_includes last_response.body, '<td hidden>60</td>'
    refute_includes last_response.body, '<td hidden>61</td>'
    refute_includes last_response.body, '<td hidden>62</td>'
    refute_includes last_response.body, '<td hidden>63</td>'
    refute_includes last_response.body, '<td hidden>64</td>'
  end
   
  def test_filter_matches_semi_finals
    post '/matches/filter',
      {match_status: 'all', prediction_status: 'all', "Semi Finals"=>"tournament_stage"},
      user_11_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Matches List'
    refute_includes last_response.body, '<td hidden>1</td>'
    refute_includes last_response.body, '<td hidden>2</td>'
    refute_includes last_response.body, '<td hidden>3</td>'
    refute_includes last_response.body, '<td hidden>4</td>'
    refute_includes last_response.body, '<td hidden>5</td>'
    refute_includes last_response.body, '<td hidden>6</td>'
    refute_includes last_response.body, '<td hidden>7</td>'
    refute_includes last_response.body, '<td hidden>8</td>'
    refute_includes last_response.body, '<td hidden>9</td>'
    refute_includes last_response.body, '<td hidden>10</td>'
    refute_includes last_response.body, '<td hidden>11</td>'
    refute_includes last_response.body, '<td hidden>12</td>'
    refute_includes last_response.body, '<td hidden>13</td>'
    refute_includes last_response.body, '<td hidden>14</td>'
    refute_includes last_response.body, '<td hidden>15</td>'
    refute_includes last_response.body, '<td hidden>16</td>'
    refute_includes last_response.body, '<td hidden>17</td>'
    refute_includes last_response.body, '<td hidden>18</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>21</td>'
    refute_includes last_response.body, '<td hidden>22</td>'
    refute_includes last_response.body, '<td hidden>23</td>'
    refute_includes last_response.body, '<td hidden>24</td>'
    refute_includes last_response.body, '<td hidden>25</td>'
    refute_includes last_response.body, '<td hidden>26</td>'
    refute_includes last_response.body, '<td hidden>27</td>'
    refute_includes last_response.body, '<td hidden>28</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>31</td>'
    refute_includes last_response.body, '<td hidden>32</td>'
    refute_includes last_response.body, '<td hidden>33</td>'
    refute_includes last_response.body, '<td hidden>34</td>'
    refute_includes last_response.body, '<td hidden>35</td>'
    refute_includes last_response.body, '<td hidden>36</td>'
    refute_includes last_response.body, '<td hidden>37</td>'
    refute_includes last_response.body, '<td hidden>38</td>'
    refute_includes last_response.body, '<td hidden>39</td>'
    refute_includes last_response.body, '<td hidden>40</td>'
    refute_includes last_response.body, '<td hidden>41</td>'
    refute_includes last_response.body, '<td hidden>42</td>'
    refute_includes last_response.body, '<td hidden>43</td>'
    refute_includes last_response.body, '<td hidden>44</td>'
    refute_includes last_response.body, '<td hidden>45</td>'
    refute_includes last_response.body, '<td hidden>46</td>'
    refute_includes last_response.body, '<td hidden>47</td>'
    refute_includes last_response.body, '<td hidden>48</td>'
    refute_includes last_response.body, '<td hidden>49</td>'
    refute_includes last_response.body, '<td hidden>50</td>'
    refute_includes last_response.body, '<td hidden>51</td>'
    refute_includes last_response.body, '<td hidden>52</td>'
    refute_includes last_response.body, '<td hidden>53</td>'
    refute_includes last_response.body, '<td hidden>54</td>'
    refute_includes last_response.body, '<td hidden>55</td>'
    refute_includes last_response.body, '<td hidden>56</td>'
    refute_includes last_response.body, '<td hidden>57</td>'
    refute_includes last_response.body, '<td hidden>58</td>'
    refute_includes last_response.body, '<td hidden>59</td>'
    refute_includes last_response.body, '<td hidden>60</td>'
    assert_includes last_response.body, '<td hidden>61</td>'
    assert_includes last_response.body, '<td hidden>62</td>'
    refute_includes last_response.body, '<td hidden>63</td>'
    refute_includes last_response.body, '<td hidden>64</td>'
  end
  
  def test_filter_matches_3_4_place
    post '/matches/filter',
      {match_status: 'all', prediction_status: 'all', "Third Fourth Place Play-off"=>"tournament_stage"},
      user_11_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Matches List'
    refute_includes last_response.body, '<td hidden>1</td>'
    refute_includes last_response.body, '<td hidden>2</td>'
    refute_includes last_response.body, '<td hidden>3</td>'
    refute_includes last_response.body, '<td hidden>4</td>'
    refute_includes last_response.body, '<td hidden>5</td>'
    refute_includes last_response.body, '<td hidden>6</td>'
    refute_includes last_response.body, '<td hidden>7</td>'
    refute_includes last_response.body, '<td hidden>8</td>'
    refute_includes last_response.body, '<td hidden>9</td>'
    refute_includes last_response.body, '<td hidden>10</td>'
    refute_includes last_response.body, '<td hidden>11</td>'
    refute_includes last_response.body, '<td hidden>12</td>'
    refute_includes last_response.body, '<td hidden>13</td>'
    refute_includes last_response.body, '<td hidden>14</td>'
    refute_includes last_response.body, '<td hidden>15</td>'
    refute_includes last_response.body, '<td hidden>16</td>'
    refute_includes last_response.body, '<td hidden>17</td>'
    refute_includes last_response.body, '<td hidden>18</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>21</td>'
    refute_includes last_response.body, '<td hidden>22</td>'
    refute_includes last_response.body, '<td hidden>23</td>'
    refute_includes last_response.body, '<td hidden>24</td>'
    refute_includes last_response.body, '<td hidden>25</td>'
    refute_includes last_response.body, '<td hidden>26</td>'
    refute_includes last_response.body, '<td hidden>27</td>'
    refute_includes last_response.body, '<td hidden>28</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>31</td>'
    refute_includes last_response.body, '<td hidden>32</td>'
    refute_includes last_response.body, '<td hidden>33</td>'
    refute_includes last_response.body, '<td hidden>34</td>'
    refute_includes last_response.body, '<td hidden>35</td>'
    refute_includes last_response.body, '<td hidden>36</td>'
    refute_includes last_response.body, '<td hidden>37</td>'
    refute_includes last_response.body, '<td hidden>38</td>'
    refute_includes last_response.body, '<td hidden>39</td>'
    refute_includes last_response.body, '<td hidden>40</td>'
    refute_includes last_response.body, '<td hidden>41</td>'
    refute_includes last_response.body, '<td hidden>42</td>'
    refute_includes last_response.body, '<td hidden>43</td>'
    refute_includes last_response.body, '<td hidden>44</td>'
    refute_includes last_response.body, '<td hidden>45</td>'
    refute_includes last_response.body, '<td hidden>46</td>'
    refute_includes last_response.body, '<td hidden>47</td>'
    refute_includes last_response.body, '<td hidden>48</td>'
    refute_includes last_response.body, '<td hidden>49</td>'
    refute_includes last_response.body, '<td hidden>50</td>'
    refute_includes last_response.body, '<td hidden>51</td>'
    refute_includes last_response.body, '<td hidden>52</td>'
    refute_includes last_response.body, '<td hidden>53</td>'
    refute_includes last_response.body, '<td hidden>54</td>'
    refute_includes last_response.body, '<td hidden>55</td>'
    refute_includes last_response.body, '<td hidden>56</td>'
    refute_includes last_response.body, '<td hidden>57</td>'
    refute_includes last_response.body, '<td hidden>58</td>'
    refute_includes last_response.body, '<td hidden>59</td>'
    refute_includes last_response.body, '<td hidden>60</td>'
    refute_includes last_response.body, '<td hidden>61</td>'
    refute_includes last_response.body, '<td hidden>62</td>'
    assert_includes last_response.body, '<td hidden>63</td>'
    refute_includes last_response.body, '<td hidden>64</td>'
  end
  
  def test_filter_matches_final
    post '/matches/filter',
      {match_status: 'all', prediction_status: 'all', "Final"=>"tournament_stage"},
      user_11_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Matches List'
    refute_includes last_response.body, '<td hidden>1</td>'
    refute_includes last_response.body, '<td hidden>2</td>'
    refute_includes last_response.body, '<td hidden>3</td>'
    refute_includes last_response.body, '<td hidden>4</td>'
    refute_includes last_response.body, '<td hidden>5</td>'
    refute_includes last_response.body, '<td hidden>6</td>'
    refute_includes last_response.body, '<td hidden>7</td>'
    refute_includes last_response.body, '<td hidden>8</td>'
    refute_includes last_response.body, '<td hidden>9</td>'
    refute_includes last_response.body, '<td hidden>10</td>'
    refute_includes last_response.body, '<td hidden>11</td>'
    refute_includes last_response.body, '<td hidden>12</td>'
    refute_includes last_response.body, '<td hidden>13</td>'
    refute_includes last_response.body, '<td hidden>14</td>'
    refute_includes last_response.body, '<td hidden>15</td>'
    refute_includes last_response.body, '<td hidden>16</td>'
    refute_includes last_response.body, '<td hidden>17</td>'
    refute_includes last_response.body, '<td hidden>18</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>21</td>'
    refute_includes last_response.body, '<td hidden>22</td>'
    refute_includes last_response.body, '<td hidden>23</td>'
    refute_includes last_response.body, '<td hidden>24</td>'
    refute_includes last_response.body, '<td hidden>25</td>'
    refute_includes last_response.body, '<td hidden>26</td>'
    refute_includes last_response.body, '<td hidden>27</td>'
    refute_includes last_response.body, '<td hidden>28</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>31</td>'
    refute_includes last_response.body, '<td hidden>32</td>'
    refute_includes last_response.body, '<td hidden>33</td>'
    refute_includes last_response.body, '<td hidden>34</td>'
    refute_includes last_response.body, '<td hidden>35</td>'
    refute_includes last_response.body, '<td hidden>36</td>'
    refute_includes last_response.body, '<td hidden>37</td>'
    refute_includes last_response.body, '<td hidden>38</td>'
    refute_includes last_response.body, '<td hidden>39</td>'
    refute_includes last_response.body, '<td hidden>40</td>'
    refute_includes last_response.body, '<td hidden>41</td>'
    refute_includes last_response.body, '<td hidden>42</td>'
    refute_includes last_response.body, '<td hidden>43</td>'
    refute_includes last_response.body, '<td hidden>44</td>'
    refute_includes last_response.body, '<td hidden>45</td>'
    refute_includes last_response.body, '<td hidden>46</td>'
    refute_includes last_response.body, '<td hidden>47</td>'
    refute_includes last_response.body, '<td hidden>48</td>'
    refute_includes last_response.body, '<td hidden>49</td>'
    refute_includes last_response.body, '<td hidden>50</td>'
    refute_includes last_response.body, '<td hidden>51</td>'
    refute_includes last_response.body, '<td hidden>52</td>'
    refute_includes last_response.body, '<td hidden>53</td>'
    refute_includes last_response.body, '<td hidden>54</td>'
    refute_includes last_response.body, '<td hidden>55</td>'
    refute_includes last_response.body, '<td hidden>56</td>'
    refute_includes last_response.body, '<td hidden>57</td>'
    refute_includes last_response.body, '<td hidden>58</td>'
    refute_includes last_response.body, '<td hidden>59</td>'
    refute_includes last_response.body, '<td hidden>60</td>'
    refute_includes last_response.body, '<td hidden>61</td>'
    refute_includes last_response.body, '<td hidden>62</td>'
    refute_includes last_response.body, '<td hidden>63</td>'
    assert_includes last_response.body, '<td hidden>64</td>'
  end
  
def test_filter_matches_group_stages_and_final
    post '/matches/filter',
      {match_status: 'all', prediction_status: 'all', "Group Stages"=>"tournament_stage", "Final"=>"tournament_stage"},
      user_11_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Matches List'
    assert_includes last_response.body, '<td hidden>1</td>'
    assert_includes last_response.body, '<td hidden>2</td>'
    assert_includes last_response.body, '<td hidden>3</td>'
    assert_includes last_response.body, '<td hidden>4</td>'
    assert_includes last_response.body, '<td hidden>5</td>'
    assert_includes last_response.body, '<td hidden>6</td>'
    assert_includes last_response.body, '<td hidden>7</td>'
    assert_includes last_response.body, '<td hidden>8</td>'
    assert_includes last_response.body, '<td hidden>9</td>'
    assert_includes last_response.body, '<td hidden>10</td>'
    assert_includes last_response.body, '<td hidden>11</td>'
    assert_includes last_response.body, '<td hidden>12</td>'
    assert_includes last_response.body, '<td hidden>13</td>'
    assert_includes last_response.body, '<td hidden>14</td>'
    assert_includes last_response.body, '<td hidden>15</td>'
    assert_includes last_response.body, '<td hidden>16</td>'
    assert_includes last_response.body, '<td hidden>17</td>'
    assert_includes last_response.body, '<td hidden>18</td>'
    assert_includes last_response.body, '<td hidden>29</td>'
    assert_includes last_response.body, '<td hidden>20</td>'
    assert_includes last_response.body, '<td hidden>21</td>'
    assert_includes last_response.body, '<td hidden>22</td>'
    assert_includes last_response.body, '<td hidden>23</td>'
    assert_includes last_response.body, '<td hidden>24</td>'
    assert_includes last_response.body, '<td hidden>25</td>'
    assert_includes last_response.body, '<td hidden>26</td>'
    assert_includes last_response.body, '<td hidden>27</td>'
    assert_includes last_response.body, '<td hidden>28</td>'
    assert_includes last_response.body, '<td hidden>29</td>'
    assert_includes last_response.body, '<td hidden>20</td>'
    assert_includes last_response.body, '<td hidden>31</td>'
    assert_includes last_response.body, '<td hidden>32</td>'
    assert_includes last_response.body, '<td hidden>33</td>'
    assert_includes last_response.body, '<td hidden>34</td>'
    assert_includes last_response.body, '<td hidden>35</td>'
    assert_includes last_response.body, '<td hidden>36</td>'
    assert_includes last_response.body, '<td hidden>37</td>'
    assert_includes last_response.body, '<td hidden>38</td>'
    assert_includes last_response.body, '<td hidden>39</td>'
    assert_includes last_response.body, '<td hidden>40</td>'
    assert_includes last_response.body, '<td hidden>41</td>'
    assert_includes last_response.body, '<td hidden>42</td>'
    assert_includes last_response.body, '<td hidden>43</td>'
    assert_includes last_response.body, '<td hidden>44</td>'
    assert_includes last_response.body, '<td hidden>45</td>'
    assert_includes last_response.body, '<td hidden>46</td>'
    assert_includes last_response.body, '<td hidden>47</td>'
    assert_includes last_response.body, '<td hidden>48</td>'
    refute_includes last_response.body, '<td hidden>49</td>'
    refute_includes last_response.body, '<td hidden>50</td>'
    refute_includes last_response.body, '<td hidden>51</td>'
    refute_includes last_response.body, '<td hidden>52</td>'
    refute_includes last_response.body, '<td hidden>53</td>'
    refute_includes last_response.body, '<td hidden>54</td>'
    refute_includes last_response.body, '<td hidden>55</td>'
    refute_includes last_response.body, '<td hidden>56</td>'
    refute_includes last_response.body, '<td hidden>57</td>'
    refute_includes last_response.body, '<td hidden>58</td>'
    refute_includes last_response.body, '<td hidden>59</td>'
    refute_includes last_response.body, '<td hidden>60</td>'
    refute_includes last_response.body, '<td hidden>61</td>'
    refute_includes last_response.body, '<td hidden>62</td>'
    refute_includes last_response.body, '<td hidden>63</td>'
    assert_includes last_response.body, '<td hidden>64</td>'
  end
  
  def test_filter_matches_not_locked_down_predicted_group_stages
    post '/matches/filter',
      {match_status: 'not_locked_down', prediction_status: 'predicted', "Group Stages"=>"tournament_stage"},
      user_11_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Matches List'
    refute_includes last_response.body, '<td hidden>1</td>'
    refute_includes last_response.body, '<td hidden>2</td>'
    refute_includes last_response.body, '<td hidden>3</td>'
    refute_includes last_response.body, '<td hidden>4</td>'
    refute_includes last_response.body, '<td hidden>5</td>'
    refute_includes last_response.body, '<td hidden>6</td>'
    refute_includes last_response.body, '<td hidden>7</td>'
    refute_includes last_response.body, '<td hidden>8</td>'
    refute_includes last_response.body, '<td hidden>9</td>'
    refute_includes last_response.body, '<td hidden>10</td>'
    assert_includes last_response.body, '<td hidden>11</td>'
    refute_includes last_response.body, '<td hidden>12</td>'
    refute_includes last_response.body, '<td hidden>13</td>'
    refute_includes last_response.body, '<td hidden>14</td>'
    refute_includes last_response.body, '<td hidden>15</td>'
    refute_includes last_response.body, '<td hidden>16</td>'
    refute_includes last_response.body, '<td hidden>17</td>'
    refute_includes last_response.body, '<td hidden>18</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>21</td>'
    refute_includes last_response.body, '<td hidden>22</td>'
    refute_includes last_response.body, '<td hidden>23</td>'
    refute_includes last_response.body, '<td hidden>24</td>'
    refute_includes last_response.body, '<td hidden>25</td>'
    refute_includes last_response.body, '<td hidden>26</td>'
    refute_includes last_response.body, '<td hidden>27</td>'
    refute_includes last_response.body, '<td hidden>28</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>31</td>'
    refute_includes last_response.body, '<td hidden>32</td>'
    refute_includes last_response.body, '<td hidden>33</td>'
    refute_includes last_response.body, '<td hidden>34</td>'
    refute_includes last_response.body, '<td hidden>35</td>'
    refute_includes last_response.body, '<td hidden>36</td>'
    refute_includes last_response.body, '<td hidden>37</td>'
    refute_includes last_response.body, '<td hidden>38</td>'
    refute_includes last_response.body, '<td hidden>39</td>'
    refute_includes last_response.body, '<td hidden>40</td>'
    refute_includes last_response.body, '<td hidden>41</td>'
    refute_includes last_response.body, '<td hidden>42</td>'
    refute_includes last_response.body, '<td hidden>43</td>'
    refute_includes last_response.body, '<td hidden>44</td>'
    refute_includes last_response.body, '<td hidden>45</td>'
    refute_includes last_response.body, '<td hidden>46</td>'
    refute_includes last_response.body, '<td hidden>47</td>'
    refute_includes last_response.body, '<td hidden>48</td>'
    refute_includes last_response.body, '<td hidden>49</td>'
    refute_includes last_response.body, '<td hidden>50</td>'
    refute_includes last_response.body, '<td hidden>51</td>'
    refute_includes last_response.body, '<td hidden>52</td>'
    refute_includes last_response.body, '<td hidden>53</td>'
    refute_includes last_response.body, '<td hidden>54</td>'
    refute_includes last_response.body, '<td hidden>55</td>'
    refute_includes last_response.body, '<td hidden>56</td>'
    refute_includes last_response.body, '<td hidden>57</td>'
    refute_includes last_response.body, '<td hidden>58</td>'
    refute_includes last_response.body, '<td hidden>59</td>'
    refute_includes last_response.body, '<td hidden>60</td>'
    refute_includes last_response.body, '<td hidden>61</td>'
    refute_includes last_response.body, '<td hidden>62</td>'
    refute_includes last_response.body, '<td hidden>63</td>'
    refute_includes last_response.body, '<td hidden>64</td>'
  end
  
  def test_filter_matches_locked_down_predicted_group_stages
    post '/matches/filter',
      {match_status: 'locked_down', prediction_status: 'predicted', "Group Stages"=>"tournament_stage"},
      user_11_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Matches List'
    refute_includes last_response.body, '<td hidden>1</td>'
    refute_includes last_response.body, '<td hidden>2</td>'
    refute_includes last_response.body, '<td hidden>3</td>'
    refute_includes last_response.body, '<td hidden>4</td>'
    refute_includes last_response.body, '<td hidden>5</td>'
    assert_includes last_response.body, '<td hidden>6</td>'
    refute_includes last_response.body, '<td hidden>7</td>'
    assert_includes last_response.body, '<td hidden>8</td>'
    refute_includes last_response.body, '<td hidden>9</td>'
    refute_includes last_response.body, '<td hidden>10</td>'
    refute_includes last_response.body, '<td hidden>11</td>'
    refute_includes last_response.body, '<td hidden>12</td>'
    refute_includes last_response.body, '<td hidden>13</td>'
    refute_includes last_response.body, '<td hidden>14</td>'
    refute_includes last_response.body, '<td hidden>15</td>'
    refute_includes last_response.body, '<td hidden>16</td>'
    refute_includes last_response.body, '<td hidden>17</td>'
    refute_includes last_response.body, '<td hidden>18</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>21</td>'
    refute_includes last_response.body, '<td hidden>22</td>'
    refute_includes last_response.body, '<td hidden>23</td>'
    refute_includes last_response.body, '<td hidden>24</td>'
    refute_includes last_response.body, '<td hidden>25</td>'
    refute_includes last_response.body, '<td hidden>26</td>'
    refute_includes last_response.body, '<td hidden>27</td>'
    refute_includes last_response.body, '<td hidden>28</td>'
    refute_includes last_response.body, '<td hidden>29</td>'
    refute_includes last_response.body, '<td hidden>20</td>'
    refute_includes last_response.body, '<td hidden>31</td>'
    refute_includes last_response.body, '<td hidden>32</td>'
    refute_includes last_response.body, '<td hidden>33</td>'
    refute_includes last_response.body, '<td hidden>34</td>'
    refute_includes last_response.body, '<td hidden>35</td>'
    refute_includes last_response.body, '<td hidden>36</td>'
    refute_includes last_response.body, '<td hidden>37</td>'
    refute_includes last_response.body, '<td hidden>38</td>'
    refute_includes last_response.body, '<td hidden>39</td>'
    refute_includes last_response.body, '<td hidden>40</td>'
    refute_includes last_response.body, '<td hidden>41</td>'
    refute_includes last_response.body, '<td hidden>42</td>'
    refute_includes last_response.body, '<td hidden>43</td>'
    refute_includes last_response.body, '<td hidden>44</td>'
    refute_includes last_response.body, '<td hidden>45</td>'
    refute_includes last_response.body, '<td hidden>46</td>'
    refute_includes last_response.body, '<td hidden>47</td>'
    refute_includes last_response.body, '<td hidden>48</td>'
    refute_includes last_response.body, '<td hidden>49</td>'
    refute_includes last_response.body, '<td hidden>50</td>'
    refute_includes last_response.body, '<td hidden>51</td>'
    refute_includes last_response.body, '<td hidden>52</td>'
    refute_includes last_response.body, '<td hidden>53</td>'
    refute_includes last_response.body, '<td hidden>54</td>'
    refute_includes last_response.body, '<td hidden>55</td>'
    refute_includes last_response.body, '<td hidden>56</td>'
    refute_includes last_response.body, '<td hidden>57</td>'
    refute_includes last_response.body, '<td hidden>58</td>'
    refute_includes last_response.body, '<td hidden>59</td>'
    refute_includes last_response.body, '<td hidden>60</td>'
    refute_includes last_response.body, '<td hidden>61</td>'
    refute_includes last_response.body, '<td hidden>62</td>'
    refute_includes last_response.body, '<td hidden>63</td>'
    refute_includes last_response.body, '<td hidden>64</td>'
  end

  def test_filter_matches_search_criteria_retained
    post '/matches/filter',
      {match_status: 'locked_down', prediction_status: 'predicted', "Group Stages"=>"tournament_stage"},
      user_11_session

    assert_includes last_response.body.gsub(/\n/, ''), %q(value="locked_down"     checked)
    assert_includes last_response.body.gsub(/\n/, ''), %q(value="predicted"     checked)
    assert_includes last_response.body.gsub(/\n/, ''), %q(name="Group Stages"      value="tournament_stage"      checked)
    refute_includes last_response.body.gsub(/\n/, ''), %q(name="Final"      value="tournament_stage"      checked)
  end

  def test_filter_matches_no_matches_returned
    post '/matches/filter',
      {match_status: 'locked_down', prediction_status: 'all', "Final"=>"tournament_stage"},
      user_11_session

    assert_includes last_response.body, 'No matches meet your criteria, please try again!'
    refute_includes last_response.body, 'Matches List'
  end

  def test_carousel_predicted
    get '/match/6', {}, user_11_session_predicted_criteria

    assert_includes last_response.body, '<a href="/match/8">Next match'
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

    assert_includes last_response.body.gsub(/\n/, ''), '</td>          <td>England</td>          <td>no prediction</td>          <td>no prediction</td>          <td>Iran</td>          <td>              Locked down          </td>'
    assert_includes last_response.body.gsub(/\n/, ''), '<td>Morocco</td>          <td>no prediction</td>          <td>no prediction</td>          <td>Croatia</td>          <td>          </td>          <td>'
  end

  def test_select_deslect_all_on_matcfilter_form
    get '/matches/all', {}, user_11_session

    assert_includes last_response.body, 'Select/Deselect All'
  end

  # def test_signin_with_cookie
  #   post '/users/signin', {login: 'Maccas', pword: 'a'}, {}
  #   assert_equal 302, last_response.status
  #   assert_equal 'Welcome!', session[:message]
  #   assert_equal 'Maccas', session[:user_name]
  #   p cookies[:series_id]
  #   p session[:user_name]
    
  #   get '/', {}, nil_session
  #   p session[:user_name]
  #   gets
  #   assert_equal 200, last_response.status
  #   assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
  #   assert_equal 'Maccas', session[:user_name]
  # end
  
#   def test_signin_cookie_deleted_by_signout
#     post '/users/signin', {login: 'Maccas', pword: 'a'}, {}
#     assert_equal 302, last_response.status
#     assert_equal 'Welcome!', session[:message]
#     assert_equal 'Maccas', session[:user_name]
    
#     post '/users/signout'
    
#     get '/'
#     assert_equal 200, last_response.status
#     assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
#     refute_includes last_response.body, 'Signed in as Maccas'
#   end
end
