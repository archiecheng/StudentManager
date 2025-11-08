require "sinatra"
require "sinatra/activerecord"
require "securerandom"
require_relative "./models/student"  # <- load student model
require_relative "./models/user"
enable :sessions
set :database_file, "config/database.yml"
set :sessions,
    key: "sinatra.session",
    httponly: true,
    same_site: :lax,
    secure: false,  # 如果你用 HTTPS，可以改成 true
    secret: ENV.fetch("SESSION_SECRET") { SecureRandom.hex(64) }  # 128 hex 字符=64字节

helpers do
  def flash(type = :info)
    session.delete(:flash)&.yield_self{|h| h[type]}
  end
  def set_flash(type, msg)
    session[:flash] = {type => msg}
  end
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  def require_login!
    return if logged_in?
    set_flash :error, "Please login first."
    redirect "/login"
  end
end

get "/" do
  if logged_in?
    redirect "/students"
  else
    redirect "/login"
  end
end

# database connection test
get "/dbtest" do
  "Students count: #{Student.count}"
end

# ---------- Students CRUD ----------

before "/students" do
  require_login!
end

# student list page
get "/students" do
  @students = Student.order(:created_at)
  erb(:students_index)
end

# new form page
get "/students/new" do
  @student = Student.new
  erb(:students_new)
end

post "/students" do
  p params
  @student = Student.new(name:params[:name], age:params[:age])
  if @student.save
    set_flash :success, "Student created successfully."
    redirect "/students"
  else
    @errors = @student.errors.full_messages
    set_flash :error, "Failed to create student."
    erb(:students_new)
  end
end

# edit form
get "/students/:id/edit" do
  @student = Student.find(params[:id])
  erb(:students_edit)
end

# submit form
post "/students/:id" do
  @student = Student.find(params[:id])
  if @student.update(name:params[:name], age:params[:age])
    set_flash :success, "Student updated successfully."
    redirect "/students"
  else
    @errors = @student.errors.full_messages
    set_flash :error, "Failed to update student."
    erb(:students_edit)
  end
end

# delete student
post "/students/:id/delete" do
  student = Student.find_by(id: params[:id]) or halt 404, "Student not found"
  student.destroy
  set_flash :success, "Record deleted."
  redirect "/students"
end

# show single student
get "/students/:id" do
  @student = Student.find_by(id: params[:id]) or halt 404, "Student not found"
  erb(:students_show)
end

# ---------- Auth ----------

# Signup
get "/signup" do
  erb :signup
end

post "/signup" do
  user = User.new(email: params[:email], password: params[:password], password_confirmation: params[:password_confirmation])
  if user.save
    set_flash :success, "Signup successfully. Please login."
    redirect "/login"
  else
    set_flash :error, user.errors.full_messages.join(", ")
    erb :signup
  end
end

# Login
get "/login" do
  erb :login
end

post "/login" do
  user = User.find_by(email: params[:email])
  if user && user.authenticate(params[:password])
    session[:user_id] = user.id
    set_flash :success, "Login successfully"
    redirect "/students"
  else
    set_flash :error, "Invalid email or password"
    erb :login
  end
end

# Logout
post "/logout" do
  session.delete(:user_id)
  set_flash :success, "Logout successfully"
  redirect "/login"
end

not_found do
  status 404
  erb :not_found
end

error do
  status 500
  @error = env["sinatra.error"]
  erb :internal_error
end
