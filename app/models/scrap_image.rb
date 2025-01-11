class ScrapImage < ApplicationRecord
  belongs_to :scrape, polymorphic: true
  
  validates :original_url, presence: true, uniqueness: { scope: [:scrape_type, :scrape_id] }
  validates :local_path, uniqueness: true, allow_nil: true
  
  before_save :ensure_local_path
  
  private
  
  def ensure_local_path
    return if local_path.present?
    
    # Orijinal URL'den dosya adını al
    file_name = File.basename(URI.parse(original_url).path)
    # Benzersiz bir dosya adı oluştur
    unique_name = "#{Time.current.to_i}_#{SecureRandom.hex(4)}_#{file_name}"
    # Scrape tipine göre klasör yolu oluştur
    folder_path = "scrapes/#{scrape_type.downcase.pluralize}/#{scrape_id}"
    
    self.local_path = File.join(folder_path, unique_name)
  end
end
