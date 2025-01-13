module Paginatable
  extend ActiveSupport::Concern

  included do
    helper_method :page, :per_page
  end

  def page
    params.fetch(:page, 1).to_i
  end

  def per_page
    params.fetch(:per_page, 20).to_i
  end

  def paginate(relation)
    relation.offset(offset).limit(per_page)
  end

  private

  def offset
    (page - 1) * per_page
  end
end 