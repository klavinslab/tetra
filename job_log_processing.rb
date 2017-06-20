require_relative 'testlib'

def time_size_data_processing resp, data_file, threshold, size
  begin
    start_time = resp[:backtrace][2][:inputs][:timestamp]
    end_time = resp[:backtrace][-2][:inputs][:timestamp]
  rescue => e
    puts "Error in processing start_time or end_time #{e}"
    return nil
  end
  num_of_steps_and_nexts = resp[:backtrace].length
  duration = ((end_time - start_time)/60).round(1)
  size = 0 if !size
  if duration > 0.1
    user_id = resp[:user_id].to_i
    user_name = USER_ID_NAME[user_id]
    id = resp[:id]
    all_times = resp[:backtrace].collect { |step|
      if step[:operation] == "next"
        step[:inputs][:timestamp]
      end
    }
    all_times.compact!
    time_intervals = all_times.each_cons(2).map { |a, b| ((b - a)/60).round(1) }
    average_time = 0
    if time_intervals.length > 0
      average_time = (time_intervals.inject { |sum, x| sum + x })/(time_intervals.length)
    end
    time_intervals_threshold = time_intervals.select { |t| t > threshold }
    clean_time_intervals = time_intervals - time_intervals_threshold
    average_time_interval = 0
    if clean_time_intervals.length > 0
      average_time_interval = (clean_time_intervals.inject { |sum, x| sum + x })/(clean_time_intervals.length)
    end
    max_time_interval = time_intervals_threshold.max || time_intervals.max
    #puts max_time_interval
    ajusted_duration = ( duration - (time_intervals_threshold.inject { |sum, x| sum + x } || 0) + (time_intervals_threshold.length) * average_time_interval ).round(1)
    if size > 0 && ajusted_duration > 0
      data_file.write("#{id},#{size},#{duration},#{ajusted_duration},#{max_time_interval},#{user_id},#{user_name}\n")
    end
    file_name = resp[:path].split('/').last.split('.').first
    puts "#{file_name}, job_id is #{id}, size is #{size}, duration is #{duration}, time_intervals_th is #{time_intervals_threshold}, average_time is #{average_time.round(1)}, ajusted_average_time is #{average_time_interval.round(1)}, ajusted_duration is #{ajusted_duration}, user_name is #{user_name}."
  end
end

def user_info id
  response = Test.send({
      login: Test.login,
      key: Test.key,
      run: {
        method: "find",
        args: {
          model: :user,
          where: { id: id }
        }
      }
    })
  return response[:rows][0]
end

def time_size_report resp

  file_name = resp[:path].split('/').last.split('.').first
  if FILE_LIST.include? file_name
    puts resp[:id]
    begin
      if ["get_primer","order_primer"].include? file_name
        size = resp[:backtrace][-1][:rval][:io_hash][:primer_ids].length
      elsif resp[:backtrace][-1][:rval].is_a? Array
        size = resp[:backtrace][-1][:rval].length
      elsif resp[:backtrace][-1][:rval][:io_hash][:size]
        size = resp[:backtrace][-1][:rval][:io_hash][:size]
      else
        size = 1
      end
    rescue
      return
    end

    data_file = File.open("data/#{file_name}.csv", "a")
    time_size_data_processing(resp, data_file, 20, size)
    data_file.close
  end

end

# start timing
start_time = Time.now

# make hash (user id -> user name)
user_data = Test.send({
      login: Test.login,
      key: Test.key,
      run: {
        method: "find",
        args: {
          model: :user
        }
      }
    })
USER_ID_NAME = {}
user_data[:rows].each do |user|
  USER_ID_NAME[user[:id]] = user[:name]
end

# array of protocol names
FILE_LIST = ["make_50_percent_peg", "make_50_percent_glycerol", "make_FCC", "bacteria_media", "yeast_media_ypad", "yeast_media_sdo_sc", "pour_agar_LB",
             "pour_agar_YPAD_SDO", "move_agar_plates", "make_gibson_aliquots", "make_5x_iso_buffer", "make_media_electrocompetent_ecoli_comp_cells", 
             "start_overnight_electrocompetent_ecoli_comp_cells", "inoculate_electrcompetent_ecoli_comp_cells", "check_OD_electrocompetent_ecoli_comp_cells",
             "chill_electrocompetent_ecoli_comp_cells", "first_spin_water_wash_electrocompetent_ecoli_comp_cells", 
             "first_glycerol_wash_electrocompetent_ecoli_comp_cells", "second_glycerol_wash_electrocompetent_ecoli_comp_cells",
             "aliquot_electrocompetent_ecoli_comp_cells", "order_primer", "get_primer", "PCR", "pour_gel", "run_gel", "cut_gel", "purify_gel", "gibson", 
             "ecoli_transformation", "plate_ecoli_transformation", "image_plate", "golden_gate", "start_overnight_plate", "miniprep", "sequencing", 
             "upload_sequencing_results", "restriction_digest", "plate_midiprep", "small_inoculation_midiprep", "large_inoculation_midiprep", "midiprep",
             "start_overnight_glycerol_stock", "maxiprep", "agro_transformation", "plate_agro_transformation", "discard_item", "glycerol_stock",
             "streak_yeast_plate", "overnight_suspension_collection", "inoculate_large_volume_growth", "make_yeast_competent_cell", 
             "digest_plasmid_yeast_transformation", "make_antibiotic_plate", "yeast_transformation", "plate_yeast_transformation", "make_yeast_lysate",
             "yeast_colony_PCR", "fragment_analyzing", "overnight_suspension", "yeast_mating", "make_yeast_plate", "overnight_suspension_divided_plate_to_deepwell", 
             "dilute_yeast_culture_deepwell_plate", "cytometer_reading", "golden_gate", "ecoli_transformation_stripwell", "make_ecoli_lysate",
             "move_analyzer_cartridge", "ecoli_colony_PCR", "fragment_analyzing_ecoli"]

# set file headings
FILE_LIST.each do |file_name|
  data_file_init = File.open("data/#{file_name}.csv", "w")
  data_file_init.write("job_id,size,duration,ajusted_duration,max_time_interval,user_id,user_name\n")
  data_file_init.close
end

# generate reports for all jobs within range
lower_bound_id = 28096
upper_bound_id = 41644

job_data = Test.send({
  login: Test.login,
  key: Test.key,
  run: {
    method: "find",
    args: {
      model: :job,
      where: { id: (lower_bound_id..upper_bound_id).to_a }
    }
  }
})

(lower_bound_id..upper_bound_id).each_with_index do |id, idx|
  log = job_data[:rows][idx]

  break unless log
  
  if log[:path][-2..-1] == 'rb' && log[:group_id] == 55 && log[:backtrace][-1][:operation] == "complete"
    time_size_report log
  end
end

puts "\n\n--- All done! Thanks for using TETRA. :) ---"
puts "    #{upper_bound_id - lower_bound_id} jobs processed in #{(Time.now - start_time)} s\n\n"
