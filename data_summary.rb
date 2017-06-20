require 'csv'

class Array
  def mean
    sum = inject(0) { |s,n| s += n }
    sum.to_f / size
  end

  def median
    self.sort[size / 2]
  end
  
  def mode
    freq = self.inject(Hash.new(0)) { |h,v| h[v] += 1; h } 
    self.max_by { |v| freq[v] }
  end

  def stddev
    m = mean
    variance = inject(0) { |s,n| s+= (n-m) ** 2 } / (size-1)
    Math.sqrt(variance)
  end
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
# FILE_LIST.sort!

summary_file = File.open("data_summary.csv", "w")
summary_file.write(%w[job_name num mean_time median_time mode_time mean_size median_size mode_size min_time_per_reaction max_time_per_reaction].join(", ")+ "\n")

FILE_LIST.each do |file_name|
  job_data = CSV.read("data/#{file_name}.csv")
  if job_data.length <= 1
    summary_file.write("#{file_name}, No Data\n")
    next
  end

  durations = []
  sizes = []
  job_data[1..-1].each do |data|
    durations.push data[3].to_f
    sizes.push data[1].to_f
  end

  min_time_per_reaction = [durations.mean / sizes.mean, durations.mean / sizes.median, durations.mean / sizes.mode].min
  max_time_per_reaction = [durations.mean / sizes.mean, durations.mean / sizes.median, durations.mean / sizes.mode].max

  summary_file.write("#{file_name}, #{job_data.length - 1}, #{durations.mean.round(1)}, #{durations.median.round(1)}, " + 
    "#{durations.mode.round(1)}, #{sizes.mean.round(1)}, #{sizes.median.round(1)}, #{sizes.mode.round(1)}, " +
    "#{min_time_per_reaction.round(1)}, #{max_time_per_reaction.round(1)}\n")
end

summary_file.close
