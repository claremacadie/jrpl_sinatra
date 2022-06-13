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

  def test_make_user_admin
    post '/users/toggle_admin', {user_id: '11', admin: 'true'}, admin_session
    post '/users/signout'

    post '/users/signin', {login: 'Clare Mac', pword: 'a'}, {}
    assert_equal 'Admin', session[:user_roles]
  end
  
  def test_make_admin_user_not_admin
    post '/users/toggle_admin', {user_id: '11', admin: 'true'}, admin_session
    post '/users/toggle_admin', {user_id: '11'}, admin_session
    post '/users/signout'

    post '/users/signin', {login: 'Clare Mac', pword: 'a'}, {}
    assert_nil session[:user_roles]
  end
  
  def test_make_user_admin_already_admin
    post '/users/toggle_admin', {user_id: '11', admin: 'true'}, admin_session
    post '/users/toggle_admin', {user_id: '11', admin: 'true'}, admin_session
    post '/users/signout'

    post '/users/signin', {login: 'Clare Mac', pword: 'a'}, {}
    assert_equal 'Admin', session[:user_roles]
  end
  
  def test_make_user_not_admin_already_not_admin
    post '/users/toggle_admin', {user_id: '11'}, admin_session
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
