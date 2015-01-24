class PlayLog < ActiveRecord::Base

  def self.store_log( userid, movieid )
    current_timestamp = Time.now()
	min5ago_timestamp = current_timestamp - 300

	cond = ["user_id = ? AND updated_at > ?", userid, min5ago_timestamp.strftime("%Y-%m-%d %H:%M:%S")]
    rec = PlayLog.find( :first, :conditions => cond )

	if( rec.nil?() )
	  rec = PlayLog.new()
	end

	rec.movie_id = movieid
	rec.user_id = userid
	rec.save!()
  end

end
