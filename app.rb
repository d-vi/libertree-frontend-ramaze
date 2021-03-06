require 'ramaze'
require 'm4dbi'
require 'rdbi-driver-postgresql'
require 'syck'
require 'mini_magick'
require 'redcarpet'

$conf = Syck.load( File.read("#{ File.dirname( __FILE__ ) }/config/application.yaml") )
$conf['websocket_blacklist'] ||= []
ENV['RACK_ENV'] = $conf['environment'] || 'live'

if $conf['graphicsmagick']
  MiniMagick.processor = :gm
end

all_confs = Syck.load( File.read("#{ File.dirname( __FILE__ ) }/config/database.yaml") )
env = ENV['LIBERTREE_ENV'] || 'development'
conf_db = all_confs[env]

$dbh ||= M4DBI.connect(
  :PostgreSQL,
  host:     conf_db['host'],
  database: conf_db['database'],
  username: conf_db['username'],
  password: conf_db['password']
)

require 'libertree/model'
require 'libertree/client'

require_relative 'lib/libertree/render'
require_relative 'lib/libertree/markdown'
require_relative 'lib/libertree/embedder'

require_relative 'controller/base'
require_relative 'controller/accounts'
require_relative 'controller/chat-messages'
require_relative 'controller/comment-likes'
require_relative 'controller/comments'
require_relative 'controller/contact-lists'
require_relative 'controller/home'
require_relative 'controller/invitations'
require_relative 'controller/main'
require_relative 'controller/messages'
require_relative 'controller/notifications'
require_relative 'controller/profiles'
require_relative 'controller/profiles_local'
require_relative 'controller/posts-hidden'
require_relative 'controller/post-likes'
require_relative 'controller/pools'
require_relative 'controller/posts'
require_relative 'controller/rivers'

require_relative 'controller/api/v1/base'
require_relative 'controller/api/v1/invitations'
require_relative 'controller/api/v1/posts'

require_relative 'controller/admin/base'
require_relative 'controller/admin/main'
require_relative 'controller/admin/forests'
require_relative 'controller/admin/servers'

if $conf['memcache']
  Ramaze::Cache.options.session = Ramaze::Cache::MemCache.using(compression: false)
end
Rack::RouteExceptions.route( Exception, '/error' )
