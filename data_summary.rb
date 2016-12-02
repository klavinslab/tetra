require 'csv'
class Array
  def mean
    sum = inject(0) { |s,n| s += n }
    sum.to_f / size
  end
  
  def mode
    freq = self.inject(Hash.new(0)) { |h,v| h[v] += 1; h } 
    self.max_by { |v| freq[v] }
  end
end

class Array
  def stddev
    m = mean
    variance = inject(0) { |s,n| s+= (n-m) ** 2 } / (size-1)
    Math.sqrt(variance)
  end
end
FILE_LIST = %w[get_primer PCR pour_gel run_gel cut_gel purify_gel
  gibson ecoli_transformation plate_ecoli_transformation image_plate start_overnight_plate miniprep sequencing upload_sequencing_results glycerol_stock streak_yeast_plate overnight_suspension_collection inoculate_large_volume_growth make_yeast_competent_cell digest_plasmid_yeast_transformation make_antibiotic_plate yeast_transformation plate_yeast_transformation make_yeast_lysate yeast_colony_PCR yeast_mating overnight_suspension discard_item fragment_analyzing cytometer_reading overnight_suspension_divided_plate_to_deepwell dilute_yeast_culture_deepwell_plate]

FILE_LIST.sort!

summary_file = File.open("data/data_summary.csv", "w")
summary_file.write(%w[job_name average_time_per_reaction mode_time_per_reaction num stddev average_size mode_size week_size].join(", ")+ "\n")

FILE_LIST.each do |file_name|
  job_data = CSV.read("data/#{file_name}.csv")
  mean_durations = []
  sizes = []
  job_data[1..-1].each do |data|
    mean_durations.push data[3].to_f/data[1].to_f
    sizes.push data[1].to_f
  end
  summary_file.write("#{file_name},#{mean_durations.mean.round(1)}, #{mean_durations.mean.round(1)}, #{mean_durations.size},#{mean_durations.stddev.round(1)},#{sizes.mean},#{sizes.mode},#{(sizes.mean*5).ceil}\n")
end

summary_file.close
