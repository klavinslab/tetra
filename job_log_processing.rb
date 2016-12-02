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
    if ["get_primer","order_primer"].include? file_name
      size = resp[:backtrace][-1][:rval][:io_hash][:primer_ids].length
    elsif resp[:backtrace][-1][:rval].is_a? Array
      size = resp[:backtrace][-1][:rval].length
    else
      size = resp[:backtrace][-1][:rval][:io_hash][:size]
    end
    data_file = File.open("data/#{file_name}.csv", "a")
    time_size_data_processing(resp, data_file, 20, size)
    data_file.close
  end

end

FILE_LIST = %w[order_primer get_primer PCR pour_gel run_gel cut_gel purify_gel
  gibson ecoli_transformation plate_ecoli_transformation image_plate start_overnight_plate miniprep sequencing upload_sequencing_results glycerol_stock streak_yeast_plate overnight_suspension_collection inoculate_large_volume_growth make_yeast_competent_cell digest_plasmid_yeast_transformation make_antibiotic_plate yeast_transformation plate_yeast_transformation make_yeast_lysate yeast_colony_PCR yeast_mating overnight_suspension discard_item fragment_analyzing cytometer_reading overnight_suspension_divided_plate_to_deepwell dilute_yeast_culture_deepwell_plate]

FILE_LIST.each do |file_name|
  data_file_init = File.open("data/#{file_name}.csv", "w")
  data_file_init.write("job_id,size,duration,ajusted_duration,max_time_interval,user_id,user_name\n")
  data_file_init.close
end

response = Test.send({
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
response[:rows].each do |user|
  USER_ID_NAME[user[:id]] = user[:name]
end

lower_bound_id = 27490
upper_bound_id = 34485
# 16317

(lower_bound_id..upper_bound_id).each do |id|
  response = Test.send({
      login: Test.login,
      key: Test.key,
      run: {
        method: "find",
        args: {
          model: :job,
          where: { id: id }
        }
      }
    })
  # puts response
  if response[:rows].length == 0
    break
  end
  if response[:rows].length > 0
    if response[:rows][0][:path][-2..-1] == 'rb' && response[:rows][0][:group_id] == 55 && response[:rows][0][:backtrace][-1][:operation] == "complete"
      time_size_report response[:rows][0]
    end
  end
end
