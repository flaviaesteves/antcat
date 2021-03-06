crumb :antcat do
  link "AntCat"
end

crumb :about do
  link "About", page_path('about')
  parent :antcat
end

crumb :users do
  link "Users", users_path
  parent :antcat
end

crumb :sign_up do
  link "Sign Up"
  parent :antcat
end

crumb :login do
  link "Login"
  parent :antcat
end

crumb :forgot_password do
  link "Forgot Password"
  parent :antcat
end

crumb :invitee_create_account do
  link "Create Account"
  parent :antcat
end

crumb :change_password do
  link "Change Password"
  parent :antcat
end
