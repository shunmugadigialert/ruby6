# frozen_string_literal: true

class AssociationLoadingJob < ArgumentsRoundTripJob
  def perform(record, loaded_associations = [])
    loaded_associations.each do |loaded_association|
      Array(record.public_send(loaded_association))
    end

    super
  end
end
