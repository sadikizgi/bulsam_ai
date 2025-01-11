class UpdateCarsTable < ActiveRecord::Migration[8.0]
  def change
    # Remove old columns
    remove_column :cars, :brand, :string
    remove_column :cars, :model, :string
    remove_column :cars, :year, :integer
    remove_column :cars, :price, :decimal
    remove_column :cars, :mileage, :integer
    remove_column :cars, :fuel_type, :integer
    remove_column :cars, :transmission, :integer
    remove_column :cars, :location, :string
    remove_column :cars, :status, :integer
    
    # Add new columns
    add_column :cars, :car_model, :string
    add_column :cars, :car_serial, :string
    add_column :cars, :car_motor_serial, :string
    add_column :cars, :car_serial_name, :string
    add_column :cars, :car_url, :string
    
    add_reference :cars, :vehicle, null: false, foreign_key: true
    
    add_index :cars, :car_url, unique: true
  end
end
