class CartItem < ActiveRecord::Base

belongs_to :user;
belongs_to :variable;

end
