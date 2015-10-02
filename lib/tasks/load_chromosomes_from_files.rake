namespace :genrep do

  desc "Load chromosomes from files"
  task :load_chromosomes_from_files, [:path, :genome_id] do |t, args|
    
    ### Use rails enviroment
    require "#{Rails.root}/config/environment"
 
    data_dir = APP_CONFIG[:data_dir]
    tmp_dir = Pathname.new("/scratch/cluster/monthly/genrep")
    Dir.mkdir(tmp_dir) if !File.exists?(tmp_dir)
    tmp_dir+='nr_assemblies'
    Dir.mkdir(tmp_dir) if !File.exists?(tmp_dir)
    Dir.mkdir(tmp_dir + 'fasta') if !File.exists?(tmp_dir + 'fasta')	
    
    tmp_dir = tmp_dir.to_s
    
    chr_repo_dir = data_dir + "/chromosomes/fasta/"
    nr_assembly_repo_dir = data_dir + "/nr_assemblies/"
    

    ### get file list in directory
    dir = Dir.new(args.path)
    dir.entries.select{|e| e.match(/^chr\d+\./) }.map{|e| s = e.match(/^chr(\d+)\./); s[1].to_i}.sort.each do |e|
      
     
      filename = Pathname.new(dir) + "chr#{e}.fa"
      puts filename
    
      #create new chromosome
      #id  | num |  length   | refseq_locus | refseq_version | gi_number |         created_at         |         updated_at         | name | genome_id | chr_type_id | synonyms | circular | public
      h={
        :name => e.to_s,
        :genome_id => args.genome_id,
        :chr_type_id => 1,
        :circular => false,
        :public => true,
        :num => e.to_i
      }
      new_c = Chromosome.find(:first, :conditions => h)
      if !new_c
        new_c = Chromosome.new(h)
        new_c.save
      else
      end

      ## write sequence                                                                                                                                                                        
      len_seq = 0
      
      File.open(filename, 'r') do |f|
        File.open("#{chr_repo_dir}#{new_c.id}.fa", 'w') do |f2|
          while (line = f.gets)
            if line.match(/^>/)
              f2.write(">#{new_c.id}\n")
            else
              f2.write(line)
              len_seq += line.chomp.size
            end
          end
        end
      end
      
      `gzip #{chr_repo_dir}#{new_c.id}.fa`
      new_c.update_attributes({:length => len_seq})
      
    end
  end
end
