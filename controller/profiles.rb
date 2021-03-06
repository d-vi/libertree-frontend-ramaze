module Controller
  class Profiles < Base
    map '/profiles'

    before_all do
      require_login
    end

    layout do |path|
      if path =~ %r{^_}
        nil
      elsif session[:layout] == 'narrow'
        :narrow
      else
        :default
      end
    end

    def show( member_id )
      @member = Libertree::Model::Member[ member_id.to_i ]
      if @member.nil?
        redirect_referrer
      end

      @profile = @member.profile
      @view = 'excerpts-view'
    end

    def edit
      @profile = account.member.profile
    end

    def update
      return  if ! request.post?

      name_display = request['name_display'].to_s
      if name_display.strip.empty?
        name_display = nil
      end
      begin
        account.member.profile.set(
          name_display: name_display,
          description: request['description'].to_s
        )
      rescue PGError => e
        if e.message =~ /valid_name_display/
          flash[:error] = 'Special characters are not allowed in display names.'
          redirect_referrer
        else
          raise e
        end
      end

      redirect r(:show, account.member.id)
    end

    def avatar_reset
      options = Controller::Accounts.options
      dir = File.join(options.roots.first, options.publics.first, 'images', 'avatars')
      basename = "#{account.member.id}.png"
      avatar_path = File.expand_path(basename, dir)

      begin
        FileUtils.rm avatar_path
        account.member.avatar_path = nil
        flash[:notice] = "Avatar deleted."
      rescue
        flash[:error] = "Failed to reset avatar."
      end

      redirect_referrer
    end

    def avatar_upload
      return  if ! request.post?

      tempfile, filename, type = request['file'].values_at(:tempfile, :filename, :type)
      if type.split('/').first != 'image'
        flash[:error] = 'Only image files may be used as avatars.'
        redirect_referrer
      end
      extension = File.extname(filename).downcase
      if ! ['.png', '.jpg', '.jpeg', '.gif',].include?(extension)
        flash[:error] = 'Only .png, .jpeg and .gif files may be used as avatars.'
        redirect_referrer
      end

      options = Controller::Accounts.options
      dir = File.join(options.roots.first, options.publics.first, 'images', 'avatars')
      basename = "#{account.member.id}.png"
      save_path = File.expand_path(basename, dir)
      FileUtils.mkdir_p(dir)

      image = MiniMagick::Image.open(tempfile.path)
      image.combine_options do |c|
        c.thumbnail "40x40>"
        c.background "transparent"
        c.gravity "center"
        c.extent "40x40"
      end
      avatar_mask = File.join(options.roots.first, options.publics.first, 'images', 'avatar-mask.png')
      result = MiniMagick::Image.open(avatar_mask).composite(image) {|c| c.compose "In"}
      result.write save_path
      File.chmod  0644, save_path

      account.member.avatar_path = "/images/avatars/#{basename}"

      flash[:notice] = "Avatar changed."
      redirect_referrer
    end
  end
end
