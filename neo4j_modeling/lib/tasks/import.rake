session = Neo4j::Session.open(:server_db)

namespace :import do
  task universities: :environment do
    file_path = "#{Rails.root}/lib/tasks/data/universities.json"
    json_data = open(file_path){|io| JSON.load(io) }
    
    # モデル名
    university_model = 'University'
    department_model = 'UniversityDepartment'
    
    json_data.each_slice(2) do |university_data|
      if university_name = university_data[0]['大学']
        target_university = Neo4j::Label.find_nodes(university_model, :name, university_name).first
        target_university = Neo4j::Node.create({name: university_name}, university_model) unless target_university
      end
      
      if departments = university_data[1]['学部']
        target_departments = []
        departments.each do |department_name|
          target_department = Neo4j::Label.find_nodes(department_model, :name, department_name).first
          target_department = Neo4j::Node.create({name: department_name}, department_model) unless target_department
          target_departments << target_department if target_department
        end
        
        if target_university
          target_departments.each do |department|
            has_departments = target_university.nodes(dir: :outgoing, type: :has)
            target_university.create_rel(:has, department) unless has_departments.include?(department)
          end
        end
      end
    end
  end
end