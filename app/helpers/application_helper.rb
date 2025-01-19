module ApplicationHelper
  def group_by_source(cars)
    cars.group_by { |car| extract_source_from_url(car.product_url) }
  end

  def group_by_tracking(cars)
    cars.group_by do |car|
      tracking = car.sprint.car_tracking
      {
        category: tracking.category.name,
        brand: tracking.brand&.name,
        model: tracking.model&.name,
        serial: tracking.serial&.name
      }
    end
  end

  private

  def extract_source_from_url(url)
    case url
    when /arabam\.com/
      'Arabam.com'
    when /sahibinden\.com/
      'Sahibinden.com'
    else
      'Diğer'
    end
  end
end
