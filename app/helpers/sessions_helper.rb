module SessionsHelper
    def sign_in(user)
        #create a new token
        remember_token = User.new_remember_token
        #place a raw token in the browser cookies
        cookies.permanent[:remember_token] = remember_token
        # save the hashed token to the db
        user.update_attribute(:remember_token, User.digest(remember_token))
        # set the current user equal to the given user
        self.current_user = user
    end

    def signed_in?
        !current_user.nil?
    end

    def current_user=(user)
        @current_user = user
    end

    def current_user
        remember_token = User.digest(cookies[:remember_token])
        @current_user ||= User.find_by(remember_token: remember_token)
    end

    def current_user?(user)
        user == current_user
    end

    def signed_in_user
        unless signed_in?
            store_location
            redirect_to signin_url, notice: "Please sign in"
        end
    end

    def sign_out
        # first change the user's remember token in the DB, in case it got stolen
        current_user.update_attribute(:remember_token, User.digest(User.new_remember_token))
        # remove the remember token from the session
        cookies.delete(:remember_token)
        # set teh user to nil
        self.current_user = nil
    end

    def redirect_back_or(default)
        redirect_to(session[:return_to] || default)
        session.delete(:return_to)
    end

    def store_location
        session[:return_to] = request.url if request.get?
    end
end















