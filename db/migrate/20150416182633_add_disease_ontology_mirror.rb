class AddDiseaseOntologyMirror < ActiveRecord::Migration[4.2]
  def change
    create_table :disease_ontology_mirrors do |t|
      t.string :doid
      t.string :name
    end

    add_index :disease_ontology_mirrors, :doid
    add_index :disease_ontology_mirrors, :name
  end
end
