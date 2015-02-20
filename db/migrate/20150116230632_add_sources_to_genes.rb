class AddSourcesToGenes < ActiveRecord::Migration
  def change
    create_join_table :genes, :sources do |t|
      t.integer :gene_id, null: false
      t.integer :source_id, null: false
      t.timestamps
    end
  end
end
