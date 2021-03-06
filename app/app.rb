module Server
  class App < Padrino::Application
    use ActiveRecord::ConnectionAdapters::ConnectionManagement
    register Padrino::Rendering
    register Padrino::Mailer
    register Padrino::Helpers

    enable :sessions

    ##
    # Caching support
    #
    register Padrino::Cache
    enable :caching
    #
    # You can customize caching store engines:
    #
    # set :cache, Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
    # set :cache, Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1))
    # set :cache, Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
    # set :cache, Padrino::Cache::Store::Memory.new(50)
    # set :cache, Padrino::Cache::Store::File.new(Padrino.root('tmp', app_name.to_s, 'cache')) # default choice
    #

    ##
    # Application configuration options
    #
    # set :raise_errors, true       # Raise exceptions (will stop application) (default for test)
    # set :dump_errors, true        # Exception backtraces are written to STDERR (default for production/development)
    # set :show_exceptions, true    # Shows a stack trace in browser (default for development)
    # set :logging, true            # Logging in STDOUT for development and file for production (default only for development)
    # set :public_folder, 'foo/bar' # Location for static assets (default root/public)
    # set :reload, false            # Reload application files (default in development)
    # set :default_builder, 'foo'   # Set a custom form builder (default 'StandardFormBuilder')
    # set :locale_path, 'bar'       # Set path for I18n translations (default your_apps_root_path/locale)
    # disable :sessions             # Disabled sessions by default (enable if needed)
    # disable :flash                # Disables sinatra-flash (enabled by default if Sinatra::Flash is defined)
    # layout  :my_layout            # Layout can be in views/layouts/foo.ext or views/foo.ext (default :application)
    #

    ##
    # You can configure for a specified environment like:
    #
    #   configure :development do
    #     set :foo, :bar
    #     disable :asset_stamp # no asset timestamping for dev
    #   end
    #
    configure :development do
      set :raise_errors, true       # Raise exceptions (will stop application) (default for test)
      set :dump_errors, true        # Exception backtraces are written to STDERR (default for production/development)
      set :show_exceptions, true    # Shows a stack trace in browser (default for development)
      set :logging, true            # Logging in STDOUT for development and file for production (default only for development)
    end

    configure :test do
      enable :raise_errors
      enable :logging
    end

    configure :production do
      set :cache, Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
      set :raise_errors, false
      set :dump_errors, true
      set :show_exceptions, false
      set :logging, true
    end

    error 401 do
      {message: "Bad credentials"}.to_json
    end

    error 404 do
      {message: "Not Found"}.to_json
    end

    error 422 do
      {
        message: "Unprocessable Entity",
        errors: @errors.messages.map{|message| {:field => message[0], :messages => message[1]}}
      }.to_json
    end

    before do
      pager
    end

    helpers do
      def error_message(code, message)
        content_type :json
        halt 500, {error_code: code, message: message}.to_json
      end

      def invalid_param_error
        error_message(100, "INVALID PARAMETER")
      end

      def status_failure(message, opt={})
        {status: "failure", message: message}.merge(opt)
      end

      def status_ok(opt = {})
        {status: "ok"}.merge(opt)
      end

      def login(params=nil)
        halt 404 unless request.env["HTTP_AUTHORIZATION"]
        key, token = request.env["HTTP_AUTHORIZATION"].split
        halt 401 unless key and token and key == "token" and token.length > 0
        @user = User.find_by_token(token)
        halt 401 unless @user
      end

      def pager
        @page = (params[:page] and params[:page].to_i > 0) ? params[:page] : 1
        @per = (params[:per] and params[:per].to_i > 0) ? params[:per] : 30
      end

      def user_avatar_url(user)
        uri(user.avatar.url, true, false)
      end
    end

    get '/' do
      'Welcome to LB'
    end
  end
end
