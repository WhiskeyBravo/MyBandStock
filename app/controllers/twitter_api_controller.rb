class TwitterApiController < ApplicationController
	protect_from_forgery :only => [:create, :update, :band_create, :post_retweet]
	before_filter :authenticated?, :except => [:index, :band_index, :show, :mentions, :favorites, :error, :retweet, :quick_register, :quick_finalize] # Authentication in retweet is done manually
	before_filter :user_part_of_or_admin_of_a_band?, :only => [:update, :band_create]
  skip_filter :update_last_location, :only => [:create_session, :finalize, :deauth, :retweet, :post_retweet, :create, :band_create, :error, :quick_register, :quick_finalize]


  def quick_register
    begin
  		oauth = Twitter::OAuth.new(TWITTERAPI_KEY, TWITTERAPI_SECRET_KEY)
  		oauth_callback_url = ((defined? SITE_URL) ? SITE_URL : 'http://mybandstock.com' ) +'/twitter/quick_finalize'
  		oauth.set_callback_url(oauth_callback_url)
  		request_token = oauth.request_token			
  		access_token = request_token.token
  		access_secret = request_token.secret
  		auth_url = request_token.authorize_url
  		session['rtoken_quick'] = access_token
  		session['rsecret_quick'] = access_secret		
#  		redirect_to 'http://'+auth_url
      redirect_to auth_url
    rescue
      flash[:error] = 'Sorry, Twitter is being unresponsive at the moment.'
      redirect_to :controller => 'users', :action => 'register_with_twitter'
      session['rtoken_quick'] = session['rsecret_quick'] = nil
      return false      
    end
  end
  
  def quick_finalize
    begin
			unless params[:oauth_verifier]
				flash[:error] = 'Could not verify twitter oauth.'			
        session['rtoken_quick'] = session['rsecret_quick'] = nil									
				redirect_to :controller => 'users', :action => 'register_with_twitter'
		    return false
			end
			unless session['rtoken_quick'].nil? || session['rsecret_quick'].nil?
  			user_oauth.authorize_from_request(session['rtoken_quick'], session['rsecret_quick'], params[:oauth_verifier])	
				profile = Twitter::Base.new(user_oauth).verify_credentials				
	
				#see if twitter account already exists
				existing_twitter = TwitterUser.where(:twitter_id => profile.id).first
	
				if existing_twitter				
					twitter_user = existing_twitter
					if twitter_user.oauth_access_token.blank? || twitter_user.oauth_access_secret.blank?
						twitter_user.oauth_access_token = user_oauth.access_token.token
						twitter_user.oauth_access_secret = user_oauth.access_token.secret
						twitter_user.save
					end
				else
					unless twitter_user = TwitterUser.create(:name => profile.name, :user_name => profile.screen_name, :twitter_id => profile.id, :oauth_access_token => user_oauth.access_token.token, :oauth_access_secret => user_oauth.access_token.secret)					
						flash[:error] = 'Could not create Twitter user.'
				    session['rtoken_quick'] = session['rsecret_quick'] = nil									
						redirect_to :controller => 'users', :action => 'register_with_twitter'
  			    return false
					end
				end				
									
				if twitter_user.users.count > 0
				  flash[:error] = 'This twitter account is currently tied to another MyBandStock account.  It can\'t be tied to more than one account at a time.'
				  session['rtoken_quick'] = session['rsecret_quick'] = nil			
			    redirect_to :controller => 'users', :action => 'register_with_twitter'
			    return false
			  end
				  				
				session[:quick_registration_twitter_user_id] = twitter_user.id					

			else			
				flash[:error] = 'Could not find Twitter request token or secret.'
				session['rtoken_quick'] = session['rsecret_quick'] = nil			
		    redirect_to :controller => 'users', :action => 'register_with_twitter'
		    return false
			end

			session['rtoken_quick'] = session['rsecret_quick'] = nil			
	    redirect_to :controller => 'users', :action => 'new'
	    return true
		rescue
    	flash[:error] = 'Sorry, Twitter is being unresponsive at the moment.'
			session['rtoken'] = session['rsecret'] = session[:quick_registration_twitter_user_id] = nil
    	redirect_to :controller => 'users', :action => 'register_with_twitter'
			return false
    end
  end

	def create_session
		begin
			@user = User.find(session['user_id'])			
#			redirect = session[:last_clean_url]
=begin
			
			if params[:redirect_from_twitter]
				redirect = url_for(params[:redirect_from_twitter])
				puts 'REDIRECT TO: '+redirect
			end
=end			
			
			if @user.bands.count && params[:auth_band_id]
				if @user.has_band_admin(params[:auth_band_id]) || @user.is_member_of_band(params[:auth_band_id])
					if @band = Band.find(params[:auth_band_id])
						session['band_id_for_twitter'] = params[:auth_band_id]
						redirect = url_for(:controller => 'social_networks', :action => 'index', :band_short_name => @band.short_name)
					else
						flash[:error] = 'Could not find band with given ID.'
						session['band_id_for_twitter'] = nil
						redirect_to root_url						
						return false
					end
				else
						flash[:error] = 'You are not authorized to make changes for this band.  You need to be a band admin or member to authorize their Twitter account with our service.'
						session['band_id_for_twitter'] = nil					
						redirect_to root_url
						return false
				end
			else
				session['band_id_for_twitter'] = nil
				if params[:redirect_from_twitter]
					redirect = url_for(params[:redirect_from_twitter])
				else
					redirect = root_url
				end
			end
			
			oauth = Twitter::OAuth.new(TWITTERAPI_KEY, TWITTERAPI_SECRET_KEY)
			oauth_callback_url = ((defined? SITE_URL) ? SITE_URL : 'http://mybandstock.com' ) +
			                     '/twitter/finalize/?'+
			                     ( (params[:from_band_profile]) ? 'from_band_profile=true&' : '' )+
			                     'redirect='+redirect
			oauth.set_callback_url(oauth_callback_url)
			request_token = oauth.request_token			
			access_token = request_token.token
			access_secret = request_token.secret
			auth_url = request_token.authorize_url
			session['rtoken'] = access_token
			session['rsecret'] = access_secret		
#			puts 'TEST AUTH URL'+auth_url.to_s
#			redirect_to 'http://'+auth_url
      redirect_to auth_url
    rescue
      flash[:error] = 'Sorry, Twitter is being unresponsive at the moment.'
      redirect_to root_url
      session['rtoken'] = session['rsecret'] = nil
      return false
    end   
	end
	
	
	def finalize
		error = false
		begin
			unless params[:oauth_verifier]
				flash[:error] = 'Could not verify twitter oauth.'			
				error = true
			end
			unless session['rtoken'].nil? || session['rsecret'].nil?
				if session['band_id_for_twitter']
					band_oauth.authorize_from_request(session['rtoken'], session['rsecret'], params[:oauth_verifier])
					profile = Twitter::Base.new(band_oauth).verify_credentials
					@band = Band.find(session['band_id_for_twitter'])
					
					#see if twitter account already exists
					existing_twitter = TwitterUser.where(:twitter_id => profile.id).first
					
					if existing_twitter
						twitter_user = existing_twitter
						if twitter_user.oauth_access_token.blank? || twitter_user.oauth_access_secret.blank?
						  twitter_user.oauth_access_token = band_oauth.access_token.token
						  twitter_user.oauth_access_secret = band_oauth.access_token.secret
						  twitter_user.save
					  end
					else
						unless twitter_user = TwitterUser.create(:name => profile.name, :user_name => profile.screen_name, :twitter_id => profile.id, :oauth_access_token => band_oauth.access_token.token, :oauth_access_secret => band_oauth.access_token.secret)
							flash[:error] = 'Could not create Twitter user.'
							error = true							
						end
					end				
				
					@band.twitter_user_id = twitter_user.id
					unless @band.save
						flash[:error] = 'Could not update band database with Twitter keys.'
						error = true
					end								
				else
					user_oauth.authorize_from_request(session['rtoken'], session['rsecret'], params[:oauth_verifier])
					profile = Twitter::Base.new(user_oauth).verify_credentials				
					@user = User.find(session['user_id'])
	
					#see if twitter account already exists
					existing_twitter = TwitterUser.where(:twitter_id => profile.id).first
	
					if existing_twitter				
						twitter_user = existing_twitter
						if twitter_user.oauth_access_token.blank? || twitter_user.oauth_access_secret.blank?
						  twitter_user.oauth_access_token = user_oauth.access_token.token
						  twitter_user.oauth_access_secret = user_oauth.access_token.secret
						  twitter_user.save
					  end
					else
						unless twitter_user = TwitterUser.create(:name => profile.name, :user_name => profile.screen_name, :twitter_id => profile.id, :oauth_access_token => user_oauth.access_token.token, :oauth_access_secret => user_oauth.access_token.secret)					
							flash[:error] = 'Could not create Twitter user.'
							error = true
						end
					end				
									
					if twitter_user.users.count > 0
				    flash[:error] = 'This twitter account is currently tied to another MyBandStock account.  It can\'t be tied to more than one account at a time.'
				    session['rtoken'] = session['rsecret'] = session['band_id_for_twitter'] = nil			
				    redirect_to :controller => 'users', :action => 'edit', :id => @user.id
				    return false
			    end
				  				
									
					@user.twitter_user_id = twitter_user.id
					unless @user.save					  
						flash[:error] = 'Could not update user database with Twitter keys.'
						error = true
					else
					  @user.reward_tweet_bandstock_retroactively
					end					
				end	
			else			
				flash[:error] = 'Could not find Twitter request token or secret.'
				error = true
			end
			if error
				session['rtoken'] = session['rsecret'] = session['band_id_for_twitter'] = nil			
				redirect_to root_url
				return false
			end							
			if params[:from_band_profile]
				# The RT link from the band profiles can sometimes result in redirecting the user to authorize with Twitter.
				# If that is the case, then when he returns back to the page, the RT lightbox should automatically and violently unleash itself.
				# So band#show will see this session variable, and act accordingly.
				session[:user_just_authorized_with_twitter] = true
		  end
			if params[:redirect]
				path = params[:redirect]
				params.delete(:redirect)
				params.delete(:from_band_profile)
				params.delete(:oauth_verifier)
				params.delete(:oauth_token)
				params.delete(:action)
				params.delete(:controller)
				paramsarr = params.to_a
				if params.count > 0
					path = path.to_s + '&' + paramsarr.collect{ |a| a.join('=')}.join('&')
				else
					path = path.to_s
				end
				# send all params that came  with the redirect address
				redirect_to path
			else
				redirect_to root_url
			end
			session['rtoken'] = session['rsecret'] = session['band_id_for_twitter'] = nil						
		rescue
			session['rtoken'] = session['rsecret'] = session['band_id_for_twitter'] = nil
    	flash[:error] = 'Sorry, Twitter is being unresponsive at the moment.'
    	redirect_to root_url
			return false
    end
	end


	def deauth
		if @user = User.find(session['user_id'])						
			if @user.bands.count && params[:deauth_band_id]
				if @user.has_band_admin(params[:deauth_band_id]) || @user.is_member_of_band(params[:deauth_band_id]) || @user.is_site_admin
					if @band = Band.find(params[:deauth_band_id])
						#found band and have access
						@band.twitter_user_id = nil
						if @band.save
							redirect_to :controller => 'bands', :action => 'edit', :id => @band.id
						else
							flash[:error] = 'Could not save changes. Please try again.'
							redirect_to :controller => 'bands', :action => 'edit', :id => @band.id
							return false						
						end
					else
						flash[:error] = 'Could not find band with given ID.'
						redirect_to root_url						
						return false
					end
				else
						flash[:error] = 'You are not authorized to make changes for this band.  You need to be a band admin or member to deauthorize their Twitter account with our service.'
						redirect_to root_url
						return false
				end
			else
				#deauth user
				@user.twitter_user_id = nil
				if @user.save
					redirect_to :controller => 'users', :action => 'edit', :id => @user.id
				else
					flash[:error] = 'Could not save changes. Please try again.'
					redirect_to :controller => 'users', :action => 'edit', :id => @user.id
					return false										
				end
			end
		else
			flash[:error] = 'Could not find user.'
			redirect_to root_url
			return false		
		end
		
	end

  def update

  end

	def retweet
		session[:twitter_followers] = nil
		session[:original_tweet_id] = nil
    unless session[:auth_success] == true
      if params[:lightbox].nil?
        update_last_location
        redirect_to :controller => 'login', :action => 'user'
      else
        @external = true
        @login_only = true  # Tell the login view to only show the login form
        update_last_location
        redirect_to :controller => 'login', :action => 'user', :lightbox => 'true', :login_only => 'true'
      end
      return false
    end

		error = false
		needtoauth = false
		use_latest_status = (params[:latest] && params[:latest] != '') ? params[:latest] : nil
		# When latest = true, the band's current status is tweeted, rather than the given tweet_id
		
			if @retweeter = User.find(session[:user_id]).twitter_user 
			  if @retweeter.oauth_access_token && @retweeter.oauth_access_secret
  				if (params[:tweet_id] || use_latest_status) && params[:band_id]
  					tweetclient = client(false, false, nil)
  					@band = Band.find(params[:band_id])
  					band_twitter_username = @band.twitter_username || ((@band.twitter_user) ? @band.twitter_user.user_name : nil)
  					@tweeter = (use_latest_status && band_twitter_username) ? Twitter.user(band_twitter_username) : tweetclient.status(params[:tweet_id]).user
  					@tweet = if use_latest_status
  					           @tweeter.status.text
  					         else
  					           tweetclient.status(params[:tweet_id]).text              
  					         end
  					         
  					if use_latest_status
  					  session[:original_tweet_id] = @tweeter.status.id              
					  else
              session[:original_tweet_id] = tweetclient.status(params[:tweet_id]).id					           
  				  end
  					         
  					if @band && @tweeter
  						if  (
  						      use_latest_status ||
    						    (@band.twitter_user && @band.twitter_user.twitter_id == @tweeter.id) ||
  	  					    does_tweet_belong_to_band(params[:hash_identifier], params[:tweet_id], @band)
  	  					  )
  							@retweeter_info = tweetclient.verify_credentials
  							session[:twitter_followers] = @retweeter_info.followers_count

  							#all good to retweet
  							linkback_url = ((defined?(SITE_URL)) ? SITE_URL : 'http://mybandstock.com') + '/' + @band.short_name
  							@retweet = @tweet
  							@endtags = generate_endtag(@tweeter.screen_name, linkback_url)
  							@msg = ''
  							@ellipsis = '...'
							
  							endtaglen = @endtags.to_s.length
  							tweetlen = @retweet.to_s.length
							
  							if (endtaglen + tweetlen) <= TWEET_MAX_LENGTH
  								@msg = @retweet + @endtags
  							else
  								cutlen = TWEET_MAX_LENGTH - endtaglen - @ellipsis.length
  								@msg = @retweet[0,cutlen]+@ellipsis+@endtags
  							end				
  						else
  							flash[:error] = 'The band ID and tweeting user didn\'t match up.'			
  							error = true
  						end
  					else
  						flash[:error] = 'Couldn\'t find the tweet posting user.'
  						error = true
  					end		
  				else
  					flash[:error] = 'Cound\'t get the parameters to post a re-tweet.'
  					error = true
  				end
  			else
  				error = true
  				needtoauth = true  			  
			  end
			else
				error = true
				needtoauth = true
			end
#		rescue
#			flash[:error] = 'Sorry, Twitter is being unresponsive at the moment.'
#			error = true
#		end
	
		if error
			if needtoauth
			  if params[:from_band_profile]
			    redirect_url = params[:from_band_profile]
	  	  else
  				redirect_url = url_for() +
	  			              '?band_id='+params[:band_id].to_s +
	  			              '&tweet_id='+params[:tweet_id].to_s +
	  			              '&latest=' + use_latest_status.to_s
	  	  end
				logger.info "Telling Twitter to redirect to #{ redirect_url }"
				redirect_to :action => 'create_session',
				            :lightbox => params[:lightbox],
				            :from_band_profile => ( (params[:from_band_profile]) ? 'true' : nil ),
				            :redirect_from_twitter => redirect_url
				return false
			else
				if request.xhr? || params[:lightbox]
				  render :error, :layout => 'lightbox'
				else
	  			redirect_to :action => 'error', :lightbox => params[:lightbox]
  			end
				return false
			end
		end

		if request.xhr?
		  render :layout => false
		elsif params[:lightbox]
			render :layout => 'lightbox'
		end
		
	end
	
	def error
		@showerror	= false
		unless params[:lightbox].nil?
			@showerror = true
      # If our request tells us not to display layout (in a lightbox, for instance)
      render :layout => 'lightbox'
      return
    end
    
		if request.xhr? || params[:lightbox]
			render :layout => false
		end    
	end
	
	def success
  # Here we award shares if the user has not posted a RT within the past 24 hours.
  #
    @shares = params[:shares_awarded]

		if params[:band_id]
			@band = Band.find(params[:band_id])
			@user = User.find(session[:user_id])
			if !@band.nil? && !@user.nil?
			  @success = true
=begin
			  num_tweets_in_past_day = ShareLedgerEntry.where(
			                                             :description => 'retweet_band',
                			                             :band_id => @band.id,
			                                             :user_id => @user.id
			                                           ).where("created_at > ?", 1.day.ago).count
			  if num_tweets_in_past_day == 0 || true # HERE DELETE THIS

			    if session[:twitter_followers]
				    @shares = twitter_follower_point_calculation(session[:twitter_followers].to_i)#NUM_SHARES_AWARDED_FOR_RT
			    else
			      @shares = twitter_follower_point_calculation(0)
			    end
				  session[:twitter_followers] = nil

				  

          if ShareLedgerEntry.create( :user_id => session[:user_id],
                                          :band_id => @band.id,
                                          :adjustment => @shares,
                                          :description => 'retweet_band'
                              )
                              
            @success = true
          else
            @shares = nil
          end

        else
        # User has already been awarded for tweeting today
          flash.now[:error] = 'Retweet successful, but you have already earned shares for retweeting this band today.'
        end
=end
			else
				flash[:error] = 'Check to make sure your tweet went out.'
			end
		else
			flash[:error] = 'Could not get band ID for success page.'
			redirect_to root_url
			return false
		end
		
		if request.xhr?
		  render :layout => false
		elsif params[:lightbox]
		  @external = true
		  @show_close_button = true
			render :layout => 'lightbox'
		end 
	end
	
	
	def post_retweet
		begin
			options = {}
			options.update(:in_reply_to_status_id => params[:in_reply_to_status_id]) if params[:in_reply_to_status_id].present?

			@user = User.find(session[:user_id])    			

			if params[:twitter_api] && session[:original_tweet_id] && @user.twitter_user && @user.twitter_user.oauth_access_token && @user.twitter_user.oauth_access_secret
				if params[:twitter_api][:user_id] && params[:twitter_api][:message] && params[:twitter_api][:band_id]
				  @band = Band.find(params[:twitter_api][:band_id])

					
					#make tweet
					tweet = client.update(params[:twitter_api][:message])
					flash[:notice] = "Got it! Tweet ##{tweet.id} created."
					
=begin					
  			  num_retweets_in_past_day = ShareLedgerEntry.where(
  			                                             :description => 'retweet_band',
                  			                             :band_id => @band.id,
  			                                             :user_id => @user.id
  			                                           ).where("created_at > ?", 1.day.ago).count
=end
          num_retweets_in_past_day = Retweet.where(:band_id => @band.id, :twitter_user_id => @user.twitter_user.id).where("created_at > ?", 1.day.ago).count
  			                                           
  			                                           
  			  if true#num_retweets_in_past_day == 0

  			    if session[:twitter_followers]
  				    shares = twitter_follower_point_calculation(session[:twitter_followers].to_i)#NUM_SHARES_AWARDED_FOR_RT
  			    else
  			      shares = twitter_follower_point_calculation(0)
  			    end
            
            available_shares = @band.available_shares_for_earning
            if available_shares && available_shares < shares
              shares = available_shares
            end
  			    
            if Retweet.where(:original_tweet_id => session[:original_tweet_id].to_s, :twitter_user_id => @user.twitter_user.id).count == 0
              Retweet.create(:original_tweet_id => session[:original_tweet_id].to_s, :retweet_tweet_id => tweet.id.to_s, :tweet => tweet.text, :twitter_user_id => @user.twitter_user.id, :band_id => @band.id, :twitter_followers => session[:twitter_followers], :share_value => shares)
              ShareLedgerEntry.create( :user_id => session[:user_id],
                                              :band_id => @band.id,
                                              :adjustment => shares,
                                              :description => 'retweet_band'
                                  )
            else
              flash[:error] = 'You have already retweeted this status, so we allowed you to retweet it again. Although, you didn\'t earn any points this time around.'
    				  session[:twitter_followers] = nil
    				  session[:original_tweet_id] = nil
#  					  redirect_to session['last_clean_url'], :lightbox => params[:lightbox]    
					    redirect_to :action => 'success', :lightbox => params[:lightbox], :band_id => params[:twitter_api][:band_id], :shares_awarded => 0  					
    				  return false
            end

          else
          # User has already been awarded for tweeting today
            flash[:error] = 'Retweet successful, but you have already earned shares for retweeting this band today.'
  				  session[:twitter_followers] = nil
  				  session[:original_tweet_id] = nil            
#  					redirect_to session['last_clean_url'], :lightbox => params[:lightbox]
					  redirect_to :action => 'success', :lightbox => params[:lightbox], :band_id => params[:twitter_api][:band_id], :shares_awarded => 0  					
  					return false            
          end					
					session[:twitter_followers] = nil
				  session[:original_tweet_id] = nil
				  if shares == 0
				    flash[:error] = 'Sorry, all earnable shares have been used up today.The retweet went through but you didn\'t get any shares.  Check back tomorrow to earn BandStock.'
				  end
					redirect_to :action => 'success', :lightbox => params[:lightbox], :band_id => params[:twitter_api][:band_id], :shares_awarded => shares
					return true
				else
					flash[:error] = 'Could not get required parameters to post message.'			
				  session[:twitter_followers] = nil
				  session[:original_tweet_id] = nil					
					redirect_to session['last_clean_url'], :lightbox => params[:lightbox]
					return false
				end
			else
				flash[:error] = 'Could not get required parameters to post message. Make sure cookies are enabled and try again.'
			  session[:twitter_followers] = nil
			  session[:original_tweet_id] = nil				
				redirect_to session['last_clean_url'], :lightbox => params[:lightbox]
				return false
			end
		rescue
			flash[:error] = 'Sorry, Twitter is being unresponsive at the moment.'
		  session[:twitter_followers] = nil
		  session[:original_tweet_id] = nil			
			redirect_to session[:last_clean_url], :lightbox => params[:lightbox]
			return false			
		end					
		if request.xhr? || params[:lightbox]
			render :layout => false
		end		
	end
	
  def index
  	begin
			params[:page] ||= 1
			@tweets = client.friends_timeline(:page => params[:page])
		rescue
			flash[:error] = 'Sorry, Twitter is being unresponsive at the moment.'
			redirect_to session[:last_clean_url]
			return false			
		end					
  end

	def band_index
		begin
			params[:page] ||= 1
			@tweets = client(true, false, params[:band_id]).friends_timeline(:page => params[:page])
		rescue
			flash[:error] = 'Sorry, Twitter is being unresponsive at the moment.'
			redirect_to session[:last_clean_url]
			return false			
		end					    
	end

  def show
  	begin
			@tweet = client.status(params[:id])
		rescue
			flash[:error] = 'Sorry, Twitter is being unresponsive at the moment.'
			redirect_to session[:last_clean_url]
			return false			
		end							
  end

  def mentions
		begin
			params[:page] ||= 1
			@mentions = client.replies(:page => params[:page])
		rescue
			flash[:error] = 'Sorry, Twitter is being unresponsive at the moment.'
			redirect_to session[:last_clean_url]
			return false			
		end								
  end

  def favorites
  	begin
			params[:page] ||= 1
			@favorites = client.favorites(:page => params[:page])
		rescue
			flash[:error] = 'Sorry, Twitter is being unresponsive at the moment.'
			redirect_to session[:last_clean_url]
			return false			
		end								
  end

  def create
  	begin
			options = {}
			options.update(:in_reply_to_status_id => params[:in_reply_to_status_id]) if params[:in_reply_to_status_id].present?
	
			tweet = client.update(params[:twitter_api][:text])
			flash[:notice] = "Got it! Tweet ##{tweet.id} created."
			redirect_to :action => 'show', :id => tweet.id
		rescue
			flash[:error] = 'Sorry, Twitter is being unresponsive at the moment.'
			redirect_to session[:last_clean_url]
			return false			
		end								
  end

  def band_create
  	begin
			options = {}
			options.update(:in_reply_to_status_id => params[:in_reply_to_status_id]) if params[:in_reply_to_status_id].present?
	
			if params[:twitter_api]
				if params[:twitter_api][:band_id] && params[:twitter_api][:text]
					tweet = client(true, true, params[:twitter_api][:band_id]).update(params[:twitter_api][:text])
					flash[:notice] = "Got it! Tweet ##{tweet.id} created."
					redirect_to :action => 'show', :id => tweet.id
				else
					flash[:error] = 'Could not get required parameters to post message.'			
					redirect_to session['last_clean_url']
				end
			else
				flash[:error] = 'Could not get required parameters to post message.'
				redirect_to session['last_clean_url']
			end
		rescue
			flash[:error] = 'Sorry, Twitter is being unresponsive at the moment.'
			redirect_to session[:last_clean_url]
			return false
		end								
  end


  def fav
  	begin
			flash[:notice] = "Tweet fav'd. May not show up right away due to API latency."
			client.favorite_create(params[:id])
			redirect_to :action => 'show', :id => tweet.id
		rescue
			flash[:error] = 'Sorry, Twitter is being unresponsive at the moment.'
			redirect_to session[:last_clean_url]
			return false			
		end
			
  end

  def unfav
  	begin
			flash[:notice] = "Tweet unfav'd. May not show up right away due to API latency."
			client.favorite_destroy(params[:id])
			redirect_to :action => 'show', :id => tweet.id
		rescue
			flash[:error] = 'Sorry, Twitter is being unresponsive at the moment.'
			redirect_to session[:last_clean_url]
			return false			
		end								
  end

  
  private
  
  
  def does_tweet_belong_to_band(hash, tweet_id, band)
  # We need to make sure that the tweet that the user is retweeting was actually posted by the given band.
  # So that way Nefarious Ned couldn't just retweet his own status, for example, and gain shares in one of our bands.
  # When the Retweet link was generated, it was also given a hash token, which is
  #   md5(band_id + tweet_id + band_secret_token)
  # So we generate the hash ourselves and see if it matches. If not, either the tweet ID or band ID has been forged.
  #
    return false if hash.blank? || tweet_id.blank? || band.blank?
    we_have_a_match = hash.to_s == Digest::MD5.hexdigest(band.id.to_s + tweet_id.to_s + band.secret_token.to_s).to_s
    logger.info "User tried forging band ID or tweet ID when retweeting." unless we_have_a_match
    return we_have_a_match
  end
  
  
  def generate_endtag(screen_name = nil, long_url = nil)
		endtag_str = ''
#  	if screen_name
#			endtag_str +=' @'+screen_name
#		end
		if long_url
		  short_url = ShortUrl.generate_short_url(long_url)
			endtag_str += ' '+short_url
		end
  end

end

