class CreateDenialReasons < ActiveRecord::Migration[7.1]
  def change
    create_table :denial_reasons do |t|
      t.string :code, null: false               # EOB code
      t.text :description                       # EOB description
      t.string :rejection_code
      t.string :group_code
      t.jsonb :reason_codes, default: []        # parsed array from Reason Code column
      t.string :remark_code
      t.text :suggested_correction
      t.jsonb :documentation, default: []

      t.timestamps
    end

    add_index :denial_reasons, :code, unique: true
    add_index :denial_reasons, :remark_code
  end
end
