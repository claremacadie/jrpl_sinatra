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
    { 'rack.session' => { user_name: 'admin' , user_id: 1, user_email: 'admin@julianrimet.com'} }
  end

  def user_2_session
    { 'rack.session' => { user_name: 'Clare Mac', user_id: 12, user_email: 'clare@macadie.co.uk'} }
  end
 
  def test_homepage
    get '/'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Julian Rimet Prediction League'
  end
 
  def test_all_users_list
    get '/all_users_list'
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Clare Mac'
    assert_includes last_response.body, 'This is a list of the display names of all users.'
  end
  
  def test_signin_form
    get '/users/signin'
    assert_equal 200, last_response.status
    assert_includes last_response.body, '<input'
    assert_includes last_response.body, %q(<button type="submit")
  end
  
  def test_signin
    post '/users/signin', {user_name: 'admin', pword: 'secret'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'admin', session[:user_name]
  
    get last_response['Location']
    assert_includes last_response.body, 'Signed in as admin.'
  end
  
  def test_signin_strip_input
    post '/users/signin', {user_name: '   admin  ', pword: ' secret '}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'admin', session[:user_name]
  
    get last_response['Location']
    assert_includes last_response.body, 'Signed in as admin.'
  end
  
  def test_signin_with_bad_credentials
    post '/users/signin', {user_name: 'guest', pword: 'shhhh'}, {}
    assert_equal 422, last_response.status
    assert_nil session[:user_name]
    assert_includes last_response.body, 'Invalid credentials.'
  end
  
  def test_signout
    get '/', {}, admin_session
    assert_includes last_response.body, 'Signed in as admin.'
  
    post '/users/signout'
    assert_equal 'You have been signed out.', session[:message]
  
    get last_response['Location']
    assert_nil session[:user_name]
    assert_includes last_response.body, 'Sign In'
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
  
  def test_signup_admin_username
    post '/users/signup', {new_user_name: 'admin', new_email: 'joe@joe.com', new_pword: 'dfghiewo34334', reenter_pword: 'dfghiewo34334'}
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Username cannot be 'admin'! Please choose a different username."
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
  
  def test_view_administer_account_form_signed_out
    get '/user/edit_credentials'
    assert_equal 302, last_response.status
    assert_includes session[:message], 'You must be signed in to do that.'
  end
  
  def test_view_administer_account_form_signed_in
    get '/user/edit_credentials', {}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Enter new username'
    assert_includes last_response.body, 'Enter your new email address'
    assert_includes last_response.body, 'Enter current password'
    assert_includes last_response.body, 'Enter new password'
    assert_includes last_response.body, 'Reenter new password'
  end
  
  def test_change_username
    post '/user/edit_credentials', {current_pword: 'a', new_user_name: 'joe', new_email: 'clare@macadie.co.uk', new_pword: '', reenter_pword: ''}, user_2_session
    assert_equal 302, last_response.status
    assert_equal 'joe', session[:user_name]
    assert_equal 'The following have been updated: username.', session[:message]
    
    get '/'
    assert_includes last_response.body, 'Signed in as joe.'
  end
  
  def test_change_username_strip_input
    post '/user/edit_credentials', {current_pword: '   a ', new_user_name: '   joe ', new_email: 'clare@macadie.co.uk',  new_pword: '', reenter_pword: ''}, user_2_session
    assert_equal 302, last_response.status
    assert_equal 'joe', session[:user_name]
    assert_equal 'The following have been updated: username.', session[:message]
    
    get '/'
    assert_includes last_response.body, 'Signed in as joe.'
  end
  
  def test_change_username_to_blank
    post '/user/edit_credentials', {current_pword: 'a', new_user_name: '', new_email: '', new_pword: '', reenter_pword: ''}, user_2_session
    assert_equal 422, last_response.status
    assert_equal 'Clare Mac', session[:user_name]
    assert_includes last_response.body, 'New username cannot be blank! Please enter a username.'
  end
  
  def test_change_username_to_admin
    post '/user/edit_credentials', {current_pword: 'a', new_user_name: 'admin', new_email: '', new_pword: '', reenter_pword: ''}, user_2_session
    assert_equal 422, last_response.status
    assert_equal 'Clare Mac', session[:user_name]
    assert_includes last_response.body, "New username cannot be 'admin'! Please choose a different username."
  end
  
  def test_change_username_to_existing_username
    post '/user/edit_credentials', {current_pword: 'a', new_user_name: 'Maccas', new_email: '', new_pword: '', reenter_pword: ''}, user_2_session
    assert_equal 422, last_response.status
    assert_equal 'Clare Mac', session[:user_name]
    assert_includes last_response.body, 'That username already exists. Please choose a different username.'
  end
  
  def test_change_pword
    post '/user/edit_credentials', {current_pword: 'a', new_user_name: 'Clare Mac', new_email: 'clare@macadie.co.uk', new_pword: 'Qwerty90', reenter_pword: 'Qwerty90'}, user_2_session
    assert_equal 302, last_response.status
    assert_equal 'Clare Mac', session[:user_name]
    assert_equal 'The following have been updated: password.', session[:message]
    
    post '/users/signin', {user_name: 'Clare Mac', pword: 'Qwerty90'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'Clare Mac', session[:user_name]
  end
  
  def test_change_pword_strip_input
    post '/user/edit_credentials', {current_pword: ' a   ', new_user_name: 'Clare Mac', new_email: 'clare@macadie.co.uk', new_pword: ' Qwerty90 ', reenter_pword: '   Qwerty90 '}, user_2_session
    assert_equal 302, last_response.status
    assert_equal 'Clare Mac', session[:user_name]
    assert_equal 'The following have been updated: password.', session[:message]
    
    post '/users/signin', {user_name: 'Clare Mac', pword: 'Qwerty90'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'Clare Mac', session[:user_name]
  end
  
  def test_change_pword_mismatched
    post '/user/edit_credentials', {current_pword: 'a', new_user_name: 'Clare Mac', new_email: '', new_pword: 'b', reenter_pword: 'c'}, user_2_session
    assert_equal 422, last_response.status
    assert_equal 'Clare Mac', session[:user_name]
    assert_includes last_response.body, 'The passwords do not match.'
  end
  
  def test_change_username_and_pword
    post '/user/edit_credentials', {current_pword: 'a', new_user_name: 'joe', new_email: 'clare@macadie.co.uk', new_pword: 'Qwerty90', reenter_pword: 'Qwerty90'}, user_2_session
    assert_equal 302, last_response.status
    assert_equal 'joe', session[:user_name]
    assert_equal 'The following have been updated: username, password.', session[:message]
  
    post '/users/signin', {user_name: 'joe', pword: 'Qwerty90'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'joe', session[:user_name]
  end
  
  def test_change_username_and_pword_strip
    post '/user/edit_credentials', {current_pword: 'a', new_user_name: '   joe   ', new_email: 'clare@macadie.co.uk', new_pword: ' Qwerty90', reenter_pword: '   Qwerty90 '}, user_2_session
    assert_equal 302, last_response.status
    assert_equal 'joe', session[:user_name]
    assert_equal 'The following have been updated: username, password.', session[:message]
  
    post '/users/signin', {user_name: 'joe', pword: 'Qwerty90'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'joe', session[:user_name]
  end
  
  def test_change_username_and_pword_empty
    post '/user/edit_credentials', {current_pword: 'a', new_user_name: '   joe   ', new_email: 'clare@macadie.co.uk', new_pword: '   ', reenter_pword: '   '}, user_2_session
    assert_equal 302, last_response.status
    assert_equal 'joe', session[:user_name]
    assert_equal 'The following have been updated: username.', session[:message]
  
    post '/users/signin', {user_name: 'joe', pword: 'a'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'joe', session[:user_name]
  end
  
  def test_change_user_credentials_pword_mismatched
    post '/user/edit_credentials', {current_pword: 'wrong_pword', new_user_name: 'joe', new_email: '', new_pword: 'b', reenter_pword: 'b'}, user_2_session
    assert_equal 422, last_response.status
    assert_equal 'Clare Mac', session[:user_name]
    assert_includes last_response.body, 'That is not the correct current password. Try again!'
  end
  
  def test_change_user_credentials_nothing_changed
    post '/user/edit_credentials', {current_pword: 'a', new_user_name: 'Clare Mac', new_email: 'clare@macadie.co.uk', new_pword: '', reenter_pword: ''}, user_2_session
    assert_equal 422, last_response.status
    assert_equal 'Clare Mac', session[:user_name]
    assert_includes last_response.body, 'You have not changed any of your details.'
  end

  def test_change_admin_username
    post '/user/edit_credentials', {current_pword: 'secret', new_user_name: 'Clare Mac', new_email: '', new_pword: '', reenter_pword: ''}, admin_session
    assert_equal 422, last_response.status
    assert_equal 'admin', session[:user_name]
    assert_includes last_response.body, 'Admin cannot change their username.'
  end

  def test_change_admin_pword
    post '/user/edit_credentials', {current_pword: 'secret', new_user_name: 'admin', new_email: 'admin@julianrimet.com', new_pword: 'a', reenter_pword: 'a'}, admin_session
    assert_equal 302, last_response.status
    assert_equal 'admin', session[:user_name]
    assert_equal 'The following have been updated: password.', session[:message]
  
    post '/users/signin', {user_name: 'admin', pword: 'a'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'admin', session[:user_name]
  end

  def test_change_email
    post '/user/edit_credentials', {current_pword: 'a', new_user_name: 'Clare Mac', new_email: 'new@email.com', new_pword: '', reenter_pword: ''}, user_2_session
    assert_equal 302, last_response.status
    assert_equal 'Clare Mac', session[:user_name]
    assert_equal 'new@email.com', session[:user_email]
    assert_equal 'The following have been updated: email.', session[:message]
    
    get '/'
    assert_includes last_response.body, 'Signed in as Clare Mac.'
  end

  def test_change_username_and_email
    post '/user/edit_credentials', {current_pword: 'a', new_user_name: 'joe', new_email: 'new@email.com', new_pword: '', reenter_pword: ''}, user_2_session
    assert_equal 302, last_response.status
    assert_equal 'joe', session[:user_name]
    assert_equal 'new@email.com', session[:user_email]
    assert_equal 'The following have been updated: username, email.', session[:message]
    
    get '/'
    assert_includes last_response.body, 'Signed in as joe.'
  end
  
  def test_change_username_pword_and_email
    post '/user/edit_credentials', {current_pword: 'a', new_user_name: 'joe', new_email: 'new@email.com', new_pword: 'Qwerty90', reenter_pword: 'Qwerty90'}, user_2_session
    assert_equal 302, last_response.status
    assert_equal 'joe', session[:user_name]
    assert_equal 'new@email.com', session[:user_email]
    assert_equal 'The following have been updated: username, password, email.', session[:message]
  
    post '/users/signin', {user_name: 'joe', pword: 'Qwerty90'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'joe', session[:user_name]
  end
  
  def test_change_username_pword_and_email_strip
    post '/user/edit_credentials', {current_pword: 'a', new_user_name: '   joe ', new_email: '  new@email.com ', new_pword: 'Qwerty90  ', reenter_pword: ' Qwerty90 '}, user_2_session
    assert_equal 302, last_response.status
    assert_equal 'joe', session[:user_name]
    assert_equal 'new@email.com', session[:user_email]
    assert_equal 'The following have been updated: username, password, email.', session[:message]
  
    post '/users/signin', {user_name: 'joe', pword: 'Qwerty90'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'joe', session[:user_name]
  end

  # def test_reset_pword_admin
  #   post '/users/reset_pword', {user_name: 'Clare MacAdie'}, admin_session
  #   assert_equal 302, last_response.status
  #   assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
  #   assert_equal 'The password has been reset to 'bookle' for Clare MacAdie.', session[:message]
    
  #   post '/users/signin', {user_name: 'Clare MacAdie', pword: 'bookle'}, {}
  #   assert_equal 302, last_response.status
  #   assert_equal 'Welcome!', session[:message]
  #   assert_equal 'Clare MacAdie', session[:user_name]
  # end
  
  # def test_reset_pword_not_admin
  #   post '/users/reset_pword', {user_name: 'Beth Broom'}, user_2_session
  #   assert_equal 302, last_response.status
  #   assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
  #   assert_equal 'You must be an administrator to do that.', session[:message]
  #   refute_includes last_response.body, 'The password has been reset to 'bookle' for Clare MacAdie.'
    
  #   post '/users/signin', {user_name: 'Clare MacAdie', pword: 'bookle'}, {}
  #   assert_equal 422, last_response.status
  #   assert_includes last_response.body, 'Invalid credentials'
  # end
  
  # def test_reset_pword_signed_out
  #   post '/users/reset_pword', {user_name: 'Beth Broom'}
  #   assert_equal 302, last_response.status
  #   assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
  #   assert_equal 'You must be an administrator to do that.', session[:message]
  #   refute_includes last_response.body, 'The password has been reset to 'bookle' for Clare MacAdie.'
    
  #   post '/users/signin', {user_name: 'Clare MacAdie', pword: 'bookle'}, {}
  #   assert_equal 422, last_response.status
  #   assert_includes last_response.body, 'Invalid credentials'
  # end
  
end

