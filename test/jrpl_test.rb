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
    post '/users/signin', {user_name: 'admin', password: 'secret'}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'admin', session[:user_name]
  
    get last_response['Location']
    assert_includes last_response.body, 'Signed in as admin.'
  end
  
  def test_signin_strip_input
    post '/users/signin', {user_name: '   admin  ', password: ' secret '}, {}
    assert_equal 302, last_response.status
    assert_equal 'Welcome!', session[:message]
    assert_equal 'admin', session[:user_name]
  
    get last_response['Location']
    assert_includes last_response.body, 'Signed in as admin.'
  end
  
  def test_signin_with_bad_credentials
    post '/users/signin', {user_name: 'guest', password: 'shhhh'}, {}
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
    post '/users/signup', {new_user_name: 'joe', new_email: 'joe@joe.com', new_password: 'Dfghiewo34334', reenter_password: 'Dfghiewo34334'}
    assert_equal 302, last_response.status
    assert_equal 'Your account has been created.', session[:message]
  
    get '/'
    assert_includes last_response.body, 'Signed in as joe.'
  end
  
  def test_signup_signed_out_strip_input
    post '/users/signup', {new_user_name: '   joe  ', new_email: 'joe@joe.com', new_password: ' Dfghiewo34334    ', reenter_password: '  Dfghiewo34334 '}
    assert_equal 302, last_response.status
    assert_equal 'Your account has been created.', session[:message]
  
    get '/'
    assert_includes last_response.body, 'Signed in as joe.'
  end
  
  def test_signup_signed_in
    post '/users/signup', {new_user_name: 'joe', new_email: 'joe@joe.com', new_password: 'dfghiewo34334', reenter_password: 'dfghiewo34334'}, admin_session
    assert_equal 302, last_response.status
    assert_equal 'You must be signed out to do that.', session[:message]
  end
  
  def test_signup_existing_username
    post '/users/signup', {new_user_name: 'Clare Mac', new_email: 'joe@joe.com', new_password: 'dfghiewo34334', reenter_password: 'dfghiewo34334'}
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'That username already exists.'
  end
  
  def test_signup_blank_username
    post '/users/signup', {new_user_name: '', new_email: 'joe@joe.com', new_password: 'dfghiewo34334', reenter_password: 'dfghiewo34334'}
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Username cannot be blank! Please enter a username.'
  end
  
  def test_signup_admin_username
    post '/users/signup', {new_user_name: 'admin', new_email: 'joe@joe.com', new_password: 'dfghiewo34334', reenter_password: 'dfghiewo34334'}
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Username cannot be 'admin'! Please choose a different username."
  end
  
  def test_signup_blank_password
    post '/users/signup', {new_user_name: 'joanna', new_email: 'joe@joe.com', new_password: '', reenter_password: ''}
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Password cannot be blank! Please enter a password.'
  end
  
  def test_signup_blank_username_and_password
    post '/users/signup', {new_user_name: '', new_email: 'joe@joe.com', new_password: '', reenter_password: ''}
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Username and password cannot be blank! Please enter a username and password.'
  end
  
  def test_signup_mismatched_passwords
    post '/users/signup', {new_user_name: 'joanna', new_email: 'joe@joe.com', new_password: 'dfghiewo34334', reenter_password: 'mismatched'}
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'The passwords do not match.'
  end
  
  # def test_view_administer_account_form_signed_out
  #   get '/user'
  #   assert_equal 302, last_response.status
  #   assert_includes session[:message], 'You must be signed in to do that. Sign in below or'
  # end
  
  # def test_view_administer_account_form_signed_in
  #   get '/user', {}, admin_session
  #   assert_equal 200, last_response.status
  #   assert_includes last_response.body, 'Enter new username'
  #   assert_includes last_response.body, 'Enter current password'
  #   assert_includes last_response.body, 'Enter new password'
  #   assert_includes last_response.body, 'Reenter new password'
  # end
  
  # def test_change_username
  #   post '/user/edit_login', {new_username: 'joe', current_password: 'a', new_password: '', reenter_password: ''}, user_2_session
  #   assert_equal 302, last_response.status
  #   assert_equal 'joe', session[:user_name]
  #   assert_equal 'Your username has been updated.', session[:message]
  
  #   get '/'
  #   assert_includes last_response.body, 'Signed in as joe.'
  # end
  
  # def test_change_username_strip_input
  #   post '/user/edit_login', {new_username: '   joe ', current_password: '   a ', new_password: '', reenter_password: ''}, user_2_session
  #   assert_equal 302, last_response.status
  #   assert_equal 'joe', session[:user_name]
  #   assert_equal 'Your username has been updated.', session[:message]
  
  #   get '/'
  #   assert_includes last_response.body, 'Signed in as joe.'
  # end
  
  # def test_change_username_to_blank
  #   post '/user/edit_login', {new_username: '', current_password: 'a', new_password: '', reenter_password: ''}, user_2_session
  #   assert_equal 422, last_response.status
  #   assert_equal 'Clare MacAdie', session[:user_name]
  #   assert_includes last_response.body, 'New username cannot be blank! Please enter a username.'
  # end
  
  # def test_change_username_to_admin
  #   post '/user/edit_login', {new_username: 'admin', current_password: 'a', new_password: '', reenter_password: ''}, user_2_session
  #   assert_equal 422, last_response.status
  #   assert_equal 'Clare MacAdie', session[:user_name]
  #   assert_includes last_response.body, 'New username cannot be 'admin'! Please choose a different username.'
  # end
  
  # def test_change_username_to_existing_username
  #   post '/user/edit_login', {new_username: 'Alice Allbright', current_password: 'a', new_password: '', reenter_password: ''}, user_2_session
  #   assert_equal 422, last_response.status
  #   assert_equal 'Clare MacAdie', session[:user_name]
  #   assert_includes last_response.body, 'That username already exists. Please choose a different username.'
  # end
  
  # def test_change_password
  #   post '/user/edit_login', {new_username: 'Clare MacAdie', current_password: 'a', new_password: 'Qwerty90', reenter_password: 'Qwerty90'}, user_2_session
  #   assert_equal 302, last_response.status
  #   assert_equal 'Clare MacAdie', session[:user_name]
  #   assert_equal 'Your password has been updated.', session[:message]
  
  #   post '/users/signin', {user_name: 'Clare MacAdie', password: 'Qwerty90'}, {}
  #   assert_equal 302, last_response.status
  #   assert_equal 'Welcome!', session[:message]
  #   assert_equal 'Clare MacAdie', session[:user_name]
  # end
  
  # def test_change_password_strip_input
  #   post '/user/edit_login', {new_username: 'Clare MacAdie', current_password: ' a   ', new_password: ' Qwerty90 ', reenter_password: '   Qwerty90 '}, user_2_session
  #   assert_equal 302, last_response.status
  #   assert_equal 'Clare MacAdie', session[:user_name]
  #   assert_equal 'Your password has been updated.', session[:message]
  
  #   post '/users/signin', {user_name: 'Clare MacAdie', password: 'Qwerty90'}, {}
  #   assert_equal 302, last_response.status
  #   assert_equal 'Welcome!', session[:message]
  #   assert_equal 'Clare MacAdie', session[:user_name]
  # end
  
  # def test_change_password_mismatched
  #   post '/user/edit_login', {new_username: 'Clare MacAdie', current_password: 'a', new_password: 'b', reenter_password: 'c'}, user_2_session
  #   assert_equal 422, last_response.status
  #   assert_equal 'Clare MacAdie', session[:user_name]
  #   assert_includes last_response.body, 'The passwords do not match.'
  # end
  
  # def test_change_password_no_capital
  #   post '/user/edit_login', {new_username: 'Clare MacAdie', current_password: 'a', new_password: 'qwerty90', reenter_password: 'qwerty90'}, user_2_session
  #   assert_equal 422, last_response.status
  #   assert_equal 'Clare MacAdie', session[:user_name]
  #   assert_includes last_response.body, 'Password must contain at least: 8 characters, one uppercase letter, one lowercase letter and one number.'
  # end
  
  # def test_change_password_no_number
  #   post '/user/edit_login', {new_username: 'Clare MacAdie', current_password: 'a', new_password: 'Qwertyuio', reenter_password: 'Qwertyuio'}, user_2_session
  #   assert_equal 422, last_response.status
  #   assert_equal 'Clare MacAdie', session[:user_name]
  #   assert_includes last_response.body, 'Password must contain at least: 8 characters, one uppercase letter, one lowercase letter and one number.'
  # end
  
  # def test_change_password_too_short
  #   post '/user/edit_login', {new_username: 'Clare MacAdie', current_password: 'a', new_password: 'Qwer90', reenter_password: 'Qwer90'}, user_2_session
  #   assert_equal 422, last_response.status
  #   assert_equal 'Clare MacAdie', session[:user_name]
  #   assert_includes last_response.body, 'Password must contain at least: 8 characters, one uppercase letter, one lowercase letter and one number.'
  # end
  
  # def test_change_username_and_password
  #   post '/user/edit_login', {new_username: 'joe', current_password: 'a', new_password: 'Qwerty90', reenter_password: 'Qwerty90'}, user_2_session
  #   assert_equal 302, last_response.status
  #   assert_equal 'joe', session[:user_name]
  #   assert_equal 'Your username and password have been updated.', session[:message]
  
  #   post '/users/signin', {user_name: 'joe', password: 'Qwerty90'}, {}
  #   assert_equal 302, last_response.status
  #   assert_equal 'Welcome!', session[:message]
  #   assert_equal 'joe', session[:user_name]
  # end
  
  # def test_change_user_credentials_password_mismatched
  #   post '/user/edit_login', {new_username: 'joe', current_password: 'wrong_password', new_password: 'b', reenter_password: 'b'}, user_2_session
  #   assert_equal 422, last_response.status
  #   assert_equal 'Clare MacAdie', session[:user_name]
  #   assert_includes last_response.body, 'That is not the correct current password. Try again!'
  # end

  # def test_reset_password_admin
  #   post '/users/reset_password', {user_name: 'Clare MacAdie'}, admin_session
  #   assert_equal 302, last_response.status
  #   assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
  #   assert_equal 'The password has been reset to 'bookle' for Clare MacAdie.', session[:message]
    
  #   post '/users/signin', {user_name: 'Clare MacAdie', password: 'bookle'}, {}
  #   assert_equal 302, last_response.status
  #   assert_equal 'Welcome!', session[:message]
  #   assert_equal 'Clare MacAdie', session[:user_name]
  # end
  
  # def test_reset_password_not_admin
  #   post '/users/reset_password', {user_name: 'Beth Broom'}, user_2_session
  #   assert_equal 302, last_response.status
  #   assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
  #   assert_equal 'You must be an administrator to do that.', session[:message]
  #   refute_includes last_response.body, 'The password has been reset to 'bookle' for Clare MacAdie.'
    
  #   post '/users/signin', {user_name: 'Clare MacAdie', password: 'bookle'}, {}
  #   assert_equal 422, last_response.status
  #   assert_includes last_response.body, 'Invalid credentials'
  # end
  
  # def test_reset_password_signed_out
  #   post '/users/reset_password', {user_name: 'Beth Broom'}
  #   assert_equal 302, last_response.status
  #   assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
  #   assert_equal 'You must be an administrator to do that.', session[:message]
  #   refute_includes last_response.body, 'The password has been reset to 'bookle' for Clare MacAdie.'
    
  #   post '/users/signin', {user_name: 'Clare MacAdie', password: 'bookle'}, {}
  #   assert_equal 422, last_response.status
  #   assert_includes last_response.body, 'Invalid credentials'
  # end
  
end

