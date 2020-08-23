#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require "sqlite3"

def is_phone_exists? db, phone
	db.execute('select * from Users where Phone=?', [phone]).length > 0
end 

def is_master_exists? db, name
	db.execute('select * from Masters where Master=?', [name]).length > 0
end     

def seed_db db, masters
	
	masters.each do |master|
		if !is_master_exists? db, master
			db.execute 'insert into Masters (Master) values (?)', [master]
		end	
	end		
end


def get_db
	db = SQLite3::Database.new 'database.db'
	db.results_as_hash = true
	return db
end

before do 
	db = get_db
	@masters = db.execute 'select * from Masters'

end


configure do
	db = get_db
	db.execute "CREATE TABLE IF NOT EXISTS 
	'Users' 
	(
		'id' INTEGER PRIMARY KEY AUTOINCREMENT,
		'User' TEXT, 
		'Phone' TEXT, 
		'Datestamp' TEXT, 
		'Master' TEXT, 
		'Color' TEXT
	)"
	db.execute "CREATE TABLE IF NOT EXISTS 
	'Contacts' 
	(
	'id' INTEGER PRIMARY KEY AUTOINCREMENT,
	'User' TEXT, 
	'Email' TEXT, 
	'Coment' TEXT
	)"
	db.execute "CREATE TABLE IF NOT EXISTS 
	'Masters' 
	(
	'id' INTEGER PRIMARY KEY AUTOINCREMENT,
	'Master' TEXT
	)"
seed_db db, ['Сергей', 'Изабелла', 'Елена', 'Стас', 'Александр']	
end



get '/' do
	erb "Hello! <a href=\"https://github.com/bootstrap-ruby/sinatra-bootstrap\">Original</a> pattern has been modified for <a href=\"http://rubyschool.us/\">Ruby School</a>"
end

get '/about' do
	@message = "О нас"
	erb :about
end
get '/demo' do
	erb :demo
end	

get '/contacts' do
	@message = "Наши контакты"
	erb :contacts
end

get '/visits' do
	db = get_db

	@results = db.execute 'select * from Users order by id desc' 
	@message = "Запись на сеанс к стилисту"
	erb :visits
end
get '/admins' do
	
	erb :admins
end
get '/admin_panel' do
	erb :admin_panel 
end

post '/visits' do
require "sqlite3"
 	db = get_db
	@username = params[:username]
	@phone = params[:phone]
	@datetime = params[:datetime]
	
	@master = params[:master]
    @color = params[:color]
    @results = db.execute 'select * from Users order by id desc' 
=begin
	if @username == "" or @phone == "" or @date == "" or @time == "" or @color == ""
		@error = "Вы не заполнили все графы"

		erb :visits
	else
	    @message = "#{@username.capitalize} вы записаны на #{@date} время #{@time}, Ваш мастер #{@master}"
	    @title = "Спасибо за запись, назад на главную страницу"
	    f = File.open './public/user.txt', 'a'
	    f.write "Имя: #{@username}, Тел.: #{@phone}, Мастер: #{@master}, Цвет волос: #{@color}, Дата и время: #{@date} #{@time}\n"
	    f.close

		@button = "НАЗАД НА ГЛАВНУЮ"
		erb :message
	end
=end
	# хеш

	hh = {:username => 'Введите имя', 
		:phone => 'Введите номер телефона', 
		:datetime => 'Укажите дату'
	}
# для каждой пары ключ-значение
=begin		
	hh.each do |key, value|
		#если параметр пуст
		if params[key] == ''
			#переменной error присвоить value из хэша hh 
			# (а value из хэша hh это сообщение об ошибке)
			# т.е переменной error присвоить сообщение об ошибке
			@error = hh[key]
			#Вернуть прдставление visits
			return erb :visits

		end


	end
=end
	@error = hh.select {|key,_| params[key] == ""}.values.join(", ")
	

	if @error != ''
		return erb :visits	
	end
	if is_phone_exists? db, @phone
		@error = 'Указанный вами номер есть в базе записавшихся'
		return erb :visits		
	end	
	@apply = "#{@username.capitalize} вы записаны на #{@datetime} , Ваш мастер #{@master}"
    @title = "Спасибо за запись, назад на главную страницу"
    db = get_db
    db.execute 'INSERT INTO 
    Users 
    (
	    User, 
	    Phone, 
	    Datestamp,  
	    Master, 
	    Color
    ) 
    values (?, ?, ?, ?, ?)', [@username, @phone, @datetime, @master, @color]
    db.close
	@button = "НАЗАД НА ГЛАВНУЮ"

	erb :message
		     
end
post '/contacts' do	
require "sqlite3"
db = get_db 	
	@user = params[:user]
	@email = params[:email]
	@coment = params[:coment]

	hh = {:user => 'Введите имя',
		:email => 'Введите Email',
		:coment => 'Напишите что-нибудь'		
	}
	@error = hh.select {|key,_| params[key] == ""}.values.join(", ")

	if @error != ''
		return erb :contacts	
	end	
	@apply = "#{@user} мы раccмотрим Ваше сообщение"
	db.execute 'INSERT INTO Contacts (User, Email, Coment) values (?, ?, ?)', [@user, @email, @coment]
	db.close

	
	@button = "НАЗАД НА ГЛАВНУЮ"
	erb :message
end
post '/admins' do
  @login = params[:username]
  @password = params[:password]
  
  if @login == "opr" && @password == "opr"
  	db = get_db

	@results = db.execute 'select * from Users order by id desc'
    
    erb :showuser
  elsif @login == "admin" && @password == "admin"
  	redirect '/admin_panel'
  	
  elsif @login == "" or @password == ""
    @error = 'Все графы должны содержать символы'
    erb :admins
  else
    @error = 'Вы ввели неверный пароль'
    erb :admins
    end
end
post '/admin_panel' do
@master = params[:master]
db = get_db
	if @master == ""
		@error = "Вы не ввели имя"
	erb :admin_panel		
	
	elsif is_master_exists? db, @master
		@error = "Мастер есть с таким именем"
		erb :admin_panel	
	elsif !is_master_exists? db, @master
	
	    @apply = "#{@master} был добавлен в мастера"
		db.execute 'INSERT INTO Masters (Master) values (?)', [@master]
		db.close
		erb :admin_panel
	end
	
    
end	

