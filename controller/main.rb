module Controller
  class Main < Base
    map '/'
    set_layout 'splash'
    set_layout 'default' => [:search]

    def index
      if logged_in?
        redirect Home.r(:/)
      else
        redirect r(:login)
      end
    end

    def login
      @view = 'splash'
      if logged_in?
        redirect Home.r(:/)
      end
      force_mobile_to_narrow

      if account_login( request.subset('password_reset_code') )
        redirect Accounts.r(:change_password)
      end

      @logging_in = true
      if request.post?
        a = account_login( request.subset('username', 'password') )
        if a
          if session[:back]
            target = session[:back]
            session[:back] = nil
            redirect target
          else
            redirect Controller::Home.r(:/)
          end
        else
          flash[:error] = 'Invalid credentials.'
          redirect r(:login)
        end
      end
    end

    def logout
      account_logout
      flash[:notice] = 'You have been logged out.'
      redirect r(:login)
    end

    # TODO: Move to Accounts controller?
    def signup
      redirect '/'  if logged_in?
      force_mobile_to_narrow

      @invitation_code = request['invitation_code'].to_s

      return  if ! request.post?

      invitation = Libertree::Model::Invitation[ code: @invitation_code, account_id: nil ]
      if invitation.nil?
        flash[:error] = 'A valid invitation code is required.'
        return
      end

      if request['password'].to_s != request['password-confirm'].to_s
        flash[:error] = 'You mistyped your password.'
        return
      end

      username = request['username'].to_s.strip

      # TODO: Constrain email addresses, or at least strip out unsafe HTML, etc. with Loofah, or such.
      email = request['email'].to_s.strip
      if email.empty?
        email = nil
      end

      begin
        a = Libertree::Model::Account.create(
          username: username,
          password_encrypted: BCrypt::Password.create( request['password'].to_s ),
          email: email
        )
        invitation.account_id = a.id

        account_login request.subset('username', 'password')
        redirect Home.r(:/)
      rescue PGError => e
        case e.message
        when /duplicate key value violates unique constraint "accounts_username_key"/
          flash[:error] = "Username #{request['username'].inspect} is taken.  Please choose another."
        when /constraint "username_valid"/
          flash[:error] = "Username must be at least 2 characters long and consist only of lowercase letters, numbers, underscores and dashes."
        else
          raise e
        end
      end
    end

    def layout(width)
      case width
      when 'narrow'
        session[:layout] = 'narrow'
      when 'wide'
        session[:layout] = 'default'
      end
      redirect_referrer
    end

    def _render
      require_login
      respond Libertree.render( request['s'].to_s, account.autoembed )
    end

    # This is not in the Posts controller because we will handle many other search
    # types from the one searh box in the near future.
    def search
      @q = request['q'].to_s
      @posts = Libertree::Model::Post.search(@q)
      @comments = Libertree::Model::Comment.search(@q)
      @profiles = Libertree::Model::Profile.search(@q)
      @view = 'search'
    end

    def textarea_save
      # Check valid session first.
      if session[:saved_text]
        session[:saved_text][ request['id'].to_s ] = request['text'].to_s
      end
    end

    def textarea_clear(id)
      # Check valid session first.
      if session[:saved_text]
        session[:saved_text][id] = nil
      end
    end

    def request_password_reset
      Ramaze::Log.debug request.inspect
      return  if ! request.post?

      a = Libertree::Model::Account.set_up_password_reset_for( request['email'].to_s )
      if a
        # TODO: Make a generic method for queuing email
        Libertree::Model::Job.create(
          task: 'email',
          params: {
            'to'      => request['email'].to_s,
            'subject' => '[Libertree] Password reset',
            'body'    => %{
Someone (IP address: #{request.ip}) has requested that a password reset link
be sent to this email address.  If you wish to change your Libertree password
now, visit:

http://#{request.host_with_port}/login?password_reset_code=#{a.password_reset_code}

This link is only valid for 1 hour.
            }
          }.to_json
        )
      end

      flash[:notice] = "A password reset link has been sent for the account with that email address."

      redirect_referrer
    end
  end
end
