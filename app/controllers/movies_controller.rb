# coding: utf-8

class MoviesController < ApplicationController

  before_filter :authenticate_user!
  # GET /movies
  # GET /movies.json
  def index 
    @movies_file_list = Movie.find(:all, :limit => 10, :order => "created_at DESC")

	stat = Sys::Filesystem.stat('/home/samba')
	@total = (stat.blocks * stat.block_size).to_f / 1024 / 1024 / 1024
	@available = (stat.blocks_available * stat.block_size).to_f / 1024 / 1024 / 1024
	@percentage = ((@total - @available) / @total * 100).to_i

	# Play Ranking
	now = Time.now
	if params[:rank_type] == "lm"
	  @rank_title = "先月"
	  time_where = " WHERE pl.updated_at >= '" + (Date::new(now.year, now.month, 1) << 1).to_s + " 00:00:00'"
	  time_where += " AND pl.updated_at < '" + Time.now.strftime("%Y-%m-01 00:00:00") + "'"
	  
	  sql = "SELECT mv.id AS id,title,count(*) AS count,mv.syobocalid AS syobocalid FROM `play_logs` AS pl"
	  sql += " inner join movies AS mv on pl.movie_id = mv.id"
	  sql += time_where
	  sql += " GROUP BY title ORDER BY count DESC LIMIT 0, 20"
	elsif params[:rank_type] == "cm"
	  @rank_title = "今月"
	  time_where = " WHERE pl.updated_at >= '" + Time.now.strftime("%Y-%m-01 00:00:00") + "'"

	  sql = "SELECT mv.id AS id,title,count(*) AS count,mv.syobocalid AS syobocalid FROM `play_logs` AS pl"
	  sql += " inner join movies AS mv on pl.movie_id = mv.id"
	  sql += time_where
	  sql += " GROUP BY title ORDER BY count DESC LIMIT 0, 20"
    else
	  @rank_title = "全期間"
	  time_where = " WHERE 1"
	  
	  sql = "SELECT mv.id AS id,title,count(*) AS count,mv.syobocalid AS syobocalid FROM `play_logs` AS pl"
	  sql += " inner join movies AS mv on pl.movie_id = mv.id GROUP BY title ORDER BY count DESC LIMIT 0, 20"
	end
	@play_ranking = PlayLog.find_by_sql( sql )

    # Play Ranking for user
	@user_log = {}
	@play_ranking.each do | elem |

	  sql = "SELECT * FROM `play_logs` AS pl inner join movies AS mv on pl.movie_id = mv.id"
	  sql += time_where
	  sql += " AND mv.syobocalid = '" + elem.syobocalid + "' ORDER BY user_id ASC"

  	  @play_ranking_for_user = PlayLog.find_by_sql( sql )
	  tmp_userid = nil
	  tmp_count = 0
	  @user_log[elem.syobocalid] = {} 
	  @play_ranking_for_user.each do | user |
	    if( tmp_userid.nil?() )
		  tmp_count  = 0
		  tmp_userid = user.user_id
		elsif( tmp_userid != user.user_id )
          @user_log[elem.syobocalid][tmp_userid] = tmp_count
		  tmp_userid = user.user_id
		  tmp_count  = 0
		end
		tmp_count += 1
	  end
      @user_log[elem.syobocalid][tmp_userid] = tmp_count

	end

	@user_color = {
	                1 => "blue",
					2 => "olive",
					3 => "lime",
					4 => "purple",
					5 => "maroon",
					6 => "teal",
					7 => "black"
					}

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @movies }
    end
  end

#  def list
#    @movies = Movie.find(:all, :order => "number ASC").group_by{|movie|movie.syobocalid}
#    respond_to do |format|
#      format.html # index.html.erb
#      format.json { render json: @movies }
#    end
#  end

  def list

    if params[:offset].nil? then
      @offset = 0
	else
      @offset = params[:offset].to_i
	end

    @listtype = params[:type]
	if @listtype.nil? then
	  @listtype = "file"
	else
	  @listtype = params[:type]
	end

	if @listtype == "title" then
      count = @offset * 50
	  @count = Movie.find(:all, :group => "syobocalid", :order => "created_at DESC")
	  @count = @count.length
	  if count > @count then
	    count = @count - 49 
		@offset = (@count / 50).to_i
		if @count % 50 == 0 then
		  @offset -= 1
	    end
	  end
	  @movies = Movie.find(:all, :offset => count,:limit => 50, :group => "syobocalid", :order => "created_at DESC")
 
	#デフォルトはtype=file
	else
	  count = @offset * 50
	  @count = Movie.find(:first, :select => "count(*) as count")
	  @count = @count.count
	  if count > @count then
	    count = @count - 49 
		@offset = (@count / 50).to_i
		if @count % 50 == 0 then
		  @offset -= 1
	    end
	  end
	  @movies = Movie.find(:all, :offset => count,:limit => 50, :order => "created_at DESC")
	end

	if @count % 50 == 0 then
	  @count = (@count / 50).to_i
	else
	  @count = (@count / 50).to_i + 1
	end

    if @offset - 5 <= 0 then
      @st_count = 1
    else
      @st_count = @offset - 5
	end

	if @offset + 5 >= (@count -1 ) then
	  @fn_count = @count - 2
	else
	  @fn_count = @offset + 5
	end

	if @st_count == 1 then
	  @fn_count += 5 - @offset + 1
	  if @fn_count >= @count - 1 then
	    @fn_count = @count -2
	  end
	end

	if @fn_count == @count then
	  @st_count -=  5 - (@count - 1 - @offset) + 1
	  if @st_count < 1 then
	    @st_count = 1
	  end
	end

    searchlist_rec = Movie.find(:all, :group => "syobocalid", :order => "title ASC")
	@searchlist = ""
	searchlist_rec.each do | elem |
	  @searchlist += '"'+elem.title+'",'
	end
	@searchlist += '""' 

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @movies }
    end
  end


  def search
    @searchtxt = params[:searchtxt]

    cond = [ "title LIKE ?", "%#{@searchtxt}%" ]
	@movies = Movie.find(:all, :group=> "syobocalid", :conditions => cond,
						 :order => "title ASC")
    
	searchlist_rec = Movie.find(:all, :group => "syobocalid", :order => "title ASC")
	@searchlist = ""
	searchlist_rec.each do | elem |
	  @searchlist += '"'+elem.title+'",'
	end
	@searchlist += '""' 

	respond_to do |format|
      format.html # search.html.erb
      format.json { render json: @movies }
    end

  end

  # GET /movies
  # GET /movies.json
  def control 
    @movies = Movie.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @movies }
    end
  end

  # GET /movies/1
  # GET /movies/1.json
  def show
    @movie = Movie.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @movie }
    end
  end

  # GET /movies/new
  # GET /movies/new.json
  def new
    @movie = Movie.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @movie }
    end
  end

  # GET /movies/1/edit
  def edit
    @movie = Movie.find(params[:id])
  end

  # POST /movies
  # POST /movies.json
  def create
    @movie = Movie.new(params[:movie])

    respond_to do |format|
      if @movie.save
        format.html { redirect_to @movie, notice: 'Movie was successfully created.' }
        format.json { render json: @movie, status: :created, location: @movie }
      else
        format.html { render action: "new" }
        format.json { render json: @movie.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /movies/1
  # PUT /movies/1.json
  def update
    @movie = Movie.find(params[:id])

    respond_to do |format|
      if @movie.update_attributes(params[:movie])
        format.html { redirect_to @movie, notice: 'Movie was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @movie.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /movies/1
  # DELETE /movies/1.json
  def destroy
    @movie = Movie.find(params[:id])
    @movie.destroy

    respond_to do |format|
      format.html { redirect_to movies_url }
      format.json { head :no_content }
    end
  end

  def player
    if params[:id].blank? == false
      @movie_org = Movie.find(params[:id])
	  @title = @movie_org.title
	  @number = @movie_org.number
	  @id = params[:id].to_i
	elsif params[:syobocalid].blank? == false
	  input_syobocalid = params[:syobocalid]
	  #cond = ["syobocalid = ? AND number IS NOT NULL", input_syobocalid]
	  cond = ["syobocalid = ?", input_syobocalid]
	  @movie_org = Movie.find(:first, :conditions => cond, :order => "number ASC")
	  if @movie_org.nil?
	    raise
	  end
	  @title = @movie_org.title
	  @number = @movie_org.number
	  @id = @movie_org.id
	else
	  raise
	end

	@movies = Movie.find(:all, :conditions => ["syobocalid = ? AND number IS NOT NULL", @movie_org.syobocalid], :group => "number", :order => "number ASC")
	@movies2 = Movie.find(:all, :conditions => ["syobocalid = ? AND number IS NULL", @movie_org.syobocalid], :order => "number ASC")

	@movies << @movies2
	@movies.flatten!

	PlayLog.store_log( current_user.id, @id )
  end

  def play_log
    result  = []
    userid  = current_user.id
	movieid = params[:movieid]

	unless( movieid.blank?() )
	  PlayLog.store_log( userid, movieid.to_i )
	end

	render :json => result
  end
end
