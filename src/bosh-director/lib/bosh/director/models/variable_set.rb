module Bosh::Director::Models
  class VariableSet < Sequel::Model(Bosh::Director::Config.db)
    many_to_one :deployment, :class => 'Bosh::Director::Models::Deployment'
    one_to_many :variables, :class => 'Bosh::Director::Models::Variable'
    one_to_many :instances, :class => 'Bosh::Director::Models::Instance'

    def before_create
      self.created_at ||= Time.now
    end

    def find_variable_by_name(variable_name)
      variables_dataset.where(variable_name: variable_name).limit(1).first
    end

  end
end
