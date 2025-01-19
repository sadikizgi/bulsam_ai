class CreateProxies < ActiveRecord::Migration[7.0]
  def change
    create_table :proxies do |t|
      t.string :ip, null: false
      t.integer :port, null: false
      t.string :username
      t.string :password
      t.string :proxy_type, null: false # datacenter, residential, mobile
      t.string :status, default: 'active' # active, disabled, error
      t.datetime :last_used_at
      t.datetime :last_check_at
      t.integer :response_time # milisaniye cinsinden
      t.integer :error_count, default: 0
      t.text :notes
      t.json :supported_sites, default: {} # hangi sitelerde çalıştığı bilgisi
      t.json :performance_metrics, default: {} # başarı oranı, ortalama yanıt süresi gibi metrikler

      t.timestamps
    end

    add_index :proxies, [:ip, :port], unique: true
    add_index :proxies, :proxy_type
    add_index :proxies, :status
    add_index :proxies, :last_used_at
  end
end
