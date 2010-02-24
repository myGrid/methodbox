class HelpController < ApplicationController

  before_filter :login_required

  before_filter :find_cart

end
