class Comision < ActiveRecord::Base
	has_and_belongs_to_many :periodos
end
