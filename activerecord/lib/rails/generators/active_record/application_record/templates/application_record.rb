# frozen_string_literal: true

<% module_namespacing do -%>
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
<% end -%>
