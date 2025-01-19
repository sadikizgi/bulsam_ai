class Proxy < ApplicationRecord
  # Validations
  validates :ip, presence: true
  validates :port, presence: true, numericality: { only_integer: true, greater_than: 0, less_than: 65536 }
  validates :proxy_type, presence: true, inclusion: { in: %w[datacenter residential mobile] }
  validates :status, inclusion: { in: %w[active disabled error] }
  
  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :by_type, ->(type) { where(proxy_type: type) }
  scope :available_for_site, ->(site) { 
    active.where("supported_sites->>'#{site}' != 'blocked' OR supported_sites->>'#{site}' IS NULL") 
  }
  
  # Class methods
  def self.get_next_available(site: nil, proxy_type: nil)
    scope = active
    scope = scope.by_type(proxy_type) if proxy_type
    scope = scope.available_for_site(site) if site
    
    scope.order(last_used_at: :asc).first
  end
  
  # Instance methods
  def url
    if username.present? && password.present?
      "http://#{username}:#{password}@#{ip}:#{port}"
    else
      "http://#{ip}:#{port}"
    end
  end
  
  def mark_as_used!
    update(last_used_at: Time.current)
  end
  
  def mark_site_as_blocked!(site)
    sites = supported_sites || {}
    sites[site] = 'blocked'
    update(supported_sites: sites)
  end
  
  def mark_site_as_working!(site)
    sites = supported_sites || {}
    sites[site] = 'working'
    update(supported_sites: sites)
  end
  
  def record_success!(response_time_ms)
    metrics = performance_metrics || {}
    metrics['success_count'] = (metrics['success_count'] || 0) + 1
    metrics['total_count'] = (metrics['total_count'] || 0) + 1
    metrics['avg_response_time'] = calculate_average_response_time(metrics['avg_response_time'], response_time_ms)
    
    update(
      performance_metrics: metrics,
      response_time: response_time_ms,
      last_check_at: Time.current
    )
  end
  
  def record_error!(error_message = nil)
    metrics = performance_metrics || {}
    metrics['error_count'] = (metrics['error_count'] || 0) + 1
    metrics['total_count'] = (metrics['total_count'] || 0) + 1
    
    increment!(:error_count)
    update(
      performance_metrics: metrics,
      last_check_at: Time.current,
      notes: [notes, error_message].compact.join("\n")
    )
    
    # Eğer hata sayısı belirli bir eşiği geçerse proxy'i devre dışı bırak
    update(status: 'error') if error_count >= 5
  end
  
  private
  
  def calculate_average_response_time(current_avg, new_time)
    return new_time unless current_avg
    ((current_avg * 9) + new_time) / 10.0 # Son 10 isteğin ağırlıklı ortalaması
  end
end
