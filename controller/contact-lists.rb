module Controller
  class ContactLists < Base
    map '/contact-lists'

    before_all do
      require_login
    end

    def index
      @lists = account.contact_lists
    end

    def create
      redirect_referrer  if ! request.post?

      list = Libertree::Model::ContactList.create(
        name: request['name'].to_s,
        account_id: account.id
      )

      redirect r(:show, list.id)
    end

    def show(contact_list_id)
      @list = Libertree::Model::ContactList[
        account_id: account.id,
        id: contact_list_id.to_i
      ]
      if @list.nil?
        respond "404: Not Found", 404
      end
      @all_members = Libertree::Model::Member.all.sort_by { |m| m.name_display.downcase }
    end

    def update(contact_list_id)
      redirect_referrer  if ! request.post?

      @list = Libertree::Model::ContactList[
        account_id: account.id,
        id: contact_list_id.to_i
      ]
      if @list.nil?
        respond "404: Not Found", 404
      end

      @list.members = request['members']

      flash[:notice] = "Contact list updated."
      redirect r(:/)
    end
  end
end
