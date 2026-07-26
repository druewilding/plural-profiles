module Chat::FindsPostable
  extend ActiveSupport::Concern

  private

  # Deliberately a closed case/when rather than type.constantize — the type
  # comes straight from request params, and constantizing arbitrary user
  # input onto a polymorphic association is a classic way to let an
  # attacker point it at a model it was never meant to reference.
  def find_postable(type, id)
    return nil if id.blank?

    case type
    when "Group" then Current.user.groups.find_by(id: id)
    else Current.user.profiles.find_by(id: id)
    end
  end
end
