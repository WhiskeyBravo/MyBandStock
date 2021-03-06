# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
# To completely start anew (don't do this):
#  rake db:migrate VERSION=0; rake db:migrate; rake db:seed --trace

#the creation tree goes as follows
#user ->

password = "test123"
random = ActiveSupport::SecureRandom.hex(10)
salt = Digest::SHA2.hexdigest("#{Time.now.utc}#{random}")
salted_password = Digest::SHA2.hexdigest("#{salt}#{password}")

adminUser = User.create( :first_name => 'admin',
                        :last_name => 'user',
                        :password => "c7e9034a207365a6b9ee5ec01e881cd029a937ca2465698ad048a317fdf737bc",
#												:password_confirmation => salted_password',
                        :country_id => 233,
                        :email => 'mbstech@mybandstock.com',
                        :email_confirmation => 'mbstech@mybandstock.com',
                        :status => 'active',
                        :agreed_to_tos => true,
                        :agreed_to_pp => true,
                        :password_salt => "c995ca183dd8b88ba693eec5ec0b5df8a8ba06a719e50b3a8e51c157a60d76f0")

site_admin_role = Role.create(:name => 'site_admin')
Role.create(:name => 'staff')

#grant the admin user site_admin
adminUser.roles << site_admin_role


#create JM's stuff

random = ActiveSupport::SecureRandom.hex(10)
salt = Digest::SHA2.hexdigest("#{Time.now.utc}#{random}")
salted_password = Digest::SHA2.hexdigest("#{salt}#{password}")
jm = User.create( :first_name => 'John-Michael',
                  :last_name => 'Fischer',
                  :password => salted_password,
                  :zipcode => '48116',
                  :country_id => 233,
                  :email => 'jm@mybandstock.com',
                  :email_confirmation => 'jm@mybandstock.com',
                  :status => 'active',
                  :agreed_to_tos => true,
                  :agreed_to_pp => true,
                  :password_salt => salt)
#grant admin
jm.roles << site_admin_role
#create some test bands

b_amp = Band.create(  :name => 'After Midnight Project',
                  :short_name => 'amp',
                  :access_schedule_url => 'www.amparmy.com',
                  :country_id => 232,
                  :zipcode => '90001',
                  :city => 'LA',
                  :bio => 'After Midnight Project began in 2004 in Los Angeles, California. They are known for their energetic live shows, extensive touring, and close connection to fans. With the release of their EP, The Becoming, in 2007, they caught the attention of Universal Motown and were signed.'
        )
b_dos = Band.create(  :name => 'The Dosimeters',
                  :short_name => 'the_dosimeters',
                  :country_id => 232,
                  :zipcode => '48116',
                  :city => 'Brighton')
b_flo = Band.create(  :name => 'Flobots',
                  :short_name => 'flobots',
                  :country_id => 232,
                  :zipcode => '80201',
                  :city => 'Denver')
#make user-band associations
jm.associations.create(:band_id => b_amp.id, :name => 'admin')
jm.associations.create(:band_id => b_flo.id, :name => 'admin')
jm.associations.create(:band_id => b_dos.id, :name => 'admin')

adminUser.associations.create(:band_id => b_amp.id, :name => 'admin')
adminUser.associations.create(:band_id => b_flo.id, :name => 'admin')
adminUser.associations.create(:band_id => b_dos.id, :name => 'admin')


#create some LSSs
lss_amp = b_amp.live_stream_series.create(:title => 'Warped Tour Twenty Ten',:starts_at => 1.hour.from_now, :ends_at => 1.year.from_now)
lss_dos = b_dos.live_stream_series.create(:title => 'ballet show',:starts_at => 1.hour.from_now, :ends_at => 1.year.from_now)


#create some StreamAPI viewer themes
readOnlyChat_low = StreamapiStreamTheme.create( :name => '16:9, Video & Read Only Chat - Low Quality (256 kbps)',
                  :layout_path => '/themes/100/000/866/4/theme_b8d93a34-6815-11df-897e-45bad36ccbb1.xml',
                  :skin_path => '/themes/100/000/866/4/skin_b8d93a34-6815-11df-897e-45bad36ccbb1.xml',
                  :width => 496,
                  :height => 469,
                  :quality => '256 kbps (Low)' )

fullChat_low = StreamapiStreamTheme.create( :name => '16:9, Video & Full Chat - Low Quality (256 kbps)',
                  :layout_path => '/themes/100/000/866/4/theme_67b3dede-6814-11df-897e-45bad36ccbb1.xml',
                  :skin_path => '/themes/100/000/866/4/skin_67b3dede-6814-11df-897e-45bad36ccbb1.xml',
                  :width => 496,
                  :height => 494,
                  :quality => '256 kbps (Low)' )

vidOnly_low = StreamapiStreamTheme.create( :name => '16:9, Only Video - Low Quality (256 kbps)',
                  :layout_path => '/themes/100/000/866/4/theme_edd12c3b-6813-11df-897e-45bad36ccbb1.xml',
                  :skin_path => '/themes/100/000/866/4/skin_edd12c3b-6813-11df-897e-45bad36ccbb1.xml',
                  :width => 591,
                  :height => 332,
                  :quality => '256 kbps (Low)' )

styledVidOnly_low = StreamapiStreamTheme.create( :name => '16:9, Styled - Only Video - Low Quality (256 kbps)',
                  :layout_path => '/themes/100/000/866/4/theme_5c53ade4-7577-11df-867b-37ea15bf14d6.xml',
                  :skin_path => '/themes/100/000/866/4/skin_5c53ade4-7577-11df-867b-37ea15bf14d6.xml',
                  :width => 500,
                  :height => 278,
                  :quality => '256 kbps (Low)' )

readOnlyChat_med = StreamapiStreamTheme.create( :name => '16:9, Video & Read Only Chat - Medium Quality (384 kbps)',
                  :layout_path => '/themes/100/000/866/4/theme_d8271a22-6814-11df-897e-45bad36ccbb1.xml',
                  :skin_path => '/themes/100/000/866/4/skin_d8271a22-6814-11df-897e-45bad36ccbb1.xml',
                  :width => 496,
                  :height => 469,
                  :quality => '384 kbps (Medium)' )

fullChat_med = StreamapiStreamTheme.create( :name => '16:9, Video & Full Chat - Medium Quality (384 kbps)',
                  :layout_path => '/themes/100/000/866/4/theme_aca03800-6814-11df-897e-45bad36ccbb1.xml',
                  :skin_path => '/themes/100/000/866/4/skin_aca03800-6814-11df-897e-45bad36ccbb1.xml',
                  :width => 496,
                  :height => 494,
                  :quality => '384 kbps (Medium)' )

vidOnly_med = StreamapiStreamTheme.create( :name => '16:9, Only Video - Medium Quality (384 kbps)',
                  :layout_path => '/themes/100/000/866/4/theme_e2ddf078-6812-11df-897e-45bad36ccbb1.xml',
                  :skin_path => '/themes/100/000/866/4/skin_e2ddf078-6812-11df-897e-45bad36ccbb1.xml',
                  :width => 591,
                  :height => 332,
                  :quality => '384 kbps (Medium)' )

styledVidOnly_low = StreamapiStreamTheme.create( :name => '16:9, Styled - Video + Chat - Medium Quality (384 kbps)',
                  :layout_path => '/themes/100/000/866/4/theme_5c53ade4-7577-11df-867b-37ea15bf14d6.xml',
                  :skin_path => '/themes/100/000/866/4/skin_5c53ade4-7577-11df-867b-37ea15bf14d6.xml',
                  :width => 500,
                  :height => 375,
                  :quality => '256 kbps (low)' )

styledVidOnly_med = StreamapiStreamTheme.create( :name => '16:9, Styled - Video + Chat - Medium Quality (384 kbps)',
                  :layout_path => '/themes/100/000/866/4/theme_6b6a3818-7579-11df-867b-37ea15bf14d6.xml',
                  :skin_path => '/themes/100/000/866/4/skin_6b6a3818-7579-11df-867b-37ea15bf14d6.xml',
                  :width => 500,
                  :height => 375,
                  :quality => '384 kbps (Medium)' )

styledVidOnly_HD = StreamapiStreamTheme.create( :name => '16:9, Styled - Video + Chat - HD Quality (1024 kbps)',
                  :layout_path => '/themes/100/000/866/4/theme_fc34fcf1-845d-11df-8528-85e0786ff4d7.xml',
                  :skin_path => '/themes/100/000/866/4/skin_fc34fcf1-845d-11df-8528-85e0786ff4d7.xml',
                  :width => 500,
                  :height => 375,
                  :quality => '1024 kbps (HD)' )

#create some StreamAPI streams (fake of course)
lss_dos.streamapi_streams.create( :private_hostid => 123,
                              :public_hostid => 123,
                              :title => 'act 1',
                              :starts_at => 1.weeks.from_now,
                              :ends_at => (1.weeks.from_now + 2.hours),
                              :broadcaster_theme_id => styledVidOnly_low.id,
                              :viewer_theme_id => styledVidOnly_low.id,
                              :public => false,
                              :band_id => b_dos.id )

lss_dos.streamapi_streams.create( :private_hostid => 1234,
                              :public_hostid => 1234,
                              :title => 'act 2',
                              :starts_at => 2.weeks.from_now,
                              :ends_at => (2.weeks.from_now + 3.hours),
                              :broadcaster_theme_id => styledVidOnly_low.id,
                              :viewer_theme_id => styledVidOnly_low.id,
                              :public => false,
                              :band_id => b_dos.id )
#give jm permissions to chat and view this guy
lssp = jm.live_stream_series_permissions.create(:can_view => true,
                                                :can_chat => true,
                                                :live_stream_series_id => lss_dos.id
                                                )


lss_amp.streamapi_streams.create(
                              :title => 'Exclusive Video Update #1 - Off Day',
                              :location => 'Tour Bus',
                              :starts_at => DateTime.new(2010, 6, 27, 12, 0, 0),
                              :ends_at => DateTime.new(2010, 6, 27, 13, 0, 0),
                              :broadcaster_theme_id => styledVidOnly_low.id,
                              :viewer_theme_id => styledVidOnly_low.id,
                              :public => true,
                              :band_id => b_amp.id )

lss_amp.streamapi_streams.create(
                              :title => 'Exclusive Video Update #2',
                              :location => 'Mansfield',
                              :starts_at => DateTime.new(2010, 7, 13, 12, 0, 0),
                              :ends_at => DateTime.new(2010, 7, 13, 13, 0, 0),
                              :broadcaster_theme_id => styledVidOnly_low.id,
                              :viewer_theme_id => styledVidOnly_low.id,
                              :public => true,
                              :band_id => b_amp.id )

lss_amp.streamapi_streams.create(
                              :title => 'Exclusive Video Update #3 - Off Day',
                              :location => 'Tour Bus',
                              :starts_at => DateTime.new(2010, 7, 19, 12, 0, 0),
                              :ends_at => DateTime.new(2010, 7, 19, 13, 0, 0),
                              :broadcaster_theme_id => styledVidOnly_low.id,
                              :viewer_theme_id => styledVidOnly_low.id,
                              :public => true,
                              :band_id => b_amp.id )

lss_amp.streamapi_streams.create(
                              :title => 'Exclusive Video Update #4 - Backstage Sneak Peak',
                              :location => 'Virginia Beach',
                              :starts_at => DateTime.new(2010, 7, 21, 12, 0, 0),
                              :ends_at => DateTime.new(2010, 7, 21, 13, 0, 0),
                              :broadcaster_theme_id => styledVidOnly_low.id,
                              :viewer_theme_id => styledVidOnly_low.id,
                              :public => true,
                              :band_id => b_amp.id )

lss_amp.streamapi_streams.create(
                              :title => 'Exclusive Video Update #5 - Off Day',
                              :location => 'Tour Bus',
                              :starts_at => DateTime.new(2010, 8, 3, 12, 0, 0),
                              :ends_at => DateTime.new(2010, 8, 3, 13, 0, 0),
                              :broadcaster_theme_id => styledVidOnly_low.id,
                              :viewer_theme_id => styledVidOnly_low.id,
                              :public => true,
                              :band_id => b_amp.id )

=begin
lss_amp.streamapi_streams.create(
                              :private_hostid => 123456,
                              :public_hostid => 123456,
                              :title => 'Home Depot Center',
                              :location => 'Carson, CA',
                              :starts_at => 3.weeks.from_now,
                              :ends_at => (3.weeks.from_now + 4.hours),
                              :broadcaster_theme_id => fullChat_low.id,
                              :viewer_theme_id => fullChat_low.id,
                              :public => false,
                              :band_id => b_amp.id )
lss_amp.streamapi_streams.create(
                              :private_hostid => 1234567,
                              :public_hostid => 1234567,
                              :title => 'Shoreline Amphitheatre',
                              :location => 'Mountain View, CA',
                              :starts_at => 3.weeks.from_now,
                              :ends_at => (3.weeks.from_now + 4.hours),
                              :broadcaster_theme_id => fullChat_low.id,
                              :viewer_theme_id => fullChat_low.id,
                              :public => false,
                              :band_id => b_amp.id )
lss_amp.streamapi_streams.create(
                              :private_hostid => 12345678,
                              :public_hostid => 12345678,
                              :title => 'Cricket Pavilion',
                              :location => 'Phoenix, AZ',
                              :starts_at => 3.weeks.from_now,
                              :ends_at => (3.weeks.from_now + 4.hours),
                              :broadcaster_theme_id => fullChat_low.id,
                              :viewer_theme_id => fullChat_low.id,
                              :public => false,
                              :band_id => b_amp.id )
lss_amp.streamapi_streams.create(
                              :private_hostid => 123456789,
                              :public_hostid => 123456789,
                              :title => 'AT&T Center - San Antonio, TX',
                              :starts_at => 3.weeks.from_now,
                              :ends_at => (3.weeks.from_now + 4.hours),
                              :broadcaster_theme_id => fullChat_low.id,
                              :viewer_theme_id => fullChat_low.id,
                              :public => false,
                              :band_id => b_amp.id )
=end

#create Brians stuff
random = ActiveSupport::SecureRandom.hex(10)
salt = Digest::SHA2.hexdigest("#{Time.now.utc}#{random}")
salted_password = Digest::SHA2.hexdigest("#{salt}#{password}")
brian = User.create( :first_name => 'Brian',
                  :last_name => 'Jennings',
                  :password => salted_password,
#                  :password_confirmation => salted_password,
                  :country_id => 233,
                  :email => 'brian@mybandstock.com',
                  :email_confirmation => 'brian@mybandstock.com',
                  :status => 'active',
                  :agreed_to_tos => true,
                  :agreed_to_pp => true,
                  :password_salt => salt)

#create Jakes stuff
random = ActiveSupport::SecureRandom.hex(10)
salt = Digest::SHA2.hexdigest("#{Time.now.utc}#{random}")
salted_password = Digest::SHA2.hexdigest("#{salt}#{password}")
jake = User.create( :first_name => 'Jake',
                  :last_name => 'Schwartz',
                  :password => salted_password,
#                  :password_confirmation => salted_password,
                  :country_id => 233,
                  :email => 'jake@mybandstock.com',
                  :email_confirmation => 'jake@mybandstock.com',
                  :status => 'active',
                  :agreed_to_tos => true,
                  :agreed_to_pp => true,
                  :password_salt => salt)

random = ActiveSupport::SecureRandom.hex(10)
salt = Digest::SHA2.hexdigest("#{Time.now.utc}#{random}")
salted_password = Digest::SHA2.hexdigest("#{salt}#{password}")
fan = User.create( :first_name => 'Fanzo',
                   :last_name => 'Gonzales',
                   :password => salted_password,
                   :country_id => 233,
                   :email => 'fan1@mybandstock.com',
                   :email_confirmation => 'fan1@mybandstock.com',
                   :status => 'active',
                   :agreed_to_tos => true,
                   :agreed_to_pp => true,
                   :password_salt => salt)
random = ActiveSupport::SecureRandom.hex(10)
salt = Digest::SHA2.hexdigest("#{Time.now.utc}#{random}")
salted_password = Digest::SHA2.hexdigest("#{salt}#{password}")
fan = User.create( :first_name => 'Bobeeto',
                   :last_name => 'Garcia',
                   :password => salted_password,
                   :country_id => 233,
                   :email => 'fan2@mybandstock.com',
                   :email_confirmation => 'fan2@mybandstock.com',
                   :status => 'active',
                   :agreed_to_tos => true,
                   :agreed_to_pp => true,
                   :password_salt => salt)
random = ActiveSupport::SecureRandom.hex(10)
salt = Digest::SHA2.hexdigest("#{Time.now.utc}#{random}")
salted_password = Digest::SHA2.hexdigest("#{salt}#{password}")
fan = User.create( :first_name => 'Cucumber',
                   :last_name => 'Slice',
                   :password => salted_password,
                   :country_id => 233,
                   :email => 'fan3@mybandstock.com',
                   :email_confirmation => 'fan3@mybandstock.com',
                   :status => 'active',
                   :agreed_to_tos => true,
                   :agreed_to_pp => true,
                   :password_salt => salt)

# This is the MBS API user that we use internally. These keys must match exactly the ones listed
# in environment.rb. For example, when we apply share code permissions, we call the MBS API with
# these credentials, pulled from config.
our_api_user = ApiUser.create( :api_key => 'a3dcf5600b117fc0',
                               :secret_key =>  '7f5ba404ac8599fd0cf3623ebf84e97a' )

#adminUser = User.create(:first_name => 'admin', :last_name => 'user', :password => 'fd7013a96f6210e7aa475bed9f422f70ffefa5932e5e05a6aea77840929edce2', :email => 'mbstech@mybandstock.com', :status => 'active')
#r = User.find(adminUser.id).roles.create(:name => 'site_admin')
#roles = Role.create(:name => 'staff')

