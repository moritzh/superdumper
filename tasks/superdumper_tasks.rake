namespace :db do 
  require 'config/environment.rb'
  desc "Dump the Scheme"
  task :superdumper do
    Dir.glob("#{RAILS_ROOT}/app/models/*.rb").each {|x| require x}
    Dir.glob("#{RAILS_ROOT}vendor/plugins/*/init.rb").each{|x| require x}
    outfile = File.new("database.dot","w")
    outfile << "graph G {\n"   
    outfile << "node [shape=Mrecord];"

    # we use some reflection to find all ar-models
    validModels = []
    ObjectSpace.each_object(Class) do |x|
      if x.superclass == ActiveRecord::Base  
        if x.table_exists?
          validModels << x 
          # create a new node for the model found
          outfile << "#{x.to_s} [label=\"{#{x.to_s}|"
          columnArray = []
          x.columns.each  {|c|  columnArray << "<#{c.name}> #{c.name}" }
          outfile << columnArray.join("|")
          outfile << "}\"];\n"

        end
      end
    end
    puts "Found #{validModels.size} Models that inherit from ActiveRecord"
    # now the associations, which is in fact way more dirty, tricky, whatever.
    # it doesn't take non-standard foreign keys into account. so better beware.
    # oh, and its o(n^2) at least.
    validModels.each do |x|
      assoc = x.reflect_on_all_associations(:belongs_to)
      assoc.each do |a|
        outfile << "#{x}:#{ActiveSupport::Inflector::foreign_key(a.name)}:w -- #{a.class_name}:id:e;\n"
      end
    end
    puts "Building dot file."

    outfile << "}"
    outfile.close
    puts "File built, calling dot"
    `dot -Tpdf -o database.pdf database.dot`
    puts "Dot finished, removing temporary files."
    File.delete("#{RAILS_ROOT}/database.dot")
    puts "Thank you, http://momo.brauchtman.net "
  end
end

